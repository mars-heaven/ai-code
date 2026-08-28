# 커뮤니티 JSP SID·함수 레퍼런스

apt_global.jsp(공통 상수·DB 설정)를 제외한 5개 파일의 SID(요청 구분자)와 선언 함수 정리.
회원권 구매(`purchase_membership`)와 커뮤니티 예약(`reservation_community_schedule`)은 상세 기술.

- 공통 요청 형식: `SID` 파라미터로 분기. 응답은 빌리진아이 포맷
  `[데이터길이 4byte] + [컬럼(0x1C)·레코드(0x1A) 구분자로 조립된 본문]`.
- 주요 테이블
  - `APT_COMMUNITY` : 시설 마스터 (운영시간, 좌석명 PLACE_NAME, 보안 SECURITY, 서비스타입 SERVICE_TYPE, 이용불가자리 IMPOSSIBLE_PLACE …)
  - `APT_COMMUNITY_MEMBERSHIP_INFO` : 회원권 상품 (가격, 정원 PURCHASABLE_MAX_COUNT, 예약타입 RESERVATION_TYPE, 결제여부 NEED_TO_PAY, 사용횟수 USAGE_LIMIT, 구매제한 MAX_PURCHASE_LIMIT/RESERVE_LIMIT …)
  - `APT_COMMUNITY_MEMBERSHIP_USER_LIST` : 구매된 회원권 (1행 = 회원권 1구매, PK MEMBERSHIP_USER_LIST_ID)
  - `APT_COMMUNITY_RESERVE` : 예약 (1행 = 예약 1건, PK RESERVE_ID, PLACE/DATE/TIME/EXPIRATION_DATE)
  - `PARTNER_PAYMENT` : 결제 (MENU_ID 49 = 커뮤니티, RESERVATION_ID 컬럼에 **MEMBERSHIP_USER_LIST_ID** 저장)
  - `APT_COMMUNITY_SPECIFIC` : 휴무/단축운영, `APT_COMMUNITY_USER_INFO` : 얼굴/성별, `APT_COMMUNITY_DOOR` : 출입문, `APT_COMMUNITY_QR` : QR 기기

---

## 1. apt_community_membership.jsp — 회원권

### SID 목록

| SID | 기능 |
|---|---|
| `get_membership` | 시설의 구매 가능 회원권 목록 + 내 구매 상태 조회 |
| `get_membership_option` | 회원권 옵션(OPTION_ID/이름/가격/성별필수) 목록 |
| `purchase_membership` | **회원권 구매 (+ 예약 생성 + 결제 승인)** — 아래 상세 |
| `cancel_membership` | 회원권 취소 (+ 연계 예약 일괄취소 + 결제 환불) |
| `get_my_membership_info` | 내 회원권 상세 (RESERVE_ID 기준, QR·취소/환불 가능 계산) |

#### get_membership
- 파라미터: `AptCode, CommunityType, UserId, Gender, UUID, UserDong, UserHo, UserName`
- 처리:
  - 내 유효 회원권(만료 전·미취소)을 조회해 회원권 그룹별 구매 상태 계산.
  - 세대 내 다른 이용자의 유효 회원권 존재 시 `MEMBERSHIP_GROUP` + `MEMBERSHIP_CONDITION` 최대값 기준으로 **연계(할인) 회원권**을 노출, 없으면 CONDITION=0 기본 회원권만 노출.
  - GX(17)는 전월 수강생에게 `PRIORITY_PURCHASE_DAY`만큼 **우선구매 오픈시각**을 앞당겨 계산.
  - `PREREQUISITE_MEMBERSHIP_ID`(선행 회원권) 미보유 시 구매 불가 처리.
  - 정원: `PURCHASABLE_MAX_COUNT`(정원)와 현재 등록 인원(`MEMBERSHIP_COUNT`, 취소 제외 COUNT)을 함께 내려 앱이 마감 표시.
  - `USAGE_LIMIT` 기반 남은 예약 횟수(`getRemainingUses`), `MAX_PURCHASE_LIMIT` 대비 보유 수(`recordCount`) 계산.
  - 노출 조건: `MEMBERSHIP_SHOW_DAY`(노출 시작일), `VALIDITY_DATE_TO` 미경과, `MEMBERSHIP_HIDDEN`=0, 성별 일치.
