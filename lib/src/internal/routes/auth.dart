import '/src/sdk/routes.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
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
  Future<void> logout(String refreshJwt) {
    return client.logout(refreshJwt);
  }
}

extension on UserResponse {
  DescopeUser convert() {
    final emailValue = (email ?? '').isNotEmpty ? email : null;
    final phoneValue = (phone ?? '').isNotEmpty ? phone : null;
    Uri? uri;
    final pic = picture;
    if (pic != null && pic.isNotEmpty) {
      uri = Uri.parse(pic);
    }
    return DescopeUser(userId, loginIds, createdTime, name, uri, emailValue, verifiedEmail, phoneValue, verifiedPhone);
  }
}
