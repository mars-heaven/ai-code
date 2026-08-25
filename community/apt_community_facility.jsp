<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="com.softbase.image.ImageThumbnail" %>
<%@ page import="java.io.*" %>
<%@ page import="villizine.util.IssacWeb" %>
<%@ include file="./apt_global.jsp" %>
<%@ include file="../global/community_global.jsp" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.TimeZone" %>

<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="org.json.simple.JSONArray" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="org.json.simple.parser.JSONParser" %>
<%@ page import="java.sql.SQLException" %>

<%@ page import="java.net.URL" %>
<%@ page import="org.apache.commons.codec.binary.Base64" %>
<%@ page import="java.util.UUID" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.net.URLEncoder" %>

<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>


<%@ include file="./apt_community_common.jsp" %>

<%
Connection 			conn = null;			// DB Connection Object
PreparedStatement 	pstmt = null;			// JDBC PreparedStatement Object
ResultSet 			rs = null;	 			// Query Result Set Object

IssacWeb					m_issacweb = null;


// Clear out's buffer
out.clearBuffer();
out.clear();
out = pageContext.pushBody();

// outputstream 가져오기
OutputStream outStream = response.getOutputStream();

try {

	// Load JDBC Driver and connect to database
	Class.forName(driverClass);
	conn = DriverManager.getConnection(dbUrl, dbUserId, dbUserPasswd);

	// 운영서버이면 암호화 객체 생성
	m_issacweb = createIssacWeb(request);
	// Get Parameter - SID = query 구분.
	String strSID = getRequestParam(m_issacweb, request, "SID");
	printLog("A", "SID : " + strSID);

    if(strSID.contentEquals("get_community_facility")) {
	//커뮤니티 시설 조회
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");

		// 커뮤니티 사용자 정보 -> 입주민 정보 순으로 성별 조회
		String strGender = getUserGender(conn, strAptCode, strUserId);


		// 커뮤니티 시설을 조회하는 쿼리
		String strQuery = getCommunityQuery(strAptCode);		
		printLog("D","strQuery : " + strQuery);

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		String strType = "";
		String strTitle = "";
		String strTime = "";
		String strImage = "";
		String strOperationHours = "";
		//List<Holiday> holidays = new ArrayList<Holiday>();

		for(int nRow = 0; rs.next(); nRow++) {
			List<Holiday> holidays = new ArrayList<Holiday>();

			strType = rs.getString(1);
			if(strType == null || strType.isEmpty()){
				strType = "0";
			}else{
				holidays = loadHolidays(conn, strAptCode, strType);

			}

			
			strTitle = rs.getString(2);
			if(strTitle == null || strTitle.isEmpty()){
				strTitle = "";
			}
			strTime = rs.getString(3);
			if(strTime == null || strTime.isEmpty()){
				strTime = "";
			}
			strOperationHours= rs.getString(5);
			if(strOperationHours == null || strOperationHours.isEmpty()){
				strOperationHours = "";
			}
			// OPERATION_HOURS 데이터가 있으면 사용
			if(!strOperationHours.contentEquals("")) {
				// 오늘 요일 기준 운영시간(HH:mm ~ HH:mm)
				strTime = getOperationTimeText(strOperationHours, null);
			}



			Calendar today = Calendar.getInstance();
			int todayDayOfWeek = today.get(Calendar.DAY_OF_WEEK) - 1;
			int todayDayOfMonth = today.get(Calendar.DAY_OF_MONTH);
			int weekOfMonth = today.get(Calendar.WEEK_OF_MONTH);

			SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmm");
			String formattedDateHHmm = dateFormatHHmm.format(today.getTime());
			int nNowTime = Integer.parseInt(formattedDateHHmm);

			
			// 결과 출력
			
			//휴일은 기본 false 
			boolean isHoliday = false;
			// 임시휴무일 체크
			boolean isTempHoliday = false;
			SimpleDateFormat dateFormatYYYYMMDD = new SimpleDateFormat("yyyyMMdd");
			String formattedDateYYYYMMDD = dateFormatYYYYMMDD.format(today.getTime());

			// 휴일 체크 로직
			// isTodayHoliday()  
			// Params : Holiday모델, 오늘의 요일, 일, 주
			// ture : 휴일 , false : 휴일 아님
			for (Holiday holiday : holidays) {
				if (isTodayHoliday(holiday, todayDayOfWeek, todayDayOfMonth, weekOfMonth)) {            
					isHoliday = true;
				} else {
					if(isTodayTempHoliday(holiday, formattedDateYYYYMMDD)) {
						isTempHoliday = true;
						isHoliday = true;
					}
				}
			}
		

			String strStartTime = strTime.replace(" ", "").replace(":", "").replace("~", "").substring(0, 4);
			String strEndTime = strTime.replace(" ", "").replace(":", "").replace("~", "").substring(4, 8);
			int nStartTime = Integer.parseInt(strStartTime);
			int nEndTime = Integer.parseInt(strEndTime);

			String strState;
			String strStateTitle;

			if (isHoliday) {
				strState = "2";
				if(isTempHoliday) {
					strStateTitle = "임시휴무";
				} else {
					strStateTitle = "정기휴무";
				}
			} else if (
				(nStartTime <= nEndTime && nStartTime < nNowTime && nEndTime > nNowTime)
				||
				(nStartTime > nEndTime && (nNowTime > nStartTime || nNowTime < nEndTime))
			) {
				strState  = "1";
				strStateTitle = "운영중";
			} else {
				strState = "4";
				if(strType.contentEquals(TYPE_GUESTHOUSE)){
					strStateTitle = "운영중";
					strState = "1";
				}else{
					strStateTitle = "운영종료";
				}
			}
			

			String strCommunityState = rs.getString("COMMUNITY_STATE");
			if(strCommunityState.contentEquals(UNAVAILABLE)){
				// 2 : 예약 준비중
				strStateTitle = "예약준비중";
				strState = "4";
			}

			strImage = rs.getString(4);
			if(strImage == null || strImage.isEmpty()){
				strImage = "";
			}

			
			writeColumn(baOutStream, strType);
			writeColumn(baOutStream, strTitle);
			writeColumn(baOutStream, strTime);
			writeColumn(baOutStream, strState);
			writeColumn(baOutStream, strStateTitle);
			writeColumn(baOutStream, strImage);

			writeRecord(baOutStream);


		}
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_community_facility_info")) {
	//커뮤니티 시설 설명
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");

		if(strAptCode == null || strAptCode.contentEquals("")){
			strAptCode = "0";
		}
		if(strCommunityType == null || strCommunityType.contentEquals("")){
			strCommunityType = "0";
		}
		


		// 시설명, 운영시간, 자리 개수, 시간 간격, 지도 url
		// Create a insert query
		String strQuery = "";
		strQuery += " SELECT TITLE, ";
		strQuery += " CONCAT(SUBSTRING(START_TIME,1,2), ':', SUBSTRING(START_TIME, 3,2), ' ~ ' , SUBSTRING(END_TIME,1,2), ':', SUBSTRING(END_TIME,3,2)) as TIME, ";
		strQuery += " PLACE_COUNT, TIME_INTERVAL, SEATING_MAP, IMAGE, SERVICE_TYPE, COMMUNITY_SETTING_COMMENT, GENDER, SECURITY, OPERATION_HOURS, COMMUNITY_STATE ";	
		strQuery += " FROM APT_COMMUNITY  " ;
		strQuery += " WHERE APT_CODE = '" + strAptCode + "' AND COMMUNITY_TYPE = '" + strCommunityType + "' " ;


		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		String strTitle = "";
		String strTime = "";
		String strCount = "";
		String strInterval = "";
		String strMap = "";
		String strState = "";
		String strStateTitle = "";
		String strImage = "";
		String strServiceType = "";
		String strDescription = "";
		String strGender = "";
		String strSecurity = "";
		String strOperationHours = "";
		String strCommunityState = "";


		for(int nRow = 0; rs.next(); nRow++) {
			strTitle = rs.getString(1);
			strTime = rs.getString(2);
			strCount = rs.getString(3);
			strInterval = rs.getString(4);
			strMap = rs.getString(5);
			strImage = rs.getString(6);
			strServiceType = rs.getString(7);
			strDescription = rs.getString(8);
			strGender = rs.getString(9);
			strSecurity= rs.getString(10);
			strOperationHours= rs.getString("OPERATION_HOURS");
			strCommunityState = rs.getString("COMMUNITY_STATE");

			if(strOperationHours == null) strOperationHours = "";
			// OPERATION_HOURS 데이터가 있으면 사용
			if(!strOperationHours.contentEquals("")) {
				// 오늘 요일 기준 운영시간(HH:mm ~ HH:mm)
				strTime = getOperationTimeText(strOperationHours, null);
			}
		}

		// 휴무일에 관한 데이터를 RECORD_DEL사이에 넣어야하는데
		// 우선 휴일만 가져오기
		String strHolidaysQuery = getHolidaysQuery(strAptCode,strCommunityType);

		pstmt = conn.prepareStatement(strHolidaysQuery);
		rs = pstmt.executeQuery();

		// 휴무일을 조합하는 문자열
		String strHolidays = "";
		boolean isPublicHolidays = false; 

		List<Holiday> holidays = new ArrayList<Holiday>();

		// 자바 1.7이전 버전에서는 switch문에 문자열이 안 됨...
		// int 타입으로 변경
		for(int nRow = 0; rs.next(); nRow++) {
			Holiday holiday = createHolidayFromResultSet(rs);
			int nSpecificRepeatType = holiday.repeatType;
			int nHoliDaysDayOfWeek = holiday.dayOfWeek;
			String strHolidaysDayOfMonth = holiday.dayOfMonth < 0 ? "" : Integer.toString(holiday.dayOfMonth);
        	holidays.add(holiday); // 매주 월요일
			// 휴무일 코드 값을 한글로 변환해서 사용자에게 보여준 코드
			switch (nSpecificRepeatType) {
				case WEEKLY_REPEAT: // 매주
					strHolidays += handleWeeklyRepeat(nHoliDaysDayOfWeek) + ",";
					break;
				case WEEK_OF_MONTH_1: // 해당 주 1
				case WEEK_OF_MONTH_2: // 해당 주 2
				case WEEK_OF_MONTH_3: // 해당 주 3
				case WEEK_OF_MONTH_4: // 해당 주 4
				case WEEK_OF_MONTH_5: // 해당 주 5
					strHolidays += handleSpecificWeekRepeat(nSpecificRepeatType, nHoliDaysDayOfWeek) + ",";
					break;
				case MONTHLY_REPEAT: // 매달
					strHolidays += "매달 " + strHolidaysDayOfMonth +  "일,";
					break;
				case DAILY_REPEAT: // 매일
					strHolidays += "매일,";
					break;
				case HOLIDAY_REPEAT: // 공휴일
					isPublicHolidays = true;
					strHolidays += "공휴일,";
					break;
				default:
					break;
        	}
        }

		 // 오늘 날짜 가져오기
        Calendar today = Calendar.getInstance();

        // 오늘의 요일 및 일자 정보
        int todayDayOfWeek = today.get(Calendar.DAY_OF_WEEK) - 1; // Calendar.DAY_OF_WEEK는 1(일요일)부터 시작
        int todayDayOfMonth = today.get(Calendar.DAY_OF_MONTH);
        int weekOfMonth = today.get(Calendar.WEEK_OF_MONTH);

        // 오늘 날짜 포맷팅
        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
        String formattedDate = dateFormat.format(today.getTime());

		SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmm");
		String formattedDateHHmm = dateFormatHHmm.format(today.getTime());


        // 결과 출력
		
		//휴일은 기본 false 
		boolean isHoliday = false;
		// 임시휴무일 체크
		boolean isTempHoliday = false;
		SimpleDateFormat dateFormatYYYYMMDD = new SimpleDateFormat("yyyyMMdd");
		String formattedDateYYYYMMDD = dateFormatYYYYMMDD.format(today.getTime());

        // 휴일 체크 로직
		// isTodayHoliday()  
		// Params : Holiday모델, 오늘의 요일, 일, 주
		// ture : 휴일 , false : 휴일 아님
        for (Holiday holiday : holidays) {
            if (isTodayHoliday(holiday, todayDayOfWeek, todayDayOfMonth, weekOfMonth)) {            
					isHoliday = true;
			} else if(isTodayTempHoliday(holiday, formattedDateYYYYMMDD)) {
				isTempHoliday = true;
				isHoliday = true;
			}else if(isPublicHolidays){
				String strTodayPublicHolidaysQuery = "";
				strTodayPublicHolidaysQuery += "SELECT COUNT(*) ";
				strTodayPublicHolidaysQuery += " FROM HOLIDAYS ";
				strTodayPublicHolidaysQuery += " WHERE HOLIDAY_DATE = ? ";
			

				pstmt = conn.prepareStatement(strTodayPublicHolidaysQuery);
				pstmt.setString(1, formattedDateYYYYMMDD);
				rs = pstmt.executeQuery();

				printLog("A" ," strTodayPublicHolidaysQuery : " + strTodayPublicHolidaysQuery);

				if(rs.next()){
					String strTodayPublicHolidaysCount = rs.getString(1) != null ? rs.getString(1) : "0";
									printLog("A" ," strTodayPublicHolidaysCount : " + strTodayPublicHolidaysCount);

					if(!strTodayPublicHolidaysCount.contentEquals("0")){
						isHoliday = true;
					}
				}
				
			}
        }
	
		// 휴무일 타입, 타이틀 정하기
		// isHoliday == true 면 휴일 
		// isHoliday == false 면서 
		// 현재 시간이 오픈시간 < HHmm(현재 시간) < 종료 시간 만족하면 운영중, 아니면 종료

		// strTime HH : mm ~ HH : mm 
		String strStartTime = strTime.replace(" ","").replace(":","").replace("~","").substring(0,4);
		String strEndTime = strTime.replace(" ","").replace(":","").replace("~","").substring(4,8);
		int nStartTime  = Integer.parseInt(strStartTime);
		int nEndTime = Integer.parseInt(strEndTime);
		int nNowTime = Integer.parseInt(formattedDateHHmm);
		printLog("A","nStartTime : " + nStartTime);
		printLog("A","nEndTime : " + nEndTime);
		printLog("A","nNowTime : " + nNowTime);

		
		if(isHoliday){
			if(isTempHoliday) {
				strStateTitle = "임시휴무";
			} else {
				strStateTitle = "정기휴무";
			}
			strState = "2";
		}else{
			
			if (
				(nStartTime <= nEndTime && nStartTime < nNowTime && nEndTime > nNowTime)
				||
				(nStartTime > nEndTime && (nNowTime > nStartTime || nNowTime < nEndTime))
			) {
				strState  = "1";
				strStateTitle = "운영중";
			}else{
				if(strCommunityType.contentEquals(TYPE_GUESTHOUSE)){
					strStateTitle = "운영중";
					strState = "1";
				}else{
					strStateTitle = "운영종료";
					strState = "4";
				}		
			}
		}

		if(strCommunityState.contentEquals(UNAVAILABLE)){
			//예약 준비중
			strStateTitle = "예약준비중";
			strState = "4";
			strServiceType = "3";
		}


		printLog("D","strHolidays : " + strHolidays);
		// 휴일 코드값을 한글로 변환 마지막에 ,만 제거
		if(strHolidays.length() > 0){
			strHolidays = strHolidays.substring(0, strHolidays.length() -1);
		}

		printLog("D"," strCommunityType : " + strCommunityType);
		printLog("D"," strTime : " + strTime);
		printLog("D"," strCount : " + strCount);
		printLog("D"," strInterval : " + strInterval);
		printLog("D"," strHolidays : " + strHolidays);


		if(strAptCode.contentEquals("100452") && strCommunityType.contentEquals("03")){
			strTime = "평일 (화~금) 06:00 ~ 02:00\n";
			strTime += "주말 (토~일) 08:00 ~ 24:00";
		}

		String strInfo = formatCommunityData(strCommunityType,strTime,strCount,strInterval,strHolidays);

		String strMembershipGenderQuery = "";
		strMembershipGenderQuery += "SELECT COUNT(*) ";
		strMembershipGenderQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipGenderQuery += " WHERE APT_CODE = ? ";
		strMembershipGenderQuery += " AND COMMUNITY_TYPE = ? ";
		strMembershipGenderQuery += " AND GENDER != '0' ";

		pstmt = conn.prepareStatement(strMembershipGenderQuery);
		pstmt.setString(1, strAptCode);
		pstmt.setString(2, strCommunityType);
		rs = pstmt.executeQuery();

		printLog("A" ," strMembershipGenderQuery : " + strMembershipGenderQuery);

		if(rs.next()){
			String strMembershipGenderCount = rs.getString(1) != null ? rs.getString(1) : "0";
			if(!strMembershipGenderCount.contentEquals("0")){
				strGender = "1";
			}
		}
	        
		printLog("A" ," strGender : " + strGender);


		printLog("D"," strInfo : " + strInfo);
		// 타이틀, 상태, 지도, 상세정보
		writeColumn(baOutStream, strTitle);
		writeColumn(baOutStream, strState);
		writeColumn(baOutStream, strStateTitle);
		writeColumn(baOutStream, strImage);
		writeColumn(baOutStream, strMap);
		writeColumn(baOutStream, strInfo);
		writeColumn(baOutStream, strServiceType);
		writeColumn(baOutStream, strDescription);
		if(!strGender.contentEquals("0")){
			strGender = "1";
		}
		writeColumn(baOutStream, strGender);
		writeColumn(baOutStream, strSecurity);
		writeRecord(baOutStream);



		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_community_settings")){
		// 커뮤니티 시설 최대 선택일, 보안 여부 조회
		// 20240627 얼굴인식만 있음
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");
		String strMembershipId = getRequestParam(m_issacweb, request, "MembershipId");

		if(strAptCode == null || strAptCode.contentEquals("")){
			strAptCode = "0";
		}

		if(strMembershipId == null) strMembershipId = "";
		if(strMembershipId.contentEquals("")){
			String strMembershipIdQuery = "";
			strMembershipIdQuery += "SELECT MEMBERSHIP_ID ";
			strMembershipIdQuery += "FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strMembershipIdQuery += "WHERE APT_CODE = ? ";
			strMembershipIdQuery += "AND COMMUNITY_TYPE = ? ";
			strMembershipIdQuery += "LIMIT 1 ";
			pstmt = conn.prepareStatement(strMembershipIdQuery);
			pstmt.setString(1,strAptCode);
			pstmt.setString(2,strCommunityType);
			rs = pstmt.executeQuery();
			if(rs.next()){
				strMembershipId = rs.getString("MEMBERSHIP_ID");
			}
		}

		String strQuery = "";
		strQuery += " SELECT RESERVE_MAX_DAY, SECURITY, MAP ";
		strQuery += " FROM APT_COMMUNITY ";
		strQuery += " WHERE APT_CODE = '" + strAptCode + "' AND COMMUNITY_TYPE = '" + strCommunityType + "' ";

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();
		String strMaxDay = "";
		String strSecurityType = "";
		String strMap = "";
		String strSelfReservationFlag = "";
		String strReservationStandardDay = "0";
		String strReservationStandard = "";
		String strReservationStandardUnit = "";
		String strMinConsecutiveReservation = "";
		String strMaxConsecutiveReservation = "";

		if(rs.next()){
			//strMaxDay = rs.getString(1);
			//if(strMaxDay == null) strMaxDay = "";
			strSecurityType = rs.getString(2);
			if(strSecurityType == null) strSecurityType = "";
			strMap = rs.getString(3);
			if(strMap == null) strMap = "";
		}

		String strMembershipDataQuery = "";
		strMembershipDataQuery += " SELECT SELF_RESERVATION_FLAG, RESERVE_STANDARD, RESERVE_STANDARD_UNIT, MIN_CONSECUTIVE_RESERVATION, MAX_CONSECUTIVE_RESERVATION, MAXIMUM_RESERVATION_PERIOD ";
		strMembershipDataQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipDataQuery += " WHERE MEMBERSHIP_ID = ? ";
		pstmt = conn.prepareStatement(strMembershipDataQuery);
		pstmt.setString(1, strMembershipId);
		rs = pstmt.executeQuery();

		if(rs.next()){
			strSelfReservationFlag = rs.getString("SELF_RESERVATION_FLAG") != null ? rs.getString("SELF_RESERVATION_FLAG") : "";
			strReservationStandard = rs.getString("RESERVE_STANDARD") != null ? rs.getString("RESERVE_STANDARD") : "";
			strReservationStandardUnit = rs.getString("RESERVE_STANDARD_UNIT") != null ? rs.getString("RESERVE_STANDARD_UNIT") : "";
			strMinConsecutiveReservation = rs.getString("MIN_CONSECUTIVE_RESERVATION") != null ? rs.getString("MIN_CONSECUTIVE_RESERVATION") : "";
			strMaxConsecutiveReservation = rs.getString("MAX_CONSECUTIVE_RESERVATION") != null ? rs.getString("MAX_CONSECUTIVE_RESERVATION") : "";
			strMaxDay = rs.getString("MAXIMUM_RESERVATION_PERIOD") != null ? rs.getString("MAXIMUM_RESERVATION_PERIOD") : "";
		}

		if(strReservationStandardUnit.contentEquals(UNIT_DAYS) && !strReservationStandard.contentEquals("")){
			strReservationStandardDay = strReservationStandard;
		}


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		writeColumn(baOutStream, strMaxDay);
		writeColumn(baOutStream, strSecurityType);
		writeColumn(baOutStream, strMap);
		//writeText(baOutStream, strSelfReservationFlag);
		//writeColumnDel(baOutStream);
		writeColumn(baOutStream, strReservationStandardDay);
		writeColumn(baOutStream, strMinConsecutiveReservation);
		writeColumn(baOutStream, strMaxConsecutiveReservation);
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_community_seat_map")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");		
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");		
		String strMembershipId = getRequestParam(m_issacweb, request, "MembershipId");		
		String strOptionId = getRequestParam(m_issacweb, request, "OptionId");		
		String strUserId = getRequestParam(m_issacweb, request, "UserId");		
		String strGender = getRequestParam(m_issacweb, request, "Gender");
		String strReservationId = getRequestParam(m_issacweb, request, "ReservationId");

		if(strMembershipId == null){
			strMembershipId = "";		
		}
		if(strOptionId == null){
			strOptionId = "";
		}

		if(strUserId == null){
			strUserId = "";
		}

		if(strGender == null || strGender.contentEquals("")){
			strGender = "0";
		}

		if(strReservationId == null){
			strReservationId = "";
		}

		if(!strReservationId.contentEquals("")){
			String strReservationGenderQuery = "";
			strReservationGenderQuery += " SELECT GENDER ";
			strReservationGenderQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReservationGenderQuery += " WHERE RESERVE_ID = " + strReservationId + " ";
			

			printLog("A","strReservationGenderQuery : " + strReservationGenderQuery);

			pstmt = conn.prepareStatement(strReservationGenderQuery);
			rs = pstmt.executeQuery();


			if(rs.next()){
				strGender = rs.getString(1);
			}
		}

		if(strGender.contentEquals("0")){

			// 커뮤니티 사용자 정보 -> 입주민 정보 순으로 성별 조회
			strGender = nvl(getUserGender(conn, strAptCode, strUserId), strGender);
		}

		if(strMembershipId != null && !strMembershipId.contentEquals("")){
			String strTypeQuery = "";
			strTypeQuery += " SELECT COMMUNITY_TYPE ";
			strTypeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strTypeQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

			pstmt = conn.prepareStatement(strTypeQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strCommunityType = rs.getString(1);
			}
		}

		printLog("A", "strMembershipId : " + strMembershipId);
		printLog("A", "strOptionId : " + strOptionId);
		
		String strQuery = "";
		String strMapURL = "";
		if(strMembershipId.contentEquals("") || strOptionId.contentEquals("")){
			strQuery += "SELECT MAP ";
			strQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

			pstmt = conn.prepareStatement(strQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				if(rs.getString(1) != null){
					strMapURL = rs.getString(1);
				}
			}

			if(strMapURL == null || strMapURL.contentEquals("")){
				strQuery = "";
				strQuery += " SELECT MAP ";
				strQuery += " FROM APT_COMMUNITY ";
				strQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
				strQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
				strQuery += " AND (GENDER = '" + strGender + "' OR GENDER = '0') ";
			}
		}else{
			strQuery += " SELECT MAP ";
			strQuery += " FROM APT_COMMUNITY_MEMBERSHIP_OPTION ";
			strQuery += " WHERE OPTION_ID = '" + strOptionId + "' ";
			strQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";
		}
		

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();

		
		if(rs.next()){
			strMapURL = rs.getString(1);
		}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		writeText(baOutStream, strMapURL);

		returnData(m_issacweb, baOutStream, outStream);
		
	}else if(strSID.contentEquals("get_guestroom_image")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strRoomNumber = getRequestParam(m_issacweb, request, "RoomNumber");
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");

		String strImage = " ";

		String strImageQuery = "";
		if(strCommunityType.contentEquals("10")){
			strImageQuery += "SELECT IMAGE ";
			strImageQuery += " FROM APT_COMMUNITY_GUESTHOUSE_ROOM ";
			strImageQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strImageQuery += " AND ROOM_NUMBER = '" + strRoomNumber + "' ";

			pstmt = conn.prepareStatement(strImageQuery);
			rs = pstmt.executeQuery();
			
			if(rs.next()){
				strImage = rs.getString(1);
			}
		}else{

		}

		if(strRoomNumber.contentEquals("")){
			strImage = "/upload/1/community/community_10.png";	
		}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		
		writeColumn(baOutStream, strImage);
	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_guestroom_number")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");

		String strRoomNumberQuery = "";
		strRoomNumberQuery += "SELECT ROOM_NUMBER ";
		strRoomNumberQuery += "FROM APT_COMMUNITY_GUESTHOUSE_ROOM ";
		strRoomNumberQuery += "WHERE APT_CODE = " + strAptCode + " ";

		pstmt = conn.prepareStatement(strRoomNumberQuery);
		rs = pstmt.executeQuery();


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeResultSet(baOutStream, rs);
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}

}catch(Exception e) {
	// 예외 메시지를 빌리진아이 포맷으로 전송
	sendError(m_issacweb, e, outStream);
}
finally {
	// Release a database resources
	closeQuietly(rs, pstmt, conn);
}
%>

