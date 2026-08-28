<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Date" %>
<%@ page import="java.text.*" %>
<%@ page import="javax.naming.Context" %>
<%@ page import="javax.naming.InitialContext" %>
<%@ page import="javax.sql.DataSource" %>
<%@ page import="java.sql.Connection" %>

<%!

	/*
	***** 운영 global jsp *****
	global jsp 에는 고정 변수값만 사용
	*/

	// CHARSET
	final String S_CHARSET = "UTF-8";
	
	// 통신 딜리미터
	final byte RCOUNT_DEL		= 0x1B;		// 카운트
	final byte RECORD_DEL		= 0x1A;		// 레코드
	final byte COLUMN_DEL		= 0x1C;		// 컬럼
	
	final byte AD_COL_DEL 		= 0x1F;		// 광고 컬럼 구분자
	final byte AD_ROW_DEL 		= 0x1E;		// 광고 레코드 구분자
	
	final byte COUPON_COL_DEL 	= 0x2A;		// 쿠폰 컬럼 구분자
	final byte COUPON_ROW_DEL 	= 0x2B;		// 쿠폰 레코드 구분자
	
		
	final byte SECOND_COL_DEL 	= 0x2A;		// 쿠폰 컬럼 구분자
	final byte SECOND_ROW_DEL 	= 0x2B;		// 쿠폰 레코드 구분자
	
	// For MySQL
	final String driverClass 	= "com.mysql.jdbc.Driver";
	final String dbUrl 			= "jdbc:mysql://183.111.159.197:3306/villizine";
	final String dbUserId 		= "xmobile";
	final String dbUserPasswd 	= "thqp0615";
	
	// 커넥션풀
	public static Connection getDSConnection() {
		Connection conn = null;
		
		try {
			Context context = new InitialContext();
			DataSource dataSource = (DataSource)context.lookup("java:comp/env/jdbc/mysql");
			conn = dataSource.getConnection();
		} catch(Exception e) {
			e.printStackTrace();
		}
		
		return conn;
	}
	
	// System.out.println Mode : A - ALL, D - 개발서버만
	public void printLog(String strMode, String strLog) {
		if(strMode == null || strMode.contentEquals("") || strMode.contentEquals("D")) {
			return;
		}
		java.text.SimpleDateFormat formatter = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String strDate = formatter.format(new java.util.Date());

		System.out.println("[" + strDate + "] " + strLog);
	}
	
	// System.out.println Mode : A - ALL, D - 개발서버만 - static 함수내 로그 프린트용
	public static void printSLog(String strMode, String strLog) {
		if(strMode == null || strMode.contentEquals("") || strMode.contentEquals("D")) {
			return;
		}
		java.text.SimpleDateFormat formatter = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		String strDate = formatter.format(new java.util.Date());

		System.out.println("[" + strDate + "] " + strLog);
	}
	
	// 개발서버 여부 - 운영서버임. 암호화 제거중 임시로 개발서버로 처리.
	public boolean isDev() {
		return true;
	}
	
	public String getTextStyle(String strColor, String strFontWeight, String strFontStyle){
		if(strColor != null && strFontWeight != null && strFontStyle != null){
			String strCombination = "";
			strCombination = strColor + SECOND_COL_DEL + strFontWeight + SECOND_COL_DEL + strFontStyle;
			return strCombination;
		}else{
			return "null";
		}
	}
	
	public String getDateFormatYYYYMMDDHHSS(String strDate) {
    try {
        // 입력된 strDate가 yyyyMMddHHmmss 형식인지 확인하고 Date 객체로 파싱합니다.
        java.text.SimpleDateFormat inputFormatter = new java.text.SimpleDateFormat("yyyyMMddHHmmss");
        java.util.Date date = inputFormatter.parse(strDate);

        // 변환된 Date 객체를 새로운 형식으로 포매팅합니다.
        java.text.SimpleDateFormat outputFormatter = new java.text.SimpleDateFormat("yyyy.MM.dd HH:mm");
        return outputFormatter.format(date);
    } catch (java.text.ParseException e) {
        // 파싱 오류가 발생한 경우 오류 메시지를 반환하거나 다른 처리를 할 수 있습니다.
        return "Invalid date format";
    }
	}
	
	public String getPricePattern(String strPrice){
        String strPricePattern = "";
        DecimalFormat decimalFormat = new DecimalFormat("#,###");
        try {
            // 숫자만 추출하여 파싱
            Long longValue;
            if (strPrice.contains(",")) {
                strPrice = strPrice.replaceAll(",", "");
            }
            longValue = Long.parseLong(strPrice);

            // 콤마 패턴 적용
            strPricePattern = decimalFormat.format(longValue) + "원";

        } catch(NumberFormatException e){
            strPricePattern = "";
        }
        return strPricePattern;
    }
	
	// 개발자 아이디 - 고객센터 박혜림 jangnanii@naver.com 강래아 s10270415@gmail.com
	final String DEV_USER_ID = "'nyp', 'hsyu', 'shk1', 'jangnanii@naver.com', 's10270415@gmail.com'";
	
	/* bootpay 운영용 senbox Application ID(REST API 키), Private Key */
	final String BOOTPAY_APPLICATION_ID = "64005dd53049c8001a365dd8";
	final String BOOTPAY_PRIVATE_KEY = "YiQm851b7L3JGmmxHAFVgpdFsihdEr3JV/ifgMTh9gw=";

	/* 부트페이 결제 상태값 */
	final String PAY_PURCHASE					= "1";	// 결제완료
	final String PAY_CANCEL						= "20";	// 결제취소

	/* 정기 결제 주문 상태 */
	final String SUBSCRIPTION_ING				= "0";	// 정기결제중
	final String SUBSCRIPTION_RESERVE_CANCEL	= "1";	// 다음결제부터취소
	final String SUBSCRIPTION_NOW_CANCEL		= "2";	// 즉시취소
	
	/* 우회 서버 IP(bootpay, community, partner) */
	final String ASSIST_SERVER = "http://146.56.179.38/xmobile/villizinei/realpay/";	// google - 35.212.211.73:8000 / oracle(1g) - 134.185.113.98:8080 / oracle(load balancer) - 146.56.179.38
	
	/* 메뉴 아이디 */
	final String MENUID_SYSNOTICE					= "97";	// 시스템 공지사항
	final String MENUID_SMARTDOOR					= "63";	// 스마트도어
	final String MENUID_NOTICE 						= "01";	// 아파트소식
	final String MENUID_LIVING_POST 				= "05"; // 생활의 플러스
	final String MENUID_MARKET						= "04";	// 벼룩시장
	final String MENUID_NEIGHBORHOOD				= "07";	// 이웃끼리 도란도란
	final String MENUID_DOGBEAUTYCARE				= "81"; // 반려견 방문미용
	final String MENUID_PETCARE						= "42"; // 반려견•묘 돌봄(페팸)
	final String MENUID_LAUNDRY						= "41";	// 세탁물 수거 배달(세탁왕김탈수)
	final String MENUID_SHOPPINGMALL				= "89"; // 입주민혜택몰
	final String MENUID_PLACE						= "10";	// 우리동네플레이스
	final String MENUID_RECL						= "44"; // 헌옷수거(리클)
	final String MENUID_HOUSEREPAIR					= "45";	// 집수리
	final String MENUID_FURNITURECARE				= "46"; // 가구케어
	final String MENUID_PLUMBINGCARE				= "47"; // 배관케어
	final String MENUID_HOUSECLEANING 				= "48"; // 입거주청소
	final String MENUID_CARWASH						= "43"; // 방문 세차
	final String MENUID_FURNITUREREPAIR				= "51"; // 가구수리

	/* 빌리진아이 사용자 등급 */
	final String USER_GRADE_GUEST				= "1"; // 게스트 - 회원가입 이후 아파트 및 입주민 등록을 하지 않은 사용자
	final String USER_GRADE_NOMAL 				= "2"; // 일반 회원 - 아파트 등록은 진행했지만 입주민 등록을 하지 않은 사용자
	final String USER_GRADE_RESIDENT 			= "3"; // 입주민
	final String USER_GRADE_PRESENT 			= "4"; // 입주자 대표
	final String USER_GRADE_ADMIN 				= "5"; // 관리사무소
	final String USER_GRADE_SYSADMIN 			= "6"; // 시스템 관리자 - 빌리진아이 내부 운영 직원 및 개발자
	final String USER_GRADE_HOUSINGFAIR_ADMIN 	= "7"; // 하우징페어 관리자
	final String USER_GRADE_COMMUNITY_ADMIN 	= "8"; // 커뮤니티 관리자
	final String USER_GRADE_VILLGATE_AS 		= "9"; // 빌게이트 설치 담당자

	/* 클레임 상태 코드 */
	final String CLAIM_STATE_ING				= "0"; // 진행중
	final String CLAIM_STATE_COMPLETE			= "1"; // 상태 해제
	final String CLAIM_STATE_DELETE				= "2"; // 삭제 처리
	
	/* 글 신고 상태 코드 */
	final String POST_STATE_NOMAL				= "0"; // 정상
	final String POST_STATE_CLAIM				= "1"; // 사용자 신고
	final String POST_STATE_DELETE				= "2"; // 신고처리 삭제
	
	/*  자동 신고 처리할 신고 건수 */
	final int MAX_CLAIM_COUNT					= 5;
	
	/* 스마트 도어 사용자 구분 */
	final String SMART_DOOR_REPRESENT			= "0"; // 본인(대표자)
	final String SMART_DOOR_FAMILY				= "1"; // 세대원(세대주)
	final String SMART_DOOR_VISIT				= "2"; // 방문
	
	/* 시스템 공지사항 매체 구분 */
	final String SYSNOTICE_MEDIA_PC				= "0"; // PC(관리자 프로그램)
	final String SYSNOTICE_MEDIA_MOBILE			= "1"; // 회원(모바일)
	final String SYSNOTICE_MEDIA_ADMIN			= "2"; // 관리소(모바일)
	
	/* 제휴사 멤버 코드 **/
	final String PARTNER_CODE					= "10";	// 애견방문미용 매니저
	
	/*  애견 미용 로그 구분 */
	final String DOGBEAUTY_ENTRY_CLICK			= "0"; // 메뉴 조회
	final String DOGBEAUTY_RESERVE_CLICK		= "1"; // 예약 클릭
	final String DOGBEAUTY_RESERVE_COMPLET		= "2"; // 예약 완료
	
	/* 제휴 서비스 유저 등급 */
	final String PARTNER_GRADE_NOMAL 			= "0"; // 일반 유저
	final String PARTNER_GRADE_MANAGER 			= "1"; // 매니저
	final String PARTNER_GRADE_ADMIN 			= "2"; // 사장님
	
	/** 제휴 서비스 상태  **/
	final String PARTNER_STATE_ORDER 					= "10"; // 접수 완료
	final String PARTNER_STATE_CONSULTATION_COMPLETE 	= "11"; // 상담완료
	final String PARTNER_STATE_REQUEST_PAYMENT 			= "20"; // 결제 요청
	final String PARTNER_STATE_RESERVATION_CONFIRMED 	= "30";	// 예약 확정
	final String PARTNER_STATE_END 						= "90";	// 서비스 종료
	final String PARTNER_STATE_CANCEL 					= "99";	// 취소

	private static final String[] BAD_WORDS = {
        // 한글 욕설
        "시발", "씨발", "ㅅㅂ", "개새끼", "ㄱㅅㄲ", "병신", "ㅂㅅ",
        "미친놈", "미친년", "지랄", "썅", "쌍놈", "쌍년", "개년",
        "좇",
        // 영어 욕설
        "fuck", "shit", "bitch", "asshole", "bastard",
        "damn", "crap", "dick", "pussy",
        "motherfucker", "fucker", "wtf", "stfu"
    };


	/**
	 * 텍스트 정규화 - 변형어 대응 (ㅅ1발, f.u.c.k 등)
	 */
	private static String normalizeProfanity(String text) {
		String result = text.toLowerCase();
		result = result.replace("1", "i");
		result = result.replace("0", "o");
		result = result.replace("3", "e");
		result = result.replace("4", "a");
		result = result.replace("5", "s");
		result = result.replace("@", "a");
		result = result.replace("$", "s");
		// 공백(\s)은 유지하고 특수문자만 제거
		result = result.replaceAll("[.\\-_*,!]", "");
		return result;
	}
	/**
	 * 욕설 포함 여부 확인
	 * 사용예: if (containsProfanity(content)) { // 차단 처리 }
	 */
	public static boolean containsProfanity(String text) {
		if (text == null || text.trim().equals("")) {
			return false;
		}
		String normalized = normalizeProfanity(text);
		for (int i = 0; i < BAD_WORDS.length; i++) {
			if (normalized.contains(normalizeProfanity(BAD_WORDS[i]))) {
				return true;
			}
		}
		return false;
	}


	
%>