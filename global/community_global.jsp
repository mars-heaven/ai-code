<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Date" %>
<%@ page import="java.text.*" %>
<%@ page import="java.util.HashMap" %>
<%!

    // 커뮤니티 타입
    // 골프 01, 탁구 02, ...
    final static String TYPE_GOLF = "01";
    final static String TYPE_TABLE_TENNIS = "02";
    final static String TYPE_GYM = "03";
    final static String TYPE_READING_ROOM = "04";
    final static String TYPE_SCREEN_GOLF = "05";
    final static String TYPE_GOLF_LOKKER = "06";  //골프장 락커룸
    final static String TYPE_GYM_LOKKER = "07";  //헬스장 락커룸
    final static String TYPE_SAUNA = "08"; // 사우나
    final static String TYPE_LIBRATY = "09"; // 도서관
    final static String TYPE_GUESTHOUSE = "10"; // 게스트하우스
    final static String TYPE_SKYLOUNGE = "11"; // 스카이라운지
    final static String TYPE_GX = "17"; // GX

    // 매주 반복
    final static int WEEKLY_REPEAT = 0;

    // 해당 주 반복 (1~5)
    final static int WEEK_OF_MONTH_1 = 1;
    final static int WEEK_OF_MONTH_2 = 2;
    final static int WEEK_OF_MONTH_3 = 3;
    final static int WEEK_OF_MONTH_4 = 4;
    final static int WEEK_OF_MONTH_5 = 5;

    // 매달 반복
    final static int MONTHLY_REPEAT = 6;

    // 매일 반복
    final static int DAILY_REPEAT = 7;

    // 공휴일
    final static int HOLIDAY_REPEAT = 9;
    
    // SPECIFIC 종류
    final static int SPECIFIC_HOLIDAY_REPEAT = 0;	// 정기휴일
    final static int SPECIFIC_TIME_SHORTENING = 1;	// 단축근무
    final static int SPECIFIC_TIME_BREAK = 2;				// 휴식시간
    final static int SPECIFIC_HOLIDAY_TEMP = 3;		// 임시휴무
    final static int SPECIFIC_HOLIDAY_EXCEPT = 4;	// 임시운영일

    // 일~토 요일
    final static int SUNDAY = 0;
    final static int MONDAY = 1;
    final static int TUESDAY = 2;
    final static int WEDNESDAY = 3;
    final static int THURSDAY = 4;
    final static int FRIDAY = 5;
    final static int SATURDAY = 6;

    // 예약 내역, 과거 이용 내역
    final static String RESERVATION_HISTORY = "1";
    final static String PAST_USAGE_RECORDS = "0";

    // 취소 타입 
    // 0 : 분 단위, 1 : 일 단위
    final static String CANCEL_TYPE_DAYS = "1";
    final static String CANCEL_TYPE_MINUTES = "0";

      // 서비스 타입
    final static String IMMEDIATE_RESERVE = "1";             // 바로 예약
    final static String TICKET_PURCHASE_WITH_TIME = "2";     // 이용권 구매 후 시간을 추가 선택
    final static String NO_RESERVE = "3";                    // 예약없음
    final static String TICKET_PURCHASE_AND_RESERVE = "4";   // 이용권 구매와 예약이 동시에 이루어짐
     
    // 시간 단위
    final static String UNIT_MINUTE = "0"; // 분
    final static String UNIT_HOUR = "1"; // 시
    final static String UNIT_DAYS = "2";  // 일
    final static String UNIT_MONTH = "3"; // 월
    final static String UNIT_YEAR = "4"; // 년

 // 예약 제한 횟수 단위
    final static String RESERVE_LIMIT_TYPE_PERSON = "0"; // 아이디당
    final static String RESERVE_LIMIT_TYPE_HOUSEHOLD = "1"; // 세대당

    // 예약 타입
    final static String RESERVE_TYPE_MEMBERSHIP = "0"; // 예약과 회원권 구매가 동시에 일어나는 경우
    final static String RESERVE_TYPE_ADDITIONAL_AFTER_PURCHASE = "1"; // 구매 후 추가 예약 가능
    final static String RESERVE_TYPE_ONE_OFF = "2"; // 일회성 회원권
    final static String RESERVE_TYPE_RENTAL = "3"; // 대관권 (시설 대관 전용 회원권)


    // 취소 가능 여부
    final static String CANCEL_IMPOSSIBLE = "0"; // 불가능
    final static String CANCEL_POSSIBLE = "1"; // 가능
    
    // 시설 상태
    final static String HIDDEN = "0"; // 숨김
    final static String VISIBLE = "1"; // 보임
    final static String UNAVAILABLE = "2"; // 예약준비중

    // 예약 제한 단위
    final static String RESERVE_LIMIT_UNIT_DAY = "0";
    final static String RESERVE_LIMIT_UNIT_WEEK = "1";

    // 보안여부
    final static String ACCESS_CONTROL_DISABLED  = "0";
    final static String FACE_RECOGNITION_ENABLED  = "1";

    // 시설 이용 가능 성별(GENDER)
    final static String GENDER_All = "0";   // 무관
    final static String GENDER_MAN = "1";   // 남자
    final static String GENDER_WOMAN = "2"; // 여자


    // 일~토 요일 코드값을 넣으면 해당하는 문자열을 리턴
    // 매주 월요일, 매주 수요일 등
    public String handleWeeklyRepeat(int dayOfWeek) {
        String strDayOfWeek = "";
        switch (dayOfWeek) {
            case SUNDAY:
                strDayOfWeek = "매주 일요일";
                break;
            case MONDAY:
                strDayOfWeek = "매주 월요일";
                break;
            case TUESDAY:
                strDayOfWeek = "매주 화요일";
                break;
            case WEDNESDAY:
                strDayOfWeek = "매주 수요일";
                break;
            case THURSDAY:
                strDayOfWeek = "매주 목요일";
                break;
            case FRIDAY:
                strDayOfWeek = "매주 금요일";
                break;
            case SATURDAY:
                strDayOfWeek = "매주 토요일";
                break;
            default:
                strDayOfWeek = "";
                break;
        }
        return strDayOfWeek;
    }

    // nn주 일~토 두 코드값을 넣으면 해당하는 문자열을 리턴
    // ex) 첫째주 월요일, 다섯쨰주 수요일 등
    public String handleSpecificWeekRepeat(int weekOfMonth, int dayOfWeek) {
        String strDayOfWeek = "";
        switch (weekOfMonth) {
            case WEEK_OF_MONTH_1:
                strDayOfWeek += " 첫째주";
                break;
            case WEEK_OF_MONTH_2:
                strDayOfWeek += " 둘째주";
                break;
            case WEEK_OF_MONTH_3:
                strDayOfWeek += " 셋째주";
                break;
            case WEEK_OF_MONTH_4:
                strDayOfWeek += " 넷째주";
                break;
            case WEEK_OF_MONTH_5:
                strDayOfWeek += " 다섯째주";
                break;
            default:
                strDayOfWeek = "";
                break;
        }

        switch (dayOfWeek) {
            case SUNDAY:
                strDayOfWeek += " 일요일";
                break;
            case MONDAY:
                strDayOfWeek += " 월요일";
                break;
            case TUESDAY:
                strDayOfWeek += " 화요일";
                break;
            case WEDNESDAY:
                strDayOfWeek += " 수요일";
                break;
            case THURSDAY:
                strDayOfWeek += " 목요일";
                break;
            case FRIDAY:
                strDayOfWeek += " 금요일";
                break;
            case SATURDAY:
                strDayOfWeek += " 토요일";
                break;
            default:
                strDayOfWeek = "";
                break;
        }
        return strDayOfWeek;
    }

    //커뮤니티 센터 정보에 양식에 맞게 데이터를 조합하는 메서드
    // ex)운영시간*strTime*+자리개수*strCount*+타임간격*strInterval*+휴무일*strHolidays*+
    public String formatCommunityData(String strType, String strTime, String strCount, String strInterval, String strHolidays){

        // "매주"가 2개 이상이면 첫 번째만 남기고 제거
        int firstIndex = strHolidays.indexOf("매주");
        int lastIndex = strHolidays.lastIndexOf("매주");

        if (firstIndex != -1 && lastIndex != -1 && firstIndex != lastIndex) {
            // 첫 번째 "매주"는 살리고 나머지는 제거
            String before = strHolidays.substring(0, firstIndex + 2); // "매주"까지 포함
            String after = strHolidays.substring(firstIndex + 2);
            after = after.replaceAll("매주", "");
            strHolidays = before + after;
            strHolidays = strHolidays.replaceAll("요일","");
        }
        
        String strFormatData = "";
        //골프 또는 탁구 둘이 같은 성격
        if(strType.contentEquals(TYPE_GOLF) || strType.contentEquals(TYPE_TABLE_TENNIS) || strType.contentEquals(TYPE_SCREEN_GOLF)){
            strFormatData = "운영시간*" + strTime +"*+";
            strFormatData += "자리개수*" + strCount +"개*+";
            strFormatData += "타임간격*" + strInterval +"분*+";
            if(strHolidays == null || strHolidays.contentEquals("")){
                strHolidays = "없음";
            }
            strFormatData += "휴무일*" + strHolidays +"*+";
        }else if(strType.contentEquals(TYPE_GYM) || strType.contentEquals(TYPE_LIBRATY)){
            strFormatData = "운영시간*" + strTime +"*+";
            if(strHolidays == null || strHolidays.contentEquals("")){
                strHolidays = "없음";
            }
            strFormatData += "휴무일*" + strHolidays +"*+";
        }else if(strType.contentEquals(TYPE_READING_ROOM)){
            strFormatData = "운영시간*" + strTime +"*+";
            strFormatData += "자리개수*" + strCount +"개*+";
            if(strHolidays == null || strHolidays.contentEquals("")){
                strHolidays = "없음";
            }
            strFormatData += "휴무일*" + strHolidays +"*+";
        }else if(strType.contentEquals(TYPE_GUESTHOUSE)){
            String strStartTime = strTime.replace(" ","").replace(":","").replace("~","").substring(0,4);
            strStartTime = strStartTime.substring(0,2) + ":" + strStartTime.substring(2,4);
            String strEndTime = strTime.replace(" ","").replace(":","").replace("~","").substring(4,8);
            strEndTime = strEndTime.substring(0,2) + ":" + strEndTime.substring(2,4);
            strFormatData ="운영시간*입실 당일 " + strStartTime+ " / 퇴실 익일 " + strEndTime + "*+";
            
            if(strHolidays == null || strHolidays.contentEquals("")){
                strHolidays = "없음";
            }
            strFormatData += "휴무일*" + strHolidays +"*+";

        }else{
            strFormatData = "운영시간*" + strTime +"*+";

            if(strHolidays == null || strHolidays.contentEquals("")){
                strHolidays = "없음";
            }
            strFormatData += "휴무일*" + strHolidays +"*+";
        }


        return strFormatData;
    }


 
	

	
	
%>