import '/src/sdk/routes.dart';
import '/src/types/responses.dart';
import '../../types/others.dart';
import '../http/descope_client.dart';
import 'shared.dart';

class Sso implements DescopeSso {
  final DescopeClient client;

  Sso(this.client);

  @override
  Future<String> start({required String emailOrTenantId, String? redirectUrl, SignInOptions? options}) async {
    return (await client.ssoStart(emailOrTenantId, redirectUrl, options)).url;
  }

  @override
  Future<AuthenticationResponse> exchange({required String code}) async {
    return (await client.ssoExchange(code)).toAuthenticationResponse();
  }
}
