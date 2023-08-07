package com.descope.flutter

import android.content.Context
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys

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
  private lateinit var storage: EncryptedStorage

  // MethodCallHandler
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startFlow" -> startFlow(call, result)
      "loadItem" -> loadItem(call, result)
      "saveItem" -> saveItem(call, result)
      "removeItem" -> removeItem(call, result)
      else -> result.notImplemented()
    }
  }

  // Flows

  private fun startFlow(call: MethodCall, result: Result) {
    val context = this.context ?: return result.error("NULLCONTEXT", "Context is null", null)
    val url = call.argument<String>("url") ?: return result.error("MISSINGARGS", "'url' is required for startFlow", null)
    try {
      val uri = Uri.parse(url)
      launchUri(context, uri)
      result.success(url)
    } catch (ignored: Exception) {
      result.error("INVALIDARGS", "url argument is invalid", null)
    }
  }

  // Session Management

  private fun initStorageIfNeeded(call: MethodCall, result: Result): Boolean {
    if (this::storage.isInitialized) return false

    val projectId = call.argument<String>("projectId")
    if (projectId == null) {
      result.error("MISSINGARGS", "'projectId' argument is required", null)
      return true
    }

    val context = this.context
    if (context == null) {
      result.error("NULLCONTEXT", "Context is null", null)
      return true
    }

    storage = EncryptedStorage(projectId, context)
    return false
  }

  private fun loadItem(call: MethodCall, result: Result) {
    if (initStorageIfNeeded(call, result)) return
    val key = keyFromCall(call, result) ?: return
    val value = storage.loadItem(key)
    result.success(value)
  }

  private fun saveItem(call: MethodCall, result: Result) {
    if (initStorageIfNeeded(call, result)) return
    val key = keyFromCall(call, result) ?: return
    val data = dataFromCall(call, result) ?: return
    storage.saveItem(key, data)
    result.success(key)
  }

  private fun removeItem(call: MethodCall, result: Result) {
    if (initStorageIfNeeded(call, result)) return
    val key = keyFromCall(call, result) ?: return
    storage.removeItem(key)
    result.success(key)
  }

  private fun keyFromCall(call: MethodCall, result: Result) = stringFromCall("key", call, result)

  private fun dataFromCall(call: MethodCall, result: Result) = stringFromCall("data", call, result)

  private fun stringFromCall(key: String, call: MethodCall, result: Result): String? {
    val data = call.argument<String>(key)
    if (data == null) {
      result.error("MISSINGARGS", "'$key' argument is required", null)
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
    context = activityPluginBinding.getActivity()
  }

  override fun onDetachedFromActivityForConfigChanges() {
    context = null
  }

  override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
    context = activityPluginBinding.getActivity()
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

private class EncryptedStorage(name: String, context: Context) {
  private val masterKey = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
  private val sharedPreferences = EncryptedSharedPreferences.create(
    name,
    masterKey,
    context,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
  )

  fun loadItem(key: String): String? = sharedPreferences.getString(key, null)

  fun saveItem(key: String, data: String) = sharedPreferences.edit()
    .putString(key, data)
    .apply()

  fun removeItem(key: String) = sharedPreferences.edit()
    .remove(key)
    .apply()
}