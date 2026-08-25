<%--
	=========================================================================
	커뮤니티 서버 응답(JSP) 공통 모듈
	-------------------------------------------------------------------------
	apt_community_facility / cafeteria / setting / reservation / membership
	에서 공통으로 사용하던 기능을 한곳으로 모은 모듈이다.

	[사용법]
		<%@ include file="./apt_global.jsp" %>
		<%@ include file="../global/community_global.jsp" %>
		<%@ include file="./apt_community_common.jsp" %>

		- apt_global.jsp / community_global.jsp 의 상수(S_CHARSET, COLUMN_DEL,
		  RECORD_DEL, WEEKLY_REPEAT ...)를 사용하므로 반드시 그 뒤에 include 한다.
		- 이 모듈은 상수 파일을 직접 include 하지 않는다.(중복 선언 방지)

	[구성]
		1. 요청 파라미터
		2. 응답 전송(빌리진아이 포맷)
		3. 출력 스트림 헬퍼
		4. DB 자원 헬퍼
		5. 문자열 / 날짜 / 시간 유틸
		6. 운영시간(OPERATION_HOURS) 유틸
		7. 공통 데이터 클래스(Holiday / Shortening / Reservation)
		8. 휴일 / 예약 가능 여부 판단
		9. 공통 조회 쿼리 및 조회 함수
	   10. 외부 API 호출
	=========================================================================
--%>
<%@ page import="villizine.util.IssacWeb" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.io.ByteArrayOutputStream" %>
<%@ page import="java.io.OutputStream" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.FileWriter" %>
<%@ page import="java.io.PrintWriter" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.ParseException" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Random" %>
<%@ page import="java.util.TimeZone" %>
<%@ page import="java.util.UUID" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="org.json.simple.parser.JSONParser" %>

