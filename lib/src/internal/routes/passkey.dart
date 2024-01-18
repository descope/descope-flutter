
import 'package:flutter/services.dart';

import '/src/internal/http/descope_client.dart';
import '/src/internal/others/error.dart';
import '/src/internal/routes/shared.dart';
import '/src/sdk/routes.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';

class Passkey implements DescopePasskey {
  static const _mChannel = MethodChannel('descope_flutter/methods');

  final DescopeClient client;

  Passkey(this.client);

  @override
  Future<AuthenticationResponse> signUp({required String loginId, SignUpDetails? details}) async {
    ensureMobilePlatform(DescopeException.passkeyFailed);

    final origin = await getNativeOrigin();
    final startResponse = await client.passkeySignUpStart(loginId, details, origin);
    final nativeResponse = await nativePasskey(startResponse.options, true);

    final jwtResponse = await client.passkeySignUpFinish(startResponse.transactionId, nativeResponse);
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> signIn({required String loginId, SignInOptions? options}) async {
    ensureMobilePlatform(DescopeException.passkeyFailed);

    final origin = await getNativeOrigin();
    final startResponse = await client.passkeySignInStart(loginId, origin, options);
    final nativeResponse = await nativePasskey(startResponse.options, false);

    final jwtResponse = await client.passkeySignInFinish(startResponse.transactionId, nativeResponse);
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> signUpOrIn({required String loginId, SignInOptions? options}) async {
    ensureMobilePlatform(DescopeException.passkeyFailed);

    final origin = await getNativeOrigin();
    final startResponse = await client.passkeySignUpInStart(loginId, origin, options);
    final nativeResponse = await nativePasskey(startResponse.options, startResponse.create);

    final jwtResponse = startResponse.create
        ? (await client.passkeySignUpFinish(startResponse.transactionId, nativeResponse))
        : (await client.passkeySignInFinish(startResponse.transactionId, nativeResponse));
    return jwtResponse.toAuthenticationResponse();
  }

  @override
  Future<void> add({required String loginId, required String refreshJwt}) async {
    ensureMobilePlatform(DescopeException.passkeyFailed);

    final origin = await getNativeOrigin();
    final startResponse = await client.passkeyAddStart(loginId, origin, refreshJwt);
    final nativeResponse = await nativePasskey(startResponse.options, true);

    return client.passkeyAddFinish(startResponse.transactionId, nativeResponse);
  }

  // Internal

  Future<String> getNativeOrigin() async {
    try {
      final result = await _mChannel.invokeMethod('passkeyOrigin', {});
      return result as String;
    } on Exception {
      throw DescopeException.passkeyFailed.add(message: 'Failed to determine passkey origin');
    }
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
