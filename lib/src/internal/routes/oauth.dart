import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '../http/descope_client.dart';
import 'shared.dart';

class OAuth implements DescopeOAuth {
  final DescopeClient client;

  OAuth(this.client);

  @override
  Future<String> start({required OAuthProvider provider, String? redirectUrl, SignInOptions? options}) async {
    return (await client.oauthStart(provider, redirectUrl, options)).url;
  }

  @override
  Future<AuthenticationResponse> exchange({required String code}) async {
    return (await client.oauthExchange(code)).toAuthenticationResponse();
  }
}
