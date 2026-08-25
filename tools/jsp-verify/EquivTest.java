import java.lang.reflect.*;
import java.io.*;
import java.util.*;

/** 원본 JSP 클래스와 리팩터링본 JSP 클래스의 동명 메서드를 같은 입력으로 호출해 결과를 비교한다. */
public class EquivTest {

	static int pass = 0, fail = 0;

	static void check(String label, Object expected, Object actual) {
		boolean ok = (expected == null) ? actual == null : expected.equals(actual);
		if (ok) { pass++; }
		else { fail++; System.out.println("  [FAIL] " + label + "\n         원본=" + expected + "\n         신규=" + actual); }
	}

	static Method find(Class<?> c, String name, int argc) {
		for (Method m : c.getDeclaredMethods())
			if (m.getName().equals(name) && m.getParameterCount() == argc) { m.setAccessible(true); return m; }
		return null;
	}

	static void compare(String cls, String method, Object[][] cases) throws Exception {
		Class<?> co = Class.forName("Orig_" + cls), cn = Class.forName("New_" + cls);
		Object io = co.getDeclaredConstructor().newInstance(), in = cn.getDeclaredConstructor().newInstance();
		for (Object[] args : cases) {
			Method mo = find(co, method, args.length), mn = find(cn, method, args.length);
			if (mo == null) { System.out.println("  [SKIP] " + cls + "." + method + " 원본에 없음"); return; }
			if (mn == null) { fail++; System.out.println("  [FAIL] " + cls + "." + method + " 신규에 없음(공통모듈 include 확인)"); return; }
			Object ro, rn;
			try { ro = mo.invoke(io, args); } catch (InvocationTargetException e) { ro = "EX:" + e.getCause().getClass().getSimpleName(); }
			try { rn = mn.invoke(in, args); } catch (InvocationTargetException e) { rn = "EX:" + e.getCause().getClass().getSimpleName(); }
			check(cls + "." + method + Arrays.toString(args), ro, rn);
		}
	}

	public static void main(String[] a) throws Exception {
		System.out.println("=== 1. 문자열/날짜 유틸 동등성 ===");
		compare("apt_community_cafeteria", "formatDate", new Object[][] {
			{"20240705"}, {"20260101"}, {"20251231"} });
		compare("apt_community_cafeteria", "formatTime", new Object[][] {
			{"06002200"}, {"09301830"}, {"00002400"} });
		compare("apt_community_cafeteria", "parseToHHmmHHmm", new Object[][] {
			{"06:00 ~ 22:00"}, {"09:30~18:30"} });
		compare("apt_community_cafeteria", "formatPhoneNumber", new Object[][] {
			{"01012345678"}, {"0212345678"}, {null} });
		compare("apt_community_cafeteria", "isEscapeChar", new Object[][] {
			{"it's"}, {"back\\slash"}, {""}, {null}, {"plain"} });
		compare("apt_community_membership", "formatDateTime", new Object[][] {
			{"20260825143000"}, {"2026082514"}, {""}, {null} });
		compare("apt_community_reservation", "isTimeWithinRange", new Object[][] {
			{"1200", "0900", "1800"}, {"0800", "0900", "1800"}, {"1800", "0900", "1800"} });
		compare("apt_community_setting", "defaultIfNull", new Object[][] {
			{null, "D"}, {"", "D"}, {"  ", "D"}, {"v", "D"} });

		System.out.println("=== 2. 공통 쿼리 문자열 ===");
		compare("apt_community_setting", "getHolidaysQuery", new Object[][] { {"100452", "03"} });
		compare("apt_community_reservation", "getHolidaysQuery", new Object[][] { {"100452", "03"} });
		compare("apt_community_membership", "getTimeQuery", new Object[][] { {"100452", "03"} });
		compare("apt_community_reservation", "getTimeQuery", new Object[][] { {"100452", "03"} });
		compare("apt_community_setting", "getShorteningQuery", new Object[][] { {"100452", "03"} });

		System.out.println("=== 3. JSON 추출(extractValue) ===");
		String opJson = "{\"WEEKDAY\":{\"start\":\"0600\",\"end\":\"2200\"},\"WEEKEND\":{\"start\":\"0800\",\"end\":\"2000\"}}";
		compare("apt_community_facility", "extractValue", new Object[][] {
			{opJson, "WEEKDAY", "start"}, {opJson, "WEEKEND", "end"},
			{opJson, "HOLIDAY", "start"}, {opJson, "WEEKDAY", "none"}, {"not json", "WEEKDAY", "start"} });

		System.out.println("=== 4. 시간 간격 목록(getTimeIntervals) ===");
		compare("apt_community_setting", "getTimeIntervals", new Object[][] {
			{"0600", "2200", 30, "0"}, {"0900", "1200", 1, "1"}, {"0600", "0600", 30, "0"} });

		System.out.println("\n결과: 통과 " + pass + " / 실패 " + fail);
		if (fail > 0) System.exit(1);
	}
}