- 응답(회원권별 레코드): 회원권ID, 이름, 설명(+이용기간), 가격, 이동페이지(MEMBERSHIP_TYPE), 필수선택, 다중선택, 성별필수, 구매상태(0 미구매/1·3 사용중[3=취소가능]/2·4 추가예약형 보유), 보유 MEMBERSHIP_USER_LIST_ID들(콤마), 유효기간 FROM/TO, 구매가능 시작/종료 시각, 정원, 현재 등록 인원, 남은 횟수, 보유 수, 최대 구매 수, 취소가능여부, 예약범위/단위, 예약 기준일, 결제여부, 정산일

#### purchase_membership — 상세

- 호출 시점: 회원권 구매 확정 시(유료면 앱에서 Bootpay 결제 후 `PaymentId`/`ReceiptId`를 들고 호출).
- 파라미터: `MembershipId, AptCode, UserId, UserName, UserDong, UserHo, CommunityType, Price, UserPhoneNo, Seat, MembershipOption, ReservationUserName, Gender, UUID, ReservationChannel, ValidityDateFrom, ValidityDateTo, PaymentId, ReceiptId`
- 처리 단계:
  1. **파라미터 보정**: 이용자명 없으면 구매자명, 전화번호 없으면 USER_INFO에서 조회, 가격에서 "원"/"," 제거.
  2. **회원권 정보 조회** (`APT_COMMUNITY_MEMBERSHIP_INFO`): 유효기간 정책(VALIDITY_PERIOD/UNIT, VALIDITY_DATE_FROM/TO), 정원(PURCHASABLE_MAX_COUNT), 성별, 결제여부(NEED_TO_PAY), 예약타입, 구매횟수 제한(RESERVE_LIMIT_TYPE/UNIT/LIMIT), 최대 구매수(MAX_PURCHASE_LIMIT — 이 시점에 숫자 파싱).
  3. **정원 사전 체크**: 취소 제외 구매 건수 ≥ 정원이면 즉시 `"이용권이 마감되었습니다."` 응답 (빠른 실패).
  4. **이용기간 확정**: 앱 선택일 > 회원권 고정기간 > VALIDITY_PERIOD 계산 순으로 시작/만료일 결정.
  5. **구매 횟수 제한 검사**(RESERVE_LIMIT): 이용자별(0)/세대별(1) × 일(0)/주(1) 단위로 기간 내 구매 건수 검사, 초과 시 실패 응답.
  6. **좌석 사전 체크**: 같은 시설·좌석·기간 겹침 예약 존재 시 `"해당 자리는 마감되었습니다..."` 응답.
  7. **트랜잭션 시작** `setAutoCommit(false)`.
  8. **직렬화 잠금**: `GET_LOCK('purchase_membership:{APT}:{TYPE}', 10)` — 시설 단위. 실패 시 `"회원권 구매가 처리 중입니다..."`.
  9. **잠금 후 재확인** (여기서 마감이면 예외 → rollback, INSERT/결제 진입 차단):
     - 좌석 재확인 (좌석 있는 경우)
     - **정원 재확인** (PURCHASABLE_MAX_COUNT — 2026-08 수정에서 추가)
     - 구매 개수 재확인 (MAX_PURCHASE_LIMIT — 사용자·회원권 기준)
  10. **회원권 INSERT** (`APT_COMMUNITY_MEMBERSHIP_USER_LIST`) → INSERT 후 정원 백스톱 체크(count > max 시 예외).
  11. 생성된 `MEMBERSHIP_USER_LIST_ID` 조회(동·호·이름 기준 최신) → 얼굴인식 필수 시설(SECURITY=1)인데 사진 없으면 예외.
  12. **예약 INSERT** (`APT_COMMUNITY_RESERVE`, 회원권과 연결) → `USE_COUNT + 1`.
  13. 최종 좌석 중복 검증(같은 회원권·좌석의 예약 나열 후 내 예약이 첫 번째가 아니면 예외), MAX_PURCHASE_LIMIT 최종 중복 검증.
  14. **결제** (NEED_TO_PAY=1): `verifyPayment`(금액·상태 검증) → `confirmBootpayPayment`(승인) → 영수증 URL/결제일 추출. 실패 시 예외.
  15. **PARTNER_PAYMENT INSERT** (STATE=1, MENU_ID=49, RESERVATION_ID = MEMBERSHIP_USER_LIST_ID) → 정산일(SETTLEMENT_DATE) 계산·UPDATE.
  16. 최종 조건 확인 후 **COMMIT** → RELEASE_LOCK → autoCommit 원복 → 응답 전송.
  17. **후처리**(응답 후, 실패해도 무시): 얼굴 출입 등록 API(`callDevMembershipReservationAPI`, 문별), 예약 알림 푸시(`push_send_service.jsp`).
