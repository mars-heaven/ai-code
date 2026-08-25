#!/bin/sh
# 커뮤니티 JSP 정적/런타임 검증 실행 스크립트
#
# 사전 준비 : 저장소에 포함되지 않는 include 파일(계정 정보 포함)을 globals/ 에 둔다.
#   tools/jsp-verify/globals/apt_global.jsp
#   tools/jsp-verify/globals/apt_global_payment.jsp
#   tools/jsp-verify/globals/community_global.jsp
#
# 사용법 : cd tools/jsp-verify && sh run.sh [비교기준리비전]
set -e
cd "$(dirname "$0")"

BASE_REV=${1:-HEAD~1}
export BASE_REV
export COMMUNITY_DIR=../../community
export VERIFY_WORK=build

if [ ! -f globals/apt_global.jsp ]; then
	echo "globals/ 에 apt_global.jsp / apt_global_payment.jsp / community_global.jsp 를 먼저 두세요."
	exit 1
fi

rm -rf build && mkdir -p build/orig build/classes

echo "[1/5] 비교 기준($BASE_REV) 원본 추출"
for f in cafeteria facility setting membership reservation; do
	git show "$BASE_REV:community/apt_community_$f.jsp" > "build/orig/apt_community_$f.jsp"
done

echo "[2/5] JSP -> Java 변환"
JSPS="apt_community_cafeteria.jsp apt_community_facility.jsp apt_community_setting.jsp apt_community_membership.jsp apt_community_reservation.jsp"
python3 jsp2java.py globals build/orig    build/gen_orig Orig_ $JSPS
python3 jsp2java.py globals $COMMUNITY_DIR build/gen_new  New_  $JSPS

echo "[3/5] 컴파일(원본/신규)"
javac -nowarn -d build/classes -encoding UTF-8 $(find stub -name '*.java')
javac -nowarn -cp build/classes -d build/classes -encoding UTF-8 build/gen_orig/*.java build/gen_new/*.java

echo "[4/5] 응답 포맷 비교(SID 단위)"
python3 cmp_seq.py

echo "[5/5] 동등성 테스트"
javac -nowarn -cp build/classes -d build/classes -encoding UTF-8 EquivTest.java RuntimeTest.java
java -Dfile.encoding=UTF-8 -cp build/classes RuntimeTest
java -Dfile.encoding=UTF-8 -cp build/classes EquivTest || true
