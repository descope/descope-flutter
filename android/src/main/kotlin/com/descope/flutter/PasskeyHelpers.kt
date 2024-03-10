package com.descope.flutter


import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import com.google.android.gms.fido.fido2.api.common.Attachment
import com.google.android.gms.fido.fido2.api.common.AuthenticatorSelectionCriteria
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredential
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialCreationOptions
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialDescriptor
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialParameters
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialRequestOptions
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialRpEntity
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialType
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialUserEntity
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.security.MessageDigest


// Passkey JSON

const val RESULT_CANCELED = 0

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

fun parsePublicKeyCredentialCreationOptions(options: String): PublicKeyCredentialCreationOptions {
    val json = JSONObject(options)
    return PublicKeyCredentialCreationOptions.Builder()
        .setUser(parseUser(json.getJSONObject("user")))
        .setChallenge(json.getString("challenge").decodeBase64())
        .setParameters(parseParameters(json.getJSONArray("pubKeyCredParams")))
        .setTimeoutSeconds(json.getDouble("timeout"))
        .setExcludeList(parseCredentialDescriptors(json.getJSONArray("excludeCredentials")))
        .setAuthenticatorSelection(parseSelection(json.getJSONObject("authenticatorSelection")))
        .setRp(parseRp(json.getJSONObject("rp")))
        .build()
}

fun parsePublicKeyCredentialRequestOptions(options: String): PublicKeyCredentialRequestOptions {
    val json = JSONObject(options)
    return PublicKeyCredentialRequestOptions.Builder()
        .setChallenge(json.getString("challenge").decodeBase64())
        .setAllowList(parseCredentialDescriptors(json.getJSONArray("allowCredentials")))
        .setRpId(json.getString("rpId"))
        .setTimeoutSeconds(json.getDouble("timeout"))
        .build()
}

private fun parseUser(jsonObject: JSONObject) = PublicKeyCredentialUserEntity(
    jsonObject.getString("id").decodeBase64(),
    jsonObject.getString("name"),
    "", // icon
    jsonObject.stringOrEmptyAsNull("displayName") ?: ""
)

private fun parseParameters(jsonArray: JSONArray) = mutableListOf<PublicKeyCredentialParameters>().apply {
    for (i in 0 until jsonArray.length()) {
        val jsonObject = jsonArray.getJSONObject(i)
        add(PublicKeyCredentialParameters(jsonObject.getString("type"), jsonObject.getInt("alg")))
    }
}

private fun parseCredentialDescriptors(jsonArray: JSONArray) = mutableListOf<PublicKeyCredentialDescriptor>().apply {
    for (i in 0 until jsonArray.length()) {
        val jsonObject = jsonArray.getJSONObject(i)
        add(
            PublicKeyCredentialDescriptor(
                PublicKeyCredentialType.PUBLIC_KEY.toString(),
                jsonObject.getString("id").decodeBase64(),
                null
            )
        )
    }
}

private fun parseSelection(jsonObject: JSONObject) = AuthenticatorSelectionCriteria.Builder().run {
    jsonObject.stringOrEmptyAsNull("authenticatorAttachment")?.let {
        setAttachment(Attachment.fromString(it))
    }
    build()
}

private fun parseRp(jsonObject: JSONObject) = PublicKeyCredentialRpEntity(
    jsonObject.getString("id"),
    jsonObject.getString("name"),
    null
)

// JSON

private fun JSONObject.stringOrEmptyAsNull(key: String): String? = try {
    getString(key).ifEmpty { null }
} catch (ignored: JSONException) {
    null
}

// Android Helpers

internal fun getPackageOrigin(context: Context): String {
    @Suppress("DEPRECATION")
    val signers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        packageInfo.signingInfo.apkContentsSigners // nullable according to source code
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

internal fun String.decodeBase64(): ByteArray {
    return Base64.decode(this, Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE)
}

internal fun ByteArray.toBase64(): String {
    return Base64.encodeToString(this, Base64.NO_PADDING or Base64.NO_WRAP or Base64.URL_SAFE)
}
