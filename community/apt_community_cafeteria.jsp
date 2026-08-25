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




<%@ include file="./apt_community_common.jsp" %>

<%
Connection 			conn = null;			// DB Connection Object
PreparedStatement 	pstmt = null;			// JDBC PreparedStatement Object
ResultSet 			rs = null;	 			// Query Result Set Object

ResultSetMetaData 	rsMetaData = null;
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

	if(strSID.contentEquals("get_cafeteria_category")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");

		String strCategoryQuery = "";
		strCategoryQuery += "SELECT a.CATEGORY_ID, a.CATEGORY_NAME FROM MENU_CATEGORY as a ";
		strCategoryQuery += " JOIN MENU as b ON a.CATEGORY_ID = b.CATEGORY_ID ";
		strCategoryQuery += " WHERE b.APT_CODE = ? GROUP BY b.CATEGORY_ID ";

		pstmt = conn.prepareStatement(strCategoryQuery);
		pstmt.setString(1, strAptCode);	
		rs = pstmt.executeQuery();

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeResultSet(baOutStream, rs);
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_cafeteria_menu")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strCategotyId = getRequestParam(m_issacweb, request, "CategoryId");

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

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeResultSet(baOutStream, rs);
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_cafeteria_menu_detail")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strMenuId = getRequestParam(m_issacweb, request, "MenuId");

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

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeResultSet(baOutStream, rs);
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("submit_menu_order")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");
		String strMenuIds = getRequestParam(m_issacweb, request, "MenuIds");
		String strQuantities = getRequestParam(m_issacweb, request, "Quantities");
		String strPrices = getRequestParam(m_issacweb, request, "Prices");
		String strUserName = getRequestParam(m_issacweb, request, "UserName");		
		String strUserDong = getRequestParam(m_issacweb,request,"UserDong");	
		String strUserHo = getRequestParam(m_issacweb, request, "UserHo");		
		String strUserPhone = getRequestParam(m_issacweb, request, "UserPhoneNo");

		if(strUserPhone != null) strUserPhone = strUserPhone.replaceAll("-","").replaceAll(" ","");
		if(strMenuIds == null) strMenuIds = "";
		if(strQuantities == null) strQuantities = "";
		if(strPrices == null) strPrices = "";

		String[] MenuIds = strMenuIds.split(",");
		String[] Quantities = strQuantities.split(",");
		String[] Prices = strPrices.split(",");

		

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		if(strMenuIds.contentEquals("") || strQuantities.contentEquals("") || strPrices.contentEquals("") ||
		MenuIds.length != Quantities.length || Quantities.length != Prices.length) {			
			int nInvalidArrayLengths = 9;
			writeText(baOutStream, Integer.toString(nInvalidArrayLengths));

			returnData(m_issacweb, baOutStream, outStream);
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

	
	
		writeColumn(baOutStream, Integer.toString(nRet));
		writeColumn(baOutStream, newOrderId);


		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_order_list")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");	
		String strItemCount = getRequestParam(m_issacweb, request, "ItemCount");
		String strLimitCnt = getRequestParam(m_issacweb, request, "LimitCnt");

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

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		rs = pstmt.executeQuery();

		rsMetaData = rs.getMetaData();

		String strServiceType = "";
		for(int nRow = 0; rs.next(); nRow++) {
			String strPrcie = "";
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);	
				if(strData == null) strData = "";	
				if(nCol == 1){
					try{
    					String strPriceQuery = "SELECT COALESCE(SUM(PRICE * QUANTITY), 0) FROM ORDER_MENU_DETAIL WHERE ORDER_ID = ? ";		
						PreparedStatement pstmtPrice = conn.prepareStatement(strPriceQuery);
						pstmtPrice.setString(1, strData);		
						ResultSet rsPrice = pstmtPrice.executeQuery();
						if(rsPrice.next()) {  // 반드시 next()를 호출하고 데이터를 읽어야 함
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
				}
				writeColumn(baOutStream, strData);
				if(nCol == rsMetaData.getColumnCount()) {
					writeColumn(baOutStream, strPrcie);
				}	
			}
			writeRecord(baOutStream);
		}
		// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
		returnData(m_issacweb, baOutStream, outStream);

	}else if(strSID.contentEquals("get_order_detail")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strUserId = getRequestParam(m_issacweb, request, "UserId");	
		String strOrderId = getRequestParam(m_issacweb, request, "OrderId");

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

		

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeColumn(baOutStream, strOrderTime);
		writeColumn(baOutStream, strPickUpTime);
		writeColumn(baOutStream, strTotalPrice);
		
		String strMenuQuery = "";
		strMenuQuery += "SELECT (SELECT MENU_NAME FROM MENU WHERE MENU_ID = a.MENU_ID), ";
		strMenuQuery += " a.QUANTITY, a.PRICE ";
		strMenuQuery += " FROM ORDER_MENU_DETAIL as a";
		strMenuQuery += " WHERE ORDER_ID = ? ";
		
		pstmt = conn.prepareStatement(strMenuQuery);
		pstmt.setString(1, strOrderId);
		rs = pstmt.executeQuery();

		rsMetaData = rs.getMetaData();

		String strServiceType = "";
		for(int nRow = 0; rs.next(); nRow++) {
			for(int nCol = 1; nCol <= rsMetaData.getColumnCount(); nCol++) {
				String strData = rs.getString(nCol);	
				if(strData == null) strData = "";				
				writeColumn(baOutStream, strData);
			}
		}
		writeRecord(baOutStream);

		returnData(m_issacweb, baOutStream, outStream);



	}else if(strSID.contentEquals("get_cafeteria_purchase_limit")){
		String strAptCode = getRequestParam(m_issacweb, request, "AptCode");
		String strCommuntyType = getRequestParam(m_issacweb, request, "CommunityType");

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

		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		writeResultSet(baOutStream, rs);
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

