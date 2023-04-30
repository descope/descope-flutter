import '../routes.dart';
import '../http/descope_client.dart';
import '../http/responses.dart';
import '../session/session.dart';
import '../types/others.dart';
import 'shared.dart';

class Auth implements DescopeAuth {
  final DescopeClient client;

  Auth(this.client);

  @override
  Future<MeResponse> me(String refreshJwt) async {
    return (await client.me(refreshJwt)).convert();
  }

  @override
  Future<DescopeSession> refreshSession(String refreshJwt) async {
    return (await client.refresh(refreshJwt)).convert();
  }

  @override
  Future<void> logout(String refreshJwt) {
    return client.logout(refreshJwt);
  }
}

extension on UserResponse {
  MeResponse convert() {
    final emailValue = (email ?? '').isNotEmpty ? email : null;
    final phoneValue = (phone ?? '').isNotEmpty ? phone : null;
    return MeResponse(userId, loginIds, name, picture, emailValue, verifiedEmail, phoneValue, verifiedPhone);
  }
}
