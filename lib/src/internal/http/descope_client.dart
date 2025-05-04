import 'dart:convert';

import 'package:descope/src/internal/others/system_info.dart';

import '/src/internal/others/error.dart';
import '/src/sdk/config.dart';
import '/src/sdk/sdk.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import 'http_client.dart';
import 'responses.dart';

class DescopeClient extends HttpClient {
  final DescopeConfig config;

  DescopeClient(this.config) : super(config.baseUrl ?? baseUrlForProjectId(config.projectId), config.logger, config.networkClient);

  // OTP

  Future<MaskedAddressServerResponse> otpSignUp(DeliveryMethod method, String loginId, SignUpDetails? details) {
    return post('auth/otp/signup/${method.name}', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
    });
  }

  Future<MaskedAddressServerResponse> otpSignIn(DeliveryMethod method, String loginId, SignInOptions? options) {
    return post('auth/otp/signin/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'loginOptions': options?.toMap(),
    });
  }

  Future<MaskedAddressServerResponse> otpSignUpIn(DeliveryMethod method, String loginId, SignInOptions? options) {
    return post('auth/otp/signup-in/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'loginOptions': options?.toMap(),
    });
  }

  Future<JWTServerResponse> otpVerify(DeliveryMethod method, String loginId, String code) {
    return post('auth/otp/verify/${method.name}', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'code': code,
    });
  }

  Future<MaskedAddressServerResponse> otpUpdateEmail(String email, String loginId, String refreshJwt, UpdateOptions? options) {
    return post('auth/otp/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'addToLoginIDs': options?.addToLoginIds,
      'onMergeUseExisting': options?.onMergeUseExisting,
    });
  }

  Future<MaskedAddressServerResponse> otpUpdatePhone(String phone, DeliveryMethod method, String loginId, String refreshJwt, UpdateOptions? options) {
    method.ensurePhoneMethod();
    return post('auth/otp/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
      'addToLoginIDs': options?.addToLoginIds,
      'onMergeUseExisting': options?.onMergeUseExisting,
    });
  }

  // TOTP

  Future<TotpServerResponse> totpSignUp(String loginId, SignUpDetails? details) {
    return post('auth/totp/signup', TotpServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
    });
  }

  Future<JWTServerResponse> totpVerify(String loginId, String code, SignInOptions? options) {
    return post('auth/totp/verify', JWTServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'code': code,
      'loginOptions': options?.toMap(),
    });
  }

  Future<TotpServerResponse> totpUpdate(String loginId, String refreshJwt) {
    return post('auth/totp/update', TotpServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
    });
  }

  // Password

  Future<JWTServerResponse> passwordSignUp(String loginId, String password, SignUpDetails? details) {
    return post('auth/password/signup', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'password': password,
      'user': details?.toMap(),
    });
  }

  Future<JWTServerResponse> passwordSignIn(String loginId, String password) {
    return post('auth/password/signin', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'password': password,
    });
  }

  Future<void> passwordUpdate(String loginId, String newPassword, String refreshJwt) {
    return post('auth/password/update', emptyResponse, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'newPassword': newPassword,
    });
  }

  Future<JWTServerResponse> passwordReplace(String loginId, String oldPassword, String newPassword) {
    return post('auth/password/replace', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> passwordSendReset(String loginId, String? redirectUrl) {
    return post('auth/password/reset', emptyResponse, body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
    });
  }

  Future<PasswordPolicyServerResponse> passwordGetPolicy() {
    return get('auth/password/policy', PasswordPolicyServerResponse.decoder);
  }

  // Magic Link

  Future<MaskedAddressServerResponse> magicLinkSignUp(DeliveryMethod method, String loginId, SignUpDetails? details, String? redirectUrl) {
    return post('auth/magiclink/signup/${method.name})', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
      'redirectUrl': redirectUrl,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkSignIn(DeliveryMethod method, String loginId, String? redirectUrl, SignInOptions? options) {
    return post('auth/magiclink/signin/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
      'loginOptions': options?.toMap(),
    });
  }

  Future<MaskedAddressServerResponse> magicLinkSignUpOrIn(DeliveryMethod method, String loginId, String? redirectUrl, SignInOptions? options) {
    return post('auth/magiclink/signup-in/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
      'loginOptions': options?.toMap(),
    });
  }

  Future<JWTServerResponse> magicLinkVerify(String token) {
    return post('auth/magiclink/verify', JWTServerResponse.decoder, body: {
      'token': token,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkUpdateEmail(String email, String loginId, String? redirectUrl, String refreshJwt, UpdateOptions? options) {
    return post('auth/magiclink/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'redirectUrl': redirectUrl,
      'addToLoginIDs': options?.addToLoginIds,
      'onMergeUseExisting': options?.onMergeUseExisting,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkUpdatePhone(String phone, DeliveryMethod method, String loginId, String? redirectUrl, String refreshJwt, UpdateOptions? options) {
    method.ensurePhoneMethod();
    return post('auth/magiclink/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
      'redirectUrl': redirectUrl,
      'addToLoginIDs': options?.addToLoginIds,
      'onMergeUseExisting': options?.onMergeUseExisting,
    });
  }

  // Enchanted Link

  Future<EnchantedLinkServerResponse> enchantedLinkSignUp(String loginId, SignUpDetails? details, String? redirectUrl) {
    return post('auth/enchantedlink/signup/email', EnchantedLinkServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
      'redirectUrl': redirectUrl,
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkSignIn(String loginId, String? redirectUrl, SignInOptions? options) {
    return post('auth/enchantedlink/signin/email', EnchantedLinkServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
      'loginOptions': options?.toMap(),
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkSignUpOrIn(String loginId, String? redirectUrl, SignInOptions? options) {
    return post('auth/enchantedlink/signup-in/email', EnchantedLinkServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
      'loginOptions': options?.toMap(),
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkUpdateEmail(String email, String loginId, String? redirectUrl, String refreshJwt, UpdateOptions? options) {
    return post('auth/enchantedlink/update/email', EnchantedLinkServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'redirectUrl': redirectUrl,
      'addToLoginIDs': options?.addToLoginIds,
      'onMergeUseExisting': options?.onMergeUseExisting,
    });
  }

  Future<JWTServerResponse> enchantedLinkPendingSession(String pendingRef) {
    return post('auth/enchantedlink/pending-session', JWTServerResponse.decoder, body: {
      'pendingRef': pendingRef,
    });
  }

  // OAuth

  Future<OAuthServerResponse> oauthWebStart(OAuthProvider provider, String? redirectUrl, SignInOptions? options) {
    return post('auth/oauth/authorize', OAuthServerResponse.decoder, headers: authorization(options?.refreshJwt), params: {
      'provider': provider.name,
      'redirectUrl': redirectUrl,
    }, body: options?.toMap() ?? {});
  }

  Future<JWTServerResponse> oauthWebExchange(String code) {
    return post('auth/oauth/exchange', JWTServerResponse.decoder, body: {
      'code': code,
    });
  }

  Future<OAuthNativeStartServerResponse> oauthNativeStart(OAuthProvider provider, SignInOptions? options) {
    return post('auth/oauth/native/start', OAuthNativeStartServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'provider': provider.name,
      'loginOptions': options?.toMap(),
    });
  }

  Future<JWTServerResponse> oauthNativeFinish(OAuthProvider provider, String stateId, String? user, String? authorizationCode, String? identityToken) {
    return post('auth/oauth/native/finish', JWTServerResponse.decoder, body: {
      'provider': provider.name,
      'stateId': stateId,
      'user': user,
      'code': authorizationCode,
      'idToken': identityToken,
    });
  }

  // SSO

  Future<SsoServerResponse> ssoStart(String emailOrTenantId, String? redirectUrl, SignInOptions? options) {
    return post('auth/saml/authorize', SsoServerResponse.decoder,
        headers: authorization(options?.refreshJwt),
        params: {
          'tenant': emailOrTenantId,
          'redirectUrl': redirectUrl,
        },
        body: options?.toMap() ?? {});
  }

  Future<JWTServerResponse> ssoExchange(String code) {
    return post('auth/saml/exchange', JWTServerResponse.decoder, body: {
      'code': code,
    });
  }

  // Passkeys

  Future<PasskeyStartServerResponse> passkeySignUpStart(String loginId, SignUpDetails? details, String origin) {
    return post('auth/webauthn/signup/start', PasskeyStartServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
      'origin': origin,
    });
  }

  Future<JWTServerResponse> passkeySignUpFinish(String transactionId, String response) {
    return post('auth/webauthn/signup/finish', JWTServerResponse.decoder, body: {
      'transactionId': transactionId,
      'response': response,
    });
  }

  Future<PasskeyStartServerResponse> passkeySignInStart(String loginId, String origin, SignInOptions? options) {
    return post('auth/webauthn/signin/start', PasskeyStartServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'origin': origin,
      'loginOptions': options?.toMap(),
    });
  }

  Future<JWTServerResponse> passkeySignInFinish(String transactionId, String response) {
    return post('auth/webauthn/signin/finish', JWTServerResponse.decoder, body: {
      'transactionId': transactionId,
      'response': response,
    });
  }

  Future<PasskeyStartServerResponse> passkeySignUpInStart(String loginId, String origin, SignInOptions? options) {
    return post('auth/webauthn/signup-in/start', PasskeyStartServerResponse.decoder, headers: authorization(options?.refreshJwt), body: {
      'loginId': loginId,
      'origin': origin,
      'loginOptions': options?.toMap(),
    });
  }

  Future<PasskeyStartServerResponse> passkeyAddStart(String loginId, String origin, String refreshJwt) {
    return post('auth/webauthn/update/start', PasskeyStartServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'origin': origin,
    });
  }

  Future<void> passkeyAddFinish(String transactionId, String response) {
    return post('auth/webauthn/update/finish', emptyResponse, body: {
      'transactionId': transactionId,
      'response': response,
    });
  }

  // Flows

  Future<JWTServerResponse> flowExchange(String authorizationCode, String codeVerifier) {
    return post('flow/exchange', JWTServerResponse.decoder, body: {
      'authorizationCode': authorizationCode,
      'codeVerifier': codeVerifier,
    });
  }

  // Others

  Future<UserResponse> me(String refreshJwt) {
    return get('auth/me', UserResponse.decoder, headers: authorization(refreshJwt));
  }

  Future<JWTServerResponse> refresh(String refreshJwt) {
    return post('auth/refresh', JWTServerResponse.decoder, headers: authorization(refreshJwt));
  }

  Future<void> logout(RevokeType revokeType, String refreshJwt) {
    final route = revokeType == RevokeType.currentSession ? 'auth/logout' : 'auth/logoutall';
    return post(route, emptyResponse, headers: authorization(refreshJwt));
  }

  // Internal

  @override
  String get basePath => '/v1/';

  @override
  Future<Map<String, String>> get defaultHeaders async {
    final values = {
      'Authorization': 'Bearer ${config.projectId}',
      'x-descope-sdk-name': 'flutter',
      'x-descope-sdk-version': DescopeSdk.version,
      'x-descope-project-id': config.projectId,
    };
    final systemInfo = await SystemInfo.get();
    if (systemInfo.platformName.isNotEmpty) {
      values['x-descope-platform-name'] = systemInfo.platformName;
    }
    if (systemInfo.platformVersion.isNotEmpty) {
      values['x-descope-platform-version'] = systemInfo.platformVersion;
    }
    if (systemInfo.appName.isNotEmpty) {
      values['x-descope-app-name'] = systemInfo.appName;
    }
    if (systemInfo.appVersion.isNotEmpty) {
      values['x-descope-app-version'] = systemInfo.appVersion;
    }
    if (systemInfo.device.isNotEmpty) {
      values['x-descope-device'] = systemInfo.device;
    }
    return values;
  }

  @override
  DescopeException? exceptionFromResponse(String response) {
    try {
      final json = jsonDecode(response) as Map<String, dynamic>;
      var code = json['errorCode'] as String;
      var desc = json['errorDescription'] as String?;
      var message = json['errorMessage'] as String?;
      return DescopeException(code: code, desc: desc ?? 'Descope server error', message: message);
    } catch (e) {
      return null;
    }
  }

  Map<String, String> authorization(String? value) {
    return value != null ? {'Authorization': 'Bearer ${config.projectId}:$value'} : {};
  }
}

String baseUrlForProjectId(String projectId) {
  const prefix = 'https://api';
  const suffix = 'descope.com';
  if (projectId.length >= 32) {
    final region = projectId.substring(1, 5);
    return '$prefix.$region.$suffix';
  } else {
    return '$prefix.$suffix';
  }
}

extension on SignInOptions {
  String? get refreshJwt => stepupRefreshJwt ?? mfaRefreshJwt;

  Map<String, dynamic> toMap() {
    return {
      'stepup': stepupRefreshJwt != null ? true : null,
      'mfa': mfaRefreshJwt != null ? true : null,
      'customClaims': customClaims.isNotEmpty ? customClaims : null,
      'revokeOtherSessions': revokeOtherSessions,
    };
  }
}

extension on SignUpDetails {
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'name': name,
      'givenName': givenName,
      'middleName': middleName,
      'familyName': familyName,
    };
  }
}

extension on DeliveryMethod {
  ensurePhoneMethod() {
    if (this != DeliveryMethod.sms && this != DeliveryMethod.whatsapp) {
      throw DescopeException.invalidArguments.add(message: 'Update phone can be done using SMS or WhatsApp only');
    }
  }
}
