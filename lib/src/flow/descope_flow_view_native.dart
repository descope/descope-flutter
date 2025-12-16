import 'dart:io';

import 'package:descope/src/internal/http/responses.dart';
import 'package:descope/src/internal/others/error.dart';
import 'package:descope/src/internal/routes/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/src/sdk/sdk.dart';
import '/src/types/error.dart';
import '/src/flow/descope_flow_callbacks.dart';
import '/src/flow/descope_flow_config.dart';

/// The [DescopeFlowController] class can be used to programmatically interact with a [DescopeFlowView].
/// Currently the only supported operation is to handle deep links that are received by the application.
class DescopeFlowController {
  _DescopeFlowViewState? _state;

  void _attach(_DescopeFlowViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  /// Call this function when the application receives a deep link that should be
  /// handled by the flow.
  void resumeFromDeepLink(Uri uri) {
    _state?._resumeFromDeepLink(uri);
  }
}


/// Authenticate a user using Descope Flows.
///
/// Embed this view into your UI to be able to run flows built with the
/// [Descope Flow builder](https://app.descope.com/flows). Provide the [DescopeFlowConfig] to set up the flow,
/// and [DescopeFlowCallbacks] to know when the Flow is `ready` to be presented, and finished in a `success` or `error` state.
///
/// **General Setup**
///
/// - As a prerequisite, the flow itself must be defined and hosted.
/// It's possible to use Descope's auth hosting solution, or host it
/// yourself. Read more [here.](https://docs.descope.com/auth-hosting-app)
///
/// - To use the Descope authentication methods, it is required
/// to configure the desired authentication methods in the [Descope console.](https://app.descope.com/settings/authentication)
/// Some of the default configurations might be OK to start out with,
/// but it is likely that modifications will be required before release.
///
/// **iOS Setup**
///
/// - It is possible for users to authenticate using their Apple account.
/// The authentication presents a native dialog that lets
/// the user sign in with the Apple ID they're already using on their device.
/// The Sign in with Apple APIs require some setup in your Xcode project, including
/// at the very least adding the `Sign in with Apple` capability. You will also need
/// to configure the Apple provider in the [Descope console](https://app.descope.com/settings/authentication/social).
/// In particular, when using your own account make sure that the `Client ID` value
/// matches the Bundle Identifier of your app.
///
/// - In order to use navigation / redirection based authentication,
/// namely `Magic Link`, the app must make sure the link redirects back
/// to the app. Read more on [universal links](https://developer.apple.com/ios/universal-links/)
/// to learn more. Make sure to set [DescopeFlowView.controller], and once redirected back to the app,
/// call the [DescopeFlowController.resumeFromDeepLink] function.
///
/// **Android Setup**
///
/// - **IMPORTANT NOTE**: even though Application links are the recommended way to configure
/// deep links, some browsers, such as Opera, do not honor them and open the URLs inline.
/// It is possible to circumvent this issue by using a custom scheme, albeit less secure.
///
/// - Beyond that, in order to use navigation / redirection based authentication,
/// namely `Magic Link`, `OAuth (social)` and SSO, it's required to set up app links.
/// App Links allow the application to receive navigation to specific URLs,
/// instead of opening the browser. Follow the [Android official documentation](https://developer.android.com/training/app-links)
/// to set up App link in your application. Make sure to set [DescopeFlowView.controller], and once redirected back to the app,
/// call the [DescopeFlowController.resumeFromDeepLink] function.
///
/// - Finally, it is possible for users to authenticate using the Google account or accounts they are logged into
/// on their Android devices. If you haven't already configured your app to support `Sign in with Google` you'll
/// probably need to set up your [Google APIs console project](https://developer.android.com/identity/sign-in/credential-manager-siwg#set-google)
/// for this. You should also configure an OAuth provider for Google in the in the [Descope console](https://app.descope.com/settings/authentication/social),
/// with its `Grant Type` set to `Implicit`. Also note that the `Client ID` and
/// `Client Secret` should be set to the values of your `Web application` OAuth client,
/// rather than those from the `Android` OAuth client.
/// For more details about configuring your app see the [Credential Manager documentation](https://developer.android.com/identity/sign-in/credential-manager).
class DescopeFlowView extends StatefulWidget {
  final DescopeFlowConfig config;
  final DescopeFlowCallbacks? callbacks;
  final DescopeFlowController? controller;

