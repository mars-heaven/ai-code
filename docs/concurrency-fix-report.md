# 동시성 문제 원인 진단 및 수정 내용

- 대상 브랜치: `claude/membership-concurrency-control-sei9m6`
- 수정 커밋: `dcccbf6` (베이스라인: `378b75c`)
- 수정 파일: `apt/apt_community_membership.jsp`, `apt/apt_community_reservation.jsp`
- 작성일: 2026-08-28

---

## 1. 증상

- 정원제 회원권(예: GX 강습, `PURCHASABLE_MAX_COUNT` 설정)에 **밀리초 단위 동시 구매 요청**이 들어오면
  정원을 초과해 `APT_COMMUNITY_MEMBERSHIP_USER_LIST`에 INSERT되고 결제까지 승인됨.
- 커뮤니티 예약(`reservation_community_schedule`)도 같은 자리·같은 시간대에 동시 요청이 겹치면 중복 예약 INSERT 발생.

## 2. 원인 진단

### 2-1. purchase_membership (회원권 구매)

구매 처리 순서는 다음과 같았다.

```
① 정원 사전 체크 (SELECT COUNT ... 잠금 없음, 오토커밋 모드)
② setAutoCommit(false) — 트랜잭션 시작
③ GET_LOCK 획득  ← 잠금 키가 문제
④ (좌석이 있으면) 좌석 재확인
⑤ (죽은 코드) MAX_PURCHASE_LIMIT 재확인
⑥ 회원권 INSERT → 예약 INSERT
⑦ INSERT 후 정원 체크 (count > max 이면 예외)
⑧ Bootpay verify / confirm (결제)
⑨ COMMIT → RELEASE_LOCK
```

**결함 1 — 잠금 키가 정원 검사를 직렬화하지 못함 (핵심 원인)**

| 조건 | 기존 잠금 키 | 문제 |
|---|---|---|
| 좌석 있음 | `purchase_membership_seat:{APT}:{TYPE}:{좌석}:{시작일}:{종료일}` | 좌석·기간별로 키가 달라, 이용기간이 겹치는데 키가 다른 조합은 직렬화 안 됨 |
| 좌석 없음 (GX 등 정원제) | `purchase_membership_user:{APT}:{회원권}:{동}:{호}:{이름}` | **사용자별 키** — 서로 다른 사용자는 서로 다른 잠금을 잡고 동시에 진입 |

정원(`PURCHASABLE_MAX_COUNT`) 검사는 회원권 전체 구매 건수를 세는데,
잠금이 사용자 단위여서 서로 다른 사용자의 요청이 전부 잠금을 통과했다.

**결함 2 — 잠금 획득 후 정원 재확인이 없음**

잠금 획득 후 재확인은 좌석(④)만 있었고, 정원 재확인은 없었다.
① 사전 체크는 잠금 밖(트랜잭션 시작 전)이라 동시 요청이 모두 통과한다.

**결함 3 — INSERT 후 정원 체크(⑦)는 스냅샷 때문에 무력**

InnoDB REPEATABLE READ에서 트랜잭션 A의 `SELECT COUNT(*)`는
"커밋된 행 + A 자신의 미커밋 INSERT"만 보인다.
A·B가 동시에 INSERT하면 서로의 미커밋 행이 보이지 않아
양쪽 모두 `count = 기존 + 1(자기 것)`로 계산되어 통과 → 둘 다 COMMIT → 정원 초과.

**결함 4 — MAX_PURCHASE_LIMIT 재확인 블록이 죽은 코드**

잠금 후의 구매 개수 재확인 블록은 `if (nMaxPurchaseLimit > 0)` 조건인데,
`nMaxPurchaseLimit` 파싱이 INSERT **이후**(STEP 4-2)에 있어서
재확인 시점에는 항상 0 → 블록이 한 번도 실행되지 않았다.

### 2-2. reservation_community_schedule (커뮤니티 예약)

```
① 중복/시간충돌 사전 검사 (오토커밋 모드, 잠금 없음)
② setAutoCommit(false)
③ 곧바로 예약 INSERT      ← 재확인 없음
④ 회원권 발급/연결
⑤ Bootpay verify / confirm
⑥ COMMIT
```

- **잠금이 전혀 없음.** GET_LOCK 미사용.
- 사전 검사(①)가 트랜잭션 밖이라, 두 요청이 밀리초 차이로 들어오면
  둘 다 `COUNT = 0`을 보고 둘 다 INSERT → 같은 자리·같은 시간대 중복 예약.
- INSERT 후 재검증도 없음.

참고: `reservation_guestroom`(게스트하우스)에는 객실 단위
GET_LOCK(`reservation_guestroom:{APT}:{객실}`) + 잠금 후 날짜 중복 재확인이
이미 구현되어 있었다. 이번 수정은 그 패턴을 나머지 두 SID에 확장한 것이다.

## 3. 수정 내용

### 3-1. purchase_membership

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| 잠금 키 | 좌석별 / 사용자별 (2종) | **시설 단위 단일 키** `purchase_membership:{APT_CODE}:{COMMUNITY_TYPE}` |
| GET_LOCK 대기 | 5초 | 10초 |
| 잠금 후 정원 재확인 | 없음 | **추가** — 마감 시 `"이용권이 마감되었습니다."` 예외 → INSERT/결제 진입 차단, rollback |
| MAX_PURCHASE_LIMIT 파싱 | INSERT 이후 | **잠금 이전으로 이동** → 잠금 후 구매 개수 재확인 블록 활성화 |
| 마감 안내 메시지 | 잠금 처리 catch에서 일반 오류로 덮임 | 마감/처리중/개수초과 메시지는 사용자에게 그대로 전달 |

