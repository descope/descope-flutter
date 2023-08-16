import '/src/types/responses.dart';
import '/src/types/user.dart';
import 'token.dart';

/// The `DescopeSession` class represents a successful sign in operation.
///
/// After a user finishes a sign in flow successfully you should create
/// a `DescopeSession` object from the [AuthenticationResponse] value returned
/// by all the authentication APIs.
///
///     final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: 'andy@example.com', code: '123456');
///     final session = DescopeSession.fromAuthenticationResponse(authResponse);
///
/// The session can then be used to authenticate outgoing requests to your backend
/// with a bearer token authorization header.
///
///     await request.setAuthorization(Descope.sessionManager);
///
/// If your backend uses a different authorization mechanism you can of course
/// use the session JWT directly instead of the extension function:
///
///     request.headers['X-Auth-Token'] = session.sessionJwt;
///
/// As shown above the session can be used directly but in most circumstances
/// it's recommended to let a [DescopeSessionManager] object manage it instead,
/// and the code examples above are only slightly different. See the documentation
/// for [DescopeSessionManager] for more details.
///
/// `DescopeSession` can be constructed either by using [DescopeToken]s,
/// or by providing an [AuthenticationResponse], or using the JWT strings.
class DescopeSession {
  DescopeToken _sessionToken;
  DescopeToken _refreshToken;
  DescopeUser _user;

  DescopeSession(this._sessionToken, this._refreshToken, this._user);

  /// Creates a new [DescopeSession] object from an [AuthenticationResponse].
  ///
  /// Use this initializer to create a [DescopeSession] after the user completes
  /// a sign in or sign up flow in the application.
  DescopeSession.fromAuthenticationResponse(AuthenticationResponse authenticationResponse) : this(authenticationResponse.sessionToken, authenticationResponse.refreshToken, authenticationResponse.user);

  /// Creates a new [DescopeSession] object from two JWT strings.
  ///
  /// This constructor can be used to manually recreate a user's [DescopeSession] after
  /// the application is relaunched if not using a `DescopeSessionManager` for this.
  DescopeSession.fromJwt(String sessionJwt, String refreshJwt, DescopeUser user)
      : _sessionToken = Token.decode(sessionJwt),
        _refreshToken = Token.decode(refreshJwt),
        _user = user;

  /// The wrapper for the short lived JWT that can be sent with every server
  /// request that requires authentication.
  DescopeToken get sessionToken => _sessionToken;

  /// The wrapper for the longer lived JWT that is used to create
  /// new session JWTs until it expires.
  DescopeToken get refreshToken => _refreshToken;

  /// The user to whom the [DescopeSession] belongs to.
  DescopeUser get user => _user;

  // Convenience accessors for getting values from the underlying JWTs

  /// The short lived JWT that is sent with every request that requires authentication.
  String get sessionJwt => _sessionToken.jwt;

  /// The longer lived JWT that is used to create new session JWTs until it expires.
  String get refreshJwt => _refreshToken.jwt;

  /// A map with all the custom claims in the underlying JWT. It includes
  /// any claims whose values aren't already exposed by other accessors or
  /// authorization functions.
  Map<String, dynamic> get claims => _sessionToken.customClaims;

  /// Returns the list of permissions granted for the user. Pass `null` for
  /// the [tenant] parameter if the user isn't associated with any tenant.
  List<String> permissions([String? tenant]) => _sessionToken.getPermissions(tenant: tenant);

  /// Returns the list of roles for the user. Pass `null` for the [tenant]
  /// parameter if the user isn't associated with any tenant.
  List<String> roles([String? tenant]) => _sessionToken.getRoles(tenant: tenant);

  // Updating the session manually when not using a DescopeSessionManager

  /// Updates the underlying JWTs with those from the given [RefreshResponse].
  ///
  ///     if (session.sessionToken.isExpired) {
  ///       final refreshResponse = await Descope.auth.refreshSession(session.refreshJwt);
  ///       session.updateTokens(refreshResponse);
  ///     }
  ///
  /// Important: It's recommended to use a [DescopeSessionManager] to manage sessions,
  /// in which case you should call [updateTokens] on the manager itself, or
  /// just call [refreshSessionIfNeeded] to do everything for you.
  void updateTokens(RefreshResponse refreshResponse) {
    _sessionToken = refreshResponse.sessionToken;
    _refreshToken = refreshResponse.refreshToken ?? _refreshToken;
  }

  /// Updates the session user's details with those from another [DescopeUser] value.
  ///
  ///     final userResponse = await Descope.auth.me(session.refreshJwt);
  ///     session.updateUser(userResponse);
  ///
  /// Important: It's recommended to use a [DescopeSessionManager] to manage sessions,
  /// in which case you should call [updateUser] on the manager itself instead
  /// to ensure that the updated user details are saved.
  void updateUser(DescopeUser descopeUser) {
    _user = descopeUser;
  }

  // Ensure correct equality checks between session objects

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DescopeSession && other.sessionJwt == sessionJwt && other.refreshJwt == refreshJwt && other.user == user;
  }

  @override
  int get hashCode => Object.hash(sessionJwt, refreshJwt, user);

  @override
  String toString() {
    var expires = 'expires: Never';
    if (_sessionToken.expiresAt != null) {
      final label = _sessionToken.isExpired ? 'expired' : 'expires';
      expires = '$label: ${_sessionToken.expiresAt}';
    }
    return 'DescopeSession(id: ${_refreshToken.id}, $expires)';
  }
}
