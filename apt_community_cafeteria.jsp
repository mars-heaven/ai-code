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

<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
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


	// 시간 HH:mm타입을 HHmm타입으로 포맷
    public static String parseToHHmmHHmm(String time) {
        return time.replaceAll(":", "").replaceAll(" ","").replaceAll("~","");
    }



	public static String formatPhoneNumber(String phoneNumber) {
        // 전화번호가 11자리일 때 010-1234-5678 형식으로 변환
        if (phoneNumber != null && phoneNumber.length() == 11) {
            return phoneNumber.substring(0, 3) + "-" +
                   phoneNumber.substring(3, 7) + "-" +
                   phoneNumber.substring(7);
        } else {
            // 전화번호가 유효하지 않다면 그대로 반환
            return phoneNumber;
        }
    }

	public static String formatDateTime(String dateTime) {
        // dateTime이 14자리일 때 "yyyy-MM-dd HH:mm:ss" 형식으로 변환
        if (dateTime != null && dateTime.length() == 12) {
            return dateTime.substring(0, 4) + "-" +
                   dateTime.substring(4, 6) + "-" +
                   dateTime.substring(6, 8) + " " +
                   dateTime.substring(8, 10) + ":" +
                   dateTime.substring(10, 12) + ":00";
        } else {
            // 날짜 및 시간이 유효하지 않다면 그대로 반환
            return dateTime;
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
	printLog("D", "apt_community_cafeteria paramJson : " + paramJson.toString());

	// Load JDBC Driver and connect to database
	Class.forName(driverClass);
	conn = DriverManager.getConnection(dbUrl, dbUserId, dbUserPasswd);

	// Get Parameter - SID = query 구분.
	String strSID = getJsonParam(paramJson, "SID");
	printLog("A", "SID : " + strSID);

	if(strSID.contentEquals("get_cafeteria_category")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");

		String strCategoryQuery = "";
		strCategoryQuery += "SELECT a.CATEGORY_ID, a.CATEGORY_NAME FROM MENU_CATEGORY as a ";
		strCategoryQuery += " JOIN MENU as b ON a.CATEGORY_ID = b.CATEGORY_ID ";
		strCategoryQuery += " WHERE b.APT_CODE = ? GROUP BY b.CATEGORY_ID ";

		pstmt = conn.prepareStatement(strCategoryQuery);
		pstmt.setString(1, strAptCode);	
		rs = pstmt.executeQuery();

		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();

		rsMetaData = rs.getMetaData();

		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";
				jsonItem.put(rsMetaData.getColumnLabel(nCol), strData);
			}
			dataArr.add(jsonItem);
		}
		resJson.put("RESULT", "SUCCESS");
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
		returnJson(response, resJson);

	}else if(strSID.contentEquals("get_cafeteria_menu")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");
		String strCategotyId = getJsonParam(paramJson, "CategoryId");

		String strMenuQuery = "";
		strMenuQuery += "SELECT MENU_ID, MENU_STATUS, MENU_NAME, MENU_PRICE, MENU_IMAGE_URL, MENU_DESCRIPTION ";
		strMenuQuery += " FROM MENU ";
		strMenuQuery += " WHERE APT_CODE = ? AND CATEGORY_ID = ? ";
		strMenuQuery += " AND MENU_HIDDEN = '0' ";
		strMenuQuery += " ORDER BY MENU_ID  ";

		pstmt = conn.prepareStatement(strMenuQuery);	
		pstmt.setString(1, strAptCode);	
		pstmt.setString(2, strCategotyId);	
	
		rs = pstmt.executeQuery();

		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();

		rsMetaData = rs.getMetaData();

		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";
				jsonItem.put(rsMetaData.getColumnLabel(nCol), strData);
			}
			dataArr.add(jsonItem);
		}
		resJson.put("RESULT", "SUCCESS");
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
		returnJson(response, resJson);

	}else if(strSID.contentEquals("get_cafeteria_menu_detail")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");
		String strMenuId = getJsonParam(paramJson, "MenuId");

		String strMenuQuery = "";
		strMenuQuery += "SELECT MENU_STATUS, MENU_NAME, MENU_PRICE, MENU_IMAGE_URL, MENU_DETAIL_IMAGE_URL, MENU_DESCRIPTION ";
		strMenuQuery += " FROM MENU ";
		strMenuQuery += " WHERE APT_CODE = ? AND MENU_ID = ? ";
		strMenuQuery += " AND MENU_HIDDEN = '0' ";
		strMenuQuery += " ORDER BY MENU_ID  ";

		pstmt = conn.prepareStatement(strMenuQuery);	
		pstmt.setString(1, strAptCode);	
		pstmt.setString(2, strMenuId);	
	
		rs = pstmt.executeQuery();

		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();

		rsMetaData = rs.getMetaData();

		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";
				jsonItem.put(rsMetaData.getColumnLabel(nCol), strData);
			}
			dataArr.add(jsonItem);
		}
		resJson.put("RESULT", "SUCCESS");
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
		returnJson(response, resJson);

	}else if(strSID.contentEquals("submit_menu_order")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");
		String strMenuIds = getJsonParam(paramJson, "MenuIds");
		String strQuantities = getJsonParam(paramJson, "Quantities");
		String strPrices = getJsonParam(paramJson, "Prices");
		String strUserName = getJsonParam(paramJson, "UserName");		
		String strUserDong = getJsonParam(paramJson,"UserDong");	
		String strUserHo = getJsonParam(paramJson, "UserHo");		
		String strUserPhone = getJsonParam(paramJson, "UserPhoneNo");

		if(strUserPhone != null) strUserPhone = strUserPhone.replaceAll("-","").replaceAll(" ","");
		if(strMenuIds == null) strMenuIds = "";
		if(strQuantities == null) strQuantities = "";
		if(strPrices == null) strPrices = "";

		String[] MenuIds = strMenuIds.split(",");
		String[] Quantities = strQuantities.split(",");
		String[] Prices = strPrices.split(",");

		if(strMenuIds.contentEquals("") || strQuantities.contentEquals("") || strPrices.contentEquals("") ||
		MenuIds.length != Quantities.length || Quantities.length != Prices.length) {
			resJson.put("RESULT", "SUCCESS");
			JSONObject jsonData = new JSONObject();
			jsonData.put("result", "9");
			resJson.put("DATA", jsonData);
			returnJson(response, resJson);
			return;
		}


		printLog("D","MenuIds.length : " +MenuIds.length);
		printLog("D","Quantities.length : " +Quantities.length);
		printLog("D","Prices.length : " +Prices.length);


		String strOrderIdQuery = "";
		strOrderIdQuery += "SELECT ORDER_ID ";
		strOrderIdQuery += "FROM ORDER_MENU ";
		strOrderIdQuery += "WHERE APT_CODE = ? ";
		strOrderIdQuery += "ORDER BY ORDER_TIME DESC ";
		strOrderIdQuery += "LIMIT 1 ";

		pstmt = conn.prepareStatement(strOrderIdQuery);
		pstmt.setString(1, strAptCode);
		rs = pstmt.executeQuery();
		
		String strOrderId = "";

		if(rs.next()){
			strOrderId = rs.getString("ORDER_ID") != null ? rs.getString("ORDER_ID") : "";
		}

		String[] OrderIds = strOrderId.split("_");


		Calendar today = Calendar.getInstance();
		SimpleDateFormat dateFormatyyyyMMdd = new SimpleDateFormat("yyMMdd");
		String strToday = dateFormatyyyyMMdd.format(today.getTime());

		// 새로운 OrderId 생성 로직
		String newOrderId = "";
		if (OrderIds.length == 3 && OrderIds[1].contentEquals(strToday)) {
			// 같은 날짜의 주문이 있는 경우, 마지막 번호에 1을 더함
			int lastNumber = 10;
			try{
				lastNumber = Integer.parseInt(OrderIds[2]);
			}catch(Exception e){
				e.printStackTrace();  // Exception 처리
			}
			newOrderId = strAptCode + "_" + strToday + "_" + (lastNumber + 1);
		} else {
			// 같은 날짜의 주문이 없는 경우, 번호를 1부터 시작
			newOrderId = strAptCode + "_" + strToday + "_10";
		}
		

		int nRet = 0;
		try {
			// MySQL INSERT 쿼리 실행 코드
			String strSubmitOrderQuery = "INSERT INTO ORDER_MENU ";
			strSubmitOrderQuery += " (ORDER_ID, APT_CODE, USER_ID, USER_DONG, USER_HO, USER_NAME, USER_PHONE, ORDER_TIME) ";
			strSubmitOrderQuery += " VALUES (?, ?, ?, ?, ?, ?, ?, DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'))";
			pstmt = conn.prepareStatement(strSubmitOrderQuery);
			pstmt.setString(1, newOrderId);
			pstmt.setString(2, strAptCode);
			pstmt.setString(3, strUserId);
			pstmt.setString(4, strUserDong);
			pstmt.setString(5, strUserHo);
			pstmt.setString(6, strUserName);
			pstmt.setString(7, strUserPhone);

			nRet = pstmt.executeUpdate();
		} catch (SQLException e) {
			if (e.getErrorCode() == 1062) {  // MySQL에서 Primary Key 중복 오류 코드
				// 중복된 Primary Key가 있을 때 처리하는 로직
				printLog("D", "중복된 Primary Key 값이 존재합니다.");
			} else {			
				e.printStackTrace();  // 다른 SQLException 처리
			}
		}

		if(nRet == 1){
			int nInsertCount = 0;
			int nInsertRet = 0;
			for(int nMenuCount = 0; nMenuCount < MenuIds.length; nMenuCount++) {
				try{
					String strSubmitOrderDetailQuery = "INSERT INTO ORDER_MENU_DETAIL ";
					strSubmitOrderDetailQuery += " (ORDER_ID, MENU_ID, PRICE, QUANTITY) ";
					strSubmitOrderDetailQuery += " VALUES (?, ?, ?, ?)";
					pstmt = conn.prepareStatement(strSubmitOrderDetailQuery);
					pstmt.setString(1, newOrderId);
					pstmt.setString(2, MenuIds[nMenuCount]);
					pstmt.setString(3, Prices[nMenuCount]);
					pstmt.setString(4, Quantities[nMenuCount]);

					nInsertRet = pstmt.executeUpdate();
				}catch(Exception e){
					e.printStackTrace();  // 다른 SQLException 처리
					nRet = 2;
				}
				if(nInsertRet == 1){
					nInsertCount = nInsertCount + 1;
				}
			}
			if(nInsertCount != MenuIds.length){
				nRet = 2;
			}
		}

	
	
		resJson.put("RESULT", "SUCCESS");
		JSONObject jsonData = new JSONObject();
		jsonData.put("result", Integer.toString(nRet));
		jsonData.put("orderId", newOrderId);
		resJson.put("DATA", jsonData);
		returnJson(response, resJson);

	}else if(strSID.contentEquals("get_order_list")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");	
		String strItemCount = getJsonParam(paramJson, "ItemCount");
		String strLimitCnt = getJsonParam(paramJson, "LimitCnt");

		printLog("D","strAptCode : " +strAptCode);
		printLog("D","strUserId : " +strUserId);
		printLog("D","strItemCount : " +strItemCount);
		printLog("D","strLimitCnt : " +strLimitCnt);

		String strQuery = "";	
		strQuery += " SELECT ORDER_ID, ORDER_STATUS, ";
		strQuery += " IF(CANCEL_TIME IS NOT NULL AND CANCEL_TIME != '', CANCEL_TIME, ";
		strQuery += "    IF(PICKUP_TIME IS NULL OR PICKUP_TIME = '', ORDER_TIME, PICKUP_TIME)";
		strQuery += " ) ";
		strQuery += " FROM ORDER_MENU ";
		strQuery += " WHERE USER_ID = ? AND APT_CODE = ? ";
		strQuery += " ORDER BY ORDER_TIME DESC, PICKUP_TIME DESC ";
		if(strItemCount != null && !strItemCount.contentEquals("") && !strItemCount.contentEquals("0")){
			int nItemCount = Integer.parseInt(strItemCount);
			strQuery += " LIMIT ?, ? ";
		}else{
			strQuery += " LIMIT ? ";
		}

		printLog("D","strQuery : " +strQuery);


		pstmt = conn.prepareStatement(strQuery);
		pstmt.setString(1, strUserId);
		pstmt.setString(2, strAptCode);
		if(strItemCount != null && !strItemCount.contentEquals("") && !strItemCount.contentEquals("0")){
			pstmt.setInt(3, Integer.parseInt(strItemCount));
			pstmt.setInt(4, Integer.parseInt(strLimitCnt));
					printLog("D","strItemCount : " +strItemCount);

		}else{
			pstmt.setInt(3, Integer.parseInt(strLimitCnt)); 
					printLog("D","strLimitCnt : " +strLimitCnt);

		}

		resJson.put("RESULT", "SUCCESS");
		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();

		rs = pstmt.executeQuery();

		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			String strOrderId = rs.getString(1) != null ? rs.getString(1) : "";
			String strOrderStatus = rs.getString(2) != null ? rs.getString(2) : "";
			String strDisplayTime = rs.getString(3) != null ? rs.getString(3) : "";
			String strPrcie = "";
			try{
				String strPriceQuery = "SELECT COALESCE(SUM(PRICE * QUANTITY), 0) FROM ORDER_MENU_DETAIL WHERE ORDER_ID = ? ";
				PreparedStatement pstmtPrice = conn.prepareStatement(strPriceQuery);
				pstmtPrice.setString(1, strOrderId);
				ResultSet rsPrice = pstmtPrice.executeQuery();
				if(rsPrice.next()) {
					String tempPrice = rsPrice.getString(1);
					if(tempPrice != null) {
						strPrcie = tempPrice;
					}
				}
				rsPrice.close();
				pstmtPrice.close();
			}catch(SQLException e){
				e.printStackTrace();
			}
			jsonItem.put("ORDER_ID", strOrderId);
			jsonItem.put("ORDER_STATUS", strOrderStatus);
			jsonItem.put("DISPLAY_TIME", strDisplayTime);
			jsonItem.put("TOTAL_PRICE", strPrcie);
			dataArr.add(jsonItem);
		}
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
		// 데이터 조립한 후, 클라이언트로 전송..
		returnJson(response, resJson);

	}else if(strSID.contentEquals("get_order_detail")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserId = getJsonParam(paramJson, "UserId");	
		String strOrderId = getJsonParam(paramJson, "OrderId");

		String strQuery = "";
		strQuery += " SELECT ORDER_TIME, PICKUP_TIME ";
		strQuery += " FROM ORDER_MENU ";
		strQuery += " WHERE ORDER_ID = ? ";
		strQuery += " AND CANCEL_TIME IS NULL ";

		pstmt = conn.prepareStatement(strQuery);
		pstmt.setString(1, strOrderId);
		rs = pstmt.executeQuery();

		String strOrderTime = "";
		String strPickUpTime = "";
		String strTotalPrice = "";

		if(rs.next()){
			strOrderTime = rs.getString("ORDER_TIME") != null ? rs.getString("ORDER_TIME") : "";
			strPickUpTime = rs.getString("PICKUP_TIME") != null ? rs.getString("PICKUP_TIME") : "";
		}

	

		String strPriceQuery = "SELECT COALESCE(SUM(PRICE * QUANTITY), 0) FROM ORDER_MENU_DETAIL WHERE ORDER_ID = ? ";		
		pstmt = conn.prepareStatement(strPriceQuery);
		pstmt.setString(1, strOrderId);		
		rs = pstmt.executeQuery();
		if(rs.next()) {  // 반드시 next()를 호출하고 데이터를 읽어야 함
			String tempPrice = rs.getString(1);
			if(tempPrice != null) {
				strTotalPrice = tempPrice;
			}
		}

		

		resJson.put("RESULT", "SUCCESS");
		JSONObject jsonData = new JSONObject();
		jsonData.put("orderTime", strOrderTime);
		jsonData.put("pickupTime", strPickUpTime);
		jsonData.put("totalPrice", strTotalPrice);

		String strMenuQuery = "";
		strMenuQuery += "SELECT (SELECT MENU_NAME FROM MENU WHERE MENU_ID = a.MENU_ID) as MENU_NAME, ";
		strMenuQuery += " a.QUANTITY, a.PRICE ";
		strMenuQuery += " FROM ORDER_MENU_DETAIL as a";
		strMenuQuery += " WHERE ORDER_ID = ? ";

		pstmt = conn.prepareStatement(strMenuQuery);
		pstmt.setString(1, strOrderId);
		rs = pstmt.executeQuery();

		JSONArray dataArr = new JSONArray();
		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			jsonItem.put("MENU_NAME", rs.getString(1) != null ? rs.getString(1) : "");
			jsonItem.put("QUANTITY", rs.getString(2) != null ? rs.getString(2) : "");
			jsonItem.put("PRICE", rs.getString(3) != null ? rs.getString(3) : "");
			dataArr.add(jsonItem);
		}
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);

		returnJson(response, resJson);



	}else if(strSID.contentEquals("get_cafeteria_purchase_limit")){
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strCommuntyType = getJsonParam(paramJson, "CommunityType");

		printLog("D"," strAptCode : " + strAptCode);
		printLog("D"," strCommuntyType : " + strCommuntyType);
		

		String strCommunityQuery = "";
		strCommunityQuery += "SELECT RESERVE_LIMIT ";
		strCommunityQuery += " FROM APT_COMMUNITY ";
		strCommunityQuery += " WHERE APT_CODE = ? AND COMMUNITY_TYPE = ? ";

		pstmt = conn.prepareStatement(strCommunityQuery);	
		pstmt.setString(1, strAptCode);	
		pstmt.setString(2, strCommuntyType);	
	
		rs = pstmt.executeQuery();

		JSONObject jsonData = new JSONObject();
		JSONArray dataArr = new JSONArray();

		rsMetaData = rs.getMetaData();

		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);
				if(strData == null) strData = "";
				jsonItem.put(rsMetaData.getColumnLabel(nCol), strData);
			}
			dataArr.add(jsonItem);
		}
		resJson.put("RESULT", "SUCCESS");
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
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

