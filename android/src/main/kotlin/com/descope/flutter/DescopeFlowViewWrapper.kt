package com.descope.flutter

import android.content.Context
import android.view.View
import androidx.core.net.toUri
import com.descope.android.DescopeFlow
import com.descope.android.DescopeFlowHook
import com.descope.android.DescopeFlowView
import com.descope.android.runJavaScript
import com.descope.types.AuthenticationResponse
import com.descope.types.DescopeException
import com.descope.types.DescopeUser
import com.descope.types.OAuthProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.collections.toMap

class DescopeFlowViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return DescopeFlowViewWrapper(context, viewId, args, messenger)
    }
}

class DescopeFlowViewWrapper(
    private val context: Context,
    private val id: Int,
    private val args: Any?,
    private val messenger: BinaryMessenger
) : PlatformView, MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.descope.flow/view_$id").apply {
        setMethodCallHandler(this@DescopeFlowViewWrapper)
    }

    private val flowView = DescopeFlowView(context).apply {
        // init DescopeFlow from args
        val descopeFlow = args.toDescopeFlow()

        // pipe listener callbacks through a flutter channel
        listener = object : DescopeFlowView.Listener {
            override fun onReady() {
                channel.invokeMethod("onReady", null)
            }

            override fun onSuccess(response: AuthenticationResponse) {
                try {
                    channel.invokeMethod("onSuccess", response.toMap())
                } catch (e: Exception) {
                    channel.invokeMethod("onError", DescopeException("flutter_error", "Error in onSuccess callback", e.message).toMap())
                }
            }

            override fun onError(exception: DescopeException) {
                channel.invokeMethod("onError", exception.toMap())
            }
        }

        startFlow(descopeFlow)
    }

    // PlatformView implementation

    override fun getView(): View = flowView

    override fun dispose() {
        flowView.listener = null
        channel.setMethodCallHandler(null)
    }

    // MethodCallHandler implementation

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "resumeFromDeepLink" -> resumeFromDeepLink(call, result)
            else -> result.notImplemented()
        }
    }

    private fun resumeFromDeepLink(call: MethodCall, result: Result) {
        val url = call.argument<String>("url") ?: return result.error("MISSINGARGS", "'url' is required for resumeFromDeepLink", null)
        try {
            flowView.resumeFromDeepLink(url.toUri())
            result.success(url)
        } catch (ignored: Exception) {
            result.error("INVALIDARGS", "url argument is invalid", null)
        }
    }

}

fun Any?.toDescopeFlow(): DescopeFlow {
    val map = this as? Map<*, *> ?: throw IllegalArgumentException("Flow options are required")
    val url = map["url"] as? String ?: throw IllegalArgumentException("Flow URL is required")
    val sdkVersion = map["sdkVersion"] as? String ?: throw IllegalArgumentException("SDK version is required")
    return DescopeFlow(url).apply {
        (map["androidOAuthNativeProvider"] as? String)?.let { oauthNativeProvider = OAuthProvider(name = it) }
        (map["oauthRedirect"] as? String)?.let { oauthRedirect = it }
        (map["oauthRedirectCustomScheme"] as? String)?.let { oauthRedirectCustomScheme = it }
        (map["ssoRedirect"] as? String)?.let { ssoRedirect = it }
        (map["ssoRedirectCustomScheme"] as? String)?.let { ssoRedirectCustomScheme = it }
        (map["magicLinkRedirect"] as? String)?.let { magicLinkRedirect = it }
        hooks = listOf(
            runJavaScript(DescopeFlowHook.Event.Loaded, """
                window.descopeBridge.hostInfo.sdkName = 'flutter'
                window.descopeBridge.hostInfo.sdkVersion = '$sdkVersion'
            """),
        )
    }
}

// Utilities

private fun AuthenticationResponse.toMap(): Map<String, Any> = mutableMapOf(
    "sessionJwt" to sessionToken.jwt,
    "refreshJwt" to refreshToken.jwt,
    "user" to user.toMap(),
    "firstSeen" to isFirstAuthentication
)

private fun DescopeUser.toMap() = mutableMapOf<String, Any>().apply {
    put("userId", userId)
    put("loginIds", loginIds)
    name?.let { put("name", it) }
    picture?.let { put("picture", it.toString()) }
    email?.let { put("email", it) }
    put("verifiedEmail", isVerifiedEmail)
    phone?.let { put("phone", it) }
    put("verifiedPhone", isVerifiedPhone)
    put("createdTime", createdAt)
    put("customAttributes", customAttributes)
    givenName?.let { put("givenName", it) }
    middleName?.let { put("middleName", it) }
    familyName?.let { put("familyName", it) }
    put("password", authentication.password)
    put("status", status.serialize())
    put("roleNames", authorization.roles.toList())
    put("ssoAppIds", authorization.ssoAppIds.toList())
    put("OAuth", mutableMapOf<String, Boolean>().apply {
        authentication.oauth.forEach { this[it] = true }
    })
}

private fun DescopeException.toMap(): Map<String, Any> = mutableMapOf<String, Any>().apply {
    put("code", code)
    put("desc", desc)
    message?.let { put("message", it) }
}