시설 단위 키를 선택한 이유:
- 좌석 마감 검사 범위 = 시설 전체(`APT_CODE + COMMUNITY_TYPE + PLACE`, 회원권 무관)
- 정원 마감 검사 범위 = 회원권 전체(시설에 포함)
- 두 검사 범위를 모두 포함하는 최소 단위가 시설이며,
  구버전 MySQL의 "세션당 네임드락 1개" 제약에서도 안전하다.

수정 후 처리 순서:

```
① 정원 사전 체크 (빠른 실패용, 유지)
② setAutoCommit(false)
③ GET_LOCK('purchase_membership:{APT}:{TYPE}', 10)   ← 시설 단위 직렬화
④ 좌석 재확인 (기존 유지)
⑤ 정원(PURCHASABLE_MAX_COUNT) 재확인   ← 신규. 마감이면 예외 → rollback
⑥ 구매 개수(MAX_PURCHASE_LIMIT) 재확인 ← 조기 파싱으로 활성화
⑦ 회원권 INSERT → 예약 INSERT
⑧ INSERT 후 정원 체크 (백스톱으로 유지)
⑨ Bootpay verify / confirm
⑩ COMMIT → RELEASE_LOCK → autoCommit 원복
   (실패 시: rollback → 결제 보상취소 → RELEASE_LOCK)
```

핵심: ③~⑩ 전 구간이 잠금 아래에서 실행되고, **잠금은 COMMIT(또는 rollback) 후에 해제**되므로
다음 대기 요청의 재확인 쿼리는 반드시 직전 요청의 확정 결과를 본다.
(재확인 SELECT가 트랜잭션의 첫 InnoDB 읽기이므로 스냅샷도 잠금 획득 이후에 생성된다.)

### 3-2. reservation_community_schedule

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| 잠금 | 없음 | **시설+날짜 단위** `reservation_schedule:{APT_CODE}:{COMMUNITY_TYPE}:{DATE}`, 대기 10초 |
| 잠금 후 재확인 | 없음 | **사전 검사와 동일한 중복/시간충돌 쿼리 재실행** — 충돌 시 `"죄송합니다. 선택하신 자리는 이미 예약되었습니다..."` 예외 → INSERT/결제 진입 차단, rollback |
| 잠금 해제 | — | COMMIT 직후 + finally(rollback 이후)에서 RELEASE_LOCK |

수정 후 처리 순서:

```
① 중복/시간충돌 사전 검사 (빠른 실패용, 유지)
② setAutoCommit(false)
③ GET_LOCK('reservation_schedule:{APT}:{TYPE}:{날짜}', 10)
④ 중복/시간충돌 재확인   ← 신규. 마감이면 예외 → rollback
⑤ 예약 INSERT → 회원권 발급/연결
⑥ Bootpay verify / confirm
⑦ COMMIT → RELEASE_LOCK → autoCommit 원복
   (실패 시: rollback → 결제 보상취소 → finally에서 RELEASE_LOCK)
```

## 4. 수정 후 동작 (마감 시나리오)

정원 20명 강습에 21번째~N번째 요청이 동시에 들어온 경우:

1. 첫 요청이 시설 잠금을 잡고 구매(결제 포함)를 완료·COMMIT 후 잠금 해제.
2. 대기하던 다음 요청이 잠금을 획득 → 정원 재확인에서 `20 >= 20` → 예외
   → **INSERT 없음, Bootpay verify/confirm 진입 없음**, rollback
   → 앱에 `"이용권이 마감되었습니다."` 응답.
3. 잠금 대기 10초를 초과한 요청은
   `"회원권 구매가 처리 중입니다. 잠시 후 다시 시도해주세요."`로 안전하게 실패.

예약도 동일한 방식으로, 마감된 자리·시간대는 INSERT와 결제 모두 차단된다.

## 5. 전제 및 운영 참고

- `GET_LOCK`은 **MySQL 서버 단위** 네임드락이다. 현재처럼 DB가 한 대인 구조에서 유효하며,
  DB를 다중화(리플리카에 쓰기, 샤딩 등)하면 다른 직렬화 수단이 필요하다.
- Bootpay verify/confirm(HTTP)이 기존 설계대로 잠금 구간 안에 있으므로
  같은 시설의 구매/같은 시설·날짜의 예약은 순차 처리된다.
  오픈런 상황에서 뒤 요청은 최대 10초 대기 후 재시도 안내를 받는다.
- INSERT 후 정원 체크(⑧)와 최종 좌석 검증은 백스톱으로 유지했다.
- 검증: 추가 블록의 괄호 균형 확인 및 신규 Java 코드 스텁 하네스 `javac` 컴파일 통과.

## 6. 이번 범위 밖 관찰 사항 (권고)

수정 대상은 아니지만 코드 파악 중 확인된 사항:

1. **SQL 인젝션 위험**: 다수 쿼리가 파라미터를 문자열 연결로 조립한다.
   (예: `strUserId`, `strSeat`, `strReservationUserName` 등)
   PreparedStatement 바인딩(`?`)으로 단계적 전환을 권고.
2. **자격증명 하드코딩**: `apt_global.jsp`에 DB 접속 정보와 Bootpay Private Key가
   평문으로 포함되어 있다. 설정 파일/환경변수 분리 및 키 회전을 권고.
3. `ORDER BY ... DESC LIMIT 1`로 방금 INSERT한 PK를 되찾는 패턴은
   잠금 직렬화 덕에 현재는 안전하지만, `getGeneratedKeys()` 사용이 더 견고하다.
