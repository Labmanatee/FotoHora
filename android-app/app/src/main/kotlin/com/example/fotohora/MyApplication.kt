package com.example.fotohora

import android.app.Application
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Habilitar logging de Firebase
        Firebase.database.setLogLevel(com.google.firebase.database.Logger.Level.DEBUG)
    }
}