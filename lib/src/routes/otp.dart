import 'package:descope/src/types/responses.dart';

import '../http/descope_client.dart';
import '../routes.dart';
import '../types/others.dart';
import 'shared.dart';

class Otp implements DescopeOtp {
  final DescopeClient client;

  Otp(this.client);

  @override
  Future<String> signUp({required DeliveryMethod method, required String loginId, User? user}) async {
    return (await client.otpSignUp(method, loginId, user)).convert(method);
  }

  @override
  Future<String> signIn({required DeliveryMethod method, required String loginId}) async {
    return (await client.otpSignIn(method, loginId)).convert(method);
  }

  @override
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId}) async {
    return (await client.otpSignUpIn(method, loginId)).convert(method);
  }

  @override
  Future<AuthenticationResponse> verify({required DeliveryMethod method, required String loginId, required String code}) async {
    return (await client.otpVerify(method, loginId, code)).convert();
  }

  @override
  Future<String> updateEmail({required String email, required String loginId, required String refreshJwt}) async {
    return (await client.otpUpdateEmail(email, loginId, refreshJwt)).convert(DeliveryMethod.email);
  }

  @override
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, required String refreshJwt}) async {
    return (await client.otpUpdatePhone(phone, method, loginId, refreshJwt)).convert(method);
  }
}
