import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '/src/internal/http/descope_client.dart';
import '/src/internal/http/responses.dart';
import '/src/internal/others/error.dart';
import '/src/internal/others/stubs/stub_html.dart' if (dart.library.js) 'dart:html' hide Platform;
import '/src/internal/routes/shared.dart';
import '/src/sdk/routes.dart';
import '/src/types/error.dart';
import '/src/types/flows.dart';
import '/src/types/responses.dart';

const _defaultRedirectURL = 'descopeauth://flow';
const _defaultContainerCss = {
  "background-color": "white",
  "width": "500px",
  "min-height": "300px",
  "margin": "auto",
  "position": "relative",
  "top": "50%",
  "transform": "translateY(-50%)",
  "display": "flex",
  "flex-direction": "column",
  "align-items": "center",
  "justify-content": "center",
  "box-shadow": "0px 0px 10px gray",
};
const _webComponentTag = 'descope-wc';
const _flowContainerClass = '.login-container';
const _eventReady = 'ready';
const _eventSuccess = 'success';
const _eventError = 'error';

class Flow extends DescopeFlow {
  static const _mChannel = MethodChannel('descope_flutter/methods');
  static const _eChannel = EventChannel('descope_flutter/events');
  static final _random = Random.secure();
  static final _sha256 = Sha256();

  final _htmlValidator = NodeValidatorBuilder.common()
    ..allowElement('style')
    ..allowElement('script', attributes: ['src'])
    ..allowElement(_webComponentTag, attributes: ['project-id', 'flow-id', 'base-url', 'locale', 'debug']);

  final DescopeClient client;
  _FlowRunner? _current;

  Flow(this.client);

  @override
  Future<AuthenticationResponse> start(DescopeFlowOptions options) async {
    // cancel any previous still running flows
    _cancelCurrentFlow();

    // prepare a new flow runner
    final runner = _FlowRunner(options);
    if (kIsWeb) {
      _startWebFlow(runner);
    } else {
      _startMobileFlow(runner);
    }

    // prepare completer for response and track current runner
    final completer = Completer<AuthenticationResponse>();
    runner._completer = completer;
    _current = runner;
    return completer.future;
  }

  @override
  Future<void> resume(Uri incomingUri) async {
    final runner = _current;
    if (runner == null) throw DescopeException.flowFailed.add(message: 'No flow to resume');
    final flowUrl = runner._options.mobile?.flowUrl;
    if (flowUrl == null) throw DescopeException.flowSetup.add(message: 'Resumed flow does not have a flow URL');

    // For some reason '#' are decoded in this string, need to re-encode
    // to correctly process query parameters
    incomingUri = Uri.parse(incomingUri.toString().replaceAll('#', '%23'));
    var uri = Uri.parse(flowUrl);
    uri = uri.replace(queryParameters: incomingUri.queryParameters);
    try {
      await _mChannel.invokeMethod('startFlow', {'url': uri.toString()});
    } on PlatformException {
      throw DescopeException.flowFailed.add(message: 'Flow resume failed');
    }
  }

  @override
  void exchange(Uri incomingUri) {
    final runner = _current;
    final codeVerifier = runner?._codeVerifier;
    final completer = runner?._completer;
    if (runner == null || codeVerifier == null || completer == null) {
      throw DescopeException.flowFailed.add(message: 'No flow pending exchange');
    }

    _current = null;
    final authorizationCode = incomingUri.queryParameters['code'];
    if (authorizationCode == null) {
      final e = DescopeException.flowFailed.add(message: 'No code parameter on incoming URI');
      completer.completeError(e);
      throw e;
    }

    _exchange(authorizationCode, codeVerifier, completer);
  }

  @override
  void cancel() {
    _cancelCurrentFlow();
  }

  // Internal

  Future<void> _startMobileFlow(_FlowRunner runner) async {
    final uri = await _prepareInitialRequest(runner);
    try {
      // invoke a platform method call
      await _mChannel.invokeMethod('startFlow', {'url': uri.toString()});
      _listenToEventsIfNeeded();
    } on PlatformException {
      throw DescopeException.flowFailed.add(message: 'Flow launch failed');
    }
  }

  void _startWebFlow(_FlowRunner runner) {
    final flowId = runner._options.web?.flowId;
    if (flowId == null) throw DescopeException.flowSetup.add(message: 'Web flows require a flow ID');

    // inject style and wc script into page
    _addFlowStyleToPage(runner);
    _addFlowScriptToPage();

    // create a login container
    var loginContainer = DivElement();
    loginContainer.className = "hidden-container";
    Element wc = Element.html('<descope-wc project-id=${client.config.projectId} flow-id=$flowId base-url=${client.baseUrl}/>', validator: _htmlValidator);
    loginContainer.children.add(wc);
    // loginContainer.children.add(loadingElement);
    document.body?.children.add(loginContainer);

    // js event listeners
    runner._readyListener = (Event event) {
      loginContainer.className = "login-container";
    };

    runner._successListener = (Event event) {
      final eventDetail = (event as CustomEvent).detail as Map<dynamic, dynamic>;
      final response = JWTServerResponse.fromJson(eventDetail.stringifyKeys());
      final completer = _current?._completer;
      _cleanupWebComponent();
      _current = null;
      completer?.complete(response.toAuthenticationResponse());
    };

    runner._errorListener = (Event event) {
      final eventDetail = (event as CustomEvent).detail as Map<dynamic, dynamic>;
      _completeWithError(DescopeException.flowFailed.add(message: eventDetail['errorMessage']));
    };

    wc.addEventListener(_eventReady, runner._readyListener);
    wc.addEventListener(_eventSuccess, runner._successListener);
    wc.addEventListener(_eventError, runner._errorListener);
  }

