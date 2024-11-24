import '/src/internal/http/descope_client.dart';
import '/src/sdk/routes.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';
import 'shared.dart';

class Auth implements DescopeAuth {
  final DescopeClient client;

  Auth(this.client);

  @override
  Future<DescopeUser> me(String refreshJwt) async {
    return (await client.me(refreshJwt)).convert();
  }

  @override
  Future<RefreshResponse> refreshSession(String refreshJwt) async {
    return (await client.refresh(refreshJwt)).toRefreshResponse();
  }

  @override
  Future<void> revokeSessions(RevokeType revokeType, String refreshJwt) async {
    return client.logout(revokeType, refreshJwt);
  }

  // Deprecated

  @override
  Future<void> logout(String refreshJwt) {
    return revokeSessions(RevokeType.currentSession, refreshJwt);
  }
}
