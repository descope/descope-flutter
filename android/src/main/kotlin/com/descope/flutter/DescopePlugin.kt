package com.descope.flutter

import android.content.Context
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import androidx.credentials.CredentialManager
import androidx.credentials.CredentialManagerCallback
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import org.json.JSONObject

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** DescopePlugin */
class DescopePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private var channel : MethodChannel? = null
  private var context: Context? = null
  private lateinit var storage: Store

  // MethodCallHandler
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startFlow" -> startFlow(call, result)
      "oauthNative" -> oauthNative(call, result)
      "loadItem" -> loadItem(call, result)
      "saveItem" -> saveItem(call, result)
      "removeItem" -> removeItem(call, result)
      else -> result.notImplemented()
    }
  }

  // Flows

  private fun startFlow(call: MethodCall, res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val url = call.argument<String>("url") ?: return res.error("MISSINGARGS", "'url' is required for startFlow", null)
    try {
      val uri = Uri.parse(url)
      launchUri(context, uri)
      res.success(url)
    } catch (ignored: Exception) {
      res.error("INVALIDARGS", "url argument is invalid", null)
    }
  }

  // OAuth

  private fun oauthNative(call: MethodCall, res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val clientId = call.argument<String>("clientId") ?: return res.error("MISSINGARGS", "'clientId' is required for oauthNative", null)
    val nonce = call.argument<String>("nonce") ?: return res.error("MISSINGARGS", "'nonce' is required for oauthNative", null)
    val implicit = call.argument<Boolean>("implicit") ?: return res.error("MISSINGARGS", "'implicit' is required for oauthNative", null)

    if (!implicit) {
      return res.error("FAILED", "OAuth provider grant type must be set to implicit", null)
    }

    val option = GetGoogleIdOption.Builder().run {
      setFilterByAuthorizedAccounts(false)
      setServerClientId(clientId)
      setNonce(nonce)
      build()
    }

    val request = GetCredentialRequest.Builder().run {
      addCredentialOption(option)
      build()
    }

    val callback = object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
      override fun onResult(result: GetCredentialResponse) {
        val credential = result.credential
        if (credential !is CustomCredential) {
          return res.error("FAILED", "Unexpected OAuth credential subclass", null)
        }
        if (credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
          return res.error("FAILED", "Unexpected OAuth credential type", null)
        }

        val idTokenCred = try {
          GoogleIdTokenCredential.createFrom(credential.data)
        } catch (e: GoogleIdTokenParsingException) {
          return res.error("FAILED", "Invalid OAuth credential", null)
        }

        val values = mapOf("identityToken" to idTokenCred.idToken)
        val json = JSONObject(values).toString()
        res.success(json)
      }

      override fun onError(e: GetCredentialException) {
        if (e is GetCredentialCancellationException) {
          res.error("CANCELLED", "OAuth authentication cancelled", null)
        } else {
          res.error("FAILED", e.errorMessage?.toString(), null)
        }
      }
    }

    val credentialManager = CredentialManager.create(context)
    credentialManager.getCredentialAsync(context, request, null, Runnable::run, callback)
  }

  // Storage

  @Suppress("UNUSED_PARAMETER")
  private fun initStorageIfNeeded(call: MethodCall, key: String, res: Result): Boolean {
    if (this::storage.isInitialized) return false

    val context = this.context
    if (context == null) {
      res.error("NULLCONTEXT", "Context is null", null)
      return true
    }

    storage = createEncryptedStore(context, key)
    return false
  }

  private fun loadItem(call: MethodCall, res: Result) {
    val key = keyFromCall(call, res) ?: return
    if (initStorageIfNeeded(call, key, res)) return
    val value = storage.loadItem(key)
    res.success(value)
  }

  private fun saveItem(call: MethodCall, res: Result) {
    val key = keyFromCall(call, res) ?: return
    if (initStorageIfNeeded(call, key, res)) return
    val data = dataFromCall(call, res) ?: return
    storage.saveItem(key, data)
    res.success(key)
  }

  private fun removeItem(call: MethodCall, res: Result) {
    val key = keyFromCall(call, res) ?: return
    if (initStorageIfNeeded(call, key, res)) return
    storage.removeItem(key)
    res.success(key)
  }

  private fun keyFromCall(call: MethodCall, res: Result) = stringFromCall("key", call, res)

  private fun dataFromCall(call: MethodCall, res: Result) = stringFromCall("data", call, res)

  private fun stringFromCall(key: String, call: MethodCall, res: Result): String? {
    val data = call.argument<String>(key)
    if (data == null) {
      res.error("MISSINGARGS", "'$key' argument is required", null)
    }
    return data
  }

  // FlutterPlugin

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "descope_flutter/methods")
    channel?.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
  }

  // ActivityAware

  override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
    context = activityPluginBinding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    context = null
  }

  override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
    context = activityPluginBinding.activity
  }

  override fun onDetachedFromActivity() {
    context = null
  }
}

private fun launchUri(context: Context, uri: Uri) {
  val customTabsIntent = CustomTabsIntent.Builder()
    .setUrlBarHidingEnabled(true)
    .setShowTitle(true)
    .setShareState(CustomTabsIntent.SHARE_STATE_OFF)
    .build()
  customTabsIntent.launchUrl(context, uri)
}

private class EncryptedStorage(context: Context, name: String): Store {
  private val masterKey = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
  private val sharedPreferences = EncryptedSharedPreferences.create(
    name,
    masterKey,
    context,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
  )

  override fun loadItem(key: String): String? = sharedPreferences.getString(key, null)

  override fun saveItem(key: String, data: String) = sharedPreferences.edit()
    .putString(key, data)
    .apply()

  override fun removeItem(key: String) = sharedPreferences.edit()
    .remove(key)
    .apply()
}

/**
 * A helper interface that takes care of the actual storage of session data.
 *
 * The default function implementations in this interface do nothing or return `null`.
 */
interface Store {
  fun saveItem(key: String, data: String) {}

  fun loadItem(key: String): String? = null

  fun removeItem(key: String) {}

  companion object {
    /** A store that does nothing */
    val none = object : Store {}
  }
}

private fun createEncryptedStore(context: Context, projectId: String): Store {
  try {
    return EncryptedStorage(context, projectId)
  } catch (e: Exception) {
    try {
      // encrypted storage key unusable
      context.deleteSharedPreferences(projectId)
      return EncryptedStorage(context, projectId)
    } catch (e: Exception) {
      // unable to initialize encrypted storage
      return Store.none
    }
  }
}
