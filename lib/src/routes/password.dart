import 'package:descope/src/types/responses.dart';

import '../http/descope_client.dart';
import '../http/responses.dart';
import '../routes.dart';
import '../types/others.dart';
import 'shared.dart';

class Password implements DescopePassword {
  final DescopeClient client;

  Password(this.client);

  @override
  Future<AuthenticationResponse> signUp({required String loginId, required String password, User? user}) async {
    return (await client.passwordSignUp(loginId, password, user)).convert();
  }

  @override
  Future<AuthenticationResponse> signIn({required String loginId, required String password}) async {
    return (await client.passwordSignIn(loginId, password)).convert();
  }

  @override
  Future<void> update({required String loginId, required String newPassword, required String refreshJwt}) {
    return client.passwordUpdate(loginId, newPassword, refreshJwt);
  }

  @override
  Future<void> replace({required String loginId, required String oldPassword, required String newPassword}) {
    return client.passwordReplace(loginId, oldPassword, newPassword);
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
