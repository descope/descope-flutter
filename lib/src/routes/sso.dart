import '../routes.dart';
import '../http/descope_client.dart';
import '../session/session.dart';
import 'shared.dart';

class Sso implements DescopeSso {
  final DescopeClient client;

  Sso(this.client);

  @override
  Future<String> start({required String emailOrTenantId, String? redirectUrl}) async {
    return (await client.ssoStart(emailOrTenantId, redirectUrl)).url;
  }

  @override
  Future<DescopeSession> exchange({required String code}) async {
    return (await client.oauthExchange(code)).convert();
  }
}
