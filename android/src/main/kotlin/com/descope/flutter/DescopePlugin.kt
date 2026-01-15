package com.descope.flutter

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.browser.customtabs.CustomTabsIntent
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.descope.Descope
import com.descope.android.DescopeSystemInfo
import com.descope.internal.routes.getPackageOrigin
import com.descope.internal.routes.performAssertion
import com.descope.internal.routes.performNativeAuthorization
import com.descope.internal.routes.performRegister
import com.descope.sdk.DescopeLogger
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

/** DescopePlugin */
class DescopePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private var channel : MethodChannel? = null
  private var logChannel: MethodChannel? = null
  private var context: Context? = null
  private lateinit var storage: Store

  // MethodCallHandler
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getSystemInfo" -> getSystemInfo(result)
      "startFlow" -> startFlow(call, result)
      "oauthNative" -> oauthNative(call, result)
      "passkeySupported" -> isPasskeySupported(result)
      "passkeyOrigin" -> passkeyOrigin(result)
      "passkeyCreate" -> createOrUsePasskey(call, result, true)
      "passkeyAuthenticate" -> createOrUsePasskey(call, result, false)
      "loadItem" -> loadItem(call, result)
      "saveItem" -> saveItem(call, result)
      "removeItem" -> removeItem(call, result)
      else -> result.notImplemented()
    }
  }

  // General

  private fun getSystemInfo(res: Result) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val systemInfo = DescopeSystemInfo.getInstance(context)
    val info = mutableMapOf(
      "platformName" to "android",
      "platformVersion" to systemInfo.platformVersion,
    ).apply {
      systemInfo.appName?.let { put("appName", it) }
      systemInfo.appVersion?.let { put("appVersion", it) }
      systemInfo.device?.let { put("device", it) }
    }
    res.success(info)
  }

  // Flows - Deprecated

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
    val implicit = true // always true for Android
    GlobalScope.launch(Dispatchers.Main) {
      try {
        val identityToken = performNativeAuthorization(context, clientId, nonce, implicit)
        val json = JSONObject(mapOf("identityToken" to identityToken)).toString()
        res.success(json)
      } catch (e: Exception) {
        res.error("FAILED", e.message, null)
      }
    }
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

  private fun createOrUsePasskey(call: MethodCall, res: Result, create: Boolean) {
    val context = this.context ?: return res.error("NULLCONTEXT", "Context is null", null)
    val options = call.argument<String>("options") ?: return res.error("MISSINGARGS", "'options' is required for passkey functions", null)
    GlobalScope.launch(Dispatchers.Main) {
      try {
        val response =
          if (create) performRegister(context, options)
          else performAssertion(context, options)
        res.success(response)
      } catch (e: Exception) {
        res.error("FAILED", e.message, null)
      }
    }
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

    // Set up the log channel with a handler for logger configuration from Flutter
    val logsChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "descope_flutter/logs")
    logChannel = logsChannel
    val applicationContext = flutterPluginBinding.applicationContext

    logsChannel.setMethodCallHandler { call, result ->
      if (call.method == "configure") {
        val levelString = call.argument<String>("level")
        val unsafe = call.argument<Boolean>("unsafe")

        if (levelString == null || unsafe == null) {
          result.error("INVALID_ARGS", "Missing level or unsafe arguments", null)
          return@setMethodCallHandler
        }

        val level = when (levelString) {
          "error" -> DescopeLogger.Level.Error
          "info" -> DescopeLogger.Level.Info
          else -> DescopeLogger.Level.Debug
        }

        // Initialize SDK with the logger configured from Flutter
        Descope.setup(applicationContext, projectId = "") {
          logger = FlutterDescopeLogger(logsChannel, level, unsafe)
        }

        result.success(null)
      } else {
        result.notImplemented()
      }
    }

    flutterPluginBinding.platformViewRegistry.registerViewFactory(
      "descope_flutter/descope_flow_view",
      DescopeFlowViewFactory(flutterPluginBinding.binaryMessenger)
    )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    logChannel?.setMethodCallHandler(null)
    logChannel = null
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

// Logger

/**
 * A DescopeLogger subclass that forwards all logs to Flutter via a MethodChannel.
 * This logger mirrors the level and unsafe settings from the Flutter layer.
 */
private class FlutterDescopeLogger(private val channel: MethodChannel, level: Level, unsafe: Boolean) : DescopeLogger(level, unsafe) {
    private val handler = Handler(Looper.getMainLooper())

    override fun output(level: Level, message: String, values: List<Any>) {
        val levelString = when (level) {
            Level.Error -> "error"
            Level.Info -> "info"
            Level.Debug -> "debug"
        }

        val valuesArray = values.map { it.toString() }

        handler.post {
            channel.invokeMethod("log", mapOf(
                "level" to levelString,
                "message" to message,
                "values" to valuesArray,
            ))
        }
    }
}
