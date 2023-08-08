import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
import 'shared.dart';

class Totp implements DescopeTotp {
  final DescopeClient client;

  Totp(this.client);

  @override
  Future<TotpResponse> signUp({required String loginId, SignUpDetails? details}) async {
    return (await client.totpSignUp(loginId, details)).convert();
  }

  @override
  Future<TotpResponse> update({required String loginId, required String refreshJwt}) async {
    return (await client.totpUpdate(loginId, refreshJwt)).convert();
  }

  @override
  Future<AuthenticationResponse> verify({required String loginId, required String code, SignInOptions? options}) async {
    return (await client.totpVerify(loginId, code, options)).convert();
  }
}

extension on TotpServerResponse {
  TotpResponse convert() {
    return TotpResponse(provisioningUrl, image, key);
  }
}