  const DescopeFlowView({
    super.key,
    required this.config,
    this.callbacks,
    this.controller,
  });

  @override
  State<DescopeFlowView> createState() => _DescopeFlowViewState();
}

class _DescopeFlowViewState extends State<DescopeFlowView> {

  static const String _viewType = 'descope_flutter/descope_flow_view';

  MethodChannel? _channel;
  DescopeFlowController? get _controller => _isMobilePlatform() ? widget.controller : null;

  // State implementation

  @override
  Widget build(BuildContext context) {
    // only supported on mobile platforms
    if (_rejectNonMobilePlatform()) return const SizedBox.shrink();

    final params = <String, dynamic>{
      'url': widget.config.url,
      'androidOAuthNativeProvider': widget.config.androidOAuthNativeProvider,
      'iosOAuthNativeProvider': widget.config.iosOAuthNativeProvider,
      'oauthRedirect': widget.config.oauthRedirect,
      'oauthRedirectCustomScheme': widget.config.oauthRedirectCustomScheme,
      'ssoRedirect': widget.config.ssoRedirect,
      'ssoRedirectCustomScheme': widget.config.ssoRedirectCustomScheme,
      'magicLinkRedirect': widget.config.magicLinkRedirect,
      'sdkVersion': DescopeSdk.version,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller?._attach(this);
  }

  @override
  void dispose() {
    _controller?._detach();
    super.dispose();
  }

  // Internal

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('com.descope.flow/view_$id');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onReady':
          widget.callbacks?.onReady?.call();
          break;
        case 'onSuccess':
          try {
            final payload = _coercePayload(call.arguments);
            final authenticationResponse = JWTServerResponse.fromJson(payload).toAuthenticationResponse();
            widget.callbacks?.onSuccess?.call(authenticationResponse);
          } catch (e) {
            widget.callbacks?.onError?.call(DescopeException.flowFailed.add(message: "Unexpected success payload", cause: e));
            return;
          }
          break;
        case 'onError':
          DescopeException error;
          try {
            final payload = _coercePayload(call.arguments);
            var code = payload['code'] as String;
            var desc = payload['desc'] as String;
            var message = payload['message'] as String?;
            error = DescopeException(code: code, desc: desc, message: message);
          } catch (e) {
            error = DescopeException.flowFailed.add(message: "Unexpected error payload", cause: e);
          }
          widget.callbacks?.onError?.call(error);
          break;
      }
    });
  }

  void _resumeFromDeepLink(Uri uri) {
    // only supported on mobile platforms
    if (_rejectNonMobilePlatform()) return;
    // unfortunately the URI encoding may be unpredictable, as Flutter seems to
    // pass the URL with only '#' unencoded, while all other characters seem to remain percent encoded.
    // re-encoding the entire URI doesn't solve this, at least at the time of writing,
    // so manual fixing of this bug is required before passing it to the native side.
    final url = uri.toString().replaceAll("#", "%23");
    _channel?.invokeMethod("resumeFromDeepLink", {'url': url});
  }

  bool _rejectNonMobilePlatform() {
    if (!_isMobilePlatform()) {
      widget.callbacks?.onError?.call(
        DescopeException.flowFailed.add(message: 'DescopeFlowView is only supported on Android and iOS'),
      );
      return true;
    }
    return false;
  }
}

// Utilities

// Coerce the payload into a [Map<String, dynamic>] if possible, otherwise return an empty map.
// This is recursively done, to ensure that all keys are strings, and all values are JSON compatible.
Map<String, dynamic> _coercePayload(Object? raw) {
  final coerced = _coerceValue(raw);
  return coerced is Map<String, dynamic> ? coerced : const <String, dynamic>{};
}

dynamic _coerceValue(Object? value) {
  if (value == null) return null;

  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) {
      if (k != null) {
        out[k.toString()] = _coerceValue(v);
      }
    });
    return out;
  }

  if (value is List) {
    return value.map((e) => _coerceValue(e)).toList(growable: false);
  }

  // Primitive or other types are returned as-is.
  return value;
}

bool _isMobilePlatform() {
  return Platform.isAndroid || Platform.isIOS;
}