  void _addFlowStyleToPage(_FlowRunner runner) {
    var styleTag = '<style class="web-component-style">$_flowContainerClass {';
    final css = runner._options.web?.flowContainerCss ?? _defaultContainerCss;
    css.forEach((key, value) {
      styleTag += '$key: $value;';
    });
    styleTag += '}.hidden-container{display: none;}</style>';
    var style = Element.html(styleTag, validator: _htmlValidator);
    final existingStyle = querySelectorAll('.web-component-style');
    if (existingStyle.isNotEmpty) {
      existingStyle.first.remove();
    }
    document.head?.children.add(style);
  }

  void _addFlowScriptToPage() {
    // when the script version updates, search and remove any preexisting tags (currently none)
    // added only once
    if (querySelectorAll('.web-component-script-3-8-10').isEmpty) {
        var script = Element.html('<script src="https://cdn.jsdelivr.net/npm/@descope/web-component@3.8.10" class="web-component-script-3-8-10"></script>', validator: _htmlValidator);
        document.body?.children.add(script);
    }
  }

  void _listenToEventsIfNeeded() {
    if (!_isIOS()) {
      return;
    }
    StreamSubscription? subscription;
    subscription = _eChannel.receiveBroadcastStream().listen((event) {
      final str = event as String;
      switch (str) {
        case 'canceled':
          _completeWithError(DescopeException.flowCancelled.add(message: 'Flow canceled by user'));
          break;
        case '':
          _completeWithError(DescopeException.flowFailed.add(message: 'Unexpected error running flow'));
          break;
        default:
          try {
            final uri = Uri.parse(str);
            exchange(uri);
          } on Exception {
            _completeWithError(DescopeException.flowFailed.add(message: 'Unexpected URI received from flow'));
          }
      }
      subscription?.cancel();
    }, onError: (_) {
      _completeWithError(DescopeException.flowFailed.add(message: 'Authentication failed'));
      subscription?.cancel();
    });
  }

  void _cancelCurrentFlow() {
    _completeWithError(DescopeException.flowCancelled);
  }

  void _completeWithError(DescopeException exception) {
    _current?._completer?.completeError(exception);
    _cleanupWebComponent();
    _current = null;
  }

  void _cleanupWebComponent() {
    if (!kIsWeb) return;
    try {
      Element e = querySelectorAll(_webComponentTag).first;
      e.removeEventListener(_eventReady, _current?._readyListener);
      e.removeEventListener(_eventSuccess, _current?._successListener);
      e.removeEventListener(_eventError, _current?._successListener);
      Element container = querySelectorAll(_flowContainerClass).first;
      container.remove();
    } catch (ignored) {
      // any cleanup failures are silent
    }
  }

  Future<void> _exchange(String authorizationCode, String codeVerifier, Completer<AuthenticationResponse> completer) async {
    final authResponse = (await client.flowExchange(authorizationCode, codeVerifier)).toAuthenticationResponse();
    completer.complete(authResponse);
  }

  Future<Uri> _prepareInitialRequest(_FlowRunner runner) async {
    final flowUrl = runner._options.mobile?.flowUrl;
    if (flowUrl == null) throw DescopeException.flowSetup.add(message: 'Mobile flows require a flow URL');
    final randomBytes = _createRandomBytes();
    final hashedBytes = await _sha256.hash(randomBytes);

    final codeVerifier = base64UrlEncode(randomBytes);
    final codeChallenge = base64UrlEncode(hashedBytes.bytes);

    try {
      var uri = Uri.parse(flowUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['ra-callback'] = _isIOS() ? _defaultRedirectURL : (runner._options.mobile?.deepLinkUrl ?? _defaultRedirectURL);
      params['ra-challenge'] = codeChallenge;
      var initiator = _platformString();
      if (initiator != null) {
        params['ra-initiator'] = initiator;
      }

      uri = uri.replace(queryParameters: params);
      runner._codeVerifier = codeVerifier;
      return uri;
    } on Exception catch (e) {
      throw DescopeException.flowFailed.add(message: 'Invalid flow URL', cause: e);
    }
  }

  static List<int> _createRandomBytes([int length = 32]) {
    return List<int>.generate(length, (i) => _random.nextInt(256));
  }

  static String? _platformString() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    }
    return null;
  }

  static bool _isIOS() {
    return !kIsWeb && Platform.isIOS;
  }
}

class _FlowRunner {
  final DescopeFlowOptions _options;
  Completer<AuthenticationResponse>? _completer;

  // mobil facilities
  String? _codeVerifier;

  // web facilities
  EventListener? _readyListener;
  EventListener? _successListener;
  EventListener? _errorListener;

  _FlowRunner(this._options);
}

extension StringifyKeys on Map<dynamic, dynamic> {
  Map<String, dynamic> stringifyKeys() {
    final result = <String, dynamic>{};
    forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        result[key] = value.stringifyKeys();
      } else if (value != null) {
        result[key.toString()] = value;
      }
    });
    return result;
  }
}
