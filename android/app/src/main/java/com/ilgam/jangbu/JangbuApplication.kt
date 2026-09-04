package com.ilgam.jangbu

import android.app.Application
import com.ilgam.jangbu.data.JangbuDatabase
import com.ilgam.jangbu.data.JangbuRepository
import com.ilgam.jangbu.util.invoicePhotoDir

class JangbuApplication : Application() {
    val database: JangbuDatabase by lazy { JangbuDatabase.build(this) }
    val repository: JangbuRepository by lazy {
        JangbuRepository(database, invoicePhotoDir(this))
    }
}
