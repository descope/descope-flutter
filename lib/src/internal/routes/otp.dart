import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import 'shared.dart';

class Otp implements DescopeOtp {
  final DescopeClient client;

  Otp(this.client);

  @override
  Future<String> signUp({required DeliveryMethod method, required String loginId, SignUpDetails? details}) async {
    return (await client.otpSignUp(method, loginId, details)).convert(method);
  }

  @override
  Future<String> signIn({required DeliveryMethod method, required String loginId, SignInOptions? options}) async {
    return (await client.otpSignIn(method, loginId, options)).convert(method);
  }

  @override
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId, SignInOptions? options}) async {
    return (await client.otpSignUpIn(method, loginId, options)).convert(method);
  }

  @override
  Future<AuthenticationResponse> verify({required DeliveryMethod method, required String loginId, required String code}) async {
    return (await client.otpVerify(method, loginId, code)).toAuthenticationResponse();
  }

  @override
  Future<String> updateEmail({required String email, required String loginId, required String refreshJwt, UpdateOptions? options}) async {
    return (await client.otpUpdateEmail(email, loginId, refreshJwt, options)).convert(DeliveryMethod.email);
  }

  @override
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, required String refreshJwt, UpdateOptions? options}) async {
    return (await client.otpUpdatePhone(phone, method, loginId, refreshJwt, options)).convert(method);
  }
}
