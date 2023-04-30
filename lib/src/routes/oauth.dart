import '../routes.dart';
import '../http/descope_client.dart';
import '../session/session.dart';
import '../types/others.dart';
import 'shared.dart';

class OAuth implements DescopeOAuth {
  final DescopeClient client;

  OAuth(this.client);

  @override
  Future<String> start({required OAuthProvider provider, String? redirectUrl}) async {
    return (await client.oauthStart(provider, redirectUrl)).url;
  }

  @override
  Future<DescopeSession> exchange({required String code}) async {
    return (await client.oauthExchange(code)).convert();
  }
}
