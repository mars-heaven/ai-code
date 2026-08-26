<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.ResultSetMetaData" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.security.NoSuchAlgorithmException" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.UUID" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<%@ page import="villizine.util.IssacWeb" %>
<%@ include file="./apt_global.jsp" %>

<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.sql.SQLException" %>

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

	static class ResidentMemberInfo {
		
		String strName;
		String strMemberKindName;
		String strUserPhone;

		ResidentMemberInfo(String strName, String strMemberkindName, String strUserPhone) {
			this.strName = strName;
			this.strMemberKindName = strMemberkindName;
			this.strUserPhone = strUserPhone;
		}
	}

%>

<%	
Connection 			conn = null;
PreparedStatement 	pstmt = null;
ResultSet 			rs = null;

final String TAG = "apt_userinfo.jsp ";

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
	printLog("D", "apt_userinfo paramJson : " + paramJson.toString());

	// Load JDBC Driver and connect to database
	Class.forName(driverClass);
	conn = DriverManager.getConnection(dbUrl, dbUserId, dbUserPasswd);

	// Get Parameter - SID = query 구분.
	String strSID = getJsonParam(paramJson, "SID");
	printLog("A", TAG + "SID : " + strSID);
	
	if(strSID.contentEquals("select_household")) {
		// =========================================================
		// 같은 세대원 조회
		// =========================================================
		String strUserID = getJsonParam(paramJson, "UserId");
		String strAptCode = getJsonParam(paramJson, "AptCode");
		String strUserName = getJsonParam(paramJson, "UserName");
		String strUserDong = getJsonParam(paramJson, "UserDong");
		String strUserHo = getJsonParam(paramJson, "UserHo");	

		// =========================================================
		// 요청 파라미터 null 방어 처리
		// =========================================================
		if(strUserID == null){ strUserID = ""; }	
		if(strAptCode == null){ strAptCode = ""; }
		if(strUserName == null){ strUserName = ""; }
		if(strUserDong == null){ strUserDong = ""; }
		if(strUserHo == null){ strUserHo = ""; }

		// =========================================================
		// 0. 필수 파라미터 검증
		// ✅ UserId, AptCode는 사용자 식별 및 아파트 구분에 반드시 필요한 값이므로 필수로 검증한다.
		// =========================================================
        String strErrorMessage = "";

        if(strUserID.trim().equals("")) {
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
			strUserGradeQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strUserGradeQuery += " AND USER_ID = '" + strUserID + "' ";

			pstmt = conn.prepareStatement(strUserGradeQuery);
			rs = pstmt.executeQuery(strUserGradeQuery);

			if(rs.next() && USER_GRADE_RESIDENT.contentEquals(rs.getString("USER_GRADE"))) {
				if(strUserName.trim().equals("")) {
					strErrorMessage = "등록된 이름이 없습니다. 관리사무소 또는 고객센터에 문의해주세요";
				} else if(strUserDong.trim().equals("") || strUserHo.trim().equals("")) {
					strErrorMessage = "등록된 아파트 동/호 정보가 없습니다. 관리사무소 또는 고객센터에 문의해주세요";
				}
			}
		}

		// 에러 실행
        if(!strErrorMessage.equals("")) {
            ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

            baOutStream.write("0".getBytes(S_CHARSET)); // 조회 성공 여부
            baOutStream.write(COLUMN_DEL);

            baOutStream.write(strErrorMessage.getBytes(S_CHARSET)); // 에러 메시지
            baOutStream.write(COLUMN_DEL);

            // 기존 필드 빈값 처리
            baOutStream.write("".getBytes(S_CHARSET)); // 이름
            baOutStream.write(COLUMN_DEL);

            baOutStream.write("0".getBytes(S_CHARSET)); // 얼굴 등록 여부
            baOutStream.write(COLUMN_DEL);

            baOutStream.write("".getBytes(S_CHARSET)); // 전화번호
            baOutStream.write(COLUMN_DEL);

            baOutStream.write("0".getBytes(S_CHARSET)); // 성별
            baOutStream.write(COLUMN_DEL);

            baOutStream.write("".getBytes(S_CHARSET)); // UUID
            baOutStream.write(COLUMN_DEL);

            baOutStream.write("".getBytes(S_CHARSET)); // 이미지 URL
            baOutStream.write(COLUMN_DEL);

            baOutStream.write(RECORD_DEL);

            returnData(m_issacweb, baOutStream, outStream);
            return;
        }

		// =========================================================
		// - ✅ 현재 사용자 ✅
		// =========================================================

		// =========================================================
		// 1. 현재 사용자 이름 세팅
		// - 이름은 요청 파라미터 UserName 값을 그대로 사용
		// =========================================================

		// =========================================================
		// 2. 현재 사용자 사진 등록 여부 조회
		// - APT_COMMUNITY_USER_INFO에서 사진이 등록되어 있는지 조회
		// - EXPIRATION_DATE가 있고, IMAGE_URL이 비어있지 않은 데이터만 사진 등록으로 판단
		// =========================================================
		String strPhotoQuery = "";
		// strPhotoQuery += "SELECT COUNT(*) ";
		strPhotoQuery += " SELECT EXISTS ( ";
		strPhotoQuery += "   SELECT 1 ";
		strPhotoQuery += " FROM APT_COMMUNITY_USER_INFO ";
		strPhotoQuery += " WHERE APT_CODE = " + strAptCode + " ";

		// ✅ 관리사무소(5)/시스템관리자(6)/커뮤니티센터 관리자(8) 등급은 동/호/이름이 없으니 UserId 기반으로 조회를 하고 
		// ✅ 입주민(3)일 경우에는 동/호/이름이 없으면 안되기에 이름+동+호 모두 일치하는 경우로 조회를 한다

		// ✅ 등급과 상관없이 동/호/이름이 있으면 동/호/이름 기준으로 먼저 조회
		if(!strUserDong.trim().equals("") 
			&& !strUserHo.trim().equals("") 
			&& !strUserName.trim().equals("")) {

			strPhotoQuery += " AND DONG = '" + strUserDong + "' ";
			strPhotoQuery += " AND HO = '" + strUserHo + "' ";
			strPhotoQuery += " AND NAME = '" + strUserName + "' ";
		}
		// ✅ 동/호/이름이 없을 때만 USER_ID 기준으로 조회
		else if(!strUserID.trim().equals("")) {
			strPhotoQuery += " AND USER_ID = '" + strUserID + "' ";

			// 관리자처럼 동/호/이름 없는 데이터만 조회
			strPhotoQuery += " AND (DONG IS NULL OR DONG = '') ";
			strPhotoQuery += " AND (HO IS NULL OR HO = '') ";
			strPhotoQuery += " AND (NAME IS NULL OR NAME = '') ";
		}
		// ✅ 둘 다 아니면 조회 막기
		else {
			strPhotoQuery += " AND 1 = 0 ";
		}

		// case 1) USER_ID가 존재하고, 이름/동/호가 비어있는 데이터 중 USER_ID가 일치하는 경우
		// strPhotoQuery += "      ( ";
		// strPhotoQuery += "        USER_ID IS NOT NULL AND USER_ID != '' ";
		// strPhotoQuery += "    AND (NAME IS NULL OR NAME = '') ";
		// strPhotoQuery += "    AND (DONG IS NULL OR DONG = '') ";
		// strPhotoQuery += "    AND (HO IS NULL OR HO = '') ";
		// strPhotoQuery += "    AND USER_ID = '" + strUserID + "' ";
		// strPhotoQuery += "      ) ";

	    // case 2) 이름 + 동 + 호가 모두 일치하는 경우
		// strPhotoQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strUserDong + "' AND HO = '" + strUserHo + "' ) ";

		// case 3) 이름만 일치하고 동/호가 비어있는 경우
		// strPhotoQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";

		// strPhotoQuery += "  ) ";        	
		// strPhotoQuery += " AND EXPIRATION_DATE IS NOT NULL "; // 🚨🚨🚨 
		strPhotoQuery += " AND IMAGE_URL != '' ";
		strPhotoQuery += " AND IMAGE_URL IS NOT NULL ";
		strPhotoQuery += " ) AS IS_EXIST ";

		printLog("D", " strPhotoQuery : " + strPhotoQuery);

		PreparedStatement pstmtPhoto = conn.prepareStatement(strPhotoQuery);
		rs = pstmtPhoto.executeQuery();

		String strPhotoExists = "0";
		// 사진 등록 여부
		if(rs.next()){
			strPhotoExists = rs.getString(1);
		}

		// =========================================================
		// 3. USER_INFO에서 현재 사용자 전화번호 조회
		// =========================================================
		String strUserInfoQuery = "";
		strUserInfoQuery += " SELECT USER_PHONE ";
		strUserInfoQuery += " FROM USER_INFO ";
		strUserInfoQuery += " WHERE USER_ID = '" +strUserID  + "' ";
		strUserInfoQuery += " AND APT_CODE = " + strAptCode + " ";

		pstmt = conn.prepareStatement(strUserInfoQuery);			
		rs = pstmt.executeQuery();

		// 본인 정보 기본값 세팅
		String strPhone = "";

		// USER_INFO에 전화번호가 있으면 세팅
		if(rs.next()){
			strPhone = rs.getString(1) != null ? rs.getString(1).trim() : "";
		}

		// =========================================================
		// 4. 현재 사용자 성별 / UUID / 이미지 URL 조회
		// =========================================================
		String strGenderCountQuery = "";
		strGenderCountQuery = "";
		strGenderCountQuery += "SELECT GENDER, "; // 성별
		strGenderCountQuery += " UUID, "; // UUID
		strGenderCountQuery += " IMAGE_URL "; // 이미지 URL
		strGenderCountQuery += " FROM APT_COMMUNITY_USER_INFO ";
		// strGenderCountQuery += " WHERE 1 = 1";
		strGenderCountQuery += " WHERE APT_CODE = " + strAptCode + " ";

		// ✅ 관리사무소(5)/시스템관리자(6)/커뮤니티센터 관리자(8) 등급은 동/호/이름이 없으니 UserId 기반으로 조회를 하고 
		// ✅ 입주민(3)일 경우에는 동/호/이름이 없으면 안되기에 이름+동+호 모두 일치하는 경우로 조회를 한다

		// ✅ 등급과 상관없이 동/호/이름이 있으면 동/호/이름 기준으로 먼저 조회
		if(!strUserDong.trim().equals("") 
			&& !strUserHo.trim().equals("") 
			&& !strUserName.trim().equals("")) {

			strGenderCountQuery += " AND DONG = '" + strUserDong + "' ";
			strGenderCountQuery += " AND HO = '" + strUserHo + "' ";
			strGenderCountQuery += " AND NAME = '" + strUserName + "' ";
		}
		// ✅ 동/호/이름이 없을 때만 USER_ID 기준으로 조회
		else if(!strUserID.trim().equals("")) {
			strGenderCountQuery += " AND USER_ID = '" + strUserID + "' ";

			// 관리자처럼 동/호/이름 없는 데이터만 조회
			// strGenderCountQuery += " AND (DONG IS NULL OR DONG = '') ";
			// strGenderCountQuery += " AND (HO IS NULL OR HO = '') ";
			// strGenderCountQuery += " AND (NAME IS NULL OR NAME = '') ";
		}
		// ✅ 둘 다 아니면 조회 막기
		else {
			strGenderCountQuery += " AND 1 = 0 ";
		}

		// strGenderCountQuery += "  AND ( ";
		
		// case 1) USER_ID 기준 매칭
		// strGenderCountQuery += "        ( (USER_ID IS NOT NULL AND USER_ID != '') AND (NAME IS NULL OR NAME = '') AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') AND USER_ID = '" + strUserID + "' ) ";
		
		// case 2) 이름 + 동 + 호 기준 매칭 // 🚨🚨🚨 이름/동/호가 비어있다면?
		// strGenderCountQuery += "     OR ( NAME = '" + strUserName + "' AND DONG = '" + strUserDong + "' AND HO = '" + strUserHo + "' ) ";

		// case 3) 이름만 기준 매칭
		// strGenderCountQuery += "     OR ( NAME = '" + strUserName + "' AND (DONG IS NULL OR DONG = '') AND (HO IS NULL OR HO = '') ) ";

		// strGenderCountQuery += "  ) ";

		pstmt = conn.prepareStatement(strGenderCountQuery);	
		rs = pstmt.executeQuery();

		// 본인 정보 기본값 세팅
		String strGender = "0";
		String strUUID = "";
		String strImageURL = "";

		// APT_COMMUNITY_USER_INFO에 정보가 있으면 성별 / UUID / 이미지 URL 세팅
		if(rs.next()){
			strGender = rs.getString(1) != null ? rs.getString(1).trim() : "0";
			strUUID = rs.getString(2) != null ? rs.getString(2).trim() : "";
			strImageURL = rs.getString(3) != null ? rs.getString(3).trim() : "";
		}

		// =========================================================
		// 4. APT_COMMUNITY_USER_INFO에서 성별을 못 가져온 경우
		//    RESIDENT_MEMBER_INFO에서 성별 재조회
		// =========================================================
		if(strGender.contentEquals("0")){
			strGenderCountQuery = "";
			strGenderCountQuery += "SELECT GENDER ";
			strGenderCountQuery += " FROM RESIDENT_MEMBER_INFO ";
			// strGenderCountQuery += " WHERE 1 = 1";
			strGenderCountQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strGenderCountQuery += " AND DONG = '" + strUserDong + "' ";
			strGenderCountQuery += " AND HO = '" + strUserHo + "' ";
			strGenderCountQuery += " AND NAME = '" + strUserName + "' ";

			pstmt = conn.prepareStatement(strGenderCountQuery);
			rs = pstmt.executeQuery();

			if(rs.next()){
				strGender = rs.getString(1) != null ? rs.getString(1).trim() : "0";
			}
		}

		// =========================================================
		// 5. 응답 데이터 생성 시작
		// - 첫 번째 레코드는 현재 사용자 본인 정보
		// - 응답 순서:
		//   조회 성공 여부 / 에러 메시지 / 이름 / 얼굴 등록 여부 / 전화번호 / 성별 / UUID / 이미지URL
		// =========================================================
		ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();

		baOutStream.write("1".getBytes(S_CHARSET)); // 조회 성공 여부
		baOutStream.write(COLUMN_DEL);

		baOutStream.write("".getBytes(S_CHARSET)); // 에러 메시지
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strUserName.getBytes(S_CHARSET)); // 이름
		baOutStream.write(COLUMN_DEL);			

		baOutStream.write(strPhotoExists.getBytes(S_CHARSET)); // 얼굴 등록 여부
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strPhone.getBytes(S_CHARSET)); // 전화번호
		baOutStream.write(COLUMN_DEL);

		baOutStream.write(strGender.getBytes(S_CHARSET)); // 성별
		baOutStream.write(COLUMN_DEL);	

		baOutStream.write(strUUID.getBytes(S_CHARSET)); // UUID
		baOutStream.write(COLUMN_DEL);		

		baOutStream.write(strImageURL.getBytes(S_CHARSET)); // 이미지URL
		baOutStream.write(COLUMN_DEL);		

		baOutStream.write(RECORD_DEL);

		// =========================================================
		// - ✅✅✅ 세대원 목록 ✅✅✅
		// =========================================================

		// =========================================================
		// 6. RESIDENT_MEMBER_INFO에서 같은 동/호 세대원 목록 조회
		// - 현재 사용자 본인은 제외하고 세대원 목록에 추가
		// =========================================================
		String strQuery = "";
		strQuery += "SELECT NAME, "; // 이름
		strQuery += " MEMBER_KIND_NAME, "; // 🚨🚨🚨 MEMBER_KIND_NAME 으로 적용하는 곳이 없으니 삭제 무방?
		strQuery += " PHONE "; // 전화번호
		strQuery += " FROM RESIDENT_MEMBER_INFO ";
		strQuery += " WHERE APT_CODE = " + strAptCode + " ";
		strQuery += " AND DONG = '" + strUserDong + "' ";
		strQuery += " AND HO = '" + strUserHo + "' ";
		
		pstmt = conn.prepareStatement(strQuery);
		rs = pstmt.executeQuery();
		rsMetaData = rs.getMetaData();

		printLog("D","strQuery : " + strQuery);
		
		List<ResidentMemberInfo> residentMemberInfos = new ArrayList<ResidentMemberInfo>();

		for(int nRow = 0; rs.next(); nRow++) {
			String strName =  rs.getString(1) != null ? rs.getString(1) : "";
			String strMemberKindName = rs.getString(2) != null ? rs.getString(2) : "";		
			strPhone = rs.getString(3) != null ? rs.getString(3) : "";

			// 이름이 비어있지 않고, 현재 사용자 이름과 다르면 세대원 목록에 추가
			// 🚨🚨🚨 RESIDENT_MEMBER_INFO 테이블에 이름이 비어져있는 사람들이 많음 -> ok
			// ResidentMemberInfo에서 kindname을 쓰고있는지 확인해보기 
			if(!strName.contentEquals("") && !strName.contentEquals(strUserName)){
				residentMemberInfos.add(new ResidentMemberInfo(strName, strMemberKindName, strPhone));
			}
		}
		
		// =========================================================
		// 7. 세대원별 사진 등록 여부 / 성별 / UUID / 이미지 URL 조회 후 응답 추가
		// =========================================================
		for(ResidentMemberInfo residentMemberInfo : residentMemberInfos){
			// -----------------------------------------------------
			// 7-1. 세대원 사진 등록 여부 조회
			// -----------------------------------------------------
			strPhotoQuery = "";
			strPhotoQuery += " SELECT EXISTS ( ";
			strPhotoQuery += "   SELECT 1 ";
			strPhotoQuery += " FROM APT_COMMUNITY_USER_INFO ";
			strPhotoQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strPhotoQuery += " AND DONG = '" + strUserDong + "' ";
			strPhotoQuery += " AND HO = '" + strUserHo + "' ";
			strPhotoQuery += " AND NAME = '" + residentMemberInfo.strName + "' ";
			// strPhotoQuery += " AND EXPIRATION_DATE IS NOT NULL ";	
			strPhotoQuery += " AND IMAGE_URL != '' AND IMAGE_URL IS NOT NULL ";	
			strPhotoQuery += " ) AS IS_EXIST ";

			pstmtPhoto = conn.prepareStatement(strPhotoQuery);
			// pstmtPhoto.setString(1, strAptCode);
			// pstmtPhoto.setString(2, strUserDong);
			// pstmtPhoto.setString(3, strUserHo); 
			// pstmtPhoto.setString(4, residentMemberInfo.strName); 
			rs = pstmtPhoto.executeQuery();

			strPhotoExists = "0";
			if(rs.next()){
				strPhotoExists = rs.getString(1);
			}
		
			// -----------------------------------------------------
			// 7-2. 세대원 성별 / UUID / 이미지 URL 조회
			// -----------------------------------------------------
			strGenderCountQuery = "";
			strGenderCountQuery += "SELECT GENDER, "; // 성별
			strGenderCountQuery += " UUID, "; // UUID
			strGenderCountQuery += " IMAGE_URL "; // 이미지 URL
			strGenderCountQuery += " FROM APT_COMMUNITY_USER_INFO ";
			// strGenderCountQuery += " WHERE 1 = 1";
			strGenderCountQuery += " WHERE APT_CODE = " + strAptCode + " ";
			strGenderCountQuery += " AND DONG = '" + strUserDong + "' ";
			strGenderCountQuery += " AND HO = '" + strUserHo + "' ";
			strGenderCountQuery += " AND NAME = '" + residentMemberInfo.strName + "' ";

			pstmt = conn.prepareStatement(strGenderCountQuery);
			// pstmt.setString(1, strAptCode);
			// pstmt.setString(2, strUserDong);
			// pstmt.setString(3, strUserHo); 
			// pstmt.setString(4, residentMemberInfo.strName); 
			rs = pstmt.executeQuery();
			
			// 세대원 정보 기본값 초기화
			strGender = "0";
			strUUID = "";
			strImageURL = "";

			if(rs.next()){
				strGender = rs.getString(1) != null ? rs.getString(1) : "0";
				strUUID = rs.getString(2) != null ? rs.getString(2) : "0";
				strImageURL = rs.getString(3) != null ? rs.getString(3) : "";
			}							
			
			// -----------------------------------------------------
			// 7-3. APT_COMMUNITY_USER_INFO에서 성별이 없으면
			//      RESIDENT_MEMBER_INFO에서 세대원 성별 재조회
			// -----------------------------------------------------
			if(strGender.contentEquals("0")){
				strGenderCountQuery = "";
				strGenderCountQuery += "SELECT GENDER ";
				strGenderCountQuery += " FROM RESIDENT_MEMBER_INFO ";
				strGenderCountQuery += " WHERE 1 = 1";
				strGenderCountQuery += " AND APT_CODE = ?";
				strGenderCountQuery += " AND DONG = ? ";
				strGenderCountQuery += " AND HO = ? ";
				strGenderCountQuery += " AND NAME = ? ";

				pstmt = conn.prepareStatement(strGenderCountQuery);
				pstmt.setString(1, strAptCode);
				pstmt.setString(2, strUserDong);
				pstmt.setString(3, strUserHo); 
				pstmt.setString(4, residentMemberInfo.strName); 
				rs = pstmt.executeQuery();

				if(rs.next()){
					strGender = rs.getString(1) != null ? rs.getString(1) : "0";
				}
			}
			
			// -----------------------------------------------------
			// 7-4. 세대원 응답 데이터 추가
			// 응답 순서:
			// 이름 / 사진등록건수 / 전화번호 / 성별 / UUID / 이미지URL
			// -----------------------------------------------------
			baOutStream.write("1".getBytes(S_CHARSET)); // 성공 여부
			baOutStream.write(COLUMN_DEL);

			baOutStream.write("".getBytes(S_CHARSET)); // 에러 메시지
			baOutStream.write(COLUMN_DEL);

			baOutStream.write(residentMemberInfo.strName.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);							
			baOutStream.write(strPhotoExists.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(residentMemberInfo.strUserPhone.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strGender.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);
			baOutStream.write(strUUID.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);						
			baOutStream.write(strImageURL.getBytes(S_CHARSET));
			baOutStream.write(COLUMN_DEL);	
			baOutStream.write(RECORD_DEL);							
			}

			// =========================================================
			// 8. 최종 응답 반환
			// =========================================================
			returnData(m_issacweb, baOutStream, outStream);

		}
	}
} catch(Exception e) {
	// 출력할 데이터
	ByteArrayOutputStream baOutStream = new ByteArrayOutputStream();
	String errMsg = "Exception Msg = " + e.getMessage();
	baOutStream.write(errMsg.getBytes(S_CHARSET));
	// 빌리진아이 포맷에 맞게 데이터 조립한 후, 클라이언트로 전송..
	returnData(m_issacweb, baOutStream, outStream);
}
finally {
	// Release a database resources
	try { 
		if(rs != null) {
			rs.close(); 
		}
		if(pstmt != null) { 
			pstmt.close(); 
		}
		if(conn != null) {
			conn.close(); 
		}			
	} catch(Exception ignore) {}
}

%>