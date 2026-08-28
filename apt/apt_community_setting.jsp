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
<%@ page import="java.util.Set" %>
<%@ page import="java.util.LinkedHashSet" %>

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


<%!

	public String getRequestParam(IssacWeb issacweb, HttpServletRequest request, String strKey) {
		if(strKey == null || strKey.contentEquals("")) {
			printLog("A", "getRequestParam strKey null");
			return "";
		}

		String strValue = "";
		if(isDev() == true) {
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
	 * 빌리진아이 데이터 전송 포맷[ 데이터길이(4자리) + 데이터 ] 에 맞게 조합한 후, 클라이언트로 전송..
	 */
	public void returnData(IssacWeb issacweb, ByteArrayOutputStream baOutStream, OutputStream outStream) {
		if(baOutStream == null || outStream == null) {
			return;
		}

		try {

			byte[] baSendData = null;
			if(isDev() == true) {
				baSendData = baOutStream.toByteArray();
			} else {
				if (baOutStream.size() == 0) {
					// 빈값 처리
					baOutStream.write(" ".getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);
					baOutStream.write(RECORD_DEL);
				}
				ByteArrayOutputStream baEncryptOutStream = new ByteArrayOutputStream();
				baEncryptOutStream.write(issacweb.getEncryptData(baOutStream, S_CHARSET));

				baSendData = baEncryptOutStream.toByteArray();
			}

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
		} catch (Exception e) {

			try {

				String errMsg = "Exceptino Msg = " + e.getMessage();
				baOutStream.write(errMsg.getBytes(S_CHARSET));

				byte[] baSendData = null;
				if(isDev() == true) {
					baSendData = baOutStream.toByteArray();
				} else {
					ByteArrayOutputStream baEncryptOutStream = new ByteArrayOutputStream();
					baEncryptOutStream.write(issacweb.getEncryptData(baOutStream, S_CHARSET));

					baSendData = baEncryptOutStream.toByteArray();
				}

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
			} catch (Exception ex) {
			}
		}
	}

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

	// 오늘이 휴일인지 체크하는 메서드
	// 휴일 모델을 넣고 오늘 요일, 일, 주를 넣어주면
	// 휴일에 repeatType을 기준으로 해당하는게 있는지 확인하는 방식
    private static boolean isTodayHoliday(Holiday holiday, int todayDayOfWeek, int todayDayOfMonth, int weekOfMonth) {
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
	
	// 임시휴무일 체크
	private static boolean isTodayTempHoliday(Holiday holiday, String strSelectDay) {
		if(holiday == null || strSelectDay == null || strSelectDay.contentEquals("")) {
			return false;
		}
		
		if(holiday.specificType != SPECIFIC_HOLIDAY_TEMP) {
			return false;
		}
		
		if(holiday.specialDay.contentEquals(strSelectDay)) {
			return true;
		}

		return false;
	}

	// HH : mm ~ HH : mm 포멧에 배열을 리턴
	// 유저가 선택할 수 있는 시간을 보여주기 위한 메서드
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

                String interval = outputFormat.format(intervalStart) + " ~ " + outputFormat.format(intervalEnd);
                intervals.add(interval);

                if (intervalEnd.equals(endDate)) {
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return intervals;
    }


	// 시간 HH:mm타입을 HHmm타입으로 포맷
    public static String parseToHHmmHHmm(String time) {
        return time.replaceAll(":", "").replaceAll(" ","").replaceAll("~","");
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

	private Holiday createHolidayFromResultSet(ResultSet rs) throws SQLException {
		String strRepeatType = rs.getString(1);
		String strHoliDaysDayOfWeek = rs.getString(2);
		String strHolidaysDayOfMonth = rs.getString(3);
		String strSpecificType = rs.getString(4);
		String strSpecialDay = rs.getString(5);

		int nSpecificRepeatType = strRepeatType != null && !strRepeatType.isEmpty()
				? Integer.parseInt(strRepeatType) : -1;
		int nHoliDaysDayOfWeek = strHoliDaysDayOfWeek != null && !strHoliDaysDayOfWeek.isEmpty()
				? Integer.parseInt(strHoliDaysDayOfWeek) : -1;
		int nHolidaysDayOfMonth = strHolidaysDayOfMonth != null && !strHolidaysDayOfMonth.isEmpty()
				? Integer.parseInt(strHolidaysDayOfMonth) : -1;
		int nSpecificType = strSpecificType != null && !strSpecificType.isEmpty()
				? Integer.parseInt(strSpecificType) : -1;
		if (strSpecialDay == null) {
			strSpecialDay = "";
		}

		return new Holiday(nSpecificRepeatType, nHoliDaysDayOfWeek, nHolidaysDayOfMonth, nSpecificType, strSpecialDay);
	}

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
		String strAvailable = "0";
		String strShorteningQuery = "SELECT COUNT(*) " +
				"FROM APT_COMMUNITY_SPECIFIC " +
				"WHERE APT_CODE = ? AND COMMUNITY_TYPE = ? AND SPECIAL_DAY = ? AND SPECIFIC_TYPE = '2' " +
				"AND ((? >= START_TIME AND ? < END_TIME) OR (? > START_TIME AND ? < END_TIME))";

		PreparedStatement pstmt = null;
		ResultSet rs = null;

		try {
			pstmt = conn.prepareStatement(strShorteningQuery);
			pstmt.setString(1, strAptCode);
			pstmt.setString(2, strCommunityType);
			pstmt.setString(3, strDate);
			pstmt.setString(4, strTime.substring(0, 4)); // 시작 HHmm
			pstmt.setString(5, strTime.substring(0, 4)); // 시작 HHmm
			pstmt.setString(6, strTime.substring(4, 8)); // 종료 HHmm
			pstmt.setString(7, strTime.substring(4, 8)); // 종료 HHmm

			rs = pstmt.executeQuery();
			if (rs.next()) {
				strAvailable = rs.getString(1);
			}
			if(strAvailable.contentEquals("1")){
				// 해당 날짜가 시간이 휴일로 되어 있는 경우
				return false;
			}			
			//System.out.println("strAvailable: " + strAvailable);

		}catch (Exception e){
			String errMsg = "Exceptino Msg = " + e.getMessage();
			return false;
		}	



		return true; // 예약 시간과 겹치지 않음
	}

	private static boolean isPublicHoliday(String strSelectDay, Connection conn){
		boolean isHoliday = false;

		String strHolidayQuery = "";
		strHolidayQuery += "SELECT COUNT(*) ";
		strHolidayQuery += "FROM HOLIDAYS ";
		strHolidayQuery += "WHERE HOLIDAY_DATE = '" + strSelectDay + "' ";
		
        PreparedStatement pstmt = null;
        ResultSet rs = null;
		try{
			pstmt = conn.prepareStatement(strHolidayQuery);
			rs = pstmt.executeQuery();
			if (rs.next()) {
				String strHolidayCount = rs.getString(1);
				if(!strHolidayCount.contentEquals("0")){
					isHoliday = true;
				}
			}
			return isHoliday;
		}catch (Exception e){
			String errMsg = "Exceptino Msg = " + e.getMessage();
			
			return isHoliday;
		}	
	}

	private static boolean isSpecialOperatingDay(String strAptCode, String strCommunityType, String strSelectDay, Connection conn){
		boolean isHoliday = false;

		String strHolidayQuery = "SELECT COUNT(*) ";
		strHolidayQuery += " FROM APT_COMMUNITY_SPECIFIC ";
		strHolidayQuery += " WHERE APT_CODE = '" + strAptCode + "' AND COMMUNITY_TYPE = '" + strCommunityType + "' AND SPECIFIC_TYPE = '4' ";
		strHolidayQuery += " AND SPECIAL_DAY = '" + strSelectDay + "' ";

		
        PreparedStatement pstmt = null;
        ResultSet rs = null;
		try{
			pstmt = conn.prepareStatement(strHolidayQuery);
			rs = pstmt.executeQuery();
			if (rs.next()) {
				String strHolidayCount = rs.getString(1);
				if(!strHolidayCount.contentEquals("0")){
					isHoliday = true;
				}
			}
			return isHoliday;
		}catch (Exception e){
			String errMsg = "Exceptino Msg = " + e.getMessage();
			
			return isHoliday;
		}	
	}

	// HHmm → 분으로 변환하는 유틸 메서드
	private static int parseTimeToMinutes(String hhmm) {
		int hour = Integer.parseInt(hhmm.substring(0, 2));
		int minute = Integer.parseInt(hhmm.substring(2, 4));
		return hour * 60 + minute;
	}

	private String getHolidaysQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, SPECIFIC_TYPE, SPECIAL_DAY " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND (SPECIFIC_TYPE = '0' OR SPECIFIC_TYPE = '3') " +
			"order by SPECIFIC_TYPE, SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK ASC ";
	}

	private String getShorteningQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, START_TIME, END_TIME " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND SPECIFIC_TYPE = '1'";
	}

	
	// 휴일 데이터 클래스
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
		
	private int getUUID() {
         UUID uuid = UUID.randomUUID();

        // UUID의 해시코드로 Int형 고유번호 생성
    	int uniqueId = Math.abs(uuid.hashCode());

        return uniqueId;
    }	


	public void callDevEntranceRegistrationAPI(String strUserId, String strReservationUserName,
	 String strReservationUserPhone, String strUUID,  String strDoorId, String strAptCode, String strCommunityType, Connection conn) {
    			
		String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v6.jsp";
        String strCallSID = "call_Entrance_api";

        try {
			    
            // 쿼리 파라미터 인코딩
            String query = String.format("SID=%s&strUserId=%s&strReservationUserName=%s&strReservationUserPhone=%s&strUUID=%s&strDoorId=%s&strAptCode=%s&strCommunityType=%s",
					URLEncoder.encode(strCallSID, "UTF-8"),
					URLEncoder.encode(strUserId, "UTF-8"),
                    URLEncoder.encode(strReservationUserName, "UTF-8"),
                    URLEncoder.encode(strReservationUserPhone, "UTF-8"),
					URLEncoder.encode(strUUID, "UTF-8"),
                    URLEncoder.encode(strDoorId, "UTF-8"),
					URLEncoder.encode(strAptCode, "UTF-8"),
					URLEncoder.encode(strCommunityType, "UTF-8"));
					
					
            
            // 전체 URL 생성
            String urlString = baseUrl + "?" + query;
            URL url = new URL(urlString);
			System.out.println("Request URL: " + url);

			HttpURLConnection connAPI = (HttpURLConnection) url.openConnection();
			connAPI.setRequestMethod("POST");

			// 응답 코드 확인 (실제로 응답을 기다리지 않음)
			int responseCode = connAPI.getResponseCode();
			System.out.println("Response Code: " + responseCode);


        } catch (IOException e) {
            e.printStackTrace();
        }
	}
		
	private String extractValue(String jsonString, String key, String field) {
		// JSONParser를 사용하여 JSON 문자열을 파싱
		JSONParser parser = new JSONParser();
		try {
			JSONObject jsonObject = (JSONObject) parser.parse(jsonString);

			// 주어진 key에 해당하는 JSONObject를 가져옴
			JSONObject targetObject = (JSONObject) jsonObject.get(key);
			if (targetObject != null) {
				// 주어진 field에 해당하는 값을 가져옴
				Object value = targetObject.get(field);
				return value != null ? value.toString() : null; // null 체크 후 문자열로 변환
			} else {
				System.out.println("Key not found: " + key);
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return ""; // 값이 없거나 오류가 발생한 경우 null 반환
	}

	public void callReservationTryAgain(String strReservationId, String strUsreImage){

    			
		String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v11.jsp";
        String strCallSID = "call_gosk_reservation_api";

        try {
			    
            // 쿼리 파라미터 인코딩
            String query = String.format("SID=%s&ImageURL=%s&ReservationId=%s",
					URLEncoder.encode(strCallSID, "UTF-8"),
					URLEncoder.encode(strUsreImage, "UTF-8"),
					URLEncoder.encode(strReservationId, "UTF-8")
                    );
					
					
            
            // 전체 URL 생성
            String urlString = baseUrl + "?" + query;
            URL url = new URL(urlString);
			System.out.println("Request URL: " + url);

			HttpURLConnection connAPI = (HttpURLConnection) url.openConnection();
			connAPI.setRequestMethod("POST");

			// 응답 코드 확인 (실제로 응답을 기다리지 않음)
			int responseCode = connAPI.getResponseCode();
			System.out.println("Response Code: " + responseCode);


        } catch (IOException e) {
            e.printStackTrace();
        }
	}	



    private String defaultIfNull(String value, String defaultValue) {
        return (value == null || value.trim().isEmpty()) ? defaultValue : value;
    }

	
%>

<%
Connection 			conn = null;			// DB Connection Object
PreparedStatement 	pstmt = null;			// JDBC PreparedStatement Object
ResultSet 			rs = null;	 			// Query Result Set Object

ResultSetMetaData 	rsMetaData = null;
IssacWeb					m_issacweb = null;

ResultSet 			rs_votecount = null;	 		// Query Result Set Object
ResultSet 			rs_community = null;	 		// Query Result Set Object

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
	if(isDev() == false) {
		m_issacweb = new IssacWeb(request);
	}
	// Get Parameter - SID = query 구분.
	String strSID = getRequestParam(m_issacweb, request, "SID");
	printLog("A", "SID : " + strSID);

    if(strSID.contentEquals("get_apt_security")){
		// 커뮤니티 시설 보안 사용여부
		// 20240627 얼굴 인식만 존재
        // 2026.05.08 얼굴 인식 기기(1)/QR 기기 (2) 추가 - 박지은(2026.05.08)
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		
		//아파트 코드가 없으면 안되지만 없는경우 쿼리가 오류가 발생해서 0값을 기본으로 설정		
        strAptCode = defaultIfNull(strAptCode,"0");

		String strQuery = "";
		strQuery += " SELECT SECURITY, COUNT(*) AS SECURITY_COUNT ";
		strQuery += " FROM APT_COMMUNITY ";
		strQuery += " WHERE APT_CODE = ? ";
		strQuery += " AND SECURITY IS NOT NULL ";
		strQuery += " AND SECURITY != '' ";
		strQuery += " AND SECURITY != '0' ";
		strQuery += " GROUP BY SECURITY ";
		strQuery += " ORDER BY SECURITY ASC ";

		pstmt = conn.prepareStatement(strQuery);
		pstmt.setString(1, strAptCode);

        rs = pstmt.executeQuery();

        ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		while(rs.next()){
            String strSecurity = defaultIfNull(rs.getString("SECURITY"), "");
            String strSecurityCount = defaultIfNull(rs.getString("SECURITY_COUNT"), "0");

            if(strSecurity.contentEquals("")){
                continue;
            }

            // 1. 보안 기기 타입
            baOutStream.write(strSecurity.getBytes(S_CHARSET));
            baOutStream.write(COLUMN_DEL);

            // 2. 기기 개수
            baOutStream.write(strSecurityCount.getBytes(S_CHARSET));
            baOutStream.write(RECORD_DEL);
		}

		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

 	}else if(strSID.contentEquals("get_available_schedule")){
		// 선택한 날짜에 사용가능한 자리, 시간을 리턴
		// 1. 시설에 자리, 이용가능 시간을 조회
		// 2. 선택한 날짜에 예약된 내역을 전부 조회
		// 3. json 구조를 자리에 배열로 시간, 이용가능여부를 만들어서 return
		// 만약 선택한 날짜가 오늘이면 EndTime이 현재 시간보다 큰것만 배열로 만들기
		// 중간에라도 이용하고 싶은 사람은 본인이 리스크를 감수하고 예약하는 정책으로 결정
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");
		String strDate = getRequestParam(m_issacweb,request,"SelectedDate");
		String strMembershipId = getRequestParam(m_issacweb,request,"MembershipId");
		String strSelectedUsers = getRequestParam(m_issacweb,request,"SelectedUsers");
		String strUUID = getRequestParam(m_issacweb,request,"UUID");
		String strDong = getRequestParam(m_issacweb,request,"UserDong");
		String strHo = getRequestParam(m_issacweb,request,"UserHo");
		String strUserName = getRequestParam(m_issacweb,request,"UserName");
		String strGender = getRequestParam(m_issacweb,request,"Gender");
		
        if(strMembershipId == null || strMembershipId.contentEquals("")){
			strMembershipId = "";
		}

        strMembershipId = defaultIfNull(strMembershipId,"");
        strAptCode = defaultIfNull(strAptCode,"0");
        strSelectedUsers = defaultIfNull(strSelectedUsers,"1");
        strAptCode = defaultIfNull(strAptCode,"0");
        strGender = defaultIfNull(strGender,"0");

		if(strDate == null || strDate.contentEquals("")){
			Calendar calToday = Calendar.getInstance();
			SimpleDateFormat sdfyyyyMMdd = new SimpleDateFormat("yyyyMMdd");
			strDate = sdfyyyyMMdd.format(calToday.getTime());	
		}

		String strLimitCount = "-1";
		String strLimitType = "";
		String strLimitUnit = "";
		String strImpossiblePlace = "";
		String strCommunityOpertaionHours = "";
		String strReserveTimeInterval = "";
		String strReserveTimeLintervalUnit = "";
		String strPlaceNames = "";
		String strServiceType = "";
		String strReservationType = "";
		String strCommunityPlaceNames = "";   // APT_COMMUNITY.PLACE_NAME
		String strMembershipPlaceNames = "";  // 회원권 MEMBERSHIP_PLACE

		String strCommunitySettingsQuery = "";
		strCommunitySettingsQuery += "SELECT IMPOSSIBLE_PLACE, OPERATION_HOURS, PLACE_NAME, SERVICE_TYPE ";
		strCommunitySettingsQuery += " FROM APT_COMMUNITY ";
		strCommunitySettingsQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strCommunitySettingsQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";

		pstmt = conn.prepareStatement(strCommunitySettingsQuery);
		rs = pstmt.executeQuery();
	
		if(rs.next()){		
			strImpossiblePlace = defaultIfNull(rs.getString("IMPOSSIBLE_PLACE"), "");
            strCommunityOpertaionHours = defaultIfNull(rs.getString("OPERATION_HOURS"), "");

			// APT_COMMUNITY.PLACE_NAME을 별도 변수에 저장
			strCommunityPlaceNames = defaultIfNull(rs.getString("PLACE_NAME"), "");

			// 기본 자리명은 APT_COMMUNITY.PLACE_NAME
			strPlaceNames = strCommunityPlaceNames;

			strServiceType = defaultIfNull(rs.getString("SERVICE_TYPE"), "");
		}
			
		if(strServiceType.contentEquals(IMMEDIATE_RESERVE) && (strMembershipId == null || strMembershipId.contentEquals(""))){		
			String strMembershipIdQuery = "";
			strMembershipIdQuery += "SELECT MEMBERSHIP_ID ";
			strMembershipIdQuery += "FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strMembershipIdQuery += "WHERE COMMUNITY_TYPE = ? ";
			strMembershipIdQuery += "AND APT_CODE = ? ";
			strMembershipIdQuery += "LIMIT 1 ";

			printLog("A","strMembershipIdQuery : " + strMembershipIdQuery);
			
			pstmt = conn.prepareStatement(strMembershipIdQuery);
			pstmt.setString(1, strCommunityType);
			pstmt.setString(2, strAptCode);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strMembershipId = defaultIfNull(rs.getString("MEMBERSHIP_ID"), "");
			}
		}			

		String strMembershipSettingsQuery = "";
		strMembershipSettingsQuery += " SELECT RESERVE_LIMIT_TYPE, RESERVE_LIMIT_UNIT, RESERVE_LIMIT, ";
		strMembershipSettingsQuery += " RESERVE_TIME_INTERVAL, RESERVE_TIME_INTERVAL_UNIT, MEMBERSHIP_PLACE, RESERVATION_TYPE "; 
		strMembershipSettingsQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipSettingsQuery += " WHERE MEMBERSHIP_ID = ? ";

		pstmt = conn.prepareStatement(strMembershipSettingsQuery);
		pstmt.setString(1, strMembershipId);
		rs = pstmt.executeQuery();

		printLog("A","strMembershipSettingsQuery : " + strMembershipSettingsQuery);

		if(rs.next()){
			strLimitType = defaultIfNull(rs.getString("RESERVE_LIMIT_TYPE"),"");
			strLimitUnit =  defaultIfNull(rs.getString("RESERVE_LIMIT_UNIT"),"");
			strLimitCount =  defaultIfNull(rs.getString("RESERVE_LIMIT"),"");
			strReserveTimeInterval =  defaultIfNull(rs.getString("RESERVE_TIME_INTERVAL"),"");
			strReserveTimeLintervalUnit =  defaultIfNull(rs.getString("RESERVE_TIME_INTERVAL_UNIT"),"");
			// strPlaceNames = (rs.getString("MEMBERSHIP_PLACE") != null && !rs.getString("MEMBERSHIP_PLACE").isEmpty()) ? rs.getString("MEMBERSHIP_PLACE") : strPlaceNames;
			strMembershipPlaceNames = defaultIfNull(rs.getString("MEMBERSHIP_PLACE"), "").trim();

			// 1순위: 회원권 자리명
			if (strMembershipPlaceNames != null && !strMembershipPlaceNames.contentEquals("")) {
				strPlaceNames = strMembershipPlaceNames;
			} else {
				// 2순위: 커뮤니티 기본 자리명
				strPlaceNames = strCommunityPlaceNames;
			}

			strReservationType = rs.getString("RESERVATION_TYPE") != null ? rs.getString("RESERVATION_TYPE") : "";
		}

		if(strPlaceNames != null && strPlaceNames.contentEquals("")){
			strPlaceNames = " ";
		}

		String strReservationCountQuery = "";		
		strReservationCountQuery += " SELECT COUNT(*) ";
		strReservationCountQuery += " FROM APT_COMMUNITY_RESERVE ";
		strReservationCountQuery += " WHERE APT_CODE = " + strAptCode + " ";

		if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_PERSON)){
		// 아이디당
			strReservationCountQuery += " AND USER_DONG = '" + strDong + "' AND USER_HO = '" + strHo + "' AND RESERVE_USER_NAME = '" + strUserName + "' ";
		}else if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_HOUSEHOLD)){
			// 세대당
			strReservationCountQuery += " AND USER_DONG = '" + strDong + "' AND USER_HO = '" + strHo + "' ";
		}
		strReservationCountQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";		

		if(strLimitUnit.contentEquals(RESERVE_LIMIT_UNIT_DAY)){
			//하루제한
			strReservationCountQuery += " AND DATE = '" + strDate + "' ";
		}else if(strLimitUnit.contentEquals(RESERVE_LIMIT_UNIT_WEEK)){
			// 주간 제한
			strReservationCountQuery += " AND DATE >= DATE_SUB(STR_TO_DATE('" + strDate + "', '%Y%m%d'), INTERVAL (DAYOFWEEK(STR_TO_DATE('" + strDate + "', '%Y%m%d')) + 5) % 7 DAY) ";
			strReservationCountQuery += " AND DATE < DATE_ADD(DATE_SUB(STR_TO_DATE('" + strDate + "', '%Y%m%d'), INTERVAL (DAYOFWEEK(STR_TO_DATE('" + strDate +"', '%Y%m%d')) + 5) % 7 DAY), INTERVAL 7 DAY) ";			
		}

		if(strMembershipId != null && !strMembershipId.contentEquals("")){
			strReservationCountQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";
		}			

		strReservationCountQuery += " AND (RESERVE_CANCEL_TIME = '' OR RESERVE_CANCEL_TIME IS NULL) ";
	
		printLog("A","strReservationCountQuery : " + strReservationCountQuery);

		pstmt = conn.prepareStatement(strReservationCountQuery);
		rs = pstmt.executeQuery();

		String strReservationCount = "";
		if(rs.next()){
			strReservationCount = rs.getString(1);
		}

		boolean isMaxReserve = false;

		if(strLimitCount != null && !strLimitCount.contentEquals("") && Integer.parseInt(strReservationCount) >= Integer.parseInt(strLimitCount)){
			isMaxReserve = true;
		}	
	
		String strStartTime = "";
		String strEndTime = "";
		int nIntervalMinutes = -1;

		//해당 하는 커뮤니티에 자리, 시작시간, 종료시간, 시간 간격을 먼저 조회하기
		if(!strCommunityOpertaionHours.contentEquals("")) {
			SimpleDateFormat sdfOperationHours = new SimpleDateFormat("yyyyMMdd");		
			Date dateOperationHours = sdfOperationHours.parse(strDate);
			Calendar calendarOperationHours = Calendar.getInstance();
			calendarOperationHours.setTime(dateOperationHours);

			// 요일 확인 (1: 일요일, 2: 월요일, ..., 7: 토요일)
			int dayOfWeekOperationHours = calendarOperationHours.get(Calendar.DAY_OF_WEEK);

			if (dayOfWeekOperationHours == Calendar.SATURDAY || dayOfWeekOperationHours == Calendar.SUNDAY) {
				// 주말인 경우
				strStartTime = extractValue(strCommunityOpertaionHours, "WEEKEND", "start");
				strEndTime = extractValue(strCommunityOpertaionHours, "WEEKEND", "end");
			} else {
				// 평일인 경우
				strStartTime = extractValue(strCommunityOpertaionHours, "WEEKDAY", "start");
				strEndTime = extractValue(strCommunityOpertaionHours, "WEEKDAY", "end");
			}
		}
		
		nIntervalMinutes = Integer.parseInt(strReserveTimeInterval);	

		// 시간 설정 못 가져오면 클라이언트에 에러코드 리턴
		// 에러 코드 미정
		if(nIntervalMinutes == -1){
			return;
		}
		
		String strShortening = getShorteningQuery(strAptCode, strCommunityType);

		pstmt = conn.prepareStatement(strShortening);
		rs = pstmt.executeQuery();

		List<Shortening> shortenings = new ArrayList<Shortening>();

		rsMetaData = rs.getMetaData();

		// 먼저 휴일인지를 체크 holidays, strDate 값으로 휴일을 비교
      	// 날짜 형식을 지정하여 SimpleDateFormat 객체 생성
        SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
		int todayDayOfWeek = -1;
		int todayDayOfMonth = -1;
		int weekOfMonth = -1;
        try {
            // 문자열을 Date 객체로 변환
            Date date = sdf.parse(strDate);
            
            // Date 객체를 Calendar 객체에 설정
            Calendar selectedDate = Calendar.getInstance();
            selectedDate.setTime(date);

            // 오늘의 요일 및 일자 정보
        	todayDayOfWeek = selectedDate.get(Calendar.DAY_OF_WEEK) - 1; // Calendar.DAY_OF_WEEK는 1(일요일)부터 시작
            todayDayOfMonth = selectedDate.get(Calendar.DAY_OF_MONTH);
            weekOfMonth = selectedDate.get(Calendar.WEEK_OF_MONTH);

        } catch (ParseException e) {
            e.printStackTrace();
        }
				
		// 자바 1.7이전 버전에서는 switch문에 문자열이 안 됨...
		// int 타입으로 변경
		for(int nSpecificRow = 0; rs.next(); nSpecificRow++) {
			String strSpecificRepeatType =  rs.getString(1);
			String strSpecificDayOfWeek = rs.getString(2);
			String strSpecificDayOfMonth = rs.getString(3);
			String strSpecificStartTime = rs.getString(4);
			String strSpecificEndTime = rs.getString(5);
			int nRepeatType = -1;
			int nSpecificDayOfWeek = -1;
			int nSpecificDayOfMonth = -1;

			if(strSpecificRepeatType != null && !strSpecificRepeatType.contentEquals("")){
				nRepeatType = Integer.parseInt(strSpecificRepeatType);
			}

			if(strSpecificDayOfWeek != null && !strSpecificDayOfWeek.contentEquals("")){
				nSpecificDayOfWeek = Integer.parseInt(strSpecificDayOfWeek);
			}

			if(strSpecificDayOfMonth != null && !strSpecificDayOfMonth.contentEquals("")){
				nSpecificDayOfMonth = Integer.parseInt(strSpecificDayOfMonth);
			}

			if(strSpecificStartTime != null && !strSpecificStartTime.contentEquals("") && strSpecificEndTime != null && !strSpecificEndTime.contentEquals("")){
				shortenings.add(new Shortening(nRepeatType, nSpecificDayOfWeek, nSpecificDayOfMonth, strSpecificStartTime, strSpecificEndTime)); // 매주 월요일					
			}
		}

		// ture : 단축 , false : 단축 아님
		// 단축이면 strStartTime, strEndTime 변경
        for (Shortening shortening : shortenings) {
					
			// 매주 반복이고 todayDayOfWeek가 같으면 단축
			if(shortening.repeatType == 0 && todayDayOfWeek == shortening.dayOfWeek){
				strStartTime = shortening.StartTime;
				strEndTime = shortening.EndTime;
 			}else if(shortening.repeatType == weekOfMonth && todayDayOfWeek == shortening.dayOfWeek){
				strStartTime = shortening.StartTime;
				strEndTime = shortening.EndTime;
			}else{

			}
        }

		// 커뮤니티 시설 자리에 대한 포맷
		List<String> placeNames = new ArrayList<String>();	

		// 쉼표를 기준으로 분할
		if(strPlaceNames.contains("\",\"")){
			String[] parts = strPlaceNames.split("\",\"");

			// 분할된 문자열 출력
			for (String part : parts) {
				// 각 부분의 앞뒤 따옴표 제거
				part = part.replaceAll("^\"|\"$", "");
				placeNames.add(part);
			}
		}else{
			if (strPlaceNames != null && strPlaceNames.length() > 0) {
        	    strPlaceNames = strPlaceNames.replaceAll("^\"|\"$", ""); // 정규식을 사용하여 문자열의 앞뒤에 있는 따옴표를 제거합니다.
        	}
			placeNames.add(strPlaceNames);
		}

		// 예약 가능한 시간을 구하기
		// 시작시간, 종료 시간, 시간 간격을 넣으면 HH : mm ~ HH : mm 형태로 리스트를 만들기
		// intervals는 HH : mm ~ HH : mm 타입에 배열
		// intervalsFormHHmmHHmm는 HHmmHHmm 타입에 배열
		// strDate가 오늘이면 현재 시간보다 큰 시간만 만들기

		Calendar today = Calendar.getInstance();

        SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmm");
		SimpleDateFormat dateFormatyyyyMMdd = new SimpleDateFormat("yyyyMMdd");

        String formattedDateHHmm = dateFormatHHmm.format(today.getTime());
		String formattedDateyyyyMMdd = dateFormatyyyyMMdd.format(today.getTime());

        int nNowTime = Integer.parseInt(formattedDateHHmm);

		// 오늘이고 오늘 오픈 가능 시간보다 현재시간이 작은 경우
	
        // HH 부분을 추출하여 시간 값으로 변환
        int currentHour = Integer.parseInt(formattedDateHHmm.substring(0, 2));
		boolean isClosed = false;

		if(formattedDateyyyyMMdd.contentEquals(strDate) && nNowTime > Integer.parseInt(strEndTime)){
			//strStartTime = String.valueOf(currentHour + 1) + "00";
			isClosed = true;
		}

		//List<String> intervals = getTimeIntervals(strStartTime, strEndTime, nIntervalMinutes);	
		List<String> intervals = getTimeIntervals(strStartTime, strEndTime, nIntervalMinutes, strReserveTimeLintervalUnit);		
		List<String> intervalsFormHHmmHHmm = new ArrayList<String>();

		for (String strInterval : intervals) {
			intervalsFormHHmmHHmm.add(parseToHHmmHHmm(strInterval));
        }

		//리스트에 있는 데이터를 기준으로 해당 예약건을 조회해서 비교 or 해당 날짜의 모든 예약건을 가져와서 비교
		// 쿼리를 생각해서 한번에 조회해오는걸로 선택했습니다.
		// TIME, PLACE 날짜, 시간, 자리만 조회
		// Reservation모델에 자리, 시간값 셋
		List<Reservation> reservations = new ArrayList<Reservation>();				

		String strSelectedReservationQuery = "";
		strSelectedReservationQuery += " SELECT PLACE, TIME ";
		strSelectedReservationQuery += " FROM APT_COMMUNITY_RESERVE ";
		strSelectedReservationQuery += " WHERE APT_CODE = '" + strAptCode +  "' AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
		strSelectedReservationQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
		strSelectedReservationQuery += " AND DATE = '" + strDate + "' AND RESERVE_CANCEL_TIME IS NULL; ";
		
		printLog("A","strSelectedReservationQuery : " + strSelectedReservationQuery);

		pstmt = conn.prepareStatement(strSelectedReservationQuery);
		rs = pstmt.executeQuery();
		rsMetaData = rs.getMetaData();
		
		for(int nRow = 0; rs.next(); nRow++) {
			String strPlaceName =  rs.getString(1);
			String strReservTime = rs.getString(2);
			reservations.add(new Reservation(strPlaceName, strReservTime));        	
        }

		// 휴일 정보를 가져와서 데이터 클래스로 변환
		// 선택한 날짜가 휴일인지, 예약 마감인지, 아니면 예약 가능한지 체크를 하기 위함
		// 먼저 isTodayHoliday()메서드를 통해서 먼저 휴일인지 비교 후 
		// 휴일이 아니면 나머지는 enabled, disable로 표시
		String strHolidaysQuery = getHolidaysQuery(strAptCode,strCommunityType);

		pstmt = conn.prepareStatement(strHolidaysQuery);
		rs = pstmt.executeQuery();
		rsMetaData = rs.getMetaData();
		
		List<Holiday> holidays = new ArrayList<Holiday>();

		// 자바 1.7이전 버전에서는 switch문에 문자열이 안 됨...
		// int 타입으로 변경

		boolean isHolidaysType = false;

		for(int nRow = 0; rs.next(); nRow++) {
			String strRepeatType =  rs.getString(1);

			if(strRepeatType.contentEquals("9")){
				isHolidaysType = true;
			}

			String strHoliDaysDayOfWeek = rs.getString(2);
			String strHolidaysDayOfMonth = rs.getString(3);
			String strSpecificType = rs.getString(4);
			String strSpecialDay = rs.getString(5);
			int nSpecificRepeatType = -1;
			int nHoliDaysDayOfWeek = -1;
			int nHolidaysDayOfMonth = -1;
			int nSpecificType = -1;

			if(strRepeatType != null && !strRepeatType.contentEquals("")){
				nSpecificRepeatType = Integer.parseInt(strRepeatType);
			}

			if(strHoliDaysDayOfWeek != null && !strHoliDaysDayOfWeek.contentEquals("")){
				nHoliDaysDayOfWeek = Integer.parseInt(strHoliDaysDayOfWeek);
			}

			if(strHolidaysDayOfMonth != null && !strHolidaysDayOfMonth.contentEquals("")){
				nHolidaysDayOfMonth = Integer.parseInt(strHolidaysDayOfMonth);
			}

			if(strSpecificType != null && !strSpecificType.contentEquals("")){
				nSpecificType = Integer.parseInt(strSpecificType);
			}

			if(strSpecialDay == null) {
				strSpecialDay = "";
			}

        	holidays.add(new Holiday(nSpecificRepeatType, nHoliDaysDayOfWeek, nHolidaysDayOfMonth, nSpecificType, strSpecialDay)); // 매주 월요일
		}

		// 자리, 시간, 예약건을 조합해서 json타입으로 변환
		// 자리 : [{
		// time : 시간,
		//  available : 1 }]
		// 포맷
		JSONArray jsonArray = new JSONArray();
		JSONObject placeInfo = new JSONObject();
		JSONArray timeAvailabilityList = new JSONArray();
		// 휴일은 기본 false 
		boolean isHoliday = false;
		// 임시휴무일 체크
		boolean isTempHoliday = false;

        // 휴일 체크 로직
		// isTodayHoliday()  
		// Params : Holiday모델, 오늘의 요일, 일, 주
		// ture : 휴일 , false : 휴일 아님
        for (Holiday holiday : holidays) {
        	if (isTodayHoliday(holiday, todayDayOfWeek, todayDayOfMonth, weekOfMonth)) {            
				isHoliday = true;
         	} else {
				if(strDate != null && !strDate.contentEquals("") && 8 <= strDate.length()) {
					String strSelectDay = strDate.substring(0, 8);
					if(isTodayTempHoliday(holiday, strSelectDay)) {
						isTempHoliday = true;
						isHoliday = true;
					}
				}
            }
        }

		if(isHolidaysType){
			// 선택일이 공휴일 테이블에 포함되어 있으면..휴무일
			// strDate
			String strHolidayQuery = "";
			strHolidayQuery += "SELECT COUNT(*) ";
			strHolidayQuery += "FROM HOLIDAYS ";
			strHolidayQuery += "WHERE HOLIDAY_DATE = '" + strDate + "' ";

			pstmt = conn.prepareStatement(strHolidayQuery);
			rs = pstmt.executeQuery();
			if(rs.next()){
				String strHolidayCount = rs.getString(1);
				if(!strHolidayCount.contentEquals("0")){
					isHoliday = true;
				}
			}
		}			

		// operation_hours
		// 운영시간이 별도로 json으로 존재하면 
		String strTestQuery = "SELECT MEMBERSHIP_PLACE, " +
								" OPERATION_HOURS " +
								" FROM APT_COMMUNITY_MEMBERSHIP_INFO " +
								" WHERE COMMUNITY_TYPE = ? " +
								" AND APT_CODE = ? " +
								" AND MEMBERSHIP_ID = ? " +
								" AND OPERATION_HOURS LIKE '%reservations%' "; // reservations 배열이 존재하는 경우만 찾기
		// 개발서버랑 코드가 다름
		//	" AND JSON_EXTRACT(OPERATION_HOURS, '$.reservations') IS NOT NULL"; // reservations 배열이 존재하는 경우만 찾기

		printLog("A","strTestQuery : " + strTestQuery);

		pstmt = conn.prepareStatement(strTestQuery);
		pstmt.setString(1, strCommunityType);
		pstmt.setString(2, strAptCode);
		pstmt.setString(3, strMembershipId);
		rs = pstmt.executeQuery();

		// 3가지 케이스
		// 1. 휴일 , 2. 예약 마감, 3. 예약 자리
		// isTodayHoliday()메서드로 확인한 휴일로 먼저 비교 후
		// 휴일이 아니면 2중 for문으로 isAvailable() 메서드에 모든 값이 false인지 체크 
		// 모든 값이 false면 이용가능한 자리, 시간이 없는거니가 예약 마감으로 변경
		boolean isReservationClosed = true;

		if(isHoliday){
			JSONObject timeInfo = new JSONObject();

			if(isTempHoliday) {
				timeInfo.put("time", "센터 임시휴일");
			} else{
				timeInfo.put("time", "센터 정기휴일");
			}

			timeInfo.put("available", false);
			timeInfo.put("color", "red");
			timeAvailabilityList.add(timeInfo);

			String strHolidayPlaceName = "";

			// 1순위: APT_COMMUNITY.PLACE_NAME
			if (strCommunityPlaceNames != null && !strCommunityPlaceNames.trim().contentEquals("")) {
				strHolidayPlaceName = strCommunityPlaceNames;

			// 2순위: APT_COMMUNITY_MEMBERSHIP_INFO.MEMBERSHIP_PLACE
			} else if (strMembershipPlaceNames != null && !strMembershipPlaceNames.trim().contentEquals("")) {
				strHolidayPlaceName = strMembershipPlaceNames;
			}

			strHolidayPlaceName = strHolidayPlaceName.replaceAll("^\"|\"$", "").trim();

			printLog("A", "[휴일 JSON 자리]"
						+ " / COMMUNITY_PLACE : [" + strCommunityPlaceNames + "]"
						+ " / MEMBERSHIP_PLACE : [" + strMembershipPlaceNames + "]"
						+ " / FINAL_PLACE : [" + strHolidayPlaceName + "]");

			placeInfo.put("place", "");
			// placeInfo.put("place", strHolidayPlaceName);
			placeInfo.put("availability", timeAvailabilityList);
			jsonArray.add(placeInfo);
		}else if(isMaxReserve){
			JSONObject timeInfo = new JSONObject();
			printLog("A","strLimitUnit : " +strLimitUnit);
			printLog("A","strLimitType : " +strLimitType);

			if(strLimitUnit.contentEquals(RESERVE_LIMIT_UNIT_DAY)){				
				if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_PERSON)){
					// 아이디당
					timeInfo.put("time", "금일 예약 횟수를 모두 사용하셨습니다.");
				}else if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_HOUSEHOLD)){
					// 세대당
					timeInfo.put("time", "금일 해당 세대에 예약 횟수를 모두 사용하셨습니다.");
				}
			}else if(strLimitUnit.contentEquals(RESERVE_LIMIT_UNIT_WEEK)){
				if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_PERSON)){
					// 아이디당
					timeInfo.put("time", "금주 예약 횟수를 모두 사용하셨습니다.");
				}else if(strLimitType.contentEquals(RESERVE_LIMIT_TYPE_HOUSEHOLD)){
					// 세대당
					timeInfo.put("time", "금주 해당 세대에 예약 횟수를 모두 사용하셨습니다.");
				}					
			}
					
			timeInfo.put("available", false);
			timeInfo.put("color", "red");
			timeAvailabilityList.add(timeInfo);

			placeInfo.put("place", "");
			placeInfo.put("availability", timeAvailabilityList);
			jsonArray.add(placeInfo);
		}else if (rs.next()) {
			// strPlaceNames = rs.getString("MEMBERSHIP_PLACE");
			String strReservationMembershipPlace = defaultIfNull(rs.getString("MEMBERSHIP_PLACE"), "").trim();

			printLog("A",  "[reservations 분기 진입]"
							+ " / strCommunityPlaceNames : [" + strCommunityPlaceNames + "]"
							+ " / DB MEMBERSHIP_PLACE : [" + strReservationMembershipPlace + "]");

			// APT_COMMUNITY.PLACE_NAME이 없을 때만 회원권 자리 사용
			if ((strCommunityPlaceNames == null || strCommunityPlaceNames.trim().contentEquals("")) && !strMembershipPlaceNames.contentEquals("")) {
				strPlaceNames = strMembershipPlaceNames;
			}

			printLog("A", "[회원권 자리]"
							+ " / COMMUNITY_PLACE : [" + strCommunityPlaceNames + "]"
							+ " / MEMBERSHIP_PLACE : [" + strMembershipPlaceNames + "]"
							+ " / 최종 strPlaceNames : [" + strPlaceNames + "]");

			// 1순위: 현재 회원권 MEMBERSHIP_PLACE
			if (!strReservationMembershipPlace.contentEquals("")) {
				strPlaceNames = strReservationMembershipPlace;

			// 2순위: APT_COMMUNITY.PLACE_NAME
			} else if (strCommunityPlaceNames != null
					&& !strCommunityPlaceNames.trim().contentEquals("")) {
				strPlaceNames = strCommunityPlaceNames;

			} else {
				strPlaceNames = "";
			}

			printLog("A", "[reservations 최종 자리]" + " / strPlaceNames : [" + strPlaceNames + "]");

			String strOperationJson = rs.getString("OPERATION_HOURS");

			jsonArray.clear(); // 기존 데이터 제거

			// OPERATION_HOURS를 JSON 객체로 변환
			JSONParser parser = new JSONParser();
			JSONObject operationHoursJson = (JSONObject) parser.parse(strOperationJson);

			// 현재 날짜의 요일 계산
			SimpleDateFormat sdfOperationHours = new SimpleDateFormat("yyyyMMdd");
			Date dateOperationHours = sdfOperationHours.parse(strDate);
			Calendar calendarOperationHours = Calendar.getInstance();
			calendarOperationHours.setTime(dateOperationHours);
			int dayOfWeekOperationHours = calendarOperationHours.get(Calendar.DAY_OF_WEEK);

			// 평일/주말 구분
			String dayType;

			if (dayOfWeekOperationHours == Calendar.SATURDAY || dayOfWeekOperationHours == Calendar.SUNDAY) {
				dayType = "WEEKEND";
			} else {
				dayType = "WEEKDAY";
			}

			// 해당 요일의 reservations 배열 추출
			JSONObject selectedDayJson = (JSONObject) operationHoursJson.get(dayType);
			JSONArray reservationsArray = (JSONArray) selectedDayJson.get("reservations");

			// 장소 이름 배열 분리
			String[] strPlaceNamesArray = strPlaceNames.split(",");

			for (String strPlaceName : strPlaceNamesArray) {
				timeAvailabilityList = new JSONArray();

				for (int i = 0; i < reservationsArray.size(); i++) {
					String actualTime = (String) reservationsArray.get(i); // 예약 시간 가져오기
					String strReservationTypePlaceName = strPlaceName.replaceAll("\"", "");

					if (strReservationType.contentEquals(RESERVE_TYPE_RENTAL)) {
						strReservationTypePlaceName = "PLACE_ALL";
					}

					boolean isAvailablity = isAvailable(reservations,
														strReservationTypePlaceName,
														actualTime.replaceAll(":", "").replaceAll("~", ""),
														strDate,
														strCommunityType,
														strAptCode,
														conn);

					if (isAvailablity) {
						isReservationClosed = false;
					}

					JSONObject timeInfo = new JSONObject();
					timeInfo.put("time", actualTime);
					timeInfo.put("available", isAvailablity);
					timeInfo.put("color", isAvailablity ? "black" : "gray300");
					timeAvailabilityList.add(timeInfo);
				}

				placeInfo = new JSONObject();
				placeInfo.put("place", strPlaceName.replaceAll("\"", ""));
				placeInfo.put("availability", timeAvailabilityList);

				jsonArray.add(placeInfo);
			}
			printLog("D","jsonArray : " + jsonArray.toString());
			
		}else{
			JSONArray jsonArrayImpossiblePlace = new JSONArray(); // 빈 JSONArray로 초기화
			
			if (strImpossiblePlace != null && !strImpossiblePlace.contentEquals("")) {
				// JSONParser 객체 생성
				JSONParser impossiblePlaceParser = new JSONParser();

				// JSON 문자열 파싱 -> JSONArray 객체로 변환
				Object obj = impossiblePlaceParser.parse(strImpossiblePlace);
				
				// obj가 JSONArray인지 확인 후 캐스팅
				if (obj instanceof JSONArray) {
					jsonArrayImpossiblePlace = (JSONArray) obj;
				} else {
					// obj가 JSONArray가 아닐 경우 처리
					jsonArrayImpossiblePlace = new JSONArray(); // 빈 JSONArray로 초기화
				}
			}
			
			for (String place : placeNames) {
				// strDate 선택한날짜라 시작시간, 종료시간을 각 각 조합해서 불가능한 시간대에 포함되는지 체크
				placeInfo = new JSONObject(); 
				timeAvailabilityList = new JSONArray();
				boolean isPossible = true;
				String strReason = "";

				// 배열 내 각 JSONObject 순회
				if (jsonArray != null) {
					boolean hasAddedUnavailableInfo = false; // 불가능한 시간대 정보 추가 여부 플래그

					for (int j = 0; j < intervalsFormHHmmHHmm.size(); j++) {

						String timeToCompare = intervalsFormHHmmHHmm.get(j);
						String actualTime = intervals.get(j);
						String actualTimeFormatted = strDate + actualTime.replaceAll(":", "").replaceAll(" ", "").replaceAll("~", "").substring(0, 4);
						String strReservationTypePlaceName = place.replaceAll("\"", "");
						if(strReservationType.contentEquals(RESERVE_TYPE_RENTAL)){
							strReservationTypePlaceName = "PLACE_ALL";
						}

						boolean isAvailablity = isAvailable(reservations, strReservationTypePlaceName, timeToCompare, strDate,strCommunityType,strAptCode, conn);
		
						if (isAvailablity) {                            
							isReservationClosed = false;
						}
						JSONObject timeInfo = new JSONObject();
						boolean isUnavailable = false; // 불가능한 시간대 체크 플래그

						// jsonArrayImpossiblePlace를 순회하여 불가능한 시간대 체크
						for (int i = 0; i < jsonArrayImpossiblePlace.size(); i++) {
							JSONObject jsonObj = (JSONObject) jsonArrayImpossiblePlace.get(i);
							String name = (String) jsonObj.get("name") != null ? (String) jsonObj.get("name") : "";
							String reason = (String) jsonObj.get("reason") != null ? (String) jsonObj.get("reason") : "";
							String unavailableFrom = (String) jsonObj.get("unavailable_from") != null ? (String) jsonObj.get("unavailable_from") : "";
							String unavailableTo = (String) jsonObj.get("unavailable_to") != null ? (String) jsonObj.get("unavailable_to") : "";

							if (name != null) {
								String[] names = name.split(",");
								for (String n : names) {
									if (place.contentEquals(n)) {
										// unavailableFrom과 unavailableTo가 yyyyMMddHHmm 포맷인지 확인
										if (unavailableFrom.length() == 12 && unavailableTo.length() == 12) {
											// 불가능한 시간대 체크
											if (actualTimeFormatted.compareTo(unavailableFrom) >= 0 && actualTimeFormatted.compareTo(unavailableTo) <= 0) {
												// 불가능한 시간대가 발견되면 한 번만 추가
												if (!hasAddedUnavailableInfo) {
													if(formattedDateyyyyMMdd.contentEquals(strDate) && Integer.parseInt(actualTime.replaceAll(":","").replaceAll(" ", "").replaceAll("~", "").substring(4,8)) < Integer.parseInt(formattedDateHHmm)){
														//timeInfo.put("time", actualTime);
														//timeInfo.put("available", isAvailablity);
														//timeInfo.put("color", isAvailablity ? "black" : "gray300");
														//timeAvailabilityList.add(timeInfo);
													}else{
														timeInfo.put("time", reason);
														timeInfo.put("available", false);
														timeInfo.put("color", "gray500");
														timeAvailabilityList.add(timeInfo);
														hasAddedUnavailableInfo = true; // 추가했음을 표시
													}									
												}
												isUnavailable = true; // 불가능한 경우
												isPossible = false; // 불가능한 경우
												break; // 더 이상 체크할 필요 없음
											}
										}else if (unavailableFrom.length() == 12 && unavailableTo.length() != 12) {
											// unavailableFrom이 존재할 경우
											if (actualTimeFormatted.compareTo(unavailableFrom) >= 0) {
												// 불가능한 경우
												if (!hasAddedUnavailableInfo) {
													timeInfo.put("time", reason);
													timeInfo.put("available", false);
													timeInfo.put("color", "gray500");
													timeAvailabilityList.add(timeInfo);
													hasAddedUnavailableInfo = true; // 추가했음을 표시
												}
												isUnavailable = true; // 불가능한 경우
												isPossible = false; // 불가능한 경우
											}
										}else if (unavailableTo.length() == 12 && unavailableFrom.length() != 12) {
											// unavailableTo가 존재할 경우
											if (actualTimeFormatted.compareTo(unavailableTo) <= 0) {
												// 불가능한 경우
												if (!hasAddedUnavailableInfo) {
													timeInfo.put("time", reason);
													timeInfo.put("available", false);
													timeInfo.put("color", "gray500");
													timeAvailabilityList.add(timeInfo);
													hasAddedUnavailableInfo = true; // 추가했음을 표시
												}
												isUnavailable = true; // 불가능한 경우
												isPossible = false; // 불가능한 경우
											}
										}else{
											if (!hasAddedUnavailableInfo) {
												timeInfo.put("time", reason);
												timeInfo.put("available", false);
												timeInfo.put("color", "gray500");
												timeAvailabilityList.add(timeInfo);
												hasAddedUnavailableInfo = true; // 추가했음을 표시
											}
											isUnavailable = true; // 불가능한 경우
											isPossible = false; // 불가능한 경우
										}
									}
								}
							}
						}

						// 불가능한 경우가 아닐 때만 timeInfo 추가
						if (!isUnavailable) {
							if(formattedDateyyyyMMdd.contentEquals(strDate) &&
								Integer.parseInt(actualTime.replaceAll(":","").replaceAll(" ", "").replaceAll("~", "").substring(4,8)) < Integer.parseInt(formattedDateHHmm) &&
								!actualTime.replaceAll(":","").replaceAll(" ", "").replaceAll("~", "").substring(4,8).contentEquals("0000")){

							}else{
								timeInfo = new JSONObject(); // 새로운 JSONObject 생성
								timeInfo.put("time", actualTime);
								timeInfo.put("available", isAvailablity);
								timeInfo.put("color", isAvailablity ? "black" : "gray300");
								timeAvailabilityList.add(timeInfo);
							}
						}
					}
				}

				// 최종적으로 placeInfo에 추가
				placeInfo.put("place", place);
				placeInfo.put("availability", timeAvailabilityList);
				jsonArray.add(placeInfo);
			}

			if (isReservationClosed) {
				jsonArray.clear(); // 기존 데이터 제거
				JSONObject timeInfo = new JSONObject();
				timeInfo.put("time", "예약 마감");
				timeInfo.put("available", false);
				timeInfo.put("color", "black");

				placeInfo = new JSONObject();
				placeInfo.put("place", ""); // 빈 장소 이름
				timeAvailabilityList = new JSONArray();
				timeAvailabilityList.add(timeInfo);
				placeInfo.put("availability", timeAvailabilityList);

				jsonArray.add(placeInfo);
			}else if(isClosed){
				jsonArray.clear(); // 기존 데이터 제거
				JSONObject timeInfo = new JSONObject();
				timeInfo.put("time", "운영 종료");
				timeInfo.put("available", false);
				timeInfo.put("color", "black");

				placeInfo = new JSONObject();
				placeInfo.put("place", ""); // 빈 장소 이름
				timeAvailabilityList = new JSONArray();
				timeAvailabilityList.add(timeInfo);
				placeInfo.put("availability", timeAvailabilityList);

				jsonArray.add(placeInfo);
			}
		}
		
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write(jsonArray.toString().getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("register_user_face")) {
		//사진 등록하기 
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");		
		String strImageUrl = getRequestParam(m_issacweb, request, "ImageUrl");
		String strDong = getRequestParam(m_issacweb, request, "UserDong");
		String strHo = getRequestParam(m_issacweb, request, "UserHo");
		String strName = getRequestParam(m_issacweb, request, "UserName");
		String strUserPhoneNo = getRequestParam(m_issacweb, request, "UserPhoneNo");
		String strUUID = getRequestParam(m_issacweb, request, "UUID"); // 재등록시 기존 UUID에 업데이트
		
		if(strAptCode == null ||strAptCode.isEmpty()) {
			strAptCode = "0";
		}

		if(strUserId == null ){
			strUserId = "";
		}

		if(strDong == null){
			strDong = "";	
		}
		if(strHo == null){
			strHo = "";	
		}
		if(strName == null || strName.contentEquals("")){
			String strUserNameQuery = "";
			strUserNameQuery += " SELECT USER_NAME ";
			strUserNameQuery += " FROM USER_INFO ";
			strUserNameQuery += " WHERE 1 = 1 ";
			strUserNameQuery += " AND  APT_CODE = " + strAptCode + " ";
			strUserNameQuery += " AND  USER_ID = '" + strUserId + "' ";


			pstmt = conn.prepareStatement(strUserNameQuery);
			rs = pstmt.executeQuery();
		
			if(rs.next()) {
				strName = rs.getString(1) != null ? rs.getString(1) : "";		
			}

		}

		if(strUserPhoneNo == null || strUserPhoneNo.contentEquals("")){
			String strUserPhoneQuery = "";
			strUserPhoneQuery += " SELECT USER_PHONE ";
			strUserPhoneQuery += " FROM USER_INFO ";
			strUserPhoneQuery += " WHERE 1 = 1 ";
			strUserPhoneQuery += " AND  APT_CODE = " + strAptCode + " ";
			strUserPhoneQuery += " AND  USER_ID = '" + strUserId + "' ";


			pstmt = conn.prepareStatement(strUserPhoneQuery);
			rs = pstmt.executeQuery();
		
			if(rs.next()) {
				strUserPhoneNo = rs.getString(1) != null ? rs.getString(1) : "";		
			}
		}

		
		
		if(strUUID == null || strUUID.contentEquals("")){
			strUUID = "0";
		}

		// 사진이 등록되어 있는지 확인
		// 이미 등록된 사진이 없으면 insert 
		// 기존에 등록된 사진이 있으면 업데이트 

		String strCountQuery = "";
		strCountQuery += "SELECT COUNT(*) ";
		strCountQuery += "FROM APT_COMMUNITY_USER_INFO ";
		strCountQuery += "WHERE APT_CODE = " + strAptCode + " ";
		if(strUUID.contentEquals("0")){
			strCountQuery += "AND DONG = '" + strDong + "' ";
			strCountQuery += "AND HO = '" + strHo + "' ";
			strCountQuery += "AND NAME = '" + strName + "' ";			
		}else{
			strCountQuery += "AND UUID = " + strUUID + " ";
		}
		

		
		pstmt = conn.prepareStatement(strCountQuery);
		rs = pstmt.executeQuery();

		String resultCnt = new String();
		if(rs.next()) {
			resultCnt = rs.getString(1);	
		}

		printLog("A", "strCountQuery" + strCountQuery);

		

		// 유저의 고유 값을 만들어야 주 출입구에 데이터를 넣어줄 수 있음
		
		int nUUID = 0;	
		int maxRetries = 5;  // 최대 재시도 횟수
		boolean isUnique = false;
		if(strUUID.contentEquals("0")){
			for (int attempt = 0; attempt < maxRetries; attempt++) {
				nUUID = getUUID();  // UUID 생성
				String strCheckUUID = "";
				strCheckUUID += "SELECT COUNT(*) ";
				strCheckUUID += " FROM APT_COMMUNITY_USER_INFO ";
				strCheckUUID += " WHERE UUID = " + nUUID + " ";

				pstmt = conn.prepareStatement(strCheckUUID);
				rs = pstmt.executeQuery();

				String strUUIDCount = new String();
				if(rs.next()) {
					strUUIDCount = rs.getString(1);	
				}

				if (strUUIDCount.contentEquals("0")) {  // UUID가 고유하면 루프 종료
					isUnique = true;
					break;
				}
			}
		}else{
			isUnique = true;
			nUUID = Integer.parseInt(strUUID);
		}


		printLog("A","nUUID : " +nUUID);

		String strQuery = "";		
		if(isUnique && resultCnt.contentEquals("0")){
			strQuery += " INSERT INTO APT_COMMUNITY_USER_INFO (USER_ID, APT_CODE, IMAGE_URL, UUID, DONG, HO, NAME ) ";
			strQuery +=  " VALUES ('" + strUserId +"', '"+strAptCode+"', '"+strImageUrl+"', " +  nUUID + ", '" + strDong + "', '" + strHo + "', '" + strName + "' )";
		}else if(isUnique && resultCnt.contentEquals("1")){
			strQuery += " UPDATE APT_COMMUNITY_USER_INFO SET ";
			strQuery += " IMAGE_URL = '" + strImageUrl + "', ";		
			strQuery += " APT_CODE = " + strAptCode  + ", ";
			strQuery += " EXPIRATION_DATE = NULL, "; 
			strQuery += " UUID = " + nUUID  + ", ";
			strQuery += " DONG = '" + strDong  + "', ";
			strQuery += " HO = '" + strHo  + "', ";
			strQuery += " NAME = '" + strName  + "' ";		
			strQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strQuery += " AND DONG = '" + strDong + "' ";
			strQuery += " AND HO = '" + strHo + "' ";
			strQuery += " AND NAME = '" + strName + "' ";	
		}

		printLog("A","strQuery : " +strQuery);

		
		pstmt = conn.prepareStatement(strQuery);
		int nRet = pstmt.executeUpdate();

		// 얼굴 등록에 성공했으면 
		// 아파트코드, 주출입구(1)인 경우를 조회해서 모든 문에 얼굴 등록해주기
		// 기간은 사진의 만료일
		// @Param AccessToken,TID, MemNo, MemName, MemPH, FaceData, StartTime, EndTime, DoorCode

	

		String strExpirationDateQuery = "";
		strExpirationDateQuery += " SELECT EXPIRATION_DATE ";
		strExpirationDateQuery += " FROM APT_COMMUNITY_USER_INFO ";
		strExpirationDateQuery += "WHERE UUID = " + nUUID + " ";	
		strExpirationDateQuery += " LIMIT 1 ";

		pstmt = conn.prepareStatement(strExpirationDateQuery);
		rs = pstmt.executeQuery();

		String strExpirationDate = "";
		if(rs.next()) {
			strExpirationDate = rs.getString(1);	
		}

		strUUID = String.valueOf(nUUID);

		// 관리자만 모든 문에 출입 가능하게 등록
		String strUserGradeQuery = "";
		strUserGradeQuery += " SELECT USER_GRADE ";
		strUserGradeQuery += " FROM USER_INFO ";
		strUserGradeQuery += " WHERE USER_ID = '" + strUserId + "' ";
		strUserGradeQuery += " AND APT_CODE = " + strAptCode + " ";
		
		pstmt = conn.prepareStatement(strUserGradeQuery);
		rs = pstmt.executeQuery();
		String strUserGrade = "";
		if(rs.next()){
			strUserGrade = rs.getString(1);
		}
		String strCommunityDoorQuery = "";
		strCommunityDoorQuery += " SELECT DOOR_ID, COMMUNITY_TYPE ";
		strCommunityDoorQuery += " FROM APT_COMMUNITY_DOOR ";
		strCommunityDoorQuery += " WHERE 1 = 1 ";
		strCommunityDoorQuery += " AND ATP_CODE = " + strAptCode + " ";
		if(!strUserGrade.contentEquals(USER_GRADE_COMMUNITY_ADMIN) && !strUserGrade.contentEquals(USER_GRADE_ADMIN)){
			strCommunityDoorQuery += " AND DOOR_TYPE = '0' ";
		}

		pstmt = conn.prepareStatement(strCommunityDoorQuery);
		rs = pstmt.executeQuery();
		List<String> listDoorIds = new ArrayList<String>();
		List<String> listDoorIdsAndCommunityType = new ArrayList<String>();
			// Loop a select result records
		String strDoorId = "";
		String strDoorCommunityType = "";
		for(int nRow = 0; rs.next(); nRow++) {
			strDoorId = rs.getString(1);
			strDoorCommunityType = rs.getString(2);
			listDoorIds.add(strDoorId);
			listDoorIdsAndCommunityType.add(strDoorCommunityType.substring(0,2));
		}
			String strCommunityType = "00";

	
		for (int nDoorId = 0; nDoorId < listDoorIds.size(); nDoorId++) { // n은 반복 횟수
			// callEntranceRegistrationAPI 메서드를 동기적으로 호출


			callDevEntranceRegistrationAPI(strUserId, strName, strUserPhoneNo, strUUID, listDoorIds.get(nDoorId), strAptCode, listDoorIdsAndCommunityType.get(nDoorId), conn);
			
			// 이 코드는 위의 callEntranceRegistrationAPI 호출이 완료된 후 실행됩니다.
			System.out.println("등록 API 호출 완료: " + (nDoorId + 1) + "번째 호출");

			 try {
				Thread.sleep(1000); // 1000 milliseconds = 1 second
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

		if(listDoorIds.size() == 0){
    		String strUpdateQuery = "UPDATE APT_COMMUNITY_USER_INFO SET EXPIRATION_DATE = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 5 YEAR), '%Y%m%d') WHERE UUID = " + strUUID + " ";		
			pstmt = conn.prepareStatement(strUpdateQuery);
			int nRetUpdate = pstmt.executeUpdate();
		}
		
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		if(!isUnique){
			nRet = 0;
		}

		// 얼굴 등록하면서 오늘 예약이 있었으면 얼굴 정보만 변경해서 새로 등록
		String strTodayReserveQuery = "";
		strTodayReserveQuery += "SELECT RESERVE_ID ";
		strTodayReserveQuery += " FROM APT_COMMUNITY_RESERVE ";
		strTodayReserveQuery += " WHERE (( ";
		strTodayReserveQuery += "    EXPIRATION_DATE IS NULL";
		strTodayReserveQuery += "    AND (";
		strTodayReserveQuery += "        (LENGTH(DATE) = 8 AND STR_TO_DATE(DATE, '%Y%m%d') = CURDATE())";
		strTodayReserveQuery += "        OR (LENGTH(DATE) = 14 AND STR_TO_DATE(DATE, '%Y%m%d%H%i%S') = CURDATE())";
		strTodayReserveQuery += "    )";
		strTodayReserveQuery += " )";
		strTodayReserveQuery += " OR( ";
		strTodayReserveQuery += "    EXPIRATION_DATE IS NOT NULL";
		strTodayReserveQuery += "        AND DATE_FORMAT(STR_TO_DATE(DATE, '%Y%m%d%H%i%S'), '%Y%m%d') >= DATE_FORMAT(CURDATE(), '%Y%m%d') ";
		strTodayReserveQuery += "        AND DATE_FORMAT(CURDATE(), '%Y%m%d') <= DATE_FORMAT(STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%S'), '%Y%m%d') ";
		strTodayReserveQuery += " ))";    
		strTodayReserveQuery += " AND RESERVE_CANCEL_CHANNEL IS NULL ";
		strTodayReserveQuery += " AND UUID = " + strUUID + " ";
		pstmt = conn.prepareStatement(strTodayReserveQuery);
		rs = pstmt.executeQuery();

		List<String> listReservationIds = new ArrayList<String>();
			// Loop a select result records
		String strReservationIds = "";
		for(int nRow = 0; rs.next(); nRow++) {
			strDoorId = rs.getString(1);
			listReservationIds.add(strDoorId);
		}

		for (int nReservationCount = 0; nReservationCount < listReservationIds.size(); nReservationCount++) {
			String strCallReservationId = listReservationIds.get(nReservationCount);
			// 재등록
			if(strCallReservationId != null && !strCallReservationId.contentEquals("")){
				callReservationTryAgain(strCallReservationId, strImageUrl);
				System.out.println("재등록 API 호출 완료: " + (nReservationCount + 1) + "번째 호출");
			}

			try {
				Thread.sleep(1000); // 1000 milliseconds = 1 second
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		
		baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
 	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	} else if(strSID.contentEquals("get_user_photo_status")) {
		// =========================================================
		// 등록된 얼굴 상태 조회
		// =========================================================
		String strUserId = getRequestParam(m_issacweb, request, "UserId");		
		String strUUID = getRequestParam(m_issacweb, request, "UUID");		
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");		
		String strDong = getRequestParam(m_issacweb, request, "UserDong");		
		String strHo = getRequestParam(m_issacweb, request, "UserHo");		
		String strUserName = getRequestParam(m_issacweb, request, "UserName");		

		// =========================================================
		// 요청 파라미터 null 방어 처리
		// =========================================================
		if(strUserId == null){ strUserId = ""; }	
		if(strUUID == null){ strUUID = ""; }
		if(strAptCode == null){ strAptCode = ""; }
		if(strDong == null){ strDong = ""; }
		if(strHo == null){ strHo = ""; }
		if(strUserName == null){ strUserName = ""; }

		// =========================================================
		// 0. 필수 파라미터 검증
		// ✅ UserId, AptCode는 사용자 식별 및 아파트 구분에 반드시 필요한 값이므로 필수로 검증한다.
		// =========================================================
        String strErrorMessage = "";

        if(strUserId.trim().equals("")) { // UserId + Dong + Ho + name 이 모두 없을 때 -> 오류
            strErrorMessage = "등록된 아이디가 없습니다";
        } else if(strAptCode.trim().equals("")) {
            strErrorMessage = "등록된 아파트코드가 없습니다";
        }

		// ✅ 관리사무소(5)/시스템관리자(6)/커뮤니티센터 관리자(8) 등급은 동/호/이름 없어도 무방하다
		// ✅ 입주민(3)일 경우에는 동/호/이름이 없으면 안되기에 등급 체크를 해서 동/호/이름 없을 경우 에러 메세지를 남긴다 
		String strUserGrade = "";

		if(strErrorMessage.equals("")) {
			String strUserGradeQuery = "";
			strUserGradeQuery += " SELECT USER_GRADE ";
			strUserGradeQuery += " FROM USER_INFO ";
			strUserGradeQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
			strUserGradeQuery += " AND USER_ID = '" + strUserId + "' ";

			pstmt = conn.prepareStatement(strUserGradeQuery);
			rs = pstmt.executeQuery();

			if(rs.next()) {
				strUserGrade = rs.getString("USER_GRADE") != null ? rs.getString("USER_GRADE") : "";

				if(USER_GRADE_RESIDENT.contentEquals(strUserGrade)) {
					if(strUserName.trim().equals("")) {
						strErrorMessage = "등록된 이름이 없습니다. 관리사무소 또는 고객센터에 문의해주세요";
					} else if(strDong.trim().equals("") || strHo.trim().equals("")) {
						strErrorMessage = "등록된 아파트 동/호 정보가 없습니다. 관리사무소 또는 고객센터에 문의해주세요";
					}
				}
			}
		}

		// 에러 실행
        if(!strErrorMessage.equals("")) {
            ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

            // baOutStream.write("0".getBytes(S_CHARSET)); // 조회 성공 여부
            // baOutStream.write(COLUMN_DEL);

            // baOutStream.write(strErrorMessage.getBytes(S_CHARSET)); // 에러 메시지
            // baOutStream.write(COLUMN_DEL);

            // 기존 필드 빈값 처리
			baOutStream.write("0".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write("".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);		

            returnData(m_issacweb, baOutStream, outStream);
            return;
        }
	
		// ================================
		// USER_ID 매핑 처리
		// ================================
		// UserId가 넘어온 경우,
		// 기존 APT_COMMUNITY_USER_INFO 테이블에서
		// 아파트코드 + 동 + 호 + 이름이 일치하면서 USER_ID가 비어있는 데이터에
		// 현재 UserId를 업데이트한다.

		// 🚨🚨🚨 APT_COMMUNITY_USER_INFO에
		// ❌ 동/호는 있고, 이름이 없는 사람 -> 다른 사람을 등록했을 가능성이 있기에 업데이트 하지 않는다
		// ⭕️ 동/호가 없고, 이름이 있는 사람 -> 다른 사람일 수 있지만 동/호는 업데이트 할 수 있다

		if(strUserId.contentEquals("")){
            if(!strDong.trim().equals("") && !strHo.trim().equals("") && !strUserName.trim().equals("")){
                String strMembershipUserMappingQuery = "";

				// USER_ID가 비어있는 기존 사용자 정보에 현재 USER_ID를 매핑
                strMembershipUserMappingQuery += " UPDATE APT_COMMUNITY_USER_INFO SET ";
                strMembershipUserMappingQuery += " USER_ID = '" + strUserId + "' ";
                strMembershipUserMappingQuery += " WHERE APT_CODE = " + strAptCode + " ";
                strMembershipUserMappingQuery += " AND DONG = '" + strDong + "' ";
                strMembershipUserMappingQuery += " AND HO = '" + strHo + "' ";
                strMembershipUserMappingQuery += " AND NAME = '" + strUserName + "' ";
                strMembershipUserMappingQuery += " AND (USER_ID = '' OR USER_ID IS NULL ) ";

                pstmt = conn.prepareStatement(strMembershipUserMappingQuery);
                pstmt.executeUpdate();

                printLog("D", "strMembershipUserMappingQuery : " + strMembershipUserMappingQuery);
            }
		}

		// ================================
		// 등록 완료된 사진 존재 여부 조회
		// ================================
		// EXPIRATION_DATE IS NOT NULL 이므로, // 🚨🚨🚨 NULL일 수 있다
		// 만료일이 존재하는 데이터 = 등록 완료된 사진 데이터로 보고 조회한다.
		//
		// IMAGE_URL 이 비어있지 않은 데이터만 카운트한다.
		//
		// 조회 조건은 아래 3가지 중 하나라도 만족하면 해당 사용자 사진으로 판단한다.
		// 1) USER_ID만 있는 데이터와 현재 USER_ID가 일치하는 경우
		// 2) 이름 + 동 + 호가 모두 일치하는 경우
		// 3) 이름만 일치하고 동/호가 비어있는 경우 // ❌

		String strCountQuery = "";
		strCountQuery += " SELECT EXISTS ( ";
		strCountQuery += "   SELECT 1 ";
		strCountQuery += "FROM APT_COMMUNITY_USER_INFO ";
		// strCountQuery += "WHERE EXPIRATION_DATE IS NOT NULL ";	
		strCountQuery += "WHERE IMAGE_URL != '' AND IMAGE_URL IS NOT NULL ";	
		strCountQuery += "  AND APT_CODE = " + strAptCode + " ";	

		// ✅ 관리사무소(5)/시스템관리자(6)/커뮤니티센터 관리자(8) 등급은 동/호/이름이 없으니 UserId 기반으로 조회를 하고 
		// ✅ 입주민(3)일 경우에는 동/호/이름이 없으면 안되기에 이름+동+호 모두 일치하는 경우로 조회를 한다

		// ✅ 등급과 상관없이 동/호가 있으면 동/호 기준으로 먼저 조회
		// ✅ 동/호가 없으면 USER_ID 기준으로 조회

		if(!strDong.trim().equals("") && !strHo.trim().equals("") && !strUserName.trim().equals("")){
			strCountQuery += " AND DONG = '" + strDong + "' ";
			strCountQuery += " AND HO = '" + strHo + "' ";

			// 이름까지 있으면 더 정확하게 이름도 함께 체크
			// if(!strUserName.trim().equals("")) {
				strCountQuery += " AND NAME = '" + strUserName + "' ";
			// }
		}
		// ✅ 동/호가 없으면 USER_ID 기준으로 조회
		else if(!strUserId.trim().equals("")) {
			strCountQuery += " AND USER_ID = '" + strUserId + "' ";
		}
		// ✅ 둘 다 없으면 조회 막기
		else {
			strCountQuery += " AND 1 = 0 ";
		}

		// strCountQuery += "  AND ( ";

		// USER_ID가 존재하고, 이름/동/호는 비어있는 데이터 중 USER_ID가 일치하는 경우
		// strCountQuery += "        ( (USER_ID IS NOT NULL AND USER_ID != '') AND (NAME IS NULL OR NAME = '') AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') AND USER_ID = '" + strUserId + "' ) ";
		
		// 이름 + 동 + 호가 모두 일치하는 경우
		// strCountQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strDong + "' AND HO = '" + strHo + "' ) ";
		
		// 이름만 일치하고 동/호가 비어있는 경우
		// strCountQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";
		// strCountQuery += "  ) ";
		strCountQuery += " ) AS IS_EXIST ";

		printLog("A","strCountQuery : "+ strCountQuery);
		
		pstmt = conn.prepareStatement(strCountQuery);
		rs = pstmt.executeQuery();

		// 등록 완료된 사진 데이터 개수
		// String resultCnt = "0";
		// if(rs.next()) {
		// 	resultCnt = rs.getString(1);	
		// }

		String resultCnt = "0";

		if(rs.next()) {
			resultCnt = rs.getString(1) != null ? rs.getString(1) : "0";
		}


		// 조회 개수가 10개를 초과하면 비정상 데이터로 보고 0 처리
		// if(Integer.parseInt(resultCnt) > 10){
		// 	resultCnt = "0";
		// }

		// 1개 이상 조회된 경우 클라이언트에는 1로 내려줌
		// 즉, 실제 개수와 상관없이 "사진 있음" 상태로 변환
		// if(!resultCnt.contentEquals("0") && !resultCnt.contentEquals("")){
		// 	resultCnt = "1";
		// }			
		
		// ================================
		// 심사 중인 사진 존재 여부 조회 // 🚨🚨🚨 -> 웹훅 확인 필요
		// ================================
		// EXPIRATION_DATE IS NULL 이므로,
		// 아직 만료일이 없는 데이터 = 심사 중인 사진 데이터로 보고 조회한다.
		//
		// 위의 등록 완료 사진 조회와 동일한 사용자 매칭 조건을 사용한다.
		// String strInspectionCountQuery = "";
		// strInspectionCountQuery += "SELECT COUNT(*) ";
		// strInspectionCountQuery += "FROM APT_COMMUNITY_USER_INFO ";
		// strInspectionCountQuery += "WHERE EXPIRATION_DATE IS NULL ";
		// strInspectionCountQuery += "  AND APT_CODE = " + strAptCode + " ";
		// strInspectionCountQuery += "  AND ( ";

		// USER_ID가 존재하고, 이름/동/호는 비어있는 데이터 중 USER_ID가 일치하는 경우
		// strInspectionCountQuery += "        ( (USER_ID IS NOT NULL AND USER_ID != '') AND (NAME IS NULL OR NAME = '') AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') AND USER_ID = '" + strUserId + "' ) ";
		
		// 이름 + 동 + 호가 모두 일치하는 경우
		// strInspectionCountQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strDong + "' AND HO = '" + strHo + "' ) ";
		
		// 이름만 일치하고 동/호가 비어있는 경우
		// strInspectionCountQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";
		// strInspectionCountQuery += "  ) ";

		// printLog("D","strInspectionCountQuery : "+ strInspectionCountQuery);
		
		// pstmt = conn.prepareStatement(strInspectionCountQuery);
		// rs = pstmt.executeQuery();

		// 심사 중인 사진 데이터 개수
		// String strInspectionResultCnt = "";

		// if(rs.next()) {
		// 	strInspectionResultCnt = rs.getString(1);	
		// }

		// 심사 중 데이터가 10개를 초과하면 비정상 데이터로 보고 0 처리
		// if(Integer.parseInt(strInspectionResultCnt) > 10){
		// 	strInspectionResultCnt = "0";
		// }

		// 심사 중 데이터가 정확히 1개 있으면
		// resultCnt를 9로 변경하여 클라이언트에 "심사중" 상태로 전달한다.
		// if(strInspectionResultCnt != null && strInspectionResultCnt.contentEquals("1")){		
		// 	resultCnt = "9";		
		// }

		// printLog("A","strInspectionResultCnt : " + strInspectionResultCnt);

		// ================================
		// 등록 완료된 사진 IMAGE_URL 조회
		// ================================
		// EXPIRATION_DATE IS NOT NULL 이고 IMAGE_URL이 있는 데이터 중
		// 현재 사용자 조건에 맞는 사진 URL을 조회한다.
		//
		// rs.next() 한 번만 사용하므로,
		// 여러 건이 조회되어도 첫 번째 IMAGE_URL만 내려간다.
		String strImageURLQuery = "";
		strImageURLQuery += "SELECT IMAGE_URL ";
		strImageURLQuery += "FROM APT_COMMUNITY_USER_INFO ";
		// strImageURLQuery += "WHERE EXPIRATION_DATE IS NOT NULL ";	
		strImageURLQuery += "WHERE IMAGE_URL != '' AND IMAGE_URL IS NOT NULL ";	
		strImageURLQuery += "  AND APT_CODE = " + strAptCode + " ";	

		// ✅ 관리사무소(5)/시스템관리자(6)/커뮤니티센터 관리자(8) 등급은 동/호/이름이 없으니 UserId 기반으로 조회를 하고 
		// ✅ 입주민(3)일 경우에는 동/호/이름이 없으면 안되기에 이름+동+호 모두 일치하는 경우로 조회를 한다

		// 입주민(3)
		// → 이름 + 동 + 호가 모두 일치하는 데이터만 조회
		// if(USER_GRADE_RESIDENT.contentEquals(strUserGrade)) {
		// 	strImageURLQuery += " AND NAME = '" + strUserName + "' ";
		// 	strImageURLQuery += " AND DONG = '" + strDong + "' ";
		// 	strImageURLQuery += " AND HO = '" + strHo + "' ";
		// }

		// // 관리사무소(5) / 시스템관리자(6) / 커뮤니티센터 관리자(8)
		// // → USER_ID가 일치하는 데이터만 조회
		// else if(
		// 	USER_GRADE_ADMIN.contentEquals(strUserGrade)
		// 	|| USER_GRADE_SYSADMIN.contentEquals(strUserGrade)
		// 	|| USER_GRADE_COMMUNITY_ADMIN.contentEquals(strUserGrade)
		// ) {
		// 	strImageURLQuery += " AND USER_ID = '" + strUserId + "' ";

		// 	// 관리자 데이터 중 이름/동/호가 비어있는 데이터만 조회하려면 아래 조건 추가
		// 	// strImageURLQuery += " AND (NAME IS NULL OR NAME = '') ";
		// 	// strImageURLQuery += " AND (DONG IS NULL OR DONG = '') ";
		// 	// strImageURLQuery += " AND (HO IS NULL OR HO = '') ";
		// }

		// // 그 외 등급
		// // → 조회되지 않도록 막음
		// else {
		// 	strImageURLQuery += " AND 1 = 0 ";
		// }

		// ✅ 등급과 상관없이 동/호/이름이 있으면 동/호/이름 기준으로 먼저 조회
		if(!strDong.trim().equals("") && !strHo.trim().equals("") && !strUserName.trim().equals("")) {
			strImageURLQuery += " AND DONG = '" + strDong + "' ";
			strImageURLQuery += " AND HO = '" + strHo + "' ";
			strImageURLQuery += " AND NAME = '" + strUserName + "' ";
		}
		// ✅ 동/호/이름이 없을 때만 USER_ID 기준으로 조회
		else if(!strUserId.trim().equals("")) {
			strImageURLQuery += " AND USER_ID = '" + strUserId + "' ";

			// 동/호/이름 없는 관리자용 데이터만 조회하고 싶으면 이 조건까지 추가하는 게 안전함
			strImageURLQuery += " AND (DONG IS NULL OR DONG = '') ";
			strImageURLQuery += " AND (HO IS NULL OR HO = '') ";
			strImageURLQuery += " AND (NAME IS NULL OR NAME = '') ";
		}
		// ✅ 둘 다 아니면 조회 막기
		else {
			strImageURLQuery += " AND 1 = 0 ";
		}

		// strImageURLQuery += "  AND ( ";

		// USER_ID가 존재하고, 이름/동/호는 비어있는 데이터 중 USER_ID가 일치하는 경우
		// strImageURLQuery += "        ( (USER_ID IS NOT NULL AND USER_ID != '') AND (NAME IS NULL OR NAME = '') AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') AND USER_ID = '" + strUserId + "' ) ";
		
		// 이름 + 동 + 호가 모두 일치하는 경우
		// strImageURLQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strDong + "' AND HO = '" + strHo + "' ) ";
		
		// 이름만 일치하고 동/호가 비어있는 경우
		// strImageURLQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";
		// strImageURLQuery += "  ) ";

		pstmt = conn.prepareStatement(strImageURLQuery);
		rs = pstmt.executeQuery();

		String strImageURL = "";

		// 조회된 IMAGE_URL이 null이 아니면 해당 URL 사용,
		// null이면 빈값으로 내려준다.
		if(rs.next()) {
			strImageURL = rs.getString(1) != null ? rs.getString(1) : "";	
		}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		
		// baOutStream.write("1".getBytes(S_CHARSET)); // 조회 성공 여부
		baOutStream.write(resultCnt.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// baOutStream.write("".getBytes(S_CHARSET)); // 에러 메시지
		// baOutStream.write(COLUMN_DEL);

		// baOutStream.write(resultCnt.getBytes(S_CHARSET));
 		// baOutStream.write(COLUMN_DEL);	
		
		baOutStream.write(strImageURL.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);	
 	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_apt_manuals")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");		
		String strManualURL = " ";
		if(strAptCode.contentEquals("100542")){
			strManualURL = "http://183.111.159.197:8080/xmobile/villizinei/html/community/100542/introduction.html";
		}else{
			strManualURL = "http://183.111.159.197:8080/xmobile/villizinei/html/community/1/introduction.html";
		}
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write(strManualURL.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		returnData(m_issacweb, baOutStream, outStream);
	}else if(strSID.contentEquals("register_user_gender")){
		// 유저 성별 자체 등록
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUUID = getRequestParam(m_issacweb, request, "UUID");
		String strDong = getRequestParam(m_issacweb, request, "UserDong");
		String strHo = getRequestParam(m_issacweb, request, "UserHo");
		String strUserName = getRequestParam(m_issacweb, request, "UserName");
		String strGender = getRequestParam(m_issacweb, request, "Gender");

		String strCountQuery = "";
		strCountQuery += "SELECT COUNT(*) ";
		strCountQuery += "FROM APT_COMMUNITY_USER_INFO ";
		strCountQuery += "WHERE APT_CODE = " + strAptCode + " ";
		strCountQuery += "AND DONG = '" + strDong + "' ";
		strCountQuery += "AND HO = '" + strHo + "' ";
		strCountQuery += "AND NAME = '" + strUserName + "' ";			
	
		pstmt = conn.prepareStatement(strCountQuery);
		rs = pstmt.executeQuery();

		String resultCnt = new String();
		if(rs.next()) {
			resultCnt = rs.getString(1);	
		}

		printLog("A", "strCountQuery" + strCountQuery);

		

		// 유저의 고유 값을 만들어야 주 출입구에 데이터를 넣어줄 수 있음
		
		int nUUID = 0;	
		int maxRetries = 10;  // 최대 재시도 횟수
		boolean isUnique = false;

		for (int attempt = 0; attempt < maxRetries; attempt++) {
			nUUID = getUUID();  // UUID 생성
			String strCheckUUID = "";
			strCheckUUID += "SELECT COUNT(*) ";
			strCheckUUID += " FROM APT_COMMUNITY_USER_INFO ";
			strCheckUUID += " WHERE UUID = " + nUUID + " ";

			pstmt = conn.prepareStatement(strCheckUUID);
			rs = pstmt.executeQuery();

			String strUUIDCount = new String();
			if(rs.next()) {
				strUUIDCount = rs.getString(1);	
			}

			if (strUUIDCount.contentEquals("0")) {  // UUID가 고유하면 루프 종료
				isUnique = true;
				break;
			}
		}
	

		printLog("A","nUUID : " +nUUID);

		String strQuery = "";		
		if(isUnique && resultCnt.contentEquals("0")){
			strQuery += " INSERT INTO APT_COMMUNITY_USER_INFO (APT_CODE, UUID, DONG, HO, NAME ) ";
			strQuery +=  " VALUES ('"+strAptCode+"',  " +  nUUID + ", '" + strDong + "', '" + strHo + "', '" + strUserName + "' )";

			pstmt = conn.prepareStatement(strQuery);
			pstmt.executeUpdate();

		}


		String strUpdateQuery = "";
		strUpdateQuery += " UPDATE APT_COMMUNITY_USER_INFO SET ";
		strUpdateQuery += " GENDER = '" + strGender + "' ";
		strUpdateQuery += " WHERE APT_CODE = " + strAptCode + " ";		
		strUpdateQuery += " AND DONG = '" + strDong + "' ";	
		strUpdateQuery += " AND HO = '" + strHo + "' ";	
		strUpdateQuery += " AND NAME = '" + strUserName + "' ";	
		
		pstmt = conn.prepareStatement(strUpdateQuery);
		int nRet = pstmt.executeUpdate();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		
		baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);
	}else if(strSID.contentEquals("retry_register_user_face")){
		// 얼굴 다시 등록
		String strReservationId = getRequestParam(m_issacweb, request, "ReservationId");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");

		String strDataQuery = "";
		strDataQuery += "SELECT APT_CODE, USER_DONG, USER_HO, RESERVE_USER_NAME ";
		strDataQuery += " FROM APT_COMMUNITY_RESERVE";
		strDataQuery += " WHERE RESERVE_ID = " + strReservationId + " ";
		pstmt = conn.prepareStatement(strDataQuery);
		rs = pstmt.executeQuery();

		String strAptCode = "0";
		String strUserDong = "";
		String strUserHo = "";
		String strUserName = "";

		if(rs.next()){
			strAptCode = rs.getString(1);
			strUserDong = rs.getString(2);
			strUserHo = rs.getString(3);
			strUserName = rs.getString(4);
		}

		if(strAptCode == null || strAptCode.contentEquals("")){
			strAptCode = "0";
		}

		String strUserImageQuery = "";	
		strUserImageQuery += "SELECT IMAGE_URL ";
		strUserImageQuery += "FROM APT_COMMUNITY_USER_INFO ";
		strUserImageQuery += "WHERE (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE != '' ) ";
		strUserImageQuery += "  AND APT_CODE = " + strAptCode + " ";
		strUserImageQuery += "  AND ( ";
		strUserImageQuery += "        ( (USER_ID IS NOT NULL AND USER_ID != '') AND (NAME IS NULL OR NAME = '') AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') AND USER_ID = '" + strUserId + "' ) ";
		strUserImageQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strUserDong + "' AND HO = '" + strUserHo + "' ) ";
		strUserImageQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";
		strUserImageQuery += "  ) ";


		String strUserImageURL = "";

		pstmt = conn.prepareStatement(strUserImageQuery);
		rs = pstmt.executeQuery();

		if(rs.next()){
			strUserImageURL = rs.getString(1);
		}
		String strQuery = "";
		strQuery += " SELECT COUNT(*) ";
		strQuery += " FROM APT_COMMUNITY_RESERVE ";
		strQuery += " WHERE RESERVE_ID = " + strReservationId + " ";
		strQuery += " AND (RESERVE_CANCEL_TIME IS NULL OR RESERVE_CANCEL_TIME = '') ";
		strQuery += " AND ( ";
		strQuery += " IF((EXPIRATION_DATE IS NULL OR EXPIRATION_DATE = ''), ";
		strQuery += " (DATE <= DATE_FORMAT(SYSDATE(), '%Y%m%d') AND ";
		strQuery += "  DATE >= DATE_FORMAT(SYSDATE(), '%Y%m%d')), ";
		strQuery += " (EXPIRATION_DATE >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') AND ";
		strQuery += "  DATE <= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'))";
		strQuery += " ) ";
		strQuery += " ) ";

		pstmt = conn.prepareStatement(strQuery);	
		rs = pstmt.executeQuery();

		String strReserveCount = "0";
		
		if(rs.next()){
			 strReserveCount = rs.getString(1);
		}

		String strData = "0";
		if(strUserImageURL != null && !strUserImageURL.contentEquals("") && strReserveCount.contentEquals("1")){
			// 이미지가 있으면 해당 예약건으로 이미지 등록 재요청
			callReservationTryAgain(strReservationId, strUserImageURL);
			strData = "1";
		}else if(strReserveCount.contentEquals("0")){
			strData = "2";
		}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		baOutStream.write(strData.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_unavailable_dates")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strRoomNumber = getRequestParam(m_issacweb, request, "RoomNumber");
		
		String strReservationDateQuery = "";
		strReservationDateQuery += " SELECT DATE, EXPIRATION_DATE ";
		strReservationDateQuery += " FROM APT_COMMUNITY_RESERVE";
		strReservationDateQuery += " WHERE COMMUNITY_TYPE = '10'";
		strReservationDateQuery += " AND (DATE >= CURDATE() OR (DATE <= CURDATE() AND EXPIRATION_DATE >= CURDATE() ))";
		strReservationDateQuery += " AND APT_CODE = " + strAptCode + " ";
		strReservationDateQuery += " AND PLACE = '" + strRoomNumber + "' ";
		strReservationDateQuery += " AND (RESERVE_CANCEL_CHANNEL IS NULL OR RESERVE_CANCEL_CHANNEL = '' )"; // 취소 안 된것만

		printLog("A","strReservationDateQuery : " + strReservationDateQuery);

		pstmt = conn.prepareStatement(strReservationDateQuery);
		rs = pstmt.executeQuery();

		// 불가능한 날짜가 겹칠 수 있어서 List에서 Set 타입으로 바꿨습니다
		Set<String> dateRange = new LinkedHashSet<String>();

		rsMetaData = rs.getMetaData();

		for (int nRow = 0; rs.next(); nRow++) {
			String strStartDate = rs.getString(1); // yyyyMMdd
			String strEndDate = rs.getString(2);   // yyyyMMdd

			printLog("A", "Row " + nRow + ": strStartDate = " + strStartDate + ", strEndDate = " + strEndDate);

			if (strStartDate == null || strEndDate == null) {
				continue;
			}

			try {
				// DateTimeFormatter (입력 형식: yyyyMMdd)
				SimpleDateFormat inputFormatter = new SimpleDateFormat("yyyyMMdd");
				SimpleDateFormat outputFormatter = new SimpleDateFormat("yyyyMMdd");

				// LocalDate 변환
				Date startDate = inputFormatter.parse(strStartDate);
				Date endDate = inputFormatter.parse(strEndDate);

				// 디버깅용 출력
				printLog("D", "Parsed Start Date: " + startDate);
				printLog("D", "Parsed End Date: " + endDate);

				// 날짜 범위 생성
				Calendar cal = Calendar.getInstance();
				while (startDate.before(endDate)) { // 종료일 - 1 까지
					String formattedDate = outputFormatter.format(startDate);
					dateRange.add(formattedDate);

					printLog("D", "Generated Date: " + formattedDate);

					cal.setTime(startDate);
					cal.add(Calendar.DATE, 1);
					String strDate = outputFormatter.format(cal.getTime());
					startDate = outputFormatter.parse(strDate);
				}
			} catch (Exception e) {
				printLog("E", "Error parsing dates: " + e.getMessage());
			}
		}

		// =========================================================
		// IMPOSSIBLE_PLACE에 설정된 이용 불가능 날짜 추가
		// =========================================================
		String strImpossiblePlace = "";

		String strImpossiblePlaceQuery = "";
		strImpossiblePlaceQuery += " SELECT IMPOSSIBLE_PLACE ";
		strImpossiblePlaceQuery += " FROM APT_COMMUNITY ";
		strImpossiblePlaceQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strImpossiblePlaceQuery += " AND COMMUNITY_TYPE = '10' ";

		printLog("A", "strImpossiblePlaceQuery : " + strImpossiblePlaceQuery);

		pstmt = conn.prepareStatement(strImpossiblePlaceQuery);
		rs = pstmt.executeQuery();

		if (rs.next()) {
			strImpossiblePlace = defaultIfNull(rs.getString("IMPOSSIBLE_PLACE"), "");
		}

		if (strImpossiblePlace != null && !strImpossiblePlace.contentEquals("")) {

			try {

				JSONParser parser = new JSONParser();
				Object obj = parser.parse(strImpossiblePlace);

				if (obj instanceof JSONArray) {

					JSONArray impossiblePlaceArray = (JSONArray) obj;

					SimpleDateFormat impossibleDateFormat = new SimpleDateFormat("yyyyMMdd");

					// get_unavailable_dates에서 조회할 최대 범위
					// 오늘 ~ 2개월 뒤 마지막 날
					Calendar todayCal = Calendar.getInstance();

					// 시간 제거
					todayCal.set(Calendar.HOUR_OF_DAY, 0);
					todayCal.set(Calendar.MINUTE, 0);
					todayCal.set(Calendar.SECOND, 0);
					todayCal.set(Calendar.MILLISECOND, 0);

					Calendar maxCal = (Calendar) todayCal.clone();
					maxCal.add(Calendar.MONTH, 2);
					maxCal.set(Calendar.DAY_OF_MONTH, maxCal.getActualMaximum(Calendar.DAY_OF_MONTH));

					for (int i = 0; i < impossiblePlaceArray.size(); i++) {

						JSONObject jsonObj = (JSONObject) impossiblePlaceArray.get(i);

						String name = jsonObj.get("name") != null ? (String) jsonObj.get("name") : "";
						String unavailableFrom = jsonObj.get("unavailable_from") != null ? (String) jsonObj.get("unavailable_from") : "";
						String unavailableTo = jsonObj.get("unavailable_to") != null ? (String) jsonObj.get("unavailable_to") : "";

						// 시작일이 없으면 처리 불가
						if (unavailableFrom.length() < 8) {
							continue;
						}

						// =========================================================
						// 현재 RoomNumber가 IMPOSSIBLE_PLACE의 name에 포함되어 있는지 확인
						// =========================================================
						boolean isTargetRoom = false;

						String[] names = name.split(",");

						for (String n : names) {

							if (strRoomNumber.trim().contentEquals(n.trim())) {
								isTargetRoom = true;
								break;
							}
						}

						// 다른 방에 대한 설정이면 무시
						if (!isTargetRoom) {
							continue;
						}

						// yyyyMMddHHmm -> yyyyMMdd
						String strFromDate = unavailableFrom.substring(0, 8);

						Calendar fromCal = Calendar.getInstance();
						fromCal.setTime(impossibleDateFormat.parse(strFromDate));

						fromCal.set(Calendar.HOUR_OF_DAY, 0);
						fromCal.set(Calendar.MINUTE, 0);
						fromCal.set(Calendar.SECOND, 0);
						fromCal.set(Calendar.MILLISECOND, 0);

						Calendar toCal;

						// =========================================================
						// unavailable_to 있음
						// =========================================================
						if (unavailableTo.length() >= 8) {

							String strToDate = unavailableTo.substring(0, 8);

							toCal = Calendar.getInstance();
							toCal.setTime(impossibleDateFormat.parse(strToDate));

							toCal.set(Calendar.HOUR_OF_DAY, 0);
							toCal.set(Calendar.MINUTE, 0);
							toCal.set(Calendar.SECOND, 0);
							toCal.set(Calendar.MILLISECOND, 0);

						} else {

							// =====================================================
							// unavailable_to 없음
							// → 무기한
							// 실제로 무한 날짜를 만들 수 없으므로
							// 현재 API 조회범위인 2개월 뒤 마지막 날까지 추가
							// =====================================================
							toCal = (Calendar) maxCal.clone();
						}

						// 이미 지난 시작일이면 오늘부터 추가
						if (fromCal.before(todayCal)) {
							fromCal = (Calendar) todayCal.clone();
						}

						// API 조회 범위보다 종료일이 멀면 조회 범위까지만
						if (toCal.after(maxCal)) {
							toCal = (Calendar) maxCal.clone();
						}

						// =========================================================
						// from ~ to 날짜 모두 불가능 날짜에 추가
						// =========================================================
						Calendar addCal = (Calendar) fromCal.clone();

						while (!addCal.after(toCal)) {

							String unavailableDate = impossibleDateFormat.format(addCal.getTime());

                            if (dateRange.add(unavailableDate)) {
                                printLog("A", "IMPOSSIBLE_PLACE unavailableDate : " + unavailableDate);
                            }

							addCal.add(Calendar.DATE, 1);
						}
					}
				}

			} catch (Exception e) {

				printLog("E", "IMPOSSIBLE_PLACE parse error : " + e.getMessage());
			}
		}

		printLog("D","dateRange.size() : "+ dateRange.size());

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		if(dateRange.size() == 0){
			dateRange.add(" ");
		}

		// 휴무일로 설정된 날이 있으면 휴무일도 이용불가능한날로 계산하기
		String strHolidaysQuery = getHolidaysQuery(strAptCode,"10");

		pstmt = conn.prepareStatement(strHolidaysQuery);
		rs_community = pstmt.executeQuery();

		rsMetaData = rs_community.getMetaData();
		// 휴무일을 조합하는 문자열
		String strHolidays = "";
		printLog("D","strHolidaysQuery : " +strHolidaysQuery);

		List<Holiday> holidays = new ArrayList<Holiday>();

		// 자바 1.7이전 버전에서는 switch문에 문자열이 안 됨...
		// int 타입으로 변경
		while (rs_community.next()) {
			holidays.add(createHolidayFromResultSet(rs_community));
		}

		Calendar today = Calendar.getInstance();
		Calendar endDate = (Calendar) today.clone();
		endDate.add(Calendar.MONTH, 2);
		endDate.set(Calendar.DAY_OF_MONTH, endDate.getActualMaximum(Calendar.DAY_OF_MONTH));

		Calendar checkDate = (Calendar) today.clone();

		SimpleDateFormat dateFormatYYYYMMDD = new SimpleDateFormat("yyyyMMdd");
		boolean isEmpty = true;

		while (!checkDate.after(endDate)) {
			int dayOfWeek = checkDate.get(Calendar.DAY_OF_WEEK) - 1; // 0: 일요일 ~ 6: 토요일
			int dayOfMonth = checkDate.get(Calendar.DAY_OF_MONTH);
			int weekOfMonth = checkDate.get(Calendar.WEEK_OF_MONTH);

			String formattedDateYYYYMMDD = dateFormatYYYYMMDD.format(checkDate.getTime());
			boolean isHolidayFound = false;

			for (Holiday holiday : holidays) {
								
				if (isTodayHoliday(holiday, dayOfWeek, dayOfMonth, weekOfMonth)) {
					isHolidayFound = true;
					break;
				}

				if (isTodayTempHoliday(holiday, formattedDateYYYYMMDD)) {
					isHolidayFound = true;
					break;
				}

				if(isPublicHoliday(formattedDateYYYYMMDD, conn)){
					isHolidayFound = true;
					break;
				}							
			}

			if(isSpecialOperatingDay(strAptCode, "10", formattedDateYYYYMMDD, conn)){
				isHolidayFound = false;
			}

			if (isHolidayFound) {
				isEmpty = false;
				printLog("D","formattedDateYYYYMMDD : " +formattedDateYYYYMMDD);

				baOutStream.write(formattedDateYYYYMMDD.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			}
			checkDate.add(Calendar.DAY_OF_MONTH, 1);
		}

		for (String unavailableDate : dateRange) {
			baOutStream.write(unavailableDate.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(RECORD_DEL);

			printLog("A","unavailableDate : "+ unavailableDate);
		}

		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_monthly_limit")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb,request,"UserId");
		String strCommunityType = getRequestParam(m_issacweb,request,"CommunityType");
		String strUUID = getRequestParam(m_issacweb, request, "UUID");
		String strDong = getRequestParam(m_issacweb, request, "UserDong");
		String strHo = getRequestParam(m_issacweb, request, "UserHo");

		String strQuery = "";
		strQuery += " SELECT RESERVE_LIMIT ";
		strQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";

		printLog("D","strQuery : "+ strQuery);

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();

		String strMaxCount = "0";
		if(rs.next()){
			strMaxCount = rs.getString(1);
		}
		
		
		

		String reservationQuery = "";
		reservationQuery += " SELECT DATE_FORMAT(DATE, '%Y%m') AS RESERVE_MONTH, ";
		reservationQuery += "        SUM(DATEDIFF(EXPIRATION_DATE, DATE)) AS RESERVED_DAYS ";
		reservationQuery += " FROM APT_COMMUNITY_RESERVE ";
		reservationQuery += " WHERE APT_CODE = " + strAptCode + " ";
		reservationQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
		reservationQuery += " AND USER_DONG = '" + strDong + "' ";
		reservationQuery += " AND USER_HO = '" + strHo + "' ";
		reservationQuery += " AND DATE_FORMAT(DATE, '%Y%m') >= DATE_FORMAT(CURDATE(), '%Y%m') "; // 이번 달 이상
		reservationQuery += " AND DATE_FORMAT(DATE, '%Y%m') <= DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 2 MONTH), '%Y%m') "; // 다다음 달 이하
		reservationQuery += " AND (RESERVE_CANCEL_CHANNEL IS NULL OR RESERVE_CANCEL_CHANNEL = '' )"; // 취소 안 된것만
		reservationQuery += " GROUP BY DATE_FORMAT(DATE, '%Y%m') "; // 월별로 그룹화

		pstmt = conn.prepareStatement(reservationQuery);
		rs = pstmt.executeQuery();

		// 월별 예약 결과 저장
		Map<String, Integer> reservationCounts = new HashMap<String, Integer>();
		List<String> targetMonths = new ArrayList<String>();
		Map<String, Integer> remainingCounts = new HashMap<String, Integer>();
		int maxCount = Integer.parseInt(strMaxCount); // 최대 예약 가능 일수

		// 이번 달부터 다다음 달까지 월 키 생성
		Calendar calendar = Calendar.getInstance();
		SimpleDateFormat monthFormat = new SimpleDateFormat("yyyyMM", Locale.getDefault());
		for (int i = 0; i < 3; i++) {
			targetMonths.add(monthFormat.format(calendar.getTime())); // 월 키 추가
			calendar.add(Calendar.MONTH, 1);
		}

		// 쿼리 결과 처리
		while (rs.next()) {
			String reserveMonth = rs.getString("RESERVE_MONTH"); // yyyyMM 형식
			//int reservedDays = rs.getInt("RESERVED_DAYS");
			String strReservedDays = rs.getString("RESERVED_DAYS");
			if(strReservedDays == null) strReservedDays = "0";
			int reservedDays = Integer.parseInt(strReservedDays);
			reservationCounts.put(reserveMonth, reservedDays);
		}
		// 각 월의 남은 예약 가능 일수 계산
		for (String month : targetMonths) {
			//int reserved = reservationCounts.getOrDefault(month, 0); // 예약된 일수
			int reserved = 0;
			if(reservationCounts.get(month) != null) {
				reserved = reservationCounts.get(month);
			}
			remainingCounts.put(month, Math.max(0, maxCount - reserved)); // 남은 일수
		}
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		// 결과 디버깅 출력
		for (String month : targetMonths) {
			baOutStream.write(Integer.toString(remainingCounts.get(month)).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		returnData(m_issacweb, baOutStream, outStream);
	
	}else if(strSID.contentEquals("get_min_max_people_range")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strMembershipId = getRequestParam(m_issacweb, request, "MembershipId");

		if(strMembershipId == null || strMembershipId.contentEquals("")){
			strMembershipId = "0";
		}

		String strMaxPeopleQuery = "SELECT MIN_PEOPLE, MAX_PEOPLE " + 
								" FROM APT_COMMUNITY_MEMBERSHIP_INFO " +
								" WHERE MEMBERSHIP_ID = ? ";

		pstmt = conn.prepareStatement(strMaxPeopleQuery);

		pstmt.setInt(1, Integer.parseInt(strMembershipId));
		
		rs = pstmt.executeQuery();
		String strMaxPeople = "0";
		String strMinPeople = "0";
		if (rs.next()) {
			strMinPeople = rs.getString("MIN_PEOPLE");
			strMaxPeople = rs.getString("MAX_PEOPLE");
		} else {
			strMinPeople = "0";
			strMaxPeople = "0";
		}
		
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write(strMinPeople.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
		baOutStream.write(strMaxPeople.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
		

		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_holidays")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb,request,"UserId");
		String strMembershipId = getRequestParam(m_issacweb,request,"MembershipId");
		String strCommunityType = getRequestParam(m_issacweb, request, "CommunityType");
				
		
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		List<Holiday> holidays = new ArrayList<Holiday>();

	
		String strHolidaysQuery = getHolidaysQuery(strAptCode,strCommunityType);

		pstmt = conn.prepareStatement(strHolidaysQuery);
		rs_community = pstmt.executeQuery();

		rsMetaData = rs_community.getMetaData();
		// 휴무일을 조합하는 문자열
		String strHolidays = "";
				printLog("D","strHolidaysQuery : " +strHolidaysQuery);


		// 자바 1.7이전 버전에서는 switch문에 문자열이 안 됨...
		// int 타입으로 변경
		for(int nHoliDaysRow = 0; rs_community.next(); nHoliDaysRow++) {
			String strRepeatType =  rs_community.getString(1);
			String strHoliDaysDayOfWeek = rs_community.getString(2);
			String strHolidaysDayOfMonth = rs_community.getString(3);
			String strSpecificType = rs_community.getString(4);
			String strSpecialDay = rs_community.getString(5);
			int nSpecificRepeatType = -1;
			int nHoliDaysDayOfWeek = -1;
			int nHolidaysDayOfMonth = -1;
			int nSpecificType = -1;
			if(strRepeatType != null && !strRepeatType.contentEquals("")){
				nSpecificRepeatType = Integer.parseInt(strRepeatType);
			}
			if(strHoliDaysDayOfWeek != null && !strHoliDaysDayOfWeek.contentEquals("")){
				nHoliDaysDayOfWeek = Integer.parseInt(strHoliDaysDayOfWeek);
			}
			if(strHolidaysDayOfMonth != null && !strHolidaysDayOfMonth.contentEquals("")){
				nHolidaysDayOfMonth = Integer.parseInt(strHolidaysDayOfMonth);
			}
			if(strSpecificType != null && !strSpecificType.contentEquals("")){
				nSpecificType = Integer.parseInt(strSpecificType);
			}
			if(strSpecialDay == null) {
				strSpecialDay = "";
			}
			holidays.add(new Holiday(nSpecificRepeatType, nHoliDaysDayOfWeek, nHolidaysDayOfMonth, nSpecificType, strSpecialDay)); // 매주 월요일					
		}


		Calendar today = Calendar.getInstance();
		Calendar endDate = (Calendar) today.clone();
		endDate.add(Calendar.MONTH, 2);
		endDate.set(Calendar.DAY_OF_MONTH, endDate.getActualMaximum(Calendar.DAY_OF_MONTH));

		Calendar checkDate = (Calendar) today.clone();

		SimpleDateFormat dateFormatYYYYMMDD = new SimpleDateFormat("yyyyMMdd");
		boolean isEmpty = true;

		while (!checkDate.after(endDate)) {
			int dayOfWeek = checkDate.get(Calendar.DAY_OF_WEEK) - 1; // 0: 일요일 ~ 6: 토요일
			int dayOfMonth = checkDate.get(Calendar.DAY_OF_MONTH);
			int weekOfMonth = checkDate.get(Calendar.WEEK_OF_MONTH);

			String formattedDateYYYYMMDD = dateFormatYYYYMMDD.format(checkDate.getTime());

			boolean isHolidayFound = false;

			for (Holiday holiday : holidays) {
								
				if (isTodayHoliday(holiday, dayOfWeek, dayOfMonth, weekOfMonth)) {
					isHolidayFound = true;
					break;
				}

				if (isTodayTempHoliday(holiday, formattedDateYYYYMMDD)) {
					isHolidayFound = true;
					break;
				}
			}


			if (isHolidayFound) {
				isEmpty = false;
				printLog("D","formattedDateYYYYMMDD : " +formattedDateYYYYMMDD);

				baOutStream.write(formattedDateYYYYMMDD.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			}

			checkDate.add(Calendar.DAY_OF_MONTH, 1);
		}

		if(isEmpty){
			baOutStream.write(" ".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		baOutStream.write(RECORD_DEL);
		returnData(m_issacweb, baOutStream, outStream);


	}


}catch(Exception e) {
	ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
	String errMsg = "Exception Msg = " + e.getMessage();
	baOutStream.write(errMsg.getBytes(S_CHARSET));
	printLog("A", " ###### errMsg  = #####" + errMsg);

	// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
	returnData(m_issacweb, baOutStream, outStream);
}
finally {
	// Release a database resources
	if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
	if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
	if(conn != null) { try { conn.close(); } catch(Exception ignore) {} }
}
%>

