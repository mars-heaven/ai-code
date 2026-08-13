<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*"%>
<%@ page import="org.apache.http.impl.client.HttpClientBuilder" %>
<%@ page import="org.apache.http.impl.client.CloseableHttpClient" %>
<%@ page import="org.apache.http.impl.client.BasicResponseHandler" %>
<%@ page import="org.apache.http.client.ResponseHandler" %>
<%@ page import="org.apache.http.client.methods.CloseableHttpResponse" %>
<%@ page import="org.apache.http.client.methods.HttpPost" %>
<%@ page import="org.apache.http.entity.StringEntity" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="org.json.simple.JSONArray" %>
<%@ page import="org.json.simple.parser.JSONParser"%>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Date"%>
<%@ page import="java.util.Collections"%>
<%@ page import="java.util.ArrayList"%>
<%@ include file="./apt_global.jsp" %>

<%!	
	/**
	 * 주차연동 업체 코드
	 */
	final String PARKING_COMPANY_NEXPA		= "001";	// 넥스파
	final String PARKING_COMPANY_AMANO		= "002";	// 아마노코리아
	final String PARKING_COMPANY_HYUN		= "003";	// 현파킹시스템
	final String PARKING_COMPANY_SPONE		= "004";	// 에스피원
	final String PARKING_COMPANY_DYIOT		= "005";	// 대영아이오티
	final String PARKING_COMPANY_PNPHT		= "006";	// 피앤피하이텍(루나랩스)
	final String PARKING_COMPANY_COMMAX	= "007";	// 코맥스
	final String PARKING_COMPANY_CMCNI		= "008";	// 청명씨앤아이
	
	/**
	 * 주차연동 업체 인증키
	 */
	// 아마노 - Basic 인증중이나 자체DB방식이 아니라 서비스가 분리되어 있어서 서비스내에서 사용안함.
	final String AUTHKEY_HEADER_AMANO = "";
	// 대영아이오티 - Bearer 인증키. 업체 현장 전체 동일키 사용.
	final String AUTHKEY_HEADER_DYIOT = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIwMjQyMDY0ODgiLCJuYW1lIjoiaHR0cDovL3d3dy5keWlrMjEuY28ua3IvIiwidmlzaW9uIjoidjQifQ.FWrZJsSj3ElO7tSp4QHMDM5TJ5HsvTyuJK0ByzSv1Q8";
	// 피앤피하이텍(루나랩스) - body에 인증키 스트링 사용중이나 자체DB방식이 아니라 서비스가 분리되어 있어서 서비스내에서 사용안함.
	final String AUTHKEY_BODY_PNPHT = "";
	// 청명씨앤아이 - 아파트별인지 최초 현장이라 확인되지 않음.
	final String AUTHKEY_HEADER_CMCNI = "Bearer ALH-48266593-6k2mQ0e1r9VbPpZ1nY3sGx7kT2hWc8JfL0aDq5mN";
	
	/**
	 * 주차연동 업체로 방문등록, 삭제 하지 않고 자체 DB로 처리함.
	 */
	final String NO_SEND_COMPANY = "NO_SEND";

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
	 * 업체 인증 토큰. 있을 경우만 사용. 아파트별로 다를 경우 위해 아파트 코드도 받음
	 */
	public String getSendDataAuth(String strCompanyCode, String strAptCode) {
		if(strCompanyCode == null || strCompanyCode.contentEquals("")) {
			printLog("A", "getSendDataAuth strCompanyCode null");
			return "";
		}
		
		try {
			// 업체 인증 토큰
			String strAuth = "";

			if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
				strAuth = AUTHKEY_HEADER_DYIOT;
			} else if(strCompanyCode.contentEquals(PARKING_COMPANY_CMCNI)) {
				strAuth = AUTHKEY_HEADER_CMCNI;
			} else {
				strAuth = "";
			}
		
			return strAuth;
		} catch (Exception ex) {
			printLog("D", "Exception : " + ex.getMessage());	
			return "";
		}
	}	
	
	/**
	 * 방문예약 업체 송신 데이터 조립
	 */
	public JSONObject getSendDataVisitReg(String strCompanyCode, String strSendAptCode, String strDong, String strHo, String strCarNumber, String strStartDate, String strEndDate, String strMemo) {
		if(strCompanyCode == null || strCompanyCode.contentEquals("")) {
			printLog("A", "getSendDataVisitReg strCompanyCode null");
			return null;
		}
		
		try {
			// 업체 송수신 전문 양식대로 조립
			JSONObject jsonObject = new JSONObject();
			/** 005 : 대영아이오티 */
			if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
				// 방문일 날짜 포맷 변환
				SimpleDateFormat inputFormat = new SimpleDateFormat("yyyyMMddHHmmss");
				SimpleDateFormat outputFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
				Date dateStart = inputFormat.parse(strStartDate);
				Date dateEnd = inputFormat.parse(strEndDate);
				String strSendStartDate = outputFormat.format(dateStart);
				String strSendEndDate = outputFormat.format(dateEnd);
				// 상점ID - 동+호(4자리0맞춤). 예시. 1010101 : 101동101호
				String strSendHo = "0000" + strHo;
				strSendHo = strSendHo.substring(strSendHo.length() - 4, strSendHo.length());
				String strShopID = strDong + strSendHo;
				
				jsonObject.put("carno", strCarNumber);		//차량번호(필수)
				jsonObject.put("usebgndt", strSendStartDate);		//방문예약 시작일(필수)
				jsonObject.put("useenddt", strSendEndDate);		//방문예약 종료일(필수)
				jsonObject.put("msg", "");								//비고
				jsonObject.put("shopid", strShopID);			//상점ID(필수).
			} else {
			/** 빌리진아이 자체방식 포맷 */
				//jsonObject.put("apt_code", strSendAptCode);		// 아파트 코드(아파트 구분이 필요할 경우)
				jsonObject.put("dong", strDong);								// 방문세대 동(필수)
				jsonObject.put("ho", strHo);										// 방문세대 호(필수)
				jsonObject.put("car_number", strCarNumber);			// 등록할 차량번호(필수)
				jsonObject.put("start_date", strStartDate);			// 방문 시작일시(yyyyMMddHHmmss)(필수)
				jsonObject.put("end_date", strEndDate);				//	방문 종료일시(yyyyMMddHHmmss)(필수)
				jsonObject.put("memo", strMemo);							// 메모
			}

			return jsonObject;
		} catch (Exception ex) {
			printLog("D", "Exception : " + ex.getMessage());	
			return null;
		}
	}	
	
	/**
	 * 방문삭제 업체 송신 데이터 조립
	 */
	public JSONObject getSendDataVisitDel(String strCompanyCode, String strSendAptCode, String strSendVisitID) {
		if(strCompanyCode == null || strCompanyCode.contentEquals("")) {
			printLog("A", "getSendDataVisitDel strCompanyCode null");
			return null;
		}
		if(strSendVisitID == null || strSendVisitID.contentEquals("")) {
			printLog("A", "getSendDataVisitDel strSendVisitID null");
			return null;
		}
		
		try {
			// 업체 송수신 전문 양식대로 조립
			JSONObject jsonObject = new JSONObject();
			/** 005 : 대영아이오티 */
			if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
				jsonObject.put("vsid", strSendVisitID);		// 방문예약 고유ID(필수)
			} else {
			/** 빌리진아이 자체방식 포맷 */
				//jsonObject.put("apt_code", strSendAptCode);		// 아파트 코드(아파트 구분이 필요할 경우)	
				jsonObject.put("visit_id", strSendVisitID);		// 방문예약 고유ID(필수)
			}

			return jsonObject;
		} catch (Exception ex) {
			printLog("D", "Exception : " + ex.getMessage());	
			return null;
		}
	}
		
	/**
	 * 업체 송신(POST)
	 */
	public String callHttpPost(String strUrl, String strAuth, JSONObject jsonParam) {
		if(strUrl == null || strUrl.contentEquals("")) {
			printLog("A", "callHttpPost strUrl null");
			return "";
		}
		
		try {
			CloseableHttpClient httpclient = HttpClientBuilder.create().build();
			HttpPost httppost = new HttpPost(strUrl);
			httppost.addHeader("Content-Type", "application/json;charset=UTF-8");
			// 인증 토큰이 있으면 헤더에 세팅
			if(!strAuth.contentEquals("")) {
				httppost.addHeader("Authorization", strAuth);
			}
			printLog("D", "send Param : " + jsonParam.toJSONString());
			
			StringEntity params = new StringEntity(jsonParam.toJSONString(), "UTF-8");
			httppost.setEntity(params);
			
			//printLog("D", "receive resPost pre");	
			CloseableHttpResponse resPost = httpclient.execute(httppost);
			//printLog("D", "receive resPost");
			int nResCode = resPost.getStatusLine().getStatusCode();
			printLog("A", "receive nResCode : " + Integer.toString(nResCode));	
			String responseBody = "";
			if (resPost.getStatusLine().getStatusCode() == 200) {
				ResponseHandler<String> responseHandler = new BasicResponseHandler();
				responseBody = responseHandler.handleResponse(resPost);
			}	
			printLog("A", "receive responseBody : " + responseBody);
			
		/*	 테스트시 리턴 확인
			ResponseHandler<String> responseHandler = new BasicResponseHandler();
			String responseBody = httpclient.execute(httppost, responseHandler);
		*/	
			// 서버 접속 불가시 리턴 코드가 확인이 되는지 등 상황 확인을 하고 맞게 response 값을 주자.
			return responseBody;
		} catch (Exception ex) {
			printLog("D", "callHttpPost Exception : " + ex.getMessage());	
			return "";
		}
	}
	
	/**
	 * 업체 송신(DELETE)
	 */
	public String callHttpDelete(String strUrl, String strAuth, JSONObject jsonParam) {
		if(strUrl == null || strUrl.contentEquals("")) {
			printLog("A", "callHttpDelete strUrl null");
			return "";
		}
		
		HttpURLConnection connection = null;
		BufferedReader buffReader = null;
		try {
			URL moduleUrl = new URL(strUrl);
			connection = (HttpURLConnection) moduleUrl.openConnection();
			// DELETE 메서드 지정
			connection.setRequestMethod("DELETE");
			connection.setDoOutput(true);
			// 커넥션, read 타임아웃 각 10초 설정
			connection.setConnectTimeout(10000);
			connection.setReadTimeout(10000);
			// json 전송타입 설정
			connection.setRequestProperty("Content-Type", "application/json; utf-8");
			connection.setRequestProperty("Accept", "application/json");
			// 인증 토큰이 있으면 헤더에 세팅
			if(!strAuth.contentEquals("")) {
				connection.setRequestProperty("Authorization", strAuth);
			}
			printLog("A", "send Param : " + jsonParam.toJSONString());
			printLog("D", "send pre");	
			// JSON Body 전송
			try {
				OutputStream outStream = connection.getOutputStream();
				byte[] input = jsonParam.toString().getBytes("utf-8");
				outStream.write(input, 0, input.length);
			} catch (Exception ex) {
			}
			printLog("D", "send post");
			int nResCode = connection.getResponseCode();
			printLog("A", "*************************receive nResCode : " + Integer.toString(nResCode));	
			// 수신데이터
			String responseBody = "";
			if (nResCode == HttpURLConnection.HTTP_OK) {
				buffReader = new BufferedReader(new InputStreamReader(connection.getInputStream(), "utf-8"));
				StringBuilder resData = new StringBuilder();
				String responseLine;
				while ((responseLine = buffReader.readLine()) != null) {
					resData.append(responseLine.trim());
				}
				responseBody = resData.toString();
			}
			printLog("A", "receive responseBody : " + responseBody);
			// 버퍼리더로 읽은 json 값의 문자 처리
			responseBody = responseBody.replace("\\r\\n", "");
			responseBody = responseBody.replace("\\\"", "\"");
			printLog("A", "receive responseBody : " + responseBody);

			JSONObject responseObject = new JSONObject();
			int nIndex = responseBody.indexOf("\"result\":");
			if(-1 < nIndex) {
				int nStart = responseBody.indexOf("\"", nIndex + 9) + 1;
    			int nEnd = responseBody.indexOf("\"", nStart);
				String strValue = responseBody.substring(nStart, nEnd);
				responseObject.put("result", strValue);
			}
			responseBody = responseObject.toString();
			printLog("A", "receive responseBody : " + responseBody);
			
			if(buffReader != null) {
				buffReader.close();
			}
			connection.disconnect();

		/*	 테스트시 리턴 확인
			ResponseHandler<String> responseHandler = new BasicResponseHandler();
			String responseBody = httpclient.execute(httppost, responseHandler);
		*/	
			// 서버 접속 불가시 리턴 코드가 확인이 되는지 등 상황 확인을 하고 맞게 response 값을 주자.
			return responseBody;
		} catch (Exception e) {
			printLog("A", "callHttpDelete Exception : " + e.getMessage());	
			return "";
		} finally {
			if (buffReader != null) {
				try {
					buffReader.close();
				} catch(IOException e) {
					e.printStackTrace();
				}
			}
			if (connection != null) connection.disconnect();
		}
	}
	
	/**
	 * 주차서버 우회 송신(POST)
	 */
	public String callHttpPostAssist(String strAptCode, String strUrl, String strSendKind, JSONObject jsonParam) {
		if(strUrl == null || strUrl.contentEquals("")) {
			printLog("A", "callHttpPostAssist strUrl null");
			return "";
		}
		if(strAptCode.contentEquals("") ||strSendKind.contentEquals("")) {
			printLog("A", "callHttpPostAssist param null");
			return "";
		}

		String strAssistUrl = "http://parking.vzi.co.kr/xmobile/villizinei/parking/call_assist.jsp";
		
		try {
			CloseableHttpClient httpclient = HttpClientBuilder.create().build();
			HttpPost httppost = new HttpPost(strAssistUrl);
			httppost.addHeader("Content-Type", "application/json;charset=UTF-8");
			
			// json param 에 우회종류, 로그용 아파트코드, 호출 업체 url 추가
			jsonParam.put("assistkind", strSendKind);
			jsonParam.put("aptcode", strAptCode);
			jsonParam.put("callurl", strUrl);
			printLog("A", "callHttpPostAssist " + strSendKind + " send Param : " + jsonParam.toJSONString());
			
			StringEntity params = new StringEntity(jsonParam.toJSONString(), "UTF-8");
			httppost.setEntity(params);
			
			//printLog("D", "receive resPost pre");	
			CloseableHttpResponse resPost = httpclient.execute(httppost);
			//printLog("D", "receive resPost");
			int nResCode = resPost.getStatusLine().getStatusCode();
			printLog("A", "callHttpPostAssist " + strSendKind + " nResCode : " + Integer.toString(nResCode));	
			String responseBody = "";
			if (resPost.getStatusLine().getStatusCode() == 200) {
				ResponseHandler<String> responseHandler = new BasicResponseHandler();
				responseBody = responseHandler.handleResponse(resPost);
			}	
			printLog("A", "callHttpPostAssist " + strSendKind + " responseBody : " + responseBody);
			
		/*	 테스트시 리턴 확인
			ResponseHandler<String> responseHandler = new BasicResponseHandler();
			String responseBody = httpclient.execute(httppost, responseHandler);
		*/	
			// 서버 접속 불가시 리턴 코드가 확인이 되는지 등 상황 확인을 하고 맞게 response 값을 주자.
			return responseBody;
		} catch (Exception ex) {
			printLog("D", "callHttpPost Exception : " + ex.getMessage());	
			return "";
		}
	}
	
	/**
	 * 방문예약 업체 수신 데이터 파싱
	 */
	public HashMap<String, String> getResposeDataVisitReg(String strCompanyCode, String responseBody) {
		if(strCompanyCode == null || strCompanyCode.contentEquals("")) {
			printLog("A", "getResposeDataVisitReg strCompanyCode null");
			return null;
		}
		try {
			HashMap<String, String> mapResposeData = new HashMap();
			
			// 업체 수신 전문 양식대로 파싱해서 맵에 저장
			JSONParser parser = new JSONParser();
			JSONObject responseObject = (JSONObject)parser.parse(responseBody);

			/** 005 : 대영아이오티 */
			if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
				// 결과값 0 : 성공
				String strResult = (String)responseObject.get("result").toString();
				if(strResult.contentEquals("0")) {
					strResult = "OK";
				} else {
					strResult = "FAIL";
				}
				// 방문예약 아이디
				String strVisitID = (String)responseObject.get("vsid").toString();
				
				// 에러메세지 값은 없으므로 빈값
				mapResposeData.put("error_message", "");
				mapResposeData.put("result", strResult);		// OK : 성공, FAIL : 실패
				mapResposeData.put("data", strVisitID);

			} else {
			/** 빌리진아이 자체방식 포맷 */
				// 결과값 0 : 성공
				String strResult = (String)responseObject.get("result").toString();
				if(strResult.contentEquals("0")) {
					strResult = "OK";
				} else {
					strResult = "FAIL";
				}
				// 결과 메시지
				String strResultMsg = (String)responseObject.get("message").toString();
				// 방문예약 아이디
				String strVisitID = (String)responseObject.get("visit_id").toString();
				
				// 에러메세지 값은 없으므로 빈값
				mapResposeData.put("error_message", "");
				mapResposeData.put("result", strResult);		// OK : 성공, FAIL : 실패
				mapResposeData.put("message", strResultMsg);
				mapResposeData.put("data", strVisitID);
			}

			return mapResposeData;
		} catch (Exception ex) {
			printLog("A", "Exception : " + ex.getMessage());	
			return null;
		}
	
	}
	
	/**
	 * 방문삭제 업체 수신 데이터 파싱
	 */
	public HashMap<String, String> getResposeDataVisitDel(String strCompanyCode, String responseBody) {
		if(strCompanyCode == null || strCompanyCode.contentEquals("")) {
			printLog("A", "getResposeDataVisitDel strCompanyCode null");
			return null;
		}
		try {
			HashMap<String, String> mapResposeData = new HashMap();
			
			// 업체 수신 전문 양식대로 파싱해서 맵에 저장
			JSONParser parser = new JSONParser();
			JSONObject responseObject = (JSONObject)parser.parse(responseBody);

			/** 005 : 대영아이오티 */
			if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
				// 결과값 0 : 성공
				String strResult = (String)responseObject.get("result").toString();
				if(strResult.contentEquals("0")) {
					strResult = "OK";
				} else {
					strResult = "FAIL";
				}
				
				// 에러메세지 값은 없으므로 빈값
				mapResposeData.put("error_message", "");
				mapResposeData.put("result", strResult);		// OK : 성공, FAIL : 실패
			} else {
			/** 빌리진아이 자체방식 포맷 */
				// 결과값 0 : 성공
				String strResult = (String)responseObject.get("result").toString();
				if(strResult.contentEquals("0")) {
					strResult = "OK";
				} else {
					strResult = "FAIL";
				}
				// 결과 메시지
				String strResultMsg = (String)responseObject.get("message").toString();
				
				// 에러메세지 값은 없으므로 빈값
				mapResposeData.put("error_message", "");
				mapResposeData.put("result", strResult);		// OK : 성공, FAIL : 실패
				mapResposeData.put("message", strResultMsg);
			}

			return mapResposeData;
		} catch (Exception ex) {
			printLog("A", "Exception : " + ex.getMessage());	
			return null;
		}
	
	}

