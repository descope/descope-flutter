import 'package:http/http.dart' as http;

import '/src/session/manager.dart';
import '/src/session/session.dart';
import '/src/session/token.dart';

extension AddAuthorization on http.Request {
  /// Ensures that the active session in a [DescopeSessionManager] is valid and
  /// then sets its session JWT as the Bearer Token value of the Authorization
  /// header field in the [http.Request].
  void setAuthorization(DescopeSessionManager sessionManager) async {
    await sessionManager.refreshSessionIfNeeded();
    final session = sessionManager.session;
    if (session != null) {
      setAuthorizationFromSession(session);
    }
  }

  /// Sets the session JWT from a [DescopeSession] as the Bearer Token value of
  /// the Authorization header field in the [http.Request].
  void setAuthorizationFromSession(DescopeSession session) {
    setAuthorizationFromToken(session.sessionToken);
  }

  /// Sets the JWT from a [DescopeToken] as the Bearer Token value of
  /// the Authorization header field in the [http.Request].
  void setAuthorizationFromToken(DescopeToken token) {
    headers['Authorization'] = "Bearer ${token.jwt}";
  }
}