<%!

	// =====================================================================
	// 1. 요청 파라미터
	// =====================================================================

	/**
	 * 요청 파라미터 조회.(암호화 사용 페이지)
	 * 개발서버는 request 에서, 운영서버는 IssacWeb 복호화 결과에서 읽는다.
	 */
	public String getRequestParam(IssacWeb issacweb, HttpServletRequest request, String strKey) {
		if(strKey == null || strKey.contentEquals("")) {
			printLog("A", "getRequestParam strKey null");
			return "";
		}

		String strValue = "";
		if(issacweb == null || isDev() == true) {
			strValue = request.getParameter(strKey);
			if(strValue == null) strValue = "";
			try {
				//개발서버만 UTF-8로 한번더 전환
				strValue = new String(strValue.getBytes("8859_1"), S_CHARSET);
			} catch (Exception e) {
				e.printStackTrace();
			}
		} else {
			strValue = issacweb.getParameter(strKey);
			if(strValue == null) strValue = "";
		}

		return strValue;
	}

	/**
	 * 요청 파라미터 조회.(암호화 미사용 페이지 - 항상 request 에서 읽는다)
	 */
	public String getRequestParam(HttpServletRequest request, String strKey) {
		return getRequestParam(null, request, strKey);
	}


	// =====================================================================
	// 2. 응답 전송(빌리진아이 포맷 : 데이터길이(4byte) + 데이터)
	// =====================================================================

	/**
	 * 전송 데이터 생성. issacweb 이 없거나 개발서버면 평문, 그 외에는 암호화한다.
	 */
	private byte[] toSendData(IssacWeb issacweb, ByteArrayOutputStream baOutStream) throws IOException {
		if(issacweb == null || isDev() == true) {
			return baOutStream.toByteArray();
		}

		if(baOutStream.size() == 0) {
			// 빈값 처리 - 암호화 대상이 비어있으면 공백 레코드를 넣는다.
			baOutStream.write(" ".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(RECORD_DEL);
		}

		ByteArrayOutputStream baEncryptOutStream = new ByteArrayOutputStream();
		baEncryptOutStream.write(issacweb.getEncryptData(baOutStream, S_CHARSET));

		return baEncryptOutStream.toByteArray();
	}

	/**
	 * 데이터길이(4byte) 헤더를 붙여 클라이언트로 전송한다.
	 */
	private void writeSendData(byte[] baSendData, OutputStream outStream) throws IOException {
		int nSendDataLength = baSendData.length;

		byte[] baSendDataLength = new byte[4];
		baSendDataLength[0] = (byte)((nSendDataLength & 0xff000000) / 0x1000000);
		baSendDataLength[1] = (byte)((nSendDataLength & 0x00ff0000) / 0x10000);
		baSendDataLength[2] = (byte)((nSendDataLength & 0x0000ff00) / 0x100);
		baSendDataLength[3] = (byte) (nSendDataLength & 0x000000ff);

		outStream.write(baSendDataLength, 0, 4);
		outStream.write(baSendData, 0, nSendDataLength);
		outStream.flush();
		outStream.close();
	}

	/**
	 * 빌리진아이 데이터 전송 포맷[ 데이터길이(4자리) + 데이터 ] 에 맞게 조합한 후, 클라이언트로 전송..
	 */
	public void returnData(IssacWeb issacweb, ByteArrayOutputStream baOutStream, OutputStream outStream) {
		if(baOutStream == null || outStream == null) {
			return;
		}

		try {
			writeSendData(toSendData(issacweb, baOutStream), outStream);
		} catch (Exception e) {
			try {
				baOutStream.write(("Exceptino Msg = " + e.getMessage()).getBytes(S_CHARSET));
				writeSendData(toSendData(issacweb, baOutStream), outStream);
			} catch (Exception ex) {
			}
		}
	}

	/**
	 * 암호화를 사용하지 않는 페이지용 전송.
	 */
	public void returnData(ByteArrayOutputStream baOutStream, OutputStream outStream) {
		returnData(null, baOutStream, outStream);
	}

	/**
	 * 예외 발생 시 에러 메시지를 응답으로 내려준다.(각 페이지의 catch 블록 공통)
	 */
	public void sendError(IssacWeb issacweb, Exception e, OutputStream outStream) {
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		try {
			String errMsg = "Exception Msg = " + e.getMessage();
			baOutStream.write(errMsg.getBytes(S_CHARSET));
			printLog("A", " ###### errMsg  = #####" + errMsg);
		} catch (Exception ignore) {
		}
		returnData(issacweb, baOutStream, outStream);
	}

	public void sendError(Exception e, OutputStream outStream) {
		sendError(null, e, outStream);
	}


	// =====================================================================
	// 3. 출력 스트림 헬퍼
	// =====================================================================

	public String nvl(String strValue) {
		return strValue == null ? "" : strValue;
	}

	public String nvl(String strValue, String strDefault) {
		return (strValue == null || strValue.contentEquals("")) ? strDefault : strValue;
	}

	/** 컬럼 1개 출력(null 은 빈 문자열로 처리) */
	public void writeColumn(ByteArrayOutputStream baOutStream, String strValue) throws IOException {
		baOutStream.write(nvl(strValue).getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
	}

	/** 구분자 없이 값만 출력(null 은 빈 문자열로 처리) */
	public void writeText(ByteArrayOutputStream baOutStream, String strValue) throws IOException {
		baOutStream.write(nvl(strValue).getBytes(S_CHARSET));
	}

	/** 컬럼 구분자만 출력(값을 여러 조건으로 나눠 쓴 뒤 마무리할 때 사용) */
	public void writeColumnDel(ByteArrayOutputStream baOutStream) throws IOException {
		baOutStream.write(COLUMN_DEL);
	}

	/** 레코드 구분자 출력 */
	public void writeRecord(ByteArrayOutputStream baOutStream) throws IOException {
		baOutStream.write(RECORD_DEL);
	}

	/** 컬럼 여러개 출력(레코드 구분자 없음) */
	public void writeColumns(ByteArrayOutputStream baOutStream, String[] arrValues) throws IOException {
		if(arrValues == null) return;
		for(int nCol = 0; nCol < arrValues.length; nCol++) {
			writeColumn(baOutStream, arrValues[nCol]);
		}
	}

	/** 1개 레코드 출력(컬럼 + 레코드 구분자) */
	public void writeRow(ByteArrayOutputStream baOutStream, String[] arrValues) throws IOException {
		writeColumns(baOutStream, arrValues);
		writeRecord(baOutStream);
	}

	/** 현재 행의 모든 컬럼 출력 */
	public void writeCurrentRow(ByteArrayOutputStream baOutStream, ResultSet rs, int nColumnCount) throws Exception {
		for(int nCol = 1; nCol <= nColumnCount; nCol++) {
			writeColumn(baOutStream, rs.getString(nCol));
		}
	}

	/**
	 * ResultSet 의 전체 행/열을 그대로 출력한다.(가장 많이 반복되던 패턴)
	 * @return 출력한 행 수
	 */
	public int writeResultSet(ByteArrayOutputStream baOutStream, ResultSet rs) throws Exception {
		if(rs == null) return 0;

		ResultSetMetaData rsMetaData = rs.getMetaData();
		int nColumnCount = rsMetaData.getColumnCount();

		int nRow = 0;
		for(; rs.next(); nRow++) {
			writeCurrentRow(baOutStream, rs, nColumnCount);
			writeRecord(baOutStream);
		}
		return nRow;
	}


	// =====================================================================
	// 4. DB 자원 헬퍼
	// =====================================================================

	/** 운영서버이면 암호화 객체 생성, 개발서버이면 null */
	public IssacWeb createIssacWeb(HttpServletRequest request) {
		if(isDev() == true) {
			return null;
		}
		return new IssacWeb(request);
	}

	public void closeQuietly(ResultSet rs, PreparedStatement pstmt, Connection conn) {
		if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
		if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
		if(conn != null) { try { conn.close(); } catch(Exception ignore) {} }
	}

	/** 단일 값 조회 헬퍼 (없으면 strDefault) */
	public String selectOne(Connection conn, String strQuery, String[] arrParams, String strDefault) {
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = conn.prepareStatement(strQuery);
			if(arrParams != null) {
				for(int nIndex = 0; nIndex < arrParams.length; nIndex++) {
					pstmt.setString(nIndex + 1, arrParams[nIndex]);
				}
			}
			rs = pstmt.executeQuery();
			if(rs.next()) {
				String strValue = rs.getString(1);
				if(strValue != null) {
					return strValue;
				}
			}
		} catch(Exception e) {
			printLog("A", "selectOne error : " + e.getMessage() + " / query : " + strQuery);
		} finally {
			if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
			if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
		}
		return strDefault;
	}

	/** COUNT(*) 조회 결과가 0보다 큰지 확인 */
	public boolean existsRow(Connection conn, String strQuery, String[] arrParams) {
		return !selectOne(conn, strQuery, arrParams, "0").contentEquals("0");
	}


	// =====================================================================
	// 5. 문자열 / 날짜 / 시간 유틸
	// =====================================================================

	/**
	 * mysql \' or \\  이스케이프 문자 처리
	 */
	public static String isEscapeChar(String strContent) {
		if(strContent == null || strContent.contentEquals("")) {
			return "";
		}
		String strReplaceContent = strContent;
		if(strContent.contains("\'")) {
			strReplaceContent = strReplaceContent.replace("\'", "\'\'");
		}
		if(strContent.contains("\\")) {
			strReplaceContent = strReplaceContent.replace("\\", "\\\\");
		}
		return strReplaceContent;
	}

	public static boolean createDirectory(String path) {
		int charPos = path.lastIndexOf("/");
		boolean result = false;
		if(charPos > -1) {
			String partialPath = path.substring(0, charPos);
			File file = new File(partialPath);
			result = file.mkdirs();
		}
		return result;
	}

	public static String defaultIfNull(String value, String defaultValue) {
		return (value == null || value.trim().isEmpty()) ? defaultValue : value;
	}

	/**
	 * 날짜 포맷 변환 : yyyyMMdd -> yy.MM.dd(E)
	 */
	public static String formatDate(String inputDate) {
		SimpleDateFormat inputFormat = new SimpleDateFormat("yyyyMMdd");
		SimpleDateFormat outputFormat = new SimpleDateFormat("yy.MM.dd(E)", new Locale("ko", "KR"));
		Date date;
		try {
			date = inputFormat.parse(inputDate);
		} catch (ParseException e) {
			throw new IllegalArgumentException("Invalid date format: " + inputDate);
		}
		return outputFormat.format(date);
	}

	/**
	 * 시간 포맷 변환 : HHmmHHmm -> HH:mm ~ HH:mm
	 */
	public static String formatTime(String inputTime) {
		String startTime = inputTime.substring(0, 4);
		String endTime = inputTime.substring(4);

		SimpleDateFormat inputFormat = new SimpleDateFormat("HHmm");
		SimpleDateFormat outputFormat = new SimpleDateFormat("HH:mm");

		Date startDate, endDate;
		try {
			startDate = inputFormat.parse(startTime);
			endDate = inputFormat.parse(endTime);
		} catch (ParseException e) {
			throw new IllegalArgumentException("Invalid time format: " + inputTime);
		}

		return outputFormat.format(startDate) + " ~ " + outputFormat.format(endDate);
	}

	/**
	 * 일시 포맷 변환 : yyyyMMddHHmmss -> yy.MM.dd(E) HH:mm:ss (Asia/Seoul)
	 */
	public static String formatDateTime(String dateTime) {
		if(dateTime == null || dateTime.trim().contentEquals("")) {
			return "";
		}

		dateTime = dateTime.trim();

		if(dateTime.length() != 14) {
			return "";
		}

		try {
			TimeZone seoulTimeZone = TimeZone.getTimeZone("Asia/Seoul");

			SimpleDateFormat inputFormat = new SimpleDateFormat("yyyyMMddHHmmss");
			inputFormat.setTimeZone(seoulTimeZone);

			SimpleDateFormat outputFormat = new SimpleDateFormat("yy.MM.dd(E) HH:mm:ss", Locale.KOREAN);
			outputFormat.setTimeZone(seoulTimeZone);

			return outputFormat.format(inputFormat.parse(dateTime));
		} catch(Exception e) {
			e.printStackTrace();
			return "";
		}
	}

	/**
	 * 주문 일시 포맷 변환 : yyyyMMddHHmm -> yyyy-MM-dd HH:mm:00
	 */
	public static String formatOrderDateTime(String dateTime) {
		if (dateTime != null && dateTime.length() == 12) {
			return dateTime.substring(0, 4) + "-" +
				   dateTime.substring(4, 6) + "-" +
				   dateTime.substring(6, 8) + " " +
				   dateTime.substring(8, 10) + ":" +
				   dateTime.substring(10, 12) + ":00";
		}
		return dateTime;
	}

	/**
	 * ISO 8601 -> yyyyMMddHHmmss
	 */
	public String convDateFormat(String strDate) {
		if(strDate == null || strDate.contentEquals("")) {
			return "";
		}

		String strConvDate = "";
		try {
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX");
			Date date = dateFormat.parse(strDate);
			dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
			strConvDate = dateFormat.format(date);
			printLog("D", "convDateFormat : " + strDate + " => " + strConvDate);
		} catch (Exception ex) {
		}
		return strConvDate;
	}

	public static String formatPhoneNumber(String phoneNumber) {
		// 전화번호가 11자리일 때 010-1234-5678 형식으로 변환
		if (phoneNumber != null && phoneNumber.length() == 11) {
			return phoneNumber.substring(0, 3) + "-" +
				   phoneNumber.substring(3, 7) + "-" +
				   phoneNumber.substring(7);
		}
		// 전화번호가 유효하지 않다면 그대로 반환
		return phoneNumber;
	}

	/** 시간 HH:mm ~ HH:mm 타입을 HHmmHHmm 타입으로 포맷 */
	public static String parseToHHmmHHmm(String time) {
		return time.replaceAll(":", "").replaceAll(" ","").replaceAll("~","");
	}

	/** HHmm -> 분 */
	public static int parseTimeToMinutes(String hhmm) {
		int hour = Integer.parseInt(hhmm.substring(0, 2));
		int minute = Integer.parseInt(hhmm.substring(2, 4));
		return hour * 60 + minute;
	}

	/** 현재 시간이 시작 시간과 종료 시간 사이에 있는지 확인 */
	public static boolean isTimeWithinRange(String currentTime, String startTime, String endTime) {
		return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
	}

	/**
	 * 운영중 여부 판단.(자정을 넘기는 운영시간도 처리)
	 */
	public static boolean isOperatingNow(int nStartTime, int nEndTime, int nNowTime) {
		if(nStartTime <= nEndTime) {
			return nStartTime < nNowTime && nEndTime > nNowTime;
		}
		return nNowTime > nStartTime || nNowTime < nEndTime;
	}

	/** 현재 시각 문자열(패턴 지정) */
	public static String now(String strPattern) {
		return new SimpleDateFormat(strPattern).format(Calendar.getInstance().getTime());
	}

	/** 일시YYMMDDHHMMSSMS(15) */
	public static String createDateTimeId() {
		SimpleDateFormat simpleDateFormat = new SimpleDateFormat("YYYYMMddHHmmssSSS");
		String strDate = simpleDateFormat.format(new Date());
		return strDate.substring(2, 17);
	}

	/** 랜덤(4) + 일시(15) */
	public static String createOrederID() {
		Random rand = new Random();
		String strRand = Integer.toString(rand.nextInt(9999));
		return strRand + createDateTimeId();
	}

	public static int getUUID() {
		// UUID의 해시코드로 Int형 고유번호 생성
		return Math.abs(UUID.randomUUID().hashCode());
	}

	/**
	 * 결제 처리중 실패시 로그 남김(월별 파일 생성).
	 */
	public void writeLogFile(String strLog) {
		PrintWriter writer = null;
		try {
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
			String strDate = dateFormat.format(new Date());
			String strFileName = strDate.substring(0, 7) + ".txt";		// 월별로 생성

			String strWebrootPath = getServletContext().getRealPath("/");
			strWebrootPath = strWebrootPath.replaceAll("\\\\", "/");
			String strFilePath = strWebrootPath + "villizinei/file/payerror/" + strFileName;

			File file = new File(strFilePath);
			if(!file.exists()) {
				file.createNewFile();
			}

			writer = new PrintWriter(new FileWriter(file, true));		// 이어쓰기
			writer.write("[" + strDate + "] " + strLog + "\n");
			writer.close();
		} catch(IOException ioe) {
		} finally {
			try {
				writer.close();
			} catch(Exception e) {
			}
		}
	}

	/**
	 * HH:mm ~ HH:mm 포맷의 선택 가능 시간 목록 생성
	 */
	public static List<String> getTimeIntervals(String startTime, String endTime, int intervalMinutes, String strReserveTimeLintervalUnit) {
		List<String> intervals = new ArrayList<String>();
		SimpleDateFormat sdf = new SimpleDateFormat("HHmm");
		SimpleDateFormat outputFormat = new SimpleDateFormat("HH:mm");

		try {
			Date startDate = sdf.parse(startTime);
			Date endDate = sdf.parse(endTime);

			Calendar startCal = Calendar.getInstance();
			startCal.setTime(startDate);
			Calendar endCal = Calendar.getInstance();
			endCal.setTime(endDate);

			while (startCal.before(endCal)) {
				Date intervalStart = startCal.getTime();
				if (strReserveTimeLintervalUnit.contentEquals(UNIT_MINUTE)) {
					startCal.add(Calendar.MINUTE, intervalMinutes); // 분 단위 추가
				} else if (strReserveTimeLintervalUnit.contentEquals(UNIT_HOUR)) {
					startCal.add(Calendar.HOUR_OF_DAY, intervalMinutes); // 시간 단위 추가
				} else if (strReserveTimeLintervalUnit.contentEquals(UNIT_DAYS)) {
					startCal.add(Calendar.DAY_OF_YEAR, intervalMinutes); // 일 단위 추가
				} else if (strReserveTimeLintervalUnit.contentEquals(UNIT_MONTH)) {
					startCal.add(Calendar.MONTH, intervalMinutes); // 월 단위 추가
				} else if (strReserveTimeLintervalUnit.contentEquals(UNIT_YEAR)) {
					startCal.add(Calendar.YEAR, intervalMinutes); // 연 단위 추가
				}

				Date intervalEnd = startCal.getTime();
				if (intervalEnd.after(endDate)) {
					intervalEnd = endDate;
				}

				intervals.add(outputFormat.format(intervalStart) + " ~ " + outputFormat.format(intervalEnd));

				if (intervalEnd.equals(endDate)) {
					break;
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}

		return intervals;
	}


	// =====================================================================
	// 6. 운영시간(OPERATION_HOURS) 유틸
	// =====================================================================

	/**
	 * JSON 문자열에서 key.field 값 추출
	 */
	public static String extractValue(String jsonString, String key, String field) {
		JSONParser parser = new JSONParser();
		try {
			JSONObject jsonObject = (JSONObject) parser.parse(jsonString);

			JSONObject targetObject = (JSONObject) jsonObject.get(key);
			if (targetObject != null) {
				Object value = targetObject.get(field);
				return value != null ? value.toString() : null;
			}
			System.out.println("Key not found: " + key);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return ""; // 값이 없거나 오류가 발생한 경우 빈값 반환
	}

	/**
	 * OPERATION_HOURS(JSON)에서 기준일자의 운영 시작/종료 시간(HHmm)을 조회한다.
	 * @param strDate 기준일자(yyyyMMdd). null 또는 형식이 맞지 않으면 오늘 기준.
	 * @return [0] 시작시간, [1] 종료시간. 값이 없으면 빈 문자열.
	 */
	public static String[] getOperationTimeRange(String strOperationHours, String strDate) {
		String[] arrTime = new String[] { "", "" };

		if(strOperationHours == null || strOperationHours.contentEquals("")) {
			return arrTime;
		}

		try {
			SimpleDateFormat sdfOperationHours = new SimpleDateFormat("yyyyMMdd");

			String strTargetDate = (strDate != null && strDate.length() >= 8)
					? strDate.substring(0, 8) : sdfOperationHours.format(new Date());

			Calendar calendarOperationHours = Calendar.getInstance();
			calendarOperationHours.setTime(sdfOperationHours.parse(strTargetDate));

			// 요일 확인 (1: 일요일, 2: 월요일, ..., 7: 토요일)
			int nDayOfWeek = calendarOperationHours.get(Calendar.DAY_OF_WEEK);

			// WEEKDAY 또는 WEEKEND에 따라 값 추출
			String strDayType = (nDayOfWeek == Calendar.SATURDAY || nDayOfWeek == Calendar.SUNDAY)
					? "WEEKEND" : "WEEKDAY";

			String strStartTime = extractValue(strOperationHours, strDayType, "start");
			String strEndTime = extractValue(strOperationHours, strDayType, "end");

			arrTime[0] = strStartTime == null ? "" : strStartTime;
			arrTime[1] = strEndTime == null ? "" : strEndTime;
		} catch (Exception e) {
			e.printStackTrace();
			arrTime[0] = "";
			arrTime[1] = "";
		}

		return arrTime;
	}

	/** 오늘 기준 운영 시작/종료 시간(HHmm) */
	public static String[] getOperationTimeRange(String strOperationHours) {
		return getOperationTimeRange(strOperationHours, null);
	}

	/** 운영시간을 HHmmHHmm 형태로 조합(값이 없으면 빈 문자열) */
	public static String getOperationTime(String strOperationHours, String strDate) {
		String[] arrTime = getOperationTimeRange(strOperationHours, strDate);
		if(arrTime[0].contentEquals("") || arrTime[1].contentEquals("")) {
			return "";
		}
		return arrTime[0] + arrTime[1];
	}

	/** 운영시간을 HH:mm ~ HH:mm 형태로 조합(값이 없으면 빈 문자열) */
	public static String getOperationTimeText(String strOperationHours, String strDate) {
		String[] arrTime = getOperationTimeRange(strOperationHours, strDate);
		if(arrTime[0].length() < 4 || arrTime[1].length() < 4) {
			return "";
		}
		return arrTime[0].substring(0, 2) + ":" + arrTime[0].substring(2, 4) + " ~ "
			 + arrTime[1].substring(0, 2) + ":" + arrTime[1].substring(2, 4);
	}


	// =====================================================================
	// 7. 공통 데이터 클래스
	// =====================================================================

	// 휴일 데이터 클래스
	static class Holiday {
		int repeatType;
		int dayOfWeek;
		int dayOfMonth;
		int specificType;
		String specialDay;

		Holiday(int repeatType, int dayOfWeek, int dayOfMonth, int specificType, String specialDay) {
			this.repeatType = repeatType;
			this.dayOfWeek = dayOfWeek;
			this.dayOfMonth = dayOfMonth;
			this.specificType = specificType;
			this.specialDay = specialDay;
		}
	}

	// 단축운영 데이터 클래스
	static class Shortening {
		int repeatType;
		int dayOfWeek;
		int dayOfMonth;
		String StartTime;
		String EndTime;

		Shortening(int repeatType, int dayOfWeek, int dayOfMonth, String strStartTime, String strEndTime) {
			this.repeatType = repeatType;
			this.dayOfWeek = dayOfWeek;
			this.dayOfMonth = dayOfMonth;
			this.StartTime = strStartTime;
			this.EndTime = strEndTime;
		}
	}

	// 예약건 데이터 클래스
	static class Reservation {
		String strTime;
		String strPlace;

		Reservation(String Place, String Time) {
			this.strPlace = Place;
			this.strTime = Time;
		}

		public String getPlace(){
			return strPlace;
		}

		public String getTime(){
			return strTime;
		}
	}


	// =====================================================================
	// 8. 휴일 / 예약 가능 여부 판단
	// =====================================================================

	/**
	 * 오늘이 휴일인지 체크하는 메서드
	 * 휴일 모델을 넣고 오늘 요일, 일, 주를 넣어주면
	 * 휴일에 repeatType을 기준으로 해당하는게 있는지 확인하는 방식
	 * true : 휴일, false : 휴일 아님
	 */
	public static boolean isTodayHoliday(Holiday holiday, int todayDayOfWeek, int todayDayOfMonth, int weekOfMonth) {
		switch (holiday.repeatType) {
			case WEEKLY_REPEAT:
				return holiday.dayOfWeek == todayDayOfWeek;
			case WEEK_OF_MONTH_1:
			case WEEK_OF_MONTH_2:
			case WEEK_OF_MONTH_3:
			case WEEK_OF_MONTH_4:
			case WEEK_OF_MONTH_5:
				return holiday.dayOfWeek == todayDayOfWeek && holiday.repeatType == weekOfMonth;
			case MONTHLY_REPEAT:
				return holiday.dayOfMonth == todayDayOfMonth;
			case DAILY_REPEAT:
				return true;
			case HOLIDAY_REPEAT:
				// 구체적인 공휴일 날짜와 비교하는 로직 필요
				return false;
			default:
				return false;
		}
	}

	/** 임시휴무일 체크 */
	public static boolean isTodayTempHoliday(Holiday holiday, String strSelectDay) {
		if(holiday == null || strSelectDay == null || strSelectDay.contentEquals("")) {
			return false;
		}

		if(holiday.specificType != SPECIFIC_HOLIDAY_TEMP) {
			return false;
		}

		return holiday.specialDay.contentEquals(strSelectDay);
	}

	private static int parseIntOrDefault(String strValue, int nDefault) {
		if(strValue == null || strValue.isEmpty()) {
			return nDefault;
		}
		try {
			return Integer.parseInt(strValue);
		} catch(Exception e) {
			return nDefault;
		}
	}

	/**
	 * 휴일 조회 ResultSet 의 현재 행으로 Holiday 생성
	 * (컬럼 순서는 getHolidaysQuery 기준)
	 */
	public static Holiday createHolidayFromResultSet(ResultSet rs) throws SQLException {
		int nSpecificRepeatType = parseIntOrDefault(rs.getString(1), -1);
		int nHoliDaysDayOfWeek = parseIntOrDefault(rs.getString(2), -1);
		int nHolidaysDayOfMonth = parseIntOrDefault(rs.getString(3), -1);
		int nSpecificType = parseIntOrDefault(rs.getString(4), -1);

		String strSpecialDay = rs.getString(5);
		if (strSpecialDay == null) {
			strSpecialDay = "";
		}

		return new Holiday(nSpecificRepeatType, nHoliDaysDayOfWeek, nHolidaysDayOfMonth, nSpecificType, strSpecialDay);
	}

	/**
	 * 시설의 휴무일 목록 조회
	 */
	public List<Holiday> loadHolidays(Connection conn, String strAptCode, String strCommunityType) {
		List<Holiday> holidays = new ArrayList<Holiday>();

		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = conn.prepareStatement(getHolidaysQuery(strAptCode, strCommunityType));
			rs = pstmt.executeQuery();
			while(rs.next()) {
				holidays.add(createHolidayFromResultSet(rs));
			}
		} catch(Exception e) {
			printLog("A", "loadHolidays error : " + e.getMessage());
		} finally {
			if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
			if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
		}

		return holidays;
	}

	/**
	 * 휴무일 목록으로 기준일자의 휴무 여부 판단
	 * @return [0] 휴무 여부, [1] 임시휴무 여부
	 */
	public static boolean[] checkHoliday(List<Holiday> holidays, String strSelectDay) {
		boolean[] arrHoliday = new boolean[] { false, false };

		if(holidays == null || strSelectDay == null || strSelectDay.length() < 8) {
			return arrHoliday;
		}

		try {
			Calendar calendar = Calendar.getInstance();
			calendar.setTime(new SimpleDateFormat("yyyyMMdd").parse(strSelectDay.substring(0, 8)));

			int nDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK) - 1;
			int nDayOfMonth = calendar.get(Calendar.DAY_OF_MONTH);
			int nWeekOfMonth = calendar.get(Calendar.WEEK_OF_MONTH);

			for (Holiday holiday : holidays) {
				if (isTodayHoliday(holiday, nDayOfWeek, nDayOfMonth, nWeekOfMonth)) {
					arrHoliday[0] = true;
				} else if (isTodayTempHoliday(holiday, strSelectDay.substring(0, 8))) {
					arrHoliday[0] = true;
					arrHoliday[1] = true;
				}
			}
		} catch(Exception e) {
			e.printStackTrace();
		}

		return arrHoliday;
	}

	/** 오늘 기준 휴무 여부 판단 */
	public static boolean[] checkHolidayToday(List<Holiday> holidays) {
		return checkHoliday(holidays, now("yyyyMMdd"));
	}

	/** 공휴일 여부 */
	public static boolean isPublicHoliday(String strSelectDay, Connection conn){
		String strHolidayQuery = "SELECT COUNT(*) FROM HOLIDAYS WHERE HOLIDAY_DATE = ? ";
		return countByQuery(conn, strHolidayQuery, new String[] { strSelectDay }) > 0;
	}

	/** 특별운영일 여부 */
	public static boolean isSpecialOperatingDay(String strAptCode, String strCommunityType, String strSelectDay, Connection conn){
		String strHolidayQuery = "SELECT COUNT(*) FROM APT_COMMUNITY_SPECIFIC "
			+ " WHERE APT_CODE = ? AND COMMUNITY_TYPE = ? AND SPECIFIC_TYPE = '4' AND SPECIAL_DAY = ? ";
		return countByQuery(conn, strHolidayQuery, new String[] { strAptCode, strCommunityType, strSelectDay }) > 0;
	}

	/** COUNT 조회(static 컨텍스트용) */
	private static int countByQuery(Connection conn, String strQuery, String[] arrParams) {
		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = conn.prepareStatement(strQuery);
			if(arrParams != null) {
				for(int nIndex = 0; nIndex < arrParams.length; nIndex++) {
					pstmt.setString(nIndex + 1, arrParams[nIndex]);
				}
			}
			rs = pstmt.executeQuery();
			if (rs.next()) {
				return parseIntOrDefault(rs.getString(1), 0);
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
			if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
		}
		return 0;
	}

	/**
	 * 예약 가능 여부 확인
	 * - 기존 예약과 시간이 겹치는지
	 * - 해당 날짜/시간이 휴무(SPECIFIC_TYPE = '2')로 지정되었는지
	 */
	public static boolean isAvailable(List<Reservation> reservations, String strPlace, String strTime,
			String strDate, String strCommunityType, String strAptCode, Connection conn) {
		// strTime의 길이가 8자가 아닌 경우 false 반환
		if (strTime == null || strTime.length() != 8) {
			return false;
		}

		// strTime -> 시작/종료 분으로 변환
		int start = parseTimeToMinutes(strTime.substring(0, 4));
		int end = parseTimeToMinutes(strTime.substring(4, 8));
		if (end <= start) {
			end += 24 * 60; // 자정 넘김 보정
		}

		for (Reservation reservation : reservations) {
			if (reservation.getPlace().equals(strPlace) || reservation.getPlace().contentEquals("PLACE_ALL") || strPlace.contentEquals("PLACE_ALL")) {
				String reservationTime = reservation.getTime();
				if (reservationTime == null || reservationTime.length() != 8) {
					continue; // 잘못된 예약 데이터는 건너뜀
				}

				int resStart = parseTimeToMinutes(reservationTime.substring(0, 4));
				int resEnd = parseTimeToMinutes(reservationTime.substring(4, 8));
				if (resEnd <= resStart) {
					resEnd += 24 * 60; // 자정 넘김 보정
				}

				// 범위 겹침: (start < resEnd) && (end > resStart)
				if (start < resEnd && end > resStart) {
					return false; // 겹침
				}
			}
		}

		// DB에서 특정 날짜, 시간, 시설이 휴일로 지정되었는지 추가 확인
		String strShorteningQuery = "SELECT COUNT(*) " +
				"FROM APT_COMMUNITY_SPECIFIC " +
				"WHERE APT_CODE = ? AND COMMUNITY_TYPE = ? AND SPECIAL_DAY = ? AND SPECIFIC_TYPE = '2' " +
				"AND ((? >= START_TIME AND ? < END_TIME) OR (? > START_TIME AND ? < END_TIME))";

		String strStart = strTime.substring(0, 4);	// 시작 HHmm
		String strEnd = strTime.substring(4, 8);	// 종료 HHmm

		// 해당 날짜의 시간이 휴일로 되어 있으면 예약 불가
		return countByQuery(conn, strShorteningQuery,
				new String[] { strAptCode, strCommunityType, strDate, strStart, strStart, strEnd, strEnd }) < 1;
	}


	// =====================================================================
	// 9. 공통 조회 쿼리 및 조회 함수
	// =====================================================================

	public static String getHolidaysQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, SPECIFIC_TYPE, SPECIAL_DAY " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND (SPECIFIC_TYPE = '0' OR SPECIFIC_TYPE = '3') " +
			"order by SPECIFIC_TYPE, SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK ASC ";
	}

	public static String getShorteningQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, START_TIME, END_TIME " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND SPECIFIC_TYPE = '1'";
	}

	public static String getTimeQuery(String aptCode, String communityType) {
		return "SELECT START_TIME, END_TIME, OPERATION_HOURS, COMMUNITY_STATE " +
			"FROM APT_COMMUNITY " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' ";
	}

	public static String getCommunityQuery(String aptCode) {
		return "SELECT COMMUNITY_TYPE, TITLE, " +
			"CONCAT(SUBSTRING(START_TIME,1,2), ':', SUBSTRING(START_TIME, 3,2), ' ~ ' , SUBSTRING(END_TIME,1,2), ':', SUBSTRING(END_TIME,3,2)) as TIME, " +
			"IMAGE, OPERATION_HOURS, COMMUNITY_STATE " +
			"FROM APT_COMMUNITY " +
			"WHERE APT_CODE = '" + aptCode + "' AND PARENT_ID IS NULL AND COMMUNITY_STATE != '0' GROUP BY COMMUNITY_TYPE ORDER BY INAPP_ORDER, COMMUNITY_TYPE, GENDER ";
	}

	/**
	 * 사용자 성별 조회.
	 * APT_COMMUNITY_USER_INFO -> (없으면) USER_INFO 의 동/호/이름으로 RESIDENT_MEMBER_INFO 조회
	 */
	public String getUserGender(Connection conn, String strAptCode, String strUserId) {
		String strGender = selectOne(conn,
			"SELECT GENDER FROM APT_COMMUNITY_USER_INFO WHERE USER_ID = ? AND APT_CODE = ? ",
			new String[] { strUserId, strAptCode }, "");

		if(!strGender.contentEquals("") && !strGender.contentEquals("0")) {
			return strGender;
		}

		PreparedStatement pstmt = null;
		ResultSet rs = null;
		try {
			pstmt = conn.prepareStatement(
				"SELECT USER_DONG, USER_HO, USER_NAME FROM USER_INFO WHERE USER_ID = ? AND APT_CODE = ? ");
			pstmt.setString(1, strUserId);
			pstmt.setString(2, strAptCode);
			rs = pstmt.executeQuery();

			if(rs.next()) {
				String strResidentGender = selectOne(conn,
					"SELECT GENDER FROM RESIDENT_MEMBER_INFO WHERE APT_CODE = ? AND DONG = ? AND HO = ? AND NAME = ? ",
					new String[] { strAptCode, nvl(rs.getString(1)), nvl(rs.getString(2)), nvl(rs.getString(3)) }, "");

				if(!strResidentGender.contentEquals("")) {
					strGender = strResidentGender;
				}
			}
		} catch(Exception e) {
			printLog("A", "getUserGender error : " + e.getMessage());
		} finally {
			if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
			if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
		}

		return strGender;
	}

	/**
	 * 회원권 잔여 사용 횟수 조회
	 */
	public int getRemainingUses(Connection conn, String membershipId, String strUserDong, String strUserHo,
			String strUserName, String aptCode, int usageLimit) throws SQLException {
		String strUserMembershipListQuery =
			"SELECT MEMBERSHIP_USER_LIST_ID " +
			" FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
			" WHERE MEMBERSHIP_ID = ?" +
			" AND USER_DONG  = ? " +
			" AND USER_HO  = ? " +
			" AND USER_NAME  = ? " +
			" AND APT_CODE  = ? " +
			" ORDER BY MEMBERSHIP_USER_LIST_ID desc " +
			" LIMIT 1";

		String strMembershipListId = selectOne(conn, strUserMembershipListQuery,
			new String[] { membershipId, strUserDong, strUserHo, strUserName, aptCode }, "0");

		String strUsageQuery =
			"SELECT COUNT(*) as use_count FROM APT_COMMUNITY_RESERVE " +
			"WHERE MEMBERSHIP_USER_LIST_ID = ?  " +
			" AND USER_DONG = ? " +
			" AND USER_HO = ? " +
			" AND RESERVE_USER_NAME = ? " +
			" AND APT_CODE = ? " +
			" AND RESERVE_CANCEL_TIME IS NULL";

		int nUsedCount = countByQuery(conn, strUsageQuery,
			new String[] { strMembershipListId, strUserDong, strUserHo, strUserName, aptCode });

		return Math.max(0, usageLimit - nUsedCount);
	}


	// =====================================================================
	// 10. 외부 API 호출(개발 서버 URL 우회)
	// =====================================================================

	private static final String COMMUNITY_API_V6 = "http://146.56.179.38/xmobile/villizinei/community/community_api_v6.jsp";
	private static final String COMMUNITY_API_V11 = "http://146.56.179.38/xmobile/villizinei/community/community_api_v11.jsp";

	/** URLEncoder.encode(UTF-8) - null 은 빈값 처리 */
	private static String encodeParam(String strValue) {
		try {
			return URLEncoder.encode(strValue == null ? "" : strValue, "UTF-8");
		} catch (Exception e) {
			return "";
		}
	}

	/**
	 * 커뮤니티 API 호출.
	 * @param arrParams 이름/값 순서로 나열한 파라미터 배열 (SID 제외)
	 */
	private static boolean callCommunityApi(String strBaseUrl, String strCallSID, String[] arrParams) {
		try {
			StringBuilder sbQuery = new StringBuilder();
			sbQuery.append("SID=").append(encodeParam(strCallSID));

			if(arrParams != null) {
				for(int nIndex = 0; nIndex + 1 < arrParams.length; nIndex += 2) {
					sbQuery.append("&").append(arrParams[nIndex]).append("=").append(encodeParam(arrParams[nIndex + 1]));
				}
			}

			URL url = new URL(strBaseUrl + "?" + sbQuery.toString());
			System.out.println("Request URL: " + url);

			HttpURLConnection connAPI = (HttpURLConnection) url.openConnection();
			connAPI.setRequestMethod("POST");

			// 응답 코드 확인 (실제로 응답을 기다리지 않음)
			System.out.println("Response Code: " + connAPI.getResponseCode());
			return true;
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}
	}

	/** 출입 등록 정보 삭제 */
	public void callDevMemberDeleteAPI(String strresultBeforeUUID, String strDoorId, String strAptCode, String strCommunityType, Connection conn) {
		callCommunityApi(COMMUNITY_API_V11, "call_delete_api", new String[] {
			"strresultBeforeUUID", strresultBeforeUUID,
			"strDoorId", strDoorId,
			"strAptCode", strAptCode,
			"strCommunityType", strCommunityType });
	}

	/** 예약 출입 등록 */
	public void callDevReservationAPI(String strUserId, String strReservationUserName, String strReservationUserPhone,
			String strDate, String strTime, String strDoorId, String strAptCode, Connection conn,
			String strCommunityType, String strDong, String strHo) {
		callCommunityApi(COMMUNITY_API_V11, "call_reservation_api", new String[] {
			"strUserId", strUserId,
			"strReservationUserName", strReservationUserName,
			"strReservationUserPhone", strReservationUserPhone,
			"strDate", strDate,
			"strTime", strTime,
			"strDoorId", strDoorId,
			"strAptCode", strAptCode,
			"strCommunityType", strCommunityType,
			"strUserDong", strDong,
			"strUserHo", strHo });
	}

	/** 회원권 출입 등록 */
	public boolean callDevMembershipReservationAPI(String strUserId, String strReservationUserName, String strReservationUserPhone,
			String strStartDate, String strEndDate, String strDoorId, String strAptCode, String strCommunityType,
			String strDong, String strHo, Connection conn) {
		callCommunityApi(COMMUNITY_API_V11, "call_reservation_membership_api", new String[] {
			"strUserId", strUserId,
			"strReservationUserName", strReservationUserName,
			"strReservationUserPhone", strReservationUserPhone,
			"strStartDate", strStartDate,
			"strEndDate", strEndDate,
			"strDoorId", strDoorId,
			"strAptCode", strAptCode,
			"strCommunityType", strCommunityType,
			"strDong", strDong,
			"strHo", strHo });

		return true;
	}

	/** 얼굴 등록 */
	public void callDevEntranceRegistrationAPI(String strUserId, String strReservationUserName,
			String strReservationUserPhone, String strUUID, String strDoorId, String strAptCode,
			String strCommunityType, Connection conn) {
		callCommunityApi(COMMUNITY_API_V6, "call_Entrance_api", new String[] {
			"strUserId", strUserId,
			"strReservationUserName", strReservationUserName,
			"strReservationUserPhone", strReservationUserPhone,
			"strUUID", strUUID,
			"strDoorId", strDoorId,
			"strAptCode", strAptCode,
			"strCommunityType", strCommunityType });
	}

	/** 얼굴 등록 재시도 */
	public void callReservationTryAgain(String strReservationId, String strUsreImage) {
		callCommunityApi(COMMUNITY_API_V11, "call_gosk_reservation_api", new String[] {
			"ImageURL", strUsreImage,
			"ReservationId", strReservationId });
	}

%>