- 실패 경로: 예외 → rollback → (결제 승인 후였다면) `cancelBootpayPaymentByReceiptId`로 **보상 취소** → 실패 응답("0" + 메시지) → finally에서 RELEASE_LOCK, autoCommit 원복.
- 응답: 성공 시 `1, "예약이 완료되었습니다!", 예약ID, 구매내역 문자열(성함/동호/시설/날짜/회원권/좌석), 결제ID(유료)` / 실패 시 `0, 메시지, 공백...`

#### cancel_membership
- 파라미터: `MembershipUserListId, CancelTime, CancelReason, CancelChannel(00=사용자), IsRefund(1=환불)`
- 처리: 취소 대상 조회(이미 취소된 건 제외) → 회원권 CANCEL_DATE UPDATE →
  `CANCEL_TYPE`에 따라 연계 예약 일괄취소(0=전체, 1=미래 예약만) →
  정산일 이전 + 이용 시작 전 + 유료 건이면 Bootpay 환불(우회서버 `bootpay_recepit_cancel.jsp`) 후 `PAYMENT_PAY`/`PARTNER_PAYMENT` 갱신 →
  세대 연계 회원권(CONDITION 0/1) 재구성: 대표(0) 취소 시 세대원의 할인(1) 회원권을 취소하고 기본가 회원권·예약으로 재발급 →
  얼굴인식 시설이면 출입 삭제 API 호출.
- 응답: 처리 건수(1 성공 / -1 실패)

#### get_my_membership_info
- 파라미터: `AptCode, UserId, MembershipId(실제 값은 RESERVE_ID), UserName, UserDong, UserHo`
- 처리: 예약-회원권-시설-옵션 조인 상세 조회 → 표시 정보 문자열(`항목*값*+` 포맷) 조립 →
  취소 가능(회원권/예약 취소정책 + RESERVE_CANCEL_AVAILABLE_TIME 마감시각) / 환불 가능(정산일·이용시작 전) 계산 →
  QR 보안(SECURITY=2) 시설이면 본인+미취소+입장 가능 시간(±15분) 조건에서 QR ID/보안코드 반환 →
  운영상태(휴무/운영중/종료) 계산.
- 응답: 이미지, 시설명, 상세문자열, 취소가능, 버튼문구, 취소마감시각, 버튼표시, 보안, 자리변경가능, 회원권ID, 옵션ID, 자리, 시작/종료일, 입장 시작/종료시각, 시설타입, 영수증URL, QR ID/보안코드, 운영상태, 환불마감일, MEMBERSHIP_USER_LIST_ID

### 선언 함수 (membership)

| 함수 | 기능 |
|---|---|
| `getRequestParam(request, key)` | 요청 파라미터를 8859_1→UTF-8 변환해 조회 (null→"") |
| `returnData(baOut, out)` | [길이4byte+본문] 포맷으로 응답 전송 |
| `createOrederID()` | 랜덤4 + yyMMddHHmmssSSS 주문번호 생성 |
| `writeLogFile(log)` | 결제 오류 월별 로그 파일 기록 |
| `convDateFormat(date)` | ISO8601 → yyyyMMddHHmmss 변환 (Bootpay 응답용) |
| `Holiday` (class) | 휴무 규칙 모델 (반복타입/요일/일/특정일) |
| `formatDate(yyyyMMdd)` | `yy.MM.dd(E)` 한국어 표기 |
| `Reservation` (class) | 자리+시간 모델 |
| `callDevMemberDeleteAPI(...)` | 우회서버로 얼굴 출입 삭제 API 호출 |
| `callDevMembershipReservationAPI(...)` | 우회서버로 회원권 기간 얼굴 출입 등록 API 호출 |
| `getRemainingUses(conn, ...)` | USAGE_LIMIT − 사용(예약) 횟수 = 남은 횟수 |
| `getHolidaysQuery(apt, type)` | 정기(0)/임시(3) 휴무 조회 쿼리 |
| `isTodayHoliday(...)` / `isTodayTempHoliday(...)` | 오늘이 정기/임시 휴무인지 판정 |
| `getTimeQuery(apt, type)` | 시설 운영시간(START/END, OPERATION_HOURS) 조회 쿼리 |
| `extractValue(json, key, field)` | OPERATION_HOURS JSON에서 WEEKDAY/WEEKEND start·end 추출 |
| `validateLastReservationPeriod(...)` | 마지막 예약이 아직 지나지 않았는지 판정 (횟수 소진 회원권 상태 표시용) |
| `formatDateTime(yyyyMMddHHmmss)` | `yy.MM.dd(E) HH:mm:ss` 표기 |

