import '/src/sdk/routes.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import 'shared.dart';

class Sso implements DescopeSso {
  final DescopeClient client;

  Sso(this.client);

  @override
  Future<String> start({required String emailOrTenantId, String? redirectUrl}) async {
    return (await client.ssoStart(emailOrTenantId, redirectUrl)).url;
  }

  @override
  Future<AuthenticationResponse> exchange({required String code}) async {
    return (await client.oauthExchange(code)).convert();
  }
}
