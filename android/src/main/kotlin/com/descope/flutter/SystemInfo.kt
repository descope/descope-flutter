package com.descope.flutter

import android.content.Context
import android.os.Build

internal interface SystemInfo {
    val appName: String?
    val appVersion: String?
    val platformVersion: String
    val device: String?
}

internal class DescopeSystemInfo private constructor(context: Context) : SystemInfo {
    
    override val appName: String? = try {
        context.applicationInfo.loadLabel(context.packageManager).toString()
    } catch (ignored: Exception) {
        null
    }
    
    override val appVersion: String? = try {
        context.packageManager.getPackageInfo(context.packageName, 0)?.versionName
    } catch (ignored: Exception) {
        null
    }
    
    override val platformVersion: String = Build.VERSION.RELEASE
    
    override val device: String? = runCatching {
        val build = setOf<String?>(Build.MANUFACTURER, Build.MODEL)
        val values = build.mapNotNull { it?.replace(",", "_") }
            .filter { it.isNotBlank() && it != Build.UNKNOWN }
            .toSet()
        values.joinToString(", ").ifBlank { null }
    }.getOrNull()
    
    companion object {
        private var instance: SystemInfo? = null
        
        fun getInstance(context: Context): SystemInfo {
            return instance ?: DescopeSystemInfo(context).apply { instance = this }
        }
    }
}