`verifyPayment`, `confirmBootpayPayment`, `cancelBootpayPaymentByReceiptId`,
`convertBootpayDateToDBFormat`, `getJsonNumberToString` 등 결제 함수는
**apt_global_payment.jsp**(이번 저장소에 미포함)에 정의된 것으로 추정.

---

## 2. apt_community_reservation.jsp — 예약

### SID 목록

| SID | 기능 |
|---|---|
| `cancel_myreservation` | 예약 취소 (+ 회원권 취소, 결제 환불, 푸시, 얼굴 삭제) |
| `get_reservation_list` | 내 예약 내역 목록 (10건 페이징, D-day, QR, 운영상태) |
| `get_reservation_info` | 예약 상세 (취소 가능/마감시각, 환불, QR, 영수증) |
| `get_qr_info_list` | 아파트의 QR 기기 목록 |
| `reservation_community_schedule` | **커뮤니티 예약 (+ 회원권 발급 + 결제)** — 아래 상세 |
| `create_partner_payment` | 결제 주문번호(PAYMENT_ID) 발급 |
| `get_reservation_notice` | 시설명 + 예약 유의사항(RESERVATION_INFORMATION) |
| `get_community_available_seat` | 기간 기준 잔여 좌석 조회 (JSON) |
| `reservation_guestroom` | 게스트하우스 예약 (+ 회원권 + 결제) — 객실 단위 GET_LOCK 기적용 |
| `update_reservation_seat` | 예약 자리 변경 (변경 후 재검증, 충돌 시 원복) |
| `get_membership_list` | 내 회원권 목록 (예약 연계 상태 포함) |

#### reservation_community_schedule — 상세

- 호출 시점: 시간대 예약 확정 시(유료면 Bootpay 결제 후 호출). `SERVICE_TYPE 1(바로예약)`/`4(구매+예약 동시)` 시설과 `RESERVE_TYPE 1(구매 후 추가예약)`의 추가 예약에 사용.
- 파라미터: `CommunityType, UserId, UserDong, UserHo, ReservationUserName, ReservationUserPhone, Place, Date(yyyyMMdd), Time(HHmmHHmm), AptCode, UserName, MembershipId, Price, People, Gender, UUID, PaymentId, ReceiptId`
- 처리 단계:
  1. **필수값 검증** (AptCode/UserId/CommunityType/MembershipId/Date/Time/동/호/이용자명) — 없으면 즉시 실패 응답.
  2. 전화번호 보정(USER_INFO), 시설 설정 조회(SECURITY/SERVICE_TYPE/GENDER), 회원권 조회(가격·RESERVATION_TYPE·NEED_TO_PAY), 정산 기준일 조회.
  3. 대관형(RESERVE_TYPE_RENTAL=3)은 `Place = "PLACE_ALL"`로 통일.
  4. **중복/시간충돌 사전 검사**: 같은 아파트·시설·날짜(대관 아니면 자리까지)에서 취소 안 된 예약과 시간 겹침(자정 넘김 포함) COUNT. 겹치면 nRet=2로 "이미 예약되었습니다" 응답.
  5. 즉시예약 시설인데 MembershipId 없으면 기본 회원권 자동 선택. 얼굴인식 필수 시설(SECURITY=1)인데 사진 없으면 코드 9 응답.
  6. 유료 건: PaymentId/ReceiptId/Price 필수, `PARTNER_PAYMENT`에서 같은 PAYMENT_ID가 이미 승인(STATE=1)인지 중복 확인.
  7. **트랜잭션 시작** → **직렬화 잠금** `GET_LOCK('reservation_schedule:{APT}:{TYPE}:{날짜}', 10)` → **잠금 후 중복/시간충돌 재확인** (2026-08 수정에서 추가; 마감이면 예외 → rollback, INSERT/결제 차단).
  8. **예약 INSERT** (`APT_COMMUNITY_RESERVE`) → 생성 RESERVE_ID 조회.
  9. **회원권 발급/연결**:
     - RESERVATION_TYPE ≠ 1: 예약 날짜·시간을 이용기간으로 하는 회원권을 새로 INSERT 후 예약에 연결.
     - RESERVATION_TYPE = 1(구매 후 추가예약): 유효 회원권이 없거나 USAGE_LIMIT 소진 시에만 새 회원권 INSERT(당일 유효기간 정책 계산), 이후 최신 회원권을 예약에 연결.
  10. **결제** (`processReservationPayment`): verify → confirm → PARTNER_PAYMENT INSERT(STATE=1) → 정산일 UPDATE. 결과는 `PaymentResult`에 기록.
  11. 최종 조건 확인 → **COMMIT** → RELEASE_LOCK → autoCommit 원복 → 성공 응답 전송.
  12. **후처리**(응답 후): 당일·이용시간 내면 IoT 전원 제어 API, 예약 푸시, 얼굴 출입 등록 API(`callDevReservationAPI`, 당일 예약만; 미래 예약은 스케줄러 처리).
