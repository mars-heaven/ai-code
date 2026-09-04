package com.ilgam.jangbu.util

import android.content.Context
import java.time.Instant
import java.time.ZoneId
import java.time.LocalDate

/** 앱이 기억해 두는 자잘한 설정. 장부와 달리 없어져도 큰일 나지 않는 것들입니다. */
class Prefs(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences("jangbu_prefs", Context.MODE_PRIVATE)

    /** 마지막으로 백업을 저장한 시각 */
    var lastBackupAt: Long
        get() = prefs.getLong(KEY_LAST_BACKUP, 0L)
        set(value) = prefs.edit().putLong(KEY_LAST_BACKUP, value).apply()

    /** 눌렀을 때 소리로 알려 줄지 여부 */
    var speakEnabled: Boolean
        get() = prefs.getBoolean(KEY_SPEAK, true)
        set(value) = prefs.edit().putBoolean(KEY_SPEAK, value).apply()

    /** 지금 붙어 있는 업체. 서버를 안 쓰면 비어 있습니다. */
    var shopId: String
        get() = prefs.getString(KEY_SHOP_ID, "").orEmpty()
        set(value) = prefs.edit().putString(KEY_SHOP_ID, value).apply()

    var shopName: String
        get() = prefs.getString(KEY_SHOP_NAME, "").orEmpty()
        set(value) = prefs.edit().putString(KEY_SHOP_NAME, value).apply()

    /** 이 업체에서 내가 사장님인지(가족은 보기만 합니다) */
    var shopIsOwner: Boolean
        get() = prefs.getBoolean(KEY_SHOP_OWNER, true)
        set(value) = prefs.edit().putBoolean(KEY_SHOP_OWNER, value).apply()

    fun clearShop() {
        prefs.edit()
            .remove(KEY_SHOP_ID)
            .remove(KEY_SHOP_NAME)
            .remove(KEY_SHOP_OWNER)
            .apply()
    }

    private companion object {
        const val KEY_LAST_BACKUP = "last_backup_at"
        const val KEY_SPEAK = "speak_enabled"
        const val KEY_SHOP_ID = "shop_id"
        const val KEY_SHOP_NAME = "shop_name"
        const val KEY_SHOP_OWNER = "shop_is_owner"
    }
}

/** 0 이면 "아직 없음" 입니다. */
fun Long.toBackupDisplay(): String =
    if (this <= 0L) "아직 백업한 적이 없습니다"
    else "마지막 백업 " + Instant.ofEpochMilli(this)
        .atZone(ZoneId.systemDefault()).toLocalDate().toDisplay()

/** 백업한 지 오래되었는지 — 오래되면 홈에서 눈에 띄게 알려 줍니다. */
fun Long.backupIsStale(days: Long = 14): Boolean {
    if (this <= 0L) return true
    val last = Instant.ofEpochMilli(this).atZone(ZoneId.systemDefault()).toLocalDate()
    return last.plusDays(days).isBefore(LocalDate.now())
}
