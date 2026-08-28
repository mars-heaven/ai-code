# 시설별 예약·구매 흐름 정리

코드에서 파악되는 흐름 기준. 시설의 동작은 `APT_COMMUNITY.SERVICE_TYPE`(시설 단위)과
`APT_COMMUNITY_MEMBERSHIP_INFO.RESERVATION_TYPE`(회원권 단위) 조합으로 결정된다.

## 0. 공통 진입 및 결제 흐름

**공통 진입**

```
앱 커뮤니티 탭
 → get_community_facility        (시설 목록·운영상태)
 → get_community_facility_info   (시설 상세, SERVICE_TYPE 확인 → 이후 화면 분기)
 → get_community_settings        (최대 선택일·보안·연속예약 설정)
 → get_reservation_notice        (유의사항)
 → [SECURITY=1] get_user_photo_status / register_user_face  (얼굴 등록)
 → [성별 구분 시설] register_user_gender
```

**유료 결제 공통 (NEED_TO_PAY = 1)**

```
create_partner_payment            → PAYMENT_ID(주문번호) 발급
앱에서 Bootpay 결제창 진행          → RECEIPT_ID 획득 (승인 전 상태)
purchase_membership 또는
reservation_community_schedule /
reservation_guestroom 호출 시
PaymentId + ReceiptId 전달
 서버: 트랜잭션+GET_LOCK 내부에서
   DB INSERT → verifyPayment(금액 검증) → confirmBootpayPayment(승인)
   → PARTNER_PAYMENT INSERT(STATE=1) → COMMIT
 실패 시: rollback + (승인 후였다면) 보상 취소(cancelBootpayPaymentByReceiptId)
```

- 결제 행의 `PARTNER_PAYMENT.RESERVATION_ID`에는 예약 ID가 아니라 **MEMBERSHIP_USER_LIST_ID**가 저장된다 (MENU_ID=49).
- 모든 흐름에서 "구매/예약 1건"은 최종적으로
  `APT_COMMUNITY_MEMBERSHIP_USER_LIST`(회원권) + `APT_COMMUNITY_RESERVE`(예약) 행 쌍으로 남는다.

---

## 1. SERVICE_TYPE = 1 · 바로 예약 (IMMEDIATE_RESERVE)

날짜·시간대·자리를 골라 바로 예약하는 시설. **골프연습장, 탁구장, 스크린골프** 유형.

```
get_available_schedule (선택 날짜의 자리×시간대 가능 여부 JSON)
   ├─ 휴무(정기/임시/공휴일)·단축운영 반영
   ├─ 아이디당/세대당 × 일/주 예약 횟수 제한(RESERVE_LIMIT) 검사
   └─ 기존 예약·휴식시간·IMPOSSIBLE_PLACE와 겹침 계산
 → (유료면 결제 공통 흐름)
 → reservation_community_schedule
     예약 INSERT + 회원권 자동 발급(예약 시간 = 이용기간) + 결제 승인
     ※ MembershipId 미전달 시 시설 기본 회원권 자동 선택
 → 후처리: IoT 전원(당일·이용시간 내), 푸시, 얼굴 출입 등록(당일 건)
취소: cancel_myreservation (미래 건이면 환불 포함)
```

- 동시성 방어: `reservation_schedule:{APT}:{TYPE}:{날짜}` 잠금 + 잠금 후 시간충돌 재확인.
- 대관 회원권(RESERVE_TYPE=3)이 붙으면 자리 대신 `PLACE_ALL`로 시설 전체를 잡는다 → **스카이라운지 대관** 유형.

## 2. SERVICE_TYPE = 2 · 이용권 구매 후 이용 (TICKET_PURCHASE_WITH_TIME)

기간형 회원권을 구매한 뒤 이용(또는 추가 예약)하는 시설. **헬스장, 독서실, 사우나, 락커** 유형.

```
get_membership (구매 가능 회원권 목록 + 내 보유 상태)
   ├─ 세대 연계 할인: 세대 내 유효 회원권 있으면 CONDITION 높은(할인) 회원권 노출
   ├─ 선행 회원권(PREREQUISITE) 조건: 예) 락커는 헬스 회원권 보유자만
   └─ 정원·구매횟수·최대 보유 수 표시
 → get_membership_option (옵션 선택: 예. 락커 위치, 부가상품)
 → [좌석 시설] get_community_seat_map + get_community_available_seat (독서실 지정석 등)
 → (유료면 결제 공통 흐름)
 → purchase_membership
     회원권 INSERT + 예약 INSERT(기간 전체 1건) + 결제 승인
     좌석·정원·구매개수 잠금 후 재확인
 → 후처리: 얼굴 출입 등록(이용 시작일 도래 시), 푸시
이용: get_membership_list / get_my_membership_info (QR 표시: SECURITY=2)
자리 변경: update_reservation_seat (IS_SEAT_CHANGEABLE=1)
취소: cancel_membership (연계 예약 일괄 취소 + 환불 + 세대 연계 재구성)
```

- 동시성 방어: `purchase_membership:{APT}:{TYPE}` 시설 단위 잠금 + 좌석/정원/개수 재확인.
- **RESERVE_TYPE = 1 (구매 후 추가 예약)** 회원권 — 예: 골프장 월 회원권처럼
  회원권을 사두고 회차별 예약을 따로 하는 경우:

