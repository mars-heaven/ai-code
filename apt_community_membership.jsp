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

	//결제 
	public static String createOrederID() {
		// 랜덤4자리
		Random rand = new Random();
		String strRand = Integer.toString(rand.nextInt(9999));
		
		// 일시YYMMDDHHMMSSMS(15)
		SimpleDateFormat simpleDateFormat = new SimpleDateFormat("YYYYMMddHHmmssSSS");
		Date date = new Date();
		String strDate = simpleDateFormat.format(date);
		strDate = strDate.substring(2, 17);
		
		// 랜덤(4) + 일시(15)
		return strRand + strDate;
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



	public boolean callDevMembershipReservationAPI(String strUserId, String strReservationUserName, String strReservationUserPhone,
	 String strStartDate, String strEndDate, String strDoorId, String strAptCode, String strCommunityType, String strDong, String strHo, Connection conn){
		
		String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v11.jsp";
        String strCallSID = "call_reservation_membership_api";
        try {
			    

            // 쿼리 파라미터 인코딩
            String query = String.format("SID=%s&strUserId=%s&strReservationUserName=%s&strReservationUserPhone=%s&strStartDate=%s&strEndDate=%s&strDoorId=%s&strAptCode=%s&strCommunityType=%s&strDong=%s&strHo=%s",
					URLEncoder.encode(strCallSID, "UTF-8"),
					URLEncoder.encode(strUserId, "UTF-8"),
                    URLEncoder.encode(strReservationUserName, "UTF-8"),
                    URLEncoder.encode(strReservationUserPhone, "UTF-8"),
					URLEncoder.encode(strStartDate, "UTF-8"),
                    URLEncoder.encode(strEndDate, "UTF-8"),
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
		
		boolean isSuccess = true;
	
		return isSuccess;

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

	private String getHolidaysQuery(String aptCode, String communityType) {
		return "SELECT SPECIFIC_REPEAT_TYPE, SPECIFIC_DAY_OF_THE_WEEK, SPECIFIC_DAY_OF_THE_MONTH, SPECIFIC_TYPE, SPECIAL_DAY " +
			"FROM APT_COMMUNITY_SPECIFIC " +
			"WHERE APT_CODE = '" + aptCode + "' AND COMMUNITY_TYPE = '" + communityType + "' AND (SPECIFIC_TYPE = '0' OR SPECIFIC_TYPE = '3') ";
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

	private String getTimeQuery(String aptCode, String communityType) {
		return "SELECT  " +
			" START_TIME , END_TIME, " +
			" OPERATION_HOURS " +
			"FROM APT_COMMUNITY " +
			"WHERE APT_CODE = '" + aptCode + "'  "+
			" AND  COMMUNITY_TYPE= '" + communityType + "'  ";
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


	private boolean validateLastReservationPeriod(Connection conn, String membershipId, String strDong, String strHo, String strName, String aptCode) throws SQLException {
		String strUserMembershipListQuery = 
			"SELECT MEMBERSHIP_USER_LIST_ID " + 
			" FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
			" WHERE MEMBERSHIP_ID = ? " + // WHERE 절에서 중복된 WHERE 제거
			" AND APT_CODE  = ? " +
			" AND USER_DONG  = ? " +
			" AND USER_HO  = ? " +
			" AND USER_NAME  = ? " +	
			" ORDER BY MEMBERSHIP_USER_LIST_ID desc " +
			" LIMIT 1";

		PreparedStatement pstmt = conn.prepareStatement(strUserMembershipListQuery);
		pstmt.setString(1, membershipId);
		pstmt.setString(2, aptCode);
		pstmt.setString(3, strDong);
		pstmt.setString(4, strHo);
		pstmt.setString(5, strName);

		ResultSet rs = pstmt.executeQuery();
		String strMembershipListId = "0";
		if (rs.next()) {
			strMembershipListId = rs.getString("MEMBERSHIP_USER_LIST_ID");
		}

		String strValidateLastReservationQuery = 
			"SELECT DATE, TIME FROM APT_COMMUNITY_RESERVE " +
			"WHERE MEMBERSHIP_USER_LIST_ID = ?   " + 
			" AND USER_DONG = ? " +
			" AND USER_HO = ? " +
			" AND RESERVE_USER_NAME = ? " +		
			" AND APT_CODE = ? " +
			"AND RESERVE_CANCEL_TIME IS NULL " +
			"ORDER BY DATE desc, TIME desc LIMIT 1 ";

		pstmt = conn.prepareStatement(strValidateLastReservationQuery);
		pstmt.setString(1, strMembershipListId);
		pstmt.setString(2, strDong);
		pstmt.setString(3, strHo);
		pstmt.setString(4, strName);
		pstmt.setString(5, aptCode);
		rs = pstmt.executeQuery();

		printLog("D","strValidateLastReservationQuery : " + strValidateLastReservationQuery);

		if (rs.next()) {
			String date = rs.getString("DATE"); // yyyyMMdd 형식
			String time = rs.getString("TIME"); // hhmmhhmm 형식

			// TIME이 NULL이 아니고 빈 문자열이 아닐 때
			 if (time != null && !time.isEmpty()) {
				// DATE와 TIME을 합쳐서 datetime 문자열 생성
				String dateTimeString = date + time.substring(0, 4); // hhmm에서 hh만 사용
				SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmm");
				try {
					Date reservationDateTime = dateFormat.parse(dateTimeString);
					Date currentDateTime = new Date(); // 현재 시간

					// 예약 시간이 현재 시간보다 이전인지 확인
					return reservationDateTime.after(currentDateTime); // 이전이면 true
				} catch (ParseException e) {
					e.printStackTrace(); // 예외 처리
				}
        	}
		}
		return false; // 예약이 없거나 TIME이 NULL인 경우 false 반환
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

    if(strSID.contentEquals("get_membership")){
		// 회원권 조회
		String strCommunityType = getRequestParam(request, "CommunityType");
		String strAptCode = getRequestParam(request, "AptCode");
		String strUserId = getRequestParam(request, "UserId");
		String strGender = getRequestParam(request, "Gender");
		String strUUID = getRequestParam(request, "UUID");			
		String strDong = getRequestParam(request, "UserDong");
		String strHo = getRequestParam(request, "UserHo");
		String strUserName = getRequestParam(request, "UserName");

		
		// 내가 구매한 회원권에 사용 횟수가 회원권 정보에 한 번 제한 횟수랑 같은 경우
		// 그리고 구매한 회원에 만료일자랑 사용 일자가 현재 날짜 기준으로 유효한 경우 활성화된 회원권으로 취급

		// 내가 구매한 회원권에 커뮤니티 타입에 맞춰서 보여주는 경우 
	
		// 기존 회원권 아이디로 조회했다가, 독서실 같이 같은 시설에 여러 회원권이 있는 경우 둘 중 한개만 사용중으로 나오는 문제로
		// 커뮤니티 타입으로 비교하는 로직으로 수정

		// 기존2 회원권을 조회했을 때 예약을 취소했으면 회원권을 취소했다고 판단하는 로직에서
		// 골프장처럼 1달 회원권을 구매하고 예약 후 취소를 하면 회원권 자체는 유효한 회원권으로 처리

		String strMembershipIdQuery = "";
		strMembershipIdQuery += " SELECT ul.MEMBERSHIP_ID, LEFT(ul.REGISTRATION_DATE,8), LEFT(ul.EXPIRATION_DATE,8), mi.MEMBERSHIP_GROUP ";
		strMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST as ul";
		strMembershipIdQuery += " JOIN APT_COMMUNITY_MEMBERSHIP_INFO as mi ";
		strMembershipIdQuery += " ON mi.MEMBERSHIP_ID = ul.MEMBERSHIP_ID ";
		strMembershipIdQuery += " JOIN APT_COMMUNITY_RESERVE as cr ";
		strMembershipIdQuery += " ON cr.MEMBERSHIP_ID = ul.MEMBERSHIP_ID ";
		strMembershipIdQuery += " WHERE 1 = 1 ";
		strMembershipIdQuery += " AND STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW()  ";
		//strMembershipIdQuery += " AND STR_TO_DATE(ul.REGISTRATION_DATE, '%Y%m%d%H%i%s') <= NOW() ";
		strMembershipIdQuery += " AND ul.CANCEL_DATE IS NULL ";
		strMembershipIdQuery += " AND ul.APT_CODE = " + strAptCode + " ";
		strMembershipIdQuery += " AND ul.USER_DONG = '" + strDong + "' ";
		strMembershipIdQuery += " AND ul.USER_HO = '" + strHo + "' ";
		strMembershipIdQuery += " AND ul.USER_NAME = '" + strUserName + "' ";
		strMembershipIdQuery += " AND cr.USER_DONG = '" + strDong + "' ";		  
		strMembershipIdQuery += " AND cr.USER_HO = '" + strHo + "' ";		  
		strMembershipIdQuery += " AND cr.RESERVE_USER_NAME = '" + strUserName + "' ";
		strMembershipIdQuery += " AND ul.EXPIRATION_DATE != '' ";
		strMembershipIdQuery += " AND IF(mi.RESERVATION_TYPE = '1', 1=1, cr.RESERVE_CANCEL_TIME IS NULL ) ";
		strMembershipIdQuery += "GROUP BY cr.MEMBERSHIP_ID ";
		
		printLog("A","strMembershipIdQuery : "+ strMembershipIdQuery);

		pstmt = conn.prepareStatement(strMembershipIdQuery);
		rs = pstmt.executeQuery();

		List<String> listCommunityTypes = new ArrayList<String>();
		List<String> listRegistrationDate = new ArrayList<String>();
		List<String> listExpirationDate = new ArrayList<String>();
		List<String> listMembershipGroups = new ArrayList<String>();

			// Loop a select result records
		String strMembershipListId = "";
		String strRegistrationDate = "";
		String strExpirationDate = "";
		String strMembershipGroup = "";

		for(int nRow = 0; rs.next(); nRow++) {
			strMembershipListId = rs.getString(1);		
			listCommunityTypes.add(strMembershipListId);

			strRegistrationDate = rs.getString(2);		
			listRegistrationDate.add(strRegistrationDate);

			strExpirationDate = rs.getString(3);		
			listExpirationDate.add(strExpirationDate);

			strMembershipGroup = rs.getString(4);		
			listMembershipGroups.add(strMembershipGroup);

		}


		String strServiceTypeQuery = "SELECT SERVICE_TYPE ";
		strServiceTypeQuery += " FROM APT_COMMUNITY ";
		strServiceTypeQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strServiceTypeQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";

		pstmt = conn.prepareStatement(strServiceTypeQuery);
		rs = pstmt.executeQuery();

		String strCommunityServiceType = "";
		if(rs.next()){
			strCommunityServiceType = rs.getString(1);
		}

		// 유효한 회원권 존재 체크
		// 없으면 : 0 , 있으면 : 1

		String strCountQuery = "";
		strCountQuery += "SELECT COUNT(*) ";
		strCountQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ul ";
		strCountQuery += " JOIN APT_COMMUNITY_MEMBERSHIP_INFO mi ON ul.MEMBERSHIP_ID = mi.MEMBERSHIP_ID "; // 조인 추가
		strCountQuery += " WHERE STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() ";
		strCountQuery += " AND STR_TO_DATE(ul.REGISTRATION_DATE, '%Y%m%d%H%i%s') <= NOW() ";
		strCountQuery += " AND ul.CANCEL_DATE IS NULL ";
		strCountQuery += " AND ul.USER_DONG = '" + strDong + "' AND ul.USER_HO = '" + strHo + "' ";
		strCountQuery += " AND USER_NAME != '"+ strUserName + "' ";		
		strCountQuery += " AND mi.MEMBERSHIP_CONDITION = '0' "; // MEMBERSHIP_CONDITION이 0인 조건 추가
		strCountQuery += " AND ul.COMMUNITY_TYPE = '" + strCommunityType + "' AND ul.APT_CODE = " + strAptCode + " ";
		
		pstmt = conn.prepareStatement(strCountQuery);
		rs = pstmt.executeQuery();

		String strMembershipCount = "0";
		if(rs.next()){
			strMembershipCount = rs.getString(1);
		}

	

		//strMembershipCount 이 값이 1보다 크면 유효한 회원권이 존재
		// 할인된 회원권만 보여주는 코드 추가 

		
		String strSelectMemberShipQuery = "";
		if(Integer.parseInt(strMembershipCount) > 0){
			strSelectMemberShipQuery += "SELECT a.RESERVATION_TYPE, a.MEMBERSHIP_CANCEL_AVAILABLE, a.MEMBERSHIP_GROUP, ";
			strSelectMemberShipQuery += " a.MEMBERSHIP_ID, a.COMMUNITY_TYPE, a.NAME, a.DESCRIPTION,";
			strSelectMemberShipQuery += " a.PRICE, a.MEMBERSHIP_TYPE, a.IS_REQUIRED, a.MULTI_SELECT, ";
			strSelectMemberShipQuery += " a.GENDER_REQUIRED, DATE_FORMAT(a.VALIDITY_DATE_FROM, '%Y%m%d') as VALIDITY_DATE_FROM, ";
			strSelectMemberShipQuery += " DATE_FORMAT(a.VALIDITY_DATE_TO, '%Y%m%d') as VALIDITY_DATE_TO, ";	
			strSelectMemberShipQuery += " CASE ";
			strSelectMemberShipQuery += "    WHEN a.COMMUNITY_TYPE = '17' ";
			strSelectMemberShipQuery += "         AND a.PRIORITY_PURCHASE_DAY IS NOT NULL ";
			strSelectMemberShipQuery += "         AND a.PRIORITY_PURCHASE_DAY != '' ";
			strSelectMemberShipQuery += "         AND EXISTS ( ";
			strSelectMemberShipQuery += "             SELECT 1 FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST b ";
			strSelectMemberShipQuery += "             WHERE b.APT_CODE = " + strAptCode;
			strSelectMemberShipQuery += "             AND b.USER_DONG = '" + strDong + "' ";
			strSelectMemberShipQuery += "             AND b.USER_HO = '" + strHo + "' ";
			strSelectMemberShipQuery += "             AND b.USER_NAME = '" + strUserName + "' ";
			strSelectMemberShipQuery += "             AND b.COMMUNITY_TYPE = '17' ";
			strSelectMemberShipQuery += "             AND (b.CANCEL_DATE IS NULL OR b.CANCEL_DATE = '') ";
			strSelectMemberShipQuery += "             AND DATE_FORMAT(b.REGISTRATION_DATE, '%Y%m') = DATE_FORMAT(DATE_SUB(a.VALIDITY_DATE_FROM, INTERVAL 1 MONTH), '%Y%m') ";
			strSelectMemberShipQuery += "         ) ";
			strSelectMemberShipQuery += " THEN DATE_FORMAT(DATE_SUB(a.PURCHASABLE_DATE_FROM, INTERVAL a.PRIORITY_PURCHASE_DAY DAY), '%Y%m%d%H%i%s') ";
			strSelectMemberShipQuery += "         ELSE DATE_FORMAT(a.PURCHASABLE_DATE_FROM, '%Y%m%d%H%i%s') ";
			strSelectMemberShipQuery += " END as PURCHASABLE_DATE_FROM, ";
			strSelectMemberShipQuery += "  DATE_FORMAT(a.PURCHASABLE_DATE_TO, '%Y%m%d%H%i%s') AS PURCHASABLE_DATE_TO, a.PURCHASABLE_MAX_COUNT, ";
			strSelectMemberShipQuery += " (SELECT count(c.USER_ID) FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST c WHERE a.MEMBERSHIP_ID = c.MEMBERSHIP_ID AND (c.CANCEL_DATE is null or c.CANCEL_DATE = '')) as MEMBERSHIP_COUNT, ";
			strSelectMemberShipQuery += " a.USAGE_LIMIT, a.MAX_PURCHASE_LIMIT, a.VALIDITY_PERIOD, a.VALIDITY_PERIOD_UNIT, a.RESERVE_STANDARD, a.RESERVE_STANDARD_UNIT,   ";
			strSelectMemberShipQuery += " a.PREREQUISITE_MEMBERSHIP_ID, a.NEED_TO_PAY ";
			strSelectMemberShipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO AS a ";
			strSelectMemberShipQuery += " INNER JOIN ( ";
			strSelectMemberShipQuery += "	SELECT MEMBERSHIP_GROUP, MAX(MEMBERSHIP_CONDITION) AS max_condition ";
			strSelectMemberShipQuery += "	FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strSelectMemberShipQuery += "	WHERE APT_CODE = "+ strAptCode;
			strSelectMemberShipQuery += "	AND PARENT_ID = '"+ strCommunityType +"' ";
			strSelectMemberShipQuery += "   GROUP BY MEMBERSHIP_GROUP ";
			strSelectMemberShipQuery += " ) AS b ";
			strSelectMemberShipQuery += " ON a.MEMBERSHIP_GROUP = b.MEMBERSHIP_GROUP AND a.MEMBERSHIP_CONDITION = b.max_condition ";
			strSelectMemberShipQuery += " WHERE a.APT_CODE = "+ strAptCode +" ";
			strSelectMemberShipQuery += " AND a.PARENT_ID = '" + strCommunityType + "' ";
			strSelectMemberShipQuery += " AND (a.MEMBERSHIP_SHOW_DAY is null OR a.MEMBERSHIP_SHOW_DAY = '' ";
			strSelectMemberShipQuery += " 			OR DATE_FORMAT(DATE_SUB(a.PURCHASABLE_DATE_FROM, INTERVAL a.MEMBERSHIP_SHOW_DAY DAY), '%Y%m%d') <= DATE_FORMAT(NOW(), '%Y%m%d')) ";
			strSelectMemberShipQuery += " AND (a.VALIDITY_DATE_TO IS NULL OR a.VALIDITY_DATE_TO = '' OR DATE_FORMAT(a.VALIDITY_DATE_TO, '%Y%m%d') >= DATE_FORMAT(NOW(), '%Y%m%d')) ";
			strSelectMemberShipQuery += " AND (a.MEMBERSHIP_HIDDEN IS NULL OR a.MEMBERSHIP_HIDDEN = '0') ";
			// 성별 추가		
			strSelectMemberShipQuery += " AND a.GENDER in ('0', '" + strGender + "') ";
			strSelectMemberShipQuery += " ORDER BY a.MEMBERSHIP_CONDITION DESC, a.VALIDITY_DATE_FROM DESC, a.NAME ";
		}else{
			strSelectMemberShipQuery += "SELECT a.RESERVATION_TYPE, a.MEMBERSHIP_CANCEL_AVAILABLE, a.MEMBERSHIP_GROUP, ";
			strSelectMemberShipQuery += " a.MEMBERSHIP_ID, a.COMMUNITY_TYPE, a.NAME, a.DESCRIPTION, ";
			strSelectMemberShipQuery += " a.PRICE, a.MEMBERSHIP_TYPE, a.IS_REQUIRED, a.MULTI_SELECT, ";
			strSelectMemberShipQuery += " a.GENDER_REQUIRED, DATE_FORMAT(a.VALIDITY_DATE_FROM, '%Y%m%d') as VALIDITY_DATE_FROM, ";
			strSelectMemberShipQuery += " DATE_FORMAT(a.VALIDITY_DATE_TO, '%Y%m%d') as VALIDITY_DATE_TO , ";
			strSelectMemberShipQuery += " CASE ";
			strSelectMemberShipQuery += "    WHEN a.COMMUNITY_TYPE = '17' ";
			strSelectMemberShipQuery += "         AND a.PRIORITY_PURCHASE_DAY IS NOT NULL ";
			strSelectMemberShipQuery += "         AND a.PRIORITY_PURCHASE_DAY != '' ";
			strSelectMemberShipQuery += "         AND EXISTS ( ";
			strSelectMemberShipQuery += "             SELECT 1 FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST b ";
			strSelectMemberShipQuery += "             WHERE b.APT_CODE = " + strAptCode;
			strSelectMemberShipQuery += "             AND b.USER_DONG = '" + strDong + "' ";
			strSelectMemberShipQuery += "             AND b.USER_HO = '" + strHo + "' ";
			strSelectMemberShipQuery += "             AND b.USER_NAME = '" + strUserName + "' ";
			strSelectMemberShipQuery += "             AND b.COMMUNITY_TYPE = '17' ";
			strSelectMemberShipQuery += "             AND (b.CANCEL_DATE IS NULL OR b.CANCEL_DATE = '') ";
			strSelectMemberShipQuery += "             AND DATE_FORMAT(b.REGISTRATION_DATE, '%Y%m') = DATE_FORMAT(DATE_SUB(a.VALIDITY_DATE_FROM, INTERVAL 1 MONTH), '%Y%m') ";
			strSelectMemberShipQuery += "         ) THEN DATE_FORMAT(DATE_SUB(a.PURCHASABLE_DATE_FROM, INTERVAL a.PRIORITY_PURCHASE_DAY DAY), '%Y%m%d%H%i%s')  ";
			strSelectMemberShipQuery += "     ELSE DATE_FORMAT(a.PURCHASABLE_DATE_FROM, '%Y%m%d%H%i%s') ";
			strSelectMemberShipQuery += " END as PURCHASABLE_DATE_FROM, ";
			strSelectMemberShipQuery += " a.PURCHASABLE_DATE_TO, a.PURCHASABLE_MAX_COUNT, ";
			strSelectMemberShipQuery += " (SELECT count(b.USER_ID) FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST b WHERE a.MEMBERSHIP_ID = b.MEMBERSHIP_ID AND (b.CANCEL_DATE is null or b.CANCEL_DATE = '')) as MEMBERSHIP_COUNT, ";
			strSelectMemberShipQuery += " a.USAGE_LIMIT, a.MAX_PURCHASE_LIMIT, a.VALIDITY_PERIOD, a.VALIDITY_PERIOD_UNIT, a.RESERVE_STANDARD, a.RESERVE_STANDARD_UNIT,  ";
			strSelectMemberShipQuery += " a.PREREQUISITE_MEMBERSHIP_ID, a.NEED_TO_PAY ";
			strSelectMemberShipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO a ";
			strSelectMemberShipQuery += " WHERE 1 = 1 ";
			strSelectMemberShipQuery += " AND a.APT_CODE = " + strAptCode;
			strSelectMemberShipQuery += " AND a.PARENT_ID = '" + strCommunityType + "' ";
			strSelectMemberShipQuery += " AND a.MEMBERSHIP_CONDITION = '0' ";
			strSelectMemberShipQuery += " AND (a.MEMBERSHIP_SHOW_DAY is null OR a.MEMBERSHIP_SHOW_DAY = '' ";
			strSelectMemberShipQuery += " 			OR DATE_FORMAT(DATE_SUB(a.PURCHASABLE_DATE_FROM, INTERVAL a.MEMBERSHIP_SHOW_DAY DAY), '%Y%m%d') <= DATE_FORMAT(NOW(), '%Y%m%d')) ";
			strSelectMemberShipQuery += " AND (a.VALIDITY_DATE_TO IS NULL OR a.VALIDITY_DATE_TO = '' OR DATE_FORMAT(a.VALIDITY_DATE_TO, '%Y%m%d') >= DATE_FORMAT(NOW(), '%Y%m%d')) ";		
			strSelectMemberShipQuery += " AND (a.MEMBERSHIP_HIDDEN IS NULL OR a.MEMBERSHIP_HIDDEN = '0') ";		
			// 성별 추가
			strSelectMemberShipQuery += " AND a.GENDER in ('0', '" + strGender + "') ";		
			strSelectMemberShipQuery += " ORDER BY a.VALIDITY_DATE_FROM DESC, a.NAME ";
		}			

		
		
		printLog("A","strSelectMemberShipQuery : "+ strSelectMemberShipQuery);


		pstmt = conn.prepareStatement(strSelectMemberShipQuery);
		rs = pstmt.executeQuery();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		String strType = "";
		while (rs.next()) {
			String membershipId = rs.getString("MEMBERSHIP_ID");
			String name = rs.getString("NAME");
			if (name != null) {
				name = name.replace("*", "").replace("+", "");
			}
			String description = rs.getString("DESCRIPTION");
			String price = rs.getString("PRICE");
			String reservationType = rs.getString("RESERVATION_TYPE");
			String isRequired = rs.getString("IS_REQUIRED");
			String multiSelect = rs.getString("MULTI_SELECT");
			String genderRequired = rs.getString("GENDER_REQUIRED");
			String cancelAvailable = rs.getString("MEMBERSHIP_CANCEL_AVAILABLE");
			String MembershipType = rs.getString("MEMBERSHIP_TYPE");
			String MembershipGroup = rs.getString("MEMBERSHIP_GROUP");
			String ValidityDateFrom = rs.getString("VALIDITY_DATE_FROM") != null ? rs.getString("VALIDITY_DATE_FROM") : "";
			String ValidityDateTo = rs.getString("VALIDITY_DATE_TO") != null ? rs.getString("VALIDITY_DATE_TO") : "";
			String PurchasbleDateFrom = rs.getString("PURCHASABLE_DATE_FROM") != null ? rs.getString("PURCHASABLE_DATE_FROM") : "";
			String PurchasbleDateTo = rs.getString("PURCHASABLE_DATE_TO") != null ? rs.getString("PURCHASABLE_DATE_TO") : "";
			String PurchasbleMaxCount = rs.getString("PURCHASABLE_MAX_COUNT") != null ? rs.getString("PURCHASABLE_MAX_COUNT") : "";
			String MembershipCount = rs.getString("MEMBERSHIP_COUNT") != null ? rs.getString("MEMBERSHIP_COUNT") : "";
			int usageLimit = rs.getInt("USAGE_LIMIT");
			int remainingUses = 0;
			if(PurchasbleMaxCount.contentEquals("")){
				MembershipCount = "";
			}
			int nMaxPurchaseLimit = rs.getInt("MAX_PURCHASE_LIMIT");
			String ValidityPeriodUnit = rs.getString("VALIDITY_PERIOD_UNIT") != null ? rs.getString("VALIDITY_PERIOD_UNIT") : "";
			String ValidityPeriod = rs.getString("VALIDITY_PERIOD") != null ? rs.getString("VALIDITY_PERIOD") : "";
			String ReservationStandardUnit = rs.getString("RESERVE_STANDARD_UNIT") != null ? rs.getString("RESERVE_STANDARD_UNIT") : "";
			String ReservationStandard = rs.getString("RESERVE_STANDARD") != null ? rs.getString("RESERVE_STANDARD") : "";
			String PrerequisiteMembershipId = rs.getString("PREREQUISITE_MEMBERSHIP_ID") != null ? rs.getString("PREREQUISITE_MEMBERSHIP_ID") : "";	

			String NeedToPay = rs.getString("NEED_TO_PAY");
			if(NeedToPay == null || NeedToPay.contentEquals("")){
				NeedToPay = "0";
			}

			String strReservationStandardDay = "";
			if(ReservationStandardUnit.contentEquals(UNIT_DAYS) && !ReservationStandard.contentEquals("")){
				strReservationStandardDay = ReservationStandard;
			}


			
			// 회원권 구매 상태 및 사용기간 확인
			String purchaseStatus = "0";
			String membershipDate = "";
			int recordCount = 0;
			// 구매한 회원권이 
			String membershipUserListIds = "";

			/*String strUserMembershipQuery = 
			"SELECT ul.MEMBERSHIP_USER_LIST_ID, ul.REGISTRATION_DATE, ul.EXPIRATION_DATE " +
			" FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ul " +
			" WHERE ul.MEMBERSHIP_ID = ? " + 
			" AND ul.APT_CODE = ? " +
			" AND ul.USER_DONG = '" + strDong + "' " +
			" AND ul.USER_HO = '" + strHo + "' " +
			" AND ul.USER_NAME = '" + strUserName + "' " + 
			" AND STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() " +
			" AND STR_TO_DATE(ul.PURCHASE_DATE, '%Y%m%d%H%i%s') <= NOW() " +
			" AND ul.CANCEL_DATE IS NULL";


			PreparedStatement pstmtUser = conn.prepareStatement(strUserMembershipQuery);
			pstmtUser.setString(1, membershipId);
			pstmtUser.setString(2, strAptCode);
			ResultSet rsUser = pstmtUser.executeQuery();
			*/
			String strUserMembershipCountQuery = "";
			// strUserMembershipCountQuery += " SELECT EXISTS ( ";
			// strUserMembershipCountQuery += "		SELECT 1 ";
						strUserMembershipCountQuery += " SELECT ";
			strUserMembershipCountQuery += "     COUNT(DISTINCT ul.MEMBERSHIP_USER_LIST_ID) AS RECORD_COUNT, ";
			strUserMembershipCountQuery += "     GROUP_CONCAT( ";
			strUserMembershipCountQuery += "         DISTINCT ul.MEMBERSHIP_USER_LIST_ID ";
			strUserMembershipCountQuery += "         ORDER BY ul.MEMBERSHIP_USER_LIST_ID DESC ";
			strUserMembershipCountQuery += "         SEPARATOR ',' ";
			strUserMembershipCountQuery += "     ) AS MEMBERSHIP_USER_LIST_IDS ";
			// strUserMembershipCountQuery += "     MAX(ul.MEMBERSHIP_USER_LIST_ID) AS MEMBERSHIP_USER_LIST_ID ";
			strUserMembershipCountQuery += "		FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ul ";
			strUserMembershipCountQuery += "		LEFT JOIN PARTNER_PAYMENT b ";
			strUserMembershipCountQuery += "		 ON ul.MEMBERSHIP_USER_LIST_ID = b.RESERVATION_ID ";
			strUserMembershipCountQuery += "		WHERE ul.MEMBERSHIP_ID = " + membershipId + " ";
			strUserMembershipCountQuery += "		AND ul.APT_CODE = " + strAptCode + " ";
			strUserMembershipCountQuery += "		AND ul.USER_DONG = '" + strDong + "' ";
			strUserMembershipCountQuery += "		AND ul.USER_HO = '" + strHo + "' ";
			strUserMembershipCountQuery += "		AND ul.USER_NAME = '" + strUserName + "' ";
			strUserMembershipCountQuery += "		AND STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() ";
			strUserMembershipCountQuery += "		AND STR_TO_DATE(ul.PURCHASE_DATE, '%Y%m%d%H%i%s') <= NOW() ";
			strUserMembershipCountQuery += "		AND ul.CANCEL_DATE IS NULL ";
			strUserMembershipCountQuery += "		AND (b.RESERVATION_ID IS NULL OR b.STATE = '1') ";
			// strUserMembershipCountQuery += "	) AS is_exist ";

			pstmt = conn.prepareStatement(strUserMembershipCountQuery);
			ResultSet rsUserMembershipCount = pstmt.executeQuery();
			if(rsUserMembershipCount.next()){
				try{
					// recordCount = rsUserMembershipCount.getInt(1);
					recordCount = rsUserMembershipCount.getInt("RECORD_COUNT");

					membershipUserListIds = rsUserMembershipCount.getString("MEMBERSHIP_USER_LIST_IDS") != null ? rsUserMembershipCount.getString("MEMBERSHIP_USER_LIST_IDS") : "";

				}catch(Exception e){
					e.printStackTrace();		
				}
			}
			


			//if (rsUser.next()) {
			if (0 < recordCount) {
				//String regDate = rsUser.getString("REGISTRATION_DATE");
				//String expDate = rsUser.getString("EXPIRATION_DATE");

				printLog("A","strAptCode : "+ strAptCode);

				// 남은 사용 횟수 계산
				remainingUses = getRemainingUses(conn, membershipId, strDong, strHo, strUserName, strAptCode, usageLimit);

				printLog("A","remainingUses : "+ remainingUses);

				// 예약 타입과 취소 가능 여부, 남은 횟수에 따른 상태 설정
				if (usageLimit != 0 && remainingUses == 0) {
					if(validateLastReservationPeriod(conn, membershipId, strDong, strHo, strUserName, strAptCode)){
						// 마지막 사용일이 아직 안지났으면 사용중으로 표시
						purchaseStatus = cancelAvailable.equals(CANCEL_POSSIBLE) ? "3" : "1";
					}else{
						// 사용 제한이 있고 남은 횟수가 0이면 미구매 상태로 처리
						purchaseStatus = "0";
					}					
					membershipDate = description; // description을 표시
				} else {                
					for(int nMembershipCount = 0; nMembershipCount < listMembershipGroups.size(); nMembershipCount ++){					
						if(MembershipGroup.contentEquals(listMembershipGroups.get(nMembershipCount).toString())){
							// if(ValidityPeriodUnit.contentEquals(UNIT_DAYS) && ValidityPeriod.contentEquals("1")){
							// 	purchaseStatus = "0";
							// }else if(reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE)){
							// 	purchaseStatus = cancelAvailable.equals(CANCEL_POSSIBLE) ? "4" : "2";
							// }else if(reservationType.contentEquals(RESERVE_TYPE_ONE_OFF)){
							// 	purchaseStatus = "0";
							// }else{
							// 	purchaseStatus = cancelAvailable.equals(CANCEL_POSSIBLE) ? "3" : "1";
							// }

							if(reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE)) {
								purchaseStatus = cancelAvailable.equals(CANCEL_POSSIBLE) ? "4" : "2";
							} else if(reservationType.contentEquals(RESERVE_TYPE_ONE_OFF)) {
								purchaseStatus = "0";
							} else {
								purchaseStatus = cancelAvailable.equals(CANCEL_POSSIBLE) ? "3" : "1";
							}

							membershipDate = formatDate(listRegistrationDate.get(nMembershipCount).toString()) + " ~ " + formatDate(listExpirationDate.get(nMembershipCount).toString());												
						}
					}		
				}
			}

			printLog("D","remainingUses : " + remainingUses);
			String strData = description;

			if (ValidityDateTo != null && !ValidityDateTo.isEmpty() &&
				ValidityDateFrom != null && !ValidityDateFrom.isEmpty()) {			
			} else {
				if(membershipDate != null && !membershipDate.contentEquals("")){
					strData += "\n\n" + "이용권 기간 : " + membershipDate;
				}
			}
				

			// if(!reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE) && nMaxPurchaseLimit != 0 && nMaxPurchaseLimit <= recordCount){				
			// 	if(ValidityPeriodUnit.contentEquals(UNIT_DAYS) && ValidityPeriod.contentEquals("1")){
			// 		purchaseStatus = "0";
			// 	}else{
			// 		purchaseStatus = cancelAvailable.contentEquals(CANCEL_POSSIBLE) ? "3" : "1";
			// 	}
			// }else if(!reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE) && (nMaxPurchaseLimit == 0 || nMaxPurchaseLimit > recordCount)){
			// 	purchaseStatus = "0";
			// }

			if(!reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE) && nMaxPurchaseLimit != 0 && nMaxPurchaseLimit <= recordCount) {
				purchaseStatus = cancelAvailable.contentEquals(CANCEL_POSSIBLE) ? "3" : "1";
			} else if(!reservationType.contentEquals(RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE) && (nMaxPurchaseLimit == 0 || nMaxPurchaseLimit > recordCount)) {
				purchaseStatus = "0";
			}

			boolean isPrerequisite = false;

			// listCommunityTypes 회원권 아이디 리스트
			// 선행조건 회원권 아이디가 있는 경우 내가 구매한 회원권 리스트중에 유효한 회원권이 있으면 
			// 구매 가능 그 외 구매 불가능
			if(PrerequisiteMembershipId != null && !PrerequisiteMembershipId.contentEquals("")){		
				String[] splitStr = PrerequisiteMembershipId.split(",");
				for(int nPrerequisiteMembershipId = 0; nPrerequisiteMembershipId < splitStr.length; nPrerequisiteMembershipId++){
					for(String strPurchasedMembershipId : listCommunityTypes){
						if(strPurchasedMembershipId.contentEquals(splitStr[nPrerequisiteMembershipId])){
							// 하나라도 구매했으면 구매했다고 체크
							isPrerequisite = true;
						}
					}
				}
			}else{
				isPrerequisite = true;
			}

			printLog("A","isPrerequisite : " + isPrerequisite);	

			if(!isPrerequisite){
				purchaseStatus = "1";
			}
			
			String strSettlementCutoffDayQeury = "";
			strSettlementCutoffDayQeury += " SELECT COMMUNITY_SETTLEMENT_CUTOFF_DAY";
			strSettlementCutoffDayQeury += " FROM APT_CONFIG ";
			strSettlementCutoffDayQeury += " WHERE APT_CODE = " + strAptCode + " ";				
			pstmt = conn.prepareStatement(strSettlementCutoffDayQeury);
			ResultSet rsSettlement = pstmt.executeQuery();		
			
			String strSettlementCutoffDay = "";
			if(rsSettlement.next()) {
				strSettlementCutoffDay = rsSettlement.getString(1) != null ? rsSettlement.getString(1) : "";
			}

			printLog("D","strSettlementCutoffDayQeury : " + strSettlementCutoffDayQeury);	

			printLog("D","strSettlementCutoffDay : " + strSettlementCutoffDay);

			// 회원권 ID
			baOutStream.write(membershipId.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);		

			// 회원권 이름
			baOutStream.write(name.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 회원권 설명
			baOutStream.write(strData.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 가격
			baOutStream.write(price.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 다음 이동 페이지
			baOutStream.write(MembershipType.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 필수 선택 여부
			baOutStream.write(isRequired.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 다중 선택 여부
			baOutStream.write(multiSelect.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 성별 필수
			baOutStream.write(genderRequired.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 회원권 구매 여부
			baOutStream.write(purchaseStatus.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 내가 구매한 회원권의 MEMBERSHIP_USER_LIST_ID
			// 🚨🚨 동일한 MEMBERSHIP_ID를 여러 번 구매한 경우, MEMBERSHIP_USER_LIST_ID를 쉼표로 연결하여 전달한다.
			// 예: "103958,103957"
			// 앱에서 회원권별 취소가 필요할 경우, 쉼표로 구분된 ID를 분리하여 개별 처리하도록 보강 필요 // MEMO: - 박지은(2026.07.16)
			if(recordCount > 0) {
				baOutStream.write(membershipUserListIds.getBytes(S_CHARSET));
			} else {
				baOutStream.write("".getBytes(S_CHARSET));
			}
			baOutStream.write(COLUMN_DEL);

			// 회원권 유효기간 시작 날짜
			baOutStream.write(ValidityDateFrom.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 회원권 유효기간 마지막 날짜
			baOutStream.write(ValidityDateTo.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			
			// 회원권 구매 가능 시작 시간
			baOutStream.write(PurchasbleDateFrom.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 회원권 구매 가능 종료 시간
			baOutStream.write(PurchasbleDateTo.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 수강생 최대 인원
			baOutStream.write(PurchasbleMaxCount.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 수강생 현재 등록 인원
			baOutStream.write(MembershipCount.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);			

			// 남은 예약 횟수	
			if(usageLimit == 0 || (usageLimit != 0 && remainingUses == 0 && purchaseStatus.contentEquals("0"))){
				baOutStream.write("".getBytes(S_CHARSET));	
			}else{
				baOutStream.write(Integer.toString(remainingUses).getBytes(S_CHARSET));
			}
			baOutStream.write(COLUMN_DEL);	
			
						
			// 내가 구매한 회원권 개수
			if(nMaxPurchaseLimit != 0 && !reservationType.contentEquals(RESERVE_TYPE_ONE_OFF)){
				baOutStream.write(Integer.toString(recordCount).getBytes(S_CHARSET));
			}else{
				recordCount = 0;
				baOutStream.write(Integer.toString(recordCount).getBytes(S_CHARSET));
			}

			baOutStream.write(COLUMN_DEL);	
			
			// 최대 구매 가능한 회원권 수
			baOutStream.write(Integer.toString(nMaxPurchaseLimit).getBytes(S_CHARSET));				
			baOutStream.write(COLUMN_DEL);	

			// 취소 가능 여부
			baOutStream.write(cancelAvailable.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			// 예약 범위
			baOutStream.write(ValidityPeriod.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);		

			// 예약 범위 단위
			baOutStream.write(ValidityPeriodUnit.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);		

			// 예약 가능 기준일
			baOutStream.write(strReservationStandardDay.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	

			// 결제 여부
			baOutStream.write(NeedToPay.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			// 정산일자
			baOutStream.write(strSettlementCutoffDay.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);						
			
			baOutStream.write(RECORD_DEL);	
		}
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);
	}else if(strSID.contentEquals("get_membership_option")){
		// 회원권 옵션 조회
		String strMembershipId = getRequestParam(request, "MembershipId");
		
		String strSelectMemberShipOptionQuery = "";
		strSelectMemberShipOptionQuery += "SELECT OPTION_ID, OPTION_NAME, OPTION_PRICE, GENDER_REQUIRED ";
		strSelectMemberShipOptionQuery += " FROM APT_COMMUNITY_MEMBERSHIP_OPTION ";
		strSelectMemberShipOptionQuery += " WHERE 1 = 1 ";
		strSelectMemberShipOptionQuery += " AND MEMBERSHIP_ID = " + strMembershipId + " ";


		pstmt = conn.prepareStatement(strSelectMemberShipOptionQuery);
		rs = pstmt.executeQuery();

		rsMetaData = rs.getMetaData();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		for(int nRow = 0; rs.next(); nRow++) {
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";			
				baOutStream.write(strData.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			}
			baOutStream.write(RECORD_DEL);
		}
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(baOutStream, outStream);

	}else if(strSID.contentEquals("purchase_membership")){
		// 회원권 구매
		String strMembershipId = getRequestParam(request,"MembershipId");
		String strAptCode = getRequestParam(request, "AptCode");		
		String strUserId = getRequestParam(request,"UserId");	
		String strUserName = getRequestParam(request, "UserName");		
		String strUserDong = getRequestParam(request,"UserDong");	
		String strUserHo = getRequestParam(request, "UserHo");		
		String strCommunityType = getRequestParam(request, "CommunityType");		
		String strPrice = getRequestParam(request, "Price");		
		String strUserPhoneNo = getRequestParam(request, "UserPhoneNo");
		String strSeat = getRequestParam(request, "Seat");
		String strOptions = getRequestParam(request, "MembershipOption");
		String strReservationUserName = getRequestParam(request, "ReservationUserName");
		String strGender = getRequestParam(request, "Gender");
		String strUUID = getRequestParam(request, "UUID");
		String strValidityDateFrom = getRequestParam(request, "ValidityDateFrom");
		String strValidityDateTo = getRequestParam(request, "ValidityDateTo");
		String strPaymentId = getRequestParam(request, "PaymentId");
		String strReceiptId = getRequestParam(request, "ReceiptId");

printLog("A", "*** time test - " + strPaymentId + " : 1 구매 시작");	

		String strRequestLog = "";
		strRequestLog += "* MembershipId : " + strMembershipId + ", AptCode : " + strAptCode + ", CommunityType : " + strCommunityType + "\r\n";
		strRequestLog += "* UserId : " + strUserId + ", UserName : " + strUserName + ", UserDong : " + strUserDong + ", UserHo : " + strUserHo + ", UserPhoneNo : " + strUserPhoneNo + "\r\n";
		strRequestLog += "* ReservationUserName : " + strReservationUserName + ", Gender : " + strGender  + ", UUID : " + strUUID + "\r\n";
		strRequestLog += "* Seat : " + strSeat + ", MembershipOption : " + strOptions + ", ValidityDateFrom : " + strValidityDateFrom + ", ValidityDateTo : " + strValidityDateTo + "\r\n";
		strRequestLog += "* Price : " + strPrice + ", PaymentId : " + strPaymentId + ", ReceiptId : " + strReceiptId;
		printLog("A", "*** purchase_membership Request DATA *** \r\n" + strRequestLog);
		
		boolean isPurchase = false;
		String strMembershipUserListId = "0";
		String strReceiptUrl = "";
		String strPurchasedDate = "";	
		String strMaxPurchaseLimit = "";	

		// =========================================================
		// purchase_membership 결제/트랜잭션 상태값
		// =========================================================
		// Bootpay 결제가 실제 승인되었는지
		boolean isPaymentConfirmed = false;

		// conn.setAutoCommit(false)를 실행했는지
		boolean isTransactionStarted = false;

		// PARTNER_PAYMENT 저장까지 성공했는지
		boolean isPaymentSaved = false;
		
		// 회원권·예약·결제정보 DB COMMIT까지 최종 성공했는지
		boolean isDbCommitted = false;

		// 동일 회원권 동시 구매 요청 잠금 상태
		boolean isPurchaseLockAcquired = false;
		// GET_LOCK / RELEASE_LOCK에 사용할 잠금 키
		String strPurchaseLockKey = "";

		int nMaxPurchaseLimit = 0;

		// 후처리 실행 여부
		boolean shouldRunPostProcess = false;

		boolean isAutoCommitRestored = false;

		try { 
			if(strReservationUserName == null || strReservationUserName.contentEquals("")) strReservationUserName = strUserName;

			if(strValidityDateFrom == null){
				strValidityDateFrom = "";
			}

			if(strValidityDateFrom != null && strValidityDateFrom.length() == 8){
				strValidityDateFrom = strValidityDateFrom + "000000";
			}

			if(strValidityDateTo != null && strValidityDateTo.length() == 8){
				strValidityDateTo = strValidityDateTo + "235959";
			}

			String strRequestValidityDateFrom = strValidityDateFrom;
			String strRequestValidityDateTo = strValidityDateTo;

			if(strSeat == null) strSeat = "";

			if(strOptions == null) strOptions = "";

			if (strUserPhoneNo != null && strUserPhoneNo.length() > 15) {
				strUserPhoneNo = strUserPhoneNo.substring(0, 15);
			}

			String strCommunityGender = "";
			String strMembershipGender = "";

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
			
			List<String> listOption = new ArrayList<String>();
			if(!strOptions.contentEquals("")){
				String[] splitStr = strOptions.split(",");
				for(int nOpstions = 0; nOpstions < splitStr.length; nOpstions++){
					listOption.add(splitStr[nOpstions]);
				}
			}

			printLog("A","strOptions : " + strOptions);

			strPrice = strPrice.replace("원","").replace(",","");
			printLog("D","strPrice : " + strPrice);

			String strValidityPeriodQuery = "";
			strValidityPeriodQuery += " SELECT VALIDITY_PERIOD, "
										+ " COMMUNITY_TYPE, "
										+ " PURCHASABLE_MAX_COUNT, "
										+ " VALIDITY_DATE_FROM, "
										+ " VALIDITY_DATE_TO, "
										+ " VALIDITY_PERIOD_UNIT, "
										+ " GENDER, "
										+ " NEED_TO_PAY, "
										+ " NAME, "
										+ " RESERVATION_TYPE, "
										+ " RESERVE_LIMIT_TYPE, "
										+ " RESERVE_LIMIT_UNIT, "
										+ " RESERVE_LIMIT, "
										+ " MAX_PURCHASE_LIMIT ";
			strValidityPeriodQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
			strValidityPeriodQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";	

			pstmt = conn.prepareStatement(strValidityPeriodQuery);
			rs = pstmt.executeQuery();

			String strValidityPeriod = new String();
			String strPurchasableMaxCnt = new String();	// 이용권 구매가능 최대 갯수
			String strValidityPeriodUnit = new String();

			String strNeedToPay = "";
			String strMembershipName = "";
			String strReservationType = "";

			String strResultCode = "0";
			String strResultMessage = "이용권이 마감 되었습니다.";
			String strEmpty = " ";

			String strReserveLimitType = "";
			String strReserveLimitUnit = "";
			String strReserveLimit = "";
			
			String dbDateFrom = "";
			String dbDateTo = "";

			if(rs.next()) {
				strValidityPeriod = rs.getString(1);	
				strCommunityType = rs.getString(2);
				strPurchasableMaxCnt = rs.getString(3);	

				dbDateFrom = rs.getString(4);
				dbDateTo = rs.getString(5);

				strValidityPeriodUnit = rs.getString(6) != null ? rs.getString(6).trim() : "";

				printLog("A", "purchase_membership 좌석 기간 검사"
								+ " / membershipId : " + strMembershipId
								+ " / requestDateFrom : " + strRequestValidityDateFrom
								+ " / requestDateTo : " + strRequestValidityDateTo
								+ " / dbDateFrom : " + dbDateFrom
								+ " / dbDateTo : " + dbDateTo
								+ " / validityPeriod : " + strValidityPeriod
								+ " / validityPeriodUnit : " + strValidityPeriodUnit
								+ " / seat : " + strSeat);

				strMembershipGender = rs.getString(7) != null ? rs.getString(7) : "";
				strNeedToPay = rs.getString(8);

				if(strNeedToPay == null || strNeedToPay.contentEquals("")){
					strNeedToPay = "0";
				}

				strMembershipName = rs.getString(9) != null ? rs.getString(9) : "";
				strReservationType = rs.getString(10) != null ? rs.getString(10) : "";
				strReserveLimitType = rs.getString(11) != null ? rs.getString(11) : "";
				strReserveLimitUnit = rs.getString(12) != null ? rs.getString(12) : "";
				strReserveLimit = rs.getString(13) != null ? rs.getString(13) : "";
				strMaxPurchaseLimit = rs.getString(14) != null ? rs.getString(14) : "";

				if (strMembershipName != null) {
					strMembershipName = strMembershipName.replace("*", "").replace("+", "");
				}
			}

			boolean isNeedPayment = "1".contentEquals(strNeedToPay);
			boolean hasMaxPurchaseLimit = strMaxPurchaseLimit != null && !strMaxPurchaseLimit.trim().contentEquals("") && !"0".contentEquals(strMaxPurchaseLimit.trim());

			printLog("A", "purchase_membership 구매 가능 개수 설정"
							+ " - membershipId : " + strMembershipId
							+ ", maxPurchaseLimit : " + strMaxPurchaseLimit
							+ ", hasMaxPurchaseLimit : " + hasMaxPurchaseLimit);
				
			// 이용권 구매가능 최대 갯수가 있는 경우(ex. GX 강습 정원 마감) 마감여부를 먼저 체크함
			if(strPurchasableMaxCnt != null && !strPurchasableMaxCnt.contentEquals("")) {
				String strMembershipQuery = "";
				strMembershipQuery += " SELECT count(USER_ID) ";
				strMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
				strMembershipQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";
				strMembershipQuery += " AND (CANCEL_DATE is null OR CANCEL_DATE = '') ";
				
				pstmt = conn.prepareStatement(strMembershipQuery);
				rs = pstmt.executeQuery();
				
				String strPurchaseMembership = "0";

				if(rs.next()) {
					strPurchaseMembership = rs.getString(1);
				}
				
				if(Integer.parseInt(strPurchaseMembership) >= Integer.parseInt(strPurchasableMaxCnt)) {

					strResultCode = "0";
					strResultMessage = "이용권이 마감되었습니다.";
					strEmpty = " ";

					printLog("A", "[PRECHECK][FAIL] 회원권 정원 마감"
									+ " - membershipId : " + strMembershipId
									+ ", currentCount : " + strPurchaseMembership
									+ ", maxCount : " + strPurchasableMaxCnt);

					ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

					baOutStream.write(strResultCode.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strResultMessage.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);

					returnData(baOutStream, outStream);
					return;
				}
			}
			
			printLog("D", "strGender : "+strGender);

			String strCommunityGenderQuery = "";
			strCommunityGenderQuery += " SELECT GENDER ";
			strCommunityGenderQuery += " FROM APT_COMMUNITY ";
			strCommunityGenderQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strCommunityGenderQuery += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";
			
			pstmt = conn.prepareStatement(strCommunityGenderQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strCommunityGender = rs.getString(1);	
			}
			
			// 이용권 사용기간 가져오기. 이용권 유효기간 값이 있을 경우에는 해당값 사용
			String strStartDate = "";
			String strEndDate = "";
			String strPurchaseDate = "";
			String strExpirationDate = "";
			
			boolean bSetDate = false;
			// 1. 앱에서 선택한 날짜가 있으면 사용
			if(strRequestValidityDateFrom != null && strRequestValidityDateFrom.length() >= 8) {

				String strSelectedDate = strRequestValidityDateFrom.substring(0, 8);
				
				strValidityDateFrom = strSelectedDate + "000000";
				strValidityDateTo = strSelectedDate + "235959";
				
				bSetDate = true;
				printLog("A", "purchase_membership 이용권 사용기간 - 앱에서 선택한 날짜 사용 : " + strValidityDateFrom + " ~ " + strValidityDateTo);
			}
			// 2. 회원권 기간이 있으면 사용
			if(!bSetDate) {
				if(dbDateFrom != null && !dbDateFrom.contentEquals("")) {
					strValidityDateFrom = dbDateFrom;
					bSetDate = true;
				}

				if(dbDateTo != null && !dbDateTo.contentEquals("")) {
					strValidityDateTo = dbDateTo;
					bSetDate = true;
				}
				
				if(bSetDate) {
					printLog("A", "purchase_membership 이용권 사용기간 - 회원권 기간 날짜 사용 : " + strValidityDateFrom + " ~ " + strValidityDateTo);
				}
			}
			// 3. ValidityPeriod, ValidityPeriodUnit 값 확인
			SimpleDateFormat sdf = new SimpleDateFormat("yyyyMMddHHmmss");
			sdf.setTimeZone(TimeZone.getTimeZone("Asia/Seoul")); // 한국 시간대 설정
			String currentDateTime = sdf.format(new Date());
			String strAPIEndDate = "";

			if(strValidityDateFrom != null && !strValidityDateFrom.contentEquals("") && strValidityDateTo != null && !strValidityDateTo.contentEquals("")) {
				strStartDate = strValidityDateFrom;
				strEndDate = strValidityDateTo;

				strPurchaseDate = currentDateTime;
				strExpirationDate = strEndDate.substring(0,8);
	
				strAPIEndDate = strExpirationDate + "235959";
			} else {
				// 이용권 사용기간 가져오기
				int nValidityPeriod = 0;
				if(strValidityPeriod != null && !strValidityPeriod.trim().contentEquals("")) {
					try {
						nValidityPeriod = Integer.parseInt(strValidityPeriod.trim());
					} catch(Exception validityPeriodException) {
						nValidityPeriod = 0;
					}
				}				
	
				Calendar calendar = Calendar.getInstance();
	
				if(strValidityPeriodUnit.contentEquals(UNIT_MINUTE)){
					calendar.add(Calendar.MINUTE, nValidityPeriod);
				}else if(strValidityPeriodUnit.contentEquals(UNIT_HOUR)){
					calendar.add(Calendar.HOUR_OF_DAY, nValidityPeriod);
				}else if(strValidityPeriodUnit.contentEquals(UNIT_DAYS)){
					calendar.add(Calendar.DAY_OF_YEAR, nValidityPeriod);
				}else if(strValidityPeriodUnit.contentEquals(UNIT_MONTH)){
					calendar.add(Calendar.MONTH, nValidityPeriod);
					calendar.add(Calendar.DAY_OF_YEAR, -1); // 하루 전으로
				}else if(strValidityPeriodUnit.contentEquals(UNIT_YEAR)){
					calendar.add(Calendar.YEAR, nValidityPeriod);
					calendar.add(Calendar.DAY_OF_YEAR, -1); // 하루 전으로
				}
	
				printLog("A","strValidityPeriodUnit : "  + strValidityPeriodUnit + ", nValidityPeriod : "  + nValidityPeriod);

				SimpleDateFormat sdfExpirationDate = new SimpleDateFormat("yyyyMMdd");
				strExpirationDate = sdfExpirationDate.format(calendar.getTime());

				strStartDate = currentDateTime;
				strPurchaseDate = strStartDate;

				// 개인정보 사진 만료일까지
				strEndDate = strExpirationDate + "235959";
				strAPIEndDate = strExpirationDate + "235959";

				printLog("A", "purchase_membership 이용권 사용기간 - ValidityPeriod, ValidityPeriodUnit 값 기준 날짜 사용 : " + strStartDate + " ~ " + strEndDate);
			}

			printLog("A", "purchase_membership 이용권 최종 사용 기간"
							+ " / membershipId : " + strMembershipId
							+ " / finalStartDate : " + strStartDate
							+ " / finalEndDate : " + strEndDate
							+ " / seat : " + strSeat);
			
			// =========================================================
			// 회원권 구매 횟수 제한 검사
			//
			// RESERVE_LIMIT_TYPE
			// 0 : 실제 이용자별 제한
			// 1 : 세대별 제한
			//
			// RESERVE_LIMIT_UNIT
			// 0 : 일 단위
			// 1 : 주 단위
			//
			// RESERVE_LIMIT
			// 제한 횟수
			//
			// RESERVE_LIMIT이 NULL, 빈값, 0이면 구매 제한 없음
			// =========================================================
			boolean hasReserveLimit = strReserveLimit != null && !strReserveLimit.trim().contentEquals("") && !"0".contentEquals(strReserveLimit.trim());

			if(hasReserveLimit) {

				int nReserveLimit = 0;

				try {
					nReserveLimit = Integer.parseInt(strReserveLimit.trim());
				} catch(Exception limitParseException) {
					printLog("A", "purchase_membership RESERVE_LIMIT 숫자 변환 실패"
									+ " / membershipId : " + strMembershipId
									+ " / reserveLimit : " + strReserveLimit);

					// 잘못된 설정값은 제한 없음으로 처리
					nReserveLimit = 0;
				}

				if(nReserveLimit > 0) {

					String strDuplicateMembershipQuery = "";

					strDuplicateMembershipQuery += " SELECT COUNT(*) ";
					strDuplicateMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST MUL ";

					strDuplicateMembershipQuery += " INNER JOIN APT_COMMUNITY_RESERVE ACR ";
					strDuplicateMembershipQuery += " ON ACR.MEMBERSHIP_USER_LIST_ID = MUL.MEMBERSHIP_USER_LIST_ID ";

					strDuplicateMembershipQuery += " WHERE MUL.APT_CODE = ? ";
					strDuplicateMembershipQuery += " AND MUL.MEMBERSHIP_ID = ? ";

					// 같은 동·호수
					strDuplicateMembershipQuery += " AND MUL.USER_DONG = ? ";
					strDuplicateMembershipQuery += " AND MUL.USER_HO = ? ";

					strDuplicateMembershipQuery += " AND ACR.APT_CODE = ? ";
					strDuplicateMembershipQuery += " AND ACR.MEMBERSHIP_ID = ? ";
					strDuplicateMembershipQuery += " AND ACR.USER_DONG = ? ";
					strDuplicateMembershipQuery += " AND ACR.USER_HO = ? ";

					// 이용자당 제한
					if("0".contentEquals(strReserveLimitType)) {
						strDuplicateMembershipQuery += " AND MUL.USER_NAME = ? ";
						strDuplicateMembershipQuery += " AND ACR.RESERVE_USER_NAME = ? ";
					}

					// 회원권 미취소
					strDuplicateMembershipQuery += " AND (MUL.CANCEL_DATE IS NULL OR MUL.CANCEL_DATE = '') ";

					// 예약 미취소
					strDuplicateMembershipQuery += " AND ACR.RESERVE_CANCEL_TIME IS NULL ";

					// 회원권 미만료
					strDuplicateMembershipQuery += " AND STR_TO_DATE(MUL.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() ";

					// 일 단위 제한
					if("0".contentEquals(strReserveLimitUnit)) {
						strDuplicateMembershipQuery += " AND DATE(STR_TO_DATE(MUL.PURCHASE_DATE, '%Y%m%d%H%i%s')) = CURDATE() ";
					} else if("1".contentEquals(strReserveLimitUnit)) { // 주 단위 제한: 월요일 시작
						strDuplicateMembershipQuery += " AND YEARWEEK("
														+ " STR_TO_DATE(MUL.PURCHASE_DATE, '%Y%m%d%H%i%s'), "
														+ " 1"
														+ " ) = YEARWEEK(NOW(), 1) ";
					}

					printLog("A", "purchase_membership 회원권 구매 제한 검사"
									+ " / membershipId : " + strMembershipId
									+ " / reservationUserName : " + strReservationUserName
									+ " / reserveLimitType : " + strReserveLimitType
									+ " / reserveLimitUnit : " + strReserveLimitUnit
									+ " / reserveLimit : " + strReserveLimit
									+ " / query : " + strDuplicateMembershipQuery);

					pstmt = conn.prepareStatement(strDuplicateMembershipQuery);

					int nParamIndex = 1;

					pstmt.setString(nParamIndex++, strAptCode);
					pstmt.setString(nParamIndex++, strMembershipId);

					pstmt.setString(nParamIndex++, strUserDong);
					pstmt.setString(nParamIndex++, strUserHo);

					pstmt.setString(nParamIndex++, strAptCode);
					pstmt.setString(nParamIndex++, strMembershipId);

					pstmt.setString(nParamIndex++, strUserDong);
					pstmt.setString(nParamIndex++, strUserHo);

					// 이용자당 제한일 때만 이름 파라미터 추가
					if("0".contentEquals(strReserveLimitType)) {
						pstmt.setString(nParamIndex++, strReservationUserName);

						pstmt.setString(nParamIndex++, strReservationUserName);
					}

					rs = pstmt.executeQuery();

					int nDuplicateMembershipCount = 0;

					if(rs.next()) {
						nDuplicateMembershipCount = rs.getInt(1);
					}

					printLog("A", "purchase_membership 회원권 구매 제한 검사 결과"
									+ " / membershipId : " + strMembershipId
									+ " / reservationUserName : " + strReservationUserName
									+ " / duplicateCount : " + nDuplicateMembershipCount
									+ " / reserveLimit : " + nReserveLimit);

					// 현재 기간 내 구매 건수가 제한 횟수 이상이면 구매 차단
					if(nDuplicateMembershipCount >= nReserveLimit) {

						strResultCode = "0";

						if("0".contentEquals(strReserveLimitUnit)) {
							strResultMessage =
								"해당 회원권은 하루 최대 "
								+ nReserveLimit
								+ "회까지 구매할 수 있습니다.";
						} else if("1".contentEquals(strReserveLimitUnit)) {
							strResultMessage =
								"해당 회원권은 주 최대 "
								+ nReserveLimit
								+ "회까지 구매할 수 있습니다.";
						} else {
							strResultMessage = "해당 회원권의 구매 가능 횟수를 초과했습니다.";
						}

						strEmpty = " ";

						printLog("A", "purchase_membership 회원권 구매 제한 초과"
										+ " / membershipId : " + strMembershipId
										+ " / currentBuyerUserId : " + strUserId
										+ " / currentBuyerUserName : " + strUserName
										+ " / membershipUserName : " + strReservationUserName
										+ " / reserveLimitType : " + strReserveLimitType
										+ " / reserveLimitUnit : " + strReserveLimitUnit
										+ " / duplicateCount : " + nDuplicateMembershipCount
										+ " / reserveLimit : " + nReserveLimit);

						strResultMessage = "해당 회원권의 구매 가능 횟수를 초과했습니다.";

						ByteArrayOutputStream duplicateStream = new ByteArrayOutputStream();

						duplicateStream.write(strResultCode.getBytes(S_CHARSET));
						duplicateStream.write(COLUMN_DEL);

						duplicateStream.write(strResultMessage.getBytes(S_CHARSET));
						duplicateStream.write(COLUMN_DEL);

						duplicateStream.write(strEmpty.getBytes(S_CHARSET));
						duplicateStream.write(COLUMN_DEL);

						duplicateStream.write(strEmpty.getBytes(S_CHARSET));
						duplicateStream.write(COLUMN_DEL);

						duplicateStream.write(strEmpty.getBytes(S_CHARSET));
						duplicateStream.write(COLUMN_DEL);

						returnData(duplicateStream, outStream);
						return;
					}
				}
			}

			printLog("A", "purchase_membership 좌석 기간 검사"
						+ " / membershipId : " + strMembershipId
						+ " / communityType : " + strCommunityType
						+ " / finalStartDate : " + strStartDate
						+ " / finalEndDate : " + strEndDate
						+ " / seat : " + strSeat);
					
			// =========================
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
			strValiditySeatQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= STR_TO_DATE('" + strStartDate + "', '%Y%m%d%H%i%s') ";
			
			if(strValidityDateFrom != null && !strValidityDateFrom.contentEquals("")) {
				strValiditySeatQuery +=  " AND STR_TO_DATE(DATE, '%Y%m%d%H%i%s') <= STR_TO_DATE('" + strEndDate + "', '%Y%m%d%H%i%s')" ;
			}
			
			if(!strCommunityGender.contentEquals("0") || !strMembershipGender.contentEquals("0")){
				strValiditySeatQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
			}

			printLog("A","strValiditySeatQuery : "  + strValiditySeatQuery);

			pstmt = conn.prepareStatement(strValiditySeatQuery);
			rs = pstmt.executeQuery();

			String strValiditySeatCount = new String();
			
			if(rs.next()) {
				strValiditySeatCount = rs.getString(1);	
			}

			ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

			// 동일 기간에 해당 좌석을 사용하는 예약이 없는 경우 예약 처리
			if(strValiditySeatCount.contentEquals("0")){
				
				int nRet = 0;
				boolean isPurchased = false;

				printLog("A", "[STEP 1][START] 회원권/예약 DB 작업 준비"
								+ " - needToPay : " + strNeedToPay
								+ ", membershipId : " + strMembershipId
								+ ", paymentId : " + strPaymentId
								+ ", receiptId : " + strReceiptId
								+ ", price : " + strPrice);

				try {
					conn.setAutoCommit(false);
					isTransactionStarted = true;

					String strLockStartDate = strStartDate != null && strStartDate.length() >= 8 ? strStartDate.substring(0, 8) : "";

					String strLockEndDate = strEndDate != null && strEndDate.length() >= 8 ? strEndDate.substring(0, 8) : "";

					if(strSeat != null && !strSeat.trim().contentEquals("")) {

						// 좌석이 있는 회원권:
						// 동일 시설·동일 좌석·동일 이용기간 중복 방지
						strPurchaseLockKey = "purchase_membership_seat:"
												+ strAptCode + ":"
												+ strCommunityType + ":"
												+ strSeat.trim() + ":"
												+ strLockStartDate + ":"
												+ strLockEndDate;

					} else {

						// 좌석이 없는 회원권:
						// 동일 이용자·동일 회원권 중복 구매 방지
						strPurchaseLockKey =
							"purchase_membership_user:"
							+ strAptCode + ":"
							+ strMembershipId + ":"
							+ strUserDong + ":"
							+ strUserHo + ":"
							+ strReservationUserName;
					}

					String strPurchaseLockQuery = "SELECT GET_LOCK(?, 5)";

					pstmt = conn.prepareStatement(strPurchaseLockQuery);

					pstmt.setString(1, strPurchaseLockKey);

					rs = pstmt.executeQuery();

					int nPurchaseLockResult = 0;

					if(rs.next()) {
						nPurchaseLockResult = rs.getInt(1);
					}

					printLog("A", "[STEP 1][CHECK] 회원권 구매 동시 요청 잠금 결과"
							+ " - lockKey : " + strPurchaseLockKey
							+ ", lockResult : "+ nPurchaseLockResult);

					if(nPurchaseLockResult != 1) {
						throw new Exception("회원권 구매가 처리 중입니다. 잠시 후 다시 시도해주세요.");
					}

					isPurchaseLockAcquired = true;

					// 좌석이 있는 경우 잠금 획득 후 다시 확인
					if(strSeat != null && !strSeat.trim().contentEquals("")) {

						String strLockedSeatQuery = "";
						strLockedSeatQuery += " SELECT COUNT(*) ";
						strLockedSeatQuery += " FROM APT_COMMUNITY_RESERVE ";
						strLockedSeatQuery += " WHERE APT_CODE = ? ";
						strLockedSeatQuery += " AND COMMUNITY_TYPE = ? ";
						strLockedSeatQuery += " AND PLACE = ? ";
						strLockedSeatQuery += " AND PLACE != '' ";
						strLockedSeatQuery += " AND RESERVE_CANCEL_TIME IS NULL ";
						strLockedSeatQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') ";
						strLockedSeatQuery += "     >= STR_TO_DATE(?, '%Y%m%d%H%i%s') ";
						strLockedSeatQuery += " AND STR_TO_DATE(DATE, '%Y%m%d%H%i%s') ";
						strLockedSeatQuery += "     <= STR_TO_DATE(?, '%Y%m%d%H%i%s') ";

						pstmt = conn.prepareStatement(strLockedSeatQuery);
						pstmt.setString(1, strAptCode);
						pstmt.setString(2, strCommunityType);
						pstmt.setString(3, strSeat);
						pstmt.setString(4, strStartDate);
						pstmt.setString(5, strEndDate);

						rs = pstmt.executeQuery();

						int nLockedSeatCount = 0;

						if(rs.next()) {
							nLockedSeatCount = rs.getInt(1);
						}

						printLog("A", "[STEP 1][CHECK] 잠금 획득 후 좌석 재확인"
									+ " / lockKey : " + strPurchaseLockKey
									+ " / aptCode : " + strAptCode
									+ " / communityType : " + strCommunityType
									+ " / seat : " + strSeat
									+ " / startDate : " + strStartDate
									+ " / endDate : " + strEndDate
									+ " / duplicateCount : " + nLockedSeatCount);

						if(nLockedSeatCount > 0) {
							throw new Exception(
								"해당 자리는 마감되었습니다. 다른 자리를 선택해주세요."
							);
						}
					}

					if(nMaxPurchaseLimit > 0) {

						String strLockedPurchaseCountQuery = "";
						strLockedPurchaseCountQuery += " SELECT COUNT(*) ";
						strLockedPurchaseCountQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
						strLockedPurchaseCountQuery += " WHERE APT_CODE = ? ";
						strLockedPurchaseCountQuery += " AND MEMBERSHIP_ID = ? ";
						strLockedPurchaseCountQuery += " AND USER_DONG = ? ";
						strLockedPurchaseCountQuery += " AND USER_HO = ? ";
						strLockedPurchaseCountQuery += " AND USER_NAME = ? ";
						strLockedPurchaseCountQuery += " AND (CANCEL_DATE IS NULL OR CANCEL_DATE = '') ";
						strLockedPurchaseCountQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() ";

						pstmt = conn.prepareStatement(strLockedPurchaseCountQuery);
						pstmt.setString(1, strAptCode);
						pstmt.setString(2, strMembershipId);
						pstmt.setString(3, strUserDong);
						pstmt.setString(4, strUserHo);
						pstmt.setString(5, strReservationUserName);

						rs = pstmt.executeQuery();

						int nCurrentPurchaseCount = 0;

						if(rs.next()) {
							nCurrentPurchaseCount = rs.getInt(1);
						}

						printLog("A", "[STEP 1][CHECK] 잠금 획득 후 회원권 구매 개수 재확인"
										+ " - currentCount : " + nCurrentPurchaseCount
										+ ", maxPurchaseLimit : " + nMaxPurchaseLimit);

						if(nCurrentPurchaseCount >= nMaxPurchaseLimit) {
							throw new Exception("해당 회원권의 구매 가능 개수를 초과했습니다.");
						}
					}

					printLog("A", "[STEP 1][SUCCESS] 회원권 구매 동시 요청 잠금 획득" + " - lockKey : " + strPurchaseLockKey);

					printLog("A", "[STEP 1][SUCCESS] 트랜잭션 시작 성공" + " - autoCommit : false");

				} catch(Exception transactionStartException) {

					printLog("A", "[STEP 1][FAIL] 트랜잭션 또는 구매 잠금 처리 실패"
									+ " - message : " + transactionStartException.getMessage()
									+ ", exception : " + transactionStartException.toString());

					if(transactionStartException.getMessage() != null && transactionStartException.getMessage().contentEquals("회원권 구매가 처리 중입니다. 잠시 후 다시 시도해주세요.")) {
						throw transactionStartException;
					}

					throw new Exception("회원권 구매 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.", transactionStartException);
				}

				try{
					String strMembershipPurchaseQuery = "INSERT INTO APT_COMMUNITY_MEMBERSHIP_USER_LIST "
					+ "(USER_ID, MEMBERSHIP_ID, PRICE, PURCHASE_DATE, DESCRIPTION, USER_DONG, USER_HO, USER_NAME, APT_CODE, "
					+ " REGISTRATION_DATE, EXPIRATION_DATE, COMMUNITY_TYPE, OPTIONS, UUID) "
					+ " VALUES (?, ?, ?, ?, REPLACE(REPLACE((SELECT NAME FROM APT_COMMUNITY_MEMBERSHIP_INFO WHERE MEMBERSHIP_ID = ?), '*', ''), '+', ''), ?, ?, ?, ?, ?, ?, ?,?, ?)";

					pstmt = conn.prepareStatement(strMembershipPurchaseQuery);
					pstmt.setString(1, strUserId);
					pstmt.setString(2, strMembershipId);
					pstmt.setString(3, strPrice);
					pstmt.setString(4, strPurchaseDate);
					pstmt.setString(5, strMembershipId); // 서브쿼리에서도 같은 값을 사용
					pstmt.setString(6, strUserDong);
					pstmt.setString(7, strUserHo);
					pstmt.setString(8, strReservationUserName);
					pstmt.setString(9, strAptCode);
					pstmt.setString(10, strStartDate);
					pstmt.setString(11, strEndDate);
					pstmt.setString(12, strCommunityType);
					pstmt.setString(13, strOptions);
					pstmt.setString(14, strUUID);

					printLog("A", "[STEP 2][START] 회원권 DB INSERT 시작"
									+ " - membershipId : " + strMembershipId
									+ ", userId : " + strUserId
									+ ", reservationUserName : " + strReservationUserName
									+ ", userDong : " + strUserDong
									+ ", userHo : " + strUserHo
									+ ", price : " + strPrice);
					
					nRet = pstmt.executeUpdate();

					printLog("A", "[STEP 2][RESULT] 회원권 DB INSERT 결과" + " - nRet : " + nRet);

					if(nRet != 1) {
						printLog("A", "[STEP 2][FAIL] 회원권 DB INSERT 실패"
										+ " - membershipId : " + strMembershipId
										+ ", nRet : " + nRet);

						throw new Exception("회원권 발급에 실패했습니다.");
					}

					isPurchased = true;
					isPurchase = true;

					printLog("A", "[STEP 2][SUCCESS] 회원권 DB INSERT 성공" + " - membershipId : " + strMembershipId);

					// 이용권 구매가능 최대 갯수가 있는 경우(ex. GX 강습 정원 마감) 마감여부를 먼저 체크함
					if(strPurchasableMaxCnt != null && !strPurchasableMaxCnt.contentEquals("") && nRet == 1) {
						
						String strMembershipQuery = "";
						strMembershipQuery += " SELECT count(USER_ID) ";
						strMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
						strMembershipQuery += " WHERE MEMBERSHIP_ID = " + strMembershipId + " ";
						strMembershipQuery += " AND (CANCEL_DATE is null OR CANCEL_DATE  = '') ";
						
						pstmt = conn.prepareStatement(strMembershipQuery);
						rs = pstmt.executeQuery();
						
						String strPurchaseMembership = "0";

						if(rs.next()) {
							strPurchaseMembership = rs.getString(1);
						}

						printLog("A", "[STEP 2][CHECK] 회원권 INSERT 후 최종 정원 확인"
											+ " - membershipId : " + strMembershipId
											+ ", currentCount : " + strPurchaseMembership
											+ ", maxCount : " + strPurchasableMaxCnt);

						if(Integer.parseInt(strPurchaseMembership) > Integer.parseInt(strPurchasableMaxCnt)) {

							printLog("A", "[STEP 2][FAIL] 회원권 INSERT 후 최종 정원 초과"
												+ " - membershipId : " + strMembershipId
												+ ", currentCount : " + strPurchaseMembership
												+ ", maxCount : " + strPurchasableMaxCnt);

							throw new Exception("이용권이 마감되었습니다.");
						}

						printLog("A", "[STEP 2][SUCCESS] 회원권 INSERT 후 최종 정원 확인 통과"
										+ " - membershipId : " + strMembershipId
										+ ", currentCount : " + strPurchaseMembership
										+ ", maxCount : " + strPurchasableMaxCnt);
					}

				}catch(Exception e){		
					printLog("A", "MembershipPurchaseQuery Exception : " + e.toString());
					throw e;
				}
				
				String strMessage = "";

				if(nRet == 1){
					isPurchased = true;
					isPurchase = true;
					strMessage = "예약이 완료되었습니다!";
				}else{
					strMessage = "예약에 실패했습니다.";
				}
				
				// 생성된 회원권 사용자 ID 조회
				String strLastMembershipIdQuery = "";
				strLastMembershipIdQuery += "SELECT MEMBERSHIP_USER_LIST_ID, DESCRIPTION, REGISTRATION_DATE, EXPIRATION_DATE ";
				strLastMembershipIdQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
				strLastMembershipIdQuery += " WHERE APT_CODE = " + strAptCode + " ";
				strLastMembershipIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
				strLastMembershipIdQuery += " AND USER_HO = '" + strUserHo + "' ";
				strLastMembershipIdQuery += " AND USER_NAME = '" + strReservationUserName + "' ";
				strLastMembershipIdQuery += " ORDER BY MEMBERSHIP_USER_LIST_ID  desc LIMIT 1 ";

				printLog("A" , "strLastMembershipIdQuery : " +strLastMembershipIdQuery);

				printLog("A", "[STEP 3][START] 생성된 회원권 사용자 ID 조회"
								+ " - membershipId : " + strMembershipId
								+ ", userId : " + strUserId
								+ ", reservationUserName : " + strReservationUserName);

				pstmt = conn.prepareStatement(strLastMembershipIdQuery);
				rs = pstmt.executeQuery();

				String strLastMembershipId = "0";
				String strMemebershipDescription = "";
				String strMembershipStartDate = "";
				String strMembershipEndDate = "";

				if(rs.next()) {
					strLastMembershipId = rs.getString(1);	
					strMemebershipDescription = rs.getString(2);
					strMembershipStartDate = rs.getString(3);
					strMembershipEndDate = rs.getString(4);
				}

				strMembershipUserListId = strLastMembershipId;

				if(strMembershipUserListId == null
					|| strMembershipUserListId.contentEquals("")
					|| strMembershipUserListId.contentEquals("0")) {

						printLog("A", "[STEP 3][FAIL] 생성된 회원권 사용자 ID 조회 실패"
										+ " - membershipId : " + strMembershipId
										+ ", membershipUserListId : "
										+ strMembershipUserListId);

						throw new Exception("생성된 회원권 사용자 ID를 확인할 수 없습니다.");
				}

				printLog("A",  "[STEP 3][SUCCESS] 생성된 회원권 사용자 ID 확인"
								+ " - membershipUserListId : "
								+ strMembershipUserListId
								+ ", registrationDate : "
								+ strMembershipStartDate
								+ ", expirationDate : "
								+ strMembershipEndDate);

				//회원권 구매후 예약 테이블에 삽입
				String strCommunitySecurity = "";
				strCommunitySecurity += " SELECT SECURITY ";
				strCommunitySecurity += " FROM APT_COMMUNITY ";
				strCommunitySecurity += " WHERE 1 = 1 ";
				strCommunitySecurity += " AND  APT_CODE = " + strAptCode + " ";
				strCommunitySecurity += " AND  COMMUNITY_TYPE = '" + strCommunityType + "' ";

				pstmt = conn.prepareStatement(strCommunitySecurity);
				rs = pstmt.executeQuery();

				String strSecurityType = "";

				if(rs.next()) {
					strSecurityType = rs.getString(1);
				}

				// 얼굴 등록이 되어 있는 경우에만 가능	
				String strQueryImageCheck = "";
				strQueryImageCheck += "SELECT COUNT(*) FROM APT_COMMUNITY_USER_INFO ";
				strQueryImageCheck += " WHERE UUID = '" + strUUID + "' ";
				strQueryImageCheck += " AND IMAGE_URL IS NOT NULL ";

				pstmt = conn.prepareStatement(strQueryImageCheck);
				rs = pstmt.executeQuery();
				
				String resultImageCnt = "";

				if(rs.next()) {
					resultImageCnt = rs.getString(1);
				}

				if(resultImageCnt.contentEquals("0")&& strSecurityType.contentEquals("1")) {

					printLog("A", "[STEP 4][FAIL] 얼굴인식 필수 시설 사진 미등록"
									+ " - uuid : " + strUUID
									+ ", membershipUserListId : "
									+ strMembershipUserListId);

					throw new Exception("얼굴 인식을 위해 사진을 다시 등록해주세요.");
				}

				if(!isPurchased) {
					throw new Exception("회원권 발급이 완료되지 않았습니다.");
				}

				boolean isReservation = false;

				try{
					printLog("A", "[STEP 4][START] 회원권 연결 예약 DB INSERT 시작"
									+ " - membershipId : " + strMembershipId
									+ ", membershipUserListId : "
									+ strMembershipUserListId
									+ ", seat : " + strSeat
									+ ", communityType : " + strCommunityType);

					String strMembershipReservationQuery = "";
					strMembershipReservationQuery += " INSERT INTO APT_COMMUNITY_RESERVE ( ";
					strMembershipReservationQuery += " COMMUNITY_TYPE, USER_ID, USER_DONG, USER_HO, ";
					strMembershipReservationQuery += " RESERVE_USER_NAME, RESERVE_USER_PHONE, ";
					strMembershipReservationQuery += " APT_CODE, REG_DATE, REG_CHANNEL, USER_NAME, EXPIRATION_DATE, MEMBERSHIP_ID, DATE, MEMBERSHIP_USER_LIST_ID, PLACE, GENDER, UUID ) ";
					strMembershipReservationQuery += " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

					pstmt = conn.prepareStatement(strMembershipReservationQuery);
					pstmt.setString(1, strCommunityType);
					pstmt.setString(2, strUserId);
					pstmt.setString(3, strUserDong);
					pstmt.setString(4, strUserHo);
					pstmt.setString(5, strReservationUserName);
					pstmt.setString(6, strUserPhoneNo);
					pstmt.setString(7, strAptCode);
					pstmt.setString(8, strPurchaseDate);
					pstmt.setString(9, "00");
					pstmt.setString(10, strUserName);
					pstmt.setString(11, strEndDate);
					pstmt.setString(12, strMembershipId);
					pstmt.setString(13, strStartDate);
					pstmt.setString(14, strLastMembershipId);
					pstmt.setString(15, strSeat);					
					pstmt.setString(16, strGender);					
					pstmt.setString(17, strUUID);

					int nReservationRet = pstmt.executeUpdate();
					nRet = nReservationRet;

					printLog("A", "[STEP 4][RESULT] 회원권 연결 예약 DB INSERT 결과" + " - nReservationRet : " + nReservationRet);	

					if(nReservationRet != 1) {
						printLog("A", "[STEP 4][FAIL] 회원권 연결 예약 DB INSERT 실패"
										+ " - membershipUserListId : "
										+ strMembershipUserListId
										+ ", seat : " + strSeat);

						throw new Exception("회원권 예약 정보 저장에 실패했습니다.");
					}

					isReservation = true;

					printLog("A", "[STEP 4][SUCCESS] 회원권 연결 예약 DB INSERT 성공"
									+ " - membershipUserListId : " + strMembershipUserListId
									+ ", seat : " + strSeat);
					
				} catch(Exception reservationInsertException) {

					printLog("A", "[STEP 4][ERROR] 회원권 연결 예약 DB 처리 중 예외"
									+ " - message : " + reservationInsertException.getMessage()
									+ ", exception : " + reservationInsertException.toString()
									+ ", membershipUserListId : " + strMembershipUserListId
									+ ", seat : " + strSeat);

					throw reservationInsertException;
				}

				if(isReservation){
					String strUseCountQuery = "";
					strUseCountQuery += " UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET ";
					strUseCountQuery += " USE_COUNT = USE_COUNT + 1 ";
					strUseCountQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strLastMembershipId + " ";

					pstmt = conn.prepareStatement(strUseCountQuery);
					int nUseCountRet = pstmt.executeUpdate();

					if(nUseCountRet != 1) {
						printLog("A", "[STEP 4][FAIL] 회원권 사용 횟수 UPDATE 실패"
											+ " - membershipUserListId : "
											+ strLastMembershipId
											+ ", nUseCountRet : "
											+ nUseCountRet);

						throw new Exception("회원권 사용 횟수 저장에 실패했습니다.");
					}

					printLog("A", "[STEP 4][SUCCESS] 회원권 사용 횟수 UPDATE 성공"
									+ " - membershipUserListId : "
									+ strLastMembershipId);	
				}

				baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
				baOutStream.write(strMessage.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				// 회원권을 구매하고 자리를 예약 뒤 한번 더 검증
				// 같은 시간대에 검증 쿼리가 동작하면 둘 다 예약 가능한 자리로 나오니 실제 DB에서 같은 데이터가 들어갔는지 한 번 더 검증
				// 같은 시설, 같은 회원권, 같은 자리, 같은 만료일을 가지면 동일한 주문으로 확인
				String strReserveCountQuery = " SELECT RESERVE_ID, USER_ID, MEMBERSHIP_USER_LIST_ID, RESERVE_USER_NAME ";
				strReserveCountQuery += " FROM APT_COMMUNITY_RESERVE ";
				strReserveCountQuery += " WHERE COMMUNITY_TYPE = '" + strCommunityType + "' ";
				strReserveCountQuery += " AND MEMBERSHIP_ID = " + strMembershipId + " ";
				strReserveCountQuery += " AND PLACE = '" + strSeat + "' ";
				strReserveCountQuery += " AND PLACE != '' ";
				strReserveCountQuery += " AND RESERVE_CANCEL_TIME IS NULL ";	
				strReserveCountQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= STR_TO_DATE('" + strStartDate + "', '%Y%m%d%H%i%s') ";

				if(strValidityDateFrom != null && !strValidityDateFrom.contentEquals("")) {
					strReserveCountQuery +=  " AND STR_TO_DATE(DATE, '%Y%m%d%H%i%s') <= STR_TO_DATE('" + strEndDate + "', '%Y%m%d%H%i%s')" ;
				}

				if(!strCommunityGender.contentEquals("0") || !strMembershipGender.contentEquals("0")){
					strReserveCountQuery += " AND (GENDER = '0' OR GENDER = '" + strGender + "') ";
				}

				strReserveCountQuery += " ORDER BY RESERVE_ID asc ";

				printLog("A" , "strReserveCountQuery : " +strReserveCountQuery);				

				pstmt = conn.prepareStatement(strReserveCountQuery);
				rs = pstmt.executeQuery();

				List<String> listResevationIds = new ArrayList<String>();
				List<String> listMembershipUserListIds = new ArrayList<String>();
				List<String> listUserIds = new ArrayList<String>();

				String strReservationIds = "";
				String strUserIds = "";
				String strMembershipUserListIds = "";

				for(int nRow = 0; rs.next(); nRow++) {
					strReservationIds = rs.getString(1);		
					listResevationIds.add(strReservationIds);

					strUserIds = rs.getString(2);		
					listUserIds.add(strUserIds);

					strMembershipUserListIds = rs.getString(3);		
					listMembershipUserListIds.add(strMembershipUserListIds);
				}

				String strValidityReserveIdQeury = "";
				strValidityReserveIdQeury += "SELECT RESERVE_ID ";
				strValidityReserveIdQeury += "FROM APT_COMMUNITY_RESERVE ";
				strValidityReserveIdQeury += "WHERE MEMBERSHIP_USER_LIST_ID = " + strLastMembershipId + " ";

				pstmt = conn.prepareStatement(strValidityReserveIdQeury);
				rs = pstmt.executeQuery();

				String strValidityReserveId = "";

				if(rs.next()){
					strValidityReserveId = rs.getString(1) != null ? rs.getString(1) : "";
				}

				printLog("A" , "listUserIds.size() : " +listUserIds.size());				
				printLog("A" , "strValidityReserveId : " +strValidityReserveId);				

				if(listUserIds.size() > 1 &&
					strValidityReserveId != null &&
					!strValidityReserveId.contentEquals("") &&
					!listResevationIds.get(0).toString().contentEquals(strValidityReserveId)) {

						printLog("A", "[STEP 4][FAIL] 최종 자리 중복 확인"
										+ " - membershipUserListId : " + strLastMembershipId
										+ ", reserveId : " + strValidityReserveId
										+ ", seat : " + strSeat);

						throw new Exception("해당 자리는 마감되었습니다. 다른 자리를 선택해주세요.");
				}
				
				if(hasMaxPurchaseLimit) {

					try {
						nMaxPurchaseLimit = Integer.parseInt(strMaxPurchaseLimit.trim());

					} catch(Exception maxLimitParseException) {

						printLog("A", "purchase_membership MAX_PURCHASE_LIMIT 숫자 변환 실패"
										+ " - membershipId : " + strMembershipId
										+ ", maxPurchaseLimit : " + strMaxPurchaseLimit);

						nMaxPurchaseLimit = 0;
						hasMaxPurchaseLimit = false;
					}

					// =========================================================
					// STEP 4-2. 동일 사용자·동일 회원권 최종 중복 구매 확인
					// - 동시 요청으로 회원권과 예약이 중복 생성됐는지 결제 승인 전에 확인
					// =========================================================
					String strFinalDuplicateMembershipQuery = "";
					strFinalDuplicateMembershipQuery += " SELECT MEMBERSHIP_USER_LIST_ID ";
					strFinalDuplicateMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
					strFinalDuplicateMembershipQuery += " WHERE APT_CODE = ? ";
					strFinalDuplicateMembershipQuery += " AND MEMBERSHIP_ID = ? ";
					strFinalDuplicateMembershipQuery += " AND USER_DONG = ? ";
					strFinalDuplicateMembershipQuery += " AND USER_HO = ? ";
					strFinalDuplicateMembershipQuery += " AND USER_NAME = ? ";
					strFinalDuplicateMembershipQuery += " AND (CANCEL_DATE IS NULL OR CANCEL_DATE = '') ";
					strFinalDuplicateMembershipQuery += " AND STR_TO_DATE(EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() ";
					strFinalDuplicateMembershipQuery += " ORDER BY MEMBERSHIP_USER_LIST_ID ASC ";

					pstmt = conn.prepareStatement(strFinalDuplicateMembershipQuery);

					pstmt.setString(1, strAptCode);
					pstmt.setString(2, strMembershipId);
					pstmt.setString(3, strUserDong);
					pstmt.setString(4, strUserHo);
					pstmt.setString(5, strReservationUserName);

					rs = pstmt.executeQuery();

					List<String> listMembershipIds = new ArrayList<String>();

					while(rs.next()) {
						listMembershipIds.add(rs.getString(1));
					}

					printLog("A", "[STEP 4][CHECK] 동일 사용자 동일 회원권 최종 중복 확인"
							+ " - currentMembershipUserListId : " + strMembershipUserListId
							+ ", duplicateCount : " + listMembershipIds.size()
							+ ", membershipId : " + strMembershipId
							+ ", reservationUserName : " + strReservationUserName);

					if(nMaxPurchaseLimit > 0 && listMembershipIds.size() > nMaxPurchaseLimit) {

						int nCurrentMembershipIndex = listMembershipIds.indexOf(strMembershipUserListId);

						if(nCurrentMembershipIndex < 0 || nCurrentMembershipIndex >= nMaxPurchaseLimit) {

							printLog("A", "[STEP 4][FAIL] 회원권 최대 구매 개수 초과"
												+ " - currentMembershipUserListId : " + strMembershipUserListId
												+ ", currentIndex : " + nCurrentMembershipIndex
												+ ", totalCount : " + listMembershipIds.size()
												+ ", maxPurchaseLimit : " + nMaxPurchaseLimit);

							throw new Exception("해당 회원권의 구매 가능 개수를 초과했습니다.");
						}
					}
				}

				if(isNeedPayment) {

					printLog("A", "[STEP 5][CHECK] 회원권/예약 DB 작업 완료 후 결제 검증 조건 확인"
									+ " - isPurchase : " + isPurchase
									+ ", membershipUserListId : "
									+ strMembershipUserListId
									+ ", paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", expectedPrice : " + strPrice);

					if(!isPurchase) {
						printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 발급 미완료");
						throw new Exception("회원권 발급이 완료되지 않았습니다.");
					}

					if(strMembershipUserListId == null
						|| strMembershipUserListId.contentEquals("")
						|| strMembershipUserListId.contentEquals("0")) {

							printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 사용자 ID 없음"
											+ " - membershipUserListId : "
											+ strMembershipUserListId);

							throw new Exception("회원권 사용자 ID가 없습니다.");
					}

					if(strPaymentId == null
						|| strPaymentId.contentEquals("")
						|| strReceiptId == null
						|| strReceiptId.contentEquals("")
						|| strPrice == null
						|| strPrice.contentEquals("")) {

							throw new Exception("결제 정보가 없습니다.");
					}

					printLog("A","[STEP 5][START] Bootpay 결제 verify 시작"
									+ " - receiptId : " + strReceiptId
									+ ", expectedStatus : 2"
									+ ", expectedPrice : " + strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 2 결제검증 시작(우회구간)");

					boolean isVerifiedPayment = verifyPayment(strReceiptId, "2", strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 3 결제검증 종료(우회구간)");	

					if(!isVerifiedPayment) {
						printLog("A", "[STEP 5][FAIL] Bootpay 결제 verify 실패"
										+ " - receiptId : " + strReceiptId
										+ ", expectedPrice : " + strPrice);

						throw new Exception("결제 검증에 실패했습니다.");
					}

					printLog("A", "[STEP 5][SUCCESS] Bootpay 결제 verify 성공"
									+ " - receiptId : " + strReceiptId
									+ ", price : " + strPrice);

									
					printLog("A", "[STEP 6][START] Bootpay 결제 confirm 시작"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", price : " + strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 4 결제컨펌 시작(우회구간)");

					// boolean isConfirmedPayment = confirmBootpayPayment(strPaymentId, strReceiptId, strPrice);

                    JSONObject jsonConfirmResult = confirmBootpayPayment(strPaymentId,
                                                                        strReceiptId,
                                                                        strPrice);

printLog("A", "*** time test - " + strPaymentId + " : 5 결제컨펌 종료(우회구간)");

                    if(jsonConfirmResult == null) {
						printLog("A",  "[STEP 6][FAIL] Bootpay 결제 confirm 실패" + " - paymentId : " + strPaymentId + ", receiptId : " + strReceiptId);

                        throw new Exception("결제 승인에 실패했습니다.");
                    }

					isPaymentConfirmed = true;

					// confirm 응답에서 결제 부가정보 추출
					strReceiptUrl = jsonConfirmResult.get("receipt_url") != null ? jsonConfirmResult.get("receipt_url").toString() : "";
                    String strPurchasedAt = jsonConfirmResult.get("purchased_at") != null ? jsonConfirmResult.get("purchased_at").toString() : "";
                    strPurchasedDate = convertBootpayDateToDBFormat(strPurchasedAt);

					printLog("A", "[STEP 6][SUCCESS] Bootpay 결제 confirm 성공"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId);
				}

				String strReservatinIdQuery = "";
				strReservatinIdQuery = "SELECT RESERVE_ID ";
				strReservatinIdQuery += " FROM APT_COMMUNITY_RESERVE ";
				strReservatinIdQuery += " WHERE APT_CODE = " + strAptCode + " ";
				strReservatinIdQuery += " AND USER_DONG = '" + strUserDong + "' ";
				strReservatinIdQuery += " AND USER_HO = '" + strUserHo + "' ";
				strReservatinIdQuery += " AND RESERVE_USER_NAME = '" + strReservationUserName + "' ";	
				strReservatinIdQuery += " ORDER BY RESERVE_ID desc LIMIT 1";

				printLog("A" , "strReservatinIdQuery : " +strReservatinIdQuery);
								
				pstmt = conn.prepareStatement(strReservatinIdQuery);
				rs = pstmt.executeQuery();

				String strReservationId = "";

				if(rs.next()) {
					strReservationId = rs.getString(1) != null ? rs.getString(1) : "";
				}

				baOutStream.write(strReservationId.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				// 예약 정보
				String strCommunityName = "";
				strCommunityName += "SELECT TITLE ";
				strCommunityName += " FROM APT_COMMUNITY ";
				strCommunityName += " WHERE APT_CODE = " + strAptCode + " ";
				strCommunityName += " AND COMMUNITY_TYPE = '" + strCommunityType + "' ";

				pstmt = conn.prepareStatement(strCommunityName);
				rs = pstmt.executeQuery();

				String strCommunityTitle = new String();

				if(rs.next()) {
					strCommunityTitle = rs.getString(1);	
				}

				String strMembershipPurchase = "성함*" + strReservationUserName + "*+";
				strMembershipPurchase += "동/호수*" + strUserDong + "동 " + strUserHo + "호" + "*+";
				strMembershipPurchase += "시설내역*" + strCommunityTitle + "*+";

				String strMembershipStartDateValue = strStartDate.substring(0, 8);
				String strMembershipEndDateValue = strEndDate.substring(0, 8);

				String strMembershipDateText = "";

				if(strMembershipStartDateValue.contentEquals(strMembershipEndDateValue)) {
					// 시작일과 종료일이 같으면 날짜 하나만 표시
					strMembershipDateText = formatDate(strMembershipStartDateValue);
				} else {
					// 시작일과 종료일이 다르면 기간으로 표시
					strMembershipDateText =
						formatDate(strMembershipStartDateValue)
						+ " ~ "
						+ formatDate(strMembershipEndDateValue);
				}

				strMembershipPurchase += "날짜/시간*" + strMembershipDateText + "*+";	
				strMembershipPurchase += "회원권*" + strMemebershipDescription + "*+";

				if(!strSeat.contentEquals("")){
					strMembershipPurchase += "좌석*" + strSeat + "*+";
				}

				baOutStream.write(strMembershipPurchase.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				String strCommunityDoorIdQuery = "";
				strCommunityDoorIdQuery += " SELECT DOOR_ID ";
				strCommunityDoorIdQuery += " FROM APT_COMMUNITY_DOOR ";
				strCommunityDoorIdQuery += " WHERE 1 = 1 ";
				strCommunityDoorIdQuery += " AND ATP_CODE = " + strAptCode + " ";
				strCommunityDoorIdQuery += " AND COMMUNITY_TYPE LIKE '%" + strCommunityType + "%' ";	

				if(strGender != null && !strGender.contentEquals("")){
					strCommunityDoorIdQuery += " AND (GENDER = '0' OR GENDER = '" +strGender + "' ) ";
				}

				printLog("A","strCommunityDoorIdQuery : " +strCommunityDoorIdQuery);

				pstmt = conn.prepareStatement(strCommunityDoorIdQuery);
				rs = pstmt.executeQuery();

				List<String> listDoorIds = new ArrayList<String>();
				String strDoorId = "";

				for(int nRow = 0; rs.next(); nRow++) {
					strDoorId = rs.getString(1);
					listDoorIds.add(strDoorId);
				}
				
				if(listOption.size() != 0){
					for (String strOptionIds : listOption){
						String strOptionCommunityTypeQuery = "";
						strOptionCommunityTypeQuery += "SELECT COMMUNITY_TYPE ";
						strOptionCommunityTypeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_OPTION ";
						strOptionCommunityTypeQuery += " WHERE OPTION_ID = " + strOptionIds + " ";

						pstmt = conn.prepareStatement(strOptionCommunityTypeQuery);
						rs = pstmt.executeQuery();
						
						if(rs.next()){
							if(rs.getString(1) != null) {
								strCommunityType = rs.getString(1);
							}else{
								strCommunityType = "";
							}
						}

						if(!strCommunityType.contentEquals("")){
							strCommunityDoorIdQuery = "";
							strCommunityDoorIdQuery += " SELECT DOOR_ID ";
							strCommunityDoorIdQuery += " FROM APT_COMMUNITY_DOOR ";
							strCommunityDoorIdQuery += " WHERE 1 = 1 ";
							strCommunityDoorIdQuery += " AND ATP_CODE = " + strAptCode + " ";
							strCommunityDoorIdQuery += " AND COMMUNITY_TYPE LIKE '%" + strCommunityType + "%' ";	

							if(strGender != null && !strGender.contentEquals("")){
								strCommunityDoorIdQuery += " AND (GENDER = '0' OR GENDER = '" +strGender + "' ) ";
							}

							printLog("D"," strCommunityDoorIdQuery " + strCommunityDoorIdQuery);

							pstmt = conn.prepareStatement(strCommunityDoorIdQuery);
							rs = pstmt.executeQuery();

							strDoorId = "";
							for(int nRow = 0; rs.next(); nRow++) {
								strDoorId = rs.getString(1);
								listDoorIds.add(strDoorId);
							}
						}
					}
				}

				printLog("A"," listDoorIds size " + listDoorIds.size());

				// STEP 7. 유료 회원권 결제 정보 저장
				if(strNeedToPay.contentEquals("1") && isPurchase){

					String strPaymentItem = strMembershipName + "*" + strPrice + "*+";

					String strInsertPaymentQuery = "";
					strInsertPaymentQuery += "INSERT INTO PARTNER_PAYMENT ";
					strInsertPaymentQuery += " (PAYMENT_ID, RESERVATION_ID, PRICE, TOTAL_PRICE, STATE, DATE, COMMENT, IMAGE, PAYMENT_ITEM, COUPON_USE, INSPECTION, MENU_ID, RECEIPT_ID, USER_ID, RECEIPT_URL, PURCHASED_DATE )";
					strInsertPaymentQuery += " VALUES('" + strPaymentId + "', ";
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

					printLog("A", "[STEP 7][START] PARTNER_PAYMENT INSERT 시작"
										+ " - paymentId : " + strPaymentId
										+ ", membershipUserListId : "
										+ strMembershipUserListId
										+ ", receiptId : " + strReceiptId
										+ ", price : " + strPrice);

					pstmt = conn.prepareStatement(strInsertPaymentQuery);
					int nPaymentRet = pstmt.executeUpdate();
				
					printLog("A", "[STEP 7][RESULT] PARTNER_PAYMENT INSERT 결과" + " - nPaymentRet : " + nPaymentRet);

					if(nPaymentRet != 1) {
						printLog("A", "[STEP 7][FAIL] PARTNER_PAYMENT INSERT 실패"
										+ " - paymentId : " + strPaymentId
										+ ", membershipUserListId : "
										+ strMembershipUserListId);

						throw new Exception("결제 정보 저장에 실패했습니다.");
					}

					isPaymentSaved = true;

					printLog("A", "[STEP 7][SUCCESS] PARTNER_PAYMENT INSERT 성공" + " - paymentId : " + strPaymentId);

					baOutStream.write(strPaymentId.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);		

					printLog("A", "[STEP 7][START] 정산 기준일 조회" + " - aptCode : " + strAptCode);
					
					String strSettlementCutoffDay = "";
					String strSettlementCutoffDayQeury = "";
					strSettlementCutoffDayQeury += " SELECT COMMUNITY_SETTLEMENT_CUTOFF_DAY";
					strSettlementCutoffDayQeury += " FROM APT_CONFIG ";
					strSettlementCutoffDayQeury += " WHERE APT_CODE = " + strAptCode + " ";				
					pstmt = conn.prepareStatement(strSettlementCutoffDayQeury);
					rs = pstmt.executeQuery();

					if(rs.next()) {
						strSettlementCutoffDay = rs.getString(1) != null ? rs.getString(1) : "";
					}

					printLog("A", "[STEP 7][RESULT] 정산 기준일 조회 결과"
									+ " - settlementCutoffDay : "
									+ strSettlementCutoffDay);

					if (strSettlementCutoffDay != null && !strSettlementCutoffDay.isEmpty()) {
						String strSettlementDate = "";

						int cutoffDay = Integer.parseInt(strSettlementCutoffDay);
						
						Calendar cal = Calendar.getInstance();
						int todaySettlement = cal.get(Calendar.DAY_OF_MONTH);
						
						if (cutoffDay == 0) {
							// 매달 말일
							cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH));
						} else if (todaySettlement <= cutoffDay) {
							// 이번달 정산일
							cal.set(Calendar.DAY_OF_MONTH, cutoffDay);
						} else {
							// 다음달 정산일
							cal.add(Calendar.MONTH, 1);
							cal.set(Calendar.DAY_OF_MONTH, cutoffDay);
						}
						
						SimpleDateFormat sdfSettlementDateyyyyMMdd = new SimpleDateFormat("yyyyMMdd");
						strSettlementDate = sdfSettlementDateyyyyMMdd.format(cal.getTime());

						printLog("A", "[STEP 7][START] 회원권 정산일 UPDATE 시작"
										+ " - membershipUserListId : "
										+ strMembershipUserListId
										+ ", settlementDate : "
										+ strSettlementDate);

						String strMembershipSettlementupdateQuery = "";
						strMembershipSettlementupdateQuery += "UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET";
						strMembershipSettlementupdateQuery += " SETTLEMENT_DATE = '" + strSettlementDate + "' ";
						strMembershipSettlementupdateQuery += " WHERE MEMBERSHIP_USER_LIST_ID = '" + strMembershipUserListId + "' ";

						pstmt = conn.prepareStatement(strMembershipSettlementupdateQuery);
						int nSettlement = pstmt.executeUpdate();

						printLog("A", "[STEP 7][RESULT] 회원권 정산일 UPDATE 결과" + " - nSettlement : " + nSettlement);	

						if(nSettlement != 1) {
							printLog("A", "[STEP 7][FAIL] 회원권 정산일 UPDATE 실패"
												+ " - membershipUserListId : "
												+ strMembershipUserListId
												+ ", settlementDate : "
												+ strSettlementDate);

							throw new Exception("회원권 정산일 저장에 실패했습니다.");
						}

						printLog("A", "[STEP 7][SUCCESS] 회원권 정산일 UPDATE 성공"
											+ " - membershipUserListId : "
											+ strMembershipUserListId
											+ ", settlementDate : "
											+ strSettlementDate);
					}

				}else{
					// 무료 회원권
					baOutStream.write(strEmpty.getBytes(S_CHARSET));
					baOutStream.write(COLUMN_DEL);
				}

				printLog("A", "[STEP 8][CHECK] 최종 commit 조건 확인"
								+ " - isTransactionStarted : " + isTransactionStarted
								+ ", isNeedPayment : " + isNeedPayment
								+ ", isPurchase : " + isPurchase
								+ ", membershipUserListId : " + strMembershipUserListId
								+ ", isPaymentConfirmed : " + isPaymentConfirmed
								+ ", isPaymentSaved : " + isPaymentSaved);

				if(!isPurchase) {
					printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 발급 미완료");

					throw new Exception("회원권 발급이 완료되지 않았습니다.");
				}

				if(strMembershipUserListId == null
					|| strMembershipUserListId.contentEquals("")
					|| strMembershipUserListId.contentEquals("0")) {

						printLog("A", "[STEP 8][FAIL] 최종 실패 - 회원권 사용자 ID 없음"
										+ " - membershipUserListId : "
										+ strMembershipUserListId);

						throw new Exception("회원권 사용자 ID가 없습니다.");
				}

				if(isNeedPayment) {

					if(!isPaymentConfirmed) {
						printLog("A", "[STEP 8][FAIL] 최종 실패 - Bootpay 승인 미완료");

						throw new Exception("결제 승인이 완료되지 않았습니다.");
					}

					if(!isPaymentSaved) {
						printLog("A", "[STEP 8][FAIL] 최종 실패 - 결제 DB 저장 미완료");

						throw new Exception("결제 필요 건인데 결제 정보 저장이 완료되지 않았습니다.");
					}
				}

				// =========================================================
				// 회원권, 예약, 결제정보 DB 작업 모두 성공
				// 반드시 응답 반환 전에 commit
				// =========================================================
				if(isTransactionStarted) {

					printLog("A", "[STEP 8][START] 모든 작업 성공, DB COMMIT 시작"
									+ " - membershipUserListId : "
									+ strMembershipUserListId
									+ ", paymentId : "
									+ strPaymentId);

					conn.commit();

					// 반드시 commit 성공 후에만 true
    				isDbCommitted = true;
					shouldRunPostProcess = true;

printLog("A", "*** time test - " + strPaymentId + " : 6 구매처리 완료");

					printLog("A", "[STEP 8][SUCCESS] purchase_membership DB COMMIT 성공" + " - membershipUserListId : " + strMembershipUserListId);

					// =========================================================
					// COMMIT 후 구매 잠금 즉시 해제
					// =========================================================
					if(isPurchaseLockAcquired && strPurchaseLockKey != null && !strPurchaseLockKey.contentEquals("")) {

						String strReleaseLockQuery = "SELECT RELEASE_LOCK(?)";

						pstmt = conn.prepareStatement(strReleaseLockQuery);
						pstmt.setString(1, strPurchaseLockKey);
						rs = pstmt.executeQuery();

						isPurchaseLockAcquired = false;

						printLog("A", "[TRANSACTION][END] purchase_membership 구매 잠금 해제" + " - lockKey : " + strPurchaseLockKey);
					}


					// =========================================================
					// autoCommit 즉시 원복
					// =========================================================
					if(isTransactionStarted) {
						conn.setAutoCommit(true);
						isAutoCommitRestored = true;

						printLog("A", "[TRANSACTION][END] purchase_membership autoCommit 원복 성공");
					}

					returnData(baOutStream, outStream);

					printLog("A", "[RESPONSE][SUCCESS] purchase_membership 앱 응답 전송 완료"
									+ " - membershipUserListId : " + strMembershipUserListId
									+ ", paymentId : " + strPaymentId);
				}

				// =========================================================
				// 1. 얼굴인식 출입 권한 등록
				// - 예약 성공 여부와 분리
				// - 실패해도 앱에는 예약 성공으로 처리
				// =========================================================
				if(shouldRunPostProcess) {

					try {

						printLog("A", "[POST_PROCESS][DOOR][START] 얼굴 출입 등록 시작"
										+ " / membershipUserListId : " + strMembershipUserListId
										+ " / uuid : " + strUUID
										+ " / doorCount : " + listDoorIds.size());

						SimpleDateFormat sdfyyyyMMdd = new SimpleDateFormat("yyyyMMdd");
						Calendar today = Calendar.getInstance();
						String strToday = sdfyyyyMMdd.format(today.getTime());
						String startDate = strStartDate != null && strStartDate.length() >= 8 ? strStartDate.substring(0, 8) : "";

						if(startDate.contentEquals("")) {

							printLog("A", "[POST_PROCESS][DOOR][SKIP] 시작일 정보 없음" + " / membershipUserListId : " + strMembershipUserListId);

						} else if(startDate.compareTo(strToday) > 0) {

							printLog("A", "[POST_PROCESS][DOOR][SKIP] 이용 시작일 이전으로 출입 등록 생략"
											+ " / startDate : " + startDate
											+ " / today : " + strToday
											+ " / membershipUserListId : " + strMembershipUserListId);

						} else if(listDoorIds == null || listDoorIds.isEmpty()) {

							printLog("A", "[POST_PROCESS][DOOR][SKIP] 등록 대상 출입문 없음" + " / membershipUserListId : " + strMembershipUserListId);

						} else {

							for(int nDoorCount = 0;
								nDoorCount < listDoorIds.size();
								nDoorCount++) {

								boolean isSuccess = callDevMembershipReservationAPI(strUserId,
																					strReservationUserName,
																					strUserPhoneNo,
																					strStartDate,
																					strAPIEndDate,
																					listDoorIds.get(nDoorCount),
																					strAptCode,
																					strCommunityType,
																					strUserDong,
																					strUserHo,
																					conn);

								printLog("A", "[POST_PROCESS][DOOR][RESULT]"
											+ " - doorId : " + listDoorIds.get(nDoorCount)
											+ ", isSuccess : " + isSuccess
											+ ", membershipUserListId : " + strMembershipUserListId);
							}

							printLog("A", "[POST_PROCESS][DOOR][END] 얼굴 출입 등록 처리 종료" + " / membershipUserListId : " + strMembershipUserListId);
						}

printLog("A", "*** time test - " + strPaymentId + " : 7 얼굴등록 처리 종료");

					} catch(Exception doorApiException) {

						printLog("A", "[POST_PROCESS][DOOR][FAIL] 출입 등록 API 처리 실패"
										+ " - membershipUserListId : "
										+ strMembershipUserListId
										+ ", exception : "
										+ doorApiException.toString());
					}
				}

				// =========================================================
				// 2. 예약 알림 푸시
				// - 예약 성공 여부와 분리
				// - 실패해도 앱에는 예약 성공으로 처리
				// =========================================================
				if(shouldRunPostProcess) {

					try {

						printLog("A", "[POST_PROCESS][PUSH][START] 예약·결제와 별개로 푸시 처리 시작"
										+ " / membershipUserListId : " + strMembershipUserListId
										+ " / aptCode : " + strAptCode
										+ " / communityType : " + strCommunityType);

						String strPushQuery = "";
						strPushQuery += " SELECT COUNT(*) ";
						strPushQuery += " FROM APT_COMMUNITY ";
						strPushQuery += " WHERE APT_CODE = ? ";
						strPushQuery += " AND COMMUNITY_TYPE = ? ";
						strPushQuery += " AND PUSH_NOTI_CODE IN (1, 4, 9) ";

						pstmt = conn.prepareStatement(strPushQuery);
						pstmt.setString(1, strAptCode);
						pstmt.setString(2, strCommunityType);

						rs = pstmt.executeQuery();

						int nPushNotiCount = 0;

						if(rs.next()) {
							nPushNotiCount = rs.getInt(1);
						}

						if(nPushNotiCount > 0) {

							String strCommunityCenterNameQuery = "";
							strCommunityCenterNameQuery += " SELECT TITLE ";
							strCommunityCenterNameQuery += " FROM APT_COMMUNITY ";
							strCommunityCenterNameQuery += " WHERE APT_CODE = ? ";
							strCommunityCenterNameQuery += " AND COMMUNITY_TYPE = ? ";

							pstmt = conn.prepareStatement(strCommunityCenterNameQuery);

							pstmt.setString(1, strAptCode);
							pstmt.setString(2, strCommunityType);

							rs = pstmt.executeQuery();

							String strCommunityCenterName = "커뮤니티센터";

							if(rs.next()) {
								String strTitle = rs.getString(1);

								if(strTitle != null
									&& !strTitle.contentEquals("")) {

									strCommunityCenterName = strTitle;
								}
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

							// 메시지 생성 및 푸시 전송
							dispatcher.include(request, response);

							printLog("A",  "[POST_PROCESS][PUSH][SUCCESS] 예약 알림 푸시 전송 완료" + " / membershipUserListId : " + strMembershipUserListId);

						} else { 
							printLog("A", "[POST_PROCESS][PUSH][SKIP] 푸시 발송 대상 시설 아님"
											+ " / aptCode : " + strAptCode
											+ " / communityType : " + strCommunityType
											+ " / membershipUserListId : " + strMembershipUserListId);
						}

printLog("A", "*** time test - " + strPaymentId + " : 8 푸시 처리 종료");

					} catch(Exception pushException) {

						printLog("A", "[POST_PROCESS][PUSH][FAIL] 예약 푸시 처리 실패"
										+ " - membershipUserListId : "
										+ strMembershipUserListId
										+ ", exception : "
										+ pushException.toString());
					}
				}
			
			} else {

				strResultCode = "0";
				strResultMessage = "해당 자리는 마감되었습니다. 다른 자리를 선택해주세요.";
				strEmpty = " ";

				baOutStream.write(strResultCode.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				baOutStream.write(strResultMessage.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				baOutStream.write(strEmpty.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				baOutStream.write(strEmpty.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);

				baOutStream.write(strEmpty.getBytes(S_CHARSET));
				baOutStream.write(COLUMN_DEL);
			
			}
			returnData(baOutStream, outStream);

		} catch(Exception e) {

			printLog("A", "[FAIL] purchase_membership 전체 처리 실패"
							+ " - message : " + e.getMessage()
							+ ", exception : " + e.toString()
							+ ", isTransactionStarted : " + isTransactionStarted
							+ ", isPaymentConfirmed : " + isPaymentConfirmed
							+ ", isPaymentSaved : " + isPaymentSaved
							+ ", isPurchase : " + isPurchase
							+ ", membershipUserListId : " + strMembershipUserListId
							+ ", paymentId : " + strPaymentId
							+ ", receiptId : " + strReceiptId);

			// =========================================================
			// 1. DB rollback 시도
			// - DB connection이 이미 끊긴 경우 rollback도 실패할 수 있다.
			// - rollback 실패 여부와 상관없이 아래 결제 보상취소는 진행해야 한다.
			// =========================================================

			try {
				if(isTransactionStarted && !isDbCommitted) {

					printLog("A", "[ROLLBACK][START] purchase_membership DB rollback 시작"
									+ " - membershipUserListId : "
									+ strMembershipUserListId);

					conn.rollback();

					printLog("A", "[ROLLBACK][SUCCESS] purchase_membership DB rollback 성공"
										+ " - membershipUserListId : "
										+ strMembershipUserListId);
				}

			} catch(Exception rollbackException) {

				printLog("A", "[ROLLBACK][FAIL] purchase_membership DB rollback 실패"
								+ " - message : " + rollbackException.getMessage()
								+ ", exception : " + rollbackException.toString());
			}

			
			// =========================================================
			// 2. 결제 승인 후 DB COMMIT 실패 시 Bootpay 보상취소
			// - DB connection이 끊겨도 Bootpay 취소는 별도 HTTP 요청이므로 실행 가능
			// - rollback 성공 여부가 아니라 최종 commit 성공 여부를 기준으로 판단
			// =========================================================
			if(isPaymentConfirmed && !isDbCommitted) {

				try {

					printLog("A", "[PAYMENT_CANCEL][START] purchase_membership 결제 보상취소 시작"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", cancelPrice : " + strPrice
									+ ", membershipUserListId : "
									+ strMembershipUserListId);

					String strCancelResult = cancelBootpayPaymentByReceiptId(strReceiptId, strPrice);

					if("1".contentEquals(strCancelResult)) {

						printLog("A", "[PAYMENT_CANCEL][SUCCESS] purchase_membership 결제 보상취소 성공"
										+ " - paymentId : " + strPaymentId
										+ ", receiptId : " + strReceiptId
										+ ", cancelPrice : " + strPrice);

					} else {

						printLog("A", "[PAYMENT_CANCEL][FAIL] purchase_membership 결제 보상취소 실패"
										+ " - paymentId : " + strPaymentId
										+ ", receiptId : " + strReceiptId
										+ ", cancelPrice : " + strPrice
										+ ", cancelResult : " + strCancelResult);
					}

				} catch(Exception paymentCancelException) {

					printLog("A", "[PAYMENT_CANCEL][ERROR] purchase_membership 결제 보상취소 예외"
									+ " - paymentId : " + strPaymentId
									+ ", receiptId : " + strReceiptId
									+ ", exception : "
									+ paymentCancelException.toString());
				}
			}

			String strExceptionMessage = e.getMessage() != null ? e.getMessage() : "회원권 구매에 실패했습니다.";

			ByteArrayOutputStream errorStream = new ByteArrayOutputStream();

			errorStream.write("0".getBytes(S_CHARSET));
			errorStream.write(COLUMN_DEL);

			errorStream.write(strExceptionMessage.getBytes(S_CHARSET));
			errorStream.write(COLUMN_DEL);

			errorStream.write(" ".getBytes(S_CHARSET));
			errorStream.write(COLUMN_DEL);

			errorStream.write(" ".getBytes(S_CHARSET));
			errorStream.write(COLUMN_DEL);

			errorStream.write(" ".getBytes(S_CHARSET));
			errorStream.write(COLUMN_DEL);

			returnData(errorStream, outStream);

		} finally { 

			try {
				if(isPurchaseLockAcquired && strPurchaseLockKey != null && !strPurchaseLockKey.contentEquals("")) {

					String strReleaseLockQuery = "SELECT RELEASE_LOCK(?)";

					pstmt = conn.prepareStatement(strReleaseLockQuery);

					pstmt.setString(1, strPurchaseLockKey);

					rs = pstmt.executeQuery();

					isPurchaseLockAcquired = false;

					printLog("A", "[TRANSACTION][END] purchase_membership 구매 잠금 해제" + " - lockKey : "+ strPurchaseLockKey);
				}

			} catch(Exception releaseLockException) {

				printLog("A", "[TRANSACTION][FAIL] purchase_membership 구매 잠금 해제 실패" + " - exception : " + releaseLockException.toString());
			}

			try {

				// 성공 흐름에서 이미 원복했으면 재실행하지 않음
				if(isTransactionStarted && !isAutoCommitRestored) {

					conn.setAutoCommit(true);
					isAutoCommitRestored = true;

					printLog("A", "[TRANSACTION][END] purchase_membership autoCommit 원복 성공");
				}

			} catch(Exception autoCommitException) {

				printLog("A", "[TRANSACTION][FAIL] purchase_membership autoCommit 원복 실패" + " - exception : " + autoCommitException.toString());
			}
		}

	}else if(strSID.contentEquals("cancel_membership")){
		String strMembershipUserListId = getRequestParam(request, "MembershipUserListId");
		// 관리자프로그램에서 취소할 경우에는 취소시간, 취소채널이 파라미터로 넘어온다.
		String strRequestCancelTime = getRequestParam(request, "CancelTime");
		String strRequestCancelReason = getRequestParam(request, "CancelReason");
		String strRequestCancelChannel = getRequestParam(request, "CancelChannel");
		String strIsRefund = getRequestParam(request, "IsRefund"); // "0" : 환불 안 함 or "1" : 환불 함

		// =========================================================
		//  null 및 기본값 처리
		// =========================================================
		if(strMembershipUserListId == null) {
			strMembershipUserListId = "";
		}

		if(strRequestCancelTime == null) {
			strRequestCancelTime = "";
		}

		if(strRequestCancelReason == null) {
			strRequestCancelReason = "";
		}

		if(strRequestCancelChannel == null ||
		strRequestCancelChannel.contentEquals("")) {
			// 00: 사용자 앱 취소
			strRequestCancelChannel = "00";
		}

		if(strIsRefund == null || strIsRefund.contentEquals("")) {
			strIsRefund = "1"; // 기본값: 환불 진행
		}
		if(strRequestCancelReason.contentEquals("")) {
			if(strRequestCancelChannel.contentEquals("00")) {
				strRequestCancelReason = "사용자 취소";
			} else {
				strRequestCancelReason = "관리자 취소";
			}
		}	

		// =========================================================
		// 필수 파라미터 검사
		// =========================================================
		if(strMembershipUserListId.contentEquals("")) {
			ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

			baOutStream.write("-1".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			returnData(baOutStream, outStream);
			return;
		}

		

		String strRequestLog = "*** apt_community_membership.jsp cancel_membership Request ***";
		strRequestLog += "\n* strMembershipUserListId : " + strMembershipUserListId;
		strRequestLog += "\n* strRequestCancelTime : " + strRequestCancelTime;
		strRequestLog += "\n* strRequestCancelReason : " + strRequestCancelReason;
		strRequestLog += "\n* strRequestCancelChannel : " + strRequestCancelChannel;
		strRequestLog += "\n* IsRefund : " + strIsRefund;
		strRequestLog += "\n*************************************************************";
		printLog("A", strRequestLog);

		// =========================================================
		// 취소 대상 회원권 조회
		//
		// 앱 또는 관리자 프로그램에서 전달받은
		// MembershipUserListId를 기준으로 취소 대상을 조회한다.
		//
		// MembershipId, AptCode, 동·호, 사용자 정보는
		// 요청 파라미터로 받지 않고 회원권 구매 내역에서 조회하여
		// 이후 예약 취소, 결제 취소 및 연계 회원권 처리에 사용한다.
		//
		// 이미 취소된 회원권은 조회 대상에서 제외한다.
		// =========================================================
		String strMembershipTargetId = "";
		String strMembershipTargetUserName = "";
		String strMembershipId = "";
		String strAptCode = "";
		String strDong = "";
		String strHo = "";
		String strUserId = "";
		String strUserName = "";

		printLog("A", "cancel_membership 취소 대상 조회 시작" + " / MembershipUserListId : " + strMembershipUserListId);

		String strMembershipTargetQuery = "";
		strMembershipTargetQuery += " SELECT ";
		strMembershipTargetQuery += "     MEMBERSHIP_USER_LIST_ID, ";
		strMembershipTargetQuery += "     MEMBERSHIP_ID, ";
		strMembershipTargetQuery += "     APT_CODE, ";
		strMembershipTargetQuery += "     USER_DONG, ";
		strMembershipTargetQuery += "     USER_HO, ";
		strMembershipTargetQuery += "     USER_ID, ";
		strMembershipTargetQuery += "     USER_NAME ";
		strMembershipTargetQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
		strMembershipTargetQuery += " WHERE MEMBERSHIP_USER_LIST_ID = ? ";
		strMembershipTargetQuery += " AND (CANCEL_DATE IS NULL OR CANCEL_DATE = '') ";
		strMembershipTargetQuery += " LIMIT 1 ";

		pstmt = conn.prepareStatement(strMembershipTargetQuery);
		pstmt.setString(1, strMembershipUserListId);

		rs = pstmt.executeQuery();

		if(rs.next()) {
			strMembershipTargetId = rs.getString("MEMBERSHIP_USER_LIST_ID");
			strMembershipId = rs.getString("MEMBERSHIP_ID");
			strAptCode = rs.getString("APT_CODE");
			strDong = rs.getString("USER_DONG");
			strHo = rs.getString("USER_HO");
			strUserId = rs.getString("USER_ID");
			strUserName = rs.getString("USER_NAME");

			if(strMembershipTargetId == null) {
				strMembershipTargetId = "";
			}

			if(strMembershipId == null) {
				strMembershipId = "";
			}

			if(strAptCode == null) {
				strAptCode = "";
			}

			if(strDong == null) {
				strDong = "";
			}

			if(strHo == null) {
				strHo = "";
			}

			if(strUserId == null) {
				strUserId = "";
			}

			if(strUserName == null) {
				strUserName = "";
			}

			if(strMembershipTargetUserName == null) {
				strMembershipTargetUserName = "";
			}

			strMembershipTargetUserName = strUserName;

			printLog("A", "cancel_membership 취소 대상 조회 성공"
							+ " / MembershipUserListId : " + strMembershipTargetId
							+ " / MembershipId : " + strMembershipId
							+ " / AptCode : " + strAptCode
							+ " / UserDong : " + strDong
							+ " / UserHo : " + strHo
							+ " / UserId : " + strUserId
							+ " / UserName : " + strMembershipTargetUserName);

		} else { 
			    printLog("A", "cancel_membership 취소 대상 조회 실패"
								+ " / 전달받은 MembershipUserListId : " + strMembershipUserListId
								+ " / 조회 실패 사유 후보:" + " 존재하지 않는 ID 또는 이미 취소된 회원권");
		}

		printLog("A", "cancel_membership 최종 취소 대상"
						+ " / MEMBERSHIP_USER_LIST_ID : " + strMembershipTargetId
						+ " / MEMBERSHIP_ID : " + strMembershipId
						+ " / APT_CODE : " + strAptCode
						+ " / USER_DONG : " + strDong
						+ " / USER_HO : " + strHo
						+ " / USER_ID : " + strUserId
						+ " / USER_NAME : " + strMembershipTargetUserName);

		// 취소 대상 회원권을 찾지 못하면 오류 리턴
		if(strMembershipTargetId.contentEquals("")) {
			ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

			baOutStream.write("-1".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			returnData(baOutStream, outStream);
			return;
		}

        // 취소 대상 회원권의 연계 조건과 시설 유형 조회
		// MEMBERSHIP_CONDITION:
		// 연계된 세대원 회원권 재구성 여부 판단에 사용
		// COMMUNITY_TYPE:
		// 얼굴인식 출입 권한 삭제 대상 시설을 확인할 때 사용
		String strMembershipConditionQuery = "";
		strMembershipConditionQuery += "SELECT MEMBERSHIP_CONDITION, COMMUNITY_TYPE ";
		strMembershipConditionQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO ";
		strMembershipConditionQuery += " WHERE MEMBERSHIP_ID = '" + strMembershipId + "'";

		rs = pstmt.executeQuery(strMembershipConditionQuery);

		String membershipCondition = ""; 
		String strCommunityType = "";

		if (rs.next()) {
			membershipCondition = rs.getString("MEMBERSHIP_CONDITION");
			strCommunityType = rs.getString("COMMUNITY_TYPE");
		}

		if(membershipCondition == null) {
			membershipCondition = "";
		}

		if(strCommunityType == null) {
			strCommunityType = "";
		}

		printLog("A",  "cancel_membership 회원권 설정 조회"
						+ " / MembershipId : " + strMembershipId
						+ " / MembershipCondition : " + membershipCondition
						+ " / CommunityType : " + strCommunityType);

		String strMembershipCancelQuery = "";
		strMembershipCancelQuery += " UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST SET ";

		if(14 <= strRequestCancelTime.length()) {
			strMembershipCancelQuery += " CANCEL_DATE = " + strRequestCancelTime + ",";
		}  else {
			strMembershipCancelQuery += " CANCEL_DATE = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'),";
		} 
    
		strMembershipCancelQuery += " CANCEL_CHANNEL='" + strRequestCancelChannel + "', ";
		strMembershipCancelQuery += " CANCEL_REASON= '" + strRequestCancelReason + "' ";
		strMembershipCancelQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strMembershipTargetId + " " ;
		printLog("D"," strMembershipCancelQuery : " + strMembershipCancelQuery);

		pstmt = conn.prepareStatement(strMembershipCancelQuery);
		int nRet = pstmt.executeUpdate();	

		printLog("A", "cancel_membership 회원권 취소 처리 결과"
						+ " / MembershipUserListId : " + strMembershipTargetId
						+ " / updateCount : " + nRet);		

		// 회원권 취소 UPDATE가 실제로 반영되지 않은 경우
		// 이후 예약 취소 및 결제 취소 로직을 진행하지 않고 실패 반환
		if(nRet < 1) {
			printLog("A", "cancel_membership 회원권 취소 UPDATE 실패"
							+ " / MembershipUserListId : " + strMembershipTargetId);

			ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

			baOutStream.write("-1".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			returnData(baOutStream, outStream);
			return;
		}

		String strMembershipCancelTypeQuery = "";
		strMembershipCancelTypeQuery += " SELECT CANCEL_TYPE, NEED_TO_PAY ";
		strMembershipCancelTypeQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO  ";
		strMembershipCancelTypeQuery += " WHERE MEMBERSHIP_ID = " +strMembershipId  + " ";
		
		pstmt = conn.prepareStatement(strMembershipCancelTypeQuery);
		rs = pstmt.executeQuery();

		String strMemebershipCancelType = "";
		String strNeedToPay = "";

		if(rs.next()){
			strMemebershipCancelType = rs.getString(1);
			strNeedToPay = rs.getString(2);

			if(strMemebershipCancelType == null) {
				strMemebershipCancelType = "";
			}

			if(strNeedToPay == null){
				strNeedToPay = "";
			}
		}

		if(!strMembershipTargetId.contentEquals("")){
			// 회원권 취소하는데 
			// 앞으로 예약된 내역도 지우는 회원권인지, 아니면 현재 예약만 취소하는 회원권인지 구분
			// 헬스장은 이미 사용중이라 헬스장은 취소하면 현재 이용중인 예약도 취소지만
			// 골프장 같은 경우는 과거 예약은 취소 안 하고 미래에 예약한 내역만 취소하는 회원권이므로 구분이 필요하다고 생각합니다.		

			String strReservationUpdateQuery = "";
			
			if(strMemebershipCancelType.contentEquals("0")){	
				// 헬스장처럼 과거에 예약한 내역 취소
				strReservationUpdateQuery += " UPDATE APT_COMMUNITY_RESERVE SET "; 

				// 관리자프로그램에서 취소할 경우에는 취소시간, 취소채널이 파라미터로 넘어온다.
				if(14 <= strRequestCancelTime.length()) {
					strReservationUpdateQuery += " RESERVE_CANCEL_TIME = " + strRequestCancelTime + ",";
				}  else {
					strReservationUpdateQuery += " RESERVE_CANCEL_TIME = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'),";
				} 

				strReservationUpdateQuery += " RESERVE_CANCEL_CHANNEL='" + strRequestCancelChannel + "', ";
				strReservationUpdateQuery += " CANCEL_REASON = '회원권 취소로 인한 예약 일괄 취소' ";
				strReservationUpdateQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strMembershipTargetId + " " ;

			}else if(strMemebershipCancelType.contentEquals("1")){
				// 골프장처럼 미래에 예약된 내역만 취소
				strReservationUpdateQuery += " UPDATE APT_COMMUNITY_RESERVE SET ";

				if(14 <= strRequestCancelTime.length()) {
					strReservationUpdateQuery += " RESERVE_CANCEL_TIME = " + strRequestCancelTime + ",";
				}  else {
					strReservationUpdateQuery += " RESERVE_CANCEL_TIME = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'),";
				} 
				strReservationUpdateQuery += " RESERVE_CANCEL_CHANNEL='" + strRequestCancelChannel + "', ";
				strReservationUpdateQuery += " CANCEL_REASON = '회원권 취소로 인한 예약 일괄 취소' ";
				strReservationUpdateQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strMembershipTargetId + " " ;
				strReservationUpdateQuery += " AND (IF(LENGTH(DATE) = 8, ";
				strReservationUpdateQuery += "          CONCAT(DATE, LEFT(TIME, 4)), ";
				strReservationUpdateQuery += "          DATE) > DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') )";
			}	

			if(!strReservationUpdateQuery.contentEquals("")) {
				pstmt = conn.prepareStatement(strReservationUpdateQuery);
				int nRetReservation = pstmt.executeUpdate();

				printLog("A", "cancel_membership 연계 예약 취소 결과"
								+ " / MembershipUserListId : " + strMembershipTargetId
								+ " / CancelType : " + strMemebershipCancelType
								+ " / updateCount : " + nRetReservation);
			} else { 
				printLog("A", "cancel_membership 예약 취소 미실행"
								+ " / 잘못되거나 비어 있는 CancelType : " + strMemebershipCancelType
								+ " / MembershipUserListId : " + strMembershipTargetId);
			}

			String strPurchasedMembershipQuery = "SELECT REGISTRATION_DATE, SETTLEMENT_DATE ";
			strPurchasedMembershipQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST ";
			strPurchasedMembershipQuery += " WHERE MEMBERSHIP_USER_LIST_ID = " + strMembershipTargetId + " " ;

			pstmt = conn.prepareStatement(strPurchasedMembershipQuery);
			rs = pstmt.executeQuery();

			String strRegistrationDate = "";
			String strSettlementDate = "";
			boolean idSettlement = false;

			if(rs.next()){
				strRegistrationDate = rs.getString(1);
				strSettlementDate = rs.getString(2);
			}		

			String strToday = new SimpleDateFormat("yyyyMMdd").format(new Date());

			if (strSettlementDate != null && strSettlementDate.length() == 8) {
				if (strToday.compareTo(strSettlementDate) <= 0) {
					// 정산일이 오늘 오늘보다 미래인 경우
					idSettlement = true;
				} else {
					// 정산일이 과거인 경우
					idSettlement = false;
				}
			} else {
				printLog("A", "날짜 값 이상 - strSettlementDate: " + strSettlementDate);
			}
			printLog("A", "strToday: " + strToday);
			printLog("A", "strSettlementDate: " + strSettlementDate);
			printLog("A", "idSettlement: " + idSettlement);

			boolean isReservationFuture = false;

			if (strRegistrationDate != null && strRegistrationDate.length() >= 8) {
				String strRegistrationDateOnly = strRegistrationDate.substring(0, 8);
				if (strRegistrationDateOnly.compareTo(strToday) < 0) {
					// 과거 (등록일이 오늘보다 이전)
					isReservationFuture = false;
				} else if (strRegistrationDateOnly.compareTo(strToday) == 0) {
					// 오늘
					isReservationFuture = false;
				} else {
					// 미래 (등록일이 오늘보다 이후)
					isReservationFuture = true;
				}
			} else {
				printLog("A", "날짜 값 이상 - strRegistrationDate: " + strRegistrationDate);
			}
			
			// 관리자 프로그램에서 취소시 미래날짜 예약인지 체크하지 않고 무조건 취소가능하게 강제로 미래로 세팅해 줌.
			if(!strRequestCancelChannel.contentEquals("00")) {
				isReservationFuture = true;
			}

			printLog("A", "isReservationFuture: " + isReservationFuture);
			printLog("A", "strIsRefund: " + strIsRefund);
			printLog("A", "strNeedToPay: " + strNeedToPay);
			printLog("A", "idSettlement: " + idSettlement);

			// 결과 확인
			if(strNeedToPay != null && !strNeedToPay.contentEquals("") && strIsRefund != null && strIsRefund.contentEquals("1") && idSettlement && isReservationFuture ){
				// 결제를 사용하는 회원권인 경우
				// 결제를 한 예약건인 경우에는 결제 취소까지 진행			
				String strQueryReceiptID = "";
				strQueryReceiptID += " SELECT RECEIPT_ID, TOTAL_PRICE ";
				strQueryReceiptID += " FROM PARTNER_PAYMENT ";
				strQueryReceiptID += " WHERE MENU_ID = '49' ";			
				strQueryReceiptID += " AND RESERVATION_ID = " + strMembershipTargetId + " " ;
				printLog("A", "cancel_membership update PARTNER_PAYMENT strQueryReceiptID " + strQueryReceiptID);

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
					printLog("A", "cancel_membership 결제 취소 요청 영수증 ID - " + strReceiptID);
					printLog("A", "cancel_membership 결제 취소 시작 - " + strReceiptID);

					/** 자바 1.7 ssl 프로토콜 인증 오류로 임시로 개발서버에서 부트페이 호출함 */
					String strPayUrl = ASSIST_SERVER + "bootpay_recepit_cancel.jsp";
					//String strPayUrl = "http://35.212.211.73:8000/bootpay_receipt_cancel";
					
					JSONObject jsonObject = new JSONObject();
					jsonObject.put("ReceiptID", strReceiptID);
					jsonObject.put("CancelPrice", strCancelPrice);
					
					CloseableHttpClient httpclient = HttpClientBuilder.create().build();
					HttpPost httppost = new HttpPost(strPayUrl);
					httppost.addHeader("Content-Type", "application/json;charset=UTF-8");
					printLog("A", "cancel_membership bootpay_recepit_cancel Param : " + jsonObject.toJSONString());
					StringEntity params = new StringEntity(jsonObject.toJSONString(), "UTF-8");
					httppost.setEntity(params);

					ResponseHandler<String> responseHandler = new BasicResponseHandler();
					String strCancelPayment = httpclient.execute(httppost, responseHandler);
					printLog("A", "cancel_membership bootpay_recepit_cancel response : " + strCancelPayment);
					ObjectMapper mapper = new ObjectMapper();
					HashMap resCancelPayment = new HashMap();
					resCancelPayment = mapper.readValue(strCancelPayment, HashMap.class);
					
					JSONObject jsonObj =  new JSONObject(resCancelPayment);
					printLog("A", "cancel_membership receiptCancel() : " + jsonObj);
				
					// 결제 취소 성공
					if(resCancelPayment.get("error_code") == null) {
						String strCancelReceiptID = (String) jsonObj.get("receipt_id");		// 취소된 영수증ID
						String strCancelOrderID = (String) jsonObj.get("order_id");				// 취소된 주문 ID
						printLog("A", "cancel_membership receiptCancel() 성공. 취소된 영수증ID : " + strCancelReceiptID + ", 주문 ID : " + strCancelOrderID);
						String strPrice = getJsonNumberToString(jsonObj, "price");				// 결제.승인 금액
						String strCanceledPrice = getJsonNumberToString(jsonObj, "cancelled_price");				// 취소 금액
						String strPAY_CANCEL_AT = (String) jsonObj.get("cancelled_at");				// 결제취소시간
						strPAY_CANCEL_AT = convDateFormat(strPAY_CANCEL_AT);
						String strReceiptUrl = (String) jsonObj.get("receipt_url");					// 취소된 주문 영수증
						String strStatus = getJsonNumberToString(jsonObj, "status");	// 결제 취소 상태. 
						
						// 결제 취소 - 부분취소시 1(승인)이 성공. 전체취소시 20(취소)이 성공.
						if(strStatus.contentEquals(PAY_PURCHASE) || strStatus.contentEquals(PAY_CANCEL)) {
							printLog("A", "cancel_membership 결제 취소 성공. 결제금액 - " + strPrice + ", 취소금액 - " + strCanceledPrice);
							
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
							printLog("A", "cancel_membership strQueryPaymentUpdate : " + strQueryPaymentUpdate);
							pstmt = conn.prepareStatement(strQueryPaymentUpdate);
							int nPaymentRet = pstmt.executeUpdate();
							printLog("A",  "cancel_membership PAYMENT_PAY 업데이트 결과"
											+ " / updateCount : " + nPaymentRet
											+ " / ReceiptId : " + strReceiptID);														
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
							printLog("A", "cancel_membership strPartnerPaymentQueryUpdate : " + strPartnerPaymentQueryUpdate);
												
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

		if(strMemebershipCancelType.contentEquals("0") && membershipCondition.contentEquals("0")){
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
								"WHERE ul.USER_NAME != ?  AND ul.APT_CODE = ? AND ul.USER_DONG = ? AND ul.USER_HO = ? "+
								" AND mi.MEMBERSHIP_CONDITION = '1' AND mi.MEMBERSHIP_GROUP = ?" +
								" AND (ul.CANCEL_DATE IS NULL OR ul.CANCEL_DATE = '')" +
								" AND  STR_TO_DATE(ul.EXPIRATION_DATE, '%Y%m%d%H%i%s') >= NOW() " +
								" AND STR_TO_DATE(ul.REGISTRATION_DATE, '%Y%m%d%H%i%s') <= NOW() " +
								"LIMIT 1"; // 아무나 결과를 한 개만 추출

			pstmt = conn.prepareStatement(strCheckMembershipQuery);
			pstmt.setString(1, strMembershipTargetUserName);
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
				strMembershipUserListId = rs.getString("MEMBERSHIP_USER_LIST_ID");

				String strCancelMembershipQuery = "UPDATE APT_COMMUNITY_MEMBERSHIP_USER_LIST " +
												"SET CANCEL_DATE = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') " +
												"WHERE MEMBERSHIP_USER_LIST_ID = ?";

				PreparedStatement pstmtCancel = conn.prepareStatement(strCancelMembershipQuery);
				pstmtCancel.setString(1, strMembershipUserListId);						
				pstmtCancel.executeUpdate();
				
				String strCancelReserveQuery = "UPDATE APT_COMMUNITY_RESERVE " +
												"SET RESERVE_CANCEL_TIME = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'), " +
												" RESERVE_CANCEL_CHANNEL = '00' " +
												"WHERE MEMBERSHIP_USER_LIST_ID = ? " ;

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

		if(strCommunityType != null && !strCommunityType.contentEquals("")){
			String strReserveIdQuery = "";
			strReserveIdQuery += " SELECT RESERVE_ID ";
			strReserveIdQuery += " FROM APT_COMMUNITY_RESERVE ";
			strReserveIdQuery += " WHERE MEMBERSHIP_USER_LIST_ID = ? ";
			strReserveIdQuery += " ORDER BY RESERVE_ID DESC ";
			strReserveIdQuery += " LIMIT 1 ";

			pstmt = conn.prepareStatement(strReserveIdQuery);
			pstmt.setString(1, strMembershipTargetId);

			rs = pstmt.executeQuery();	
			
			String strAptCommunityReservationId = "";

			if(rs.next()){
				strAptCommunityReservationId = rs.getString("RESERVE_ID");
			}

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
		
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
		baOutStream.write(Integer.toString(nRet).getBytes(S_CHARSET));
		baOutStream.write(COLUMN_DEL);
		returnData(baOutStream, outStream);

	} else if(strSID.contentEquals("get_my_membership_info")){

		String strAptCode = getRequestParam(request, "AptCode");
		String strUserId = getRequestParam(request, "UserId");		
		// get_membership_list의 첫 번째 값은 APT_COMMUNITY_RESERVE.RESERVE_ID
		String strReserveId = getRequestParam(request, "MembershipId");
		String strInputUserName = getRequestParam(request, "UserName");
		String strDong = getRequestParam(request, "UserDong");
		String strHo = getRequestParam(request, "UserHo");

		if(strReserveId == null || strReserveId.trim().contentEquals("")) {

			printLog(
				"A",
				"get_my_membership_info ReserveId 빈값"
					+ " / AptCode : " + strAptCode
					+ " / UserId : " + strUserId
					+ " / UserName : " + strInputUserName
			);

			ByteArrayOutputStream emptyStream = new ByteArrayOutputStream();
			returnData(emptyStream, outStream);
			return;
		}

		String strQuery = "";
		strQuery += " SELECT ";

		//  커뮤니티 시설 이미지
		strQuery += " ac.IMAGE, ";

		// 커뮤니티 시설명
		strQuery += " ac.TITLE, ";

		// 회원권 이용자 이름
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.USER_NAME
		strQuery += " mul.USER_NAME, ";

		// 예약 상세와 응답 구조를 맞추기 위해 RESERVE_USER_NAME alias로 내려줌
		// 실제로는 mul.USER_NAME과 같은 값
		// QR 노출 시 입력 UserName과 비교하는 기준값
		strQuery += " mul.USER_NAME AS RESERVE_USER_NAME, ";

		// 동
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.USER_DONG
		strQuery += " mul.USER_DONG, ";

		// 호
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.USER_HO
		strQuery += " mul.USER_HO, ";

		// 이용 시작일 / 등록일
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.REGISTRATION_DATE
		// 예약 정보가 없을 때 startDate 기준으로 사용됨
		// 환불 가능 날짜 계산에도 사용됨
		strQuery += " mul.REGISTRATION_DATE, ";

		// 회원권 만료일
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.EXPIRATION_DATE
		// 예약 만료일이 없을 때 endDate 기준으로 사용됨
		// 만료 여부 계산에도 사용됨
		strQuery += " mul.EXPIRATION_DATE, ";

		// 구매일
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.PURCHASE_DATE
		strQuery += " mul.PURCHASE_DATE, ";

		// 회원권 설명
		// 기존 회원권명 후보값
		strQuery += " mul.DESCRIPTION AS MEMBERSHIP_TITLE, ";

		// 회원권 ID
		strQuery += " mul.MEMBERSHIP_ID, ";

		// 회원권 사용자 목록 ID
		strQuery += " mul.MEMBERSHIP_USER_LIST_ID, ";

		// 커뮤니티 타입
		strQuery += " mul.COMMUNITY_TYPE, ";

		// 옵션 ID
		// APT_COMMUNITY_MEMBERSHIP_USER_LIST.OPTIONS
		strQuery += " mul.OPTIONS AS OPTION_IDS, ";

		// 회원권 취소일
		// 값이 있으면 취소된 회원권으로 판단
		strQuery += " mul.CANCEL_DATE, ";

		// 정산일
		// 환불 가능 날짜 계산에 사용됨
		strQuery += " mul.SETTLEMENT_DATE, ";

		// 회원권명
		strQuery += " mi.NAME AS MEMBERSHIP_NAME, ";

		// 회원권 자체 취소 가능 여부
		// APT_COMMUNITY_MEMBERSHIP_INFO.CANCEL_AVAILABLE
		strQuery += " IFNULL(mi.MEMBERSHIP_CANCEL_AVAILABLE, '0') AS MEMBERSHIP_CANCEL_AVAILABLE, ";

		// 예약 취소 가능 여부
		// APT_COMMUNITY_MEMBERSHIP_INFO.RESERVE_CANCEL_AVAILABLE
		// 예약 정보가 있는 회원권은 이 값을 기준으로 취소 버튼 노출 여부를 판단함
		strQuery += " IFNULL(mi.RESERVE_CANCEL_AVAILABLE, '0') AS RESERVE_CANCEL_AVAILABLE, ";

		// 옵션명
		// OPTIONS 값이 있으면 옵션 테이블에서 OPTION_NAME 조회
		strQuery += " CASE ";
		strQuery += "   WHEN mul.OPTIONS IS NOT NULL AND mul.OPTIONS != '' THEN amo.OPTION_NAME ";
		strQuery += "   ELSE NULL ";
		strQuery += " END AS OPTION_NAME, ";

		strQuery += " cr.DATE AS RESERVE_DATE, ";
		strQuery += " cr.EXPIRATION_DATE AS RESERVE_EXPIRATION_DATE, ";
		strQuery += " cr.TIME AS RESERVE_TIME, ";
		strQuery += " cr.PLACE AS RESERVE_PLACE, ";

		// 예약 이용자 성별
		strQuery += " cr.GENDER AS RESERVE_GENDER, ";

		// 예약 타입
		strQuery += " mi.RESERVATION_TYPE ";

		// 기준 테이블
		// 회원권 상세는 APT_COMMUNITY_MEMBERSHIP_USER_LIST 기준으로 조회
		strQuery += " FROM APT_COMMUNITY_MEMBERSHIP_USER_LIST mul ";

		// 예약 정보 조인
		// 앱에서 전달받은 MembershipId 값은 실제로 APT_COMMUNITY_RESERVE.RESERVE_ID이다.
		strQuery += " INNER JOIN APT_COMMUNITY_RESERVE cr ";
		strQuery += "   ON cr.MEMBERSHIP_USER_LIST_ID = mul.MEMBERSHIP_USER_LIST_ID ";
		strQuery += "  AND cr.APT_CODE = mul.APT_CODE ";
		strQuery += "  AND cr.RESERVE_ID = '" + strReserveId + "' ";

		// 커뮤니티 시설 정보 조인
		// 시설 이미지, 시설명 조회용
		strQuery += " LEFT JOIN APT_COMMUNITY ac ";
		strQuery += "   ON ac.COMMUNITY_TYPE = mul.COMMUNITY_TYPE ";
		strQuery += "  AND ac.APT_CODE = mul.APT_CODE ";

		// 회원권 기본 정보 조인
		// 회원권명, 취소 가능 여부, 예약 타입 조회용
		strQuery += " LEFT JOIN APT_COMMUNITY_MEMBERSHIP_INFO mi ";
		strQuery += "   ON mi.MEMBERSHIP_ID = mul.MEMBERSHIP_ID ";

		// 회원권 옵션 정보 조인
		// 옵션명 조회용
		strQuery += " LEFT JOIN APT_COMMUNITY_MEMBERSHIP_OPTION amo ";
		strQuery += "   ON amo.OPTION_ID = mul.OPTIONS ";

		// 조회 조건
		// 같은 아파트의 회원권만 조회
		strQuery += " WHERE mul.APT_CODE = '" + strAptCode + "' ";

		strQuery += "  AND cr.RESERVE_ID = '" + strReserveId + "' ";

		// 본인 회원권이거나,
		// 다른 사람이 예약해준 경우라도 같은 동/호 + 이름이 일치하면 조회 가능
		strQuery += "   AND ( ";
		strQuery += "        mul.USER_ID = '" + strUserId + "' ";
		strQuery += "        OR ( ";
		strQuery += "             mul.USER_DONG = '" + strDong + "' ";
		strQuery += "         AND mul.USER_HO = '" + strHo + "' ";
		strQuery += "         AND mul.USER_NAME = '" + strInputUserName + "' ";
		strQuery += "        ) ";
		strQuery += "   ) ";

		printLog("D", "get_my_membership_info strQuery : " + strQuery);

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
		String strGender = "";
		String strMembershipUserListIdResult = "0";
		String strQRId = ""; // QR 기기 iD
		String strQRSecurityCode = ""; // QR 보안 코드
		String strReserveCount = "";
		String strCancellable = "0";
		String strButtonContext = "";
		String strCancellableDate = "";
		String strSettlementDate = ""; // 정산일
		String strRegistrationDate = ""; // 이용 시작일
		String strMembershipUserName = "";
		String reservationType = "";
        String strReserveDate = "";
        String strReserveExpirationDate = "";
        String strReserveTime = "";

		// 회원권 구매일 / 취소일
		String strPurchaseDate = "";
		String strCancelDate = "";

		// APT_COMMUNITY_MEMBERSHIP_INFO 취소 정책값
		String strCancelAvailable = "0";        // 회원권 취소 가능 여부
		String strReserveCancelAvailable = "0"; // 예약 취소 가능 여부

		if(rs.next()) {
			strImage = rs.getString("IMAGE") != null ? rs.getString("IMAGE") : "";
			strTitle = rs.getString("TITLE") != null ? rs.getString("TITLE") : "";

			strMembershipUserName = rs.getString("USER_NAME") != null ? rs.getString("USER_NAME") : "";
			strUserName = rs.getString("RESERVE_USER_NAME") != null ? rs.getString("RESERVE_USER_NAME") : "";

			// APT_COMMUNITY_RESERVE.PLACE 값이 있으면 사용하고,
			// NULL이면 빈 문자열로 내려줌
			strPlace = rs.getString("RESERVE_PLACE") != null
				? rs.getString("RESERVE_PLACE")
				: "";			

			strReserveDate = rs.getString("RESERVE_DATE") != null ? rs.getString("RESERVE_DATE") : "";
		    strReserveExpirationDate = rs.getString("RESERVE_EXPIRATION_DATE") != null ? rs.getString("RESERVE_EXPIRATION_DATE") : "";
			strReserveTime = rs.getString("RESERVE_TIME") != null ? rs.getString("RESERVE_TIME") : "";


			if(strReserveDate != null && !strReserveDate.contentEquals("")) {
				strDate = strReserveDate;
			} else {
				strDate = rs.getString("REGISTRATION_DATE") != null ? rs.getString("REGISTRATION_DATE") : "";
			}

			if(strReserveExpirationDate != null && !strReserveExpirationDate.contentEquals("")) {
				strExpirationDate = strReserveExpirationDate;
			} else {
				strExpirationDate = rs.getString("EXPIRATION_DATE") != null ? rs.getString("EXPIRATION_DATE") : "";
			}

			if(strReserveTime != null && !strReserveTime.contentEquals("")) {
				strTime = strReserveTime;
			} else {
				strTime = "";
			}

			strMembershipId = rs.getString("MEMBERSHIP_ID") != null ? rs.getString("MEMBERSHIP_ID") : "";
			strMembershipListId = rs.getString("MEMBERSHIP_USER_LIST_ID") != null ? rs.getString("MEMBERSHIP_USER_LIST_ID") : "";
			strMembershipUserListIdResult = rs.getString("MEMBERSHIP_USER_LIST_ID") != null ? rs.getString("MEMBERSHIP_USER_LIST_ID") : "0";

			strCommunitYType = rs.getString("COMMUNITY_TYPE") != null ? rs.getString("COMMUNITY_TYPE") : "";
			strGender = rs.getString("RESERVE_GENDER") != null ? rs.getString("RESERVE_GENDER") : "0";
			strOptionIds = rs.getString("OPTION_IDS") != null ? rs.getString("OPTION_IDS") : "";

			strOptions = rs.getString("OPTION_NAME") != null ? rs.getString("OPTION_NAME") : "";

			strMembershipTitle = rs.getString("MEMBERSHIP_NAME") != null ? rs.getString("MEMBERSHIP_NAME") : "";
			reservationType = rs.getString("RESERVATION_TYPE") != null ? rs.getString("RESERVATION_TYPE") : "";

			// 회원권 자체 취소 가능 여부
			strCancelAvailable = rs.getString("MEMBERSHIP_CANCEL_AVAILABLE") != null ? rs.getString("MEMBERSHIP_CANCEL_AVAILABLE") : "0";

			// 예약 취소 가능 여부
			strReserveCancelAvailable = rs.getString("RESERVE_CANCEL_AVAILABLE") != null ? rs.getString("RESERVE_CANCEL_AVAILABLE") : "0";

			// isCanceled = rs.getString("CANCEL_DATE") != null;

			strPurchaseDate = rs.getString("PURCHASE_DATE") != null ? rs.getString("PURCHASE_DATE").trim() : "";

			strCancelDate = rs.getString("CANCEL_DATE") != null ? rs.getString("CANCEL_DATE").trim() : "";

			isCanceled = !strCancelDate.contentEquals("");
			
			strSettlementDate = rs.getString("SETTLEMENT_DATE") != null ? rs.getString("SETTLEMENT_DATE") : "";
			strRegistrationDate =  rs.getString("REGISTRATION_DATE") != null ? rs.getString("REGISTRATION_DATE") : "";
		} else { 

			// 예약 상세 조회 결과가 없는 경우
			// 가짜 23개 빈 컬럼을 내려주지 않고 빈 응답 반환
			ByteArrayOutputStream emptyStream = new ByteArrayOutputStream();

			printLog(
				"A",
				"get_my_membership_info 조회 결과 없음"
					+ " / AptCode : " + strAptCode
					+ " / ReserveId : " + strReserveId
					+ " / UserId : " + strUserId
			);

			returnData(emptyStream, outStream);
			return;
		}

		// SECURITY 조회
		// 커뮤니티 시설의 보안 사용 여부를 조회함
		String strSecurityQuery = "";
		strSecurityQuery += " SELECT SECURITY ";
		strSecurityQuery += " FROM APT_COMMUNITY ";
		strSecurityQuery += " WHERE COMMUNITY_TYPE = '" + strCommunitYType + "' ";
		strSecurityQuery += " AND APT_CODE = '" + strAptCode + "' ";

		strSecurityQuery += " AND (GENDER = 0 OR GENDER = '" + strGender + "') ";

		printLog("A", "get_my_membership_info strSecurityQuery : " + strSecurityQuery);

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

		if(strInputUserName != null && !strInputUserName.contentEquals("")) {
			isSameUserName = strInputUserName.contentEquals(strMembershipUserName);
		}

		// SECURITY가 QR 보안인 경우 QR 정보 조회
		// 단, 예약 후 추가사용 타입은 QR ID / QR SECURITY CODE 빈값으로 내려줌
		if(strSecurity != null 
			&& strSecurity.contentEquals("2") 
			&& isSameUserName
			&& !isCanceled) {

			// QR 정보 조회 쿼리
			// SECURITY가 "2"인 경우에만 실행됨
			// 단, 아래 조건을 모두 만족해야 QR ID / QR SECURITY CODE가 내려감
			// 1. 보안 상태가 QR 보안("2")
			// 2. 입력받은 UserName과 회원권 USER_NAME이 같음
			// 3. RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE 타입이 아님
			String strQRInfoQuery = "";
			strQRInfoQuery += " SELECT ID, SECURITY_CODE ";
			strQRInfoQuery += " FROM APT_COMMUNITY_QR ";
			strQRInfoQuery += " WHERE APT_CODE = '" + strAptCode + "' ";
			strQRInfoQuery += " AND COMMUNITY_TYPE = '" + strCommunitYType + "' ";
			strQRInfoQuery += " AND (GENDER = 0 OR GENDER = '" + strGender + "') ";
			strQRInfoQuery += " ORDER BY ";
			strQRInfoQuery += " CASE WHEN GENDER = '" + strGender + "' THEN 0 ELSE 1 END ";
			strQRInfoQuery += " LIMIT 1 ";

			printLog("A", "get_my_membership_info strQRInfoQuery : " + strQRInfoQuery);

			PreparedStatement pstmtQRInfo = null;
			ResultSet rsQRInfo = null;

			try {
				pstmtQRInfo = conn.prepareStatement(strQRInfoQuery);
				rsQRInfo = pstmtQRInfo.executeQuery();

				if(rsQRInfo.next()){
					strQRId = rsQRInfo.getString(1) != null ? rsQRInfo.getString(1) : "";
					strQRSecurityCode = rsQRInfo.getString(2) != null ? rsQRInfo.getString(2) : "";
				}
			} finally {
				if(rsQRInfo != null) try { rsQRInfo.close(); } catch(Exception e) {}
				if(pstmtQRInfo != null) try { pstmtQRInfo.close(); } catch(Exception e) {}
			}
		} else {
			strQRId = "";
			strQRSecurityCode = "";
		}	

		// 회원권 정책 조회 쿼리
		// 사용 제한 횟수, 예약 취소 가능 기준, 자리 변경 가능 여부 조회
		String strUsageLimitQuery = "";
		strUsageLimitQuery += " SELECT ";

		// 사용 제한 횟수
		strUsageLimitQuery += " USAGE_LIMIT, ";

		// 예약 취소 가능 시간 단위
		// 예: 분, 시간, 일
		// strCancelType에 저장됨
		strUsageLimitQuery += " RESERVE_CANCEL_AVAILABLE_TIME_UNIT, ";

		// 예약 취소 가능 시간 값
		// 예: 10, 1 등
		// strCancelTime에 저장됨
		strUsageLimitQuery += " RESERVE_CANCEL_AVAILABLE_TIME, ";

		// 자리 변경 가능 여부
		strUsageLimitQuery += " IS_SEAT_CHANGEABLE ";

		strUsageLimitQuery += " FROM APT_COMMUNITY_MEMBERSHIP_INFO  ";
		strUsageLimitQuery += " WHERE MEMBERSHIP_ID = ? ";

		pstmt = conn.prepareStatement(strUsageLimitQuery);
		pstmt.setString(1, strMembershipId);
		rs = pstmt.executeQuery();
		String strUsageLimit = "";

		String strSeatChangeAble = "0";
		String strInfo = "";

		if(rs.next()){
			if(rs.getString("USAGE_LIMIT") != null){
				strUsageLimit = rs.getString("USAGE_LIMIT");
			}

			strCancelType = rs.getString("RESERVE_CANCEL_AVAILABLE_TIME_UNIT") != null ? rs.getString("RESERVE_CANCEL_AVAILABLE_TIME_UNIT") : ""; // 취소 종류(단위 -  0 : 분, 1 : 일)

			strCancelTime = rs.getString("RESERVE_CANCEL_AVAILABLE_TIME") != null ? rs.getString("RESERVE_CANCEL_AVAILABLE_TIME") : ""; // 취소 시간(단위 - 0 : mm분, 1 : dd일)

			if(rs.getString("IS_SEAT_CHANGEABLE") != null){
				strSeatChangeAble = rs.getString("IS_SEAT_CHANGEABLE");
			}
		}

		// 취소된 회원권이면 자리 변경 불가
		if(isCanceled) {
			strSeatChangeAble = "0";
		}
		
		boolean isExpiration = false;

		if(strExpirationDate != null && !strExpirationDate.contentEquals("") && strExpirationDate.length() == 14){
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
		}

		if(!strUserName.contentEquals("")){
			strInfo += "이용자 성함*" + strUserName + "*+" ;
		}

		// 동/호수 제외
		// 시설내역 제외

		if(!strPlace.isEmpty()){
			if(strPlace.contentEquals("PLACE_ALL")){
				strPlace = "대관";
			}
			strInfo += "자리*" + strPlace + "*+" ;
		}

		// 시설 운영 시간 조회
		String strStartTime = "";       // 시설 운영 시작 시각
		String strEndTime = "";         // 시설 운영 종료 시각
		String strOperationHours = "";  // 주중/주말 운영시간 JSON
		String strDisplayStartTime = "";
		String strDisplayEndTime = "";

		String strTimeQuery = getTimeQuery(strAptCode, strCommunitYType);
		printLog("A", "get_my_membership_info strTimeQuery : " + strTimeQuery);

		PreparedStatement pstmtTime = null;
		ResultSet rsTime = null;

		try {
			pstmtTime = conn.prepareStatement(strTimeQuery);
			rsTime = pstmtTime.executeQuery();

			if(rsTime.next()) {
				strStartTime = rsTime.getString(1) != null ? rsTime.getString(1) : "";
				strEndTime = rsTime.getString(2) != null ? rsTime.getString(2) : "";
				strOperationHours = rsTime.getString(3) != null ? rsTime.getString(3) : "";
			}
		} finally {
			if(rsTime != null) try { rsTime.close(); } catch(Exception e) {}
			if(pstmtTime != null) try { pstmtTime.close(); } catch(Exception e) {}
		}

		// 최종 시간 표시 기준
		// 1. APT_COMMUNITY_RESERVE.TIME 값이 있으면 예약 시간 사용
		// 2. TIME 값이 없으면 APT_COMMUNITY.OPERATION_HOURS 사용
		// 3. OPERATION_HOURS도 없으면 START_TIME / END_TIME 사용

		boolean hasReserveTime = strTime != null 
			&& !strTime.contentEquals("") 
			&& strTime.length() == 8;

		if(hasReserveTime) {

			// APT_COMMUNITY_RESERVE.TIME 사용
			strDisplayStartTime = strTime.substring(0, 4);
			strDisplayEndTime = strTime.substring(4, 8);

		} else if(strOperationHours != null && !strOperationHours.contentEquals("")) {

			// APT_COMMUNITY.OPERATION_HOURS 사용
			try {
				SimpleDateFormat sdfOperationHoursL = new SimpleDateFormat("yyyyMMdd");

				String dateForOperationHours = "";
				if(strDate != null && strDate.length() >= 8) {
					dateForOperationHours = strDate.substring(0, 8);
				} else {
					dateForOperationHours = sdfOperationHoursL.format(new Date());
				}

				Date dateOperationHoursL = sdfOperationHoursL.parse(dateForOperationHours);
				Calendar calendarOperationHoursL = Calendar.getInstance();
				calendarOperationHoursL.setTime(dateOperationHoursL);

				int dayOfWeekOHL = calendarOperationHoursL.get(Calendar.DAY_OF_WEEK);

				if(dayOfWeekOHL == Calendar.SATURDAY || dayOfWeekOHL == Calendar.SUNDAY) {
					strDisplayStartTime = extractValue(strOperationHours, "WEEKEND", "start");
					strDisplayEndTime = extractValue(strOperationHours, "WEEKEND", "end");
				} else {
					strDisplayStartTime = extractValue(strOperationHours, "WEEKDAY", "start");
					strDisplayEndTime = extractValue(strOperationHours, "WEEKDAY", "end");
				}

			} catch(Exception e) {
				e.printStackTrace();
				strDisplayStartTime = "";
				strDisplayEndTime = "";
			}

		} else if(strStartTime != null && !strStartTime.contentEquals("")
			&& strEndTime != null && !strEndTime.contentEquals("")) {

			// OPERATION_HOURS가 없을 때만 START_TIME / END_TIME 사용
			strDisplayStartTime = strStartTime;
			strDisplayEndTime = strEndTime;
		}

		// state: 시설 운영시간(OPERATION_HOURS 또는 START_TIME/END_TIME) 기준
		String strOpTimeForState = "";
		if(strOperationHours != null && !strOperationHours.contentEquals("")) {
			try {
				SimpleDateFormat sdfOpTimeForState = new SimpleDateFormat("yyyyMMdd");
				String dateForOpState = "";
				if(strDate != null && strDate.length() >= 8) {
					dateForOpState = strDate.substring(0, 8);
				} else {
					dateForOpState = sdfOpTimeForState.format(new Date());
				}
				Date dateOpState = sdfOpTimeForState.parse(dateForOpState);
				Calendar calendarOpState = Calendar.getInstance();
				calendarOpState.setTime(dateOpState);
				int dayOfWeekOpState = calendarOpState.get(Calendar.DAY_OF_WEEK);
				if(dayOfWeekOpState == Calendar.SATURDAY || dayOfWeekOpState == Calendar.SUNDAY) {
					strOpTimeForState = extractValue(strOperationHours, "WEEKEND", "start")
						+ extractValue(strOperationHours, "WEEKEND", "end");
				} else {
					strOpTimeForState = extractValue(strOperationHours, "WEEKDAY", "start")
						+ extractValue(strOperationHours, "WEEKDAY", "end");
				}
			} catch(Exception e) {
				strOpTimeForState = "";
			}
		} else if(strStartTime != null && !strStartTime.contentEquals("")
			&& strEndTime != null && !strEndTime.contentEquals("")) {
			strOpTimeForState = strStartTime + strEndTime;
		}

		if(!strDate.isEmpty()) {
			String strStartDate = "";
			String strEndDate = "";

			if(strDate.length() >= 8) {
				strStartDate = strDate.substring(0, 8);
			}

			if(strExpirationDate != null && strExpirationDate.length() >= 8) {
				strEndDate = strExpirationDate.substring(0, 8);
			}

			// 실제 예약 시간이 있는 경우에는 단건 예약으로 판단한다.
			// 회원권 만료일과 관계없이 예약 날짜 하나와 예약 시간을 표시한다.
			if(hasReserveTime && !strStartDate.isEmpty()) {

				strInfo += "날짜*" + formatDate(strStartDate) + "*+";

				if(strDisplayStartTime != null
					&& strDisplayEndTime != null
					&& strDisplayStartTime.length() == 4
					&& strDisplayEndTime.length() == 4) {

					String strFormattedTime =
						strDisplayStartTime.substring(0, 2)
						+ ":"
						+ strDisplayStartTime.substring(2, 4)
						+ " ~ "
						+ strDisplayEndTime.substring(0, 2)
						+ ":"
						+ strDisplayEndTime.substring(2, 4);

					strInfo += "시간*" + strFormattedTime + "*+";
				}

			// 예약 시간이 없는 기간형 회원권
			} else if(!strStartDate.isEmpty() && !strEndDate.isEmpty()) {

				if(strStartDate.contentEquals(strEndDate)) {
					strInfo += "날짜*" + formatDate(strStartDate) + "*+";
				} else {
					strInfo += "날짜*"
						+ formatDate(strStartDate)
						+ " ~ "
						+ formatDate(strEndDate)
						+ "*+";
				}

			// 종료일이 없는 경우
			} else if(!strStartDate.isEmpty()) {

				strInfo += "날짜*" + formatDate(strStartDate) + "*+";
			}
		}

		if(strReserveCount != null && !strReserveCount.isEmpty()){
			strInfo += "사용횟수*" + strReserveCount + "회*+";
		}

		if(!strMembershipTitle.isEmpty()){
			if(!strOptions.isEmpty()){
				strMembershipTitle += "\n" + strOptions;
			}
			strInfo += "회원권*" + strMembershipTitle + "*+";
		}

		// 회원권 구매일
		if(strPurchaseDate != null
			&& strPurchaseDate.length() == 14) {

			String strFormattedPurchaseDate =
				formatDateTime(strPurchaseDate);

			if(!strFormattedPurchaseDate.contentEquals("")) {
				strInfo += "구매 날짜*"
					+ strFormattedPurchaseDate
					+ "*+";
			}
		}

		// 취소된 회원권인 경우에만 취소일 표시
		if(isCanceled
			&& strCancelDate != null
			&& strCancelDate.length() == 14) {

			String strFormattedCancelDate =
				formatDateTime(strCancelDate);

			if(!strFormattedCancelDate.contentEquals("")) {
				strInfo += "취소 날짜*"
					+ strFormattedCancelDate
					+ "*+";
			}
		}


		// ========================
		// 취소 가능 여부 판단
		// get_reservation_info 기준으로 맞춤
		// ========================
		// 예약 정보가 있는 회원권이면 RESERVE_CANCEL_AVAILABLE 기준
		// 예약 정보가 없는 순수 회원권이면 CANCEL_AVAILABLE 기준
		// 단, 예약일/예약시간이 있으면 RESERVE_CANCEL_AVAILABLE_TIME 기준으로 취소 마감 시간까지 체크한다.

		strCancellable = "0";
		strButtonContext = "";
		strCancellableDate = "";
		strButtonVisibility = "0";

		// 예약 정보가 있는지 여부
		boolean hasReservationInfo = strReserveDate != null && !strReserveDate.contentEquals("");

		// 예약 시간이 없으면 하루 기준으로 판단
		boolean hasReservationTime = strTime != null && !strTime.contentEquals("");

		String strCancelAvailablePolicy = "";

		// 예약 정보가 있으면 예약 취소 가능 여부 기준
		if(hasReservationInfo) {
			strCancelAvailablePolicy = strReserveCancelAvailable != null ? strReserveCancelAvailable : "0";
		} else {
			// 예약 정보가 없는 순수 회원권이면 기존 회원권 취소 가능 여부 기준
			strCancelAvailablePolicy = strCancelAvailable != null ? strCancelAvailable : "0";
		}

		// 이미 만료되었거나 취소된 경우
		if(isExpiration || isCanceled) {
			strCancellable = "0";
			strButtonContext = "";
			strCancellableDate = "";
			strButtonVisibility = "0";

		} else if(strCancelAvailablePolicy.contentEquals(CANCEL_IMPOSSIBLE)) {
			// 정책상 취소 불가
			strCancellable = "0";
			strButtonContext = "";
			strCancellableDate = "";
			strButtonVisibility = "0";

		} else if(hasReservationInfo) {
			// 예약 정보가 있는 경우 get_reservation_info처럼 취소 가능 시간 계산

			// 취소 가능 시간 값이 없으면 시간 제한 없이 취소 가능 (취소 가능 시간이 없으면 취소 불가 처리에서 반대로 변경)
			if(strCancelTime == null || strCancelTime.contentEquals("")) {
				strCancellable = "1";
				strButtonContext = "취소하기";
				strCancellableDate = "";
				strButtonVisibility = "1";
			} else {
				String compareTime = strTime;

				if(compareTime == null || compareTime.contentEquals("")) {
					compareTime = "00002400";
				}

				try {
					// 서울 타임 존
					TimeZone seoulTimeZone = TimeZone.getTimeZone("Asia/Seoul");

					Calendar reserveDate = Calendar.getInstance(seoulTimeZone);
					Calendar nowDate = Calendar.getInstance(seoulTimeZone);

					int nYear = Integer.parseInt(strDate.substring(0, 4));
					int nMonth = Integer.parseInt(strDate.substring(4, 6));
					int nDay = Integer.parseInt(strDate.substring(6, 8));
					int nHour = Integer.parseInt(compareTime.substring(0, 2));
					int nMinute = Integer.parseInt(compareTime.substring(2, 4));

					reserveDate.set(nYear, nMonth - 1, nDay, nHour, nMinute);


					int cancelTimeValue = Integer.parseInt(strCancelTime.replaceAll("[^0-9]", ""));
					int subtractValue = -cancelTimeValue;

					Calendar cancelLimitDate = (Calendar) reserveDate.clone();

					if(strCancelType.contentEquals(UNIT_MINUTE)) {
						cancelLimitDate.add(Calendar.MINUTE, subtractValue);
					} else if(strCancelType.contentEquals(UNIT_HOUR)) {
						cancelLimitDate.add(Calendar.HOUR_OF_DAY, subtractValue);
					} else if(strCancelType.contentEquals(UNIT_DAYS)) {
						cancelLimitDate.add(Calendar.DAY_OF_MONTH, subtractValue);
					}

					SimpleDateFormat sdfyyMMddHHmm = new SimpleDateFormat("yyMMddHHmm", Locale.KOREAN);
					String formattedCancellableDate = sdfyyMMddHHmm.format(cancelLimitDate.getTime());

					if(cancelLimitDate.compareTo(nowDate) <= 0) {

						// 취소 제한 시간이 지났으므로 취소 불가
						strCancellable = "0";

						if(cancelTimeValue == 0) {
							strButtonContext = "예약 시작 이후에는 취소가 불가능합니다.";

						} else if(strCancelType.contentEquals(UNIT_MINUTE)) {
							strButtonContext = "예약 " + strCancelTime + "분 전까지만 취소가 가능합니다.";

						} else if(strCancelType.contentEquals(UNIT_HOUR)) {
							strButtonContext = "예약 " + strCancelTime + "시간 전까지만 취소가 가능합니다.";

						} else if(strCancelType.contentEquals(UNIT_DAYS)) {
							strButtonContext = "예약 " + strCancelTime + "일 전까지만 취소가 가능합니다.";

						} else {
							// 단위값이 예상과 다를 때 기본 문구
							strButtonContext = "예약 취소 가능 시간이 지났습니다.";
						}

						strCancellableDate = "";
						strButtonVisibility = "1"; // 버튼 표시

					} else {
						// 취소 가능
						strCancellable = "1";
						strButtonContext = "취소하기";
						strCancellableDate = formattedCancellableDate;
						strButtonVisibility = "1";
					}

				} catch(Exception e) {
					e.printStackTrace();

					// 날짜 파싱 실패 시 안전하게 취소 불가 처리
					strCancellable = "0";
					strButtonContext = "";
					strCancellableDate = "";
					strButtonVisibility = "0";
				}
			}

		} else {
			// 예약 정보가 없는 순수 회원권 취소
			strCancellable = "1";
			strButtonContext = "취소하기";
			strCancellableDate = "";
			strButtonVisibility = "1";
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
			isRegistrationAfterToday = strRegistrationDate.substring(0, 8).compareTo(strToday) > 0;
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


		// 영수증 URL 조회 쿼리
		// 결제 영수증 URL 조회
		String strReceiptURLQeury = "";
		strReceiptURLQeury += " SELECT RECEIPT_URL FROM PARTNER_PAYMENT ";
		strReceiptURLQeury += " WHERE MENU_ID = '49' ";

		// 회원권 사용자 목록 ID 기준으로 영수증 조회
		strReceiptURLQeury += " AND RESERVATION_ID = '" + strMembershipUserListIdResult + "' ";

		pstmt = conn.prepareStatement(strReceiptURLQeury);
		rs = pstmt.executeQuery();

		String strReceiptURL = "";
		if(rs.next()){
			if(rs.getString(1) != null){
				strReceiptURL = rs.getString(1);
			}
		}

		List<Holiday> holidays = new ArrayList<Holiday>();

		// 휴무일 조회 쿼리
		// getHolidaysQuery 내부에서 커뮤니티별 정기휴무/임시휴무 설정을 조회하는 구조로 보임
		// 운영상태 계산에 사용됨
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

		Calendar today = Calendar.getInstance();
		int todayDayOfWeek = today.get(Calendar.DAY_OF_WEEK) - 1;
		int todayDayOfMonth = today.get(Calendar.DAY_OF_MONTH);
		int weekOfMonth = today.get(Calendar.WEEK_OF_MONTH);

		SimpleDateFormat dateFormatHHmm = new SimpleDateFormat("HHmm");
		String formattedDateHHmm = dateFormatHHmm.format(today.getTime());
		int nNowTime = Integer.parseInt(formattedDateHHmm);

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

		boolean bHasReservationTime = hasReserveTime;

		if(strDisplayStartTime != null && strDisplayEndTime != null
			&& strDisplayStartTime.length() == 4
			&& strDisplayEndTime.length() == 4) {

			strTime = strDisplayStartTime + strDisplayEndTime;

		} else {
			strTime = "00002400";
		}


		boolean bValidTime = (strTime != null && strTime.length() == 8);
		SimpleDateFormat sdfHHmm = new SimpleDateFormat("HHmm");
		Calendar calStart = null;
		Calendar calEnd = null;

		// if(bValidTime && bHasReservationTime) {
		// 	// 예약시간이 있는 경우 - QR 응답용 시작 -15분, 종료 +15분 (입장 융통성)
		// 	calStart = Calendar.getInstance();
		// 	calStart.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTime.substring(0,2)));
		// 	calStart.set(Calendar.MINUTE, Integer.parseInt(strTime.substring(2,4)));
		// 	calStart.add(Calendar.MINUTE, -15);
		// 	calEnd = Calendar.getInstance();
		// 	calEnd.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strTime.substring(4,6)));
		// 	calEnd.set(Calendar.MINUTE, Integer.parseInt(strTime.substring(6,8)));
		// 	calEnd.add(Calendar.MINUTE, 15);
		// }

		if(bValidTime && bHasReservationTime
			&& strDate != null
			&& strDate.length() >= 8) {

		try {
			TimeZone seoulTimeZone = TimeZone.getTimeZone("Asia/Seoul");

			int nYear = Integer.parseInt(strDate.substring(0, 4));
			int nMonth = Integer.parseInt(strDate.substring(4, 6));
			int nDay = Integer.parseInt(strDate.substring(6, 8));

			int nStartHour = Integer.parseInt(strTime.substring(0, 2));
			int nStartMinute = Integer.parseInt(strTime.substring(2, 4));

			int nEndHour = Integer.parseInt(strTime.substring(4, 6));
			int nEndMinute = Integer.parseInt(strTime.substring(6, 8));

			// QR 입장 가능 시작 시각: 예약 시작 15분 전
			calStart = Calendar.getInstance(seoulTimeZone);
			calStart.clear();
			calStart.set(
				nYear,
				nMonth - 1,
				nDay,
				nStartHour,
				nStartMinute,
				0
			);
			calStart.add(Calendar.MINUTE, -15);

			// QR 입장 가능 종료 시각: 예약 종료 15분 후
			calEnd = Calendar.getInstance(seoulTimeZone);
			calEnd.clear();

			if(nEndHour == 24 && nEndMinute == 0) {
				// 24:00은 다음 날 00:00으로 처리
				calEnd.set(
					nYear,
					nMonth - 1,
					nDay,
					0,
					0,
					0
				);
				calEnd.add(Calendar.DAY_OF_MONTH, 1);
			} else {
				calEnd.set(
					nYear,
					nMonth - 1,
					nDay,
					nEndHour,
					nEndMinute,
					0
				);
			}

			calEnd.add(Calendar.MINUTE, 15);

			Calendar now = Calendar.getInstance(seoulTimeZone);

			boolean isWithinQRAvailableTime =
				now.compareTo(calStart) >= 0
				&& now.compareTo(calEnd) <= 0;

			// QR 입장 가능 시간이 아니면 QR 정보 제거
			if(!isWithinQRAvailableTime) {
				strQRId = "";
				strQRSecurityCode = "";
			}

			printLog(
				"D",
				"get_my_membership_info QR 시간 확인"
					+ " / now : " + now.getTime()
					+ " / calStart : " + calStart.getTime()
					+ " / calEnd : " + calEnd.getTime()
					+ " / isWithinQRAvailableTime : "
					+ isWithinQRAvailableTime
			);

		} catch(Exception e) {
			e.printStackTrace();

			// 시간 계산 오류가 발생한 경우에도 QR이 노출되지 않도록 처리
			strQRId = "";
			strQRSecurityCode = "";
			calStart = null;
			calEnd = null;
		}
	}

		// state: 시설 운영시간(OPERATION_HOURS 또는 START_TIME/END_TIME) ±15분 기준
		boolean bValidOpTime = (strOpTimeForState != null && strOpTimeForState.length() == 8);
		int nOpStartTime = 0;
		int nOpEndTime = 0;
		
		// if(bValidOpTime) {
		// 	Calendar calOpStart = Calendar.getInstance();
		// 	calOpStart.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strOpTimeForState.substring(0, 2)));
		// 	calOpStart.set(Calendar.MINUTE, Integer.parseInt(strOpTimeForState.substring(2, 4)));
		// 	calOpStart.add(Calendar.MINUTE, -15);
		// 	Calendar calOpEnd = Calendar.getInstance();
		// 	calOpEnd.set(Calendar.HOUR_OF_DAY, Integer.parseInt(strOpTimeForState.substring(4, 6)));
		// 	calOpEnd.set(Calendar.MINUTE, Integer.parseInt(strOpTimeForState.substring(6, 8)));
		// 	calOpEnd.add(Calendar.MINUTE, 15);
		// 	nOpStartTime = Integer.parseInt(sdfHHmm.format(calOpStart.getTime()));
		// 	nOpEndTime = Integer.parseInt(sdfHHmm.format(calOpEnd.getTime()));
		// }

		if(bValidOpTime) {

			String strOpStart = strOpTimeForState.substring(0, 4);
			String strOpEnd = strOpTimeForState.substring(4, 8);

			int nStartHour = Integer.parseInt(strOpStart.substring(0, 2));
			int nStartMinute = Integer.parseInt(strOpStart.substring(2, 4));

			int nEndHour = Integer.parseInt(strOpEnd.substring(0, 2));
			int nEndMinute = Integer.parseInt(strOpEnd.substring(2, 4));

			Calendar calOpStart = Calendar.getInstance();
			calOpStart.set(Calendar.HOUR_OF_DAY, nStartHour);
			calOpStart.set(Calendar.MINUTE, nStartMinute);
			calOpStart.set(Calendar.SECOND, 0);
			calOpStart.set(Calendar.MILLISECOND, 0);
			calOpStart.add(Calendar.MINUTE, -15);

			Calendar calOpEnd = Calendar.getInstance();
			calOpEnd.set(Calendar.SECOND, 0);
			calOpEnd.set(Calendar.MILLISECOND, 0);

			if(nEndHour == 24 && nEndMinute == 0) {
				// 2400은 당일 마지막 시각으로 처리
				calOpEnd.set(Calendar.HOUR_OF_DAY, 23);
				calOpEnd.set(Calendar.MINUTE, 59);
			} else {
				calOpEnd.set(Calendar.HOUR_OF_DAY, nEndHour);
				calOpEnd.set(Calendar.MINUTE, nEndMinute);
				calOpEnd.add(Calendar.MINUTE, 15);
			}

			nOpStartTime = Integer.parseInt(
				sdfHHmm.format(calOpStart.getTime())
			);

			nOpEndTime = Integer.parseInt(
				sdfHHmm.format(calOpEnd.getTime())
			);
		}

		String strState;
		String strStateTitle;

		// if (isHoliday) {
		// 	strState = "2";
		// 	if(isTempHoliday) {
		// 		strStateTitle = "임시휴무";
		// 	} else {
		// 		strStateTitle = "정기휴무";
		// 	}
		// } else if (!bValidOpTime) {
		// 	strState = "4";
		// 	strStateTitle = "운영종료";
		// } else if (
		// 	(nOpStartTime <= nOpEndTime && nOpStartTime <= nNowTime && nOpEndTime >= nNowTime)
		// 	||
		// 	(nOpStartTime > nOpEndTime && (nNowTime >= nOpStartTime || nNowTime <= nOpEndTime))
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

		boolean isAllDayOperation = "00002400".contentEquals(strOpTimeForState);

		if(isHoliday) {
			strState = "2";

			if(isTempHoliday) {
				strStateTitle = "임시휴무";
			} else {
				strStateTitle = "정기휴무";
			}

		} else if(isAllDayOperation) {
			// 00:00 ~ 24:00 시설
			strState = "1";
			strStateTitle = "운영중";

		} else if(!bValidOpTime) {
			strState = "4";
			strStateTitle = "운영종료";

		} else if(
			(nOpStartTime <= nOpEndTime
				&& nOpStartTime <= nNowTime
				&& nOpEndTime >= nNowTime)
			||
			(nOpStartTime > nOpEndTime
				&& (nNowTime >= nOpStartTime
					|| nNowTime <= nOpEndTime))
		) {
			strState = "1";
			strStateTitle = "운영중";

		} else {
			strState = "4";

			if(strCommunitYType.contentEquals(TYPE_GUESTHOUSE)) {
				strStateTitle = "운영중";
				strState = "1";
			} else {
				strStateTitle = "운영종료";
			}
		}

		printLog("D", strState);
		printLog("D", strStateTitle);

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write(strImage.getBytes(S_CHARSET)); // 10
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strTitle.getBytes(S_CHARSET)); // 1
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strInfo.getBytes(S_CHARSET)); // 2
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strCancellable.getBytes(S_CHARSET)); // 3
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strButtonContext.getBytes(S_CHARSET)); // 4
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strCancellableDate.getBytes(S_CHARSET)); // 5
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strButtonVisibility.getBytes(S_CHARSET)); // 6
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strSecurity.getBytes(S_CHARSET)); // 7
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strSeatChangeAble.getBytes(S_CHARSET)); // 8
		baOutStream.write(COLUMN_DEL);		

		baOutStream.write(strMembershipId.getBytes(S_CHARSET)); // 9
		baOutStream.write(COLUMN_DEL);	
		
		baOutStream.write(strOptionIds.getBytes(S_CHARSET)); // 10
		baOutStream.write(COLUMN_DEL);	
		
		baOutStream.write(strPlace.getBytes(S_CHARSET)); // 11
		baOutStream.write(COLUMN_DEL);	
		
		String strStartDate = "";
		String strEndDate = "";

		if(strDate != null && strDate.length() >= 8) {
			strStartDate = strDate.substring(0, 8);
		}

		// 실제 예약 시간이 있는 단건 예약이면 시작일과 종료일을 동일하게 내려준다.
		if(hasReserveTime && !strStartDate.contentEquals("")) {

			strEndDate = strStartDate;

		} else if(strExpirationDate != null && strExpirationDate.length() >= 8) {

			// 시간이 없는 기간형 회원권만 만료일 사용
			strEndDate = strExpirationDate.substring(0, 8);
		}

		if((strEndDate == null || strEndDate.contentEquals(""))
			&& strStartDate != null
			&& !strStartDate.contentEquals("")) {

			strEndDate = strStartDate;
		}

		baOutStream.write(strStartDate.getBytes(S_CHARSET));  // 12
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strEndDate.getBytes(S_CHARSET)); // 13
		baOutStream.write(COLUMN_DEL);

		
		if(calStart != null && calEnd != null) {
			baOutStream.write(sdfHHmm.format(calStart.getTime()).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(sdfHHmm.format(calEnd.getTime()).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		} else if(strDisplayStartTime != null 
			&& strDisplayEndTime != null
			&& strDisplayStartTime.length() == 4
			&& strDisplayEndTime.length() == 4) {

			baOutStream.write(strDisplayStartTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strDisplayEndTime.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

		} else if(strTime != null && strTime.length() == 8) {
			baOutStream.write(strTime.substring(0,4).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strTime.substring(4,8).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		} else if(strDate != null && strDate.length() >= 12 && strExpirationDate != null && strExpirationDate.length() >= 12) {
			baOutStream.write(strDate.substring(8,12).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(strExpirationDate.substring(8,12).getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		} else {
			baOutStream.write("".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);

			baOutStream.write("".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		baOutStream.write(strCommunitYType.getBytes(S_CHARSET)); // 14
		baOutStream.write(COLUMN_DEL);

		if(strReceiptURL == null || strReceiptURL.trim().contentEquals("")){
			baOutStream.write("".getBytes(S_CHARSET));
		}else{
			baOutStream.write(strReceiptURL.getBytes(S_CHARSET)); //15
		}
		baOutStream.write(COLUMN_DEL);

		if(strQRId == null || strQRId.trim().contentEquals("")){
			baOutStream.write("".getBytes(S_CHARSET));
		}else{
			baOutStream.write(strQRId.getBytes(S_CHARSET)); //15
		}

		// baOutStream.write(strQRId.getBytes(S_CHARSET)); // 16
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strQRSecurityCode.getBytes(S_CHARSET)); // 17
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strState.getBytes(S_CHARSET)); // 18
		baOutStream.write(COLUMN_DEL);

		if(strRefundableDate == null || strRefundableDate.trim().contentEquals("")){ // 19
			baOutStream.write("".getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}else{
			baOutStream.write(strRefundableDate.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
		}

		// 20. 실제 구매·이용 회원권 고유 ID
		// cancel_membership 요청 시 MembershipUserListId로 다시 전달
		if(strMembershipUserListIdResult == null
				|| strMembershipUserListIdResult.trim().contentEquals("")) {

			baOutStream.write("0".getBytes(S_CHARSET));

		} else {
			baOutStream.write(
				strMembershipUserListIdResult.getBytes(S_CHARSET)
			);
		}
		baOutStream.write(COLUMN_DEL);
		
		baOutStream.write(RECORD_DEL);	
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
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

