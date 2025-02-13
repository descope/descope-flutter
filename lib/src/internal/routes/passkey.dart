
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '/src/internal/http/descope_client.dart';
import '/src/internal/others/error.dart';
import '/src/internal/routes/shared.dart';
import '/src/internal/others/web_passkeys.dart';
import '/src/sdk/routes.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';

class Passkey implements DescopePasskey {
  static const _mChannel = MethodChannel('descope_flutter/methods');

  final DescopeClient client;
  final _webPasskeys = WebPasskeys();

  Passkey(this.client);

  @override
  Future<bool> isSupported() async {
    try {
      if (kIsWeb) {
        return _webPasskeys.isSupported();
      } else if (Platform.isIOS || Platform.isAndroid) {
        return await _mChannel.invokeMethod('passkeySupported', {});
      } else {
        return false;
      }
    } on Exception {
      throw DescopeException.passkeyFailed.add(message: 'Failed to determine if passkeys are supported');
    }
  }

  @override
  Future<AuthenticationResponse> signUp({required String loginId, SignUpDetails? details}) async {
    _ensureSupportedPlatform();

    final origin = await getOrigin();
    final startResponse = await client.passkeySignUpStart(loginId, details, origin);
    final passkeyResponse = await nativeOrWebPasskey(startResponse.options, true);

    final jwtResponse = await client.passkeySignUpFinish(startResponse.transactionId, passkeyResponse);
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> signIn({required String loginId, SignInOptions? options}) async {
    _ensureSupportedPlatform();

    final origin = await getOrigin();
    final startResponse = await client.passkeySignInStart(loginId, origin, options);
    final passkeyResponse = await nativeOrWebPasskey(startResponse.options, false);

    final jwtResponse = await client.passkeySignInFinish(startResponse.transactionId, passkeyResponse);
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> signUpOrIn({required String loginId, SignInOptions? options}) async {
    _ensureSupportedPlatform();

    final origin = await getOrigin();
    final startResponse = await client.passkeySignUpInStart(loginId, origin, options);
    final passkeyResponse = await nativeOrWebPasskey(startResponse.options, startResponse.create);

    final jwtResponse = startResponse.create
        ? (await client.passkeySignUpFinish(startResponse.transactionId, passkeyResponse))
        : (await client.passkeySignInFinish(startResponse.transactionId, passkeyResponse));
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<void> add({required String loginId, required String refreshJwt}) async {
    _ensureSupportedPlatform();

    final origin = await getOrigin();
    final startResponse = await client.passkeyAddStart(loginId, origin, refreshJwt);
    final nativeResponse = await nativeOrWebPasskey(startResponse.options, true);

    return client.passkeyAddFinish(startResponse.transactionId, nativeResponse);
  }

  // Internal

  Future<String> getOrigin() async {
    try {
      if (kIsWeb) {
        // web origin
        return _webPasskeys.getOrigin();
      } else {
        // native origin
        final result = await _mChannel.invokeMethod('passkeyOrigin', {});
        return result as String;
      }
    } on Exception {
      throw DescopeException.passkeyFailed.add(message: 'Failed to determine passkey origin');
    }
  }

  Future<String> nativeOrWebPasskey(String options, bool create) async {
    if (kIsWeb) {
      return await _webPasskeys.passkey(options, create);
    }
    return nativePasskey(options, create);
  }

  Future<String> nativePasskey(String options, bool create) async {
    dynamic result;
    try {
      final method = create ? 'passkeyCreate' : 'passkeyAuthenticate';
      result = await _mChannel.invokeMethod(method, {'options': options});
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'CANCELLED': throw DescopeException.passkeyCancelled;
        default: throw DescopeException.passkeyFailed.add(message: e.message ?? 'Failed to call native code');
      }
    }
    if (result == null) {
      throw DescopeException.passkeyFailed.add(message: 'Received empty Passkey response');
    }
    try {
      return result as String;
    } on Exception {
      throw DescopeException.passkeyFailed.add(message: 'Received invalid Passkey response');
    }
  }

}

void _ensureSupportedPlatform() {
  if (kIsWeb || Platform.isIOS || Platform.isAndroid) return;
  throw DescopeException.passkeyFailed.add(message: 'Feature not supported on this platform');
}
