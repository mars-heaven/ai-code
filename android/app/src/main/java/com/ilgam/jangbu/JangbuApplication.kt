package com.ilgam.jangbu

import android.app.Application
import com.ilgam.jangbu.data.JangbuDatabase
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.server.ServerAvailability
import com.ilgam.jangbu.server.SyncRepository
import com.ilgam.jangbu.util.Prefs
import com.ilgam.jangbu.util.Speaker
import com.ilgam.jangbu.util.SpeakerHolder
import com.ilgam.jangbu.util.invoicePhotoDir

class JangbuApplication : Application(), SpeakerHolder {

    val database: JangbuDatabase by lazy { JangbuDatabase.build(this) }
    val repository: JangbuRepository by lazy {
        JangbuRepository(database, invoicePhotoDir(this))
    }

    /** 소리 안내는 앱에 하나만 두고 화면끼리 나눠 씁니다. */
    override val speaker: Speaker by lazy { Speaker(this) }

    /** 서버와 맞추는 일꾼. 업체에 붙어 있을 때만 있습니다. */
    @Volatile
    var sync: SyncRepository? = null
        private set

    override fun onCreate() {
        super.onCreate()
        // 지난번에 붙어 둔 업체가 있으면 앱을 켤 때 바로 맞추기 시작합니다.
        val shopId = Prefs(this).shopId
        if (shopId.isNotBlank()) startSync(shopId)
    }

    fun startSync(shopId: String) {
        if (shopId.isBlank() || !ServerAvailability.ready(this)) return
        if (sync != null) return

        val worker = SyncRepository(database, shopId)
        // 앞으로 장부에 적는 것이 서버에도 함께 비칩니다.
        repository.mirror = worker
        worker.start()
        sync = worker
    }

    fun stopSync() {
        repository.mirror = null
        sync?.release()
        sync = null
    }
}
