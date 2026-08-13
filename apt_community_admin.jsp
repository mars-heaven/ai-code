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

<%!

	public String getJsonParam(JSONObject json, String strKey) {
		if (json == null || strKey == null) return "";
		Object val = json.get(strKey);
		return val == null ? "" : val.toString();
	}


	/**
	 * JSON 결과 전송
	 */
	public void returnJson(HttpServletResponse response, JSONObject jsonResponse) {
		try {
			printLog("A", "returnJson : " + jsonResponse.toJSONString());
			response.setContentType("application/json");
			response.setCharacterEncoding("UTF-8");
			PrintWriter out = response.getWriter();
			out.print(jsonResponse.toJSONString());
			out.flush();
			out.close();
		} catch (Exception e) {
			e.printStackTrace();
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

    public void callLockDevice(String strAptCode, String strCommunityType, List<String> doorIds, String strStatus) {
    	// 우회서버에 v9서비스 없음. IP만 변경함.
    	String baseUrl = "http://146.56.179.38/xmobile/villizinei/community/community_api_v9.jsp";
        String strCallSID = "call_lock_device_api";								

		for (String doorId : doorIds) {
			 try {
				// 쿼리 파라미터 인코딩
				String query = String.format("SID=%s&strAptCode=%s&strCommunityType=%s&strDoorId=%s&strLockStatus=%s",
						URLEncoder.encode(strCallSID, "UTF-8"),
						URLEncoder.encode(strAptCode, "UTF-8"),
						URLEncoder.encode(strCommunityType, "UTF-8"),
						URLEncoder.encode(doorId, "UTF-8"),
						URLEncoder.encode(strStatus, "UTF-8")
				);

				// 전체 URL 생성
				String urlString = baseUrl + "?" + query;
				URL url = new URL(urlString);
				System.out.println("Request URL: " + url);

				HttpURLConnection connAPI = (HttpURLConnection) url.openConnection();
				connAPI.setRequestMethod("POST");

				int responseCode = connAPI.getResponseCode();
				System.out.println("Response Code: " + responseCode);

				// ✅ 1초(1000ms) 대기
				Thread.sleep(1000);

			} catch (Exception e) {
				e.printStackTrace();				
			}
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

JSONObject resJson = new JSONObject();

try {

	// JSON Body 파싱
	request.setCharacterEncoding("UTF-8");
	StringBuilder sb = new StringBuilder();
	BufferedReader br = request.getReader();
	String line;
	while ((line = br.readLine()) != null) {
		sb.append(line);
	}
	JSONParser parser = new JSONParser();
	JSONObject paramJson = (JSONObject) parser.parse(sb.toString());
	printLog("D", "apt_community_admin paramJson : " + paramJson.toString());

	// Load JDBC Driver and connect to database
	Class.forName(driverClass);
	conn = DriverManager.getConnection(dbUrl, dbUserId, dbUserPasswd);

	// Get Parameter - SID = query 구분.
	String strSID = getJsonParam(paramJson, "SID");
	printLog("A", "SID : " + strSID);

	if(strSID.contentEquals("get_apt_door_list")) {
		//문 리스트 조회하기
		String strUserId = getJsonParam(paramJson, "UserId");
        String strAptCode = getJsonParam(paramJson, "AptCode");
        String strUserGrade = getJsonParam(paramJson, "UserGrade");

        printLog("A", "strUserId : " + strUserId);
	    printLog("A", "strAptCode : " + strAptCode);
    	printLog("A", "strUserGrade : " + strUserGrade);


        if(Integer.parseInt(strUserGrade) <= 3){
            // return
            resJson.put("RESULT", "SUCCESS");
            JSONObject jsonData = new JSONObject();
            jsonData.put("result", "0");
            resJson.put("DATA", jsonData);
            // 데이터 조립한 후, 클라이언트로 전송..
            returnJson(response, resJson);
            return;
        }

		String strDoorQuery = "";
		strDoorQuery += "SELECT COMMENT, RESERVE_COMMUNITY_TYPE ";
		strDoorQuery += "FROM APT_COMMUNITY_DOOR ";
		strDoorQuery += "WHERE APT_CODE = ? ";
        strDoorQuery += "GROUP BY COMMENT, RESERVE_COMMUNITY_TYPE ";
        strDoorQuery += "ORDER BY COMMENT ";

		pstmt = conn.prepareStatement(strDoorQuery);
        pstmt.setString(1, strAptCode);
		rs = pstmt.executeQuery();
        rsMetaData = rs.getMetaData();

		resJson.put("RESULT", "SUCCESS");
		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();
		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";
				jsonItem.put(rsMetaData.getColumnLabel(nCol), strData);
			}
			dataArr.add(jsonItem);
		}
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);

		// 데이터 조립한 후, 클라이언트로 전송..
		returnJson(response, resJson);

	}else if(strSID.contentEquals("unlock_door")){
        // 문 여는 서비스
        String strUserId = getJsonParam(paramJson, "UserId");
        String strAptCode = getJsonParam(paramJson, "AptCode");
        String strTitle = getJsonParam(paramJson, "Title");
        String strCommunityType = getJsonParam(paramJson, "CommunityType");



        String strCommunityDoorIdQuery = "";
        strCommunityDoorIdQuery += " SELECT DOOR_ID ";
        strCommunityDoorIdQuery += " FROM APT_COMMUNITY_DOOR ";
        strCommunityDoorIdQuery += " WHERE 1 = 1 ";
        strCommunityDoorIdQuery += " AND APT_CODE = " + strAptCode + " ";
        strCommunityDoorIdQuery += " AND RESERVE_COMMUNITY_TYPE LIKE '%" + strCommunityType + "%' ";
        strCommunityDoorIdQuery += " AND COMMENT = '" + strTitle + "' ";

        printLog("A", "strCommunityDoorIdQuery : " + strCommunityDoorIdQuery);

        PreparedStatement pstmtDoor = conn.prepareStatement(strCommunityDoorIdQuery);

        ResultSet rsDoor = pstmtDoor.executeQuery();


        List<String> listDoorIds = new ArrayList<String>();
        String strDoorId = "";
        for(int nRow2 = 0; rsDoor.next(); nRow2++) {
            strDoorId = rsDoor.getString(1);
            listDoorIds.add(strDoorId);
        }
        callLockDevice(strAptCode, strCommunityType, listDoorIds ,"2");

		for (String doorId : listDoorIds) {
			String strLogQuery = "INSERT INTO APT_COMMUNITY_DOOR_LOCK_HISTORY ";
			strLogQuery += "(USER_ID, APT_CODE, COMMUNITY_TYPE, DOOR_ID, EVENT_TYPE, EVENT_TIME) ";
			strLogQuery += "VALUES ";
			strLogQuery += "('" + strUserId + "', " + strAptCode + ", '" + strCommunityType + "', '" + doorId + "', '2', DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s')) ";

			pstmt = conn.prepareStatement(strLogQuery);
			pstmt.executeUpdate();
		}

        // return
        resJson.put("RESULT", "SUCCESS");
        JSONObject jsonData = new JSONObject();
        jsonData.put("result", "1");
        resJson.put("DATA", jsonData);
        // 데이터 조립한 후, 클라이언트로 전송..
        returnJson(response, resJson);
    }else if(strSID.contentEquals("lock_door")){
        // 문 여는 서비스
        String strUserId = getJsonParam(paramJson, "UserId");
        String strAptCode = getJsonParam(paramJson, "AptCode");
        String strTitle = getJsonParam(paramJson, "Title");
        String strCommunityType = getJsonParam(paramJson, "CommunityType");



        String strCommunityDoorIdQuery = "";
        strCommunityDoorIdQuery += " SELECT DOOR_ID ";
        strCommunityDoorIdQuery += " FROM APT_COMMUNITY_DOOR ";
        strCommunityDoorIdQuery += " WHERE 1 = 1 ";
        strCommunityDoorIdQuery += " AND APT_CODE = " + strAptCode + " ";
        strCommunityDoorIdQuery += " AND RESERVE_COMMUNITY_TYPE LIKE '%" + strCommunityType + "%' ";
        strCommunityDoorIdQuery += " AND COMMENT = '" + strTitle + "' ";
            printLog("A", "strCommunityDoorIdQuery : " + strCommunityDoorIdQuery);

        PreparedStatement pstmtDoor = conn.prepareStatement(strCommunityDoorIdQuery);

        ResultSet rsDoor = pstmtDoor.executeQuery();


        List<String> listDoorIds = new ArrayList<String>();
        String strDoorId = "";
        for(int nRow2 = 0; rsDoor.next(); nRow2++) {
            strDoorId = rsDoor.getString(1);
            listDoorIds.add(strDoorId);
        }
        callLockDevice(strAptCode, strCommunityType,listDoorIds ,"1");


		for (String doorId : listDoorIds) {
			String strLogQuery = "INSERT INTO APT_COMMUNITY_DOOR_LOCK_HISTORY ";
			strLogQuery += "(USER_ID, APT_CODE, COMMUNITY_TYPE, DOOR_ID, EVENT_TYPE, EVENT_TIME) ";
			strLogQuery += "VALUES ";
			strLogQuery += "('" + strUserId + "', " + strAptCode + ", '" + strCommunityType + "', '" + doorId + "', '1', DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s')) ";

			pstmt = conn.prepareStatement(strLogQuery);
			pstmt.executeUpdate();
		}

        // return
        resJson.put("RESULT", "SUCCESS");
        JSONObject jsonData = new JSONObject();
        jsonData.put("result", "1");
        resJson.put("DATA", jsonData);
        // 데이터 조립한 후, 클라이언트로 전송..
        returnJson(response, resJson);
    }
}catch(Exception e) {
	String errMsg = "Exception Msg = " + e.getMessage();
	printLog("A", " ###### errMsg  = #####" + errMsg);

	resJson.put("RESULT", "FAIL");
	resJson.put("ERRMSG", e.getMessage());
	// 데이터 조립한 후, 클라이언트로 전송..
	returnJson(response, resJson);
}
finally {
	// Release a database resources
	if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
	if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }
	if(conn != null) { try { conn.close(); } catch(Exception ignore) {} }
}
%>