```
(회원권은 이미 보유)
get_available_schedule → reservation_community_schedule
   ├─ 유효 회원권이 있으면 그 회원권에 예약만 연결 (USE_COUNT 기반)
   ├─ USAGE_LIMIT 소진 or 회원권 없음 → 새 회원권 자동 발급 후 연결
   └─ 취소 시(cancel_myreservation): 예약만 취소, 회원권은 유지
       (단, 미결제 STATE=0 건은 회원권도 함께 취소)
```

## 3. SERVICE_TYPE = 4 · 이용권 구매와 예약 동시 (TICKET_PURCHASE_AND_RESERVE)

구매 = 수강신청인 시설. **GX 강습(17)** 유형. 정원 마감(`PURCHASABLE_MAX_COUNT`)이 핵심.

```
get_membership
   ├─ 강습(회원권)별 정원·현재 등록 인원 표시
   ├─ 구매 가능 시작시각(PURCHASABLE_DATE_FROM) 도래 시 오픈
   └─ 전월 수강생은 PRIORITY_PURCHASE_DAY일 만큼 우선구매
 → (유료면 결제 공통 흐름)
 → purchase_membership
     시설 잠금 → **정원 재확인(마감 시 여기서 차단)** → 회원권+예약 INSERT → 결제 → COMMIT
 → 후처리: 얼굴 출입 등록, 푸시
취소: cancel_membership (정산일 전 환불)
```

- 이번 동시성 수정의 주 대상. 정원이 차면 INSERT·결제 모두 진입 불가.

## 4. 게스트하우스 (COMMUNITY_TYPE = 10, 전용 흐름)

객실×숙박기간 단위 예약. 전용 SID를 사용한다.

```
get_guestroom_number (객실 목록) → get_guestroom_image (객실 사진)
 → get_unavailable_dates (객실별 예약 불가 날짜: 기존 예약 + IMPOSSIBLE_PLACE + 휴무·공휴일)
 → get_monthly_limit (세대의 월별 잔여 예약 가능 박수, 3개월)
 → get_min_max_people_range (인원 범위)
 → (유료면 결제 공통 흐름)
 → reservation_guestroom
     객실 잠금(reservation_guestroom:{APT}:{객실}) → 날짜 겹침 재확인
     → 회원권 INSERT + 예약 INSERT(체크인 DATE ~ 체크아웃 EXPIRATION_DATE) → 결제 → COMMIT
취소: cancel_myreservation
```

- 운영상태 표시는 게스트하우스 특례: 운영시간 밖에도 "운영중"으로 표시.

## 5. SERVICE_TYPE = 3 · 예약 없음 (NO_RESERVE)

조회 전용 시설(자유 이용). `get_community_facility(_info)`로 운영상태·안내만 제공하고
구매/예약 SID를 사용하지 않는다. COMMUNITY_STATE=2(예약준비중)인 시설도 이 상태로 노출된다.

---

## 6. 시설 타입 ↔ 흐름 매핑 (코드 근거 요약)

| 시설 (COMMUNITY_TYPE) | 유형 | 주 흐름 | 근거 |
|---|---|---|---|
| 골프 01 / 탁구 02 / 스크린골프 05 | 시간대·자리 예약 | ① 바로 예약 | facility 상세에 자리개수·타임간격 표시 |
| 헬스장 03 / 도서관 09 | 기간 회원권 | ② 구매 후 이용 | 운영시간+휴무만 표시, 기간형 |
| 독서실 04 | 기간 회원권 + 지정석 | ② (+ 좌석) | 자리개수 표시, 좌석맵, 광명자이 QR 특례 |
| 골프락커 06 / 헬스락커 07 | 기간 회원권 + 지정 락커 | ② (+ 좌석·선행회원권) | Seat 파라미터, PREREQUISITE |
| 사우나 08 | 기간/일일 회원권 | ② | — |
| 게스트하우스 10 | 객실 숙박 | ④ 전용 흐름 | reservation_guestroom, COMMUNITY_TYPE='10' 하드코딩 |
| 스카이라운지 11 | 대관 | ① + RESERVE_TYPE=3 | PLACE_ALL 처리 |
| GX 17 | 정원제 수강 | ③ 구매=예약 동시 | 정원·우선구매 로직이 17에 하드코딩 |

## 7. 흐름별 동시성 방어 현황 (수정 후)

| 흐름 | 잠금 키 | 잠금 후 재확인 | 마감 시 |
|---|---|---|---|
| 회원권 구매 (purchase_membership) | `purchase_membership:{APT}:{TYPE}` (10초) | 좌석 + 정원 + 구매개수 | INSERT·결제 차단, rollback |
| 커뮤니티 예약 (reservation_community_schedule) | `reservation_schedule:{APT}:{TYPE}:{날짜}` (10초) | 자리·시간충돌 | INSERT·결제 차단, rollback |
| 게스트하우스 (reservation_guestroom) | `reservation_guestroom:{APT}:{객실}` (5초) | 날짜 겹침 | INSERT·결제 차단, rollback (기존 구현) |
| 자리 변경 (update_reservation_seat) | 없음 | 변경 후 재검증 → 원복 | 낙관적 방식 (원복으로 복구) |
