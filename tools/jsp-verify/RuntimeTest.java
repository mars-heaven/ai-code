import java.lang.reflect.*;
import java.io.*;
import java.sql.*;
import java.util.*;
import java.text.SimpleDateFormat;

/** 리팩터링으로 도입한 공통 헬퍼가 원본 인라인 로직과 같은 결과를 내는지 실행 비교 */
public class RuntimeTest {

	static final byte RECORD_DEL = 0x1A, COLUMN_DEL = 0x1C;
	static final String S_CHARSET = "UTF-8";
	static int pass = 0, fail = 0;

	static void check(String label, Object exp, Object act) {
		boolean ok = exp == null ? act == null : exp.equals(act);
		if (ok) pass++;
		else { fail++; System.out.println("  [FAIL] " + label + "\n         원본=" + exp + "\n         신규=" + act); }
	}

	static String hex(byte[] b) { StringBuilder sb = new StringBuilder(); for (byte x : b) sb.append(String.format("%02x", x)); return sb.toString(); }

	static Method m(Class<?> c, String name, int argc) {
		for (Method x : c.getDeclaredMethods())
			if (x.getName().equals(name) && x.getParameterCount() == argc) { x.setAccessible(true); return x; }
		throw new RuntimeException("no method " + name + "/" + argc + " in " + c.getName());
	}

	/** 컬럼 값 배열로 동작하는 가짜 ResultSet */
	static ResultSet fakeRs(final String[][] rows) {
		final int[] cur = { -1 };
		final int cols = rows.length == 0 ? 0 : rows[0].length;
		InvocationHandler meta = (p, mm, args) -> {
			if (mm.getName().equals("getColumnCount")) return cols;
			return null;
		};
		final ResultSetMetaData md = (ResultSetMetaData) Proxy.newProxyInstance(
				RuntimeTest.class.getClassLoader(), new Class[] { ResultSetMetaData.class }, meta);
		InvocationHandler h = (p, mm, args) -> {
			String n = mm.getName();
			if (n.equals("next")) { cur[0]++; return cur[0] < rows.length; }
			if (n.equals("getMetaData")) return md;
			if (n.equals("getString")) return rows[cur[0]][((Integer) args[0]) - 1];
			if (n.equals("close")) return null;
			if (n.equals("toString")) return "fakeRs";
			if (n.equals("hashCode")) return 1;
			if (n.equals("equals")) return p == args[0];
			return null;
		};
		return (ResultSet) Proxy.newProxyInstance(
				RuntimeTest.class.getClassLoader(), new Class[] { ResultSet.class }, h);
	}

