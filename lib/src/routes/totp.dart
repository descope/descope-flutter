import '../routes.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
import '../session/session.dart';
import '../types/others.dart';
import 'shared.dart';

class Totp implements DescopeTotp {
  final DescopeClient client;

  Totp(this.client);

  @override
  Future<TotpResponse> signUp({required String loginId, User? user}) async {
    return (await client.totpSignUp(loginId, user)).convert();
  }

  @override
  Future<TotpResponse> update({required String loginId, required String refreshJwt}) async {
    return (await client.totpUpdate(loginId, refreshJwt)).convert();
  }

  @override
  Future<DescopeSession> verify({required String loginId, required String code}) async {
    return (await client.totpVerify(loginId, code)).convert();
  }
}

extension on TotpServerResponse {
  TotpResponse convert() {
    return TotpResponse(provisioningUrl, image, key);
  }
}
