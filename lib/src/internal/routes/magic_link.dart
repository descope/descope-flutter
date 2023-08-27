import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/internal/http/descope_client.dart';
import 'shared.dart';

class MagicLink implements DescopeMagicLink {
  final DescopeClient client;

  MagicLink(this.client);

  @override
  Future<String> signUp({required DeliveryMethod method, required String loginId, SignUpDetails? details, String? redirectUrl}) async {
    return (await client.magicLinkSignUp(method, loginId, details, redirectUrl)).convert(method);
  }

  @override
  Future<String> signIn({required DeliveryMethod method, required String loginId, String? redirectUrl, SignInOptions? options}) async {
    return (await client.magicLinkSignIn(method, loginId, redirectUrl, options)).convert(method);
  }

  @override
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId, String? redirectUrl, SignInOptions? options}) async {
    return (await client.magicLinkSignUpOrIn(method, loginId, redirectUrl, options)).convert(method);
  }

  @override
  Future<String> updateEmail({required String email, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options}) async {
    return (await client.magicLinkUpdateEmail(email, loginId, redirectUrl, refreshJwt, options)).convert(DeliveryMethod.email);
  }

  @override
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options}) async {
    return (await client.magicLinkUpdatePhone(phone, method, loginId, redirectUrl, refreshJwt, options)).convert(method);
  }

  @override
  Future<AuthenticationResponse> verify({required String token}) async {
    return (await client.magicLinkVerify(token)).convert();
  }
}