	public static void main(String[] a) throws Exception {
		Class<?> cn = Class.forName("New_apt_community_facility");
		Object in = cn.getDeclaredConstructor().newInstance();

		System.out.println("=== A. 출력 헬퍼 바이트 동등성 ===");
		// A-1 : writeColumn / writeText / writeRecord
		String[] vals = { "abc", "", null, "한글값", "1", "0" };
		ByteArrayOutputStream expected = new ByteArrayOutputStream();
		for (String v : vals) {                              // 원본 패턴
			String d = v == null ? "" : v;
			expected.write(d.getBytes(S_CHARSET));
			expected.write(COLUMN_DEL);
		}
		expected.write(RECORD_DEL);
		ByteArrayOutputStream actual = new ByteArrayOutputStream();
		Method wc = m(cn, "writeColumn", 2), wr = m(cn, "writeRecord", 1);
		for (String v : vals) wc.invoke(in, actual, v);
		wr.invoke(in, actual);
		check("writeColumn/writeRecord 바이트", hex(expected.toByteArray()), hex(actual.toByteArray()));

		// A-2 : writeResultSet vs 원본 전체 덤프 루프
		String[][] rows = { { "1", "메뉴A", null }, { "2", "", "설명" }, { "3", "메뉴C", "0" } };
		ResultSet rs1 = fakeRs(rows), rs2 = fakeRs(rows);
		ByteArrayOutputStream expDump = new ByteArrayOutputStream();
		ResultSetMetaData md = rs1.getMetaData();
		for (int r = 0; rs1.next(); r++) {                   // 원본 루프 그대로
			for (int c = 1; c <= md.getColumnCount(); c++) {
				String d = rs1.getString(c);
				if (d == null) d = "";
				expDump.write(d.getBytes(S_CHARSET));
				expDump.write(COLUMN_DEL);
			}
			expDump.write(RECORD_DEL);
		}
		ByteArrayOutputStream actDump = new ByteArrayOutputStream();
		Object nRows = m(cn, "writeResultSet", 2).invoke(in, actDump, rs2);
		check("writeResultSet 바이트", hex(expDump.toByteArray()), hex(actDump.toByteArray()));
		check("writeResultSet 행 수", 3, nRows);

		// A-3 : returnData 길이헤더 + 본문 (isDev()=true 이므로 평문 경로)
		byte[] payload = "가나다ABC".getBytes(S_CHARSET);
		ByteArrayOutputStream src = new ByteArrayOutputStream();
		src.write(payload);
		final ByteArrayOutputStream sink = new ByteArrayOutputStream();
		OutputStream os = new OutputStream() {
			public void write(int b) { sink.write(b); }
			public void write(byte[] b, int off, int len) { sink.write(b, off, len); }
		};
		m(cn, "returnData", 3).invoke(in, null, src, os);
		ByteArrayOutputStream expSend = new ByteArrayOutputStream();
		int len = payload.length;
		expSend.write(new byte[] { (byte) ((len & 0xff000000) / 0x1000000), (byte) ((len & 0x00ff0000) / 0x10000),
				(byte) ((len & 0x0000ff00) / 0x100), (byte) (len & 0x000000ff) });
		expSend.write(payload);
		check("returnData 전송 바이트", hex(expSend.toByteArray()), hex(sink.toByteArray()));

		System.out.println("=== B. 운영시간(OPERATION_HOURS) 파싱 ===");
		String json = "{\"WEEKDAY\":{\"start\":\"0600\",\"end\":\"2200\"},\"WEEKEND\":{\"start\":\"0800\",\"end\":\"2000\"}}";
		Method range = m(cn, "getOperationTimeRange", 2);
		Method text = m(cn, "getOperationTimeText", 2);
		Method optime = m(cn, "getOperationTime", 2);
		Method extract = m(cn, "extractValue", 3);
		String[] dates = { "20260824", "20260825", "20260829", "20260830", null };   // 월/화/토/일/오늘
		for (String d : dates) {
			String[] got = (String[]) range.invoke(in, json, d);
			// 원본 인라인 로직 재현
			Calendar cal = Calendar.getInstance();
			if (d != null) cal.setTime(new SimpleDateFormat("yyyyMMdd").parse(d));
			int dow = cal.get(Calendar.DAY_OF_WEEK);
			String key = (dow == Calendar.SATURDAY || dow == Calendar.SUNDAY) ? "WEEKEND" : "WEEKDAY";
			String es = (String) extract.invoke(in, json, key, "start");
			String ee = (String) extract.invoke(in, json, key, "end");
			check("운영시간 start(" + d + ")", es, got[0]);
			check("운영시간 end(" + d + ")", ee, got[1]);
			check("운영시간 텍스트(" + d + ")",
					es.substring(0, 2) + ":" + es.substring(2, 4) + " ~ " + ee.substring(0, 2) + ":" + ee.substring(2, 4),
					text.invoke(in, json, d));
			check("운영시간 HHmmHHmm(" + d + ")", es + ee, optime.invoke(in, json, d));
		}
		check("운영시간 빈 JSON", "", text.invoke(in, "", "20260825"));
		check("운영시간 null JSON", "", text.invoke(in, null, "20260825"));

		System.out.println("=== C. 휴일 파싱/판정 ===");
		Method chf = m(cn, "createHolidayFromResultSet", 1);
		Method todayH = m(cn, "isTodayHoliday", 4);
		Method tempH = m(cn, "isTodayTempHoliday", 2);
		String[][] hrows = {
			{ "0", "1", null, "0", null },      // 매주 월요일
			{ "6", null, "15", "0", "" },       // 매달 15일
			{ "3", "2", null, "3", "20260825" },// 임시휴무(특정일)
			{ "7", null, null, "0", null },     // 매일
			{ null, "", "", "", null },         // 값 없음
		};
		ResultSet hrs = fakeRs(hrows);
		int idx = 0;
		while (hrs.next()) {
			Object h = chf.invoke(null, hrs);
			// 원본 파싱 로직 재현
			String[] r = hrows[idx];
			int rt = (r[0] != null && !r[0].isEmpty()) ? Integer.parseInt(r[0]) : -1;
			int dw = (r[1] != null && !r[1].isEmpty()) ? Integer.parseInt(r[1]) : -1;
			int dm = (r[2] != null && !r[2].isEmpty()) ? Integer.parseInt(r[2]) : -1;
			int st = (r[3] != null && !r[3].isEmpty()) ? Integer.parseInt(r[3]) : -1;
			String sd = r[4] == null ? "" : r[4];
			Class<?> hc = h.getClass();
			Field f;
			f = hc.getDeclaredField("repeatType"); f.setAccessible(true); check("Holiday.repeatType[" + idx + "]", rt, f.get(h));
			f = hc.getDeclaredField("dayOfWeek"); f.setAccessible(true); check("Holiday.dayOfWeek[" + idx + "]", dw, f.get(h));
			f = hc.getDeclaredField("dayOfMonth"); f.setAccessible(true); check("Holiday.dayOfMonth[" + idx + "]", dm, f.get(h));
			f = hc.getDeclaredField("specificType"); f.setAccessible(true); check("Holiday.specificType[" + idx + "]", st, f.get(h));
			f = hc.getDeclaredField("specialDay"); f.setAccessible(true); check("Holiday.specialDay[" + idx + "]", sd, f.get(h));

			// 판정 로직 : 월요일(dayOfWeek=1), 15일, 3주차 기준
			boolean expHoliday;
			switch (rt) {
				case 0: expHoliday = (dw == 1); break;
				case 1: case 2: case 3: case 4: case 5: expHoliday = (dw == 1 && rt == 3); break;
				case 6: expHoliday = (dm == 15); break;
				case 7: expHoliday = true; break;
				default: expHoliday = false;
			}
			check("isTodayHoliday[" + idx + "]", expHoliday, todayH.invoke(null, h, 1, 15, 3));
			check("isTodayTempHoliday[" + idx + "]", (st == 3 && sd.contentEquals("20260825")), tempH.invoke(null, h, "20260825"));
			idx++;
		}

		System.out.println("=== D. 운영중 판정(isOperatingNow) : 원본 조건식과 전수 비교 ===");
		Method oper = m(cn, "isOperatingNow", 3);
		int mismatch = 0, cases = 0;
		int[] samples = { 0, 1, 559, 600, 900, 1200, 1800, 2200, 2359, 2400 };
		for (int s : samples) for (int e : samples) for (int now : samples) {
			boolean expct = (s <= e && s < now && e > now) || (s > e && (now > s || now < e));
			boolean got = (Boolean) oper.invoke(null, s, e, now);
			cases++;
			if (expct != got) { mismatch++; System.out.println("  [FAIL] isOperatingNow(" + s + "," + e + "," + now + ") 원본=" + expct + " 신규=" + got); }
		}
		if (mismatch == 0) { pass++; System.out.println("  OK " + cases + "가지 조합 모두 일치"); } else fail += mismatch;

		System.out.println("\n결과: 통과 " + pass + " / 실패 " + fail);
		if (fail > 0) System.exit(1);
	}
}
