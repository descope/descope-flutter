package com.descope.flutter

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
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
import com.google.android.gms.fido.Fido
import com.google.android.gms.fido.fido2.api.common.AuthenticatorAssertionResponse
import com.google.android.gms.fido.fido2.api.common.AuthenticatorAttestationResponse
import com.google.android.gms.fido.fido2.api.common.AuthenticatorErrorResponse
import com.google.android.gms.fido.fido2.api.common.ErrorCode.ABORT_ERR
import com.google.android.gms.fido.fido2.api.common.ErrorCode.TIMEOUT_ERR
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredential
import com.google.android.gms.fido.fido2.api.common.PublicKeyCredentialType
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
      "passkeySupported" -> isPasskeySupported(result)
      "passkeyOrigin" -> passkeyOrigin(result)
      "passkeyCreate" -> createPasskey(call, result)
      "passkeyAuthenticate" -> usePasskey(call, result)
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

  // Passkeys

  private fun isPasskeySupported(res: Result) {
    res.success(android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P)
  }

  private fun passkeyOrigin(res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    try {
      val origin = getPackageOrigin(context)
      res.success(origin)
    } catch (e: Exception) {
      res.error("FAILED", "Context is null", null)
    }
  }

  private fun createPasskey(call: MethodCall, res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val options = call.argument<String>("options") ?: return res.error("MISSINGARGS", "'options' is required for createPasskey", null)
    performRegister(context, options) { pendingIntent, e ->
      if (e != null) {
        res.error("FAILED", e.message, null)
      } else if (pendingIntent != null) {
        activityHelper.startHelperActivity(context, pendingIntent) { code, intent ->
          try {
            val json = prepareRegisterResponse(code, intent)
            res.success(json)
          } catch (e: Exception) {
            res.error("FAILED", e.message, null)
          }
        }
      } else {
        res.error("FAILED", "Unxepected result when registering passkey", null)
      }
    }
  }

  private fun usePasskey(call: MethodCall, res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val options = call.argument<String>("options") ?: return res.error("MISSINGARGS", "'options' is required for usePasskey", null)
    performAssertion(context, options) { pendingIntent, e ->
      if (e != null) {
        res.error("FAILED", e.message, null)
      } else if (pendingIntent != null) {
        activityHelper.startHelperActivity(context, pendingIntent) { code, intent ->
          try {
            val json = prepareAssertionResponse(code, intent)
            res.success(json)
          } catch (e: Exception) {
            res.error("FAILED", e.message, null)
          }
        }
      } else {
        res.error("FAILED", "Unxepected result when registering passkey", null)
      }
    }
  }

  private fun performRegister(context: Context, options: String, callback: (PendingIntent?, Exception?) -> Unit) {
    val client = Fido.getFido2ApiClient(context)
    val opts = parsePublicKeyCredentialCreationOptions(convertOptions(options))
    val task = client.getRegisterPendingIntent(opts)
    task.addOnSuccessListener { callback(it, null) }
    task.addOnFailureListener { callback(null, it) }
  }

  private fun performAssertion(context: Context, options: String, callback: (PendingIntent?, Exception?) -> Unit) {
    val client = Fido.getFido2ApiClient(context)
    val opts = parsePublicKeyCredentialRequestOptions(convertOptions(options))
    val task = client.getSignPendingIntent(opts)
    task.addOnSuccessListener { callback(it, null) }
    task.addOnFailureListener { callback(null, it) }
  }

  private fun prepareRegisterResponse(resultCode: Int, intent: Intent?): String {
    val credential = extractCredential(resultCode, intent)
    val rawId = credential.rawId?.toBase64()
    val response = credential.response as AuthenticatorAttestationResponse
    return JSONObject().apply {
      put("id", rawId)
      put("type", PublicKeyCredentialType.PUBLIC_KEY.toString())
      put("rawId", rawId)
      put("response", JSONObject().apply {
        put("clientDataJson", response.clientDataJSON.toBase64())
        put("attestationObject", response.attestationObject.toBase64())
      })
    }.toString()
  }

  private fun prepareAssertionResponse(resultCode: Int, intent: Intent?): String {
    val credential = extractCredential(resultCode, intent)
    val rawId = credential.rawId?.toBase64()
    val response = credential.response as AuthenticatorAssertionResponse
    return JSONObject().apply {
      put("id", rawId)
      put("type", PublicKeyCredentialType.PUBLIC_KEY.toString())
      put("rawId", rawId)
      put("response", JSONObject().apply {
        put("clientDataJson", response.clientDataJSON.toBase64())
        put("authenticatorData", response.authenticatorData.toBase64())
        put("signature", response.signature.toBase64())
        response.userHandle?.let { put("userHandle", it.toBase64()) }
      })
    }.toString()
  }

  private fun extractCredential(resultCode: Int, intent: Intent?): PublicKeyCredential {
    // check general response
    if (resultCode == RESULT_CANCELED) throw Exception("Passkey canceled")
    if (intent == null) throw Exception("Null intent received from ")

    // get the credential from the intent extra
    val credential = try {
      val byteArray = intent.getByteArrayExtra("FIDO2_CREDENTIAL_EXTRA")!!
      PublicKeyCredential.deserializeFromBytes(byteArray)
    } catch (e: Exception) {
      throw Exception("Failed to extract credential from intent")
    }

    // check for any logical failures
    (credential.response as? AuthenticatorErrorResponse)?.run {
      when (errorCode) {
        ABORT_ERR -> throw Exception("Passkey canceled")
        TIMEOUT_ERR -> throw Exception("The operation timed out")
        else -> throw Exception("Passkey authentication failed (${errorCode.name}: $errorMessage)")
      }
    }

    return credential
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
