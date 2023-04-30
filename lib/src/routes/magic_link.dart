import '../routes.dart';
import '../http/descope_client.dart';
import '../session/session.dart';
import '../types/others.dart';
import 'shared.dart';

class MagicLink implements DescopeMagicLink {
  final DescopeClient client;

  MagicLink(this.client);

  @override
  Future<String> signUp({required DeliveryMethod method, required String loginId, User? user, String? uri}) async {
    return (await client.magicLinkSignUp(method, loginId, user, uri)).convert(method);
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
  Future<DescopeSession> verify({required String token}) async {
    return (await client.magicLinkVerify(token)).convert();
  }
}
