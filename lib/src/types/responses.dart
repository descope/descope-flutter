import 'package:descope/descope.dart';
import 'package:descope/src/types/user.dart';

/// Returned from user authentication calls.
class AuthenticationResponse {
  /// The user's session token is used to perform authorized backend requests.
  final DescopeToken sessionToken;

  /// The refresh token is used to refresh expired session tokens.
  final DescopeToken refreshToken;

  /// Whether this the user's first authentication.
  final bool isFirstAuthentication;

  /// Information about the user.
  final DescopeUser user;

  AuthenticationResponse(this.sessionToken, this.refreshToken, this.isFirstAuthentication, this.user);
}

/// Returned from the refreshSession call.
/// The refresh token might get updated as well with new information on the user that
/// might have changed.
class RefreshResponse {
  /// Refreshed session token
  final DescopeToken sessionToken;

  /// Optionally a refresh token
  final DescopeToken? refreshToken;

  RefreshResponse(this.sessionToken, this.refreshToken);
}
