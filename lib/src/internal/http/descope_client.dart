import 'package:descope/src/internal/others/error.dart';

import '/src/sdk/config.dart';
import '/src/sdk/sdk.dart';
import '/src/types/error.dart';
import '/src/types/others.dart';
import 'http_client.dart';
import 'responses.dart';

class DescopeClient extends HttpClient {
  final DescopeConfig config;

  DescopeClient(this.config) : super(config.baseUrl);

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

  Future<MaskedAddressServerResponse> otpUpdateEmail(String email, String loginId, String refreshJwt) {
    return post('auth/otp/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
    });
  }

  Future<MaskedAddressServerResponse> otpUpdatePhone(String phone, DeliveryMethod method, String loginId, String refreshJwt) {
    method.ensurePhoneMethod();
    return post('auth/otp/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
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

  Future<void> passwordReplace(String loginId, String oldPassword, String newPassword) {
    return post('auth/password/replace', emptyResponse, body: {
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

  Future<MaskedAddressServerResponse> magicLinkUpdateEmail(String email, String loginId, String? redirectUrl, String refreshJwt) {
    return post('auth/magiclink/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'redirectUrl': redirectUrl,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkUpdatePhone(String phone, DeliveryMethod method, String loginId, String? redirectUrl, String refreshJwt) {
    method.ensurePhoneMethod();
    return post('auth/magiclink/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
      'redirectUrl': redirectUrl,
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

  Future<EnchantedLinkServerResponse> enchantedLinkUpdateEmail(String email, String loginId, String? redirectUrl, String refreshJwt) {
    return post('auth/enchantedlink/update/email', EnchantedLinkServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'redirectUrl': redirectUrl,
    });
  }

  Future<JWTServerResponse> enchantedLinkPendingSession(String pendingRef) {
    return post('auth/enchantedlink/pending-session', JWTServerResponse.decoder, body: {
      'pendingRef': pendingRef,
    });
  }

  // OAuth

  Future<OAuthServerResponse> oauthStart(OAuthProvider provider, String? redirectUrl, SignInOptions? options) {
    return post('auth/oauth/authorize', OAuthServerResponse.decoder,
        headers: authorization(options?.refreshJwt),
        params: {
          'provider': provider.name,
          'redirectUrl': redirectUrl,
        },
        body: options?.toMap() ?? {});
  }

  Future<JWTServerResponse> oauthExchange(String code) {
    return post('auth/oauth/exchange', JWTServerResponse.decoder, body: {
      'code': code,
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

  Future<void> logout(String refreshJwt) {
    return post('auth/logout', emptyResponse, headers: authorization(refreshJwt));
  }

  // Internal

  @override
  String get basePath => '/v1/';

  @override
  Map<String, String> get defaultHeaders => {
        'Authorization': 'Bearer ${config.projectId}',
        'x-descope-sdk-name': 'flutter',
        'x-descope-sdk-version': DescopeSdk.version,
      };

  Map<String, String> authorization(String? value) {
    return value != null ? {'Authorization': 'Bearer ${config.projectId}:$value'} : {};
  }
}

extension on SignInOptions {
  String? get refreshJwt => stepupRefreshJwt ?? mfaRefreshJwt;

  Map<String, dynamic> toMap() {
    return {
      'stepup': stepupRefreshJwt != null ? true : null,
      'mfa': mfaRefreshJwt != null ? true : null,
      'customClaims': customClaims.isNotEmpty ? customClaims : null,
    };
  }
}

extension on SignUpDetails {
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'name': name,
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
