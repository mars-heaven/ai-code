package com.ilgam.jangbu

import android.app.Application
import com.ilgam.jangbu.data.JangbuDatabase
import com.ilgam.jangbu.data.JangbuRepository
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
}
