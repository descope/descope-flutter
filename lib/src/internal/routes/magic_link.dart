import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import 'shared.dart';

class MagicLink implements DescopeMagicLink {
  final DescopeClient client;

  MagicLink(this.client);

  @override
  Future<String> signUp({required DeliveryMethod method, required String loginId, SignUpDetails? details, String? uri}) async {
    return (await client.magicLinkSignUp(method, loginId, details, uri)).convert(method);
  }

  @override
  Future<String> signIn({required DeliveryMethod method, required String loginId, String? uri}) async {
    return (await client.magicLinkSignIn(method, loginId, uri)).convert(method);
  }

  @override
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId, String? uri}) async {
    return (await client.magicLinkSignUpOrIn(method, loginId, uri)).convert(method);
  }

  @override
  Future<String> updateEmail({required String email, required String loginId, String? uri, required String refreshJwt}) async {
    return (await client.magicLinkUpdateEmail(email, loginId, uri, refreshJwt)).convert(DeliveryMethod.email);
  }

  @override
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, String? uri, required String refreshJwt}) async {
    return (await client.magicLinkUpdatePhone(phone, method, loginId, uri, refreshJwt)).convert(method);
  }

  @override
  Future<AuthenticationResponse> verify({required String token}) async {
    return (await client.magicLinkVerify(token)).convert();
  }
}