- 실패 경로: 예외 → rollback → (confirm 후였다면) Bootpay 보상 취소 → 실패 응답 → finally에서 RELEASE_LOCK, autoCommit 원복.
- 응답: 성공 `1, "예약이 완료되었습니다!", 예약ID, 예약내역 문자열` / 자리 중복 `2, "죄송합니다. 선택하신 자리는..."` / 실패 `0, 메시지`

#### 기타 SID 요약

- **cancel_myreservation** (`ReservationId, CancelTime, CancelReason, CancelChannel, IsRefund`):
  예약 RESERVE_CANCEL_TIME UPDATE → 세대 연계(CONDITION) 재구성(회원권 취소와 동일 로직) →
  RESERVATION_TYPE ≠ 1 이거나 미결제(STATE=0) 건이면 연결 회원권도 취소 →
  얼굴인식 시설이면 출입 삭제 API → 취소 푸시 →
  미래 예약 + 환불요청 + 정산일 이전이면 Bootpay 환불 및 결제 테이블 갱신.
- **get_reservation_list**: 동·호·이름 기준 USER_ID 자동 매핑(과거 데이터 보정 UPDATE) 후
  예약 목록 10건씩 조회. D-day(DIFF_DATE), 이용가능→일일권→기간권→완료 순 정렬,
  미결제(STATE=0) 건 스킵, QR(보안2·본인·미취소·미경과)과 시설 운영상태 계산.
- **get_reservation_info**: 예약 1건 상세 + 취소 정책(RESERVE_CANCEL_AVAILABLE(_TIME))으로
  취소 가능/마감시각/버튼 문구 계산, 환불 가능일 계산, 영수증 URL, QR, 운영상태.
- **create_partner_payment** (`UserId, AptCode, Price`): `"49" + UUID + yyMMddHHmmssSSS` 형식
  PAYMENT_ID를 중복 검사(최대 5회)로 발급. 실제 결제 행은 예약/구매 SID에서 INSERT.
- **get_community_available_seat**: 회원권/옵션의 자리 목록(MEMBERSHIP_PLACE 또는 시설 PLACE_NAME)과
  기간 겹침 예약, IMPOSSIBLE_PLACE(이용불가 자리)를 비교해
  `[{seatName, available}]` JSON + 잔여 수 반환.
- **reservation_guestroom**: 필수값·날짜 겹침 사전 검사 → 트랜잭션 →
  `GET_LOCK('reservation_guestroom:{APT}:{객실}', 5)` → 잠금 후 날짜 중복 재확인 →
  회원권 INSERT → 예약 INSERT → 결제 verify/confirm → PARTNER_PAYMENT → COMMIT.
  (동시성 방어가 이미 적용되어 있던 SID)
- **update_reservation_seat** (`ReservationId, BeforeSeat, Seat`): 대상 자리 비었는지 확인 후
  PLACE UPDATE → 직후 재검증에서 같은 자리 예약이 1건이 아니면 BeforeSeat로 원복(코드 9).
- **get_membership_list**: 회원권(mul) 기준 목록. 예약 서브쿼리(최근 RESERVE_ID, 시작/만료/시간/횟수)와
  시설 정보를 조인해 D-day·이용날짜·시간·취소상태·미결제 제외 등을 계산.

