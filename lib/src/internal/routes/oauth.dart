import 'dart:convert';

import 'package:flutter/services.dart';

import '/src/internal/http/descope_client.dart';
import '/src/internal/others/error.dart';
import '/src/sdk/routes.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import 'shared.dart';

class OAuth implements DescopeOAuth {
  static const _mChannel = MethodChannel('descope_flutter/methods');

  final DescopeClient client;

  OAuth(this.client);

  @override
  Future<String> start({required OAuthProvider provider, String? redirectUrl, SignInOptions? options}) async {
    return (await client.oauthWebStart(provider, redirectUrl, options)).url;
  }

  @override
  Future<AuthenticationResponse> exchange({required String code}) async {
    return (await client.oauthWebExchange(code)).toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> native({required OAuthProvider provider, SignInOptions? options}) async {
    ensureMobilePlatform(DescopeException.oauthNativeFailed);

    final startResponse = await client.oauthNativeStart(provider, options);
    final nativeResponse = await callNative(startResponse.clientId, startResponse.nonce, startResponse.implicit);

    final user = nativeResponse['user'] as String?;
    final authorizationCode = nativeResponse['authorizationCode'] as String?;
    final identityToken = nativeResponse['identityToken'] as String?;

    final jwtResponse = await client.oauthNativeFinish(provider, startResponse.stateId, user, authorizationCode, identityToken);
    return jwtResponse.toAuthenticationResponse();
  }

  Future<Map<String, dynamic>> callNative(String clientId, String nonce, bool implicit) async {
    dynamic result;
    try {
      result = await _mChannel.invokeMethod('oauthNative', {
        'clientId': clientId,
        'nonce': nonce,
        'implicit': implicit
      });
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'CANCELLED': throw DescopeException.oauthNativeCancelled;
        default: throw DescopeException.oauthNativeFailed.add(message: e.message ?? 'Failed to call native code');
      }
    }
    if (result == null) {
      throw DescopeException.oauthNativeFailed.add(message: 'Received empty OAuth response');
    }
    try {
      final serialized = result as String;
      return jsonDecode(serialized);
    } on Exception {
      throw DescopeException.oauthNativeFailed.add(message: 'Received invalid OAuth response');
    }
  }
}
