import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
import 'shared.dart';

class Password implements DescopePassword {
  final DescopeClient client;

  Password(this.client);

  @override
  Future<AuthenticationResponse> signUp({required String loginId, required String password, SignUpDetails? details}) async {
    return (await client.passwordSignUp(loginId, password, details)).toAuthenticationResponse();
  }

  @override
  Future<AuthenticationResponse> signIn({required String loginId, required String password}) async {
    return (await client.passwordSignIn(loginId, password)).toAuthenticationResponse();
  }

  @override
  Future<void> update({required String loginId, required String newPassword, required String refreshJwt}) {
    return client.passwordUpdate(loginId, newPassword, refreshJwt);
  }

  @override
  Future<AuthenticationResponse> replace({required String loginId, required String oldPassword, required String newPassword}) async {
    return (await client.passwordReplace(loginId, oldPassword, newPassword)).convert();
  }

  @override
  Future<void> sendReset({required String loginId, String? redirectUrl}) {
    return client.passwordSendReset(loginId, redirectUrl);
  }

  @override
  Future<PasswordPolicy> getPolicy() async {
    return (await client.passwordGetPolicy()).convert();
  }
}

extension on PasswordPolicyServerResponse {
  PasswordPolicy convert() {
    return PasswordPolicy(minLength, lowercase, uppercase, number, nonAlphanumeric);
  }
}
