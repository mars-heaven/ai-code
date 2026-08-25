# 커뮤니티 JSP 검증 하네스

`community/apt_community_*.jsp` 를 **실제 Java 컴파일**로 검증하고, 리팩터링 전후의
응답 포맷과 공통 함수 동작이 같은지 비교하는 도구다.

## 구성

| 파일 | 역할 |
|---|---|
| `jsp2java.py` | JSP의 `<%@ include %>` 를 인라인하고 선언부/스크립틀릿을 하나의 Java 클래스로 변환 |
| `stub/` | 컴파일에 필요한 외부 라이브러리 최소 스텁(servlet, json-simple, apache-http, jackson, IssacWeb 등) |
| `cmp_seq.py` | SID 블록별로 응답 출력 순서(값 / 컬럼구분자 / 레코드구분자)를 기준 리비전과 비교 |
| `cmp_output.py` | SID 블록별 출력 개수 비교(요약용) |
| `check_braces.py` | 스크립틀릿 중괄호 균형 검사 |
| `EquivTest.java` | 원본 클래스와 신규 클래스의 동명 메서드를 같은 입력으로 호출해 결과 비교 |
| `RuntimeTest.java` | 출력 헬퍼 바이트, 운영시간 파싱, 휴일 파싱/판정, 운영중 판정을 원본 로직과 실행 비교 |
| `run.sh` | 위 과정을 순서대로 실행 |

## 사전 준비

include 대상 전역 파일은 DB 계정 정보와 결제 키를 포함하므로 저장소에 넣지 않는다.
검증할 때만 아래 위치에 복사한다.

```
tools/jsp-verify/globals/apt_global.jsp
tools/jsp-verify/globals/apt_global_payment.jsp
tools/jsp-verify/globals/community_global.jsp
```

## 실행

```sh
cd tools/jsp-verify
sh run.sh            # 기준 리비전 기본값 HEAD~1
sh run.sh <리비전>    # 원하는 리비전과 비교
```

`build/` 아래에 변환 결과와 클래스가 생성된다.

## 판정 기준

- 컴파일 : 원본과 신규 모두 오류 0 이어야 한다.
- `cmp_seq.py` : 차이로 남는 항목은 아래 두 가지뿐이어야 한다.
  - `-VAL errMsg` : catch 블록의 에러 응답이 `sendError()` 로 옮겨간 것
  - `DUMPLOOP/VAL/DEL/REC → DUMP` : 전체 행 덤프 루프가 `writeResultSet()` 로 바뀐 것
- `RuntimeTest` / `EquivTest` : 실패 0 (단, 의도적으로 통일한 공통 쿼리 3건은 EquivTest 에서 차이로 보고된다)