%>

<%
Connection 			conn = null;		// DB Connection Object
PreparedStatement 	pstmt = null;		// JDBC PreparedStatement Object
ResultSet 			rs = null;	 		// Query Result Set Object
ResultSetMetaData 	rsMetaData = null;

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
	printLog("D", "apt_parking_own paramJson : " + paramJson.toString());

	// Load JDBC Driver and connect to database
	Class.forName(driverClass);
	conn = DriverManager.getConnection(dbUrl, dbUserId, dbUserPasswd);
	
	// Get Parameter - SID = query 구분.
	String strSID = getJsonParam(paramJson, "SID");
	printLog("A", "apt_parking_own SID : " + strSID);
	
	if(strSID.contentEquals("select_main_parkingcompany")) {
		// ### 차량출입관리 메인화면 조회 - "select_main_parkingcompany" ###
		// Get Parameter - PostId = 글 아이디
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strDong = getJsonParam(paramJson, "Dong");
		String strHo = getJsonParam(paramJson, "Ho");
		String strStartDate = getJsonParam(paramJson, "StartDate");	// yyyyMMdd
		String strEndDate = getJsonParam(paramJson, "EndDate");		// yyyyMMdd
		
		// 일자 오류 확인
		if(strStartDate.length() != 8) {
			strStartDate = strStartDate.substring(0, 4) + "0" + strStartDate.substring(4, 7);
		}
		if(strEndDate.length() != 8) {
			strEndDate = strEndDate.substring(0, 4) + "0" + strEndDate.substring(4, 7);
		}
//printLog("A", "select_main_parkingcompany strAptCode : " + strAptCode + ", strDong : " + strDong + ", strHo : " + strHo + ", strStartDate : " + strStartDate + ", strEndDate : " + strEndDate);
		// 총 방문주차 무료시간 조회(이번달 사용량 계산)
		String strQueryFree = "";
		strQueryFree += " SELECT APT_VISIT_FREE_TIME, APT_VISIT_FREE_TIME_USECAR, APT_VISIT_FREE_TIME_NOCAR, ";
		strQueryFree += "  API_SELECT_USE_PARKING, APT_GUIDE_COMMENT ";
		strQueryFree += " FROM PARKING_COMPANY ";
		strQueryFree += " WHERE APT_CODE = '" + strAptCode + "' ";
		
		pstmt = conn.prepareStatement(strQueryFree);
		rs = pstmt.executeQuery();

		// 아파트 월 방문 할당시간, 세대 남은시간
		String strAllParkingTime = "0";
		String strUserCarTime = "0";	// 정기차량등록 세대설정값
		String strNoCarTime = "0";	// 정기차량미등록 세대설정값
		String strRemainParkingTime = "0";
		// 정기차량 등록여부 조회 url
		String strUseParkingUrl = "";
		// 아파트별 앱 부과 안내 메세지
		String strGuideComment = "";

		if(rs.next()) {
			strAllParkingTime = rs.getString(1);
			if(strAllParkingTime == null) strAllParkingTime = "0";
			strUserCarTime = rs.getString(2);
			if(strUserCarTime == null) strUserCarTime = "0";
			strNoCarTime = rs.getString(3);
			if(strNoCarTime == null) strNoCarTime = "0";
			strUseParkingUrl = rs.getString(4);
			if(strUseParkingUrl == null) strUseParkingUrl = "";
			strGuideComment = rs.getString(5);
			if(strGuideComment == null) strGuideComment = "";
		}
		
		// 세대 공통 무료시간 설정값이 0 이면 개별 설정값이 있는지 확인
		if(strAllParkingTime.contentEquals("0")) {
			// 정기차량 등록시 무료시간 설정값 있는지 확인 - 정기차량여부 조회 url 이 있고 구분무료시간중 1개라도 있어야 함.
			if((!strUserCarTime.contentEquals("0") || !strNoCarTime.contentEquals("0")) && !strUseParkingUrl.contentEquals("")) {
				// 무료시간이 개별 설정되어 있으면 해당 세대 정기차량 등록여부 조회해옴.
				// 조회된 값에 따라 해당하는 무료시간을 strAllParkingTime 에 저장
				// 주차차단기 업체 서버 호출. 업체별로 양식대로 호출하도록 구성하도록. 현재는 사용안함으로 넥스파 예시로 남겨놈
				/*JSONObject jsonObject = new JSONObject();
				jsonObject.put("dong", strDong);
				jsonObject.put("ho", strHo);
				
				String responseBody = callHttpPost(strUseParkingUrl, "", jsonObject);
				
				JSONParser parser = new JSONParser();
				JSONObject responseObject = (JSONObject)parser.parse(responseBody);
				printLog("A", "receive nexpa response : " + responseObject.toJSONString());
				String strParseResult = (String)responseObject.get("result").toString();
				// result 가 없으면 빈값 - 없나 보자
				if(!strParseResult.contentEquals("")) {
					responseObject = (JSONObject)parser.parse(strParseResult);
					
					String strParseMessage = (String)responseObject.get("message").toString();
					printLog("A", "message : " + (String)responseObject.get("message"));
					if(strParseMessage.contentEquals("OK")) {	// 정기차량:OK, 비정기차량:NO
						strAllParkingTime = strUserCarTime;
					} else {
						strAllParkingTime = strNoCarTime;
					}
				}*/
			}
		}

		// 방문내역 전체 조회해서 시간 계산. 초단위로 리턴. 방문시간 사용안하면 할필요 없음.
		if(!strAllParkingTime.contentEquals("0")) {
			// 이달의 세대 방문 입출차 시간 조회. 월내 출차된 건만 방문시간 확인이 가능함. 미출차 건은 시간 계산 안됨.
			// 차량번호, 입차시간, 출차시간 - 입차순 정렬
			String strYYYYMM = strStartDate.substring(0, 6);
			String strQueryInout = "";
			strQueryInout += " SELECT CAR_NUMBER, IN_DATE, OUT_DATE ";
			strQueryInout += " FROM PARKING_INOUT ";
			strQueryInout += " WHERE substr(OUT_DATE, 1, 6) = '" + strYYYYMM + "' ";
			strQueryInout += " AND APT_CODE = " + strAptCode + " ";
			strQueryInout += " AND DONG = " + strDong + " ";
			strQueryInout += " AND HO = " + strHo + " ";
			strQueryInout += " AND PASS_TYPE = '0' AND DATA_TYPE <> 'D' ";	// 0:방문, D:삭제
			strQueryInout += " ORDER BY CAR_NUMBER, IN_DATE ";
	
			pstmt = conn.prepareStatement(strQueryInout);
			rs = pstmt.executeQuery();

			// 주차시간 계산
			int nRemainParkingTime = 0;
			for(int nRow = 0; rs.next(); nRow++) {
				String strCarNumber = rs.getString(1);
				if(strCarNumber == null) strCarNumber = "";
				String strInDate = rs.getString(2);
				if(strInDate == null) strInDate = "";
				String strOutDate = rs.getString(3);
				if(strOutDate == null) strOutDate = "";

				String strParkingTime = "";
				String strCalcStart = strInDate;
				String strCalcEnd = strOutDate;
				// 입차일이 비었거나(미인식), 이전월이면 당월 1일 0시부터 계산(당월 무료시간 이므로)
				if(strInDate.contentEquals("") || Integer.parseInt(strInDate.substring(0,8)) < Integer.parseInt(strStartDate)) {
					strCalcStart = strYYYYMM + "01000000";
				}
				// 주차시간 계산
				if(!strCalcStart.contentEquals("") && !strCalcEnd.contentEquals("")) {
					Date dateIn = new Date(Integer.parseInt(strCalcStart.substring(0, 4)), Integer.parseInt(strCalcStart.substring(4, 6)), Integer.parseInt(strCalcStart.substring(6, 8)),
														 Integer.parseInt(strCalcStart.substring(8, 10)), Integer.parseInt(strCalcStart.substring(10, 12)), Integer.parseInt(strCalcStart.substring(12, 14)));
					Date dateOut = new Date(Integer.parseInt(strCalcEnd.substring(0, 4)), Integer.parseInt(strCalcEnd.substring(4, 6)), Integer.parseInt(strCalcEnd.substring(6, 8)),
														 Integer.parseInt(strCalcEnd.substring(8, 10)), Integer.parseInt(strCalcEnd.substring(10, 12)), Integer.parseInt(strCalcEnd.substring(12, 14)));

					nRemainParkingTime += (dateOut.getTime() - dateIn.getTime()) / 1000;
					printLog("D", strCarNumber + " - Start : " + strCalcStart + ", End : " + strCalcEnd + ", DateDiff : " + ((dateOut.getTime() - dateIn.getTime()) / 1000) );
				}
			}
			strRemainParkingTime = Long.toString(Integer.parseInt(strAllParkingTime) - nRemainParkingTime);
		} else {
			strRemainParkingTime = strAllParkingTime;
		}
		String strOverCost = "-1";	// 비용 없음 처리
printLog("A", "select_main_parkingcompany strAllParkingTime : " + strAllParkingTime + ", strRemainParkingTime : " + strRemainParkingTime);
		// 데이터 내릴 준비
		resJson.put("RESULT", "SUCCESS");
		
		JSONObject jsonData = new JSONObject();
		jsonData.put("allParkingTime", strAllParkingTime);
		jsonData.put("remainParkingTime", strRemainParkingTime);
		jsonData.put("overCost", strOverCost);
		jsonData.put("guideComment", strGuideComment);
		
		resJson.put("DATA", jsonData);
		// 데이터 조립한 후, 클라이언트로 전송..
		returnJson(response, resJson);
	} else if(strSID.contentEquals("select_inoutlist_parkingcompany")) {
		// ### 차량출입관리 입출차 내역 조회 하기 - "select_inoutlist_parkingcompany" ###
		// Get Parameter - AptCode = 아파트 코드, strDong = 동, strHo = 호, PostId - 글아이디, LimitCnt - 차량 조회될 건수
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strDong = getJsonParam(paramJson, "Dong");
		String strHo = getJsonParam(paramJson, "Ho");
		String strInOutKind = getJsonParam(paramJson, "ParikngKind");
		String strStartDate = getJsonParam(paramJson, "StartDate");	// yyyyMMdd
		String strEndDate = getJsonParam(paramJson, "EndDate");		// yyyyMMdd
		String strCarNum = getJsonParam(paramJson, "CarNumber");
		String strUserId = getJsonParam(paramJson, "UserId");
printLog("A", "select_main_parkingcompany strAptCode : " + strAptCode + ", strDong : " + strDong + ", strHo : " + strHo + ", strInOutKind : " + strInOutKind
 + ", strStartDate : " + strStartDate + ", strEndDate : " + strEndDate + ", strCarNum : " + strCarNum + ", strUserId : " + strUserId);		
		// 푸시 설정 아파트인지 확인
		String strQueryDay = "";
		strQueryDay += " SELECT USE_PUSH_INOUT ";
		strQueryDay += " FROM PARKING_COMPANY ";
		strQueryDay += " WHERE APT_CODE = '" + strAptCode + "' ";

		pstmt = conn.prepareStatement(strQueryDay);
		rs = pstmt.executeQuery();

		String strUsePushInOut = "0";	// 입출차 통보 푸시는 기본 없음
		if(rs.next()) {
			strUsePushInOut = rs.getString(1);
			if(strUsePushInOut == null) strUsePushInOut = "0";
		}
		
		// 개인 푸시 on/off 상태 조회. 기본 디비값이 사용 1, 사용안함 0
		String strPushOnOff = "1";
		// 입출차 통보 푸시 사용 안함일 경우 개인 푸시 조회 안하고 2 리턴
		if(strUsePushInOut.contentEquals("0")) {
			strPushOnOff = "2";
		} else {
			String strQueryPush = "";
			strQueryPush += " SELECT ";
			if(strInOutKind.contentEquals("VISIT")) {
				strQueryPush += " PUSH_VISIT_INOUT ";
			} else {
				strQueryPush += " PUSH_PARKING_INOUT ";
			}
			strQueryPush += " FROM USER_INFO ";
			strQueryPush += " WHERE USER_ID = '" + strUserId + "' ";
			
			pstmt = conn.prepareStatement(strQueryPush);
			rs = pstmt.executeQuery();
			
			if(rs.next()) {
				strPushOnOff = rs.getString(1);
				if(strPushOnOff == null) strPushOnOff = "1";
			}
		}

		// 기간내 방문 입출차 내역 조회
		String strYYYYMM = strStartDate.substring(0, 6);
		String strQueryInout = "";
		if(strInOutKind.contentEquals("VISIT")) {
			// 방문
			strQueryInout += " SELECT CAR_NUMBER, IN_DATE, OUT_DATE, EVENT_TYPE ";
			strQueryInout += " FROM PARKING_INOUT ";
			strQueryInout += " WHERE (substr(OUT_DATE, 1, 6) = '" + strYYYYMM + "' OR substr(IN_DATE, 1, 6) = '" + strYYYYMM + "') ";
			strQueryInout += " AND APT_CODE = " + strAptCode + " ";
			strQueryInout += " AND DONG = " + strDong + " ";
			strQueryInout += " AND HO = " + strHo + " ";
			if(!strCarNum.contentEquals("")) {
				strQueryInout += " AND CAR_NUMBER like '%" + strCarNum + "%' ";
			}
			strQueryInout += " AND PASS_TYPE = '0' AND DATA_TYPE <> 'D' ";	// 0:방문, D:삭제
			strQueryInout += " ORDER BY CAR_NUMBER, IN_DATE, EVENT_TYPE ";
		} else {
			// 세대
			strQueryInout += " SELECT CAR_NUMBER, if(EVENT_TYPE = '0', IN_DATE, '') as IN_DATE, if(EVENT_TYPE = '1', OUT_DATE, '') as OUT_DATE, '' as PARKING_TIME ";
			strQueryInout += " FROM PARKING_INOUT ";
			strQueryInout += " WHERE (substr(OUT_DATE, 1, 6) = '" + strYYYYMM + "' OR substr(IN_DATE, 1, 6) = '" + strYYYYMM + "') ";
			strQueryInout += " AND APT_CODE = " + strAptCode + " ";
			strQueryInout += " AND DONG = " + strDong + " ";
			strQueryInout += " AND HO = " + strHo + " ";
			if(!strCarNum.contentEquals("")) {
				strQueryInout += " AND CAR_NUMBER like '%" + strCarNum + "%' ";
			}
			strQueryInout += " AND PASS_TYPE = '1' AND DATA_TYPE <> 'D' ";	// 1:세대, D:삭제
			strQueryInout += " ORDER BY if(EVENT_TYPE = '0', IN_DATE, OUT_DATE) DESC ";
		}
		pstmt = conn.prepareStatement(strQueryInout);
		rs = pstmt.executeQuery();
		
		ArrayList<String> arrList = new ArrayList<String>();
		for(int nRow = 0; rs.next(); nRow++) {
			String strCarNumber = rs.getString(1);
			if(strCarNumber == null) strCarNumber = "";
			String strInDate = rs.getString(2);
			if(strInDate == null) strInDate = "";
			String strOutDate = rs.getString(3);
			if(strOutDate == null) strOutDate = "";
			String strEventType = rs.getString(4);
			if(strEventType == null) strEventType = "";

			// 방문이면 주차시간 계산해서 추가
			if(strInOutKind.contentEquals("VISIT")) {
				String strParkingTime = "";
				String strCalcStart = strInDate;
				String strCalcEnd = strOutDate;
				// 입차일이 비었거나(미인식), 이전월이면 조회월 1일 0시부터 계산(이번달 주차시간이므로 유효한 만큼만 표시)
				if(strInDate.contentEquals("") || Integer.parseInt(strInDate.substring(0,8)) < Integer.parseInt(strStartDate)) {
					strCalcStart = strYYYYMM + "01000000";
				}
				// 출차일이 비었거나(미출차), 조회종료월보다 이후면 종료일 24시까지 계산(이번달 주차시간이므로 유효한 만큼만 표시)
				if(!strOutDate.contentEquals("") && Integer.parseInt(strEndDate) < Integer.parseInt(strOutDate.substring(0,8))) {
					strCalcEnd = strEndDate + "235959";
				}
				// 주차시간 계산
				if(!strCalcStart.contentEquals("") && !strCalcEnd.contentEquals("")) {
					Date dateIn = new Date(Integer.parseInt(strCalcStart.substring(0, 4)), Integer.parseInt(strCalcStart.substring(4, 6)), Integer.parseInt(strCalcStart.substring(6, 8)),
														 Integer.parseInt(strCalcStart.substring(8, 10)), Integer.parseInt(strCalcStart.substring(10, 12)), Integer.parseInt(strCalcStart.substring(12, 14)));
					Date dateOut = new Date(Integer.parseInt(strCalcEnd.substring(0, 4)), Integer.parseInt(strCalcEnd.substring(4, 6)), Integer.parseInt(strCalcEnd.substring(6, 8)),
														 Integer.parseInt(strCalcEnd.substring(8, 10)), Integer.parseInt(strCalcEnd.substring(10, 12)), Integer.parseInt(strCalcEnd.substring(12, 14)));
	
					strParkingTime = Long.toString((dateOut.getTime() - dateIn.getTime()) / 1000);
					printLog("D", strCarNumber + " - Start : " + strCalcStart + ", End : " + strCalcEnd + ", DateDiff : " + ((dateOut.getTime() - dateIn.getTime()) / 1000) );
				}
				// 입차 기준으로 소팅하려고 맨 앞에 입차 데이터를 넣어줌
				// 입차시간 + 출차시간 + 주차시간 + 차량번호 + 입출차 구분(데이터 내릴때 사용)
				arrList.add(strInDate + "," + strOutDate + "," + strParkingTime + "," + strCarNumber + "," + strEventType);
			} else {
				// 세대차량 조회일때. 주차시간 계산 안함. 차량번호,입차,출차,주차시간. 입출차시간 역순
				arrList.add(strInDate + "," + strOutDate + ",," + strCarNumber);
			}
		}
		// array sort - desc 방문일때만. 세대는 쿼리에서 sort
		if(strInOutKind.contentEquals("VISIT")) {
			Collections.sort(arrList, Collections.reverseOrder());
		}
		// 로그 찍어봄
		for(int nCnt = 0; nCnt < arrList.size(); nCnt++) {
			printLog("D", "DESC arrList - " + arrList.get(nCnt));
		}
		// 데이터 내릴 준비
		resJson.put("RESULT", "SUCCESS");
		
		JSONObject jsonData = new JSONObject();
		// 맨앞에 푸시 on/off 상태를 넣어줌
		jsonData.put("pushState", strPushOnOff);
		JSONArray dataArr = new JSONArray();
		String strPreVisitIn = "";
		for(int nRow = 0; nRow < arrList.size(); nRow++) {
			String[] arrRetData =  arrList.get(nRow).split(",");

			JSONObject jsonItem = new JSONObject();
			if(strInOutKind.contentEquals("VISIT")) {
				// 출차면 무조건 유효. 입차면 한단계 전데이터와 입차시간이 동일하면 무효. 아니면 아웃과 주차시간은 빈칸으로 내림.
				String strRetIn = arrRetData[0];
				String strRetOut = arrRetData[1];
				String strRetTime = arrRetData[2];
				String strEvent = arrRetData[4];

				if(strEvent.contentEquals("0")) {
					if(strRetIn.contentEquals(strPreVisitIn)) {
						continue;
					} else {
						strPreVisitIn = strRetIn;
						if(strRetTime.contentEquals("0")) {
							strRetOut = "";
							strRetTime = "";
						}
					}
				} else if(strEvent.contentEquals("1")) {
					strPreVisitIn = strRetIn;
				}
						
				jsonItem.put("carNumber", arrRetData[3]);	// 차량번호
				jsonItem.put("dateIn", strRetIn);	// 입차시간
				jsonItem.put("dateOut", strRetOut);	// 출차시간
				jsonItem.put("parkingTime", strRetTime);	// 주차시간
			} else {
				jsonItem.put("carNumber", arrRetData[3]);	// 차량번호
				jsonItem.put("dateIn", arrRetData[0]);	// 입차시간
				jsonItem.put("dateOut", arrRetData[1]);	// 출차시간
				jsonItem.put("parkingTime", arrRetData[2]);	// 주차시간
			}
			dataArr.add(jsonItem);
		}
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);
		//resJson.put("ROW_COUNT", Integer.toString(arrList.size()));
		//resJson.put("COL_COUNT", "4");

		// 데이터 조립한 후, 클라이언트로 전송..
		returnJson(response, resJson);

	} else if(strSID.contentEquals("select_visitlist_parkingcompany")) {
		// ### 차량출입관리 방문 등록 리스트 조회 하기 - "select_visitlist_parkingcompany" ###
		// Get Parameter - AptCode = 아파트 코드, strDong = 동, strHo = 호
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strDong = getJsonParam(paramJson, "Dong");
		String strHo = getJsonParam(paramJson, "Ho");
		String strCarNumber = "";//"11테스트1111";
		String strStartDate = getJsonParam(paramJson, "StartDate");	// yyyyMMdd
		String strEndDate = getJsonParam(paramJson, "EndDate");		// yyyyMMdd

		// 1회 방문등록 가능일수 조회, 방문시작 지정 가능 최대일수는 나중에 사용.
		// 업체 정보와 맞아야 다른곳에서 등록되는 데이터와 문제가 안생기므로 아파트에서 빌리진아이에만 다르게 지정해도 안됨.
		String strQueryInfo = "";
		strQueryInfo += " SELECT APT_VISIT_MAX_TERM, APT_VISIT_MAX_START_DAY ";
		strQueryInfo += " FROM PARKING_COMPANY ";
		strQueryInfo += " WHERE APT_CODE = '" + strAptCode + "' ";
		
		pstmt = conn.prepareStatement(strQueryInfo);
		rs = pstmt.executeQuery();

		String strDayConutRegVisit = "3";
		String strVisitMaxStartDay = "";
		if(rs.next()) {
			strDayConutRegVisit = rs.getString(1);
			if(strDayConutRegVisit == null) strDayConutRegVisit = "";
			strVisitMaxStartDay = rs.getString(2);
			if(strVisitMaxStartDay == null) strVisitMaxStartDay = "";
		}
		
		// 자체 DB 방식. 아직 방문 기간이 남아있는 모든 데이터 조회함. 방문기간이 지났더라도 이번달 데이터는 보여줌
		String strQueryVisit = "";
		strQueryVisit += " SELECT START_DATE, END_DATE, CAR_NUMBER, VISIT_ID ";
		strQueryVisit += " FROM PARKING_VISIT ";
		strQueryVisit += " WHERE APT_CODE = '" + strAptCode + "' ";
		strQueryVisit += " AND DONG = '" + strDong + "' ";
		strQueryVisit += " AND HO = '" + strHo + "' ";
		strQueryVisit += " AND '" + strStartDate + "000000' <= END_DATE ";
		strQueryVisit += " AND (STATE is null OR STATE <> 'D') ";
		strQueryVisit += " ORDER BY DATE desc ";		// 등록 기준 역순 정렬
		
		pstmt = conn.prepareStatement(strQueryVisit);
		rs = pstmt.executeQuery();

		// 데이터 내릴 준비
		resJson.put("RESULT", "SUCCESS");
		JSONObject jsonData = new JSONObject();
		// 맨앞에 방문 등록 가능일수를 넣어줌
		jsonData.put("dayCountRegVisit", strDayConutRegVisit);
		JSONArray dataArr = new JSONArray();
		for(int nRow = 0; rs.next(); nRow++) {
			JSONObject jsonItem = new JSONObject();
			jsonItem.put("startDate", rs.getString(1));	// 시작일
			jsonItem.put("endDate", rs.getString(2));	// 종료일
			jsonItem.put("carNumber", rs.getString(3));	// 차량번호
			jsonItem.put("regDate", rs.getString(4));	// 등록아이디
				
			dataArr.add(jsonItem);
		}
		jsonData.put("list", dataArr);
		resJson.put("DATA", jsonData);

		// 데이터 조립한 후, 클라이언트로 전송..
		returnJson(response, resJson);

	} else if(strSID.contentEquals("insert_visit_parkingcompany")) {
		// ### 차량출입관리 방문예약 하기 - "insert_visit_parkingcompany" ###
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strDong = getJsonParam(paramJson, "Dong");
		String strHo = getJsonParam(paramJson, "Ho");
		String strCarNumber = getJsonParam(paramJson, "CarNumber");
		String strStartDate = getJsonParam(paramJson, "StartDate");// + "000000";
		String strEndDate = getJsonParam(paramJson, "EndDate") + "235959";
		String strMemo = "";//getJsonParam(paramJson, "Memo");	// 현재 앱에서 메모 안올림. 이후 추가 기능.
  		printLog("A", "insert_visit_parkingcompany strCarNumber : " + strCarNumber);
		
		// 업체 url 조회후 호출. 성공시 DB 인서트
		String strQueryUrl = "";
		strQueryUrl += " SELECT API_INSERT_VISIT, APT_TO_COMPANY_CODE, COMPANY_CODE ";
		strQueryUrl += " FROM PARKING_COMPANY ";
		strQueryUrl += " WHERE APT_CODE = '" + strAptCode + "' ";
		
		pstmt = conn.prepareStatement(strQueryUrl);
		rs = pstmt.executeQuery();
		
		String strCompanyCode = "";		// 업체 코드
		String strUrl = "";							// 업체 방문등록 URL
		String strCode_APTtoCOMPANY = "";	// 아파트코드에 해당하는 업체 관리 코드가 있으면 사용.
		if(rs.next()) {
			strUrl = rs.getString(1);
			if(strUrl == null) strUrl = "";
			strCode_APTtoCOMPANY = rs.getString(2);
			if(strCode_APTtoCOMPANY == null) strCode_APTtoCOMPANY = "";
			strCompanyCode = rs.getString(3);
			if(strCompanyCode == null) strCompanyCode = "";
		}
		// 업체용 호출 아파트 구분코드
		String strSendAptCode = strAptCode;
		if(!strCode_APTtoCOMPANY.contentEquals("")) {
			strSendAptCode = strCode_APTtoCOMPANY;
		}
		// 차량번호 공백 제거
		strCarNumber = strCarNumber.trim();
		strCarNumber = strCarNumber.replace(" ", "");
		
		// 호출할수 있는 주소가 있거나 업체 호출없이 DB등록만() 하는 경우
		if(!strUrl.contentEquals("") || strSendAptCode.contentEquals(NO_SEND_COMPANY)) {
			// 방문시작일이 오늘이면 현재시간 부터
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmmss");
			Date date = new Date();
			String strNowDate = dateFormat.format(date);
			if(strStartDate.contentEquals(strNowDate.substring(0, 8))) {
				strStartDate = strNowDate;
			} else {
				strStartDate = strStartDate + "000000";
			}
			// 방문등록전 중복 기간 체크. 업체에 따라 중복 등록시 별도 오류 메세지 없이 실패로 리턴 오는 경우가 있음.
			// 업체별로 중복을 세대내, 아파트 전체 로 체크 기준이 다름. 이후 작업 필요함.
			String strQueryReg = "";
			strQueryReg += " SELECT count(*) ";
			strQueryReg += " FROM PARKING_VISIT ";
			strQueryReg += " WHERE APT_CODE = '" + strAptCode + "' ";
			strQueryReg += " AND DONG = '" + strDong + "' ";
			strQueryReg += " AND HO = '" + strHo + "' ";
			strQueryReg += " AND CAR_NUMBER = '" + strCarNumber + "' ";
			strQueryReg += " AND ( ";
			strQueryReg += "  ('" + strStartDate + "' <= START_DATE AND START_DATE <= '" + strEndDate + "') ";
			strQueryReg += "  OR ('" + strStartDate + "' <= END_DATE AND END_DATE <= '" + strEndDate + "') ";
			strQueryReg += "  OR (START_DATE <= '" + strStartDate + "' AND '" + strEndDate + "' <= END_DATE) ";
			strQueryReg += " ) ";
			strQueryReg += " AND (STATE is null OR STATE <> 'D') ";

			pstmt = conn.prepareStatement(strQueryReg);
			rs = pstmt.executeQuery();
			
			String strVisitRegCount = "0";
			if(rs.next()) {
				strVisitRegCount = rs.getString(1);
				if(strVisitRegCount == null) strVisitRegCount = "0";
			}
			
			// 기간내 중복된 방문 예약건이 있으면 안됨.
			if(0 < Integer.parseInt(strVisitRegCount)) {
				// 에러메세지 로그 찍음. 나중에 리턴코드 정의
				String strErrorMsg = "기간내 중복된 방문 예약건이 있습니다.";
				printLog("A", "insert_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
				resJson.put("RESULT", "FAIL");
				resJson.put("ERRMSG", strErrorMsg);
				returnJson(response, resJson);
				return;
			}
			
			String strRet = "OK";			// 방문 예약 결과(업체 통신하지 않는 경우 기본 성공)
			String strRegVisitID = "";		// 업체 방문예약 아이디

			// 업체로 방문등록을 하지 않는 경우 송신은 필요없이 DB 처리만 해야함.
			if(!strSendAptCode.contentEquals(NO_SEND_COMPANY)) {
				// 업체 방문 등록 호출. 업체코드, 업체관리 현장코드(아파트코드), 호출URL, 동, 호, 차량번호, 방문시작, 방문종료
				// 헤더 데이터(인증 토큰)
				String strAuth = getSendDataAuth(strCompanyCode, strAptCode);
				printLog("A", "insert_visit_parkingcompany " + strAptCode + " Auth : " + strAuth);
				// 송신 데이터 조립
				JSONObject jsonSendData = getSendDataVisitReg(strCompanyCode, strSendAptCode, strDong, strHo, strCarNumber, strStartDate, strEndDate, strMemo);
				printLog("A", "insert_visit_parkingcompany " + strAptCode + " SendData : " + jsonSendData.toJSONString());
				// 업체 전송 결과.
				String responseBody = callHttpPost(strUrl, strAuth, jsonSendData);
				// http 통신결과(나중에), 전송결과, 데이터
				if(responseBody.contentEquals("")) {
					strRet = "FAIL";
					// 에러메세지 로그 찍음. 나중에 리턴코드 정의
					String strErrorMsg = "호출 결과를 받지 못했습니다.";
					printLog("A", "insert_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
				} else {
					// 수신 데이터 조립
					HashMap<String, String> mapResposeData = getResposeDataVisitReg(strCompanyCode, responseBody);
					
					if(mapResposeData == null) {
						strRet = "FAIL";
						String strErrorMsg = "response data parsing error";
						printLog("A", "insert_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
						resJson.put("RESULT", strRet);
						resJson.put("ERRMSG", strErrorMsg);
						returnJson(response, resJson);
						return;
					}
					
					// 에러메세지가 있으면 오류
					String strErrorMessage = mapResposeData.get("error_message");
					if(strErrorMessage != null && !strErrorMessage.contentEquals("")) {
						strRet = "FAIL";
						// 에러메세지 로그 찍음. 나중에 리턴코드 정의
						printLog("A", "insert_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMessage);
					} else {
						// 데이터 처리
						strRet = mapResposeData.get("result");	// OK : 성공, FAIL : 실패
						if(strRet.contentEquals("OK")) {
							strRegVisitID = mapResposeData.get("data");		// 업체 방문예약 아이디
						} else {
							strRet = "FAIL";
							// 에러메세지 로그 찍음
							String strErrorMsg = "주차 방문 예약에 실패했습니다.";
							printLog("A", "insert_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
						}
					}
				}
			}
			
			// DB 인서트
			if(strRet.contentEquals("OK")) {
				strRet = "FAIL";	// DB 실행전 실패 기본값
				
				String strQueryIns = "";
				strQueryIns += " INSERT INTO PARKING_VISIT (APT_CODE, DONG, HO, CAR_NUMBER, START_DATE, END_DATE, COMPANY_VISIT_ID, REG_USERID, REG_TYPE, DATE) ";
				strQueryIns += " VALUES ('" + strAptCode + "', '" + strDong + "', '" + strHo + "', '" + strCarNumber + "', '" + strStartDate + "', '" + strEndDate + "', "; 
				strQueryIns += "  '" + strRegVisitID + "', 'APP', '0', DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s'))";

				pstmt = conn.prepareStatement(strQueryIns);
				int nRet = pstmt.executeUpdate();
				
				printLog("A", "insert_visit_parkingcompany own_db insert strCarNumber : " + strCarNumber + ", result : " + Integer.toString(nRet));
				if(nRet == 1) {
					strRet = "OK";
				} else {
					strRet = "FAIL";
					// DB 인서트 실패시 업체 예약 삭제. 업체에 삭제이력이 남는 경우 있으므로 할지 고민중.
				}
			}
JSONArray dataArr = new JSONArray();
			// 출력할 데이터
			dataArr.add(strRet);
			resJson.put("DATA", dataArr);
			// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
			returnJson(response, resJson);
			
		}
	} else if(strSID.contentEquals("delete_visit_parkingcompany")) {
		// ### 차량출입관리 방문 삭제 하기 - "delete_visit_parkingcompany" ###
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strDong = getJsonParam(paramJson, "Dong");
		String strHo = getJsonParam(paramJson, "Ho");
		String strCarNumber = getJsonParam(paramJson, "CarNumber");
		String strVisitId = getJsonParam(paramJson, "RegDate");

		// 업체 url 조회후 있으면 호출 작업 계속
		String strQueryUrl = "";
		strQueryUrl += " SELECT API_DELETE_VISIT, APT_TO_COMPANY_CODE, COMPANY_CODE ";
		strQueryUrl += " FROM PARKING_COMPANY ";
		strQueryUrl += " WHERE APT_CODE = '" + strAptCode + "' ";
		
		pstmt = conn.prepareStatement(strQueryUrl);
		rs = pstmt.executeQuery();
		
		String strCompanyCode = "";		// 업체 코드
		String strUrl = "";							// 업체 방문삭제 URL
		String strCode_APTtoCOMPANY = "";	// 아파트코드에 해당하는 업체 관리 코드가 있으면 사용.
		if(rs.next()) {
			strUrl = rs.getString(1);
			if(strUrl == null) strUrl = "";
			strCode_APTtoCOMPANY = rs.getString(2);
			if(strCode_APTtoCOMPANY == null) strCode_APTtoCOMPANY = "";
			strCompanyCode = rs.getString(3);
			if(strCompanyCode == null) strCompanyCode = "";
		}
		// 업체용 호출 아파트 구분코드
		String strSendAptCode = strAptCode;
		if(!strCode_APTtoCOMPANY.contentEquals("")) {
			strSendAptCode = strCode_APTtoCOMPANY;
		}
			
		// 호출할수 있는 주소가 있거나 업체 호출없이 DB등록만() 하는 경우
		if(!strUrl.contentEquals("") || strSendAptCode.contentEquals(NO_SEND_COMPANY)) {
			String strRet = "OK";			// 방문 삭제 결과(업체 통신하지 않는 경우 기본 성공)
			String strSendVisitID = "";	// 업체 방문등록 아이디
			
			// 업체로 방문등록을 하지 않는 경우 송신은 필요없이 DB 처리만 해야함.
			if(!strSendAptCode.contentEquals(NO_SEND_COMPANY)) {
				// 방문 DB에서 업체 방문 아이디 조회
				String strQueryId = "";
				strQueryId += " SELECT COMPANY_VISIT_ID ";
				strQueryId += " FROM PARKING_VISIT ";
				strQueryId += " WHERE APT_CODE = '" + strAptCode + "' ";
				strQueryId += " AND VISIT_ID = '" + strVisitId + "' ";
				strQueryId += " AND (STATE is null OR STATE <> 'D') ";
				
				pstmt = conn.prepareStatement(strQueryId);
				rs = pstmt.executeQuery();

				if(rs.next()) {
					strSendVisitID = rs.getString(1);
					if(strSendVisitID == null) strSendVisitID = "";
				}
	
				if(strSendVisitID.contentEquals("")) {
					String strErrorMsg = "삭제할 방문 아이디가 없습니다.";
					printLog("A", "delete_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
					resJson.put("RESULT", "FAIL");
					resJson.put("ERRMSG", strErrorMsg);
					returnJson(response, resJson);
					return;
				}
				
				// 업체 방문 삭제 호출. 업체코드, 업체관리 현장코드(아파트코드), 호출URL, 업체 방문아이디
				// 헤더 데이터(인증 토큰)
				String strAuth = getSendDataAuth(strCompanyCode, strAptCode);
				printLog("A", "delete_visit_parkingcompany " + strAptCode + " Auth : " + strAuth);
				// 송신 데이터 조립
				JSONObject jsonSendData = getSendDataVisitDel(strCompanyCode, strSendAptCode, strSendVisitID);
				printLog("A", "delete_visit_parkingcompany " + strAptCode + " SendData : " + jsonSendData.toJSONString());
				// 업체 전송 결과.
				String responseBody = "";
				if(strCompanyCode.contentEquals(PARKING_COMPANY_DYIOT)) {
					// 005 대영IOT는 삭제시 RequestMethod 에 DELETE 방식으로 전송
					//responseBody = callHttpDelete(strUrl, strAuth, jsonSendData);
					// 운영서버 java 1.7 문제로 우회함(주차서버)
					responseBody = callHttpPostAssist(strAptCode, strUrl, "DYIOT_DELETE", jsonSendData);
				} else {
					responseBody = callHttpPost(strUrl, strAuth, jsonSendData);
				}

				// http 통신결과(나중에), 전송결과, 데이터
				if(responseBody.contentEquals("")) {
					strRet = "FAIL";
					// 에러메세지 로그 찍음. 나중에 리턴코드 정의
					String strErrorMsg = "호출 결과를 받지 못했습니다.";
					printLog("A", "delete_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
				} else {
					// 수신 데이터 조립
					HashMap<String, String> mapResposeData = getResposeDataVisitDel(strCompanyCode, responseBody);
	
					if(mapResposeData == null) {
						strRet = "FAIL";
						String strErrorMsg = "response data parsing error";
						printLog("A", "delete_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
						resJson.put("RESULT", strRet);
						resJson.put("ERRMSG", strErrorMsg);
						returnJson(response, resJson);
						return;
					}
					String strErrorMessage = mapResposeData.get("error_message");
					// 에러메세지가 있으면 오류
					if(strErrorMessage != null && !strErrorMessage.contentEquals("")) {
						strRet = "FAIL";
						// 에러메세지 로그 찍음. 나중에 리턴코드 정의
						printLog("A", "delete_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMessage);
					} else {
						// 데이터 처리
						strRet = mapResposeData.get("result");	// OK : 성공, FAIL : 실패
						if(!strRet.contentEquals("OK")) {
							strRet = "FAIL";
							// 에러메세지 로그 찍음
							String strErrorMsg = "주차 방문예약 취소에 실패했습니다.";
							printLog("A", "delete_visit_parkingcompany " + strCarNumber + " errorMessage - " + strErrorMsg);
						}
					}
				}		
			}			
			if(strRet.contentEquals("OK")) {
				strRet = "FAIL";	// DB 실행전 실패 기본값
				
				// DB 삭제 플래그 업데이트
				String strQueryUp = "";
				strQueryUp += " UPDATE PARKING_VISIT SET ";
				strQueryUp += " STATE = 'D', "; 
				strQueryUp += " REG_TYPE = '0', "; 
				strQueryUp += " MODIFY_USER_ID = 'APP', ";
				strQueryUp += " MODIFY_DATE = DATE_FORMAT(SYSDATE(), '%Y%m%d%H%i%s') ";
				strQueryUp += " WHERE VISIT_ID = '" + strVisitId + "' ";
				if(!strSendAptCode.contentEquals(NO_SEND_COMPANY)) {
					strQueryUp += " AND COMPANY_VISIT_ID = '" + strSendVisitID + "' ";
				}

				pstmt = conn.prepareStatement(strQueryUp);
				int nRet = pstmt.executeUpdate();
				
				printLog("A", "delete_visit_parkingcompany own_db delete strCarNumber : " + strCarNumber + ", result : " + Integer.toString(nRet));
				if(nRet == 1) {
					strRet = "OK";
				} else {
					strRet = "FAIL";
					// DB 업데이트 실패시?
				}
			}
JSONArray dataArr = new JSONArray();
			// 출력할 데이터
			dataArr.add(strRet);
			resJson.put("DATA", dataArr);
			// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
			returnJson(response, resJson);
		}
	}
	
} catch(Exception e) {
	resJson.put("RESULT", "FAIL");
	resJson.put("ERRMSG", e.getMessage());
	// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
	returnJson(response, resJson);
}
finally {
	// Release a database resources
	if(rs != null) { try { rs.close(); } catch(Exception ignore) {} }
	if(pstmt != null) { try { pstmt.close(); } catch(Exception ignore) {} }	
	if(conn != null) { try { conn.close(); } catch(Exception ignore) {} }			
}
%>