### 선언 함수 (reservation)

| 함수 | 기능 |
|---|---|
| `getRequestParam` / `returnData` / `writeLogFile` / `convDateFormat` | membership과 동일 |
| `Holiday` / `isTodayHoliday` / `isTodayTempHoliday` / `Shortening` | 휴무·단축운영 모델 및 판정 |
| `formatDate` / `formatTime` / `formatDateTime` | 날짜·시간 표시 포맷 |
| `getTimeQuery` / `getHolidaysQuery` / `extractValue` | 운영시간·휴무 조회 |
| `Reservation` (class) | 자리+시간 모델 |
| `callDevMemberDeleteAPI` / `callDevReservationAPI` | 얼굴 출입 삭제/당일 등록 API (우회서버) |
| `getRemainingUses` | USAGE_LIMIT 잔여 횟수 |
| `isTimeWithinRange(now, s, e)` | 현재 시간이 구간 내인지 |
| `createDateTimeId()` | yyMMddHHmmssSSS 결제 ID 조각 생성 |
| `PaymentResult` (class) | confirm/저장 성공 여부·영수증 URL·결제일 보관 |
| `processReservationPayment(conn, ...)` | 유료 예약 결제 일괄 처리: verify → confirm → PARTNER_PAYMENT INSERT → 정산일 UPDATE |

---

## 3. apt_community_setting.jsp — 설정·부가 기능

### SID 목록

| SID | 기능 |
|---|---|
| `get_apt_security` | 아파트의 보안 기기 유형(1 얼굴인식/2 QR)·개수 |
| `get_available_schedule` | **선택 날짜의 자리×시간대별 예약 가능 여부 JSON** |
| `register_user_face` | 얼굴 사진 등록 (UUID 발급, 공용 출입문 등록, 당일 예약 재등록) |
| `get_user_photo_status` | 등록 사진 존재 여부(0/1) + 이미지 URL |
| `get_apt_manuals` | 커뮤니티 이용안내 HTML URL |
| `register_user_gender` | 이용자 성별 등록 (APT_COMMUNITY_USER_INFO) |
| `retry_register_user_face` | 예약 건 기준 얼굴 재등록 API 재호출 |
| `get_unavailable_dates` | 게스트하우스 객실 예약 불가 날짜 (기존 예약 + IMPOSSIBLE_PLACE + 휴무·공휴일) |
| `get_monthly_limit` | 게스트하우스 월별 잔여 예약 가능 일수 (3개월) |
| `get_min_max_people_range` | 회원권의 최소/최대 인원 |
| `get_holidays` | 향후 2개월 휴무일 목록 (yyyyMMdd) |

#### get_available_schedule (예약 화면의 핵심 조회)
- 파라미터: `AptCode, UserId, CommunityType, SelectedDate, MembershipId, SelectedUsers, UUID, UserDong, UserHo, UserName, Gender`
- 처리: 시설 설정(IMPOSSIBLE_PLACE, OPERATION_HOURS, PLACE_NAME, SERVICE_TYPE)과
  회원권 설정(RESERVE_LIMIT_TYPE/UNIT/LIMIT, RESERVE_TIME_INTERVAL(+UNIT), MEMBERSHIP_PLACE, RESERVATION_TYPE) 조회 →
  아이디당/세대당 × 일/주 단위 예약 횟수 제한 검사(초과 시 "예약 횟수를 모두 사용" 메시지) →
  휴무(정기/임시/공휴일)면 "센터 휴일" 메시지 →
  단축운영이면 운영시간 대체 →
  회원권 OPERATION_HOURS에 `reservations` 배열이 있으면 해당 고정 시간대 사용, 없으면
  `getTimeIntervals`(시작~종료를 간격 단위로 분할)로 시간대 생성 →
  당일 예약 내역·휴식시간(SPECIFIC_TYPE=2)·IMPOSSIBLE_PLACE(사유·기간 포함)와 대조(`isAvailable`) →
  자리별 `{place, availability:[{time, available, color}]}` JSON 배열 반환.
  모든 시간대 불가면 "예약 마감", 운영 종료 시간이 지났으면 "운영 종료" 단일 레코드.

### 선언 함수 (setting)

