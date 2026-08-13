<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="com.softbase.image.ImageThumbnail" %>
<%@ page import="java.io.*" %>
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
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.Random" %>

<%@ page import ="org.apache.http.HttpResponse" %>
<%@ page import="java.net.*"%>
<%@ page import="org.apache.http.impl.client.HttpClientBuilder" %>
<%@ page import="org.apache.http.impl.client.CloseableHttpClient" %>
<%@ page import="org.apache.http.impl.client.BasicResponseHandler" %>
<%@ page import="org.apache.http.client.ResponseHandler" %>
<%@ page import="org.apache.http.client.methods.CloseableHttpResponse" %>
<%@ page import="org.apache.http.client.methods.HttpPost" %>
<%@ page import="org.apache.http.entity.StringEntity" %>
<%@ include file="./apt_global_payment.jsp" %>

<%!
	public String getRequestParam(HttpServletRequest request, String strKey) {
		if(strKey == null || strKey.contentEquals("")) {
			printLog("A", "getRequestParam strKey null");
			return "";
		}
		
		String strValue = request.getParameter(strKey);
		if(strValue == null) strValue = "";

		try {
			strValue = new String(strValue.getBytes("8859_1"), S_CHARSET);
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return strValue;
	}
	
	/**
	 * 빌리진아이 데이터 전송 포맷[ 데이터길이(4자리) + 데이터 ] 에 맞게 조합한 후, 클라이언트로 전송..
	 */
	public void returnData(ByteArrayOutputStream baOutStream, OutputStream outStream) {
		if(baOutStream == null || outStream == null) {
			return;
		}

		try {
			byte[] baSendData = null;
			baSendData = baOutStream.toByteArray();

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
				baSendData = baOutStream.toByteArray();
	
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

	/* 로그파일 생성
	 * 결제 처리중 실패시 로그 남김(월별 파일 생성).
	 */
	public void writeLogFile(String strLog) {

		PrintWriter writer = null;
		try {
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
			Date date = new Date();
			String strDate = dateFormat.format(date);
			String strFileName = strDate.substring(0, 7) + ".txt";		// 월별로 생성
			
			String strWebrootPath = getServletContext().getRealPath("/");
			strWebrootPath = strWebrootPath.replaceAll("\\\\", "/");
			String strSavePath = strWebrootPath + "villizinei/file/payerror/";

			String strFilePath = strSavePath + strFileName;

			File file = new File(strFilePath);
			if(!file.exists()) {
				file.createNewFile();
          }

			FileWriter fw = new FileWriter(file, true);		// 이어쓰기
			writer = new PrintWriter(fw);

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

	// 날짜 포맷 변환 메서드
	// 20240705 피그마 기준 yy.MM,dd(E)
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

    // 시간 포맷 변환 메서드
	// 20240705 피그마 기준 HH:mm ~ HH:mm
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

	private String getTimeQuery(String aptCode, String communityType) {
		return "SELECT  " +
			" START_TIME , END_TIME, " +
			" OPERATION_HOURS, " +
			" COMMUNITY_STATE " +
			"FROM APT_COMMUNITY " +
			"WHERE APT_CODE = '" + aptCode + "'  "+
			" AND  COMMUNITY_TYPE= '" + communityType + "'  ";
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

	private String getHolidaysQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, SPECIFIC_TYPE, SPECIAL_DAY " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND (SPECIFIC_TYPE = '0' OR SPECIFIC_TYPE = '3') ";
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

	/// 개발 서버 URL 우회하는 함수
	public void callDevMemberDeleteAPI(String strresultBeforeUUID, String strDoorId, String strAptCode, String strCommunityType, Connection conn) {	
		String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v11.jsp";
        String strCallSID = "call_delete_api";
        try {
            // 쿼리 파라미터 인코딩
            String query = String.format("SID=%s&strresultBeforeUUID=%s&strDoorId=%s&strAptCode=%s&strCommunityType=%s",
					URLEncoder.encode(strCallSID, "UTF-8"),
					URLEncoder.encode(strresultBeforeUUID, "UTF-8"),
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

	public void callDevReservationAPI(String strUserId, String strReservationUserName, String strReservationUserPhone,
	 String strDate, String strTime, String strDoorId, String strAptCode, Connection conn, String strCommunityType, String strDong, String strHo) {
    	String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v11.jsp";
        String strCallSID = "call_reservation_api";
        try {
            // 쿼리 파라미터 인코딩
            String query = String.format("SID=%s&strUserId=%s&strReservationUserName=%s&strReservationUserPhone=%s&strDate=%s&strTime=%s&strDoorId=%s&strAptCode=%s&strCommunityType=%s&strUserDong=%s&strUserHo=%s",
					URLEncoder.encode(strCallSID, "UTF-8"),
					URLEncoder.encode(strUserId, "UTF-8"),
                    URLEncoder.encode(strReservationUserName, "UTF-8"),
                    URLEncoder.encode(strReservationUserPhone, "UTF-8"),
					URLEncoder.encode(strDate, "UTF-8"),
                    URLEncoder.encode(strTime, "UTF-8"),
                    URLEncoder.encode(strDoorId, "UTF-8"),
					URLEncoder.encode(strAptCode, "UTF-8"),
					URLEncoder.encode(strCommunityType, "UTF-8"),
                    URLEncoder.encode(strDong, "UTF-8"),
					URLEncoder.encode(strHo, "UTF-8"));
					
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

	private int getRemainingUses(Connection conn, String membershipId, String strUserDong, String strUserHo, String strUserName, String aptCode, int usageLimit) throws SQLException {
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

		PreparedStatement pstmt = conn.prepareStatement(strUserMembershipListQuery);
        pstmt.setString(1, membershipId);
        pstmt.setString(2, strUserDong);
		pstmt.setString(3, strUserHo);
		pstmt.setString(4, strUserName);
		pstmt.setString(5, aptCode);
        ResultSet rs = pstmt.executeQuery();
		String strMembershipListId = "0";
		if (rs.next()) {
			strMembershipListId = rs.getString("MEMBERSHIP_USER_LIST_ID");
		}

        String strUsageQuery = 
            "SELECT COUNT(*) as use_count FROM APT_COMMUNITY_RESERVE " +
            "WHERE MEMBERSHIP_USER_LIST_ID = ?  " +
			" AND USER_DONG = ? " +	
			" AND USER_HO = ? " +	
			" AND RESERVE_USER_NAME = ? " +
			" AND APT_CODE = ? " +
            " AND RESERVE_CANCEL_TIME IS NULL";
            
        pstmt = conn.prepareStatement(strUsageQuery);
        pstmt.setString(1, strMembershipListId);
        pstmt.setString(2, strUserDong);
		pstmt.setString(3, strUserHo);
		pstmt.setString(4, strUserName);
        pstmt.setString(5, aptCode);
        rs = pstmt.executeQuery();
		if (rs.next()) {
			int usedCount = rs.getInt("use_count");
			return Math.max(0, usageLimit - usedCount);
		}
		return 0;
    }

	// 현재 시간이 시작 시간과 종료 시간 사이에 있는지 확인하는 함수
    public static boolean isTimeWithinRange(String currentTime, String startTime, String endTime) {
        // 현재 시간이 시작 시간과 종료 시간 사이에 있는지 비교
        return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
    }

	public static String createDateTimeId() {
		// 일시YYMMDDHHMMSSMS(15)
		SimpleDateFormat simpleDateFormat = new SimpleDateFormat("YYYYMMddHHmmssSSS");
		Date date = new Date();
		String strDate = simpleDateFormat.format(date);
		strDate = strDate.substring(2, 17);
		
		// 랜덤(4) + 일시(15)
		return strDate;
	}

	public String formatDateTime(String dateTime) {

		if(dateTime == null || dateTime.trim().contentEquals("")) {
			return "";
		}

		dateTime = dateTime.trim();

		if(dateTime.length() != 14) {
			return "";
		}

		try {
			TimeZone seoulTimeZone = TimeZone.getTimeZone("Asia/Seoul");

			SimpleDateFormat inputFormat =
				new SimpleDateFormat("yyyyMMddHHmmss");
			inputFormat.setTimeZone(seoulTimeZone);

			SimpleDateFormat outputFormat =
				new SimpleDateFormat("yy.MM.dd(E) HH:mm:ss", Locale.KOREAN);
			outputFormat.setTimeZone(seoulTimeZone);

			Date parsedDate = inputFormat.parse(dateTime);

			return outputFormat.format(parsedDate);

		} catch(Exception e) {
			e.printStackTrace();
			return "";
		}
	}
	
%>

<%
Connection 			conn = null;			// DB Connection Object
PreparedStatement 	pstmt = null;			// JDBC PreparedStatement Object
ResultSet 			rs = null;	 			// Query Result Set Object

ResultSetMetaData 	rsMetaData = null;

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

	// Get Parameter - SID = query 구분.
	String strSID = getRequestParam(request, "SID");
	printLog("A", "SID : " + strSID);

    if(strSID.contentEquals("cancel_myreservation")) {
	//예약 취소하기
		String strAptCommunityReservationId = getRequestParam(request, "ReservationId");
		String strRequestCancelTime = getRequestParam(request, "CancelTime");
		String strRequestCancelReason = getRequestParam(request, "CancelReason");
		String strRequestCancelChannel = getRequestParam(request, "CancelChannel");
		String strIsRefund = getRequestParam(request, "IsRefund"); // "0" : 환불 안 함 or "1" : 환불 함

		if(strRequestCancelTime == null) {
			strRequestCancelTime = "";
		}
		if(strRequestCancelChannel == null || strRequestCancelChannel.contentEquals("")) {
			strRequestCancelChannel = "00";
		}
		if(strIsRefund == null || strIsRefund.contentEquals("")){
			strIsRefund = "1";
		}
		printLog("A", "strIsRefund : " + strIsRefund);

		boolean isCancelMembershipUserList = false;
		String strCancelMembershipUserListId = "0";

		// Create a insert query
		String strQuery = "";
		strQuery += " UPDATE APT_COMMUNITY_RESERVE SET "; 
		// 관리자프로그램에서 취소할 경우에는 취소시간, 취소채널이 파라미터로 넘어온다.
		if(14 <= strRequestCancelTime.length()) {
			strQuery += " RESERVE_CANCEL_TIME = " + strRequestCancelTime + ",";
		}  else {
			strQuery += " RESERVE_CANCEL_TIME = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'),";
		} 
		
		if(strRequestCancelReason != null) {
			strQuery += " CANCEL_REASON = '" + strRequestCancelReason + "',";
		} 
		strQuery += " RESERVE_CANCEL_CHANNEL='" + strRequestCancelChannel + "' ";
		strQuery += " WHERE RESERVE_ID = '" + strAptCommunityReservationId + "' " ;

		pstmt = conn.prepareStatement(strQuery);
		int nRet = pstmt.executeUpdate();


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
		
		// 얼굴인식을 쓰는 커뮤니티센터면 삭제 API도 호출
		// 현재 예약한 서비스에 해당하는 문을 조회환 다음 for문으로 문에 등록된 사용자 제거
		String strReservationInfoQuery = "";
		strReservationInfoQuery += "SELECT COMMUNITY_TYPE, APT_CODE, MEMBERSHIP_ID, MEMBERSHIP_USER_LIST_ID, USER_ID, USER_DONG, USER_HO, RESERVE_USER_NAME, DATE, TIME ";
		strReservationInfoQuery += " FROM APT_COMMUNITY_RESERVE ";
		strReservationInfoQuery += " WHERE RESERVE_ID = '" + strAptCommunityReservationId + "' " ;
		pstmt = conn.prepareStatement(strReservationInfoQuery);
		rs = pstmt.executeQuery();
		String strCommunityType = "";
		String strAptCode = "";
		String strMembershipListId = "";
		String strMembershipId = "";
		String strUserId = "";
		String strUserDong = "";
		String strUserHo = "";
		String strReservationUserName = "";
		String strReserveDate = "";
		String strReserveTime = "";
		boolean isReservationFuture = false;
		String strPaymentCount = "";

		if(rs.next()){
			strCommunityType = rs.getString(1);
			strAptCode = rs.getString(2);
			strMembershipId = rs.getString(3) != null ? rs.getString(3) : "";
			strMembershipListId = rs.getString(4);	
			strUserId = rs.getString(5);		
			strUserDong = rs.getString(6);
			strUserHo = rs.getString(7);
			strReservationUserName = rs.getString(8);
			strReserveDate     = rs.getString(9) != null ? rs.getString(9) : "";
   		 	strReserveTime     = rs.getString(10) != null ? rs.getString(10) : "";
		}

	  	strCancelMembershipUserListId = strMembershipListId;
		if(nRet == 1){
			// 예약 취소 성공했는데 결제가 안된경우 취소했을때는 회원권 내역도 같이 취소
			String strPaymentCheckQuery = " SELECT COUNT(*) ";
			strPaymentCheckQuery += "FROM PARTNER_PAYMENT ";
			strPaymentCheckQuery += " WHERE MENU_ID = '49' ";
			strPaymentCheckQuery += " AND STATE = '0' ";
			strPaymentCheckQuery += " AND RESERVATION_ID = '" + strCancelMembershipUserListId + "' ";

			pstmt = conn.prepareStatement(strPaymentCheckQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strPaymentCount     = rs.getString(1) != null ? rs.getString(1) : "";
			}		
		}

				printLog("A", "strPaymentCount : " + strPaymentCount);

	

		String strMembershipConditionQuery = "";
		strMembershipConditionQuery += "SELECT MEMBERSHIP_CONDITION, APT_CODE, CANCEL_TYPE, NEED_TO_PAY ";
		strMembershipConditionQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipConditionQuery += " WHERE MEMBERSHIP_ID = '" + strMembershipId + "'";

		rs = pstmt.executeQuery(strMembershipConditionQuery);
		String membershipCondition = ""; 
		strAptCode = "";
		String strMemebershipCancelType = "";

		if (rs.next()) {
			membershipCondition = rs.getString("MEMBERSHIP_CONDITION");
			strAptCode = rs.getString("APT_CODE");
			strMemebershipCancelType = rs.getString("CANCEL_TYPE");

		}
	
		if(strMemebershipCancelType.contentEquals("0") && membershipCondition.contentEquals("0")){
			String strDongHoQuery = "";
			strDongHoQuery += "SELECT USER_DONG, USER_HO ";
			strDongHoQuery += " FROM USER_INFO ";
			strDongHoQuery += " WHERE 1 = 1 ";
			strDongHoQuery += " AND USER_ID ='" + strUserId + "' ";
			strDongHoQuery += " AND APT_CODE = " + strAptCode + " ";
		
			pstmt = conn.prepareStatement(strDongHoQuery);
			rs = pstmt.executeQuery();
			String strDong = "";
			String strHo = "";
			String strUserName = "";

			if(rs.next()){
				strDong = rs.getString(1);
				strHo = rs.getString(2);
			}

			String strParentMembershipQuery = "SELECT MEMBERSHIP_GROUP " +
											" FROM APT_COMMUNITY_MEMBERSHIP_INFO " +
											" WHERE MEMBERSHIP_ID = ? ";

			pstmt = conn.prepareStatement(strParentMembershipQuery);
			pstmt.setString(1, strMembershipId);		
			rs = pstmt.executeQuery();

			String strParenrMembershipId = "";
			if (rs.next()) {
				strParenrMembershipId = rs.getString("MEMBERSHIP_GROUP");
			}

			//같은 아파트,동,호에 CONDITION = 0인 회원권이 있으면 해당 회원권을 취소하고 1인 회원권으로 새로 등록

			// 1. CONDITION = 0인 회원권 조회 (MEMBERSHIP_CONDITION을 가져오기 위해 조인 사용)
			String strCheckMembershipQuery = "SELECT ul.MEMBERSHIP_USER_LIST_ID, ul.MEMBERSHIP_ID, ul.USER_ID, ul.USER_NAME " +
								"FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ul " +
								"JOIN APT_COMMUNITY_MEMBERSHIP_INFO mi ON ul.MEMBERSHIP_ID = mi.MEMBERSHIP_ID " +
								"WHERE ul.USER_ID != ?  AND ul.APT_CODE = ? AND ul.USER_DONG = ? AND ul.USER_HO = ? "+
								" AND mi.MEMBERSHIP_CONDITION = '1' AND mi.MEMBERSHIP_GROUP = ?" +
								" AND (ul.CANCEL_DATE IS NULL OR ul.CANCEL_DATE = '')" +
								" AND  STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() " +
								" AND STR_TO_DATE(ul.REGISTRATION_DATE, '%Y%m%d%H%i%s') <= NOW() " +
								"LIMIT 1"; // 아무나 결과를 한 개만 추출

			pstmt = conn.prepareStatement(strCheckMembershipQuery);
			pstmt.setString(1, strUserId);
			pstmt.setString(2, strAptCode);
			pstmt.setString(3, strDong);
			pstmt.setString(4, strHo);
			pstmt.setString(5, strParenrMembershipId);
			rs = pstmt.executeQuery();

			if (rs.next()) {
				// 2. CONDITION = 1인 회원권이 존재하면 해당 회원권, 예약을 취소
				String strMembershipIdToCancel = rs.getString("MEMBERSHIP_ID");
				String strNewUserId = rs.getString("USER_ID");
				String strNewUserName = rs.getString("USER_NAME");
				String strMembershipUserListId = rs.getString("MEMBERSHIP_USER_LIST_ID");

				String strCancelMembershipQuery = "UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
												"SET CANCEL_DATE = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') " +
												"WHERE MEMBERSHIP_USER_LIST_ID = ?";

				PreparedStatement pstmtCancel = conn.prepareStatement(strCancelMembershipQuery);
				pstmtCancel.setString(1, strMembershipUserListId);						
				pstmtCancel.executeUpdate();

				
				String strCancelReserveQuery = "UPDATE APT_COMMUNITY_RESERVE " +
												"SET RESERVE_CANCEL_TIME = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), " +
												" RESERVE_CANCEL_CHANNEL = '00' " +
												"WHERE MEMBERSHIP_USER_LIST_ID = ?";

				pstmtCancel = conn.prepareStatement(strCancelReserveQuery);
				pstmtCancel.setString(1, strMembershipUserListId);						
				pstmtCancel.executeUpdate();

				// 3. CONDITION = 0인 회원권으로 새로 등록
				// 취소된 회원권 정보 조회
				String strRetrieveMembershipQuery = "SELECT EXPIRATION_DATE, DESCRIPTION, " +
													"USER_NAME, COMMUNITY_TYPE, OPTIONS, USE_COUNT " +
													"FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
													"WHERE MEMBERSHIP_USER_LIST_ID = ? ";

				PreparedStatement pstmtRetrieve = conn.prepareStatement(strRetrieveMembershipQuery);
				pstmtRetrieve.setString(1, strMembershipUserListId);				
				ResultSet rsRetrieve = pstmtRetrieve.executeQuery();

				if (rsRetrieve.next()) {
					// 2. 기존 회원권의 모든 값 가져오기
					String expirationDate = rsRetrieve.getString("EXPIRATION_DATE");
					String description = rsRetrieve.getString("DESCRIPTION");
					String userName = rsRetrieve.getString("USER_NAME");
					String communityType = rsRetrieve.getString("COMMUNITY_TYPE");
					String options = rsRetrieve.getString("OPTIONS") != null ? rsRetrieve.getString("OPTIONS") : "";
					String useCount = rsRetrieve.getString("USE_COUNT");	

					// 3. 새로운 회원권으로 삽입
					 String strInsertMembershipQuery = "INSERT INTO APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
								"(USER_ID, MEMBERSHIP_ID, PRICE, REGISTRATION_DATE, EXPIRATION_DATE, DESCRIPTION, " +
								"USER_DONG, USER_HO, USER_NAME, APT_CODE, PURCHASE_DATE, COMMUNITY_TYPE, " +
								"OPTIONS, USE_COUNT) " +
								"VALUES (?, ?, (SELECT COALESCE(m.PRICE, 0) + COALESCE((SELECT o.OPTION_PRICE FROM APT_COMMUNITY_MEMBERSHIP_OPTION o WHERE o.OPTION_ID = ?), 0) " +
								"FROM APT_COMMUNITY_MEMBERSHIP_INFO m WHERE m.MEMBERSHIP_ID = ?), " + 
								"DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ?, ?, ?, ?, ?, ?, DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ?, ?, ?)";


					PreparedStatement pstmtInsert = conn.prepareStatement(strInsertMembershipQuery);
					pstmtInsert.setString(1, strNewUserId); // 기존 USER_ID 사용
					pstmtInsert.setString(2, strMembershipId); // 기존 MEMBERSHIP_ID 사용
					pstmtInsert.setString(3, options); // OPTION_ID 파라미터
					pstmtInsert.setString(4, strMembershipId); // 기존 MEMBERSHIP_ID 사용
					pstmtInsert.setString(5, expirationDate); // 기존 EXPIRATION_DATE 사용
					pstmtInsert.setString(6, description); // 기존 DESCRIPTION 사용
					pstmtInsert.setString(7, strDong); // 기존 USER_DONG 사용
					pstmtInsert.setString(8, strHo); // 기존 USER_HO 사용
					pstmtInsert.setString(9, userName); // 기존 USER_NAME 사용
					pstmtInsert.setString(10, strAptCode); // 기존 APT_CODE 사용
					pstmtInsert.setString(11, communityType); // 기존 COMMUNITY_TYPE 사용
					pstmtInsert.setString(12, options); // 기존 OPTIONS 사용
					pstmtInsert.setString(13, useCount); // 기존 USE_COUNT 사용


					pstmtInsert.executeUpdate();

					String strLastMembershipUserListIdQuery = "SELECT MEMBERSHIP_USER_LIST_ID ";
					strLastMembershipUserListIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
					strLastMembershipUserListIdQuery += " WHERE USER_ID = ? ";
					strLastMembershipUserListIdQuery += " ORDER BY MEMBERSHIP_USER_LIST_ID DESC ";
					strLastMembershipUserListIdQuery += " LIMIT 1 ";

					pstmt = conn.prepareStatement(strLastMembershipUserListIdQuery);
					pstmt.setString(1, strNewUserId);				
					rs = pstmt.executeQuery();

					if(rs.next()){
						String strLastMembershipUserListId = rs.getString("MEMBERSHIP_USER_LIST_ID");

						String strCancelReserveIdQuery = "SELECT RESERVE_ID ";
						strCancelReserveIdQuery += " FROM APT_COMMUNITY_RESERVE ";
						strCancelReserveIdQuery += " WHERE USER_ID = ? ";
						strCancelReserveIdQuery +=  "AND MEMBERSHIP_USER_LIST_ID = ? ";

						pstmt = conn.prepareStatement(strCancelReserveIdQuery);
						pstmt.setString(1, strNewUserId);				
						pstmt.setString(2, strMembershipUserListId);	
						rs = pstmt.executeQuery();			

						if(rs.next()){
							String strCancelReserveId = rs.getString("RESERVE_ID");

							String strNewReserveInsertQuery = "";
							strNewReserveInsertQuery += "INSERT INTO APT_COMMUNITY_RESERVE ";
							strNewReserveInsertQuery += "(COMMUNITY_TYPE, USER_ID, USER_DONG, USER_HO, RESERVE_USER_NAME, RESERVE_USER_PHONE, ";
							strNewReserveInsertQuery += "PLACE, DATE, TIME, APT_CODE, USER_NAME, REG_CHANNEL, EXPIRATION_DATE, GENDER, ";
							strNewReserveInsertQuery += "RESERVATION_PEOPLE, MEMBERSHIP_ID, MEMBERSHIP_USER_LIST_ID, REG_DATE) ";
							strNewReserveInsertQuery += "SELECT COMMUNITY_TYPE, USER_ID, USER_DONG, USER_HO, RESERVE_USER_NAME, RESERVE_USER_PHONE, ";
							strNewReserveInsertQuery += "PLACE, DATE, TIME, APT_CODE, USER_NAME, REG_CHANNEL, EXPIRATION_DATE, GENDER, ";
							strNewReserveInsertQuery += "RESERVATION_PEOPLE, ?, ?, DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') ";
							strNewReserveInsertQuery += "FROM APT_COMMUNITY_RESERVE ";
							strNewReserveInsertQuery += "WHERE RESERVE_ID = ? ";

							pstmt = conn.prepareStatement(strNewReserveInsertQuery);
							pstmt.setString(1, strMembershipId);
							pstmt.setString(2, strLastMembershipUserListId);
							pstmt.setString(3, strCancelReserveId); 

							nRet = pstmt.executeUpdate();


						}					
					}
				}
			}
		}


		String strMembershipReservationTypeQuery = "";
		strMembershipReservationTypeQuery += " SELECT RESERVATION_TYPE ";
		strMembershipReservationTypeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipReservationTypeQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

		pstmt = conn.prepareStatement(strMembershipReservationTypeQuery);
		rs = pstmt.executeQuery();
		String strReservationType = "";
	
		if(rs.next()){
			strReservationType = rs.getString(1);		
		}

		if(!strReservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE) || (strPaymentCount != null && strPaymentCount.contentEquals("1"))){
			String strMembershipCancelQuery = "";

			strMembershipCancelQuery += " UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET "; 
			// 관리자프로그램에서 취소할 경우에는 취소시간, 취소채널이 파라미터로 넘어온다.
			if(14 <= strRequestCancelTime.length()) {
				strMembershipCancelQuery += " CANCEL_DATE = '" + strRequestCancelTime + "' ";
			}  else {
				strMembershipCancelQuery += " CANCEL_DATE = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') ";
			} 
			strMembershipCancelQuery += ", CANCEL_CHANNEL= '" + strRequestCancelChannel + "' ";
	 		if(strRequestCancelReason != null) {
				strMembershipCancelQuery += ", CANCEL_REASON = '" + strRequestCancelReason + "' ";
			}				
			strMembershipCancelQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strMembershipListId;

			pstmt = conn.prepareStatement(strMembershipCancelQuery);
			nRet = pstmt.executeUpdate();

			if(nRet == 1){
				isCancelMembershipUserList = true;
			}
		}


		if(strCommunityType != null && !strCommunityType.contentEquals("")){
			// 해당 시설에 등록된 SECURITY값으로 해당 값이 1이면 얼굴 인식기능을 사용하는 아파트
			// 얼굴인식을 쓰는 아파트면 해당 시설에 등록된 문 Id를 배열로 만들어서 해당 문에 등록된 사용자 삭제 처리
			String strSecurityQuery = "";
			strSecurityQuery += "SELECT SECURITY ";
			strSecurityQuery += "FROM APT_COMMUNITY ";
			strSecurityQuery += "WHERE APT_CODE = " + strAptCode + " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
			
			pstmt = conn.prepareStatement(strSecurityQuery);
			rs = pstmt.executeQuery();
			String strSecurity = "";
			if(rs.next()){
				strSecurity = rs.getString(1);		
			}

			if(strSecurity != null && strSecurity.contentEquals("1")){
				String strCommunityDoorQuery = "";
				strCommunityDoorQuery += " SELECT DOOR_ID ";
				strCommunityDoorQuery += " FROM APT_COMMUNITY_DOOR ";
				strCommunityDoorQuery += " WHERE 1 = 1 ";
				strCommunityDoorQuery += " AND  ATP_CODE = " + strAptCode + " ";
				strCommunityDoorQuery += " AND  COMMUNITY_TYPE LIKE '%" + strCommunityType + "%' ";

				pstmt = conn.prepareStatement(strCommunityDoorQuery);
				rs = pstmt.executeQuery();
				List<String> listDoorIds = new ArrayList<String>();
					// Loop a select result records
				String strDoorId = "";
				for(int nRow = 0; rs.next(); nRow++) {
					strDoorId = rs.getString(1);
					listDoorIds.add(strDoorId);
				}

				for (int nDoorId = 0; nDoorId < listDoorIds.size(); nDoorId++) { // n은 반복 횟수
					// callEntranceRegistrationAPI 메서드를 동기적으로 호출					
					
					callDevMemberDeleteAPI(strAptCommunityReservationId,listDoorIds.get(nDoorId), strAptCode, strCommunityType, conn);
					// 이 코드는 위의 callEntranceRegistrationAPI 호출이 완료된 후 실행됩니다.
					System.out.println("API 호출 완료: " + (nDoorId + 1) + "번째 호출");
				}

			}

		}

		if(nRet != 0){

			String strPushQuery = "";
			strPushQuery = "SELECT COUNT(*) ";
			strPushQuery += " FROM APT_COMMUNITY ";
			strPushQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strPushQuery += " AND COMMUNITY_TYPE ='" + strCommunityType + "' ";
			strPushQuery += " AND PUSH_NOTI_CODE IN (2,4,9) " ;

			pstmt = conn.prepareStatement(strPushQuery);
			rs = pstmt.executeQuery();

			String strPushNotiCode = "";
			
			if(rs.next()) {
				strPushNotiCode = rs.getString(1);
			} else {
				strPushNotiCode = "0"; // 안전한 기본값
			}

			if(!strPushNotiCode.contentEquals("0")){

				String strCommunityCenterNameQuery = "";
				strCommunityCenterNameQuery = "SELECT TITLE FROM APT_COMMUNITY WHERE APT_CODE = " + strAptCode + " AND COMMUNITY_TYPE = '" +  strCommunityType + "' ";
				pstmt = conn.prepareStatement(strCommunityCenterNameQuery);
				rs = pstmt.executeQuery();

				String strCommunityCenterName = "";
				
				if(rs.next()) {
					strCommunityCenterName = rs.getString(1);
				} else {
					strCommunityCenterName = "커뮤니티센터"; // 안전한 기본값
				}


				String strMsg = "";
				strMsg = strUserDong + "동 "
				+ strUserHo + "호 "
				+ strReservationUserName + "님이 "
				+ strCommunityCenterName
				+ " 예약을 취소하셨습니다.";


				


				RequestDispatcher dispatcher = request.getRequestDispatcher("push_send_service.jsp");
				request.setAttribute("SID", new String(strSID));
				request.setAttribute("Community_AptCode", new String(strAptCode));
				request.setAttribute("Community_Msg", new String(strMsg));
				dispatcher.include(request, response);							

			}

			try {
				String strNormalizedDateTime = "";

				printLog("A", "strReserveDate: " + strReserveDate);

				if (strReserveDate.length() == 12) {
					// 케이스 2: DATE가 yyyyMMddHHmm
					strNormalizedDateTime = strReserveDate;

				}else if(strReserveDate.length() == 14){
					strNormalizedDateTime = strReserveDate.substring(0,12);

				} else if (strReserveDate.length() == 8) {
					// 케이스 1: DATE=yyyyMMdd, TIME이 없거나 빈 경우 0000으로 처리
					String strTimePrefix = "0000";
					if (strReserveTime != null && strReserveTime.length() >= 4) {
						strTimePrefix = strReserveTime.substring(0, 4);
					}
					strNormalizedDateTime = strReserveDate + strTimePrefix;
				}
				printLog("A", "strNormalizedDateTime: " + strNormalizedDateTime);

				if (!strNormalizedDateTime.isEmpty()) {
					SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmm");
					Date reserveStartTime = sdf.parse(strNormalizedDateTime);
					isReservationFuture = reserveStartTime.after(new Date());
				}

			} catch (Exception e) {
				printLog("A", "cancel_myreservation 날짜 파싱 오류: " + e.getMessage());
				isReservationFuture = false;
			}
			
			// 관리자 프로그램에서 취소시 미래날짜 예약인지 체크하지 않고 무조건 취소가능하게 강제로 미래로 세팅해 줌.
			if(!strRequestCancelChannel.contentEquals("00")) {
				isReservationFuture = true;
			}

			printLog("A", "isReservationFuture: " + isReservationFuture);

			String strMembershipSettlementQuery = "";
			strMembershipSettlementQuery += "SELECT SETTLEMENT_DATE FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST";
			strMembershipSettlementQuery += " WHERE MEMBERSHIP_USER_LIST_ID = '" + strCancelMembershipUserListId + "' ";

			pstmt = conn.prepareStatement(strMembershipSettlementQuery);
			rs = pstmt.executeQuery();

			String strSettlementDate = "";
			if (rs.next()) {
				strSettlementDate = rs.getString("SETTLEMENT_DATE");
			}

			printLog("A", "strSettlementDate : " + strSettlementDate);

			// 오늘 날짜와 비교
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
			String strToday = sdf.format(new Date());
			boolean idSettlement = false;

			if (strSettlementDate != null && !strSettlementDate.isEmpty() && strSettlementDate.compareTo(strToday) >= 0) {
				// 정산일이 오늘보다 미래인 경우
				printLog("A", "정산일이 미래이거나 오늘입니다. strSettlementDate : " + strSettlementDate);
				idSettlement = true;
			} else {
				// 정산일이 오늘이거나 과거인 경우
				printLog("A", "정산일이 과거입니다. strSettlementDate : " + strSettlementDate);
				idSettlement = false;
				
			}
			if (isReservationFuture && strIsRefund != null && strIsRefund.contentEquals("1") && isCancelMembershipUserList && idSettlement) {

				// 결제를 한 예약건인 경우에는 결제 취소까지 진행			
				String strQueryReceiptID = "";
				strQueryReceiptID += " SELECT RECEIPT_ID, TOTAL_PRICE ";
				strQueryReceiptID += " FROM PARTNER_PAYMENT ";
				strQueryReceiptID += " WHERE MENU_ID = '49' ";
				strQueryReceiptID += " AND RESERVATION_ID = '" + strCancelMembershipUserListId + "' ";
				// 결제 완료된건만 가져오기
				strQueryReceiptID += " AND STATE = '1' ";
				
				printLog("A", "update_payment_cancel_partner strQueryReceiptID " + strQueryReceiptID);
				pstmt = conn.prepareStatement(strQueryReceiptID);
				rs = pstmt.executeQuery();

				String strReceiptID = "";
				String strCancelPrice = "";
				String strReturnCode = "";			

				if(rs.next()) {
					strReceiptID = rs.getString(1);
					if(strReceiptID == null) {
						strReceiptID = "";
						
					}

					
					strCancelPrice = rs.getString(2);
					if(strCancelPrice == null) {
						strCancelPrice = "0";
						
					}
					
				}

				if(strReceiptID != null && !strReceiptID.contentEquals("")){
					printLog("A", "update_partner_payment_cancel 결제 취소 요청 영수증 ID - " + strReceiptID);
					printLog("A", "update_partner_payment_cancel 결제 취소 시작 - " + strReceiptID);

					/** 자바 1.7 ssl 프로토콜 인증 오류로 임시로 개발서버에서 부트페이 호출함 */
					String strPayUrl = ASSIST_SERVER + "bootpay_recepit_cancel.jsp";
					//String strPayUrl = "http://35.212.211.73:8000/bootpay_receipt_cancel";
					
					JSONObject jsonObject = new JSONObject();
					jsonObject.put("ReceiptID", strReceiptID);
					jsonObject.put("CancelPrice", strCancelPrice);
					
					CloseableHttpClient httpclient = HttpClientBuilder.create().build();
					HttpPost httppost = new HttpPost(strPayUrl);
					httppost.addHeader("Content-Type", "application/json;charset=UTF-8");
					printLog("A", "update_payment_cancel_partner bootpay_recepit_cancel Param : " + jsonObject.toJSONString());
					StringEntity params = new StringEntity(jsonObject.toJSONString(), "UTF-8");
					httppost.setEntity(params);

					ResponseHandler<String> responseHandler = new BasicResponseHandler();
					String strCancelPayment = httpclient.execute(httppost, responseHandler);
					printLog("A", "update_payment_cancel_partner bootpay_recepit_cancel response : " + strCancelPayment);
					ObjectMapper mapper = new ObjectMapper();
					HashMap resCancelPayment = new HashMap();
					resCancelPayment = mapper.readValue(strCancelPayment, HashMap.class);
					
					JSONObject jsonObj =  new JSONObject(resCancelPayment);
					printLog("A", "update_payment_cancel_partner receiptCancel() : " + jsonObj);
				
						// 결제 취소 성공
					if(resCancelPayment.get("error_code") == null) {
						String strCancelReceiptID = (String) jsonObj.get("receipt_id");		// 취소된 영수증ID
						String strCancelOrderID = (String) jsonObj.get("order_id");				// 취소된 주문 ID
						printLog("A", "update_partner_payment_cancel receiptCancel() 성공. 취소된 영수증ID : " + strCancelReceiptID + ", 주문 ID : " + strCancelOrderID);
						String strPrice = getJsonNumberToString(jsonObj, "price");				// 결제.승인 금액
						String strCanceledPrice = getJsonNumberToString(jsonObj, "cancelled_price");				// 취소 금액
						String strPAY_CANCEL_AT = (String) jsonObj.get("cancelled_at");				// 결제취소시간
						strPAY_CANCEL_AT = convDateFormat(strPAY_CANCEL_AT);
						String strReceiptUrl = (String) jsonObj.get("receipt_url");					// 취소된 주문 영수증
						String strStatus = getJsonNumberToString(jsonObj, "status");	// 결제 취소 상태. 
						
						// 결제 취소 - 부분취소시 1(승인)이 성공. 전체취소시 20(취소)이 성공.
						if(strStatus.contentEquals(PAY_PURCHASE) || strStatus.contentEquals(PAY_CANCEL)) {
							printLog("A", "update_partner_payment_cancel 결제 취소 성공. 결제금액 - " + strPrice + ", 취소금액 - " + strCanceledPrice);
							
							// 결제디비 업데이트. 
							String strQueryPaymentUpdate = "";
							strQueryPaymentUpdate += " UPDATE PAYMENT_PAY SET ";
							strQueryPaymentUpdate += " STATUS = '" + strStatus + "', ";
							strQueryPaymentUpdate += " CANCEL_REASON = '', ";			// 일단 없음
							strQueryPaymentUpdate += " CANCEL_PRICE = '" + strCancelPrice + "', ";
							strQueryPaymentUpdate += " PAYMENT_PRICE = '" + strPrice + "', ";
							strQueryPaymentUpdate += " PAY_CANCEL_AT = '" + strPAY_CANCEL_AT + "', ";
							strQueryPaymentUpdate += " PAY_RECEIPT_URL = '" + strReceiptUrl + "' ";
							strQueryPaymentUpdate += " WHERE PAY_RECEIPT_ID = '" + strReceiptID + "' ";
							printLog("A", "update_partner_payment_cancel strQueryPaymentUpdate : " + strQueryPaymentUpdate);
							pstmt = conn.prepareStatement(strQueryPaymentUpdate);
							int nPaymentRet = pstmt.executeUpdate();
							printLog("A", "update_partner_payment_cancel 결제 DB 업데이트 결과 : " + Integer.toString(nRet));
														
							//취소 
							String strPartnerPaymentQueryUpdate = "";
							strPartnerPaymentQueryUpdate += " UPDATE PARTNER_PAYMENT ";
							strPartnerPaymentQueryUpdate += " SET  CANCEL_PRICE = '" + strCancelPrice + "', ";
							strPartnerPaymentQueryUpdate += "  TOTAL_PRICE = (TOTAL_PRICE - " + Integer.parseInt(strCancelPrice) + "), ";
							strPartnerPaymentQueryUpdate += " STATE = '2', ";					
							strPartnerPaymentQueryUpdate += " CANCEL_DATE = '" +strPAY_CANCEL_AT  + "', ";
							strPartnerPaymentQueryUpdate += " RECEIPT_URL = '" +strReceiptUrl + "' ";
							strPartnerPaymentQueryUpdate += " WHERE RECEIPT_ID = '" + strReceiptID + "' ";

							pstmt = conn.prepareStatement(strPartnerPaymentQueryUpdate);
							nPaymentRet = pstmt.executeUpdate();
							printLog("A", "update_partner_payment_cancel strPartnerPaymentQueryUpdate : " + strPartnerPaymentQueryUpdate);
												
							if(nPaymentRet < 1) {
								strReturnCode = "0";	// 0 : DB 실패, 1 : 성공, 2 : 결제취소실패
								writeLogFile("커뮤니티센터 결제 DB update 실패 : 영수증 아이디 - " + strReceiptID + ", 취소상태 - " + strStatus);
							} else {
								strReturnCode = "1";	// 0 : DB 실패, 1 : 성공, 2 : 결제취소실패							
							}
						}else{
							strReturnCode = "2";
						}
					}
					
				}
			}

		}
		
		
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);
		
	} else if(strSID.contentEquals("get_reservation_list")) { //내 예약 내역 가져오기

		String strAptCode = getRequestParam(request, "AptCode");
		String strUserId = getRequestParam(request, "UserId");		
		String strItemCount = getRequestParam(request, "ItemCount");
		String strLimitCnt = getRequestParam(request, "LimitCnt");
		String strDong = getRequestParam(request, "UserDong");
		String strHo = getRequestParam(request, "UserHo");
		String strUserName = getRequestParam(request, "UserName");
		
		// 예약 내역 조회 시 해당 유저에 동,호, 아파트코드, 성명을 기준으로 
		// 예약 테이블에 유저 아이디가 없는 경우 UPDATE해서 유저 아이디를 넣어주는 쿼리 동작
		// if(strType.contentEquals(RESERVATION_HISTORY)){

		if(strDong != null && strHo != null && strUserName != null && strUserId != null && strAptCode != null){
			String strMembershipUserMappingQuery = "";
			strMembershipUserMappingQuery += " UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET ";
			strMembershipUserMappingQuery += " USER_ID = '" + strUserId + "' ";
			strMembershipUserMappingQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strMembershipUserMappingQuery += " AND USER_DONG = '" + strDong + "' ";
			strMembershipUserMappingQuery += " AND USER_HO = '" + strHo + "' ";
			strMembershipUserMappingQuery += " AND USER_NAME = '" + strUserName + "' ";
			strMembershipUserMappingQuery += " AND (USER_ID = '' OR USER_ID IS NULL ) ";

			pstmt = conn.prepareStatement(strMembershipUserMappingQuery);
			pstmt.executeUpdate();

			String strUserMappingQuery = "";
			strUserMappingQuery += " UPDATE APT_COMMUNITY_RESERVE SET ";
			strUserMappingQuery += " USER_ID = '" + strUserId + "' ";
			strUserMappingQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strUserMappingQuery += " AND USER_DONG = '" + strDong + "' ";
			strUserMappingQuery += " AND USER_HO = '" + strHo + "' ";
			strUserMappingQuery += " AND USER_NAME = '" + strUserName + "' ";
			strUserMappingQuery += " AND (USER_ID = '' OR USER_ID IS NULL ) ";

			pstmt = conn.prepareStatement(strUserMappingQuery);
			pstmt.executeUpdate();

			printLog("D", "strUserMappingQuery : " + strUserMappingQuery);
		}
		
		// 기존의 레코드 카운트 갯수를 먼저 내려주던걸 없애고 그냥 데이터만 전달
		// 새로운 통신방법은 데이터 개수가 없을때 처리가 기존과 다른 방법이라 
		// 레코드 카운터 사용 안 함

		// 데이터 내릴 준비
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		
		// 리턴 데이터 
		// 예약 번호, 시설명, 칩 타이틀(D-n일), 예약 자리 ,날짜, 시간, 이미지

		String strQuery = "";
		strQuery += " SELECT IF((TIME IS NOT NULL AND TIME != ''),'4','2') as SERVICE_TYPE, cr.RESERVE_ID, ac.TITLE, ";
		strQuery += " (";
		strQuery += " CASE ";
		strQuery += " WHEN (TIME IS NOT NULL AND TIME != '') ";
		strQuery += " THEN IF(";
		strQuery += "   CASE WHEN ac.SECURITY = '2' THEN ";
		strQuery += "     DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(cr.DATE, SUBSTRING(cr.TIME, 5, 4)), '%Y%m%d%H%i'), INTERVAL 15 MINUTE), '%Y%m%d%H%i') ";
		strQuery += "   ELSE CONCAT(cr.DATE, SUBSTRING(cr.TIME, 5, 4)) END ";
		strQuery += "   < DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i'), '-1', TIMESTAMPDIFF(DAY, DATE_FORMAT(SYSDATE(), '%Y%m%d'), cr.DATE)) ";
		strQuery += " WHEN (TIME IS NULL OR TIME = '') ";
		strQuery += " THEN TIMESTAMPDIFF(DAY, DATE_FORMAT(SYSDATE(), '%Y%m%d'), cr.EXPIRATION_DATE) ";
		strQuery += " END";
		strQuery += " ) as DIFF_DATE, ";

		strQuery += " ( ";
		strQuery += " CASE ";
		strQuery += " WHEN (TIME IS NOT NULL AND TIME != '') ";
		strQuery += " THEN cr.DATE ";

		strQuery += " WHEN (TIME IS NULL OR TIME = '') ";
		strQuery += "  AND cr.DATE IS NOT NULL ";
		strQuery += "  AND cr.DATE != '' ";
		strQuery += "  AND cr.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "  AND cr.EXPIRATION_DATE != '' ";
		strQuery += " THEN CONCAT(LEFT(cr.DATE, 8), LEFT(cr.EXPIRATION_DATE, 8)) ";

		strQuery += " ELSE '' ";
		strQuery += " END ) as RESERVE_DATE, ";

		strQuery += " cr.TIME, ac.IMAGE, ";
		strQuery += "( ";
		strQuery += " CASE ";
		strQuery += " WHEN (cr.PLACE  IS NOT NULL AND cr.PLACE  != '') ";
		strQuery += " THEN CONCAT('예약 자리 : ',IF(cr.PLACE = 'PLACE_ALL', '대관', cr.PLACE)) ";	
		strQuery += " WHEN (cr.PLACE  IS NULL OR cr.PLACE  = '') ";
		strQuery += " THEN (SELECT NAME FROM APT_COMMUNITY_MEMBERSHIP_INFO WHERE MEMBERSHIP_ID = cr.MEMBERSHIP_ID ) ";		
		strQuery += " END ) as PLACE,  ";	

		strQuery += " IF(RESERVE_CANCEL_TIME IS NULL, '0', '1') , ";
		strQuery += " ac.COMMUNITY_TYPE, ac.START_TIME, ac.END_TIME, ac.OPERATION_HOURS, cr.GENDER, ";
		strQuery += " cr.RESERVE_USER_NAME AS RESERVE_USER_NAME, ";
		strQuery += " cr.RESERVE_CANCEL_TIME AS RESERVE_CANCEL_TIME, ";
		strQuery += " ac.COMMUNITY_STATE AS COMMUNITY_STATE ";

		strQuery += " FROM APT_COMMUNITY_RESERVE as cr" ;
		strQuery += " LEFT JOIN APT_COMMUNITY ac ON ac.COMMUNITY_TYPE = cr.COMMUNITY_TYPE ";
		strQuery += " AND ac.APT_CODE = cr.APT_CODE ";
		strQuery += " AND (ac.GENDER = 0 OR ac.GENDER = cr.GENDER) ";
		strQuery += " WHERE (cr.USER_ID = '" + strUserId + "' OR (cr.USER_DONG = '" + strDong + "' AND cr.USER_HO = '" + strHo + "' AND cr.RESERVE_USER_NAME = '" + strUserName + "' )) ";
		strQuery += " AND cr.APT_CODE = '" + strAptCode + "' ";

		// strQuery += " ORDER BY ";
		// strQuery += " CASE ";
		// strQuery += "     WHEN (TIME IS NOT NULL AND TIME != '' AND CONCAT(DATE, LEFT(TIME, 4)) >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') AND RESERVE_CANCEL_TIME IS NULL) THEN 0 ";
		// strQuery += "     WHEN ((TIME IS NULL OR TIME = '') AND LEFT(cr.EXPIRATION_DATE, 12) >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') AND RESERVE_CANCEL_TIME IS NULL) THEN 0 ";
		// strQuery += "     ELSE 1 ";
		// strQuery += " END ASC, ";

		// strQuery += " CASE ";
		// strQuery += "     WHEN (TIME IS NOT NULL AND TIME != '' AND CONCAT(DATE, LEFT(TIME, 4)) >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') AND RESERVE_CANCEL_TIME IS NULL) ";
		// strQuery += "     THEN CONCAT(DATE, LEFT(TIME, 4)) ";
		// strQuery += "     WHEN ((TIME IS NULL OR TIME = '') AND LEFT(cr.EXPIRATION_DATE, 12) >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i')) ";
		// strQuery += "     THEN LEFT(cr.EXPIRATION_DATE, 12) ";
		// strQuery += " END ASC, ";

		// strQuery += " CASE ";
		// strQuery += "     WHEN (TIME IS NOT NULL AND TIME != '') ";
		// strQuery += "     THEN CONCAT(DATE, LEFT(TIME, 4)) ";
		// strQuery += "     ELSE LEFT(cr.EXPIRATION_DATE, 12) ";
		// strQuery += " END DESC ";

		// strQuery += " ORDER BY ";

		// // =====================================================
		// // 1. 이용 가능한 예약/회원권을 먼저 표시
		// // 시간 예약 : 예약 종료 시간이 지나지 않은 경우
		// // 기간 회원권 : 만료일이 지나지 않은 경우
		// // =====================================================
		// strQuery += " CASE ";
		// strQuery += "     WHEN ( ";
		// strQuery += "         cr.TIME IS NOT NULL ";
		// strQuery += "         AND cr.TIME != '' ";
		// strQuery += "         AND CONCAT(cr.DATE, SUBSTRING(cr.TIME, 5, 4)) ";
		// strQuery += "             >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') ";
		// strQuery += "         AND cr.RESERVE_CANCEL_TIME IS NULL ";
		// strQuery += "     ) THEN 0 ";

		// strQuery += "     WHEN ( ";
		// strQuery += "         (cr.TIME IS NULL OR cr.TIME = '') ";
		// strQuery += "         AND LEFT(cr.EXPIRATION_DATE, 12) ";
		// strQuery += "             >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') ";
		// strQuery += "         AND cr.RESERVE_CANCEL_TIME IS NULL ";
		// strQuery += "     ) THEN 0 ";

		// strQuery += "     ELSE 1 ";
		// strQuery += " END ASC, ";

		// // =====================================================
		// // 2. 이용 가능한 데이터는 시작 날짜가 가까운 순서
		// // 시간 예약 : 예약 날짜 + 시작 시간
		// // 기간 회원권 : 회원권 시작 날짜
		// // 같은 날짜면 시간 예약을 기간권보다 먼저 표시
		// // =====================================================
		// strQuery += " CASE ";
		// strQuery += "     WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		// strQuery += "         AND cr.TIME IS NOT NULL ";
		// strQuery += "         AND cr.TIME != '' ";
		// strQuery += "         AND CONCAT(cr.DATE, SUBSTRING(cr.TIME, 5, 4)) ";
		// strQuery += "             >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') ";
		// strQuery += "     THEN CONCAT(cr.DATE, LEFT(cr.TIME, 4)) ";

		// strQuery += "     WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		// strQuery += "         AND (cr.TIME IS NULL OR cr.TIME = '') ";
		// strQuery += "         AND LEFT(cr.EXPIRATION_DATE, 12) ";
		// strQuery += "             >= DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i') ";
		// strQuery += "     THEN CONCAT(LEFT(cr.DATE, 8), '9999') ";

		// strQuery += " END ASC, ";

		// // =====================================================
		// // 3. 만료되거나 취소된 데이터는 최근 데이터부터 표시
		// // =====================================================
		// strQuery += " CASE ";
		// strQuery += "     WHEN cr.TIME IS NOT NULL AND cr.TIME != '' ";
		// strQuery += "     THEN CONCAT(cr.DATE, LEFT(cr.TIME, 4)) ";
		// strQuery += "     ELSE CONCAT(LEFT(cr.DATE, 8), '0000') ";
		// strQuery += " END DESC ";

		strQuery += " ORDER BY ";

		// =====================================================
		// 1. 이용 가능한 건 먼저, 이용완료/취소 건은 맨 아래
		//
		// 시간 예약:
		// 예약 종료시간이 현재보다 이후이고 취소되지 않은 경우 이용 가능
		//
		// 기간형 회원권:
		// 만료일이 오늘 이후이고 취소되지 않은 경우 이용 가능
		// =====================================================
		strQuery += " CASE ";

		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND cr.TIME IS NOT NULL ";
		strQuery += "    AND cr.TIME != '' ";
		strQuery += "    AND LENGTH(cr.TIME) = 8 ";
		strQuery += "    AND STR_TO_DATE( ";
		strQuery += "          CONCAT(LEFT(cr.DATE, 8), SUBSTRING(cr.TIME, 5, 4)), ";
		strQuery += "          '%Y%m%d%H%i' ";
		strQuery += "        ) >= SYSDATE() ";
		strQuery += "   THEN 0 ";

		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND (cr.TIME IS NULL OR cr.TIME = '') ";
		strQuery += "    AND cr.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.EXPIRATION_DATE != '' ";
		strQuery += "    AND STR_TO_DATE( ";
		strQuery += "          LEFT(cr.EXPIRATION_DATE, 8), ";
		strQuery += "          '%Y%m%d' ";
		strQuery += "        ) >= CURDATE() ";
		strQuery += "   THEN 0 ";

		strQuery += "   ELSE 1 ";
		strQuery += " END ASC, ";


		// =====================================================
		// 2. 이용 가능한 데이터 중 일일권 먼저
		//
		// 일일권:
		// 시작일 있음 + 종료일 없음
		//
		// 기간형 회원권:
		// 시작일과 종료일 모두 있음
		// =====================================================
		strQuery += " CASE ";
		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND cr.DATE IS NOT NULL ";
		strQuery += "    AND cr.DATE != '' ";
		strQuery += "    AND ( ";
		strQuery += "         cr.EXPIRATION_DATE IS NULL ";
		strQuery += "         OR cr.EXPIRATION_DATE = '' ";
		strQuery += "    ) ";
		strQuery += "   THEN 0 ";
		strQuery += "   ELSE 1 ";
		strQuery += " END ASC, ";


		// =====================================================
		// 3. 이용 가능한 일일권은 오늘과 가까운 순
		// =====================================================
		strQuery += " CASE ";
		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND cr.DATE IS NOT NULL ";
		strQuery += "    AND cr.DATE != '' ";
		strQuery += "    AND ( ";
		strQuery += "         cr.EXPIRATION_DATE IS NULL ";
		strQuery += "         OR cr.EXPIRATION_DATE = '' ";
		strQuery += "    ) ";
		strQuery += "    AND cr.TIME IS NOT NULL ";
		strQuery += "    AND cr.TIME != '' ";
		strQuery += "    AND STR_TO_DATE( ";
		strQuery += "          CONCAT(LEFT(cr.DATE, 8), SUBSTRING(cr.TIME, 5, 4)), ";
		strQuery += "          '%Y%m%d%H%i' ";
		strQuery += "        ) >= SYSDATE() ";
		strQuery += "   THEN ABS( ";
		strQuery += "     DATEDIFF( ";
		strQuery += "       STR_TO_DATE(LEFT(cr.DATE, 8), '%Y%m%d'), ";
		strQuery += "       CURDATE() ";
		strQuery += "     ) ";
		strQuery += "   ) ";
		strQuery += "   ELSE NULL ";
		strQuery += " END ASC, ";


		// =====================================================
		// 4. 같은 날짜의 일일권은 시작시간 빠른 순
		// =====================================================
		strQuery += " CASE ";
		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND cr.TIME IS NOT NULL ";
		strQuery += "    AND cr.TIME != '' ";
		strQuery += "    AND LENGTH(cr.TIME) = 8 ";
		strQuery += "    AND STR_TO_DATE( ";
		strQuery += "          CONCAT(LEFT(cr.DATE, 8), SUBSTRING(cr.TIME, 5, 4)), ";
		strQuery += "          '%Y%m%d%H%i' ";
		strQuery += "        ) >= SYSDATE() ";
		strQuery += "   THEN STR_TO_DATE( ";
		strQuery += "     CONCAT(LEFT(cr.DATE, 8), LEFT(cr.TIME, 4)), ";
		strQuery += "     '%Y%m%d%H%i' ";
		strQuery += "   ) ";
		strQuery += "   ELSE NULL ";
		strQuery += " END ASC, ";


		// =====================================================
		// 5. 이용 가능한 기간형 회원권은 만료일 가까운 순
		// =====================================================
		strQuery += " CASE ";
		strQuery += "   WHEN cr.RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "    AND (cr.TIME IS NULL OR cr.TIME = '') ";
		strQuery += "    AND cr.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.EXPIRATION_DATE != '' ";
		strQuery += "    AND STR_TO_DATE( ";
		strQuery += "          LEFT(cr.EXPIRATION_DATE, 8), ";
		strQuery += "          '%Y%m%d' ";
		strQuery += "        ) >= CURDATE() ";
		strQuery += "   THEN STR_TO_DATE( ";
		strQuery += "     LEFT(cr.EXPIRATION_DATE, 8), ";
		strQuery += "     '%Y%m%d' ";
		strQuery += "   ) ";
		strQuery += "   ELSE NULL ";
		strQuery += " END ASC, ";


		// =====================================================
		// 6. 맨 아래의 이용완료/취소 데이터는 최근 건부터
		// =====================================================
		strQuery += " CASE ";
		strQuery += "   WHEN cr.TIME IS NOT NULL ";
		strQuery += "    AND cr.TIME != '' ";
		strQuery += "    AND LENGTH(cr.TIME) = 8 ";
		strQuery += "   THEN STR_TO_DATE( ";
		strQuery += "     CONCAT(LEFT(cr.DATE, 8), SUBSTRING(cr.TIME, 5, 4)), ";
		strQuery += "     '%Y%m%d%H%i' ";
		strQuery += "   ) ";

		strQuery += "   WHEN cr.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.EXPIRATION_DATE != '' ";
		strQuery += "   THEN STR_TO_DATE( ";
		strQuery += "     LEFT(cr.EXPIRATION_DATE, 8), ";
		strQuery += "     '%Y%m%d' ";
		strQuery += "   ) ";

		strQuery += "   ELSE STR_TO_DATE(LEFT(cr.DATE, 8), '%Y%m%d') ";
		strQuery += " END DESC, ";


		// 마지막 보조 정렬
		strQuery += " cr.RESERVE_ID DESC ";

		if(strItemCount != null && !strItemCount.contentEquals("") && !strItemCount.contentEquals("0")){
			int nItemCount = Integer.parseInt(strItemCount);
			strQuery += " LIMIT " + nItemCount + ", 10";
		}else{
			strQuery += " LIMIT 10";
		}

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();

		rsMetaData = rs.getMetaData();

		String strServiceType = "";
		String strReserveId = "";
		String strCommunityType = "";
		String strSecurity = "";
		String strQRId ="";
		String strQRSecurityCode = "";
		String strStartTime = "";
		String strEndTime = "";
		String strOperationHours = "";
		String strReservationTime = "";
		String strActualStartTime = "";
		String strActualEndTime = "";
		String strState = "";
		String strGender = "";
		boolean bSkip = false;
		String strReserveUserName = "";
		String strReserveCancelTime = "";
		String strDiffDate = "";
		String strCommunityState = "";

		for(int nRow = 0; rs.next(); nRow++) {
			bSkip = false;

			strReserveId = rs.getString("RESERVE_ID");

				printLog("A", "strReserveId : " + strReserveId);


			// MEMBERSHIP_USER_LIST_ID 조회
			String strMembershipUserListId = "";
			String strSubQuery1 = "SELECT MEMBERSHIP_USER_LIST_ID FROM APT_COMMUNITY_RESERVE WHERE RESERVE_ID = ?";
			PreparedStatement pstmtSub1 = null;
			ResultSet rsSub1 = null;
			try {
				pstmtSub1 = conn.prepareStatement(strSubQuery1);
				pstmtSub1.setString(1, strReserveId);
				rsSub1 = pstmtSub1.executeQuery();
				if (rsSub1.next()) {
					strMembershipUserListId = rsSub1.getString("MEMBERSHIP_USER_LIST_ID") != null 
											? rsSub1.getString("MEMBERSHIP_USER_LIST_ID") : "";
				}
			} finally {
				if (rsSub1 != null) try { rsSub1.close(); } catch (Exception e) {}
				if (pstmtSub1 != null) try { pstmtSub1.close(); } catch (Exception e) {}
			}

			// PARTNER_PAYMENT STATE 확인
			if (!strMembershipUserListId.isEmpty()) {
				String strSubQuery2 = "SELECT STATE FROM PARTNER_PAYMENT WHERE MENU_ID = 49 AND RESERVATION_ID = " + strMembershipUserListId + " ";
				PreparedStatement pstmtSub2 = null;
				ResultSet rsSub2 = null;
				bSkip = false;
				printLog("A", "strSubQuery2 : " + strSubQuery2);

				try {
					pstmtSub2 = conn.prepareStatement(strSubQuery2);
					rsSub2 = pstmtSub2.executeQuery();
					

					if (rsSub2.next()) {
					printLog("A", "rsSub2.getString(1) : " + rsSub2.getString(1));
						
						if(rsSub2.getString(1) != null && rsSub2.getString(1).contentEquals("0")){
							
							bSkip = true; // STATE = 0 이면 스킵
						}					
					}
				} finally {
					if (rsSub2 != null) try { rsSub2.close(); } catch (Exception e) {}
					if (pstmtSub2 != null) try { pstmtSub2.close(); } catch (Exception e) {}
				}

				if(bSkip){
					continue;
				}

				printLog("A", "bSkip : " + bSkip);

		
			}
			
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);	

				// DIFF_DATE 저장
				// -1이면 이미 지난 예약이므로 QR ID / QR SECURITY CODE를 빈값으로 내려주기 위해 사용
				if(nCol == 4){
					strDiffDate = (strData != null) ? strData : "";
				}

				if(nCol == 1){
					strServiceType = rs.getString(nCol);
				}else if(nCol == 10){
					strCommunityType = (strData != null) ? strData : "";
				}else if(nCol == 11){
					strStartTime = (strData != null) ? strData : "";
				}else if(nCol == 12){
					strEndTime = (strData != null) ? strData : "";
				}else if(nCol == 13){
					strOperationHours = (strData != null) ? strData : "";
				}else if(nCol == 14){
					strGender = (strData != null) ? strData : "";
				} else if(nCol == 15){
					strReserveUserName = (strData != null) ? strData : "";
				} else if(nCol == 16){
					strReserveCancelTime = (strData != null) ? strData : "";
				} else if(nCol == 17){
					strCommunityState = (strData != null) ? strData : "";
				}else{

					if(nCol == 2){
						strReserveId = rs.getString(2);
					}
					
					if(nCol == 6){
						strReservationTime = (strData != null) ? strData : "";
					}
					
					if(strServiceType.contentEquals(IMMEDIATE_RESERVE) || strServiceType.contentEquals(TICKET_PURCHASE_AND_RESERVE)){
						// 단건 예약을 사용하는 경우
						if(strData == null) strData = "";
						if(nCol == 5){
							strData = formatDate(strData);
						}else if(nCol == 6){					
							strData = formatTime(strData);
						}
					}else if(strServiceType.contentEquals(TICKET_PURCHASE_WITH_TIME)){
						// 이용권인 경우
						if(strData == null) strData = "";

						if(nCol == 5){
							if(strData.length() >= 16) {

								String strStartDate = strData.substring(0, 8);
								String strEndDate = strData.substring(8, 16);

								// 시작일과 종료일이 같으면 날짜 하나만 표시
								if(strStartDate.contentEquals(strEndDate)) {
									strData = formatDate(strStartDate);
								} else {
									strData = formatDate(strStartDate)
											+ " ~ "
											+ formatDate(strEndDate);
								}

							} else {
								strData = "";
							}
						}
					}
					
					baOutStream.write(strData.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);
					
				}
			}

			// 컬럼 루프 완료 후 strCommunityType(col10), strGender(col14) 세팅된 상태에서 Security/QR 조회
			String strSecurityQuery = "";
			strSecurityQuery += " SELECT SECURITY FROM APT_COMMUNITY WHERE COMMUNITY_TYPE = '" + strCommunityType + "' AND APT_CODE = '" + strAptCode + "' AND ( GENDER = 0 OR GENDER = '" + strGender + "' ) ";
			printLog("A", "strSecurityQuery : " + strSecurityQuery);
			PreparedStatement pstmtSecurity = conn.prepareStatement(strSecurityQuery);
			ResultSet rsSecurity = pstmtSecurity.executeQuery();
			if(rsSecurity.next()){
				strSecurity = rsSecurity.getString(1);
			}
			rsSecurity.close();
			pstmtSecurity.close();

			boolean isSameUserName = true;

			if(strUserName != null && !strUserName.contentEquals("")) {
				isSameUserName = strUserName.contentEquals(strReserveUserName);
			}

			// 취소된 예약이면 QR 내려주지 않음
			boolean isCancelled = strReserveCancelTime != null && !strReserveCancelTime.contentEquals("");

			// DIFF_DATE가 -1이면 이미 이용 시간이 지난 예약이므로 QR 내려주지 않음
			boolean isExpiredByDiffDate = strDiffDate != null && strDiffDate.contentEquals("-1");

			if(strSecurity != null 
				&& strSecurity.contentEquals("2") 
				&& isSameUserName 
				&& !isCancelled
				&& !isExpiredByDiffDate
			){
				String strQRInfoQuery = "";
				strQRInfoQuery += " SELECT ID, SECURITY_CODE FROM APT_COMMUNITY_QR";
				strQRInfoQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
				strQRInfoQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
				strQRInfoQuery += " AND ( GENDER = 0 OR GENDER = '" + strGender + "' ) ";

				PreparedStatement pstmtQRInfo = conn.prepareStatement(strQRInfoQuery);
				ResultSet rsQRInfo = pstmtQRInfo.executeQuery();

				if(rsQRInfo.next()){
					strQRId = rsQRInfo.getString(1) != null ? rsQRInfo.getString(1) : "";
					strQRSecurityCode = rsQRInfo.getString(2) != null ? rsQRInfo.getString(2) : "";
				}

				rsQRInfo.close();
				pstmtQRInfo.close();
			} else {
				strQRId = "";
				strQRSecurityCode = "";
			}

			// get_reservation_info와 동일한 로직으로 실제 입장/퇴장 시간 및 state 계산
			// boolean bHasReservationTime = !strReservationTime.contentEquals("");
			// String strTimeForCalc = strReservationTime;
			// if(!bHasReservationTime){
			// 	strTimeForCalc = "00002400";
			// }

			// if(!strOperationHours.contentEquals("")) {
			// 	SimpleDateFormat sdfOperationHoursL = new SimpleDateFormat("yyyyMMdd");
			// 	String currentDateTimeOHL = sdfOperationHoursL.format(new Date());
			// 	Date dateOperationHoursL = sdfOperationHoursL.parse(currentDateTimeOHL);
			// 	Calendar calendarOperationHoursL = Calendar.getInstance();
			// 	calendarOperationHoursL.setTime(dateOperationHoursL);
			// 	int dayOfWeekOHL = calendarOperationHoursL.get(Calendar.DAY_OF_WEEK);
			// 	String strStartTimeJson = "";
			// 	String strEndTimeJson = "";
			// 	if (dayOfWeekOHL == Calendar.SATURDAY || dayOfWeekOHL == Calendar.SUNDAY) {
			// 		strStartTimeJson = extractValue(strOperationHours, "WEEKEND", "start");
			// 		strEndTimeJson = extractValue(strOperationHours, "WEEKEND", "end");
			// 	} else {
			// 		strStartTimeJson = extractValue(strOperationHours, "WEEKDAY", "start");
			// 		strEndTimeJson = extractValue(strOperationHours, "WEEKDAY", "end");
			// 	}
			// 	if(strTimeForCalc.contentEquals("00002400")) {
			// 		strTimeForCalc = strStartTimeJson + strEndTimeJson;
			// 	}
			// } else {
			// 	if(strTimeForCalc.contentEquals("00002400")) {
			// 		strTimeForCalc = strStartTime + strEndTime;
			// 	}
			// }

			List<Holiday> holidaysListL = new ArrayList<Holiday>();
			PreparedStatement pstmtHolidaysL = conn.prepareStatement(getHolidaysQuery(strAptCode, strCommunityType));
			// ResultSet rsHolidaysL = pstmtHolidaysL.executeQuery();
			// while(rsHolidaysL.next()) {
			// 	String strRepeatTypeL = rsHolidaysL.getString(1);
			// 	String strHoliDaysDayOfWeekL = rsHolidaysL.getString(2);
			// 	String strHolidaysDayOfMonthL = rsHolidaysL.getString(3);
			// 	String strSpecificTypeL = rsHolidaysL.getString(4);
			// 	String strSpecialDayL = rsHolidaysL.getString(5);
			// 	int nSpecificRepeatTypeL = -1;
			// 	int nHoliDaysDayOfWeekL = -1;
			// 	int nHolidaysDayOfMonthL = -1;
			// 	int nSpecificTypeL = -1;
			// 	if(strRepeatTypeL != null && !strRepeatTypeL.contentEquals("")) nSpecificRepeatTypeL = Integer.parseInt(strRepeatTypeL);
			// 	if(strHoliDaysDayOfWeekL != null && !strHoliDaysDayOfWeekL.contentEquals("")) nHoliDaysDayOfWeekL = Integer.parseInt(strHoliDaysDayOfWeekL);
			// 	if(strHolidaysDayOfMonthL != null && !strHolidaysDayOfMonthL.contentEquals("")) nHolidaysDayOfMonthL = Integer.parseInt(strHolidaysDayOfMonthL);
			// 	if(strSpecificTypeL != null && !strSpecificTypeL.contentEquals("")) nSpecificTypeL = Integer.parseInt(strSpecificTypeL);
			// 	if(strSpecialDayL == null) strSpecialDayL = "";
			// 	holidaysListL.add(new Holiday(nSpecificRepeatTypeL, nHoliDaysDayOfWeekL, nHolidaysDayOfMonthL, nSpecificTypeL, strSpecialDayL));
			// }
			// rsHolidaysL.close();
			// pstmtHolidaysL.close();

			// Calendar todayL = Calendar.getInstance();
			// int todayDayOfWeekL = todayL.get(Calendar.DAY_OF_WEEK) - 1;
			// int todayDayOfMonthL = todayL.get(Calendar.DAY_OF_MONTH);
			// int weekOfMonthL = todayL.get(Calendar.WEEK_OF_MONTH);
			// SimpleDateFormat dateFormatHHmmL = new SimpleDateFormat("HHmm");
			// int nNowTimeL = Integer.parseInt(dateFormatHHmmL.format(todayL.getTime()));

			// boolean isHolidayL = false;
			// boolean isTempHolidayL = false;
			// SimpleDateFormat dateFormatYYYYMMDDL = new SimpleDateFormat("yyyyMMdd");
			// String formattedDateYYYYMMDDL = dateFormatYYYYMMDDL.format(todayL.getTime());

			// for (Holiday holiday : holidaysListL) {
			// 	if (isTodayHoliday(holiday, todayDayOfWeekL, todayDayOfMonthL, weekOfMonthL)) {
			// 		isHolidayL = true;
			// 	} else {
			// 		if(isTodayTempHoliday(holiday, formattedDateYYYYMMDDL)) {
			// 			isTempHolidayL = true;
			// 			isHolidayL = true;
			// 		}
			// 	}
			// }

			// boolean bValidTimeL = (strTimeForCalc != null && strTimeForCalc.length() == 8);
			// int nStartTimeL = 0;
			// int nEndTimeL = 0;
			// SimpleDateFormat sdfHHmmL = new SimpleDateFormat("HHmm");
			// Calendar calStartL = null;
			// Calendar calEndL = null;

			// if(bValidTimeL && bHasReservationTime) {
			// 	calStartL = Calendar.getInstance();
			// 	calStartL.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTimeForCalc.substring(0,2)));
			// 	calStartL.set(Calendar.MINUTE, Integer.parseInt(strTimeForCalc.substring(2,4)));
			// 	calStartL.add(Calendar.MINUTE, -15);
			// 	calEndL = Calendar.getInstance();
			// 	calEndL.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTimeForCalc.substring(4,6)));
			// 	calEndL.set(Calendar.MINUTE, Integer.parseInt(strTimeForCalc.substring(6,8)));
			// 	calEndL.add(Calendar.MINUTE, 15);
			// 	nStartTimeL = Integer.parseInt(sdfHHmmL.format(calStartL.getTime()));
			// 	nEndTimeL = Integer.parseInt(sdfHHmmL.format(calEndL.getTime()));
			// } else if(bValidTimeL) {
			// 	nStartTimeL = Integer.parseInt(strTimeForCalc.substring(0,4));
			// 	nEndTimeL = Integer.parseInt(strTimeForCalc.substring(4,8));
			// }

			// ==========================================================
			// get_community_facility와 동일한 시설 운영 상태 계산
			// 기준:
			// 1. 시설 OPERATION_HOURS
			// 2. OPERATION_HOURS가 없으면 START_TIME / END_TIME
			// 3. 정기휴무 / 임시휴무
			// 4. COMMUNITY_STATE가 UNAVAILABLE이면 예약준비중 상태
			// ==========================================================

			String strFacilityStartTime = "";
			String strFacilityEndTime = "";

			// OPERATION_HOURS가 있으면 오늘이 평일인지 주말인지에 따라 운영시간 추출
			if(strOperationHours != null && !strOperationHours.contentEquals("")) {

				Calendar calendarOperationHoursL = Calendar.getInstance();
				int dayOfWeekOHL = calendarOperationHoursL.get(Calendar.DAY_OF_WEEK);

				if(dayOfWeekOHL == Calendar.SATURDAY
					|| dayOfWeekOHL == Calendar.SUNDAY) {

					strFacilityStartTime =
						extractValue(strOperationHours, "WEEKEND", "start");

					strFacilityEndTime =
						extractValue(strOperationHours, "WEEKEND", "end");

				} else {

					strFacilityStartTime =
						extractValue(strOperationHours, "WEEKDAY", "start");

					strFacilityEndTime =
						extractValue(strOperationHours, "WEEKDAY", "end");
				}

			} else {
				// OPERATION_HOURS가 없으면 시설 기본 운영시간 사용
				strFacilityStartTime =
					strStartTime != null ? strStartTime.replace(":", "") : "";

				strFacilityEndTime =
					strEndTime != null ? strEndTime.replace(":", "") : "";
			}


			// 실제 시설 운영 시작/종료 시간 응답
			// strActualStartTime = strFacilityStartTime;
			// strActualEndTime = strFacilityEndTime;

			// ==========================================================
			// QR 입장 시작/만료시간 계산
			// get_reservation_info와 동일하게
			//
			// 예약시간이 있으면:
			// 시작시간 -15분 / 종료시간 +15분
			//
			// 예약시간이 없으면:
			// 00:00 ~ 24:00
			//
			// 시설 운영상태인 strState 계산과는 별도로 처리
			// ==========================================================

			boolean bHasReservationTime =
				strReservationTime != null
				&& !strReservationTime.contentEquals("")
				&& strReservationTime.length() == 8;

			SimpleDateFormat sdfQRTimeL =
				new SimpleDateFormat("HHmm");

			Calendar calQRStartL = null;
			Calendar calQREndL = null;

			if(bHasReservationTime) {

				calQRStartL = Calendar.getInstance();

				calQRStartL.set(
					Calendar.HOUR_OF_DAY,
					Integer.parseInt(
						strReservationTime.substring(0, 2)
					)
				);

				calQRStartL.set(
					Calendar.MINUTE,
					Integer.parseInt(
						strReservationTime.substring(2, 4)
					)
				);

				calQRStartL.set(Calendar.SECOND, 0);
				calQRStartL.set(Calendar.MILLISECOND, 0);

				// 예약 시작 15분 전부터 입장 가능
				calQRStartL.add(Calendar.MINUTE, -15);


				calQREndL = Calendar.getInstance();

				calQREndL.set(
					Calendar.HOUR_OF_DAY,
					Integer.parseInt(
						strReservationTime.substring(4, 6)
					)
				);

				calQREndL.set(
					Calendar.MINUTE,
					Integer.parseInt(
						strReservationTime.substring(6, 8)
					)
				);

				calQREndL.set(Calendar.SECOND, 0);
				calQREndL.set(Calendar.MILLISECOND, 0);

				// 예약 종료 15분 후까지 입장 가능
				calQREndL.add(Calendar.MINUTE, 15);

				strActualStartTime =
					sdfQRTimeL.format(
						calQRStartL.getTime()
					);

				strActualEndTime =
					sdfQRTimeL.format(
						calQREndL.getTime()
					);

			} else {

				// get_reservation_info와 동일하게
				// 예약시간이 없는 기간권은 하루 전체시간으로 응답
				strActualStartTime = "0000";
				strActualEndTime = "2400";
			}


			// 시설 휴무일 조회
			// List<Holiday> holidaysListL = new ArrayList<Holiday>();

			// PreparedStatement pstmtHolidaysL =
			// 	conn.prepareStatement(
			// 		getHolidaysQuery(strAptCode, strCommunityType)
			// 	);

			ResultSet rsHolidaysL = pstmtHolidaysL.executeQuery();

			while(rsHolidaysL.next()) {

				String strRepeatTypeL = rsHolidaysL.getString(1);
				String strHoliDaysDayOfWeekL = rsHolidaysL.getString(2);
				String strHolidaysDayOfMonthL = rsHolidaysL.getString(3);
				String strSpecificTypeL = rsHolidaysL.getString(4);
				String strSpecialDayL = rsHolidaysL.getString(5);

				int nSpecificRepeatTypeL = -1;
				int nHoliDaysDayOfWeekL = -1;
				int nHolidaysDayOfMonthL = -1;
				int nSpecificTypeL = -1;

				if(strRepeatTypeL != null
					&& !strRepeatTypeL.contentEquals("")) {

					nSpecificRepeatTypeL =
						Integer.parseInt(strRepeatTypeL);
				}

				if(strHoliDaysDayOfWeekL != null
					&& !strHoliDaysDayOfWeekL.contentEquals("")) {

					nHoliDaysDayOfWeekL =
						Integer.parseInt(strHoliDaysDayOfWeekL);
				}

				if(strHolidaysDayOfMonthL != null
					&& !strHolidaysDayOfMonthL.contentEquals("")) {

					nHolidaysDayOfMonthL =
						Integer.parseInt(strHolidaysDayOfMonthL);
				}

				if(strSpecificTypeL != null
					&& !strSpecificTypeL.contentEquals("")) {

					nSpecificTypeL =
						Integer.parseInt(strSpecificTypeL);
				}

				if(strSpecialDayL == null) {
					strSpecialDayL = "";
				}

				holidaysListL.add(
					new Holiday(
						nSpecificRepeatTypeL,
						nHoliDaysDayOfWeekL,
						nHolidaysDayOfMonthL,
						nSpecificTypeL,
						strSpecialDayL
					)
				);
			}

			rsHolidaysL.close();
			pstmtHolidaysL.close();


			// 오늘 날짜/시간
			Calendar todayL = Calendar.getInstance();

			int todayDayOfWeekL =
				todayL.get(Calendar.DAY_OF_WEEK) - 1;

			int todayDayOfMonthL =
				todayL.get(Calendar.DAY_OF_MONTH);

			int weekOfMonthL =
				todayL.get(Calendar.WEEK_OF_MONTH);

			SimpleDateFormat dateFormatHHmmL =
				new SimpleDateFormat("HHmm");

			int nNowTimeL =
				Integer.parseInt(
					dateFormatHHmmL.format(todayL.getTime())
				);

			SimpleDateFormat dateFormatYYYYMMDDL =
				new SimpleDateFormat("yyyyMMdd");

			String formattedDateYYYYMMDDL =
				dateFormatYYYYMMDDL.format(todayL.getTime());


			// 휴무일 확인
			boolean isHolidayL = false;
			boolean isTempHolidayL = false;

			for(Holiday holiday : holidaysListL) {

				if(isTodayHoliday(
					holiday,
					todayDayOfWeekL,
					todayDayOfMonthL,
					weekOfMonthL
				)) {

					isHolidayL = true;

				} else if(isTodayTempHoliday(
					holiday,
					formattedDateYYYYMMDDL
				)) {

					isTempHolidayL = true;
					isHolidayL = true;
				}
			}


			// 운영시간 유효성 확인
			boolean bValidTimeL =
				strFacilityStartTime != null
				&& strFacilityEndTime != null
				&& strFacilityStartTime.length() == 4
				&& strFacilityEndTime.length() == 4;

			int nStartTimeL = 0;
			int nEndTimeL = 0;

			if(bValidTimeL) {
				nStartTimeL =
					Integer.parseInt(strFacilityStartTime);

				nEndTimeL =
					Integer.parseInt(strFacilityEndTime);
			}


			// get_community_facility와 동일한 상태 계산
			if(isHolidayL) {

				// 정기휴무 또는 임시휴무
				strState = "2";

			} else if(!bValidTimeL) {

				// 운영시간이 정상적이지 않은 경우
				strState = "4";

			} else if(
				// 같은 날짜 안에서 운영되는 시설
				(
					nStartTimeL <= nEndTimeL
					&& nStartTimeL < nNowTimeL
					&& nEndTimeL > nNowTimeL
				)
				||
				// 자정을 넘어 운영하는 시설
				(
					nStartTimeL > nEndTimeL
					&& (
						nNowTimeL > nStartTimeL
						|| nNowTimeL < nEndTimeL
					)
				)
			) {

				strState = "1";

			} else {

				strState = "4";

				// 게스트하우스는 운영시간 외에도 운영중으로 처리
				if(strCommunityType.contentEquals(TYPE_GUESTHOUSE)) {
					strState = "1";
				}
			}


			// COMMUNITY_STATE가 이용 불가이면 최종적으로 예약준비중 상태
			if(strCommunityState != null
				&& strCommunityState.contentEquals(UNAVAILABLE)) {

				strState = "4";
			}

			// if(calStartL != null) {
			// 	strActualStartTime = sdfHHmmL.format(calStartL.getTime());
			// 	strActualEndTime = sdfHHmmL.format(calEndL.getTime());
			// } else if(bValidTimeL) {
			// 	strActualStartTime = strTimeForCalc.substring(0,4);
			// 	strActualEndTime = strTimeForCalc.substring(4,8);
			// }

			// if (isHolidayL) {
			// 	strState = "2";
			// } else if (!bValidTimeL) {
			// 	strState = "4";
			// } else if (
			// 	(nStartTimeL <= nEndTimeL && nStartTimeL < nNowTimeL && nEndTimeL > nNowTimeL)
			// 	||
			// 	(nStartTimeL > nEndTimeL && (nNowTimeL > nStartTimeL || nNowTimeL < nEndTimeL))
			// ) {
			// 	strState = "1";
			// } else {
			// 	strState = strCommunityType.contentEquals(TYPE_GUESTHOUSE) ? "1" : "4";
			// }

			baOutStream.write(strQRId.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strQRSecurityCode.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strSecurity.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strActualStartTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strActualEndTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strState.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(RECORD_DEL);
		
			strQRId ="";
			strQRSecurityCode = "";
			strStartTime = "";
			strEndTime = "";
			strOperationHours = "";
			strReservationTime = "";
			strActualStartTime = "";
			strActualEndTime = "";
			strState = "";
			strSecurity ="";
			strReserveUserName = "";
			strReserveCancelTime = "";
			strDiffDate = "";
			strCommunityState = "";
		}
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);
	} else if(strSID.contentEquals("get_reservation_info")) {
		// 내 예약 상세보기
		// 예약 아이디만 있어도 가능 
		String strAptCode = getRequestParam(request, "AptCode");
		String strUserId = getRequestParam(request, "UserId");		
		String strReservationId = getRequestParam(request, "ReservationId");
		String strRequestUserName = getRequestParam(request, "UserName");	

		// 필요한 리턴값
		// 시설명, 시설 이미지, 신청자 성함,(이용자 성함 있으면 없으면 "") 동/호, 시설내역(시설명 + 자리), 날짜, 시간,
		// 취소 가능여부, 취소 버튼 타이틀, 취소 가능 날짜(format : yy.mmdd (E) HH:mm 까지 취소 가능)
		// 만약 취소가 이미 불가능한 상태면 취소 가능 날짜는 빈 스트링	

		String strQuery = "";
		strQuery += "SELECT ";
		strQuery += " ac.IMAGE, ac.TITLE, ";
		strQuery += " cr.USER_NAME, cr.RESERVE_USER_NAME, ";
		strQuery += " CONCAT(cr.USER_DONG, '동 ', cr.USER_HO, '호') AS DONGHO, ";

		strQuery += " CASE ";

		// 예약 시간이 있는 단건 예약이면 기존처럼 예약일만 표시
		strQuery += "   WHEN cr.TIME IS NOT NULL AND cr.TIME != '' ";
		strQuery += "   THEN cr.DATE ";

		// 예약 시간이 없는 이용권/기간권이면 예약 시작일 DATE - EXPIRATION_DATE 표시
		strQuery += "   WHEN cr.DATE IS NOT NULL ";
		strQuery += "    AND cr.DATE != '' ";
		strQuery += "    AND cr.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.EXPIRATION_DATE != '' ";
		strQuery += "   THEN CONCAT(LEFT(cr.DATE, 8), LEFT(cr.EXPIRATION_DATE, 8)) ";

		// fallback
		strQuery += "   ELSE cr.DATE ";
		strQuery += " END AS RESERVE_DATE, ";

		strQuery += " cr.TIME, ";
		strQuery += " IF(";
		strQuery += "   IF(IFNULL(cr.TIME, '') = '',";
		strQuery += "     LEFT(cr.DATE, 8),";
		strQuery += "     CONCAT(LEFT(cr.DATE, 8), LEFT(cr.TIME, 4))";
		strQuery += "   )";
		strQuery += "   > IF(IFNULL(cr.TIME, '') = '',";
		strQuery += "     DATE_FORMAT(SYSDATE(), '%Y%m%d'),";
		strQuery += "     DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i')";
		strQuery += "   ),";
		strQuery += "   '1', '0'";
		strQuery += " ) AS BUTTON_VISIBILITY, ";
		strQuery += " IF(cr.TIME IS NOT NULL AND cr.TIME != '', '1', '2') AS SERVICE_TYPE, ";
		strQuery += " cr.PLACE, ";
		strQuery += " amul.DESCRIPTION AS MEMBERSHIP_TITLE, ";
		strQuery += " cr.EXPIRATION_DATE, ";
		strQuery += " cr.REG_DATE, ";
		strQuery += " cr.RESERVE_CANCEL_TIME, ";
		strQuery += " ac.SECURITY, ";
		strQuery += " CASE ";
		strQuery += "   WHEN amul.OPTIONS IS NOT NULL AND amul.OPTIONS != '' THEN amo.OPTION_NAME ";
		strQuery += "   ELSE NULL ";
		strQuery += " END AS OPTION_NAME, ";
		strQuery += " cr.MEMBERSHIP_ID, cr.MEMBERSHIP_USER_LIST_ID, ";
		strQuery += " amul.OPTIONS AS OPTION_IDS, cr.COMMUNITY_TYPE, cr.GENDER, amul.MEMBERSHIP_USER_LIST_ID as MEMBERSHIP_USER_LIST_ID, amul.SETTLEMENT_DATE, amul.REGISTRATION_DATE ";
		strQuery += "FROM APT_COMMUNITY_RESERVE cr ";
		strQuery += "LEFT JOIN APT_COMMUNITY ac ";
		strQuery += "  ON ac.COMMUNITY_TYPE = cr.COMMUNITY_TYPE ";
		strQuery += " AND ac.APT_CODE = '" + strAptCode + "' ";
		strQuery += "LEFT JOIN APT_COMMUNITY_MEMBERSHIP_USER_LIST amul ";
		strQuery += "  ON amul.MEMBERSHIP_USER_LIST_ID = cr.MEMBERSHIP_USER_LIST_ID ";
		strQuery += "LEFT JOIN APT_COMMUNITY_MEMBERSHIP_OPTION amo ";
		strQuery += "  ON amo.OPTION_ID = amul.OPTIONS ";
		strQuery += "  WHERE cr.APT_CODE = '" + strAptCode + "' ";
		strQuery += "  AND cr.RESERVE_ID = '" + strReservationId + "' ";

		printLog("A" , "strQuery : " + strQuery);

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();
			
		String strImage = ""; // 이미지
		String strTitle = ""; // 타이틀
		String strReservationUserName = ""; // 신청자 성함
		String strUserName =""; // 이용자 성함
		String strDongHo = ""; // 동,호
		String strPlace = ""; // 신청 자리
		String strDate = ""; // 등록일
		String strTime = ""; // 등록 시간
		String strCancelType = ""; // 취소 종류(단위 -  0 : 분, 1 : 일)
		String strCancelTime = ""; // 취소 시간(단위 - 0 : mm분, 1 : dd일)
		String strButtonVisibility = ""; // 버튼 활성화 여부
		String strServiceType = ""; // 타입이 이용권, 예약이냐에 따라서 보여주는 항목이 달라서 사용
		String strExtraData = "";
		String strExpirationDate = "";
		boolean isCanceled = false;
		String strSecurity = "";
		String strOptions = "";
		String strMembershipId = "";
		String strMembershipListId = "";
		String strMembershipTitle = "";
		String strOptionIds = "";
		String strCommunitYType = "";
		String strMembershipUserListId = "0";
		String strQRId = ""; // QR 기기 iD
		String strQRSecurityCode = ""; // QR 보안 코드
		String strGender = "";
		String strSettlementDate = ""; // 정산일
		String strRegistrationDate = ""; // 이용 시작일
		// APT_COMMUNITY_RESERVE의 등록일 / 예약 취소일
		String strPurchaseDate = "";
		String strReserveCancelTime = "";


		if(rs.next()) {
			strImage = rs.getString("IMAGE") != null ? rs.getString("IMAGE") : ""; // 이미지
			strTitle = rs.getString("TITLE") != null ? rs.getString("TITLE") : ""; // 타이틀
			strReservationUserName = rs.getString("USER_NAME") != null ? rs.getString("USER_NAME") : ""; // 신청자 성함
			strUserName = rs.getString("RESERVE_USER_NAME") != null ? rs.getString("RESERVE_USER_NAME") : ""; // 이용자 성함
			strDongHo = rs.getString("DONGHO") != null ? rs.getString("DONGHO") : ""; // 동,호
			strPlace = rs.getString("PLACE") != null ? rs.getString("PLACE") : ""; // 신청 자리
			strDate = rs.getString("RESERVE_DATE") != null ? rs.getString("RESERVE_DATE") : ""; // 등록일
			strTime = rs.getString("TIME") != null ? rs.getString("TIME") : ""; // 등록 시간		
			strButtonVisibility = rs.getString("BUTTON_VISIBILITY") != null ? rs.getString("BUTTON_VISIBILITY") : ""; // 버튼 활성화 여부
			strServiceType = rs.getString("SERVICE_TYPE") != null ? rs.getString("SERVICE_TYPE") : ""; // 타입이 이용권, 예약이냐에 따라서 보여주는 항목이 달라서 사용
			strExtraData = rs.getString("OPTION_NAME") != null ? rs.getString("OPTION_NAME") : ""; // 추가 데이터
			strExpirationDate = rs.getString("EXPIRATION_DATE") != null ? rs.getString("EXPIRATION_DATE") : ""; // 만료일

			strPurchaseDate = rs.getString("REG_DATE") != null
				? rs.getString("REG_DATE").trim()
				: "";

			strReserveCancelTime = rs.getString("RESERVE_CANCEL_TIME") != null
				? rs.getString("RESERVE_CANCEL_TIME").trim()
				: "";

			isCanceled = !strReserveCancelTime.contentEquals("");

			strSecurity = rs.getString("SECURITY") != null ? rs.getString("SECURITY") : ""; // 보안
			strOptions = rs.getString("OPTION_NAME") != null ? rs.getString("OPTION_NAME") : ""; // 옵션
			strMembershipTitle = rs.getString("MEMBERSHIP_TITLE") != null ? rs.getString("MEMBERSHIP_TITLE") : ""; // 회원권 이름 
			

			strMembershipId = rs.getString("MEMBERSHIP_ID") != null ? rs.getString("MEMBERSHIP_ID") : "";
			strMembershipListId = rs.getString("MEMBERSHIP_USER_LIST_ID") != null ? rs.getString("MEMBERSHIP_USER_LIST_ID") : "";
			strOptionIds = rs.getString("OPTION_IDS") != null ? rs.getString("OPTION_IDS") : "";
			strCommunitYType = rs.getString("COMMUNITY_TYPE") != null ? rs.getString("COMMUNITY_TYPE") : "";
			strGender = rs.getString("GENDER") != null ? rs.getString("GENDER") : "";

			strMembershipUserListId = rs.getString("MEMBERSHIP_USER_LIST_ID") != null ? rs.getString("MEMBERSHIP_USER_LIST_ID") : "0";
			strSettlementDate = rs.getString("SETTLEMENT_DATE") != null ? rs.getString("SETTLEMENT_DATE") : "";
			strRegistrationDate =  rs.getString("REGISTRATION_DATE") != null ? rs.getString("REGISTRATION_DATE") : "";


		}

		if(strMembershipTitle != null){
			strMembershipTitle = strMembershipTitle.replaceAll("\\*","");
		}

		String strUsageLimitQuery = "";
		strUsageLimitQuery += " SELECT USAGE_LIMIT, RESERVE_CANCEL_AVAILABLE_TIME_UNIT, RESERVE_CANCEL_AVAILABLE_TIME, IS_SEAT_CHANGEABLE ";
		strUsageLimitQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO  ";
		strUsageLimitQuery += " WHERE MEMBERSHIP_ID = ? ";

		pstmt = conn.prepareStatement(strUsageLimitQuery);
		pstmt.setString(1, strMembershipId);
		rs = pstmt.executeQuery();
		String strUsageLimit = "";
		String strSeatChangeAble = "0";
		if(rs.next()){
			if(rs.getString("USAGE_LIMIT") != null){
				strUsageLimit = rs.getString("USAGE_LIMIT");
			}
			strCancelType = rs.getString("RESERVE_CANCEL_AVAILABLE_TIME_UNIT") != null ? rs.getString("RESERVE_CANCEL_AVAILABLE_TIME_UNIT") : ""; // 취소 종류(단위 -  0 : 분, 1 : 일)
			strCancelTime = rs.getString("RESERVE_CANCEL_AVAILABLE_TIME") != null ? rs.getString("RESERVE_CANCEL_AVAILABLE_TIME") : ""; // 취소 시간(단위 - 0 : mm분, 1 : dd일)
			if(rs.getString("IS_SEAT_CHANGEABLE") != null){
				strSeatChangeAble = rs.getString("IS_SEAT_CHANGEABLE");
			}

			printLog("A","strCancelType : " + strCancelType );
			printLog("A","strCancelTime : " + strCancelTime );
		}
			String strReserveCount = "";

		if(strUsageLimit != null && !strUsageLimit.contentEquals("") && !strUsageLimit.contentEquals("0")){
			String strReservationCountQuery = "";
			strReservationCountQuery = " SELECT COUNT(*) as RESERVE_COUNT ";
			strReservationCountQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReservationCountQuery += " WHERE MEMBERSHIP_USER_LIST_ID = ? ";
			strReservationCountQuery += " AND RESERVE_ID <= ? ";
			
			pstmt = conn.prepareStatement(strReservationCountQuery);
			pstmt.setString(1, strMembershipListId);
			pstmt.setString(2, strReservationId);

			rs = pstmt.executeQuery();
			if(rs.next()){
				if(rs.getString("RESERVE_COUNT") != null){
					strReserveCount = rs.getString("RESERVE_COUNT");
				}
			}			
		}

		boolean isExpiration = false;

		if(strExpirationDate != null && !strExpirationDate.contentEquals("") && strExpirationDate.length() != 8){
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			
			
			String currentDateTime = sdf.format(new Date());

			try {
				// 문자열을 Date 객체로 변환
				Date expirationDate = sdf.parse(strExpirationDate);
				Date today = sdf.parse(currentDateTime);

				// 날짜 비교
				if (expirationDate.compareTo(today) <= 0) {
					// 만료일이 현재보다 이전인 경우
					isExpiration = true;				
				} else if (expirationDate.compareTo(today) > 0) {
					// 만료일이 현재보다 이후인 경우
					isExpiration = false;			
				} 
			} catch (ParseException e) {
				e.printStackTrace();
			}
		}else if(strExpirationDate != null && !strExpirationDate.contentEquals("") && strExpirationDate.length() == 8){
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMdd");
			
			
			String currentDate = sdf.format(new Date());

			try {
				// 문자열을 Date 객체로 변환
				Date expirationDate = sdf.parse(strExpirationDate);
				Date today = sdf.parse(currentDate);

				// 날짜 비교
				if (expirationDate.compareTo(today) <= 0) {
					// 만료일이 현재보다 이전인 경우
					isExpiration = true;				
				} else if (expirationDate.compareTo(today) > 0) {
					// 만료일이 현재보다 이후인 경우
					isExpiration = false;			
				} 
			} catch (ParseException e) {
				e.printStackTrace();
			}
		}

		// 취소 가능 시간(TIME) 값이 없으면 시간 제한 없이 취소 가능 (만료/취소/정책은 아래 분기에서 판단)
		boolean hasCancelTimeLimit = (strCancelTime != null && !strCancelTime.contentEquals(""));

		printLog("A","hasCancelTimeLimit : " + hasCancelTimeLimit );
		

		// UI에서 ㅁ박스 안에 있는 데이터는 딜리미터 붙인 포맷으로 전달
		String strInfo = "";
		if(!strReservationUserName.isEmpty()){
			strInfo += "신청자 성함*" + strReservationUserName + "*+" ;
		}
		if(!strUserName.contentEquals("")){
			strInfo += "이용자 성함*" + strUserName + "*+" ;
		}
		if(!strDongHo.isEmpty()){
			strInfo += "동/호수*" + strDongHo + "*+" ;
		}
		if(!strTitle.isEmpty()){		
			strInfo += "시설내역*"  + strTitle +  "*+" ;
		}
		if(!strPlace.isEmpty()){
			if(strPlace.contentEquals("PLACE_ALL")){
				strPlace = "대관";
			}
			strInfo += "자리*"  + strPlace +  "*+" ;
		}

		if(!strDate.isEmpty()){
			printLog("D","strDate.length() : " + strDate.length());
			printLog("D","strDate : " + strDate);

			if(strDate.length() == 16){
				String strStartDate = strDate.substring(0, 8);
				String strEndDate = strDate.substring(8, 16);

				// 시작일과 만료일이 같으면 날짜 하나만 표시
				// 예: 26.01.29(목) ~ 26.01.29(목) -> 26.01.29(목)
				if(strStartDate.contentEquals(strEndDate)){
					strInfo += "날짜*" + formatDate(strStartDate) + "*+";
				} else {
					strInfo += "날짜*" + formatDate(strStartDate) + " ~ " + formatDate(strEndDate) + "*+";
				}
			} else {
				strInfo += "날짜*" + formatDate(strDate) + "*+";
			}
		}

		if(!strTime.isEmpty()){
			printLog("D","strTime : " + strTime);
			strInfo += "시간*" + formatTime(strTime) + "*+" ;														
		}

		if(strReserveCount != null && !strReserveCount.isEmpty()){
			strInfo += "사용횟수*" + strReserveCount + "회*+" ;
		}			

		if(!strMembershipTitle.isEmpty()){
			if(!strOptions.isEmpty()){
				strMembershipTitle += "\n" + strOptions;
			}
			strInfo += "회원권*"  + strMembershipTitle + "*+" ;
		}

		// 예약 등록일을 구매 날짜로 표시
		if(strPurchaseDate != null
			&& strPurchaseDate.length() == 14) {

			String strFormattedPurchaseDate =
				formatDateTime(strPurchaseDate);

			if(strFormattedPurchaseDate != null
				&& !strFormattedPurchaseDate.contentEquals("")) {

				strInfo += "구매 날짜*"
					+ strFormattedPurchaseDate
					+ "*+";
			}
		}

		// 취소된 예약일 때만 예약 취소 날짜 표시
		if(isCanceled
			&& strReserveCancelTime != null
			&& strReserveCancelTime.length() == 14) {

			String strFormattedCancelDate =
				formatDateTime(strReserveCancelTime);

			if(strFormattedCancelDate != null
				&& !strFormattedCancelDate.contentEquals("")) {

				strInfo += "취소 날짜*"
					+ strFormattedCancelDate
					+ "*+";
			}
		}
		
		// 예약시간 존재 여부
		boolean bHasReservationTime = !(strTime == null || strTime.contentEquals(""));
		
		if(!bHasReservationTime){
			strTime = "00002400"; // 예약 시간이 없는 경우, 하루종일로 간주하고 비교하기 위해 00002400으로 세팅
		}

		String strCancellable = "";
		String strButtonContext = "";
		String strCancellableDate = "";
	

		 // 첫 번째 날짜(취소 가능 날짜)
        Calendar date1 = Calendar.getInstance();
		int nYear = Integer.parseInt(strDate.substring(0,4));
		int nMonth = Integer.parseInt(strDate.substring(4,6));
		int nDay = Integer.parseInt(strDate.substring(6,8));
		int nHour = Integer.parseInt(strTime.substring(0,2));
		int nMinute = Integer.parseInt(strTime.substring(2,4));

        date1.set(nYear, nMonth - 1, nDay, nHour, nMinute); 

        // 두 번째 날짜 설정(현재 날짜)    
        Calendar date2 = Calendar.getInstance(TimeZone.getTimeZone("Asia/Seoul"));

    	// 취소 가능 날짜 포멧 yy.MM.dd (E) HH:mm
        SimpleDateFormat sdf = new SimpleDateFormat("yy.MM.dd (E) HH:mm", Locale.KOREAN);
		SimpleDateFormat sdfyyMMddHHmm = new SimpleDateFormat("yyMMddHHmm", Locale.KOREAN);

        // 포맷에 맞게 날짜와 시간 출력
        String formattedTime = sdf.format(date1.getTime());
		
		// date1에서 strCancelTime빼기 (TIME 값이 있을 때만 마감 시각 계산)
        Calendar date1CancelDays = (Calendar) date1.clone();
		String formattedDate1MinusDays = "";
		String formattedDateCancellableDate = "";

		if(hasCancelTimeLimit) {
  			int daysToSubtract = -Integer.parseInt(strCancelTime.replaceAll("[^0-9]", ""));

			if(strCancelType.contentEquals(UNIT_MINUTE)){
				date1CancelDays.add(Calendar.MINUTE, daysToSubtract);
			}else if(strCancelType.contentEquals(UNIT_HOUR)){		
				date1CancelDays.add(Calendar.HOUR_OF_DAY, daysToSubtract);
			}else if(strCancelType.contentEquals(UNIT_DAYS)){		
				date1CancelDays.add(Calendar.DAY_OF_MONTH, daysToSubtract);
			}
        	formattedDate1MinusDays = sdf.format(date1CancelDays.getTime());
			formattedDateCancellableDate = sdfyyMMddHHmm.format(date1CancelDays.getTime());
		}


		String strMembershipCancelQuery = "";
		strMembershipCancelQuery += " SELECT RESERVE_CANCEL_AVAILABLE FROM APT_COMMUNITY_RESERVE as acr ";
		strMembershipCancelQuery += " JOIN APT_COMMUNITY_MEMBERSHIP_INFO as acmi ";
		strMembershipCancelQuery += " ON acmi.MEMBERSHIP_ID = acr.MEMBERSHIP_ID ";
		strMembershipCancelQuery += " WHERE acr.RESERVE_ID = " + strReservationId + " ";

		pstmt = conn.prepareStatement(strMembershipCancelQuery);
		rs = pstmt.executeQuery();
		
		String strCancelAvavilable = "0";
		if(rs.next()){
			if(rs.getString(1) != null){
				strCancelAvavilable = rs.getString(1);
			}
		}
		printLog("A","strServiceType : " + strServiceType );

		printLog("A","formattedDateCancellableDate : " + formattedDateCancellableDate );
  		printLog("A","isExpiration : " + isExpiration );
		printLog("A","isCanceled : " + isCanceled );
		// final static String IMMEDIATE_RESERVE = "1";             // 바로 예약
    	// final static String TICKET_PURCHASE_WITH_TIME = "2";     // 이용권 구매 후 시간을 추가 선택
    	// final static String NO_RESERVE = "3";                    // 예약없음
    	// final static String TICKET_PURCHASE_AND_RESERVE = "4";   // 이용권 구매와 예약이 동시에 이루어짐




		if(strServiceType.contentEquals(TICKET_PURCHASE_WITH_TIME)){
			if(isExpiration || isCanceled){
				// 만료
				strCancellable = "0";
				strButtonContext = "";
				strCancellableDate = "";
				strButtonVisibility = "0";
			}else{
				
				if(strCancelAvavilable.contentEquals(CANCEL_IMPOSSIBLE)){
					// 취소 불가능
					strCancellable = "0";
					strButtonContext = "";
					strCancellableDate = "";
					strButtonVisibility = "0";
				}else if(!hasCancelTimeLimit) {
					// 취소 가능 시간 미설정 -> 시간 제한 없이 취소 가능
					strCancellable = "1";
					strButtonContext = "취소하기";
					strCancellableDate = "";
					strButtonVisibility = "1";
				}else if (date1CancelDays.compareTo(date2) < 0) {
					printLog("A","type23 : cancel");
					
					// 날짜 비교
					// 취소 가능 날짜가 현재 날짜보다 이전인경우
					// 취소 불가능
					strCancellable = "0";    
					strButtonContext = "예약 ";

		
					if(strCancelType.contentEquals(UNIT_MINUTE)){
						strButtonContext += strCancelTime + "분 전에는 취소가 불가능합니다.";
					}else if(strCancelType.contentEquals(UNIT_HOUR)){
						strButtonContext += strCancelTime + "시간 전에는 취소가 불가능합니다.";
					}else if(strCancelType.contentEquals(UNIT_DAYS)){
						strButtonContext += strCancelTime + "일 전에는 취소가 불가능합니다.";
					}					
					strCancellableDate = "";

					
				} else if (date1CancelDays.compareTo(date2) > 0) {
									printLog("A","type3 : cancel");

					// 취소 가능 날짜가 현재 날짜보다 이후인경우
					// 취소 가능
					strCancellable = "1";
					strButtonContext = "취소하기";
					strCancellableDate = formattedDateCancellableDate;
				}else{
						printLog("A","type1 : cancel");
						// 취소 가능 
						strCancellable = "1";
						strButtonContext = "취소하기";
						strCancellableDate = "";
						strButtonVisibility = "1";
					}					
				}

		}else{
			if(strCancelAvavilable.contentEquals(CANCEL_IMPOSSIBLE)){
						printLog("A","strCancelAvavilable : " + strCancelAvavilable );
						printLog("A","CANCEL_IMPOSSIBLE : " + CANCEL_IMPOSSIBLE );

					// 취소 불가능
					strCancellable = "0";
					strButtonContext = "";
					strCancellableDate = "";
					strButtonVisibility = "0";
			}else if(!hasCancelTimeLimit) {
				// 취소 가능 시간 미설정 -> 시간 제한 없이 취소 가능
				strCancellable = "1";
				strButtonContext = "취소하기";
				strCancellableDate = "";
				strButtonVisibility = "1";
			}else if (date1CancelDays.compareTo(date2) < 0) {
				printLog("A","type22 : cancel");
				
				// 날짜 비교
				// 취소 가능 날짜가 현재 날짜보다 이전인경우
				// 취소 불가능
				strCancellable = "0";    
				strButtonContext = "예약 ";
	
				if(strCancelType.contentEquals(UNIT_MINUTE)){
					strButtonContext += strCancelTime + "분 전에는 취소가 불가능합니다.";
				}else if(strCancelType.contentEquals(UNIT_HOUR)){
					strButtonContext += strCancelTime + "시간 전에는 취소가 불가능합니다.";
				}else if(strCancelType.contentEquals(UNIT_DAYS)){
					strButtonContext += strCancelTime + "일 전에는 취소가 불가능합니다.";
				}
				strCancellableDate = "";
				
			} else if (date1CancelDays.compareTo(date2) > 0) {
								printLog("A","type3 : cancel");

				// 취소 가능 날짜가 현재 날짜보다 이후인경우
				// 취소 가능
				strCancellable = "1";
				strButtonContext = "취소하기";
				strCancellableDate = formattedDateCancellableDate;
			} else {	
												printLog("A","type4 : cancel");

				// 동일한 경우...?
				strCancellable = "1";
				strButtonContext = "취소하기";
				strCancellableDate = formattedDateCancellableDate;
			}		
		}

		
		// ========================
		// 환불 가능 여부 판단
		// ========================
		String strRefundable = "0";
		String strRefundableDate = "";
		String strToday = new SimpleDateFormat("yyyyMMdd").format(new Date());

		boolean isRefundCancellable = strCancellable.contentEquals("1");

		boolean isBeforeSettlement = false;
		if (strSettlementDate != null && strSettlementDate.length() == 8) {
			isBeforeSettlement = strToday.compareTo(strSettlementDate) <= 0;
		}

		boolean isRegistrationAfterToday = false;
		if (strRegistrationDate != null && strRegistrationDate.length() >= 8) {
			if (!strTime.isEmpty() && strTime.length() >= 4) {
				// 시간 포함 비교 (yyyyMMddHHmm)
				String strNow = strToday + new SimpleDateFormat("HHmm").format(new Date());
				String strRegistrationDateTime = strRegistrationDate.substring(0, 8) + strTime.substring(0, 4);
				isRegistrationAfterToday = strRegistrationDateTime.compareTo(strNow) > 0;
			} else {
				isRegistrationAfterToday = strRegistrationDate.substring(0, 8).compareTo(strToday) > 0;
			}
		}

		printLog("D", "strToday: " + strToday);
		printLog("D", "strSettlementDate: " + strSettlementDate);
		printLog("D", "strRegistrationDate: " + strRegistrationDate);
		printLog("D", "isRefundCancellable: " + isRefundCancellable);
		printLog("D", "isBeforeSettlement: " + isBeforeSettlement);
		printLog("D", "isRegistrationAfterToday: " + isRegistrationAfterToday);

		if (isRefundCancellable && isBeforeSettlement && isRegistrationAfterToday) {
			strRefundable = "1";

			Calendar dateSettlement = Calendar.getInstance();
			dateSettlement.set(
				Integer.parseInt(strSettlementDate.substring(0, 4)),
				Integer.parseInt(strSettlementDate.substring(4, 6)) - 1,
				Integer.parseInt(strSettlementDate.substring(6, 8)),
				0, 0, 0
			);

			Calendar dateRegistration = Calendar.getInstance();
			dateRegistration.set(
				Integer.parseInt(strRegistrationDate.substring(0, 4)),
				Integer.parseInt(strRegistrationDate.substring(4, 6)) - 1,
				Integer.parseInt(strRegistrationDate.substring(6, 8)),
				0, 0, 0
			);

			// RegistrationDate가 정산일보다 빠르면 RegistrationDate가 환불 마감
			if (dateRegistration.compareTo(dateSettlement) < 0) {
				strRefundableDate = new SimpleDateFormat("yyyyMMdd").format(dateRegistration.getTime());
			} else {
				strRefundableDate = new SimpleDateFormat("yyyyMMdd").format(dateSettlement.getTime());
			}
		}

		printLog("D", "strRefundable: " + strRefundable);
		printLog("D", "strRefundableDate: " + strRefundableDate);	


		String strReceiptURLQeury = "";
		strReceiptURLQeury += " SELECT RECEIPT_URL FROM PARTNER_PAYMENT WHERE MENU_ID = '49' AND RESERVATION_ID = '" + strMembershipListId + "' ";
		
		pstmt = conn.prepareStatement(strReceiptURLQeury);
		rs = pstmt.executeQuery();
		
		String strReceiptURL = "";
		if(rs.next()){
			if(rs.getString(1) != null){
				strReceiptURL = rs.getString(1);
			}
		}

		boolean isSameUserName = false;

		if (strRequestUserName != null && strUserName != null) {
			isSameUserName = strRequestUserName.trim().contentEquals(strUserName.trim());
		}

		if (isSameUserName && !isCanceled) {
			String strQRQuery = "";
			strQRQuery += "SELECT ID, SECURITY_CODE FROM APT_COMMUNITY_QR";
			strQRQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
			strQRQuery += " AND COMMUNITY_TYPE = '" + strCommunitYType + "' ";
			strQRQuery += " AND (GENDER = 0 OR GENDER = '" + strGender + "' )";

			printLog("A","strQRQuery :" + strQRQuery);

			pstmt = conn.prepareStatement(strQRQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strQRId = rs.getString("ID") != null ? rs.getString("ID") : "";
				strQRSecurityCode = rs.getString("SECURITY_CODE") != null ? rs.getString("SECURITY_CODE") : "";
			}
		} else {
			strQRId = "";
			strQRSecurityCode = "";
		}

		printLog("A","strRequestUserName :" + strRequestUserName);
		printLog("A","strReserveUserName :" + strUserName);
		printLog("A","strQRId :" + strQRId);
		printLog("A","strQRSecurityCode :" + strQRSecurityCode);

		printLog("A","strDate :" + strDate);
		printLog("A","strTime :" + strTime);
		printLog("A","strQRId :" + strQRId);
		printLog("A","strQRSecurityCode :" + strQRSecurityCode);


		// 시설 운영 시간 조회
		String strTimeQuery = getTimeQuery(strAptCode, strCommunitYType);		
		printLog("A","strTimeQuery : " + strTimeQuery);

		pstmt = conn.prepareStatement(strTimeQuery);
		rs = pstmt.executeQuery();

		String strStartTime =""; // 시설 운영 시작 시각
		String strEndTime ="";	// 시설 운영 종료 시각
		String strOperationHours=""; // 시설 운영 시간 (주중, 주말로 나누어진 json형태) 
		String strCommunityState = "";

		if(rs.next()) {
			strStartTime = rs.getString(1) != null ? rs.getString(1) : "";
			strEndTime = rs.getString(2) != null ? rs.getString(2) : "";
			strOperationHours = rs.getString(3) != null ? rs.getString(3) : "";
			strCommunityState = rs.getString(4) != null ? rs.getString(4) : "";
		}
		
		List<Holiday> holidays = new ArrayList<Holiday>();
		String strHolidaysQuery = getHolidaysQuery(strAptCode,strCommunitYType);

		pstmt = conn.prepareStatement(strHolidaysQuery);
		rs_community = pstmt.executeQuery();

		rsMetaData = rs_community.getMetaData();
		// 휴무일을 조합하는 문자열
		String strHolidays = "";

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
		
		// 특정 운영시간이 존재하는 경우
		// if(!strOperationHours.contentEquals("")) {
		// 	SimpleDateFormat sdfOperationHours = new SimpleDateFormat("yyyyMMdd");
		// 	String currentDateTime = sdfOperationHours.format(new Date());
		// 	Date dateOperationHours = sdfOperationHours.parse(currentDateTime);
		// 	Calendar calendarOperationHours = Calendar.getInstance();
		// 	calendarOperationHours.setTime(dateOperationHours);

		// 	// 요일 확인 (1: 일요일, 2: 월요일, ..., 7: 토요일)
		// 	int dayOfWeekOperationHours = calendarOperationHours.get(Calendar.DAY_OF_WEEK);

		// 	// WEEKDAY 또는 WEEKEND에 따라 값 추출
		// 	String strStartTimeJson = "";
		// 	String strEndTimeJson = "";
		// 	if (dayOfWeekOperationHours == Calendar.SATURDAY || dayOfWeekOperationHours == Calendar.SUNDAY) {
		// 		// 주말인 경우
		// 		strStartTimeJson = extractValue(strOperationHours, "WEEKEND", "start");
		// 		strEndTimeJson = extractValue(strOperationHours, "WEEKEND", "end");
		// 	} else {
		// 		// 평일인 경우
		// 		strStartTimeJson = extractValue(strOperationHours, "WEEKDAY", "start");
		// 		strEndTimeJson = extractValue(strOperationHours, "WEEKDAY", "end");
		// 	}
		// 	if(strTime.contentEquals("00002400")) {
		// 		strTime = strStartTimeJson+strEndTimeJson; // 예약 시간이 없는 경우, 하루종일로 간주하고 비교하기 위해 00002400으로 세팅한 것을 특정 운영시간으로 재세팅
		// 	}
		// } else {
		// 	if(strTime.contentEquals("00002400")) {
		// 		strTime = strStartTime+strEndTime; // 예약 시간이 없는 경우, 하루종일로 간주하고 비교하기 위해 00002400으로 세팅한 것을 운영시간으로 재세팅
		// 	}
		// }

		// =====================================================
		// 시설 운영시간 계산
		// strTime은 예약시간 응답용으로 유지하고,
		// 시설 운영상태 계산용 시간은 별도 변수로 분리
		// =====================================================

		String strFacilityStartTime = "";
		String strFacilityEndTime = "";

		if(strOperationHours != null
			&& !strOperationHours.contentEquals("")) {

			Calendar calendarOperationHours =
				Calendar.getInstance();

			int dayOfWeekOperationHours =
				calendarOperationHours.get(Calendar.DAY_OF_WEEK);

			if(dayOfWeekOperationHours == Calendar.SATURDAY
				|| dayOfWeekOperationHours == Calendar.SUNDAY) {

				strFacilityStartTime =
					extractValue(
						strOperationHours,
						"WEEKEND",
						"start"
					);

				strFacilityEndTime =
					extractValue(
						strOperationHours,
						"WEEKEND",
						"end"
					);

			} else {

				strFacilityStartTime =
					extractValue(
						strOperationHours,
						"WEEKDAY",
						"start"
					);

				strFacilityEndTime =
					extractValue(
						strOperationHours,
						"WEEKDAY",
						"end"
					);
			}

		} else {

			strFacilityStartTime =
				strStartTime != null
				? strStartTime.replace(":", "")
							.replace(" ", "")
				: "";

			strFacilityEndTime =
				strEndTime != null
				? strEndTime.replace(":", "")
							.replace(" ", "")
				: "";
		}

		if(strFacilityStartTime == null) {
			strFacilityStartTime = "";
		}

		if(strFacilityEndTime == null) {
			strFacilityEndTime = "";
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
		
			// boolean bValidTime = (strTime != null && strTime.length() == 8);
			// int nStartTime = 0;
			// int nEndTime = 0;
			// SimpleDateFormat sdfHHmm = new SimpleDateFormat("HHmm");
			// Calendar calStart = null;
			// Calendar calEnd = null;

			// if(bValidTime && bHasReservationTime) {
			// 	// 예약시간이 있는 경우 - 시작 -15분, 종료 +15분 (입장 융통성)
			// 	calStart = Calendar.getInstance();
			// 	calStart.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTime.substring(0,2)));
			// 	calStart.set(Calendar.MINUTE, Integer.parseInt(strTime.substring(2,4)));
			// 	calStart.add(Calendar.MINUTE, -15);
			// 	calEnd = Calendar.getInstance();
			// 	calEnd.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTime.substring(4,6)));
			// 	calEnd.set(Calendar.MINUTE, Integer.parseInt(strTime.substring(6,8)));
			// 	calEnd.add(Calendar.MINUTE, 15);

			// 	// strState 판단도 버퍼 적용된 시간 기준으로
			// 	nStartTime = Integer.parseInt(sdfHHmm.format(calStart.getTime()));
			// 	nEndTime   = Integer.parseInt(sdfHHmm.format(calEnd.getTime()));
			// } else if(bValidTime) {
			// 	// 운영시간만 있는 경우 - 버퍼 없이 원본 시간 그대로 사용
			// 	nStartTime = Integer.parseInt(strTime.substring(0,4));
			// 	nEndTime   = Integer.parseInt(strTime.substring(4,8));
			// }

			// =====================================================
			// 예약 입장/퇴장 가능시간 계산
			// 응답값에는 기존처럼 예약시간 ±15분을 적용
			// strState 계산에는 사용하지 않음
			// =====================================================

			SimpleDateFormat sdfHHmm =
				new SimpleDateFormat("HHmm");

			Calendar calStart = null;
			Calendar calEnd = null;

			boolean bValidReservationTime =
				strTime != null
				&& strTime.length() == 8;

			if(bValidReservationTime && bHasReservationTime) {

				calStart = Calendar.getInstance();

				calStart.set(
					Calendar.HOUR_OF_DAY,
					Integer.parseInt(strTime.substring(0, 2))
				);

				calStart.set(
					Calendar.MINUTE,
					Integer.parseInt(strTime.substring(2, 4))
				);

				calStart.add(Calendar.MINUTE, -15);

				calEnd = Calendar.getInstance();

				calEnd.set(
					Calendar.HOUR_OF_DAY,
					Integer.parseInt(strTime.substring(4, 6))
				);

				calEnd.set(
					Calendar.MINUTE,
					Integer.parseInt(strTime.substring(6, 8))
				);

				calEnd.add(Calendar.MINUTE, 15);
			}
			

			// String strState;
			// String strStateTitle;

			// if (isHoliday) {
			// 	strState = "2";
			// 	if(isTempHoliday) {
			// 		strStateTitle = "임시휴무";
			// 	} else {
			// 		strStateTitle = "정기휴무";
			// 	}
			// } else if (!bValidTime) {
			// 	strState = "4";
			// 	strStateTitle = "운영종료";
			// } else if (
			// 	(nStartTime <= nEndTime && nStartTime < nNowTime && nEndTime > nNowTime)
			// 	||
			// 	(nStartTime > nEndTime && (nNowTime > nStartTime || nNowTime < nEndTime))
			// ) {
			// 	strState  = "1";
			// 	strStateTitle = "운영중";
			// } else {
			// 	strState = "4";
			// 	if(strCommunitYType.contentEquals(TYPE_GUESTHOUSE)){
			// 		strStateTitle = "운영중";
			// 		strState = "1";
			// 	}else{
			// 		strStateTitle = "운영종료";
			// 	}
			// }

			// =====================================================
			// 시설 운영시간 기준 strState 계산
			// =====================================================

			boolean bValidFacilityTime =
				strFacilityStartTime != null
				&& strFacilityEndTime != null
				&& strFacilityStartTime.length() == 4
				&& strFacilityEndTime.length() == 4;

			int nFacilityStartTime = 0;
			int nFacilityEndTime = 0;

			if(bValidFacilityTime) {
				try {
					nFacilityStartTime =
						Integer.parseInt(strFacilityStartTime);

					nFacilityEndTime =
						Integer.parseInt(strFacilityEndTime);

				} catch(NumberFormatException e) {
					bValidFacilityTime = false;
				}
			}

			String strState;
			String strStateTitle;

			if(isHoliday) {

				strState = "2";

				if(isTempHoliday) {
					strStateTitle = "임시휴무";
				} else {
					strStateTitle = "정기휴무";
				}

			} else if(!bValidFacilityTime) {

				strState = "4";
				strStateTitle = "운영종료";

			} else if(
				(
					nFacilityStartTime <= nFacilityEndTime
					&& nFacilityStartTime < nNowTime
					&& nFacilityEndTime > nNowTime
				)
				||
				(
					nFacilityStartTime > nFacilityEndTime
					&& (
						nNowTime > nFacilityStartTime
						|| nNowTime < nFacilityEndTime
					)
				)
			) {

				strState = "1";
				strStateTitle = "운영중";

			} else {

				strState = "4";

				if(strCommunitYType.contentEquals(TYPE_GUESTHOUSE)) {
					strState = "1";
					strStateTitle = "운영중";
				} else {
					strStateTitle = "운영종료";
				}
			}

			// COMMUNITY_STATE가 이용 불가이면 최종 상태 덮어쓰기
			if(strCommunityState != null
				&& strCommunityState.contentEquals(UNAVAILABLE)) {

				strState = "4";
				strStateTitle = "예약준비중";
			}

			printLog("D", strState);
			printLog("D", strStateTitle);

			// 취소된 예약이면 취소 불가 + QR 정보 제거
			if (isCanceled) {
				strCancellable = "0";
				strButtonContext = "";
				strCancellableDate = "";
				strButtonVisibility = "0";
				strQRId = "";
				strQRSecurityCode = "";
				strSeatChangeAble = "0";
			}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write(strImage.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strTitle.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strInfo.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// 취소 가능 여부 1 : 취소 가능, 0 : 취소 불가능
		baOutStream.write(strCancellable.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// 버튼 텍스트 취소가능하면 취소하기 불가능하면 
		// 예약 mm분전에는 취소가 불가능합니다.
		baOutStream.write(strButtonContext.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// 취소 가능 날짜 취소가 불가능해지면 빈 스트링
		baOutStream.write(strCancellableDate.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		// 버튼 보임 여부 1 : 보임, 0 안 보임
		baOutStream.write(strButtonVisibility.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strSecurity.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		if(isExpiration || isCanceled){
			strSeatChangeAble = "0";
		}
		baOutStream.write(strSeatChangeAble.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);	

		baOutStream.write(strMembershipId.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);	

		baOutStream.write(strOptionIds.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);	

		baOutStream.write(strPlace.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);	

		if(strDate.length() == 16){		
			baOutStream.write(strDate.substring(0,8).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write(strDate.substring(8,strDate.length()).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);							
		}else{
			baOutStream.write(strDate.getBytes(S_CHARSET)); // 자리변경시 문제 생기면 다시 빈문자열로 수정 요망
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write(strDate.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
		}

		if(calStart != null) {
			baOutStream.write(sdfHHmm.format(calStart.getTime()).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(sdfHHmm.format(calEnd.getTime()).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		} else {
			baOutStream.write(strTime.substring(0,4).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strTime.substring(4,8).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		baOutStream.write(strCommunitYType.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		if(strReceiptURL == null || strReceiptURL.trim().contentEquals("")){
			baOutStream.write("".getBytes(S_CHARSET));
		}else{
			baOutStream.write(strReceiptURL.getBytes(S_CHARSET));
		}
		baOutStream.write(COLUMN_DEL);	
		
		baOutStream.write(strQRId.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strQRSecurityCode.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strState.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		if(strRefundableDate == null || strRefundableDate.trim().contentEquals("")){
			baOutStream.write("".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}else{
			baOutStream.write(strRefundableDate.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		// 마지막 응답값으로 MEMBERSHIP_USER_LIST_ID 추가
		if(strMembershipUserListId == null || strMembershipUserListId.trim().contentEquals("")) {
			baOutStream.write("0".getBytes(S_CHARSET));
		}else{
			baOutStream.write(
				strMembershipUserListId.getBytes(S_CHARSET)
			);
		}
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(RECORD_DEL);	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);

	} else if(strSID.contentEquals("get_qr_info_list")) {

		// QR 정보 조회
		String strAptCode = getRequestParam(request, "AptCode");
		//String strCommunityType = getRequestParam(request, "CommunityType");
		//String strGender = getRequestParam(request, "Gender");
		// 해당 아파트의 커뮤니티 시설에 대한 QR 정보 조회 

		String strQRListQuery = "";
		strQRListQuery += "SELECT q.COMMUNITY_TYPE, ";
		strQRListQuery += "       (SELECT c.TITLE FROM APT_COMMUNITY c WHERE c.COMMUNITY_TYPE = q.COMMUNITY_TYPE LIMIT 1) AS TITLE, ";
		strQRListQuery += "       q.GENDER, q.ID, q.SECURITY_CODE ";
		strQRListQuery += "FROM APT_COMMUNITY_QR q ";
		strQRListQuery += "WHERE q.APT_CODE = '" + strAptCode + "' ";
		//strQRListQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
		//strQRListQuery += " AND ( GENDER = 0 OR GENDER = '" + strGender + "' ) ";

		printLog("D","strQRListQuery :" + strQRListQuery);

		pstmt = conn.prepareStatement(strQRListQuery);
		rs = pstmt.executeQuery();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		// 여러개 존재하니까 커뮤니티 타입, 성별, QR ID, 보안코드 순으로 구분자 붙여서 리스트 형태로 전달
		while(rs.next()){
			String strCommunityType = rs.getString("COMMUNITY_TYPE") != null ? rs.getString("COMMUNITY_TYPE") : "";
			String strTitle = rs.getString("TITLE") != null ? rs.getString("TITLE") : "";
			String strGender = rs.getString("GENDER") != null ? rs.getString("GENDER") : "";
			String strQRId = rs.getString("ID") != null ? rs.getString("ID") : "";
			String strQRSecurityCode = rs.getString("SECURITY_CODE") != null ? rs.getString("SECURITY_CODE") : "";
			baOutStream.write(strCommunityType.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strTitle.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strGender.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strQRId.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strQRSecurityCode.getBytes(S_CHARSET));
			baOutStream.write(RECORD_DEL);
		}

			// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);



	} else if(strSID.contentEquals("reservation_community_schedule")) {

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		String strEmpty = "";

		// 결제/트랜잭션 상태 플래그
		// - Bootpay 검증 또는 승인 확인이 끝난 상태인지
		boolean isPaymentConfirmed = false;
		// - conn.setAutoCommit(false) 이후인지
		boolean isTransactionStarted = false;
		// - PARTNER_PAYMENT 저장까지 성공했는지
		boolean isPaymentSaved = false;

		// 예약·회원권·결제 DB COMMIT까지 성공했는지
		boolean isDbCommitted = false;

		// 앱 응답 후 IoT·푸시·얼굴등록을 실행할지
		boolean shouldRunPostProcess = false;

		// COMMIT 후 autoCommit이 이미 원복됐는지
		boolean isAutoCommitRestored = false;

		// 결제 관련 값
		// - 앱/서버에서 사용하는 주문번호 성격의 결제 ID
		String strPaymentId = "";
		// - Bootpay에서 내려주는 영수증 ID
		String strReceiptId = "";
		String strTotalPrice = "";
		// - Bootpay 영수증 조회 후 PARTNER_PAYMENT에 저장
		String strReceiptUrl = "";
		String strPurchasedDate = "";

		// 실패 로그 및 rollback 추적을 위해 이번 요청에서 생성된 예약/회원권 ID 보관
		String strCreatedReservationId = "";
		String strCreatedMembershipUserListId = "";

		try { 
			// =========================================================
			// 1. 요청 파라미터 수집
			// =========================================================
			String strAptCommunityType = getRequestParam(request, "CommunityType");
			String strUserId = getRequestParam(request, "UserId");
			String strUserDong = getRequestParam(request, "UserDong");
			String strUserHo = getRequestParam(request, "UserHo");
			String strReservationUserName = getRequestParam(request, "ReservationUserName");
			String strReservationUserPhone = getRequestParam(request, "ReservationUserPhone");
			String strPlace = getRequestParam(request, "Place");
			String strDate = getRequestParam(request, "Date");
			String strTime = getRequestParam(request, "Time");
			String strAptCode = getRequestParam(request, "AptCode");
			String strUserName = getRequestParam(request, "UserName");
			String strMembershipId = getRequestParam(request, "MembershipId");
			strTotalPrice = getRequestParam(request, "Price");
			String strPeople = getRequestParam(request, "People");
			String strGender = getRequestParam(request, "Gender");
			String strUUID = getRequestParam(request, "UUID");
			strPaymentId = getRequestParam(request, "PaymentId");
			strReceiptId = getRequestParam(request, "ReceiptId");

			// =========================================================
			// 2. 파라미터 기본값 보정
			// - null 값을 빈 문자열로 바꿔 오류가 나지 않게 한다.
			// =========================================================
			strAptCommunityType = strAptCommunityType != null ? strAptCommunityType.trim() : "";
			strUserId = strUserId != null ? strUserId.trim() : "";
			strUserDong = strUserDong != null ? strUserDong.trim() : "";
			strUserHo = strUserHo != null ? strUserHo.trim() : "";
			strReservationUserName = strReservationUserName != null ? strReservationUserName.trim() : "";
			strReservationUserPhone = strReservationUserPhone != null ? strReservationUserPhone.trim() : "";
			strPlace = strPlace != null ? strPlace.trim() : "";
			strDate = strDate != null ? strDate.trim() : "";
			strTime = strTime != null ? strTime.trim() : "";
			strAptCode = strAptCode != null ? strAptCode.trim() : "";
			strUserName = strUserName != null ? strUserName.trim() : "";
			strMembershipId = strMembershipId != null ? strMembershipId.trim() : "";
			strTotalPrice = strTotalPrice != null ? strTotalPrice.trim() : "";
			strPeople = strPeople != null ? strPeople.trim() : "";
			strGender = strGender != null ? strGender.trim() : "";
			strUUID = strUUID != null ? strUUID.trim() : "";
			strPaymentId = strPaymentId != null ? strPaymentId.trim() : "";
			strReceiptId = strReceiptId != null ? strReceiptId.trim() : "";

printLog("A", "*** time test - " + strPaymentId + " : 1 예약 시작");

			// =========================================================
			// 필수 파라미터 검증
			// - 빈값이면 SQL 실행 전에 실패 응답
			// - AptCode 빈값으로 인해 SQL 문법 오류가 나는 문제 방지
			// =========================================================
			if(strAptCode.contentEquals("") ||
				strUserId.contentEquals("") ||
				strAptCommunityType.contentEquals("") ||
				strMembershipId.contentEquals("") ||
				strDate.contentEquals("") ||
				strTime.contentEquals("") ||
				strUserDong.contentEquals("") ||
				strUserHo.contentEquals("") ||
				strReservationUserName.contentEquals("")) {

					baOutStream.reset();

					baOutStream.write("0".getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write("예약 필수 정보가 없습니다.".getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					returnData(baOutStream, outStream);
					return;
			}

			// - 예약자명이 비어 있으면 로그인 사용자명으로 대체한다.
			if(strReservationUserName.contentEquals("")){
				strReservationUserName = strUserName;
			}

			// - UUID는 값이 없으면 0으로 저장한다.
			if(strUUID.contentEquals("")){
				strUUID = "0";
			}

			strPeople = strPeople.replace("명", "");

			// - 가격은 DB 저장/결제 검증을 위해 "원", 콤마를 제거한다.
			strTotalPrice = strTotalPrice.replace("원", "").replace(",", "");

			// 회원권 발급 성공 여부와 발급된 MEMBERSHIP_USER_LIST_ID
			// 유료 결제 건은 이 값이 정상이어야 PARTNER_PAYMENT 저장으로 진행한다.
			boolean isPurchase = false;
			String strMembershipUserListId = "";

			// =========================================================
			// 3. 예약자 휴대폰 보정
			// - 앱에서 ReservationUserPhone이 안 넘어온 경우 USER_INFO에서 조회한다.
			// - 얼굴인식 API 등록, 예약 정보 표시 등에 사용된다.
			// =========================================================
			if(strReservationUserPhone.contentEquals("")){

				String strUserPhoneQuery = "";
				strUserPhoneQuery += " SELECT USER_PHONE ";
				strUserPhoneQuery += " FROM USER_INFO ";
				strUserPhoneQuery += " WHERE 1 = 1 ";
				strUserPhoneQuery += " AND  APT_CODE = " + strAptCode + " ";
				strUserPhoneQuery += " AND  USER_ID = '" + strUserId + "' ";

				pstmt = conn.prepareStatement(strUserPhoneQuery);
				rs = pstmt.executeQuery();
			
				if(rs.next()) {
					strReservationUserPhone = rs.getString(1) != null ? rs.getString(1) : "";		
				}
			}

			// =========================================================
			// 4. 커뮤니티 시설 설정 조회
			// - SECURITY : 얼굴인식 사용 여부
			// - SERVICE_TYPE : 즉시예약 등 서비스 타입
			// - GENDER : 시설 성별 제한
			// =========================================================
			String strCommunitySecurity = "";
			strCommunitySecurity += " SELECT SECURITY, SERVICE_TYPE, GENDER ";
			strCommunitySecurity += " FROM APT_COMMUNITY ";
			strCommunitySecurity += " WHERE 1 = 1 ";
			strCommunitySecurity += " AND  APT_CODE = " + strAptCode + " ";
			strCommunitySecurity += " AND  COMMUNITY_TYPE = '" + strAptCommunityType + "' ";
			strCommunitySecurity += " AND  (GENDER = '0' OR GENDER = '" + strGender + "') ";

			pstmt = conn.prepareStatement(strCommunitySecurity);
			rs = pstmt.executeQuery();

			String strSecurityType = "";
			String strServiceType = "";
			String strCommunityGender = "";

			if(rs.next()) {
				strSecurityType = rs.getString(1);
				strServiceType = rs.getString(2);
				strCommunityGender = rs.getString(3);			
			}

			// =========================================================
			// 5. 회원권 정책 조회
			// - PRICE : 회원권/예약 가격
			// - RESERVATION_TYPE : 예약형/기간형/구매 후 추가예약형 분기 기준
			// - NEED_TO_PAY : 결제 필요 여부. 1이면 Bootpay 검증과 PARTNER_PAYMENT 저장 필수
			// - NAME : 시설내역/결제항목 표시명으로 사용
			// =========================================================
			String strMembershipIdQuery = "";
			strMembershipIdQuery += "SELECT MEMBERSHIP_ID, PRICE, RESERVATION_TYPE, NEED_TO_PAY, NAME ";
			strMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strMembershipIdQuery += " WHERE 1 = 1 ";
			strMembershipIdQuery += " AND  APT_CODE = " + strAptCode + " ";
			strMembershipIdQuery += " AND  COMMUNITY_TYPE = '" + strAptCommunityType + "' ";

			if(!strMembershipId.contentEquals("")){
				strMembershipIdQuery += " AND  MEMBERSHIP_ID = '" + strMembershipId +"' ";
			}

			printLog("D", "strMembershipIdQuery : " + strMembershipIdQuery);

			pstmt = conn.prepareStatement(strMembershipIdQuery);
			rs = pstmt.executeQuery();
			
			String strPrice = "";
			String strReservationType = "";
			String strSettlementCutoffDay = "";
			String strNeedToPay = "0";
			String strMembershipName = "";

			if(rs.next()) {
				strMembershipId = rs.getString(1);
				strPrice = rs.getString(2);
				strReservationType = rs.getString(3);
				strNeedToPay = rs.getString(4);
				if(strNeedToPay == null || strNeedToPay.contentEquals("")){
					strNeedToPay = "0";
				}
				strMembershipName = rs.getString(5);
			}

			// NEED_TO_PAY = 1이면 유료 결제 플로우
			// 유료 건은 예약/회원권 생성 후 Bootpay 검증·승인,
			// 결제 DB 저장까지 모두 성공해야 commit한다
			boolean isNeedPayment = strNeedToPay.contentEquals("1");
			
			// =========================================================
			// 6. 아파트 커뮤니티 정산 기준일 조회
			// - PARTNER_PAYMENT 저장 후 회원권에 SETTLEMENT_DATE를 계산해서 넣기 위한 기준값
			// - 0이면 말일 정산, 그 외 숫자는 해당 일자 기준 정산
			// =========================================================
			String strSettlementCutoffDayQeury = "";

			strSettlementCutoffDayQeury += " SELECT COMMUNITY_SETTLEMENT_CUTOFF_DAY";
			strSettlementCutoffDayQeury += " FROM APT_CONFIG ";
			strSettlementCutoffDayQeury += " WHERE APT_CODE = " + strAptCode + " ";		

			pstmt = conn.prepareStatement(strSettlementCutoffDayQeury);
			rs = pstmt.executeQuery();

			if(rs.next()) {
				strSettlementCutoffDay = rs.getString(1) != null ? rs.getString(1) : "";
			}

			// 대관 예약은 특정 좌석/장소가 아니라 전체 대관으로 처리하기 위해 PLACE_ALL로 통일
			if(strReservationType.contentEquals(RESERVE_TYPE_RENTAL)){
				strPlace = "PLACE_ALL";
			}

			// =========================================================
			// 7. 예약 중복/시간 충돌 확인
			// - 같은 아파트, 같은 시설, 같은 날짜 기준으로 취소되지 않은 예약을 검사한다.
			// - 대관이 아닌 경우에는 PLACE까지 비교한다.
			// - TIME이 HHmmHHmm 형태이면 기존 예약 시간과 겹치는지도 확인한다.
			// =========================================================
			String strQueryReservationCheck = "";

			strQueryReservationCheck += "SELECT COUNT(*) FROM APT_COMMUNITY_RESERVE ";
			strQueryReservationCheck += "WHERE APT_CODE = '" + strAptCode + "' ";
			strQueryReservationCheck += "AND DATE = '" + strDate + "' ";

			if(strReservationType != null && !strReservationType.contentEquals(RESERVE_TYPE_RENTAL)){
				strQueryReservationCheck += "AND PLACE = '" + strPlace + "' ";
			}

			strQueryReservationCheck += "AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";
			strQueryReservationCheck += "AND RESERVE_CANCEL_TIME IS NULL ";

			if(strCommunityGender != null && !strCommunityGender.contentEquals("0")){
				strQueryReservationCheck += " AND  (GENDER = '0' OR GENDER = '" + strGender + "') ";
			}

			if(strTime.length() == 8){
				// TIME 형식: 시작HHmm + 종료HHmm, 예) 15001600
				// 일반 시간대와 자정 넘어가는 시간대를 나눠서 겹침 조건을 만든다.
				// 예약 시간 충돌 확인 로직 추가
				String startTime = strTime.substring(0, 4);  // ex) "1500"
				String endTime = strTime.substring(4, 8);    // ex) "1600"
				
				String S = "SUBSTRING(TIME,1,4)";
				String E = "SUBSTRING(TIME,5,4)";

				if (startTime.compareTo(endTime) < 0) {
					// 요청 일반
					strQueryReservationCheck += " AND ("
								+ " ( " + S + " < " + E
								+ "   AND " + S + " < '" + endTime + "'"
								+ "   AND " + E + " > '" + startTime + "' )"
								+ " OR ( " + S + " > " + E
								+ "   AND ( " + S + " < '" + endTime + "'"
								+ "      OR " + E + " > '" + startTime + "' ) )"
								+ " )";
				} else {
					// 요청 자정넘음
					strQueryReservationCheck += " AND ("
								+ " ( " + S + " < " + E
								+ "   AND ( " + E + " > '" + startTime + "'"
								+ "      OR " + S + " < '" + endTime + "' ) )"
								+ " OR ( " + S + " > " + E + " )"
								+ " )";
				}
			}
			
			pstmt = conn.prepareStatement(strQueryReservationCheck);
			rs = pstmt.executeQuery();

			int nRet = 0;
			String resultCnt = new String();

			if(rs.next()) {
				resultCnt = rs.getString(1);
			}
			
			// 즉시예약 시설인데 MembershipId가 비어 있으면 해당 시설의 기본 회원권을 하나 찾아서 사용
			if(strServiceType.contentEquals(IMMEDIATE_RESERVE) && strMembershipId.contentEquals("")){
				String strGetMembershipQuery = "";
				strGetMembershipQuery += "SELECT MEMBERSHIP_ID ";
				strGetMembershipQuery += "FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
				strGetMembershipQuery += "WHERE APT_CODE = ? ";
				strGetMembershipQuery += "AND COMMUNITY_TYPE = ? ";
				strGetMembershipQuery += "LIMIT 1 ";
				pstmt = conn.prepareStatement(strGetMembershipQuery);
				pstmt.setString(1,strAptCode);
				pstmt.setString(2,strAptCommunityType);
				rs = pstmt.executeQuery();
				if(rs.next()){
					strMembershipId = rs.getString("MEMBERSHIP_ID");
				}
			}

			// =========================================================
			// 8. 얼굴인식 필수 시설의 사진 등록 여부 확인
			// - SECURITY = 1인 시설은 APT_COMMUNITY_USER_INFO에 IMAGE_URL이 있어야 예약 가능
			// - 사진이 없으면 응답코드 9로 실패 처리
			// =========================================================
			String strQueryImageCheck = "";
			strQueryImageCheck += "SELECT COUNT(*) FROM APT_COMMUNITY_USER_INFO ";
			strQueryImageCheck += " WHERE APT_CODE = " + strAptCode + " ";
			strQueryImageCheck += " AND DONG = '" + strUserDong + "' ";
			strQueryImageCheck += " AND HO = '" + strUserHo + "' ";
			strQueryImageCheck += " AND NAME = '" + strReservationUserName + "' ";
			strQueryImageCheck += " AND IMAGE_URL IS NOT NULL ";

			pstmt = conn.prepareStatement(strQueryImageCheck);
			rs = pstmt.executeQuery();
			
			String resultImageCnt = "";

			if(rs.next()) {
				resultImageCnt = rs.getString(1);
			}

			boolean isSuccess = false;

			if(resultImageCnt.contentEquals("0") && strSecurityType.contentEquals("1")){
				baOutStream.write("9".getBytes(S_CHARSET));
			}else{
				if(resultCnt.contentEquals("0")){
					if(isNeedPayment) {

						if(strPaymentId.contentEquals("") || strReceiptId.contentEquals("") || strTotalPrice.contentEquals("")) {
							
							baOutStream.reset();

							baOutStream.write("0".getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write("결제 정보가 없습니다.".getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write(strEmpty.getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write(strEmpty.getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							returnData(baOutStream, outStream);
							return;
						}

						// 같은 PAYMENT_ID가 이미 PARTNER_PAYMENT에 승인 상태로 저장되어 있는지 확인
						// 중복 승인/중복 예약 생성을 막기 위한 방어 로직
						String strOrderQuery = "";
						strOrderQuery += " SELECT STATE ";
						strOrderQuery += " FROM PARTNER_PAYMENT ";
						strOrderQuery += " WHERE PAYMENT_ID = '" + strPaymentId + "' ";

						pstmt = conn.prepareStatement(strOrderQuery);
						rs = pstmt.executeQuery();

						String strOrderState = "";

						if(rs.next()) {
							strOrderState = rs.getString("STATE") != null ? rs.getString("STATE") : "";
						}

						if(strOrderState.contentEquals("1")) {

							baOutStream.reset();

							baOutStream.write("0".getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write("이미 승인된 결제건입니다.".getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write(strEmpty.getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							baOutStream.write(strEmpty.getBytes(S_CHARSET));
							baOutStream.write(COLUMN_DEL);

							returnData(baOutStream, outStream);
							return;
						}

					}

					printLog( "A", "[STEP 1][START] 예약/회원권 DB 작업 준비"
								+ " - isNeedPayment : " + isNeedPayment
								+ ", membershipId : " + strMembershipId
								+ ", paymentId : " + strPaymentId);

					try { 
						// 결제 여부와 관계없이 예약/회원권 DB 작업을 하나의 트랜잭션으로 묶는다.
						conn.setAutoCommit(false);
						isTransactionStarted = true;

						printLog("A", "[STEP 1][SUCCESS] 트랜잭션 시작 성공" + " - autoCommit : false");
					} catch(Exception transactionStartException) {
						printLog("A", "[STEP 1][FAIL] DB 트랜잭션 시작 실패"
									+ " - message : " + transactionStartException.getMessage()
									+ ", exception : " + transactionStartException.toString());

						throw new Exception("DB 트랜잭션 시작에 실패했습니다.", transactionStartException);
					}


					// =========================================================
					// 10. 예약 INSERT
					// - APT_COMMUNITY_RESERVE에 실제 예약 데이터를 생성한다.
					// - 성공 시 생성된 RESERVE_ID를 조회해 회원권 연결과 응답 데이터 구성에 사용한다.
					// =========================================================
					String strQuery = "";

					strQuery += " INSERT INTO APT_COMMUNITY_RESERVE (COMMUNITY_TYPE, USER_ID, USER_DONG, USER_HO, RESERVE_USER_NAME, RESERVE_USER_PHONE, PLACE, DATE, TIME, APT_CODE, REG_DATE, REG_CHANNEL, USER_NAME, RESERVATION_PEOPLE, GENDER, UUID ) ";
					strQuery +=  " VALUES ('" + strAptCommunityType + "', '" + strUserId  + "', '" + strUserDong +  "', '" + strUserHo + "', '" + strReservationUserName + "', '" + strReservationUserPhone + "', '" + strPlace + "', '" + strDate + "', '" + strTime + "', '" + strAptCode + "', DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), '00', '" +strUserName + "', '" + strPeople + "', '" + strCommunityGender + "', " + strUUID + ")";

					pstmt = conn.prepareStatement(strQuery);
					nRet = pstmt.executeUpdate();

					if(nRet != 1) {
						printLog( "A", "[STEP 2][FAIL] 예약 DB INSERT 실패" + " - nRet : " + nRet);
						throw new Exception("예약 정보 저장에 실패했습니다.");
					}

					isSuccess = true;

					baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));

					printLog("A", "[STEP 2][SUCCESS] 예약 DB INSERT 성공" + " - nRet : " + nRet);

					if(nRet == 1) {
						String strCreatedReservationIdQuery = "";

						strCreatedReservationIdQuery += " SELECT RESERVE_ID ";
						strCreatedReservationIdQuery += " FROM APT_COMMUNITY_RESERVE ";
						strCreatedReservationIdQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
						strCreatedReservationIdQuery += " AND USER_ID = '" + strUserId + "' ";
						strCreatedReservationIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
						strCreatedReservationIdQuery += " AND USER_HO = '" + strUserHo + "' ";
						strCreatedReservationIdQuery += " AND RESERVE_USER_NAME = '" + strReservationUserName + "' ";
						strCreatedReservationIdQuery += " AND DATE = '" + strDate + "' ";
						strCreatedReservationIdQuery += " AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";
						strCreatedReservationIdQuery += " ORDER BY RESERVE_ID DESC LIMIT 1 ";

						pstmt = conn.prepareStatement(strCreatedReservationIdQuery);
						rs = pstmt.executeQuery();

						if(rs.next()) {
							strCreatedReservationId = rs.getString(1);
						}
						printLog("A", "[STEP 2][SUCCESS] 생성된 예약 ID 확인" + " - reservationId : " + strCreatedReservationId);

						if(strCreatedReservationId == null || strCreatedReservationId.contentEquals("")) {
							printLog("A", "[STEP 2][FAIL] 생성된 예약 ID 조회 실패");
							throw new Exception("생성된 예약 ID를 확인할 수 없습니다.");
						}
					}

				}else if(!resultCnt.contentEquals("0")){
					nRet = 2;
					baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
				}
			}		

			// =========================================================
			// 11. 예약 처리 결과 응답 준비 및 후처리용 기본 데이터 조회
			// - 출입문 DOOR_ID 목록은 얼굴인식 API 등록 시 사용
			// - 응답 메시지/예약ID/예약정보는 앱 완료 화면에 표시됨
			// =========================================================
			SimpleDateFormat dateFormatyyyyMMdd = new SimpleDateFormat("yyyyMMdd");
			Calendar today = Calendar.getInstance();

			String strCommunityDoorQuery = "";

			strCommunityDoorQuery += " SELECT DOOR_ID ";
			strCommunityDoorQuery += " FROM APT_COMMUNITY_DOOR ";
			strCommunityDoorQuery += " WHERE 1 = 1 ";
			strCommunityDoorQuery += " AND  ATP_CODE = " + strAptCode + " ";
			strCommunityDoorQuery += " AND  COMMUNITY_TYPE LIKE '%" + strAptCommunityType + "%' ";

			pstmt = conn.prepareStatement(strCommunityDoorQuery);
			rs = pstmt.executeQuery();

			List<String> listDoorIds = new ArrayList<String>();
			String strDoorId = "";

			for(int nRow = 0; rs.next(); nRow++) {
				strDoorId = rs.getString(1);
				listDoorIds.add(strDoorId);
			}

			// 얼굴 인식 기기에 등록 실패한 경우도 실패로 판단해야함
			// 리턴 데이터
			// 등록 성공/실패 여부, 메세지, 예약 아이디, 예약 정보
			String strMessage = "";
			String strReservationId = "";

			// 앱 완료 화면에 보여줄 예약 상세 문자열 조립
			// 형식: 항목명*값*+ 형태로 이어붙여 내려준다.
			String strReservationInfo = "";

			if(nRet == 1){
				strMessage = "예약이 완료되었습니다!";
			}else if(nRet == 2){
				strMessage = "죄송합니다. 선택하신 자리는 이미 예약되었습니다. 다른 자리를 선택해 주세요.";
			}else if(resultImageCnt.contentEquals("0") && strSecurityType.contentEquals("1")){
				strMessage = "예약에 실패했습니다. 얼굴 인식을 위해 사진을 다시 등록해주세요.";
			}else{
				strMessage = "예약에 실패했습니다. 해당 오류가 반복될 경우, 고객센터로 문의주시기 바랍니다.";
			}
			
			String strReservatinIdQuery = "";

			strReservatinIdQuery = "SELECT RESERVE_ID ";
			strReservatinIdQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReservatinIdQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strReservatinIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
			strReservatinIdQuery += " AND USER_HO = '" + strUserHo + "' ";
			strReservatinIdQuery += " AND RESERVE_USER_NAME = '" + strReservationUserName + "' ";
			strReservatinIdQuery += " ORDER BY RESERVE_ID desc LIMIT 1";
			
			pstmt = conn.prepareStatement(strReservatinIdQuery);
			rs = pstmt.executeQuery();

			if(rs.next()) {
				strReservationId = rs.getString(1);
			}

			strReservationInfo = "성함*" + strReservationUserName + "*+";
			strReservationInfo += "동/호수*" + strUserDong + "동 " + strUserHo + "호" + "*+";

			// 시설내역 표시명 결정
			// - PLACE_ALL이면 대관
			// - Place가 있으면 Place 사용
			// - Place가 비어 있으면 회원권명 사용
			String strFacilityName = "";

			if(strPlace != null && strPlace.contentEquals("PLACE_ALL")) {
				strFacilityName = "대관";
			} else if(strPlace != null && !strPlace.contentEquals("")) {
				strFacilityName = strPlace;
			} else if(strMembershipName != null && !strMembershipName.contentEquals("")) {
				strFacilityName = strMembershipName;
			}

			strReservationInfo += "시설내역*" + strFacilityName + "*+";
			strReservationInfo += "날짜/시간*" + formatDate(strDate) + " / " + formatTime(strTime) + "*+" ;

			if(strPeople != null && !strPeople.contentEquals("")){
				if (!strPeople.endsWith("명")) {
					strPeople += "명";
				}
				strReservationInfo +=  "인원 수*" + strPeople + "*+";
			}

			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strMessage.getBytes(S_CHARSET));

			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strReservationId.getBytes(S_CHARSET));
			
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strReservationInfo.getBytes(S_CHARSET));

			printLog("D","strMessage : " +strMessage);
			printLog("D","strReservationId : " +strReservationId);
			printLog("D","strReservationInfo : " +strReservationInfo);		

			if(strTotalPrice != null && !strTotalPrice.contentEquals("")){
				strPrice = strTotalPrice;
			}

			printLog("D","strReservationType : " + strReservationType);

			// =========================================================
			// 12-1. 예약형/대관형 회원권 발급 처리
			// - RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE가 아닌 경우
			// - 예약 날짜/시간 기준으로 PURCHASE_DATE, EXPIRATION_DATE를 만든다.
			// - 회원권 발급 후 예약 테이블에 MEMBERSHIP_ID, MEMBERSHIP_USER_LIST_ID를 연결한다.
			// =========================================================
			if(isSuccess &&
				strMembershipId != null &&
				!strMembershipId.contentEquals("") &&
				strReservationType != null &&
				!strReservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE)) {	

					String strPurchaseDate = strDate + strTime.substring(0,4) + "00" ;
					String strExpirationDate = strDate + strTime.substring(4,8) + "00" ;

					SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmmss");

					String formattedDateHHmm = dateFormatHHmm.format(today.getTime());
					String formattedDateyyyyMMdd = dateFormatyyyyMMdd.format(today.getTime());
					String strRegDate = formattedDateyyyyMMdd + formattedDateHHmm;

					String strMembershipInsertQuery = "INSERT INTO APT_COMMUNITY_MEMBERSHIP_USER_LIST "
					+ "(USER_ID, MEMBERSHIP_ID, PRICE, PURCHASE_DATE, DESCRIPTION, USER_DONG, USER_HO, USER_NAME, APT_CODE, REGISTRATION_DATE, EXPIRATION_DATE, COMMUNITY_TYPE, UUID) "
					+ "VALUES (?, ?, ?, ?,  (SELECT NAME FROM APT_COMMUNITY_MEMBERSHIP_INFO WHERE MEMBERSHIP_ID = ?), ?, ?, ?, ?, ?, ?, ?, ?)";

					pstmt = conn.prepareStatement(strMembershipInsertQuery);
					pstmt.setString(1, strUserId);
					pstmt.setString(2, strMembershipId);
					pstmt.setString(3, strPrice);
					pstmt.setString(4, strRegDate);
					pstmt.setString(5, strMembershipId); // 서브쿼리에서도 같은 값을 사용
					pstmt.setString(6, strUserDong);
					pstmt.setString(7, strUserHo);
					pstmt.setString(8, strReservationUserName);
					pstmt.setString(9, strAptCode);
					pstmt.setString(10, strPurchaseDate);
					pstmt.setString(11, strExpirationDate);
					pstmt.setString(12, strAptCommunityType);
					pstmt.setString(13, strUUID);

					int nRetMembership = pstmt.executeUpdate();

					printLog("A", "[STEP 3][RESULT] 회원권 DB INSERT 결과" + " - nRetMembership : " + nRetMembership);

					if(nRetMembership != 1) {
						printLog("A", "[STEP 3][FAIL] 회원권 DB INSERT 실패" + " - nRetMembership : " + nRetMembership);
						throw new Exception("회원권 발급에 실패했습니다.");
					}

					if(nRetMembership == 1){
						isPurchase = true;

						printLog("A", "[STEP 3][SUCCESS] 회원권 DB INSERT 성공");

						String strLastMembershipIdQuery = "";

						strLastMembershipIdQuery += "SELECT MEMBERSHIP_USER_LIST_ID ";
						strLastMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
						strLastMembershipIdQuery += " WHERE APT_CODE = " + strAptCode + " ";
						strLastMembershipIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
						strLastMembershipIdQuery += " AND USER_HO = '" + strUserHo + "' ";
						strLastMembershipIdQuery += " AND USER_NAME = '" + strReservationUserName + "' ";
						strLastMembershipIdQuery += " ORDER BY MEMBERSHIP_USER_LIST_ID  desc LIMIT 1 ";

						pstmt = conn.prepareStatement(strLastMembershipIdQuery);
						rs = pstmt.executeQuery();

						String strLastMembershipId = "";
						
						if(rs.next()) {
							strLastMembershipId = rs.getString(1);					
						}else {
							strLastMembershipId = "0";
						}

						strMembershipUserListId = strLastMembershipId;

						printLog("A"," strLastMembershipIdQuery1  : " + strLastMembershipIdQuery);

						if(strLastMembershipId != null && !strLastMembershipId.contentEquals("")){
							String strUpdateReservationQuery = "";

							strUpdateReservationQuery += " UPDATE APT_COMMUNITY_RESERVE SET MEMBERSHIP_ID = '" + strMembershipId +"' , MEMBERSHIP_USER_LIST_ID = '" + strLastMembershipId + "' ";
							strUpdateReservationQuery += " WHERE RESERVE_ID = '" + strReservationId + "' " ;

							pstmt = conn.prepareStatement(strUpdateReservationQuery);
							int nUpdateRet = pstmt.executeUpdate();

							if(nUpdateRet != 1) {
								throw new Exception("예약과 회원권 연결에 실패했습니다.");
							}
						}
					}			
				// =========================================================
				// 12-2. 구매 후 추가예약형 회원권 처리
				// - RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE인 경우
				// - 회원권 유효기간 정책을 조회해 현재 시점부터 만료일을 계산한다.
				// - 이미 유효한 회원권이 없거나, 사용횟수 제한을 모두 사용한 경우 새 회원권을 발급한다.
				// - 발급/조회된 MEMBERSHIP_USER_LIST_ID를 예약에 연결한다.
				// =========================================================
				}else if(isSuccess &&
					strMembershipId != null &&
					!strMembershipId.contentEquals("") &&
					strReservationType != null &&
					strReservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE)){	

					String strValidityPeriodQuery = "";

					strValidityPeriodQuery += "SELECT VALIDITY_PERIOD, VALIDITY_PERIOD_UNIT, COMMUNITY_TYPE, USAGE_LIMIT ";
					strValidityPeriodQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
					strValidityPeriodQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

					printLog("A"," strValidityPeriodQuery  : " + strValidityPeriodQuery);

					pstmt = conn.prepareStatement(strValidityPeriodQuery);
					rs = pstmt.executeQuery();

					String strValidityPeriod = "";
					String strValidityPeriodUnit = "";				
					String strCommunityType = "";
					int nUsageLimit = 0;

					if(rs.next()) {
						strValidityPeriod = rs.getString("VALIDITY_PERIOD");	
						strValidityPeriodUnit = rs.getString("VALIDITY_PERIOD_UNIT");
						strCommunityType = rs.getString("COMMUNITY_TYPE");
						nUsageLimit = rs.getInt("USAGE_LIMIT");
					}

					// 이용권 사용기간 가져오기
					int nValidityPeriod = Integer.parseInt(strValidityPeriod);
					
					SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
					SimpleDateFormat sdfyyMMddHHmmss = new SimpleDateFormat("yyMMddHHmmss");
					
					String currentDateTime = sdf.format(new Date());
					String currentDateTimeTID = sdfyyMMddHHmmss.format(new Date());
					String strStartDate = currentDateTime;

					Calendar calendar = Calendar.getInstance();

					if (strValidityPeriodUnit.contentEquals(UNIT_MINUTE)) {
						calendar.add(Calendar.MINUTE, nValidityPeriod); // 분 단위 추가
					} else if (strValidityPeriodUnit.contentEquals(UNIT_HOUR)) {
						calendar.add(Calendar.HOUR_OF_DAY, nValidityPeriod); // 시간 단위 추가
					} else if (strValidityPeriodUnit.contentEquals(UNIT_DAYS)) {
						calendar.add(Calendar.DAY_OF_YEAR, nValidityPeriod); // 일 단위 추가
					} else if (strValidityPeriodUnit.contentEquals(UNIT_MONTH)) {
						calendar.add(Calendar.MONTH, nValidityPeriod); // 월 단위 추가
						calendar.add(Calendar.DAY_OF_YEAR, -1); // 하루 전으로
					} else if (strValidityPeriodUnit.contentEquals(UNIT_YEAR)) {
						calendar.add(Calendar.YEAR, nValidityPeriod); // 연 단위 추가
						calendar.add(Calendar.DAY_OF_YEAR, -1); // 하루 전으로
					}

					SimpleDateFormat sdfExpirationDate = new SimpleDateFormat("yyyyMMdd");
					String strExpirationDate = sdfExpirationDate.format(calendar.getTime());
				
					// 개인정보 사진 만료일까지
					String strEndDate = strExpirationDate + "235959";

					// 회원권 구매하기 전에 이 시설에 이미 등록된 자리가 있는지 확인
					// 동일 사용자/동호수/시설/회원권 기준으로 아직 만료되지 않은 회원권이 있는지 검사한다.
					// 같은 아파트, 같은 시설에 PLACE랑 내가 등록하려는 자리(Seat)이랑 비교
					String strValidityMembershipQuery = "";
					strValidityMembershipQuery += " SELECT COUNT(*) ";
					strValidityMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
					strValidityMembershipQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
					strValidityMembershipQuery += " AND APT_CODE = " + strAptCode + " ";		
					strValidityMembershipQuery += " AND CANCEL_DATE IS NULL ";		
					strValidityMembershipQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";	
					strValidityMembershipQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW()  ";
					strValidityMembershipQuery += " AND USER_DONG = '" + strUserDong + "' ";
					strValidityMembershipQuery += " AND USER_HO = '" + strUserHo + "' ";
					strValidityMembershipQuery += " AND USER_NAME = '" + strReservationUserName + "' ";

					printLog("A"," strValidityMembershipQuery  : " + strValidityMembershipQuery);

					pstmt = conn.prepareStatement(strValidityMembershipQuery);
					rs = pstmt.executeQuery();

					String strValidityMembershipCount = new String();

					if(rs.next()) {
						strValidityMembershipCount = rs.getString(1);	
					}

					// 현재 구매한 회원권이 없는 경우 
					// 내가 구매한 회원권이 있더라도 해당 회원권에 예약 횟수가 있을때 해당 회원권에 최대 횟수랑 예약 횟수가 같으면 
					// 새로운 회원권을 발급
					int ninsertMembershipList = 0;
					int remainingUses = getRemainingUses(conn, strMembershipId, strUserDong, strUserHo, strReservationUserName, strAptCode, nUsageLimit);

					if(strValidityMembershipCount.contentEquals("0") || (nUsageLimit != 0 && remainingUses == 0)){
						String strMembershipPurchaseQuery = "INSERT INTO APT_COMMUNITY_MEMBERSHIP_USER_LIST "
						+ "(USER_ID, MEMBERSHIP_ID, PRICE, PURCHASE_DATE, DESCRIPTION, USER_DONG, USER_HO, USER_NAME, APT_CODE, "
						+ " REGISTRATION_DATE, EXPIRATION_DATE, COMMUNITY_TYPE, USE_COUNT, UUID) "
						+ " VALUES (?, ?, ?, ?,  (SELECT NAME FROM APT_COMMUNITY_MEMBERSHIP_INFO WHERE MEMBERSHIP_ID = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?)";

						pstmt = conn.prepareStatement(strMembershipPurchaseQuery);
						pstmt.setString(1, strUserId);
						pstmt.setString(2, strMembershipId);
						pstmt.setString(3, strPrice);
						pstmt.setString(4, strStartDate);
						pstmt.setString(5, strMembershipId); // 서브쿼리에서도 같은 값을 사용
						pstmt.setString(6, strUserDong);
						pstmt.setString(7, strUserHo);
						pstmt.setString(8, strReservationUserName);
						pstmt.setString(9, strAptCode);
						pstmt.setString(10, strStartDate);
						pstmt.setString(11, strEndDate);
						pstmt.setString(12, strCommunityType);				
						pstmt.setString(13, "1");
						pstmt.setString(14, strUUID);

						ninsertMembershipList = pstmt.executeUpdate();

						if(ninsertMembershipList == 1){
							isPurchase = true;
						}
					}

					if(nRet == 1){
						String strLastMembershipIdQuery = "";

						strLastMembershipIdQuery += "SELECT MEMBERSHIP_USER_LIST_ID ";
						strLastMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
						strLastMembershipIdQuery += " WHERE APT_CODE = " + strAptCode + " ";
						strLastMembershipIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
						strLastMembershipIdQuery += " AND USER_HO = '" + strUserHo + "' ";
						strLastMembershipIdQuery += " AND USER_NAME = '" + strReservationUserName + "' ";
						strLastMembershipIdQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
						strLastMembershipIdQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";	
						strLastMembershipIdQuery += " ORDER BY MEMBERSHIP_USER_LIST_ID  desc LIMIT 1 ";

						pstmt = conn.prepareStatement(strLastMembershipIdQuery);
						rs = pstmt.executeQuery();

						String strLastMembershipId = "";
						
						if(rs.next()) {
							strLastMembershipId = rs.getString(1);	
						}else {
							strLastMembershipId = "0";
						}

						strMembershipUserListId = strLastMembershipId;

						printLog("A"," strLastMembershipIdQuery2  : " + strLastMembershipIdQuery);


						if(strLastMembershipId != null && !strLastMembershipId.contentEquals("")){
							String strUpdateReservationQuery = "";

							strUpdateReservationQuery += " UPDATE APT_COMMUNITY_RESERVE SET MEMBERSHIP_ID = '" + strMembershipId +"' , MEMBERSHIP_USER_LIST_ID = '" + strLastMembershipId + "' ";
							strUpdateReservationQuery += " WHERE RESERVE_ID = '" + strReservationId + "' " ;

							pstmt = conn.prepareStatement(strUpdateReservationQuery);
							int nUpdateRet = pstmt.executeUpdate();

							printLog("A", "[STEP 3][RESULT] 예약-회원권 연결 UPDATE 결과" + " - nUpdateRet : " + nUpdateRet);

							if(nUpdateRet != 1) {
								printLog("A", "[STEP 3][FAIL] 예약-회원권 연결 실패" + " - reservationId : " + strReservationId
																				+ ", membershipUserListId : " + strLastMembershipId);
								throw new Exception("예약과 회원권 연결에 실패했습니다.");
							}

							printLog("A", "[STEP 3][SUCCESS] 예약-회원권 연결 성공" + " - reservationId : " + strReservationId
																				+ ", membershipUserListId : " + strLastMembershipId);
						}
					}
				}

			// =========================================================
			// 13. 유료 예약 결제 검증 및 결제 DB 저장
			// - 예약과 회원권 생성 완료 후 Bootpay 영수증을 검증한다.
			// - 검증 성공 후 결제를 승인하고 PARTNER_PAYMENT에 저장한다.
			// =========================================================
			if(isNeedPayment && isSuccess && nRet == 1) {

				printLog("A", "[STEP 4][START] DB 작업 완료 후 결제 준비"
							+ " - isSuccess : " + isSuccess
							+ ", nRet : " + nRet
							+ ", isPurchase : " + isPurchase
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId
							+ ", totalPrice : " + strTotalPrice);

				if(!isPurchase) {
					throw new Exception("결제 필요 건인데 회원권 발급 처리에 실패했습니다.");
				}

				if(strMembershipUserListId == null || strMembershipUserListId.contentEquals("") || strMembershipUserListId.contentEquals("0")) {
					throw new Exception("결제 필요 건인데 회원권 사용자 ID가 없습니다.");
				}

				printLog("A", "[STEP 4][SUCCESS] 예약/회원권 DB 작업 완료, 결제 검증 진행 가능" + " - reservationId : " + strReservationId 
																						+ ", membershipUserListId : " + strMembershipUserListId);

				printLog("A", "[STEP 5][START] Bootpay 결제 verify 시작" + " - receiptId : " + strReceiptId + ", expectedPrice : " + strTotalPrice);

printLog( "A", "*** time test - " + strPaymentId + " : 2 결제검증 시작(우회구간)");

				// 1. 승인 전 영수증 검증
				boolean isVerifiedPayment = verifyPayment(strReceiptId, "2", strTotalPrice);

printLog("A",  "*** time test - " + strPaymentId + " : 3 결제검증 종료(우회구간)");

				if(!isVerifiedPayment) {
					printLog("A", "[STEP 5][FAIL] Bootpay 결제 verify 실패" + " - receiptId : " + strReceiptId + ", expectedPrice : " + strTotalPrice);

					throw new Exception("결제 검증에 실패했습니다.");
				}

				printLog("A", "[STEP 5][SUCCESS] Bootpay 결제 verify 성공" + " - receiptId : " + strReceiptId + ", price : " + strTotalPrice);

				printLog("A", "[STEP 6][START] Bootpay 결제 confirm 시작"
							+ " - paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId
							+ ", price : " + strTotalPrice);

printLog("A", "*** time test - " + strPaymentId + " : 4 결제컨펌 시작(우회구간)");

				JSONObject jsonConfirmResult = confirmBootpayPayment(strPaymentId, strReceiptId, strTotalPrice);

printLog("A", "*** time test - " + strPaymentId + " : 5 결제컨펌 종료(우회구간)");

				if(jsonConfirmResult == null) {
					printLog( "A",  "[STEP 6][FAIL] Bootpay 결제 confirm 실패"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId);

					throw new Exception("결제 승인에 실패했습니다.");
				}

				// 이 값은 반드시 confirm 성공 후에만 true
				isPaymentConfirmed = true;

				// confirm 응답에서 바로 결제 부가정보 추출
				strReceiptUrl = jsonConfirmResult.get("receipt_url") != null ? jsonConfirmResult.get("receipt_url").toString() : "";
				String strPurchasedAt = jsonConfirmResult.get("purchased_at") != null ? jsonConfirmResult.get("purchased_at").toString() : "";
				strPurchasedDate = convertBootpayDateToDBFormat(strPurchasedAt);

				printLog("A", "[STEP 6][SUCCESS] Bootpay 결제 confirm 성공"
							+ " - paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId
							+ ", receiptUrlExists : " + !strReceiptUrl.contentEquals("")
							+ ", purchasedDate : " + strPurchasedDate);

				// 결제내역 상세에 표시할 항목 문자열
				// 형식: 회원권명*가격*+
				String strPaymentItem = strMembershipName + "*" + strPrice + "*+";
				String strInsertPaymentQuery = "";
				strInsertPaymentQuery += "INSERT INTO PARTNER_PAYMENT ";
				strInsertPaymentQuery += " (PAYMENT_ID, RESERVATION_ID, PRICE, TOTAL_PRICE, STATE, DATE, COMMENT, IMAGE, PAYMENT_ITEM, COUPON_USE, INSPECTION, MENU_ID, RECEIPT_ID, USER_ID, RECEIPT_URL, PURCHASED_DATE )";
				strInsertPaymentQuery += " VALUES('" + strPaymentId  + "', ";
				strInsertPaymentQuery += strMembershipUserListId + ", ";
				strInsertPaymentQuery += "'" + strPrice + "', "; // PRICE
				strInsertPaymentQuery += "'" + strPrice + "', "; // TOTAL PRICE
				strInsertPaymentQuery += "'1', ";
				strInsertPaymentQuery += "DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ";
				strInsertPaymentQuery += "'', ";
				strInsertPaymentQuery += "'', ";
				strInsertPaymentQuery += "'" + strPaymentItem + "', ";
				strInsertPaymentQuery += "'0', ";
				strInsertPaymentQuery += "'0', ";
				strInsertPaymentQuery += "'49', ";
				strInsertPaymentQuery += "'" + strReceiptId + "', ";
				strInsertPaymentQuery += "'" + strUserId + "', ";
				strInsertPaymentQuery += "'" + strReceiptUrl + "', ";
				strInsertPaymentQuery += "'" + strPurchasedDate + "' ";
				strInsertPaymentQuery += ")";

				pstmt = conn.prepareStatement(strInsertPaymentQuery);

				printLog("A", "[STEP 7][START] PARTNER_PAYMENT INSERT 시작"
								+ " - paymentId : " + strPaymentId
								+ ", membershipUserListId : " + strMembershipUserListId
								+ ", receiptId : " + strReceiptId);

				int nPaymentRet = pstmt.executeUpdate();

				printLog("A", "[STEP 7][RESULT] PARTNER_PAYMENT INSERT 결과" + " - nPaymentRet : " + nPaymentRet);

				if(nPaymentRet != 1) {
					printLog("A", "[STEP 7][FAIL] PARTNER_PAYMENT INSERT 실패" + " - paymentId : " + strPaymentId);

					throw new Exception("결제 정보 저장에 실패했습니다.");
				}

				isPaymentSaved = true;

				// 결제 저장 성공 후 회원권에 정산 예정일을 기록
				// cutoffDay = 0이면 해당 월 말일, 오늘이 기준일 이후면 다음 달 기준일로 계산
				if(strSettlementCutoffDay != null && !strSettlementCutoffDay.isEmpty()) {
					String strSettlementDate = "";
					int cutoffDay = Integer.parseInt(strSettlementCutoffDay);

					Calendar cal = Calendar.getInstance();
					int todaySettlement = cal.get(Calendar.DAY_OF_MONTH);

					if(cutoffDay == 0) {
						cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
					} else if(todaySettlement <= cutoffDay) {
						cal.set(Calendar.DAY_OF_MONTH, cutoffDay);
					} else {
						cal.add(Calendar.MONTH, 1);
						cal.set(Calendar.DAY_OF_MONTH, cutoffDay);
					}

					SimpleDateFormat sdfyyyyMMdd = new SimpleDateFormat("yyyyMMdd");
					strSettlementDate = sdfyyyyMMdd.format(cal.getTime());

					String strMembershipSettlementupdateQuery = "";
					strMembershipSettlementupdateQuery += "UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET";
					strMembershipSettlementupdateQuery += " SETTLEMENT_DATE = '" + strSettlementDate + "' ";
					strMembershipSettlementupdateQuery += " WHERE MEMBERSHIP_USER_LIST_ID = '" + strMembershipUserListId + "' ";

					pstmt = conn.prepareStatement(strMembershipSettlementupdateQuery);
					int nSettlement = pstmt.executeUpdate();


					if(nSettlement != 1) {
						throw new Exception("회원권 정산일 저장에 실패했습니다.");
					}
				}
			}

			printLog("A", "[STEP 8][CHECK] 최종 commit 조건 확인"
						+ " - isTransactionStarted : " + isTransactionStarted
						+ ", isNeedPayment : " + isNeedPayment
						+ ", isSuccess : " + isSuccess
						+ ", nRet : " + nRet
						+ ", isPurchase : " + isPurchase
						+ ", isPaymentConfirmed : " + isPaymentConfirmed
						+ ", isPaymentSaved : " + isPaymentSaved);

			// =========================================================
			// 14. 최종 COMMIT
			// 예약 INSERT, 회원권 INSERT, 결제 INSERT, 정산일 UPDATE가 전부 성공했을 때만 DB 반영

			// 무료/유료 공통: 예약 INSERT가 성공해야 함
			if(!isSuccess || nRet != 1) {
				printLog("A", "[STEP 8][FAIL] 최종 실패 - 예약 저장 미완료"
								+ " - isSuccess : " + isSuccess
								+ ", nRet : " + nRet);
				throw new Exception("예약 처리가 정상적으로 완료되지 않았습니다.");
			}

			// 유료 결제 건: 회원권, Bootpay 승인, 결제 DB 저장까지 전부 성공해야 함
			if(isNeedPayment) {

				if(!isPurchase) {
					printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 발급 미완료");
					throw new Exception("결제 필요 건인데 회원권 발급이 완료되지 않았습니다.");
				}

				if(strMembershipUserListId == null
					|| strMembershipUserListId.contentEquals("")
					|| strMembershipUserListId.contentEquals("0")) {

					printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 사용자 ID 없음" + " - membershipUserListId : " + strMembershipUserListId);

					throw new Exception("결제 필요 건인데 회원권 사용자 ID가 없습니다.");
				}

				if(!isPaymentConfirmed) {
					printLog("A", "[STEP 8][FAIL] 최종 실패 - Bootpay 승인 미완료");
					throw new Exception("결제 승인이 완료되지 않았습니다.");
				}

				if(!isPaymentSaved) {
					printLog("A", "[STEP 8][FAIL] 최종 실패 - 결제 DB 저장 미완료");
					throw new Exception("결제 필요 건인데 결제 정보 저장이 완료되지 않았습니다.");
				}
			}

			printLog("A", "COMMIT 직전 - isNeedPayment : " + isNeedPayment + ", isPaymentSaved : " + isPaymentSaved);

			// 위 조건을 모두 통과한 경우에만 DB 반영
			if(isTransactionStarted) {
				printLog("A", "[STEP 8][START] 모든 작업 성공, DB COMMIT 시작"
								+ " - reservationId : " + strReservationId
								+ ", membershipUserListId : " + strMembershipUserListId
								+ ", paymentId : " + strPaymentId);
				
				conn.commit();

				// 반드시 commit 성공 후에만 true
				isDbCommitted = true;

				// 앱 응답 후 후처리를 실행할 수 있도록 설정
				shouldRunPostProcess = true;

printLog("A", "*** time test - " + strPaymentId + " : 6 예약처리 완료");

				printLog("A", "[STEP 8][SUCCESS] 전체 처리 완료 및 DB COMMIT 성공"
								+ " - isSuccess : " + isSuccess
								+ ", isPurchase : " + isPurchase
								+ ", isPaymentConfirmed : " + isPaymentConfirmed
								+ ", isPaymentSaved : " + isPaymentSaved);

				// =========================================================
				// COMMIT 직후 autoCommit 원복
				// =========================================================
				conn.setAutoCommit(true);
				isAutoCommitRestored = true;

				printLog("A", "[TRANSACTION][END] reservation_community_schedule autoCommit 원복 성공");

				// =========================================================
				// 앱에 예약 성공 응답 먼저 전송
				// =========================================================
				returnData(baOutStream, outStream);

				printLog("A", "[RESPONSE][SUCCESS] reservation_community_schedule 앱 응답 전송 완료"
							+ " - reservationId : " + strReservationId
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", paymentId : " + strPaymentId);
			}

			if(shouldRunPostProcess) {

				try {

					printLog("A", "[POST_PROCESS][IOT][START] IoT 전원 제어 시작"
								+ " / reservationId : " + strReservationId
								+ " / aptCode : " + strAptCode
								+ " / communityType : " + strAptCommunityType);

					String strToday = dateFormatyyyyMMdd.format(today.getTime());

					if(strToday.contentEquals(strDate)) {

						if(strTime != null && strTime.length() == 8) {

							String strStartTime = strTime.substring(0, 4);

							String strEndTime = strTime.substring(4, 8);

							SimpleDateFormat sdfNowTime = new SimpleDateFormat("HHmm");

							String strNowTime = sdfNowTime.format(today.getTime());

							if(isTimeWithinRange(strNowTime, strStartTime, strEndTime)) {

								String strIoTQuery = "";
								strIoTQuery += " SELECT COUNT(*) ";
								strIoTQuery += " FROM IoT_TOKEN ";
								strIoTQuery += " WHERE APT_CODE = " + strAptCode + " ";
								strIoTQuery += " AND COMMUNITY_TYPE LIKE '%" + strAptCommunityType + "%' ";

								pstmt = conn.prepareStatement(strIoTQuery);

								rs = pstmt.executeQuery();

								String strCount = "0";

								if(rs.next()) {
									strCount = rs.getString(1) != null ? rs.getString(1) : "0";
								}

								if("1".contentEquals(strCount)) {

									String strFaceRecognitionUsageQuery = "";
									strFaceRecognitionUsageQuery += " SELECT SECURITY ";
									strFaceRecognitionUsageQuery += " FROM APT_COMMUNITY ";
									strFaceRecognitionUsageQuery += " WHERE APT_CODE = " + strAptCode + " ";
									strFaceRecognitionUsageQuery += " AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";

									pstmt = conn.prepareStatement(strFaceRecognitionUsageQuery);

									rs = pstmt.executeQuery();

									String strFaceRecognitionUsage = "0";

									if(rs.next() && rs.getString(1) != null) {

										strFaceRecognitionUsage = rs.getString(1);
									}

									if("0".contentEquals(strFaceRecognitionUsage)) {

										String baseUrl = "http://146.56.179.38/xmobile/villizinei/iot/power_automation_service.jsp";

										URL url = new URL(baseUrl);

										HttpURLConnection connAPI = (HttpURLConnection)url.openConnection();

										connAPI.setRequestMethod("POST");

										int responseCode = connAPI.getResponseCode();

										printLog("A", "[POST_PROCESS][IOT][SUCCESS] IoT 전원 제어 요청 완료"
													+ " / responseCode : " + responseCode
													+ " / reservationId : " + strReservationId);
									}
								}
							}
						}
					}

				} catch(Exception iotException) {

					printLog("A", "[POST_PROCESS][IOT][FAIL] IoT 전원 제어 실패"
								+ " / reservationId : " + strReservationId
								+ " / exception : " + iotException.toString());
				}

printLog("A", "*** time test - " + strPaymentId + " : 7 IoT 처리 종료");
			}

			if(shouldRunPostProcess) {

				try {

					printLog("A", "[POST_PROCESS][PUSH][START] 예약·결제와 별개로 푸시 처리 시작"
								+ " / reservationId : " + strReservationId
								+ " / aptCode : " + strAptCode
								+ " / communityType : " + strAptCommunityType);

					String strPushQuery = "";
					strPushQuery += " SELECT COUNT(*) ";
					strPushQuery += " FROM APT_COMMUNITY ";
					strPushQuery += " WHERE APT_CODE = " + strAptCode + " ";
					strPushQuery += " AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";
					strPushQuery += " AND PUSH_NOTI_CODE IN (1,4,9) ";

					pstmt = conn.prepareStatement(strPushQuery);

					rs = pstmt.executeQuery();

					String strPushNotiCode = "0";

					if(rs.next()) {
						strPushNotiCode = rs.getString(1) != null ? rs.getString(1) : "0";
					}

					if(!"0".contentEquals(strPushNotiCode)) {

						String strCommunityCenterNameQuery = "";
						strCommunityCenterNameQuery += " SELECT TITLE ";
						strCommunityCenterNameQuery += " FROM APT_COMMUNITY ";
						strCommunityCenterNameQuery += " WHERE APT_CODE = " + strAptCode + " ";
						strCommunityCenterNameQuery += " AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";

						pstmt = conn.prepareStatement(strCommunityCenterNameQuery);

						rs = pstmt.executeQuery();

						String strCommunityCenterName = "커뮤니티센터";

						if(rs.next() && rs.getString(1) != null) {

							strCommunityCenterName = rs.getString(1);
						}

						String strMsg = strUserDong + "동 "
									+ strUserHo + "호 "
									+ strReservationUserName + "님이 "
									+ strCommunityCenterName
									+ "을(를) 예약하셨습니다.";

						RequestDispatcher dispatcher = request.getRequestDispatcher("push_send_service.jsp");

						request.setAttribute("SID", new String(strSID));
						request.setAttribute("Community_AptCode", new String(strAptCode));
						request.setAttribute("Community_Msg", new String(strMsg));

						dispatcher.include(request, response);

						printLog("A", "[POST_PROCESS][PUSH][SUCCESS] 푸시 처리 성공" + " / reservationId : " + strReservationId);

					} else {

						printLog("A", "[POST_PROCESS][PUSH][SKIP] 푸시 발송 대상 시설 아님"
									+ " / aptCode : " + strAptCode
									+ " / communityType : " + strAptCommunityType
									+ " / reservationId : " + strReservationId);
					}

				} catch(Exception pushException) {

					printLog("A", "[POST_PROCESS][PUSH][FAIL] 푸시 처리 실패"
								+ " / reservationId : " + strReservationId
								+ " / exception : " + pushException.toString());
				}

printLog("A", "*** time test - " + strPaymentId + " : 8 푸시 처리 종료");
			}

			if(shouldRunPostProcess) {

				try {

					printLog("A", "[POST_PROCESS][DOOR][START] 얼굴 출입 등록 시작"
								+ " / reservationId : " + strReservationId
								+ " / uuid : " + strUUID
								+ " / doorCount : " + listDoorIds.size());

					if(!"1".contentEquals(strSecurityType)) {

						printLog("A", "[POST_PROCESS][DOOR][SKIP] 얼굴인식 미사용 시설" + " / reservationId : " + strReservationId);

					} else if(listDoorIds.size() == 0) {

						printLog("A", "[POST_PROCESS][DOOR][SKIP] 등록 대상 출입문 없음" + " / reservationId : " + strReservationId);

					} else {

						String strRegTime = strTime;

						if(strTime != null && !strTime.contentEquals("")) {

							strRegTime = "00112349";
						}

						String strTodayReservationCountyQuery = "";
						strTodayReservationCountyQuery += " SELECT COUNT(*) ";
						strTodayReservationCountyQuery += " FROM APT_COMMUNITY_RESERVE ";
						strTodayReservationCountyQuery += " WHERE USER_DONG = '" + strUserDong + "' ";
						strTodayReservationCountyQuery += " AND USER_HO = '" + strUserHo + "' ";
						strTodayReservationCountyQuery += " AND USER_NAME = '" + strReservationUserName + "' ";
						strTodayReservationCountyQuery += " AND DATE = '" + strDate + "' ";
						strTodayReservationCountyQuery += " AND COMMUNITY_TYPE = '" + strAptCommunityType + "' ";
						strTodayReservationCountyQuery += " AND APT_CODE = '" + strAptCode + "' ";

						if(strCommunityGender != null && !"0".contentEquals(strCommunityGender)) {

							strTodayReservationCountyQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
						}

						pstmt = conn.prepareStatement(strTodayReservationCountyQuery);

						rs = pstmt.executeQuery();

						String strTodayReservationCount = "0";

						if(rs.next()) {
							strTodayReservationCount = rs.getString(1) != null ? rs.getString(1) : "0";
						}

						String strToday = dateFormatyyyyMMdd.format(today.getTime());

						if(strToday.contentEquals(strDate)) {

							for(
								int nDoorId = 0;
								nDoorId < listDoorIds.size();
								nDoorId++
							) {

								callDevReservationAPI(strUserId,
														strReservationUserName,
														strReservationUserPhone,
														strDate,
														strRegTime,
														listDoorIds.get(nDoorId),
														strAptCode,
														conn,
														strAptCommunityType,
														strUserDong,
														strUserHo);
							}

							printLog("A", "[POST_PROCESS][DOOR][SUCCESS] 얼굴 출입 등록 성공"
										+ " / reservationId : " + strReservationId
										+ " / doorCount : " + listDoorIds.size());

						} else {

							printLog("A", "[POST_PROCESS][DOOR][SKIP] 오늘 예약이 아니므로 스케줄러 처리"
										+ " / reservationDate : " + strDate
										+ " / reservationId : " + strReservationId);
						}
					}

				} catch(Exception doorException) {

					printLog("A", "[POST_PROCESS][DOOR][FAIL] 얼굴 출입 등록 실패"
								+ " / reservationId : " + strReservationId
								+ " / exception : " + doorException.toString());
				}

printLog("A", "*** time test - " + strPaymentId + " : 9 얼굴등록 처리 종료");
			}

		} catch(Exception e) {
			// =========================================================
			// 예외 처리
			// - 트랜잭션이 시작된 경우 DB rollback
			// - 오류 원인을 로그로 남기고 앱에 실패 응답 반환
			// - finally에서 autoCommit을 원복
			// =========================================================
			printLog("A", "[FAIL] reservation_community_schedule 전체 처리 실패"
							+ " - message : " + e.getMessage()
							+ ", exception : " + e.toString()
							+ ", isTransactionStarted : " + isTransactionStarted
							+ ", isPaymentConfirmed : " + isPaymentConfirmed
							+ ", isPaymentSaved : " + isPaymentSaved
							+ ", reservationId : " + strCreatedReservationId
							+ ", membershipUserListId : " + strCreatedMembershipUserListId
							+ ", paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId);

			try {
				if(isTransactionStarted && !isDbCommitted) {

					printLog("A", "[ROLLBACK][START] DB 트랜잭션 rollback 시작"
									+ " - reservationId : " + strCreatedReservationId
									+ ", membershipUserListId : " + strCreatedMembershipUserListId
									+ ", paymentId : " + strPaymentId);

					conn.rollback();

					printLog("A", "[ROLLBACK][SUCCESS] DB 트랜잭션 rollback 성공"
									+ " - reservationId : " + strCreatedReservationId
									+ ", membershipUserListId : " + strCreatedMembershipUserListId);
				}
			} catch(Exception rollbackException) {

				printLog("A", "[ROLLBACK][FAIL] DB 트랜잭션 rollback 실패"
								+ " - message : " + rollbackException.getMessage()
								+ ", exception : " + rollbackException.toString());
			}

			if(isPaymentConfirmed && !isDbCommitted) {

				try {

					printLog("A", "[COMPENSATION][START] Bootpay 승인 결제 보상 취소 시작"
								+ " - paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId
								+ ", totalPrice : " + strTotalPrice);

					String strCancelResult = cancelBootpayPaymentByReceiptId(strReceiptId, strTotalPrice);

					if("1".contentEquals(strCancelResult)) {

						printLog("A", "[COMPENSATION][SUCCESS] Bootpay 승인 결제 보상 취소 성공"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId);

					} else {

						printLog("A", "[COMPENSATION][FAIL] Bootpay 승인 결제 보상 취소 실패"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", cancelResult : " + strCancelResult);
					}

				} catch(Exception compensationException) {

					printLog("A", "[COMPENSATION][ERROR] Bootpay 보상 취소 중 예외"
								+ " - paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId
								+ ", exception : " + compensationException.toString());
				}
			}

			if(!isDbCommitted) {
				try {
					baOutStream.reset();

					baOutStream.write("0".getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					String strErrorMessage = e.getMessage() != null ? e.getMessage() : "예약 처리 중 오류가 발생했습니다.";

					baOutStream.write(strErrorMessage.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					returnData(baOutStream, outStream);

				} catch(Exception responseException) {
					printLog("A", "reservation_community_schedule response Exception : " + responseException.toString());
				}
			}
		}
		finally {
			// 트랜잭션을 시작했던 요청은 커넥션 재사용에 영향이 없도록 AutoCommit을 원복한다.
			try {
				if(isTransactionStarted && !isAutoCommitRestored) {

					conn.setAutoCommit(true);

					isAutoCommitRestored = true;

					printLog("A", "[TRANSACTION][END] reservation_community_schedule autoCommit 원복 성공");
				}
			} catch(Exception autoCommitException) {
				printLog("A", "[TRANSACTION][FAIL] reservation_community_schedule autoCommit 원복 실패" + " - exception : " + autoCommitException.toString());
			}
		}	
	} else if(strSID.contentEquals("create_partner_payment")) {
		String strUserId = getRequestParam(request, "UserId");
		String strAptCode = getRequestParam(request, "AptCode");
		String strPrice = getRequestParam(request, "Price");

		if(strUserId == null) strUserId = "";
		if(strAptCode == null) strAptCode = "";
		if(strPrice == null) strPrice = "";

		strPrice = strPrice.replace("원", "").replace(",", "").trim();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		String strPaymentId = "0";
		String strResult = "0";
		String strMessage = "";

		try {

			 {

				// USER_INFO에서 UUID 조회
				String strUserUUID = "0";

				String strUserUUIDQuery = "";
				strUserUUIDQuery += " SELECT UUID ";
				strUserUUIDQuery += " FROM USER_INFO ";
				strUserUUIDQuery += " WHERE USER_ID = ? ";
				strUserUUIDQuery += " AND APT_CODE = ? ";
				strUserUUIDQuery += " LIMIT 1 ";

				pstmt = conn.prepareStatement(strUserUUIDQuery);
				pstmt.setString(1, strUserId);
				pstmt.setString(2, strAptCode);
				rs = pstmt.executeQuery();

				if(rs.next()) {
					strUserUUID = rs.getString("UUID");

					if(strUserUUID == null || strUserUUID.contentEquals("")) {
						strUserUUID = "0";
					}
				}


				if(rs != null) {
					rs.close();
					rs = null;
				}

				if(pstmt != null) {
					pstmt.close();
					pstmt = null;
				}

				// 결제 ID 생성
				for(int nCnt = 0; nCnt < 5; nCnt++) {
					String strTempID = "49" + strUserUUID + createDateTimeId();
					// 메뉴아이디 (2자리) + UUID(19자리) + 일시(15자리) = 36자리
					String strQueryOrderID = "";
					strQueryOrderID += " SELECT COUNT(*) ";
					strQueryOrderID += " FROM PARTNER_PAYMENT ";
					strQueryOrderID += " WHERE PAYMENT_ID = ? ";
			
					pstmt = conn.prepareStatement(strQueryOrderID);
					pstmt.setString(1, strTempID);
					rs = pstmt.executeQuery();
		
					if(rs.next()) {
						String strData = rs.getString(1);
						if(strData == null) {
							strData = "";
						}
						if(strData.contentEquals("0")) {
							strPaymentId = strTempID;
							break;
						}
					}

					if(rs != null) {
						rs.close();
						rs = null;
					}

					if(pstmt != null) {
						pstmt.close();
						pstmt = null;
					}
				}

				if(strPaymentId.contentEquals("0")) {
					strMessage = "결제 ID 생성에 실패했습니다.";

				} else {

						strResult = "1";
						strMessage = "결제 ID 생성 성공";


				}
			}

		} catch(Exception e) {
			strResult = "0";
			strPaymentId = "0";
			strMessage = "결제건 생성 중 오류가 발생했습니다.";

			printLog("A", "create_partner_payment error : " + e.getMessage());
		}

		baOutStream.write(strResult.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strPaymentId.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strMessage.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);

		returnData(baOutStream, outStream);
	}else if(strSID.contentEquals("get_reservation_notice")){
		String strCommunityType = getRequestParam(request,"CommunityType");	
		String strAptCode = getRequestParam(request, "AptCode");		
		String strMembershipId = getRequestParam(request, "MembershipId");

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

		String strNoticeQuery = "";
		strNoticeQuery += "SELECT TITLE ";
		strNoticeQuery += "FROM APT_COMMUNITY ";
		strNoticeQuery += "WHERE APT_CODE = " + strAptCode + " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
		
		pstmt = conn.prepareStatement(strNoticeQuery);
		rs = pstmt.executeQuery();

		String strReservationNotice = new String();
		String strTitle = "";

		if(rs.next()) {
			strTitle = rs.getString(1);
		}

		String strMembershipNoticeQuery = "";
		strMembershipNoticeQuery += " SELECT RESERVATION_INFORMATION ";
		strMembershipNoticeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipNoticeQuery += " WHERE MEMBERSHIP_ID = ? ";

		pstmt = conn.prepareStatement(strMembershipNoticeQuery);
		pstmt.setString(1, strMembershipId);
		rs = pstmt.executeQuery();


		if(rs.next()) {
			strReservationNotice = rs.getString("RESERVATION_INFORMATION") != null ? rs.getString("RESERVATION_INFORMATION") : "";
		}
				
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		
		baOutStream.write(strTitle.getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
		baOutStream.write(strReservationNotice.getBytes(S_CHARSET));
 		baOutStream.write(COLUMN_DEL);

		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);

	}else if(strSID.contentEquals("get_community_available_seat")){
		String strAptCode = getRequestParam(request, "AptCode");		
		String strCommunityType = getRequestParam(request, "CommunityType");		
		String strMembershipId = getRequestParam(request, "MembershipId");		
		String strOptionId = getRequestParam(request, "OptionId");		
		String strUserId = getRequestParam(request, "UserId");		
		String strUUID = getRequestParam(request, "UUID");		
		String strDong = getRequestParam(request, "UserDong");	
		String strUserName 	= getRequestParam(request, "UserName");
		String strHo = getRequestParam(request, "UserHo");
		String strGender = getRequestParam(request, "Gender");
		String strReservationId = getRequestParam(request, "ReservationId");
		String strValidityDateFrom = getRequestParam(request, "ValidityDateFrom");
		String strValidityDateTo = getRequestParam(request, "ValidityDateTo");

		// 20260305 
		// 성별을 쓰는 시설이거나 회원권인경우는 
		// 예약내역에서 해당 성별이랑 비교해서 보여주기

		String strCommunityGender = "";
		String strMembershipGender = "";

		


		if(strMembershipId == null){
			strMembershipId = "";
		}
		if(strOptionId == null){
			strOptionId = "";
		}

		// 일일이용가능 횟수 제한 
		// 독서실 이용중인 경우 사용중 처리
		// 

		if(strReservationId == null){
			strReservationId = "";
		}

		if(strValidityDateFrom == null || strValidityDateFrom.contentEquals("")){
			strValidityDateFrom = "";
		}
		if(strValidityDateTo == null || strValidityDateTo.contentEquals("")){
			strValidityDateTo = strValidityDateFrom;
		}

		if(strValidityDateFrom != null && strValidityDateFrom.length() == 8){
			strValidityDateFrom = strValidityDateFrom + "000000";
		}
		if(strValidityDateTo != null && strValidityDateTo.length() == 8){
			strValidityDateTo = strValidityDateTo + "235959";
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
	
		if(strMembershipId != null && !strMembershipId.contentEquals("")){
			String strTypeQuery = "";
			strTypeQuery += " SELECT COMMUNITY_TYPE, VALIDITY_DATE_FROM, VALIDITY_DATE_TO, GENDER ";
			strTypeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strTypeQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

			pstmt = conn.prepareStatement(strTypeQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strCommunityType = rs.getString(1);				
				String dbDateFrom = rs.getString(2);
				String dbDateTo = rs.getString(3);

				if(dbDateFrom != null && !dbDateFrom.contentEquals("")){
					strValidityDateFrom = dbDateFrom;
				}
				if(dbDateTo != null && !dbDateTo.contentEquals("")){
					strValidityDateTo = dbDateTo;
				}
				strMembershipGender = rs.getString(4) != null ? rs.getString(4) : "0";
			}	
		}

		String strImpossiblePlaceQuery = "";
		strImpossiblePlaceQuery += "SELECT IMPOSSIBLE_PLACE, GENDER  ";
		strImpossiblePlaceQuery += " FROM APT_COMMUNITY ";
		strImpossiblePlaceQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strImpossiblePlaceQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
		strImpossiblePlaceQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";


		pstmt = conn.prepareStatement(strImpossiblePlaceQuery);
		rs = pstmt.executeQuery();
		String strImpossiblePlace = "";

		if(rs.next()){

			strImpossiblePlace = rs.getString("IMPOSSIBLE_PLACE") != null ? rs.getString("IMPOSSIBLE_PLACE") : "";			
			strCommunityGender  = rs.getString("GENDER") != null ? rs.getString("GENDER") : "0";			
		}

		JSONArray jsonArrayImpossiblePlace = new JSONArray(); // 빈 JSONArray로 초기화
			
		if (strImpossiblePlace != null && !strImpossiblePlace.contentEquals("")) {
			// JSONParser 객체 생성
			JSONParser impossiblePlaceParser = new JSONParser();

			// JSON 문자열 파싱 -> JSONArray 객체로 변환
			Object obj = impossiblePlaceParser.parse(strImpossiblePlace);
			
			// obj가 JSONArray인지 확인 후 캐스팅
			if (obj instanceof JSONArray) {
				jsonArrayImpossiblePlace = (JSONArray) obj;
			//printLog("D","JSON 파싱 : " + jsonArray.toJSONString());         
			} else {
				// obj가 JSONArray가 아닐 경우 처리
				jsonArrayImpossiblePlace = new JSONArray(); // 빈 JSONArray로 초기화
			}
	
		}


		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		int nRemainingSeats = 0;

		if(strMembershipId.contentEquals("") || strOptionId.contentEquals("")){

			
			String strMembershipSettingsQuery = "";
			strMembershipSettingsQuery += " SELECT  MEMBERSHIP_PLACE "; 
			strMembershipSettingsQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strMembershipSettingsQuery += " WHERE MEMBERSHIP_ID = ? ";

			pstmt = conn.prepareStatement(strMembershipSettingsQuery);
			pstmt.setString(1, strMembershipId);
			rs = pstmt.executeQuery();

			printLog("A","strMembershipSettingsQuery : " + strMembershipSettingsQuery);
			String strPlaceNames = "";

			if(rs.next()){				
				if(strPlaceNames != null && strPlaceNames.contentEquals("")){
					strPlaceNames  = rs.getString("MEMBERSHIP_PLACE") != null ? rs.getString("MEMBERSHIP_PLACE") : "";
				}
			}
			

			if(strPlaceNames == null || strPlaceNames.contentEquals("")){
				String strPlaceCountQuery = "";
				strPlaceCountQuery += " SELECT PLACE_NAME ";
				strPlaceCountQuery += " FROM APT_COMMUNITY ";
				strPlaceCountQuery += " WHERE APT_CODE = " + strAptCode + " ";
				strPlaceCountQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
				strPlaceCountQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";

				pstmt = conn.prepareStatement(strPlaceCountQuery);
				rs = pstmt.executeQuery();

				if(rs.next()){
					strPlaceNames = rs.getString(1);
				}
			}
			
			strPlaceNames = strPlaceNames.replace("\"", "");  // 큰따옴표 제거

			String[] placeNames = strPlaceNames.split(",");
			
			String strReserveTodayQuery = "";
			strReserveTodayQuery += "SELECT PLACE ";
			strReserveTodayQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReserveTodayQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
			strReserveTodayQuery += " AND APT_CODE = " + strAptCode + " ";
			strReserveTodayQuery += " AND RESERVE_CANCEL_TIME IS NULL ";

//			if(strMembershipId != null && !strMembershipId.contentEquals("")){
//				strReserveTodayQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";
//			}

			if(strValidityDateFrom.contentEquals("") && strValidityDateTo.contentEquals("")){
				strReserveTodayQuery += " AND DATE <= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
				strReserveTodayQuery += " AND EXPIRATION_DATE >= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
			}else{
				strReserveTodayQuery += " AND EXPIRATION_DATE >= '" + strValidityDateFrom + "' ";
    			strReserveTodayQuery += " AND DATE <= '" + strValidityDateTo + "' ";
			}
			// 시설정보또는 회원권정보에 성별이 있는 경우 성별도 구분
			if(!strCommunityGender.contentEquals("0") || !strMembershipGender.contentEquals("0")){
				strReserveTodayQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
			}
			
			printLog("A","strReserveTodayQuery : " + strReserveTodayQuery);



			pstmt = conn.prepareStatement(strReserveTodayQuery);
			rs = pstmt.executeQuery();

			rsMetaData = rs.getMetaData();

			JSONArray jsonArray = new JSONArray();
			
			List<String> reservePlaces = new ArrayList<String>();

			for(int nRow = 0; rs.next(); nRow++) {
				for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
					String strData = rs.getString(nCol);
					if(strData == null) strData = "";
					reservePlaces.add(strData);
				}
			}		


			for (String place : placeNames) {
				if (reservePlaces.contains(place)) {
					JSONObject seat = new JSONObject();
					seat.put("seatName", place);
					seat.put("available", 0);
					jsonArray.add(seat);
				} else {
					boolean isPossible = true;				
					for (int i = 0; i < jsonArrayImpossiblePlace.size(); i++) {
						JSONObject jsonObj = (JSONObject) jsonArrayImpossiblePlace.get(i);
						String name = (String) jsonObj.get("name");
						String reason = (String) jsonObj.get("reason");

						 // 쉼표로 구분된 name 각각을 비교
						if (name != null) {
							String[] names = name.split(",");
							for (String n : names) {
								if (n.contentEquals(place)) {
									isPossible = false;
									break; // 일치하면 더 이상 볼 필요 없음
								}
							}
						}
					}	
					JSONObject seat = new JSONObject();
					if(isPossible){
						seat.put("seatName", place);
						seat.put("available", 1);
						nRemainingSeats = nRemainingSeats + 1;
					}else{
						seat.put("seatName", "불가");
						seat.put("available", 0);
					}
					jsonArray.add(seat);
				}
			}


			// JSONArray를 문자열로 변환
			String jsonString = jsonArray.toJSONString();
					
			baOutStream.write(jsonString.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write(Integer.toString(nRemainingSeats).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			
		}else{

			String strPlaceCountQuery = "";
			strPlaceCountQuery += " SELECT PLACE_NAME ";
			strPlaceCountQuery += " FROM APT_COMMUNITY_MEMBERSHIP_OPTION ";
			strPlaceCountQuery += " WHERE 1 = 1 ";
			strPlaceCountQuery += " AND MEMBERSHIP_ID = '" + strMembershipId + "' ";
			strPlaceCountQuery += " AND OPTION_ID = '" + strOptionId + "' ";

			pstmt = conn.prepareStatement(strPlaceCountQuery);
			rs = pstmt.executeQuery();

			String strPlaceNames = "";
			if(rs.next()){
				strPlaceNames = rs.getString(1);
			}
			strPlaceNames = strPlaceNames.replace("\"", "");  // 큰따옴표 제거

			String[] placeNames = strPlaceNames.split(",");
			
			
			String strReserveTodayQuery = "";
			strReserveTodayQuery += "SELECT PLACE ";
			strReserveTodayQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReserveTodayQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
			strReserveTodayQuery += " AND RESERVE_CANCEL_TIME IS NULL ";
			strReserveTodayQuery += " AND APT_CODE = " + strAptCode + " ";
			if(strValidityDateFrom.contentEquals("") && strValidityDateTo.contentEquals("")){
				strReserveTodayQuery += " AND DATE <= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
				strReserveTodayQuery += " AND EXPIRATION_DATE >= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
			}else{
				strReserveTodayQuery += " AND DATE >= '" + strValidityDateFrom + "' ";
    			strReserveTodayQuery += " AND DATE <= '" + strValidityDateTo + "' ";
			}
			// 시설정보또는 회원권정보에 성별이 있는 경우 성별도 구분
			if(!strCommunityGender.contentEquals("0") || !strMembershipGender.contentEquals("0")){
				strReserveTodayQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
			}			
			pstmt = conn.prepareStatement(strReserveTodayQuery);
			rs = pstmt.executeQuery();

			rsMetaData = rs.getMetaData();

			JSONArray jsonArray = new JSONArray();
			
			List<String> reservePlaces = new ArrayList<String>();

			for(int nRow = 0; rs.next(); nRow++) {
				for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
					String strData = rs.getString(nCol);
					if(strData == null) strData = "";
					reservePlaces.add(strData);
				}
			}		


			for (String place : placeNames) {
				if (reservePlaces.contains(place)) {
					JSONObject seat = new JSONObject();
					seat.put("seatName", place);
					seat.put("available", 0);
					jsonArray.add(seat);
				} else {
					boolean isPossible = true;
					for (int i = 0; i < jsonArrayImpossiblePlace.size(); i++) {
						JSONObject jsonObj = (JSONObject) jsonArrayImpossiblePlace.get(i);
						String name = (String) jsonObj.get("name");
						String reason = (String) jsonObj.get("reason");

						// 해당하는게 있으면 이름 데이터에 사유 붙이기 
						if(name.contentEquals(place)){
							isPossible = false;
						}
					}	
					JSONObject seat = new JSONObject();
					if(isPossible){
						seat.put("seatName", place);
						seat.put("available", 1);
						nRemainingSeats = nRemainingSeats + 1;
					}else{
						seat.put("seatName", "불가");
						seat.put("available", 0);
					}
					jsonArray.add(seat);
				}
			}


			// JSONArray를 문자열로 변환
			String jsonString = jsonArray.toJSONString();
					
			baOutStream.write(jsonString.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write(Integer.toString(nRemainingSeats).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
		}

		returnData(baOutStream, outStream);
	}else if(strSID.contentEquals("reservation_guestroom")){
		String strMembershipId = getRequestParam(request,"MembershipId");	
		String strAptCode = getRequestParam(request, "AptCode");		
		String strUserId = getRequestParam(request,"UserId");	
		String strUserName = getRequestParam(request, "UserName");		
		String strUserDong = getRequestParam(request,"UserDong");	
		String strUserHo = getRequestParam(request, "UserHo");		
		String strReservationUserName = getRequestParam(request, "ReservationUserName");
		String strReservationUserPhone = getRequestParam(request, "ReservationUserPhone");
		String strRoomNumber = getRequestParam(request, "RoomNumber");		
		String strPrice = getRequestParam(request, "Price");		
		String strStartDate = getRequestParam(request, "StartDate");
		String strEndDate = getRequestParam(request, "EndDate");
		String strOptions = getRequestParam(request, "MembershipOption");
		String strUUID = getRequestParam(request, "UUID");
		String strRequestReservationTime = getRequestParam(request, "ReservationTime");
		String strRequestReservationChannel = getRequestParam(request, "ReservationChannel");
		String strPaymentId = getRequestParam(request, "PaymentId");
		String strReceiptId = getRequestParam(request, "ReceiptId");

		strMembershipId = strMembershipId != null ? strMembershipId.trim() : "";
		strAptCode = strAptCode != null ? strAptCode.trim() : "";
		strUserId = strUserId != null ? strUserId.trim() : "";
		strUserName = strUserName != null ? strUserName.trim() : "";
		strUserDong = strUserDong != null ? strUserDong.trim() : "";
		strUserHo = strUserHo != null ? strUserHo.trim() : "";
		strReservationUserName = strReservationUserName != null ? strReservationUserName.trim() : "";
		strReservationUserPhone = strReservationUserPhone != null ? strReservationUserPhone.trim() : "";
		strRoomNumber = strRoomNumber != null ? strRoomNumber.trim() : "";
		strPrice = strPrice != null ? strPrice.trim() : "";
		strStartDate = strStartDate != null ? strStartDate.trim() : "";
		strEndDate = strEndDate != null ? strEndDate.trim() : "";
		strOptions = strOptions != null ? strOptions.trim() : "";
		strUUID = strUUID != null ? strUUID.trim() : "";
		strRequestReservationTime = strRequestReservationTime != null ? strRequestReservationTime.trim() : "";
		strRequestReservationChannel = strRequestReservationChannel != null ? strRequestReservationChannel.trim() : "";
		strPaymentId = strPaymentId != null ? strPaymentId.trim() : "";
		strReceiptId = strReceiptId != null ? strReceiptId.trim() : "";

printLog("A", "*** time test - " + strPaymentId + " : 1 게스트하우스 예약 시작");

		if(strReservationUserName.contentEquals("")) {
			strReservationUserName = strUserName;
		}
		if(strRequestReservationChannel.contentEquals("")) {
			strRequestReservationChannel = "00";
		}
		if(strUUID.contentEquals("")) {
			strUUID = "0";
		}

		strPrice = strPrice.replace("원", "").replace(",", "");

		// 결과 값
		int nRet = 0;
		String strMessage = "예약이 완료되었습니다!";
		String strReservationId = "";
		String strResultInfo = "";

		boolean isPaymentConfirmed = false;
		boolean isTransactionStarted = false;
		boolean isPaymentSaved = false;
		boolean isNeedPayment = false;
		boolean isPurchase = false;
		boolean isReservationSaved = false;

		// 최종 DB COMMIT 성공 여부
		boolean isDbCommitted = false;

		// autoCommit 원복 여부
		boolean isAutoCommitRestored = false;

		// 동일 객실 동시 예약 요청 잠금 상태
		boolean isGuestroomLockAcquired = false;

		// GET_LOCK / RELEASE_LOCK에 사용할 잠금 키
		String strGuestroomLockKey = "";

		String strReceiptUrl = "";
		String strPurchasedDate = "";
		String strNeedToPay = "0";
		String strMembershipName = "";
		String strMembershipUserListId = "";

		try { 
			if(strMembershipId.contentEquals("")
				|| strAptCode.contentEquals("")
				|| strUserId.contentEquals("")
				|| strUserDong.contentEquals("")
				|| strUserHo.contentEquals("")
				|| strReservationUserName.contentEquals("")
				|| strRoomNumber.contentEquals("")
				|| strStartDate.contentEquals("")
				|| strEndDate.contentEquals("")) {

					throw new Exception("게스트하우스 예약 필수 정보가 없습니다.");
			}

			// 게스트하우스 예약시 만료된 날짜가 있는지 확인
			String strDateVerificationQuery = "";
			strDateVerificationQuery += " SELECT COUNT(*) ";
			strDateVerificationQuery += " FROM APT_COMMUNITY_RESERVE ";
			strDateVerificationQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strDateVerificationQuery += " AND COMMUNITY_TYPE = '10' ";
			strDateVerificationQuery += " AND PLACE = '" + strRoomNumber + "' ";	
			strDateVerificationQuery += " AND RESERVE_CANCEL_TIME IS NULL ";
			strDateVerificationQuery += " AND STR_TO_DATE(DATE, '%Y%m%d') < STR_TO_DATE('" + strEndDate + "', '%Y%m%d') ";
			strDateVerificationQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d') > STR_TO_DATE('" + strStartDate + "', '%Y%m%d') ";

			printLog("A","strDateVerificationQuery : "+ strDateVerificationQuery);

			pstmt = conn.prepareStatement(strDateVerificationQuery);
			rs = pstmt.executeQuery();

			String strDateVerificationCount = "0";

			if(rs.next()){
				strDateVerificationCount = rs.getString(1);
			}

			printLog("A","strDateVerificationCount : "+ strDateVerificationCount);

			if(!strDateVerificationCount.contentEquals("0")){
				printLog("A", "[PRECHECK][FAIL] 게스트하우스 객실 날짜 중복"
								+ " - roomNumber : " + strRoomNumber
								+ ", startDate : " + strStartDate
								+ ", endDate : " + strEndDate
								+ ", duplicateCount : "
								+ strDateVerificationCount);

				throw new Exception("날짜를 다시 선택해주세요. 예약 불가능한 날짜가 포함되어 있습니다.");
			}

			// =========================================================
			// 결제 필요 여부 조회
			// =========================================================
			String strNeedToPayQuery = "";
			strNeedToPayQuery += "SELECT NEED_TO_PAY, NAME ";
			strNeedToPayQuery += "FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strNeedToPayQuery += "WHERE MEMBERSHIP_ID = " + strMembershipId + " ";

			pstmt = conn.prepareStatement(strNeedToPayQuery);
			rs = pstmt.executeQuery();

			if(rs.next()) {
				strNeedToPay = rs.getString(1);
				if(strNeedToPay == null || strNeedToPay.contentEquals("")){
					strNeedToPay = "0";
				}
				strMembershipName = rs.getString(2) != null ? rs.getString(2) : "";
			}

			isNeedPayment = strNeedToPay.contentEquals("1");

			// =========================================================
			// 유료 회원권 결제 정보 사전 확인
			// - PaymentId, ReceiptId 필수값 확인
			// - 이미 승인된 PAYMENT_ID인지 중복 확인
			// =========================================================
			if(isNeedPayment) {

				if(strPaymentId.contentEquals("") || strReceiptId.contentEquals("")) {
					throw new Exception("결제 정보가 없습니다.");	
				}

				String strOrderQuery = "";
				strOrderQuery += " SELECT STATE ";
				strOrderQuery += " FROM PARTNER_PAYMENT ";
				strOrderQuery += " WHERE PAYMENT_ID = '" + strPaymentId + "' ";

				pstmt = conn.prepareStatement(strOrderQuery);
				// pstmt.setString(1, strPaymentId);
				rs = pstmt.executeQuery();

				String strOrderState = "0";

				if(rs.next()) {
					strOrderState = rs.getString(1) != null ? rs.getString(1) : "0";
				}

				if(strOrderState.contentEquals("1")) {
					throw new Exception("이미 승인된 결제건입니다.");
				}
			}

			printLog("A", "[STEP 1][START] 게스트하우스 회원권/예약 DB 작업 준비"
							+ " - isNeedPayment : " + isNeedPayment
							+ ", membershipId : " + strMembershipId
							+ ", roomNumber : " + strRoomNumber
							+ ", paymentId : " + strPaymentId);

			// =========================================================
			// 유료·무료 공통으로 회원권, 예약, 결제 DB 작업을 하나의 트랜잭션으로 처리
			// =========================================================
			conn.setAutoCommit(false);
			isTransactionStarted = true;

			// 동일 아파트·동일 객실의 예약 요청을 순차 처리
			strGuestroomLockKey = "reservation_guestroom:"
									+ strAptCode + ":"
									+ strRoomNumber;

			String strGuestroomLockQuery = "SELECT GET_LOCK(?, 5)";

			pstmt = conn.prepareStatement(strGuestroomLockQuery);
			pstmt.setString(1, strGuestroomLockKey);

			rs = pstmt.executeQuery();

			int nGuestroomLockResult = 0;

			if(rs.next()) {
				nGuestroomLockResult = rs.getInt(1);
			}

			printLog("A", "[STEP 1][CHECK] 게스트하우스 동시 예약 잠금 결과"
							+ " - lockKey : " + strGuestroomLockKey
							+ ", lockResult : " + nGuestroomLockResult);

			if(nGuestroomLockResult != 1) {
				throw new Exception("현재 다른 예약이 처리 중입니다. 잠시 후 다시 시도해주세요.");
			}

			isGuestroomLockAcquired = true;

			printLog("A", "[STEP 1][SUCCESS] 게스트하우스 동시 예약 잠금 획득"
							+ " - lockKey : " + strGuestroomLockKey);

			printLog("A", "[STEP 1][SUCCESS] 게스트하우스 트랜잭션 시작 성공" + " - autoCommit : false");

			// =========================================================
			// 잠금 획득 후 객실 날짜 중복 재확인
			// - 동시에 들어온 요청 중 먼저 완료된 예약을 반영하여 다시 검사
			// =========================================================
			String strLockedDateVerificationQuery = "";

			strLockedDateVerificationQuery += " SELECT COUNT(*) ";
			strLockedDateVerificationQuery += " FROM APT_COMMUNITY_RESERVE ";
			strLockedDateVerificationQuery += " WHERE APT_CODE = ? ";
			strLockedDateVerificationQuery += " AND COMMUNITY_TYPE = '10' ";
			strLockedDateVerificationQuery += " AND PLACE = ? ";
			strLockedDateVerificationQuery += " AND RESERVE_CANCEL_TIME IS NULL ";

			// 기존 예약 시작일 < 신규 예약 종료일
			strLockedDateVerificationQuery += " AND STR_TO_DATE(DATE, '%Y%m%d')" + " < STR_TO_DATE(?, '%Y%m%d') ";

			// 기존 예약 종료일 > 신규 예약 시작일
			strLockedDateVerificationQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d')" + " > STR_TO_DATE(?, '%Y%m%d') ";

			pstmt = conn.prepareStatement(strLockedDateVerificationQuery);

			pstmt.setString(1, strAptCode);
			pstmt.setString(2, strRoomNumber);
			pstmt.setString(3, strEndDate);
			pstmt.setString(4, strStartDate);

			rs = pstmt.executeQuery();

			int nLockedDuplicateCount = 0;

			if(rs.next()) {
				nLockedDuplicateCount = rs.getInt(1);
			}

			printLog("A", "[STEP 1][CHECK] 잠금 획득 후 게스트하우스 날짜 중복 재확인"
								+ " - roomNumber : " + strRoomNumber
								+ ", startDate : " + strStartDate
								+ ", endDate : " + strEndDate
								+ ", duplicateCount : " + nLockedDuplicateCount);

			if(nLockedDuplicateCount > 0) {
				throw new Exception("선택한 날짜의 객실 예약이 마감되었습니다. 다른 날짜를 선택해주세요.");
			}

			printLog("A", "[STEP 2][START] 게스트하우스 회원권 DB INSERT 시작"
								+ " - membershipId : " + strMembershipId
								+ ", userId : " + strUserId
								+ ", reservationUserName : "
								+ strReservationUserName);

			// 회원권 구매
			String query = "INSERT INTO APT_COMMUNITY_MEMBERSHIP_USER_LIST (USER_ID, MEMBERSHIP_ID, PRICE, REGISTRATION_DATE, EXPIRATION_DATE, DESCRIPTION, USER_DONG, USER_HO, USER_NAME, APT_CODE, PURCHASE_DATE, COMMUNITY_TYPE, OPTIONS, UUID) "
						+ "VALUES (?, ?, ?, ?, ?, (SELECT NAME FROM APT_COMMUNITY_MEMBERSHIP_INFO WHERE MEMBERSHIP_ID = ?), ?, ?, ?, ?, DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ?, ?, ?)";
			pstmt = conn.prepareStatement(query);
			pstmt.setString(1, strUserId);
			pstmt.setString(2, strMembershipId);
			pstmt.setString(3, strPrice);
			pstmt.setString(4, strStartDate);
			pstmt.setString(5, strEndDate);
			pstmt.setString(6, strMembershipId);
			pstmt.setString(7, strUserDong);
			pstmt.setString(8, strUserHo);
			pstmt.setString(9, strUserName);
			pstmt.setString(10, strAptCode);
			pstmt.setString(11, "10");
			pstmt.setString(12, strOptions);
			pstmt.setString(13, strUUID);		
			
			int nMembershipRet = pstmt.executeUpdate();

			printLog("A", "[STEP 2][RESULT] 게스트하우스 회원권 DB INSERT 결과" + " - nMembershipRet : " + nMembershipRet);

			if(nMembershipRet != 1) {
				throw new Exception("게스트하우스 회원권 발급에 실패했습니다.");
			}

			isPurchase = true;

			String strLastMembershipIdQuery = "";
			strLastMembershipIdQuery += "SELECT MEMBERSHIP_USER_LIST_ID ";
			strLastMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
			strLastMembershipIdQuery += " WHERE UUID = '" + strUUID + "' ORDER BY MEMBERSHIP_USER_LIST_ID  desc LIMIT 1 ";

			pstmt = conn.prepareStatement(strLastMembershipIdQuery);
			rs = pstmt.executeQuery();

			String strLastMembershipId = "";
			
			if(rs.next()) {
				strLastMembershipId = rs.getString(1);	
				strMembershipUserListId = strLastMembershipId;
			}

			if(strMembershipUserListId.contentEquals("")) {
				throw new Exception("생성된 게스트하우스 회원권 사용자 ID를 확인할 수 없습니다.");
			}

			printLog("A", "[STEP 2][SUCCESS] 게스트하우스 회원권 DB INSERT 성공" + " - membershipUserListId : " + strMembershipUserListId);

			// 예약
			boolean hasReservationTime = strRequestReservationTime != null && !strRequestReservationTime.isEmpty();
			boolean hasReservationChannel = strRequestReservationChannel != null && !strRequestReservationChannel.isEmpty();

			StringBuilder query2 = new StringBuilder();
			query2.append("INSERT INTO APT_COMMUNITY_RESERVE (");
			query2.append("COMMUNITY_TYPE, USER_ID, USER_DONG, USER_HO, RESERVE_USER_NAME, RESERVE_USER_PHONE, ");
			query2.append("PLACE, DATE, APT_CODE, REG_DATE, USER_NAME, EXPIRATION_DATE, MEMBERSHIP_ID, MEMBERSHIP_USER_LIST_ID, UUID");

			if (hasReservationTime) query2.append(", TIME");      // 예약 시간 컬럼 추가
			if (hasReservationChannel) query2.append(", REG_CHANNEL"); // 예약채널 컬럼 추가

			query2.append(") VALUES (");
			query2.append("?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ?, ?, ?, ?, ?");

			if (hasReservationTime) query2.append(", ?");
			if (hasReservationChannel) query2.append(", ?");

			query2.append(")");

			pstmt = conn.prepareStatement(query2.toString());
			int idx = 1;

			pstmt.setString(idx++, "10"); // COMMUNITY_TYPE
			pstmt.setString(idx++, strUserId);
			pstmt.setString(idx++, strUserDong);
			pstmt.setString(idx++, strUserHo);
			pstmt.setString(idx++, strReservationUserName);
			pstmt.setString(idx++, strReservationUserPhone);
			pstmt.setString(idx++, strRoomNumber);
			pstmt.setString(idx++, strStartDate);
			pstmt.setString(idx++, strAptCode);
			pstmt.setString(idx++, strUserName);
			pstmt.setString(idx++, strEndDate);
			pstmt.setString(idx++, strMembershipId);
			pstmt.setString(idx++, strLastMembershipId);
			pstmt.setString(idx++, strUUID);

			if (hasReservationTime) pstmt.setString(idx++, strRequestReservationTime);
			if (hasReservationChannel) pstmt.setString(idx++, strRequestReservationChannel);

			printLog("A", "[STEP 3][START] 게스트하우스 예약 DB INSERT 시작"
							+ " - membershipUserListId : " + strMembershipUserListId
							+ ", roomNumber : " + strRoomNumber + ", startDate : " + strStartDate
							+ ", endDate : " + strEndDate
							+ ", reservationTime : " + strRequestReservationTime
							+ ", reservationChannel : " + strRequestReservationChannel);

			int nReservationRet = pstmt.executeUpdate();

			printLog("A", "[STEP 3][RESULT] 게스트하우스 예약 DB INSERT 결과" + " - nReservationRet : " + nReservationRet);

			if(nReservationRet != 1) {

				printLog("A", "[STEP 3][FAIL] 게스트하우스 예약 DB INSERT 실패"
								+ " - membershipUserListId : " + strMembershipUserListId
								+ ", roomNumber : " + strRoomNumber);

				throw new Exception("게스트하우스 예약 정보 저장에 실패했습니다.");
			}

			isReservationSaved = true;
			nRet = 1;

			String strLastReservationIdQuery = "";
			strLastReservationIdQuery += "SELECT RESERVE_ID ";
			strLastReservationIdQuery += " FROM APT_COMMUNITY_RESERVE ";
			strLastReservationIdQuery += " WHERE UUID = '" + strUUID + "' ORDER BY RESERVE_ID  desc LIMIT 1 ";

			pstmt = conn.prepareStatement(strLastReservationIdQuery);
			rs = pstmt.executeQuery();
			
			if(rs.next()) {
				strReservationId = rs.getString(1) != null ? rs.getString(1) : "";
			}

			if(strReservationId.contentEquals("")) {
				printLog("A", "[STEP 3][FAIL] 생성된 게스트하우스 예약 ID 조회 실패" + " - membershipUserListId : " + strMembershipUserListId);
				throw new Exception("생성된 게스트하우스 예약 ID를 확인할 수 없습니다.");
			}

			printLog("A", "[STEP 3][SUCCESS] 게스트하우스 예약 DB INSERT 성공"
								+ " - reservationId : " + strReservationId
								+ ", membershipUserListId : " + strMembershipUserListId);

			printLog("A", "[STEP 4][CHECK] 게스트하우스 DB 작업 완료 후 결제 진행 조건 확인"
							+ " - isPurchase : " + isPurchase
							+ ", isReservationSaved : " + isReservationSaved
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", reservationId : " + strReservationId);

			if(isNeedPayment) {

				if(!isPurchase) {
					throw new Exception("결제 필요 건인데 회원권 발급이 완료되지 않았습니다.");
				}

				if(!isReservationSaved) {
					throw new Exception("결제 필요 건인데 예약 저장이 완료되지 않았습니다.");
				}

				if(strMembershipUserListId.contentEquals("")) {
					throw new Exception("결제 필요 건인데 회원권 사용자 ID가 없습니다.");
				}

				if(strReservationId.contentEquals("")) {
					throw new Exception("결제 필요 건인데 예약 ID가 없습니다.");
				}

				printLog("A", "[STEP 5][START] 게스트하우스 Bootpay 결제 verify 시작"
								+ " - paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId
								+ ", expectedStatus : 2"
								+ ", expectedPrice : " + strPrice);

printLog( "A", "*** time test - " + strPaymentId + " : 2 결제검증 시작(우회구간)");

				boolean isVerifiedPayment = verifyPayment(strReceiptId, "2", strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 3 결제검증 종료(우회구간)");

				if(!isVerifiedPayment) {

					printLog("A", "[STEP 5][FAIL] 게스트하우스 Bootpay 결제 verify 실패"
									+ " - receiptId : " + strReceiptId
									+ ", expectedPrice : " + strPrice);

					throw new Exception("게스트하우스 결제 검증에 실패했습니다.");
				}

				printLog("A", "[STEP 5][SUCCESS] 게스트하우스 Bootpay 결제 verify 성공"
								+ " - receiptId : " + strReceiptId
								+ ", price : " + strPrice);

				printLog("A", "[STEP 6][START] 게스트하우스 Bootpay 결제 confirm 시작"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", price : " + strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 4 결제컨펌 시작(우회구간)");

				JSONObject jsonConfirmResult = confirmBootpayPayment(strPaymentId, strReceiptId, strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 5 결제컨펌 종료(우회구간)");

				if(jsonConfirmResult == null) {

					printLog("A", "[STEP 6][FAIL] 게스트하우스 Bootpay 결제 confirm 실패"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId);

					throw new Exception("게스트하우스 결제 승인에 실패했습니다.");
				}

				// 반드시 confirm 성공 후에만 true
				isPaymentConfirmed = true;

				// confirm 응답에서 영수증 URL과 결제일 추출
				strReceiptUrl = jsonConfirmResult.get("receipt_url") != null ? jsonConfirmResult.get("receipt_url").toString() : "";
				String strPurchasedAt = jsonConfirmResult.get("purchased_at") != null ? jsonConfirmResult.get("purchased_at").toString() : "";
				strPurchasedDate = convertBootpayDateToDBFormat(strPurchasedAt);

				printLog("A", "[STEP 6][SUCCESS] 게스트하우스 Bootpay 결제 confirm 성공"
								+ " - paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId);
			}

			printLog("A", "[STEP 4][SUCCESS] 게스트하우스 결제 진행 조건 확인 완료"
							+ " - membershipUserListId : " + strMembershipUserListId
							+ ", reservationId : " + strReservationId);

			// =========================================================
			// STEP 7. 결제 정보 DB 저장
			// - 회원권과 예약 생성 후 Bootpay verify·confirm이 완료된 유료 건만 저장
			// - 영수증 URL과 승인 일자를 PARTNER_PAYMENT에 함께 기록
			// =========================================================
			if(isNeedPayment) {
				String strPaymentItem = strMembershipName + "*" + strPrice + "*+";

				String strInsertPaymentQuery = "";
				strInsertPaymentQuery += "INSERT INTO PARTNER_PAYMENT ";
				strInsertPaymentQuery += " (PAYMENT_ID, RESERVATION_ID, PRICE, TOTAL_PRICE, STATE, DATE, COMMENT, IMAGE, PAYMENT_ITEM, COUPON_USE, INSPECTION, MENU_ID, RECEIPT_ID, USER_ID, RECEIPT_URL, PURCHASED_DATE )";
				strInsertPaymentQuery += " VALUES('" + strPaymentId  + "', ";
				// 커뮤니티 회원권 결제는 PARTNER_PAYMENT.RESERVATION_ID에
				// MEMBERSHIP_USER_LIST_ID를 저장하는 기존 규칙을 따른다.
				strInsertPaymentQuery += strMembershipUserListId + ", ";
				strInsertPaymentQuery += "'" + strPrice + "', "; // PRICE
				strInsertPaymentQuery += "'" + strPrice + "', "; // TOTAL PRICE
				strInsertPaymentQuery += "'1', ";
				strInsertPaymentQuery += "DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), ";
				strInsertPaymentQuery += "'', ";
				strInsertPaymentQuery += "'', ";
				strInsertPaymentQuery += "'" + strPaymentItem + "', ";
				strInsertPaymentQuery += "'0', ";
				strInsertPaymentQuery += "'0', ";
				strInsertPaymentQuery += "'49', ";
				strInsertPaymentQuery += "'" + strReceiptId + "', ";
				strInsertPaymentQuery += "'" + strUserId + "', ";
				strInsertPaymentQuery += "'" + strReceiptUrl + "', ";
				strInsertPaymentQuery += "'" + strPurchasedDate + "' ";
				strInsertPaymentQuery += ")";

				pstmt = conn.prepareStatement(strInsertPaymentQuery);

				printLog("A", "[STEP 7][START] 게스트하우스 PARTNER_PAYMENT INSERT 시작"
									+ " - paymentId : " + strPaymentId
									+ ", reservationId : " + strReservationId
									+ ", membershipUserListId : " + strMembershipUserListId
									+ ", receiptId : " + strReceiptId
									+ ", price : " + strPrice);

				int nPaymentRet = pstmt.executeUpdate();

				printLog("A", "[STEP 7][RESULT] 게스트하우스 PARTNER_PAYMENT INSERT 결과" + " - nPaymentRet : " + nPaymentRet);

				if(nPaymentRet != 1) {

					printLog("A", "[STEP 7][FAIL] 게스트하우스 PARTNER_PAYMENT INSERT 실패" + " - paymentId : " + strPaymentId);

					throw new Exception("게스트하우스 결제 정보 저장에 실패했습니다.");
				}

				isPaymentSaved = true;

				printLog("A", "[STEP 7][SUCCESS] 게스트하우스 PARTNER_PAYMENT INSERT 성공" + " - paymentId : " + strPaymentId);
			}
					

			if(nRet == 0){
				strMessage = "예약에 실패했습니다. 다시 시도해주세요";
			}

			strResultInfo = "성함*" + strReservationUserName + "*+";
			strResultInfo += "동/호수*" + strUserDong + "동 " + strUserHo + "호" + "*+";
			strResultInfo += "시설내역*게스트 하우스*+";
			strResultInfo += "날짜/시간*" + formatDate(strStartDate) + " ~ " + formatDate(strEndDate) + "*+" ;
			strResultInfo += "회원권*게스트 하우스 숙박권*+" ;
			strResultInfo += "번호*" + strRoomNumber + "*+" ;

			printLog("D","nRet : "+ Integer.toString(nRet));
			printLog("D","strMessage : "+ strMessage);

			// =========================================================
			// STEP 8. 최종 상태 확인 및 COMMIT
			// - 무료 건: 회원권과 예약 저장 성공 여부 확인
			// - 유료 건: Bootpay 승인과 PARTNER_PAYMENT 저장까지 추가 확인
			// =========================================================
			printLog("A", "[STEP 8][CHECK] 게스트하우스 최종 commit 조건 확인"
							+ " - isTransactionStarted : " + isTransactionStarted
							+ ", isPurchase : " + isPurchase
							+ ", isReservationSaved : " + isReservationSaved
							+ ", isNeedPayment : " + isNeedPayment
							+ ", isPaymentConfirmed : " + isPaymentConfirmed
							+ ", isPaymentSaved : " + isPaymentSaved
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", reservationId : " + strReservationId);

			if(!isPurchase) {
				throw new Exception("게스트하우스 회원권 발급이 완료되지 않았습니다.");
			}

			if(!isReservationSaved || nRet != 1) {
				throw new Exception("게스트하우스 예약 저장이 완료되지 않았습니다.");
			}

			if(strMembershipUserListId.contentEquals("")) {
				throw new Exception("게스트하우스 회원권 사용자 ID가 없습니다.");
			}

			if(strReservationId.contentEquals("")) {
				throw new Exception("게스트하우스 예약 ID가 없습니다.");
			}

			if(isNeedPayment) {

				if(!isPaymentConfirmed) {
					throw new Exception("게스트하우스 결제 승인이 완료되지 않았습니다.");
				}

				if(!isPaymentSaved) {
					throw new Exception("게스트하우스 결제 정보 저장이 완료되지 않았습니다.");
				}
			}

			printLog("A", "[STEP 8][START] 게스트하우스 전체 DB COMMIT 시작"
							+ " - reservationId : " + strReservationId
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", paymentId : " + strPaymentId);

			conn.commit();

			// 반드시 COMMIT 성공 후에만 true
			isDbCommitted = true;

printLog("A", "*** time test - " + strPaymentId + " : 6 게스트하우스 예약처리 완료");

			printLog("A", "[STEP 8][SUCCESS] 게스트하우스 전체 처리 완료 및 DB COMMIT 성공"
							+ " - reservationId : " + strReservationId
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", isPaymentConfirmed : " + isPaymentConfirmed
							+ ", isPaymentSaved : " + isPaymentSaved);

			if(isGuestroomLockAcquired && strGuestroomLockKey != null && !strGuestroomLockKey.contentEquals("")) {

				String strReleaseGuestroomLockQuery = "SELECT RELEASE_LOCK(?)";

				pstmt = conn.prepareStatement(strReleaseGuestroomLockQuery);
				pstmt.setString(1, strGuestroomLockKey);
				rs = pstmt.executeQuery();

				isGuestroomLockAcquired = false;

				printLog("A", "[TRANSACTION][END] reservation_guestroom 객실 잠금 해제" + " - lockKey : " + strGuestroomLockKey);
			}

			if(isTransactionStarted) {

				conn.setAutoCommit(true);

				isAutoCommitRestored = true;

				printLog("A", "[TRANSACTION][END] reservation_guestroom autoCommit 원복 성공");
			}

			ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

			baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strMessage.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strReservationId.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strResultInfo.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			if(isNeedPayment && isPaymentSaved){
				baOutStream.write(strPaymentId.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			}else{
				baOutStream.write("".getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			}

			returnData(baOutStream, outStream);

			printLog( "A", "[RESPONSE][SUCCESS] reservation_guestroom 앱 응답 전송 완료"
						+ " - reservationId : " + strReservationId
						+ ", membershipUserListId : " + strMembershipUserListId
						+ ", paymentId : " + strPaymentId);

		// =========================================================
		// 예외 처리
		// - 트랜잭션이 시작된 경우 DB rollback
		// - 예외 메시지를 앱 응답 형식으로 반환
		// =========================================================
		} catch(Exception e) {

			printLog("A", "[FAIL] reservation_guestroom 전체 처리 실패"
							+ " - message : " + e.getMessage()
							+ ", exception : " + e.toString()
							+ ", isTransactionStarted : " + isTransactionStarted
							+ ", isPurchase : " + isPurchase
							+ ", isReservationSaved : " + isReservationSaved
							+ ", isPaymentConfirmed : " + isPaymentConfirmed
							+ ", isPaymentSaved : " + isPaymentSaved
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", reservationId : " + strReservationId
							+ ", paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId);

			try {
				// if(isTransactionStarted) {
				if(isTransactionStarted && !isDbCommitted) {

					printLog("A", "[ROLLBACK][START] reservation_guestroom DB rollback 시작"
									+ " - reservationId : " + strReservationId
									+ ", membershipUserListId : " + strMembershipUserListId);

					conn.rollback();

					printLog("A", "[ROLLBACK][SUCCESS] reservation_guestroom DB rollback 성공"
									+ " - reservationId : " + strReservationId
									+ ", membershipUserListId : " + strMembershipUserListId);
				}

			} catch(Exception rollbackException) {

				printLog("A", "[ROLLBACK][FAIL] reservation_guestroom DB rollback 실패"
								+ " - message : " + rollbackException.getMessage()
								+ ", exception : " + rollbackException.toString());
			}

			// =========================================================
			// Bootpay confirm 후 DB COMMIT 실패 시 보상 취소
			// rollback 성공 여부와 관계없이 별도로 시도
			// =========================================================
			if(isPaymentConfirmed && !isDbCommitted) {

				try {

					printLog("A", "[COMPENSATION][START] 게스트하우스 Bootpay 승인 결제 보상 취소 시작"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", price : " + strPrice);

					String strCancelResult = cancelBootpayPaymentByReceiptId(strReceiptId, strPrice);

					if("1".contentEquals(strCancelResult)) {

						printLog("A", "[COMPENSATION][SUCCESS] 게스트하우스 Bootpay 보상 취소 성공"
										+ " - paymentId : " + strPaymentId
										+ ", receiptId : " + strReceiptId);

					} else {

						printLog("A", "[COMPENSATION][FAIL] 게스트하우스 Bootpay 보상 취소 실패"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", cancelResult : " + strCancelResult);
					}

				} catch(Exception compensationException) {

					printLog("A", "[COMPENSATION][ERROR] 게스트하우스 Bootpay 보상 취소 예외"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", exception : " + compensationException.toString());
				}
			}

			if(!isDbCommitted) {

				try {

					String strErrorMessage = e.getMessage() != null ? e.getMessage() : "게스트하우스 예약 처리 중 오류가 발생했습니다.";

					ByteArrayOutputStream errorStream = new ByteArrayOutputStream();

					errorStream.write("0".getBytes(S_CHARSET));
					errorStream.write(COLUMN_DEL);

					errorStream.write(strErrorMessage.getBytes(S_CHARSET));
					errorStream.write(COLUMN_DEL);

					errorStream.write("".getBytes(S_CHARSET));
					errorStream.write(COLUMN_DEL);

					errorStream.write("".getBytes(S_CHARSET));
					errorStream.write(COLUMN_DEL);

					errorStream.write("".getBytes(S_CHARSET));
					errorStream.write(COLUMN_DEL);

					returnData(errorStream, outStream);

					printLog("A", "[RESPONSE][FAIL] reservation_guestroom 앱 실패 응답 전송 완료"
								+ " - paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId
								+ ", message : " + strErrorMessage);

				} catch(Exception responseException) {

					printLog("A", "[RESPONSE][ERROR] reservation_guestroom 실패 응답 전송 예외"
								+ " - exception : " + responseException.toString());
				}
			}

		} finally { // 커넥션 재사용에 영향이 없도록 autoCommit 상태 원복

			try {
				if(isGuestroomLockAcquired && strGuestroomLockKey != null && !strGuestroomLockKey.contentEquals("")) {

					String strReleaseGuestroomLockQuery = "SELECT RELEASE_LOCK(?)";

					pstmt = conn.prepareStatement(
						strReleaseGuestroomLockQuery
					);

					pstmt.setString(1, strGuestroomLockKey);

					rs = pstmt.executeQuery();

					printLog("A", "[TRANSACTION][END] reservation_guestroom 객실 잠금 해제"
									+ " - lockKey : "
									+ strGuestroomLockKey);

					isGuestroomLockAcquired = false;
				}

			} catch(Exception releaseLockException) {

				printLog("A", "[TRANSACTION][FAIL] reservation_guestroom 객실 잠금 해제 실패"
									+ " - exception : "
									+ releaseLockException.toString());
			}

			try {
				// if(isTransactionStarted) {
				if(isTransactionStarted && !isAutoCommitRestored) {

					conn.setAutoCommit(true);

					isAutoCommitRestored = true;

					printLog("A", "[TRANSACTION][END] reservation_guestroom autoCommit 원복 성공");
				}

			} catch(Exception autoCommitException) {

				printLog("A", "[TRANSACTION][FAIL] reservation_guestroom autoCommit 원복 실패"
								+ " - exception : " + autoCommitException.toString());
			}
		}
	}else if(strSID.contentEquals("update_reservation_seat")){
		String strAptCode = getRequestParam(request, "AptCode");
		String strCommunityType = getRequestParam(request, "CommunityType");
		String strUserId = getRequestParam(request,"UserId");
		String strReservationId = getRequestParam(request,"ReservationId");
		String strBeforeSeat = getRequestParam(request,"BeforeSeat");
		String strSeat = getRequestParam(request,"Seat");

		String strValidityDateFrom = "";
		String strValidityDateTo = "";
		String strUserDong = "";
		String strUserHo = "";
		String strReservationUserName = "";
		String strMemberShipId = "";
		String strGender = "";
		String strMembershipGender = "";

		if(strReservationId != null && !strReservationId.contentEquals("")){
			String strQuery = "";
			strQuery += "SELECT cr.DATE, cr.EXPIRATION_DATE, USER_DONG, USER_HO, RESERVE_USER_NAME, MEMBERSHIP_ID, GENDER ";
			strQuery += " FROM APT_COMMUNITY_RESERVE cr ";
			strQuery += " WHERE cr.RESERVE_ID = '" + strReservationId + "' ";	

			pstmt = conn.prepareStatement(strQuery);
			rs = pstmt.executeQuery();
		
			if(rs.next()) {		
				strValidityDateFrom = rs.getString("DATE") != null ? rs.getString("DATE") : "";
				strValidityDateTo = rs.getString("EXPIRATION_DATE") != null ? rs.getString("EXPIRATION_DATE") : "";
				strUserDong = rs.getString("USER_DONG") != null ? rs.getString("USER_DONG") : "";
				strUserHo = rs.getString("USER_HO") != null ? rs.getString("USER_HO") : "";
				strReservationUserName = rs.getString("RESERVE_USER_NAME") != null ? rs.getString("RESERVE_USER_NAME") : "";
				strMemberShipId = rs.getString("MEMBERSHIP_ID") != null ? rs.getString("MEMBERSHIP_ID") : "";
				strGender = rs.getString("GENDER") != null ? rs.getString("GENDER") : "";
			}
		}


		String strMembershipGenderQuery = "";
		strMembershipGenderQuery += "SELECT  GENDER ";
		strMembershipGenderQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipGenderQuery += " WHERE MEMBERSHIP_ID = " + strMemberShipId + " ";		

		pstmt = conn.prepareStatement(strMembershipGenderQuery);
		rs = pstmt.executeQuery();



		if(rs.next()) {			
			strMembershipGender = rs.getString(1) != null ? rs.getString(1) : "";
		}

		// 회원권 구매하기 전에 이 시설에 이미 등록된 자리가 있는지 확인
		// 같은 아파트, 같은 시설에 PLACE랑 내가 등록하려는 자리(Seat)이랑 비교
		String strValiditySeatQuery = "";
		strValiditySeatQuery += " SELECT COUNT(*) ";
		strValiditySeatQuery += " FROM APT_COMMUNITY_RESERVE ";
		strValiditySeatQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
		strValiditySeatQuery += " AND APT_CODE = " + strAptCode + " ";		
		strValiditySeatQuery += " AND PLACE = '" + strSeat + "' ";		
		strValiditySeatQuery += " AND PLACE != '' ";		
		strValiditySeatQuery += " AND RESERVE_CANCEL_TIME IS NULL ";	
		if((strValidityDateFrom == null || strValidityDateFrom.contentEquals("")) &&
			(strValidityDateTo == null || strValidityDateTo.contentEquals(""))){
			strValiditySeatQuery += " AND DATE <= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
			strValiditySeatQuery += " AND EXPIRATION_DATE >= DATE_FORMAT(SYSDATE(),'%Y%m%d%H%i%s') ";
		}else{
			strValiditySeatQuery += " AND EXPIRATION_DATE >= '" + strValidityDateFrom + "' ";
			strValiditySeatQuery += " AND DATE <= '" + strValidityDateTo + "' ";
		}
		if(!strMembershipGender.contentEquals("0")){
			strValiditySeatQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
		}

		printLog("A"," strValiditySeatQuery : "+ strValiditySeatQuery);

		pstmt = conn.prepareStatement(strValiditySeatQuery);
		rs = pstmt.executeQuery();

		int nResultRet = 0;
		int nRet = 0;
		String strValiditySeatCount = "0";
		if(rs.next()) {
			strValiditySeatCount = rs.getString(1);	
		}
		String strUpdateQuery = "";
		if(strValiditySeatCount.contentEquals("0")){
			
			strUpdateQuery += "UPDATE APT_COMMUNITY_RESERVE SET ";
			strUpdateQuery += " PLACE = '" + strSeat + "' ";
			strUpdateQuery += " WHERE RESERVE_ID = " + strReservationId + " ";
		
		    pstmt = conn.prepareStatement(strUpdateQuery);
			nRet = pstmt.executeUpdate();
		}

		if(nRet == 1){
			nResultRet = 1;
			// 한번 더 해당 자리가 1개만 예약되어 있는지 검증 
			// 혹시 같은 타이밍에 들어왔다면 기존 예약값으로 다시 원복
			strValiditySeatQuery = "";
			strValiditySeatQuery += " SELECT COUNT(*) ";
			strValiditySeatQuery += " FROM APT_COMMUNITY_RESERVE ";
			strValiditySeatQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
			strValiditySeatQuery += " AND APT_CODE = " + strAptCode + " ";		
			strValiditySeatQuery += " AND PLACE = '" + strSeat + "' ";		
			strValiditySeatQuery += " AND PLACE != '' ";		
			strValiditySeatQuery += " AND RESERVE_CANCEL_TIME IS NULL ";	
			strValiditySeatQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW()  ";
			if(!strMembershipGender.contentEquals("0")){
				strValiditySeatQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
			}

			
			pstmt = conn.prepareStatement(strValiditySeatQuery);
			rs = pstmt.executeQuery();

			strValiditySeatCount = "0";
			if(rs.next()) {
				strValiditySeatCount = rs.getString(1);	
			}

			if(!strValiditySeatCount.contentEquals("1")){
				// 한 번에 여러 예약이 있으면..
				strUpdateQuery = "";
				strUpdateQuery += "UPDATE APT_COMMUNITY_RESERVE SET ";
				strUpdateQuery += " PLACE = '" + strBeforeSeat + "' ";
				strUpdateQuery += " WHERE RESERVE_ID = " + strReservationId+ " ";

				nResultRet = 9;
			
				pstmt = conn.prepareStatement(strUpdateQuery);
				nRet = pstmt.executeUpdate();
			}
		}

		if(nResultRet == 1){
			String strPushQuery = "";
			strPushQuery = "SELECT COUNT(*) ";
			strPushQuery += " FROM APT_COMMUNITY ";
			strPushQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strPushQuery += " AND COMMUNITY_TYPE ='" + strCommunityType + "' ";
			strPushQuery += " AND PUSH_NOTI_CODE IN (3,9) " ;

			printLog("D", "strPushQuery : " + strPushQuery );

			pstmt = conn.prepareStatement(strPushQuery);
			rs = pstmt.executeQuery();

			String strPushNotiCode = "";
			
			if(rs.next()) {
				strPushNotiCode = rs.getString(1);
			} else {
				strPushNotiCode = "0"; // 안전한 기본값
			}

			if(!strPushNotiCode.contentEquals("0")){

				String strCommunityCenterNameQuery = "";
				strCommunityCenterNameQuery = "SELECT TITLE FROM APT_COMMUNITY WHERE APT_CODE = " + strAptCode + " AND COMMUNITY_TYPE = '" +  strCommunityType + "' ";
				pstmt = conn.prepareStatement(strCommunityCenterNameQuery);
				rs = pstmt.executeQuery();

				String strCommunityCenterName = "";
				
				if(rs.next()) {
					strCommunityCenterName = rs.getString(1);
				} else {
					strCommunityCenterName = "커뮤니티센터"; // 안전한 기본값
				}


				String strMsg = "";
				strMsg = strUserDong + "동 "
       			+ strUserHo + "호 "
				+ strReservationUserName + "님이 "
				+ strCommunityCenterName
				+ " 예약 자리를 변경하셨습니다.";



				RequestDispatcher dispatcher = request.getRequestDispatcher("push_send_service.jsp");
				request.setAttribute("SID", new String(strSID));
				request.setAttribute("Community_AptCode", new String(strAptCode));
				request.setAttribute("Community_Msg", new String(strMsg));
				dispatcher.include(request, response);

			}

		}

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		baOutStream.write(Integer.toString(nResultRet).getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
		baOutStream.write(RECORD_DEL);
		returnData(baOutStream, outStream);

	} else if(strSID.contentEquals("get_membership_list")) {
		String strAptCode = getRequestParam(request, "AptCode");
		String strUserId = getRequestParam(request, "UserId");
		String strItemCount = getRequestParam(request, "ItemCount");
		String strLimitCnt = getRequestParam(request, "LimitCnt");
		String strDong = getRequestParam(request, "UserDong");
		String strHo = getRequestParam(request, "UserHo");
		String strUserName = getRequestParam(request, "UserName");

		String strQuery = "";
		strQuery += " SELECT ";
		// 1. 예약 ID
		// get_reservation_list와 동일하게 APT_COMMUNITY_RESERVE.RESERVE_ID를 내려준다.
		strQuery += " IFNULL(cr.RESERVE_ID, '') AS RESERVE_ID, ";
		
		// 2. 회원권명 - APT_COMMUNITY.TITLE
		strQuery += " IFNULL(NULLIF(ac.TITLE, ''), mi.NAME) as TITLE, ";

		// 3. 예약 또는 회원권 이용 상태
		strQuery += " CASE ";

			// 1. 예약 시간이 있으면 실제 예약 날짜 기준
			// strQuery += "   WHEN cr.RESERVE_TIME IS NOT NULL ";
			// strQuery += "    AND cr.RESERVE_TIME != '' ";
			// strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
			// strQuery += "    AND cr.RESERVE_START_DATE IS NOT NULL ";
			// strQuery += "    AND cr.RESERVE_START_DATE != '' ";
			// strQuery += "   THEN TIMESTAMPDIFF( ";
			// strQuery += "     DAY, ";
			// strQuery += "     CURDATE(), ";
			// strQuery += "     STR_TO_DATE(LEFT(cr.RESERVE_START_DATE, 8), '%Y%m%d') ";
			// strQuery += "   ) ";

			// 1. 예약 시간이 있는 경우
			// 예약 종료시간이 지났으면 -1,
			// 아직 지나지 않았으면 예약 날짜 기준 남은 날짜 계산
			strQuery += "   WHEN cr.RESERVE_TIME IS NOT NULL ";
			strQuery += "    AND cr.RESERVE_TIME != '' ";
			strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
			strQuery += "    AND cr.RESERVE_START_DATE IS NOT NULL ";
			strQuery += "    AND cr.RESERVE_START_DATE != '' ";

			strQuery += "   THEN IF( ";

			strQuery += "     DATE_ADD( ";
			strQuery += "       STR_TO_DATE( ";
			strQuery += "         CONCAT( ";
			strQuery += "           LEFT(cr.RESERVE_START_DATE, 8), ";
			strQuery += "           SUBSTRING(cr.RESERVE_TIME, 5, 4) ";
			strQuery += "         ), ";
			strQuery += "         '%Y%m%d%H%i' ";
			strQuery += "       ), ";
			strQuery += "       INTERVAL 15 MINUTE ";
			strQuery += "     ) < SYSDATE(), ";

			strQuery += "     -1, ";

			strQuery += "     TIMESTAMPDIFF( ";
			strQuery += "       DAY, ";
			strQuery += "       CURDATE(), ";
			strQuery += "       STR_TO_DATE( ";
			strQuery += "         LEFT(cr.RESERVE_START_DATE, 8), ";
			strQuery += "         '%Y%m%d' ";
			strQuery += "       ) ";
			strQuery += "     ) ";

			strQuery += "   ) ";

			// 2. 시간 없는 기간형 예약은 예약 만료일 기준
			strQuery += "   WHEN cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
			strQuery += "    AND cr.RESERVE_EXPIRATION_DATE != '' ";
			strQuery += "   THEN TIMESTAMPDIFF( ";
			strQuery += "     DAY, ";
			strQuery += "     CURDATE(), ";
			strQuery += "     STR_TO_DATE(LEFT(cr.RESERVE_EXPIRATION_DATE, 8), '%Y%m%d') ";
			strQuery += "   ) ";

			// 3. 예약 정보가 없으면 회원권 만료일 기준
			strQuery += "   WHEN mul.EXPIRATION_DATE IS NOT NULL ";
			strQuery += "    AND mul.EXPIRATION_DATE != '' ";
			strQuery += "   THEN TIMESTAMPDIFF( ";
			strQuery += "     DAY, ";
			strQuery += "     CURDATE(), ";
			strQuery += "     STR_TO_DATE(LEFT(mul.EXPIRATION_DATE, 8), '%Y%m%d') ";
			strQuery += "   ) ";

			strQuery += "   ELSE 0 ";
			strQuery += " END as DIFF_DATE, ";

		// 4. 이용 날짜
		strQuery += " CASE ";

		// 1. 실제 예약 시간이 있으면 회원권 타입과 관계없이 예약 날짜를 우선 사용
		strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_START_DATE != '' ";
		strQuery += "    AND cr.RESERVE_TIME IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_TIME != '' ";
		strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
		strQuery += "   THEN LEFT(cr.RESERVE_START_DATE, 8) ";

		// 2. 실제 시간 예약이 없을 때만 추가사용형 회원권 기간 표시
		strQuery += "   WHEN mi.RESERVATION_TYPE = '" + RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE + "' ";
		strQuery += "    AND mul.REGISTRATION_DATE IS NOT NULL ";
		strQuery += "    AND mul.REGISTRATION_DATE != '' ";
		strQuery += "    AND mul.EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND mul.EXPIRATION_DATE != '' ";

		strQuery += "   THEN CONCAT( ";
		strQuery += "     LEFT(mul.REGISTRATION_DATE, 8), ";
		strQuery += "     '-', ";
		strQuery += "     LEFT(mul.EXPIRATION_DATE, 8) ";
		strQuery += "   ) ";

		// 예약 시작일과 만료일이 같은 날짜면 날짜 하나만 표시
		// 예: 2026.02.28 - 2026.02.28 이 아니라 2026.02.28
		strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_START_DATE != '' ";
		strQuery += "    AND cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_EXPIRATION_DATE != '' ";
		strQuery += "    AND LEFT(cr.RESERVE_START_DATE, 8) = LEFT(cr.RESERVE_EXPIRATION_DATE, 8) ";
		strQuery += "   THEN LEFT(cr.RESERVE_START_DATE, 8) ";

		// TIME이 없고 만료일이 있으면 기존처럼 시작일 - 만료일
		strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_START_DATE != '' ";
		strQuery += "    AND cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_EXPIRATION_DATE != '' ";

		strQuery += "   THEN CONCAT( ";
		strQuery += "     LEFT(cr.RESERVE_START_DATE, 8), ";
		strQuery += "     '-', ";
		strQuery += "     LEFT(cr.RESERVE_EXPIRATION_DATE, 8) ";
		strQuery += "   ) ";

		// TIME도 없고 만료일도 없으면 시작일만
		strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_START_DATE != '' ";
		strQuery += "   THEN LEFT(cr.RESERVE_START_DATE, 8) ";

		// 예약 테이블에 없으면 기존 회원권 기간 fallback
		strQuery += "   ELSE CONCAT( ";
		strQuery += "     LEFT(mul.REGISTRATION_DATE, 8), ";
		strQuery += "     '-', ";
		strQuery += "     LEFT(mul.EXPIRATION_DATE, 8) ";
		strQuery += "   ) ";
		
		strQuery += " END as RESERVE_DATE, ";

		// 5. 시간
		// RESERVE_TIME이 있으면 추가사용 타입이어도 시간 표시
		// 예: 18001900 -> 18:00 ~ 19:00
		strQuery += " CASE ";

		strQuery += "   WHEN cr.RESERVE_TIME IS NOT NULL ";
		strQuery += "    AND cr.RESERVE_TIME != '' ";
		strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
		strQuery += "   THEN CONCAT( ";
		strQuery += "     SUBSTRING(cr.RESERVE_TIME, 1, 2), ";
		strQuery += "     ':', ";
		strQuery += "     SUBSTRING(cr.RESERVE_TIME, 3, 2), ";
		strQuery += "     ' ~ ', ";
		strQuery += "     SUBSTRING(cr.RESERVE_TIME, 5, 2), ";
		strQuery += "     ':', ";
		strQuery += "     SUBSTRING(cr.RESERVE_TIME, 7, 2) ";
		strQuery += "   ) ";

		strQuery += "   ELSE '' ";
		strQuery += " END as TIME, ";

		// 6. 이미지
		strQuery += " ac.IMAGE, ";		

		// 7. 장소 / 예약 후 추가사용 타입이면 사용횟수 표시
		strQuery += " CASE ";
		strQuery += "   WHEN mi.RESERVATION_TYPE = '" + RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE + "' ";
		strQuery += "   THEN CONCAT('USE_COUNT:', IFNULL(cr.RESERVE_COUNT, '0')) ";
		strQuery += "   ELSE '' ";
		strQuery += " END as PLACE, ";

		// 8. 취소상태
		strQuery += " CASE ";
		strQuery += "   WHEN mul.CANCEL_DATE IS NOT NULL ";
		strQuery += "     OR cr.RESERVE_CANCEL_TIME IS NOT NULL ";
		strQuery += "   THEN '1' ";
		strQuery += "   ELSE '0' ";
		strQuery += " END AS CANCEL_STATUS, ";

		// 계산용
		strQuery += " mul.COMMUNITY_TYPE, ";
		strQuery += " ac.START_TIME, ";
		strQuery += " ac.END_TIME, ";
		strQuery += " ac.OPERATION_HOURS, ";
		strQuery += " ac.COMMUNITY_STATE, ";
		strQuery += " '0' as GENDER, ";
		strQuery += " IFNULL(mul.USER_NAME, '') as USER_NAME, ";
		strQuery += " IFNULL(cr.RESERVE_TIME, '') as RESERVE_TIME_RAW, ";
		strQuery += " IFNULL(mi.RESERVATION_TYPE, '') as RESERVATION_TYPE, ";
		strQuery += " IFNULL(mi.NAME, '') as MEMBERSHIP_NAME ";

		strQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST as mul ";

		strQuery += " LEFT JOIN APT_COMMUNITY_MEMBERSHIP_INFO mi ";
		strQuery += "   ON mi.MEMBERSHIP_ID = mul.MEMBERSHIP_ID ";

		strQuery += " LEFT JOIN ( ";
		strQuery += "   SELECT ";
		strQuery += "     MEMBERSHIP_USER_LIST_ID, ";

		// get_reservation_list와 동일하게 예약 테이블의 RESERVE_ID 사용
		// 동일한 MEMBERSHIP_USER_LIST_ID에 예약이 여러 개면 가장 최근 RESERVE_ID를 선택
		strQuery += "     MAX(RESERVE_ID) AS RESERVE_ID, ";

		strQuery += "     MIN(DATE) AS RESERVE_START_DATE, ";
		strQuery += "     MAX(EXPIRATION_DATE) AS RESERVE_EXPIRATION_DATE, ";
		strQuery += "     MAX(RESERVE_CANCEL_TIME) AS RESERVE_CANCEL_TIME, ";
		strQuery += "     MAX(TIME) AS RESERVE_TIME, ";
		strQuery += "     COUNT(*) AS RESERVE_COUNT, ";

		// EXPIRATION_DATE가 오늘 현재 시간보다 지났으면 1, 아니면 0
		// 0이 먼저 오고, 1이 아래로 내려가게 정렬용으로 사용
		strQuery += "     MIN( ";
		strQuery += "       CASE ";
		strQuery += "         WHEN EXPIRATION_DATE IS NOT NULL ";
		strQuery += "          AND EXPIRATION_DATE != '' ";
		strQuery += "          AND STR_TO_DATE(LEFT(EXPIRATION_DATE, 14), '%Y%m%d%H%i%s') < SYSDATE() ";
		strQuery += "         THEN 1 ";
		strQuery += "         ELSE 0 ";
		strQuery += "       END ";
		strQuery += "     ) AS EXPIRED_SORT, ";

		// DATE가 오늘 날짜와 얼마나 가까운지 계산
		// 작을수록 오늘과 가까움
		strQuery += "     MIN( ";
		strQuery += "       ABS( ";
		strQuery += "         DATEDIFF( ";
		strQuery += "           STR_TO_DATE(LEFT(DATE, 8), '%Y%m%d'), ";
		strQuery += "           DATE(SYSDATE()) ";
		strQuery += "         ) ";
		strQuery += "       ) ";
		strQuery += "     ) AS DATE_DIFF_SORT ";

		strQuery += "   FROM APT_COMMUNITY_RESERVE ";
		strQuery += "   WHERE APT_CODE = '" + strAptCode + "' ";
		// strQuery += "   AND RESERVE_CANCEL_TIME IS NULL ";
		strQuery += "   GROUP BY MEMBERSHIP_USER_LIST_ID ";
		strQuery += " ) as cr ON cr.MEMBERSHIP_USER_LIST_ID = mul.MEMBERSHIP_USER_LIST_ID ";

		strQuery += " LEFT JOIN ( ";
		strQuery += "   SELECT ";
		strQuery += "     COMMUNITY_TYPE, ";
		strQuery += "     MAX(NULLIF(TITLE, '')) as TITLE, ";
		strQuery += "     MAX(NULLIF(IMAGE, '')) as IMAGE, ";
		strQuery += "     MAX(START_TIME) as START_TIME, ";
		strQuery += "     MAX(END_TIME) as END_TIME, ";
		strQuery += "     MAX(OPERATION_HOURS) as OPERATION_HOURS, ";
		strQuery += "     MAX(COMMUNITY_STATE) as COMMUNITY_STATE ";
		strQuery += "   FROM APT_COMMUNITY ";
		strQuery += "   WHERE APT_CODE = '" + strAptCode + "' ";
		strQuery += "   GROUP BY COMMUNITY_TYPE ";
		strQuery += " ) as ac ON ac.COMMUNITY_TYPE = mul.COMMUNITY_TYPE ";
		
		strQuery += " LEFT JOIN PARTNER_PAYMENT pp  ";
		strQuery += "   ON mul.MEMBERSHIP_USER_LIST_ID = pp.RESERVATION_ID ";

		strQuery += " WHERE mul.APT_CODE = '" + strAptCode + "' ";

		strQuery += " AND ( ";
		strQuery += "      mul.USER_ID = '" + strUserId + "' ";
		strQuery += "      OR ( ";
		strQuery += "           mul.USER_ID != '" + strUserId + "' ";
		strQuery += "       AND mul.USER_DONG = '" + strDong + "' ";
		strQuery += "       AND mul.USER_HO = '" + strHo + "' ";
		strQuery += "       AND mul.USER_NAME = '" + strUserName + "' ";
		strQuery += "      ) ";
		strQuery += " ) ";
		strQuery += " AND (pp.RESERVATION_ID IS NULL OR pp.STATE != '0') ";

		// 취소된 회원권 제외
		// strQuery += " AND mul.CANCEL_DATE IS NULL ";

		// 만료된 회원권 제외
		// strQuery += " AND mul.EXPIRATION_DATE IS NOT NULL ";
		// strQuery += " AND mul.EXPIRATION_DATE != '' ";
		// strQuery += " AND STR_TO_DATE(LEFT(mul.EXPIRATION_DATE, 8), '%Y%m%d') >= CURDATE() ";

		// 등록일 없는 데이터 제외
		// strQuery += " AND mul.REGISTRATION_DATE IS NOT NULL ";
		// strQuery += " AND mul.REGISTRATION_DATE != '' ";

		// 오늘 이후 등록 예정/시작 회원권만 보고 싶으면 추가
		// strQuery += " AND STR_TO_DATE(LEFT(mul.REGISTRATION_DATE, 8), '%Y%m%d') >= CURDATE() ";

				strQuery += " ORDER BY ";

				// =====================================================
				// 1. 이용완료된 항목을 가장 아래로 정렬
				//
				// 시간 예약:
				// 예약 종료시간 + 15분이 현재시간보다 지나면 이용완료
				//
				// 기간형 예약/회원권:
				// 만료일이 오늘보다 이전이면 이용완료
				// =====================================================
				strQuery += " CASE ";

				// 시간 예약 이용완료
				strQuery += "   WHEN cr.RESERVE_TIME IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_TIME != '' ";
				strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
				strQuery += "    AND cr.RESERVE_START_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_START_DATE != '' ";
				strQuery += "    AND DATE_ADD( ";
				strQuery += "          STR_TO_DATE( ";
				strQuery += "            CONCAT( ";
				strQuery += "              LEFT(cr.RESERVE_START_DATE, 8), ";
				strQuery += "              SUBSTRING(cr.RESERVE_TIME, 5, 4) ";
				strQuery += "            ), ";
				strQuery += "            '%Y%m%d%H%i' ";
				strQuery += "          ), ";
				strQuery += "          INTERVAL 15 MINUTE ";
				strQuery += "        ) < SYSDATE() ";
				strQuery += "   THEN 1 ";

				// 시간 없는 기간형 예약 이용완료
				strQuery += "   WHEN ( ";
				strQuery += "          cr.RESERVE_TIME IS NULL ";
				strQuery += "          OR cr.RESERVE_TIME = '' ";
				strQuery += "        ) ";
				strQuery += "    AND cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_EXPIRATION_DATE != '' ";
				strQuery += "    AND STR_TO_DATE( ";
				strQuery += "          LEFT(cr.RESERVE_EXPIRATION_DATE, 8), ";
				strQuery += "          '%Y%m%d' ";
				strQuery += "        ) < CURDATE() ";
				strQuery += "   THEN 1 ";

				// 예약 데이터가 없는 회원권 이용완료
				strQuery += "   WHEN ( ";
				strQuery += "          cr.RESERVE_EXPIRATION_DATE IS NULL ";
				strQuery += "          OR cr.RESERVE_EXPIRATION_DATE = '' ";
				strQuery += "        ) ";
				strQuery += "    AND mul.EXPIRATION_DATE IS NOT NULL ";
				strQuery += "    AND mul.EXPIRATION_DATE != '' ";
				strQuery += "    AND STR_TO_DATE( ";
				strQuery += "          LEFT(mul.EXPIRATION_DATE, 8), ";
				strQuery += "          '%Y%m%d' ";
				strQuery += "        ) < CURDATE() ";
				strQuery += "   THEN 1 ";

				strQuery += "   ELSE 0 ";
				strQuery += " END ASC, ";

				// =====================================================
				// 1. 취소되지 않은 항목 우선
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN mul.CANCEL_DATE IS NOT NULL ";
				strQuery += "     OR cr.RESERVE_CANCEL_TIME IS NOT NULL ";
				strQuery += "   THEN 1 ";
				strQuery += "   ELSE 0 ";
				strQuery += " END ASC, ";

				// =====================================================
				// 2. 일일권 먼저, 기간형 회원권은 나중
				//
				// 일일권:
				// - 예약 시작일 있음
				// - 예약 종료일 없음
				//
				// 회원권:
				// - 시작일과 종료일 모두 있음
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_START_DATE != '' ";
				strQuery += "    AND ( ";
				strQuery += "         cr.RESERVE_EXPIRATION_DATE IS NULL ";
				strQuery += "         OR cr.RESERVE_EXPIRATION_DATE = '' ";
				strQuery += "    ) ";
				strQuery += "   THEN 0 ";
				strQuery += "   ELSE 1 ";
				strQuery += " END ASC, ";

				// =====================================================
				// 3. 일일권은 오늘 날짜와 가까운 순
				//
				// 오늘: 0
				// 내일/어제: 1
				// 모레/그제: 2
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_START_DATE != '' ";
				strQuery += "    AND ( ";
				strQuery += "         cr.RESERVE_EXPIRATION_DATE IS NULL ";
				strQuery += "         OR cr.RESERVE_EXPIRATION_DATE = '' ";
				strQuery += "    ) ";
				strQuery += "   THEN ABS( ";
				strQuery += "     DATEDIFF( ";
				strQuery += "       STR_TO_DATE(LEFT(cr.RESERVE_START_DATE, 8), '%Y%m%d'), ";
				strQuery += "       CURDATE() ";
				strQuery += "     ) ";
				strQuery += "   ) ";
				strQuery += "   ELSE NULL ";
				strQuery += " END ASC, ";

				// =====================================================
				// 4. 같은 날짜의 일일권은 예약 시작시간 빠른 순
				// RESERVE_TIME 예: 18001900
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN cr.RESERVE_START_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_START_DATE != '' ";
				strQuery += "    AND ( ";
				strQuery += "         cr.RESERVE_EXPIRATION_DATE IS NULL ";
				strQuery += "         OR cr.RESERVE_EXPIRATION_DATE = '' ";
				strQuery += "    ) ";
				strQuery += "    AND cr.RESERVE_TIME IS NOT NULL ";
				strQuery += "    AND LENGTH(cr.RESERVE_TIME) = 8 ";
				strQuery += "   THEN LEFT(cr.RESERVE_TIME, 4) ";
				strQuery += "   ELSE NULL ";
				strQuery += " END ASC, ";

				// =====================================================
				// 5. 기간형 회원권은 아직 만료되지 않은 항목 우선
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN ( ";
				strQuery += "        cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
				strQuery += "        AND cr.RESERVE_EXPIRATION_DATE != '' ";
				strQuery += "        AND STR_TO_DATE( ";
				strQuery += "              LEFT(cr.RESERVE_EXPIRATION_DATE, 8), ";
				strQuery += "              '%Y%m%d' ";
				strQuery += "            ) >= CURDATE() ";
				strQuery += "   ) ";
				strQuery += "   OR ( ";
				strQuery += "        ( ";
				strQuery += "          cr.RESERVE_EXPIRATION_DATE IS NULL ";
				strQuery += "          OR cr.RESERVE_EXPIRATION_DATE = '' ";
				strQuery += "        ) ";
				strQuery += "        AND mul.EXPIRATION_DATE IS NOT NULL ";
				strQuery += "        AND mul.EXPIRATION_DATE != '' ";
				strQuery += "        AND STR_TO_DATE( ";
				strQuery += "              LEFT(mul.EXPIRATION_DATE, 8), ";
				strQuery += "              '%Y%m%d' ";
				strQuery += "            ) >= CURDATE() ";
				strQuery += "   ) ";
				strQuery += "   THEN 0 ";
				strQuery += "   ELSE 1 ";
				strQuery += " END ASC, ";

				// =====================================================
				// 6. 기간형 회원권은 만료일이 가까운 순
				// =====================================================
				strQuery += " CASE ";
				strQuery += "   WHEN cr.RESERVE_EXPIRATION_DATE IS NOT NULL ";
				strQuery += "    AND cr.RESERVE_EXPIRATION_DATE != '' ";
				strQuery += "   THEN STR_TO_DATE( ";
				strQuery += "     LEFT(cr.RESERVE_EXPIRATION_DATE, 8), ";
				strQuery += "     '%Y%m%d' ";
				strQuery += "   ) ";

				strQuery += "   WHEN mul.EXPIRATION_DATE IS NOT NULL ";
				strQuery += "    AND mul.EXPIRATION_DATE != '' ";
				strQuery += "   THEN STR_TO_DATE( ";
				strQuery += "     LEFT(mul.EXPIRATION_DATE, 8), ";
				strQuery += "     '%Y%m%d' ";
				strQuery += "   ) ";

				strQuery += "   ELSE NULL ";
				strQuery += " END ASC, ";

				// =====================================================
				// 7. 최종 보조 정렬
				// =====================================================
				strQuery += " mul.MEMBERSHIP_USER_LIST_ID DESC ";

		int nLimitCnt = 10;

		if(strLimitCnt != null && !strLimitCnt.contentEquals("") && !strLimitCnt.contentEquals("0")) {
			nLimitCnt = Integer.parseInt(strLimitCnt);
		}

		if(strItemCount != null && !strItemCount.contentEquals("") && !strItemCount.contentEquals("0")) {
			int nItemCount = Integer.parseInt(strItemCount);
			strQuery += " LIMIT " + nItemCount + ", " + nLimitCnt;
		} else {
			strQuery += " LIMIT " + nLimitCnt;
		}

		printLog("D", "get_membership_user_list strQuery : " + strQuery);

		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();
		rsMetaData = rs.getMetaData();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		String strCommunityType = "";
		String strSecurity = "";
		String strQRId = "";
		String strQRSecurityCode = "";
		String strStartTime = "";
		String strEndTime = "";
		String strOperationHours = "";
		String strCommunityState = "";
		String strActualStartTime = "";
		String strActualEndTime = "";
		String strState = "";
		String strGender = "";
		String strMembershipUserName = "";
		// String reservationType = "";
		String strReserveTimeRaw = "";
		String strReservationType = "";
		String strCancelStatus = "";
		String strMembershipName = "";
		String strDiffDate = "";

		for(int nRow = 0; rs.next(); nRow++) {

			strCommunityType = "";
			strSecurity = "";
			strQRId = "";
			strQRSecurityCode = "";
			strStartTime = "";
			strEndTime = "";
			strOperationHours = "";
			strActualStartTime = "";
			strActualEndTime = "";
			strState = "";
			strGender = "";
			strMembershipUserName = "";
			strReserveTimeRaw = "";
			strReservationType = "";
			strCancelStatus = "";
			strMembershipName = "";
			strDiffDate = "";
			strCommunityState = "";

			// PLACE 출력 시점보다 MEMBERSHIP_NAME 컬럼 순서가 뒤에 있어서,
			// 컬럼 루프 전에 미리 꺼내둔다.
			strMembershipName = rs.getString("MEMBERSHIP_NAME") != null ? rs.getString("MEMBERSHIP_NAME") : "";

			boolean isAdditionalAfterPurchase = false;

			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";

				if(nCol <= 8) {
					// 3번째 컬럼 = DIFF_DATE
					if(nCol == 3) {
						strDiffDate = strData;
					}

					// 4번째 컬럼 = RESERVE_DATE
					if(nCol == 4 && strData != null && !strData.contentEquals("")) {

						// 단일 날짜: 20260708
						if(strData.matches("\\d{8}")) {

							strData = formatDate(strData);

						// 기간 날짜: 20260708-20310707
						} else if(strData.matches("\\d{8}-\\d{8}")) {

							String[] dateRange = strData.split("-");

							String strStartDate = dateRange[0];
							String strExpirationDate = dateRange[1];

							// 시작일과 종료일이 같으면 날짜 하나만 표시
							if(strStartDate.contentEquals(strExpirationDate)) {
								strData = formatDate(strStartDate);
							} else {
								strData =
									formatDate(strStartDate)
									+ " ~ "
									+ formatDate(strExpirationDate);
							}
						}
					}

					// 8번째 컬럼 = CANCEL_STATUS
					if(nCol == 8) {
						strCancelStatus = strData;
					}

					if(nCol == 7 && strData.startsWith("USE_COUNT:")) {
						String strCount = strData.replace("USE_COUNT:", "");

						// 한글 문구는 SQL에서 만들지 않고 Java에서 S_CHARSET으로 출력한다.
						// 예: 스크린골프 30분 회원권 / 사용횟수 2회
						String strUseCountText = "사용횟수 " + strCount + "회";

						if(strMembershipName != null && !strMembershipName.contentEquals("")) {
							strUseCountText = strMembershipName + " / " + strUseCountText;
						}

						baOutStream.write(strUseCountText.getBytes(S_CHARSET));
					} else if(nCol == 7 && !strData.isEmpty()) {

						String placeValue = strData;

						if("PLACE_ALL".equals(placeValue)) {
							placeValue = "대관";
						}

						baOutStream.write(("예약 자리 : " + placeValue).getBytes(S_CHARSET));

						System.out.println("RAW_DATA = [" + placeValue + "]");

					} else if(nCol == 7 && strData.isEmpty()) {

						baOutStream.write(strMembershipName.getBytes(S_CHARSET));

					} else {
						baOutStream.write(strData.getBytes(S_CHARSET));
					}
					baOutStream.write(COLUMN_DEL);
				} else if(nCol == 9) {
					strCommunityType = strData;

				} else if(nCol == 10) {
					strStartTime = strData;

				} else if(nCol == 11) {
					strEndTime = strData;
				} else if(nCol == 12) {
					strOperationHours = strData;
				} else if(nCol == 13) {
					strCommunityState = strData;
				} else if(nCol == 14) {
					strGender = strData;
				} else if(nCol == 15) {
					strMembershipUserName = strData;
				} else if(nCol == 16) {
					strReserveTimeRaw = strData;
				} else if(nCol == 17) {
					strReservationType = strData;
				} else if(nCol == 18) {
					strMembershipName = strData;
				}
			}

			if(strReservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE)) {
				isAdditionalAfterPurchase = true;
			}

			 // SECURITY 조회
			String strSecurityQuery = "";
			strSecurityQuery += " SELECT SECURITY ";
			strSecurityQuery += " FROM APT_COMMUNITY ";
			strSecurityQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
			strSecurityQuery += " AND APT_CODE = '" + strAptCode + "' ";
			strSecurityQuery += " AND ( GENDER = 0 OR GENDER = '" + strGender + "' ) ";

			printLog("A", "get_membership_list strSecurityQuery : " + strSecurityQuery);

			PreparedStatement pstmtSecurity = null;
			ResultSet rsSecurity = null;

			try {
				pstmtSecurity = conn.prepareStatement(strSecurityQuery);
				rsSecurity = pstmtSecurity.executeQuery();

				if(rsSecurity.next()){
					strSecurity = rsSecurity.getString(1) != null ? rsSecurity.getString(1) : "";
				}
			} finally {
				if(rsSecurity != null) try { rsSecurity.close(); } catch(Exception e) {}
				if(pstmtSecurity != null) try { pstmtSecurity.close(); } catch(Exception e) {}
			}

			boolean isSameUserName = true;

			if(strUserName != null && !strUserName.contentEquals("")) {
				isSameUserName = strUserName.contentEquals(strMembershipUserName);
			}

			// if(strUserName != null && !strUserName.contentEquals("")) {
			// 	strQuery += " AND ( ";
			// 	strQuery += "      mul.USER_ID = '" + strUserId + "' ";
			// 	strQuery += "      OR mul.USER_NAME = '" + strUserName + "' ";
			// 	strQuery += " ) ";
			// } else {
			// 	strQuery += " AND mul.USER_ID = '" + strUserId + "' ";
			// }

			boolean isNotExpired = true;

			if(strDiffDate != null && !strDiffDate.contentEquals("")) {
				try {
					isNotExpired = Integer.parseInt(strDiffDate) >= 0;
				} catch(Exception e) {
					isNotExpired = false;
				}
			}

			// SECURITY가 QR 보안인 경우 QR 정보 조회
			// if(!isAdditionalAfterPurchase 
			// 	&& strSecurity != null 
			// 	&& strSecurity.contentEquals("2") 
			// 	&& isSameUserName
			// 	&& strCancelStatus.contentEquals("0")
			// 	&& isNotExpired) {
				
			// 	String strQRInfoQuery = "";
			// 	strQRInfoQuery += " SELECT ID, SECURITY_CODE ";
			// 	strQRInfoQuery += " FROM APT_COMMUNITY_QR ";
			// 	strQRInfoQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
			// 	strQRInfoQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
			// 	strQRInfoQuery += " AND ( GENDER = 0 OR GENDER = '" + strGender + "' ) ";

			// 	printLog("A", "get_membership_list strQRInfoQuery : " + strQRInfoQuery);

			// 	PreparedStatement pstmtQRInfo = null;
			// 	ResultSet rsQRInfo = null;

			// 	try {
			// 		pstmtQRInfo = conn.prepareStatement(strQRInfoQuery);
			// 		rsQRInfo = pstmtQRInfo.executeQuery();

			// 		if(rsQRInfo.next()){
			// 			strQRId = rsQRInfo.getString(1) != null ? rsQRInfo.getString(1) : "";
			// 			strQRSecurityCode = rsQRInfo.getString(2) != null ? rsQRInfo.getString(2) : "";
			// 		}
			// 	} finally {
			// 		if(rsQRInfo != null) try { rsQRInfo.close(); } catch(Exception e) {}
			// 		if(pstmtQRInfo != null) try { pstmtQRInfo.close(); } catch(Exception e) {}
			// 	}
			// } else {
			// 	strQRId = "";
			// 	strQRSecurityCode = "";
			// }

			// 실제 QR 시간 계산
			// 예약 시간이 있으면 예약 시간 우선
			// 예약 시간이 없으면 OPERATION_HOURS 우선, 없으면 START_TIME + END_TIME 사용
			String strTimeForCalc = "";

			if(strReserveTimeRaw != null 
				&& !strReserveTimeRaw.contentEquals("") 
				&& strReserveTimeRaw.length() == 8) {

				// 예: 14301500
				strTimeForCalc = strReserveTimeRaw;

			} else if(strOperationHours != null && !strOperationHours.contentEquals("")) {

				SimpleDateFormat sdfOperationHours = new SimpleDateFormat("yyyyMMdd");
				String currentDateTime = sdfOperationHours.format(new Date());
				Date dateOperationHours = sdfOperationHours.parse(currentDateTime);

				Calendar calendarOperationHours = Calendar.getInstance();
				calendarOperationHours.setTime(dateOperationHours);

				int dayOfWeek = calendarOperationHours.get(Calendar.DAY_OF_WEEK);

				String strStartTimeJson = "";
				String strEndTimeJson = "";

				if (dayOfWeek == Calendar.SATURDAY || dayOfWeek == Calendar.SUNDAY) {
					strStartTimeJson = extractValue(strOperationHours, "WEEKEND", "start");
					strEndTimeJson = extractValue(strOperationHours, "WEEKEND", "end");
				} else {
					strStartTimeJson = extractValue(strOperationHours, "WEEKDAY", "start");
					strEndTimeJson = extractValue(strOperationHours, "WEEKDAY", "end");
				}

				strTimeForCalc = strStartTimeJson + strEndTimeJson;

			} else {
				strTimeForCalc = strStartTime + strEndTime;
			}

			// =====================================================
			// 시설 운영상태 계산용 운영시간
			// 예약시간과 분리해서 사용
			// =====================================================

			String strFacilityStartTime = "";
			String strFacilityEndTime = "";

			if(strOperationHours != null
				&& !strOperationHours.contentEquals("")) {

				Calendar facilityCalendar =
					Calendar.getInstance();

				int facilityDayOfWeek =
					facilityCalendar.get(Calendar.DAY_OF_WEEK);

				if(facilityDayOfWeek == Calendar.SATURDAY
					|| facilityDayOfWeek == Calendar.SUNDAY) {

					strFacilityStartTime =
						extractValue(
							strOperationHours,
							"WEEKEND",
							"start"
						);

					strFacilityEndTime =
						extractValue(
							strOperationHours,
							"WEEKEND",
							"end"
						);

				} else {

					strFacilityStartTime =
						extractValue(
							strOperationHours,
							"WEEKDAY",
							"start"
						);

					strFacilityEndTime =
						extractValue(
							strOperationHours,
							"WEEKDAY",
							"end"
						);
				}

			} else {

				strFacilityStartTime =
					strStartTime != null
					? strStartTime.replace(":", "")
								.replace(" ", "")
					: "";

				strFacilityEndTime =
					strEndTime != null
					? strEndTime.replace(":", "")
								.replace(" ", "")
					: "";
			}

			if(strFacilityStartTime == null) {
				strFacilityStartTime = "";
			}

			if(strFacilityEndTime == null) {
				strFacilityEndTime = "";
			}

			// 휴무 조회
			List<Holiday> holidaysList = new ArrayList<Holiday>();

			PreparedStatement pstmtHolidays = null;
			ResultSet rsHolidays = null;

			try {
				pstmtHolidays = conn.prepareStatement(getHolidaysQuery(strAptCode, strCommunityType));
				rsHolidays = pstmtHolidays.executeQuery();

				while(rsHolidays.next()) {
					String strRepeatType = rsHolidays.getString(1);
					String strHoliDaysDayOfWeek = rsHolidays.getString(2);
					String strHolidaysDayOfMonth = rsHolidays.getString(3);
					String strSpecificType = rsHolidays.getString(4);
					String strSpecialDay = rsHolidays.getString(5);

					int nSpecificRepeatType = -1;
					int nHoliDaysDayOfWeek = -1;
					int nHolidaysDayOfMonth = -1;
					int nSpecificType = -1;

					if(strRepeatType != null && !strRepeatType.contentEquals("")) {
						nSpecificRepeatType = Integer.parseInt(strRepeatType);
					}

					if(strHoliDaysDayOfWeek != null && !strHoliDaysDayOfWeek.contentEquals("")) {
						nHoliDaysDayOfWeek = Integer.parseInt(strHoliDaysDayOfWeek);
					}

					if(strHolidaysDayOfMonth != null && !strHolidaysDayOfMonth.contentEquals("")) {
						nHolidaysDayOfMonth = Integer.parseInt(strHolidaysDayOfMonth);
					}

					if(strSpecificType != null && !strSpecificType.contentEquals("")) {
						nSpecificType = Integer.parseInt(strSpecificType);
					}

					if(strSpecialDay == null) strSpecialDay = "";

					holidaysList.add(new Holiday(
						nSpecificRepeatType,
						nHoliDaysDayOfWeek,
						nHolidaysDayOfMonth,
						nSpecificType,
						strSpecialDay
					));
				}
			} finally {
				if(rsHolidays != null) try { rsHolidays.close(); } catch(Exception e) {}
				if(pstmtHolidays != null) try { pstmtHolidays.close(); } catch(Exception e) {}
			}

			Calendar today = Calendar.getInstance();

			int todayDayOfWeek = today.get(Calendar.DAY_OF_WEEK) - 1;
			int todayDayOfMonth = today.get(Calendar.DAY_OF_MONTH);
			int weekOfMonth = today.get(Calendar.WEEK_OF_MONTH);

			SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmm");
			int nNowTime = Integer.parseInt(dateFormatHHmm.format(today.getTime()));

			boolean isHoliday = false;
			boolean isTempHoliday = false;

			SimpleDateFormat dateFormatYYYYMMDD = new SimpleDateFormat("yyyyMMdd");
			String formattedDateYYYYMMDD = dateFormatYYYYMMDD.format(today.getTime());

			for (Holiday holiday : holidaysList) {
				if (isTodayHoliday(holiday, todayDayOfWeek, todayDayOfMonth, weekOfMonth)) {
					isHoliday = true;
				} else {
					if(isTodayTempHoliday(holiday, formattedDateYYYYMMDD)) {
						isTempHoliday = true;
						isHoliday = true;
					}
				}
			}

			boolean bValidTime = (strTimeForCalc != null && strTimeForCalc.length() == 8);

			int nStartTime = 0;
			int nEndTime = 0;

			if(bValidTime) {

				boolean bHasReservationTime = (
					strReserveTimeRaw != null
					&& !strReserveTimeRaw.contentEquals("")
					&& strReserveTimeRaw.length() == 8
				);

				if(bHasReservationTime) {
					// 예약시간이 있는 경우 - 시작 -15분, 종료 +15분 (입장 융통성)
					SimpleDateFormat sdfHHmm = new SimpleDateFormat("HHmm");

					Calendar calStart = Calendar.getInstance();
					calStart.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTimeForCalc.substring(0, 2)));
					calStart.set(Calendar.MINUTE, Integer.parseInt(strTimeForCalc.substring(2, 4)));
					calStart.set(Calendar.SECOND, 0);
					calStart.add(Calendar.MINUTE, -15);

					Calendar calEnd = Calendar.getInstance();
					calEnd.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTimeForCalc.substring(4, 6)));
					calEnd.set(Calendar.MINUTE, Integer.parseInt(strTimeForCalc.substring(6, 8)));
					calEnd.set(Calendar.SECOND, 0);
					calEnd.add(Calendar.MINUTE, 15);

					strActualStartTime = sdfHHmm.format(calStart.getTime());
					strActualEndTime = sdfHHmm.format(calEnd.getTime());

					nStartTime = Integer.parseInt(strActualStartTime);
					nEndTime = Integer.parseInt(strActualEndTime);

				} else {
					// 예약시간이 없는 경우 - 운영시간 그대로 사용
					strActualStartTime = strTimeForCalc.substring(0, 4);
					strActualEndTime = strTimeForCalc.substring(4, 8);

					nStartTime = Integer.parseInt(strActualStartTime);
					nEndTime = Integer.parseInt(strActualEndTime);
				}
			}

			// if (isHoliday) {
			// 	strState = "2"; // 휴무
			// } else if (!bValidTime) {
			// 	strState = "4"; // 운영 종료
			// } else if (
			// 	(nStartTime <= nEndTime && nStartTime < nNowTime && nEndTime > nNowTime)
			// 	||
			// 	(nStartTime > nEndTime && (nNowTime > nStartTime || nNowTime < nEndTime))
			// ) {
			// 	strState = "1"; // 운영중
			// } else {
			// 	strState = strCommunityType.contentEquals(TYPE_GUESTHOUSE) ? "1" : "4";
			// }

			// =====================================================
			// 시설 운영시간 기준 strState 계산
			// =====================================================

			boolean bValidFacilityTime =
				strFacilityStartTime != null
				&& strFacilityEndTime != null
				&& strFacilityStartTime.length() == 4
				&& strFacilityEndTime.length() == 4;

			int nFacilityStartTime = 0;
			int nFacilityEndTime = 0;

			if(bValidFacilityTime) {
				try {
					nFacilityStartTime =
						Integer.parseInt(strFacilityStartTime);

					nFacilityEndTime =
						Integer.parseInt(strFacilityEndTime);

				} catch(NumberFormatException e) {
					bValidFacilityTime = false;
				}
			}

			if(isHoliday) {

				strState = "2";

			} else if(!bValidFacilityTime) {

				strState = "4";

			} else if(
				(
					nFacilityStartTime <= nFacilityEndTime
					&& nFacilityStartTime < nNowTime
					&& nFacilityEndTime > nNowTime
				)
				||
				(
					nFacilityStartTime > nFacilityEndTime
					&& (
						nNowTime > nFacilityStartTime
						|| nNowTime < nFacilityEndTime
					)
				)
			) {

				strState = "1";

			} else {

				strState =
					strCommunityType.contentEquals(TYPE_GUESTHOUSE)
					? "1"
					: "4";
			}

			// COMMUNITY_STATE가 이용 불가이면 최종 상태는 4
			if(strCommunityState != null
				&& strCommunityState.contentEquals(UNAVAILABLE)) {

				strState = "4";
			}

			// 기존 get_membership_list 응답 8개 뒤에 추가 응답값 write
			baOutStream.write(strQRId.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strQRSecurityCode.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strSecurity.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strActualStartTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strActualEndTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strState.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(RECORD_DEL);
		}
		returnData(baOutStream, outStream);
	}

}catch(Exception e) {
	ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
	String errMsg = "Exception Msg = " + e.getMessage();
	baOutStream.write(errMsg.getBytes(S_CHARSET));
	printLog("A", " ###### errMsg  = #####" + errMsg);

	// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
	returnData(baOutStream, outStream);
}
finally {
	// Release a database resources
	if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
	if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
	if(conn != null) { try { conn.close(); } catch(Exception ignore) {} }
}
%>

