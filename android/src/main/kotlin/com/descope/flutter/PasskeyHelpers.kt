package com.descope.flutter


import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import org.json.JSONObject
import java.security.MessageDigest


// Passkey JSON

fun convertOptions(options: String): String {
    val root = try {
        JSONObject(options)
    } catch (e: Exception) {
        throw Exception("Invalid passkey options")
    }
    val publicKey = try {
        root.getString("publicKey")
    } catch (e: Exception) {
        throw Exception("Malformed passkey options")
    }
    return publicKey
}

// Android Helpers

internal fun getPackageOrigin(context: Context): String {
    @Suppress("DEPRECATION")
    val signers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        packageInfo?.signingInfo?.apkContentsSigners // nullable according to source code
    } else {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
        packageInfo.signatures
    }

    if (signers.isNullOrEmpty()) {
        throw Exception("Failed to find signing certificates")
    }

    val cert = signers[0].toByteArray()
    try {
        val md = MessageDigest.getInstance("SHA-256")
        val certHash = md.digest(cert)
        val encoded = certHash.toBase64()
        return "android:apk-key-hash:$encoded"
    } catch (e: Exception) {
        throw Exception("Failed to encode origin")
    }
}

// Base64

internal fun ByteArray.toBase64(): String {
    return Base64.encodeToString(this, Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE)
}