| 함수 | 기능 |
|---|---|
| `getRequestParam(issacweb, request, key)` / `returnData(issacweb, ...)` | IssacWeb 암호화 대응 버전 (isDev()=true라 평문 동작) |
| `isEscapeChar(s)` | `'`/`\` 이스케이프 |
| `Holiday` / `Shortening` / `createHolidayFromResultSet` | 휴무·단축 모델 |
| `isTodayHoliday` / `isTodayTempHoliday` / `isPublicHoliday` / `isSpecialOperatingDay` | 정기/임시/공휴일(HOLIDAYS 테이블)/임시운영일 판정 |
| `getTimeIntervals(start, end, n, unit)` | 운영시간을 간격 단위로 분할한 `HH:mm ~ HH:mm` 목록 |
| `parseToHHmmHHmm` / `parseTimeToMinutes` | 시간 포맷 변환 |
| `isAvailable(reservations, place, time, ...)` | 자리·시간대가 기존 예약(대관 PLACE_ALL 포함)·휴식시간과 겹치는지 판정 |
| `getHolidaysQuery` / `getShorteningQuery` | 휴무(0,3)/단축(1) 조회 쿼리 |
| `getUUID()` | 랜덤 UUID 해시 기반 정수 고유번호 |
| `callDevEntranceRegistrationAPI` / `callReservationTryAgain` | 얼굴 출입 등록/재등록 API (우회서버) |
| `extractValue` / `defaultIfNull` | JSON 추출 / null 기본값 |

---

## 4. apt_community_facility.jsp — 시설 조회

### SID 목록

| SID | 기능 |
|---|---|
| `get_community_facility` | 시설 목록 (타입, 이름, 운영시간, 상태[운영중/휴무/종료/예약준비중], 이미지) |
| `get_community_facility_info` | 시설 상세 (운영시간·좌석수·간격·휴무일 조합 문자열, 서비스타입, 성별, 보안) |
| `get_community_settings` | 예약 최대 선택일(MAXIMUM_RESERVATION_PERIOD), 보안, 지도, 예약 기준일, 연속예약 최소/최대 |
| `get_community_seat_map` | 좌석 배치도 URL (옵션 > 회원권 > 시설 순) |
| `get_guestroom_image` | 게스트하우스 객실 이미지 |
| `get_guestroom_number` | 게스트하우스 객실 번호 목록 |

### 선언 함수 (facility)

`getRequestParam(issacweb, ...)`, `returnData(issacweb, ...)`, `isEscapeChar`,
`Holiday`, `isTodayHoliday`, `isTodayTempHoliday`, `Reservation`,
`getCommunityQuery`(시설 목록 쿼리), `getHolidaysQuery`, `extractValue` — setting.jsp와 동일 계열.

---

## 5. global/community_global.jsp — 공통 상수·유틸

### 상수

| 분류 | 값 |
|---|---|
| 커뮤니티 타입 | 01 골프, 02 탁구, 03 헬스장, 04 독서실, 05 스크린골프, 06 골프락커, 07 헬스락커, 08 사우나, 09 도서관, 10 게스트하우스, 11 스카이라운지, 17 GX |
| 휴무 반복 | 0 매주, 1~5 n째주, 6 매달, 7 매일, 9 공휴일 |
| SPECIFIC 종류 | 0 정기휴일, 1 단축근무, 2 휴식시간, 3 임시휴무, 4 임시운영일 |
| 서비스 타입 | 1 바로예약, 2 이용권 구매 후 시간 선택, 3 예약없음, 4 이용권 구매+예약 동시 |
| 예약 타입 | 0 구매=예약 동시, 1 구매 후 추가예약, 2 일회성, 3 대관 |
| 시간 단위 | 0 분, 1 시, 2 일, 3 월, 4 년 |
| 예약 제한 | TYPE: 0 아이디당/1 세대당, UNIT: 0 일/1 주 |
| 시설 상태 | 0 숨김, 1 보임, 2 예약준비중 |
| 보안 | 0 없음, 1 얼굴인식 (+운영상 2 QR) |
| 성별 | 0 무관, 1 남, 2 여 |

### 함수

| 함수 | 기능 |
|---|---|
| `handleWeeklyRepeat(dayOfWeek)` | "매주 X요일" 문자열 |
| `handleSpecificWeekRepeat(week, day)` | "n째주 X요일" 문자열 |
| `formatCommunityData(type, time, count, interval, holidays)` | 시설 상세 안내 문자열(`운영시간*..*+자리개수*..*+...`) 조합 — 타입별 표시 항목 상이 |
