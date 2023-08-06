package com.descope.flutter

import android.content.Context
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent

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

  // MethodCallHandler
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "start" -> launchUrl(call.argument<String>("url"), result)
      else -> result.notImplemented()
    }
  }

  private fun launchUrl(url: String?, result: Result) {
    val context = this.context ?: return result.error("NULLCONTEXT", "Context is null", null)
    val url = url ?: return result.error("MISSINGURL", "url argument is null", null)
    try {
      val uri = Uri.parse(url)
      launchUri(context, uri)
      result.success(url)
    } catch (ignored: Exception) {
      result.error("INVALIDURL", "url argument is invalid", null)
    }
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
