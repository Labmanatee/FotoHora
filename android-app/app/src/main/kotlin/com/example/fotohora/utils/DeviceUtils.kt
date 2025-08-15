package com.example.fotohora.utils

import android.content.Context
import android.net.wifi.WifiManager
import android.provider.Settings

object DeviceUtils {
    fun getMacAddress(context: Context): String {
        val manager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        return manager.connectionInfo?.macAddress ?: Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        )
    }
}