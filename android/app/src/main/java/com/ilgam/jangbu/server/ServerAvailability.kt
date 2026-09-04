package com.ilgam.jangbu.server

import android.content.Context
import com.google.firebase.FirebaseApp
import com.ilgam.jangbu.BuildConfig

/**
 * 서버 저장을 쓸 수 있는 상태인지 알아봅니다.
 *
 * 이 앱은 서버 없이도 온전히 돌아갑니다.
 * google-services.json 을 넣고 빌드했을 때만 서버 기능이 켜지고,
 * 없으면 지금까지처럼 폰 안에만 저장합니다.
 */
object ServerAvailability {

    /** 빌드할 때 파이어베이스 설정 파일이 있었는지 */
    val configured: Boolean get() = BuildConfig.SERVER_ENABLED

    /** 설정 파일이 실제로 읽혀 파이어베이스가 준비됐는지 */
    fun ready(context: Context): Boolean {
        if (!configured) return false
        return runCatching {
            FirebaseApp.initializeApp(context.applicationContext) != null
        }.getOrDefault(false)
    }

    /**
     * 구글 로그인에 필요한 웹 클라이언트 번호.
     * google-services 플러그인이 넣어 주는 값이라, 설정 파일이 없으면 없습니다.
     * 코드에서 직접 R 값을 부르면 파일 없이는 빌드가 안 되므로 이름으로 찾습니다.
     */
    fun webClientId(context: Context): String? {
        val id = context.resources.getIdentifier(
            "default_web_client_id", "string", context.packageName
        )
        return if (id == 0) null else context.getString(id)
    }

    /** 화면에 그대로 띄울 수 있는 안내 문구 */
    fun unavailableReason(context: Context): String = when {
        !configured ->
            "이 앱은 아직 서버에 연결되어 있지 않습니다.\n지금은 이 휴대폰 안에만 저장됩니다."
        webClientId(context) == null ->
            "서버 설정이 덜 되어 있습니다.\n구글 로그인 설정을 확인해 주세요."
        else ->
            "서버에 연결할 수 없습니다.\n잠시 뒤에 다시 해 주세요."
    }
}
