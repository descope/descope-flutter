import '/src/sdk/config.dart';
import '/src/types/others.dart';
import 'http_client.dart';
import 'responses.dart';

class DescopeClient extends HttpClient {
  final DescopeConfig config;

  DescopeClient(this.config) : super(config.baseUrl);

  // OTP

  Future<MaskedAddressServerResponse> otpSignUp(DeliveryMethod method, String loginId, [SignUpDetails? details]) {
    return post('otp/signup/${method.name}', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
    });
  }

  Future<MaskedAddressServerResponse> otpSignIn(DeliveryMethod method, String loginId) {
    return post('otp/signin/${method.name}', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
    });
  }

  Future<MaskedAddressServerResponse> otpSignUpIn(DeliveryMethod method, String loginId) {
    return post('otp/signup-in/${method.name}', MaskedAddressServerResponse.decoder, body: {'loginId': loginId});
  }

  Future<JWTServerResponse> otpVerify(DeliveryMethod method, String loginId, String code) {
    return post('otp/verify/${method.name}', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'code': code,
    });
  }

  Future<MaskedAddressServerResponse> otpUpdateEmail(String email, String loginId, String refreshJwt) {
    return post('otp/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
    });
  }

  Future<MaskedAddressServerResponse> otpUpdatePhone(String phone, DeliveryMethod method, String loginId, String refreshJwt) {
    method.ensurePhoneMethod();
    return post('otp/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
    });
  }

  // TOTP

  Future<TotpServerResponse> totpSignUp(String loginId, [SignUpDetails? details]) {
    return post('totp/signup', TotpServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
    });
  }

  Future<JWTServerResponse> totpVerify(String loginId, String code) {
    return post('totp/verify', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'code': code,
    });
  }

  Future<TotpServerResponse> totpUpdate(String loginId, String refreshJwt) {
    return post('totp/update', TotpServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
    });
  }

  // Password

  Future<JWTServerResponse> passwordSignUp(String loginId, String password, [SignUpDetails? details]) {
    return post('password/signup', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'password': password,
      'user': details?.toMap(),
    });
  }

  Future<JWTServerResponse> passwordSignIn(String loginId, String password) {
    return post('password/signin', JWTServerResponse.decoder, body: {
      'loginId': loginId,
      'password': password,
    });
  }

  Future<void> passwordUpdate(String loginId, String newPassword, String refreshJwt) {
    return post('password/update', emptyResponse, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'newPassword': newPassword,
    });
  }

  Future<void> passwordReplace(String loginId, String oldPassword, String newPassword) {
    return post('password/replace', emptyResponse, body: {
      'loginId': loginId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> passwordSendReset(String loginId, String? redirectUrl) {
    return post('password/reset', emptyResponse, body: {
      'loginId': loginId,
      'redirectUrl': redirectUrl,
    });
  }

  Future<PasswordPolicyServerResponse> passwordGetPolicy() {
    return get('password/policy', PasswordPolicyServerResponse.decoder);
  }

  // Magic Link

  Future<MaskedAddressServerResponse> magicLinkSignUp(DeliveryMethod method, String loginId, [SignUpDetails? details, String? uri]) {
    return post('magiclink/signup/${method.name})', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
      'uri': uri,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkSignIn(DeliveryMethod method, String loginId, String? uri) {
    return post('magiclink/signin/${method.name}', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'uri': uri,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkSignUpOrIn(DeliveryMethod method, String loginId, String? uri) {
    return post('magiclink/signup-in/${method.name}', MaskedAddressServerResponse.decoder, body: {
      'loginId': loginId,
      'uri': uri,
    });
  }

  Future<JWTServerResponse> magicLinkVerify(String token) {
    return post('magiclink/verify', JWTServerResponse.decoder, body: {
      'token': token,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkUpdateEmail(String email, String loginId, String? uri, String refreshJwt) {
    return post('magiclink/update/email', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'uri': uri,
    });
  }

  Future<MaskedAddressServerResponse> magicLinkUpdatePhone(String phone, DeliveryMethod method, String loginId, String? uri, String refreshJwt) {
    method.ensurePhoneMethod();
    return post('magiclink/update/phone/${method.name}', MaskedAddressServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'phone': phone,
      'uri': uri,
    });
  }

  // Enchanted Link

  Future<EnchantedLinkServerResponse> enchantedLinkSignUp(String loginId, [SignUpDetails? details, String? uri]) {
    return post('enchantedlink/signup/email', EnchantedLinkServerResponse.decoder, body: {
      'loginId': loginId,
      'user': details?.toMap(),
      'uri': uri,
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkSignIn(String loginId, String? uri) {
    return post('enchantedlink/signin/email', EnchantedLinkServerResponse.decoder, body: {
      'loginId': loginId,
      'uri': uri,
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkSignUpOrIn(String loginId, String? uri) {
    return post('enchantedlink/signup-in/email', EnchantedLinkServerResponse.decoder, body: {
      'loginId': loginId,
      'uri': uri,
    });
  }

  Future<EnchantedLinkServerResponse> enchantedLinkUpdateEmail(String email, String loginId, String? uri, String refreshJwt) {
    return post('enchantedlink/update/email', EnchantedLinkServerResponse.decoder, headers: authorization(refreshJwt), body: {
      'loginId': loginId,
      'email': email,
      'uri': uri,
    });
  }

  Future<JWTServerResponse> enchantedLinkPendingSession(String pendingRef) {
    return post('enchantedlink/pending-session', JWTServerResponse.decoder, body: {
      'pendingRef': pendingRef,
    });
  }

  // OAuth

  Future<OAuthServerResponse> oauthStart(OAuthProvider provider, String? redirectUrl) {
    return post('oauth/authorize', OAuthServerResponse.decoder, params: {
      'provider': provider.name,
      'redirectURL': redirectUrl,
    });
  }

  Future<JWTServerResponse> oauthExchange(String code) {
    return post('oauth/exchange', JWTServerResponse.decoder, body: {
      'code': code,
    });
  }

  // SSO

  Future<SsoServerResponse> ssoStart(String emailOrTenantId, String? redirectUrl) {
    return post('saml/authorize', SsoServerResponse.decoder, params: {
      'tenant': emailOrTenantId,
      'redirectURL': redirectUrl,
    });
  }

  Future<JWTServerResponse> ssoExchange(String code) {
    return post('saml/exchange', JWTServerResponse.decoder, body: {
      'code': code,
    });
  }

  // Others

  Future<UserResponse> me(String refreshJwt) {
    return get('me', UserResponse.decoder, headers: authorization(refreshJwt));
  }

  Future<JWTServerResponse> refresh(String refreshJwt) {
    return post('refresh', JWTServerResponse.decoder, headers: authorization(refreshJwt));
  }

  Future<void> logout(String refreshJwt) {
    return post('logout', emptyResponse, headers: authorization(refreshJwt));
  }

  // Internal

  @override
  String get basePath => '/v1/auth/';

  @override
  Map<String, String> get defaultHeaders => {
        'Authorization': 'Bearer ${config.projectId}',
        'x-descope-sdk-name': 'flutter',
        'x-descope-sdk-version': '0.1.0',
      };

  Map<String, String> authorization(String value) {
    return {'Authorization': 'Bearer ${config.projectId}:$value'};
  }
}

// Extensions

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
      throw Exception('Update phone can be done using SMS or WhatsApp only');
    }
  }
}
