package com.ilgam.jangbu

import android.app.Application
import com.ilgam.jangbu.data.JangbuDatabase
import com.ilgam.jangbu.data.JangbuRepository

class JangbuApplication : Application() {
    val database: JangbuDatabase by lazy { JangbuDatabase.build(this) }
    val repository: JangbuRepository by lazy { JangbuRepository(database) }
}
