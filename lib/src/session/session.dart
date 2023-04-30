
import 'token.dart';

/// A [DescopeSession] is returned as a result of a successful sign in operation.
class DescopeSession {

  /// The private underlying wrapper for the short lived JWT that is sent with
  /// every request that requires authentication.
  final DescopeToken _sessionToken;

  /// The private underlying wrapper for the longer lived JWT that is used to
  /// create new session JWTs until it expires.
  final DescopeToken _refreshToken;

  /// Creates a new [DescopeSession] instance from two JWT strings.
  ///
  /// This constructor cab be used to recreate a user's session after an
  /// application is relaunched.
  DescopeSession(String sessionJwt, String refreshJwt) : _sessionToken = Token.decode(sessionJwt), _refreshToken = Token.decode(refreshJwt);

  /// The short lived JWT that is sent with every request that
  /// requires authentication.
  String get sessionJwt => _sessionToken.jwt;

  /// The longer lived JWT that is used to create new session JWTs
  /// until it expires.
  String get refreshJwt => _refreshToken.jwt;

  /// The unique id of the user this session was created for.
  String get userId => _refreshToken.id;

  /// The unique id of the Descope project this session was created for.
  String get projectId => _refreshToken.projectId;

  /// The time after which the session JWT expires, if any.
  DateTime? get expiresAt => _sessionToken.expiresAt;

  /// Whether the session JWT expiry time has already passed.
  bool get isExpired => _sessionToken.isExpired;

  /// The time after which the refresh JWT expires, if any.
  DateTime? get refreshExpiresAt => _refreshToken.expiresAt;

  /// Whether the refresh JWT expiry time has already passed.
  bool get isRefreshExpired => _refreshToken.isExpired;

  /// A map with all the custom claims in the underlying JWT. It includes
  /// any claims whose values aren't already exposed by other accessors or
  /// authorization functions.
  Map<String, dynamic> get customClaims => _refreshToken.customClaims;

  /// Returns the list of permissions granted for the user. Pass `null` for
  /// the [tenant] parameter if the user isn't associated with any tenant.
  List<String> getPermissions({required String? tenant}) => _refreshToken.getPermissions(tenant: tenant);

  /// Returns the list of roles for the user. Pass `null` for the [tenant]
  /// parameter if the user isn't associated with any tenant.
  List<String> getRoles({required String? tenant}) => _refreshToken.getRoles(tenant: tenant);

  /// A string representation of this [DescopeSession].
  @override
  String toString() {
    var expires = 'expires: Never';
    if (expiresAt != null) {
      final label = isExpired ? 'expired' : 'expires';
      expires = '$label: $expiresAt';
    }
    return 'DescopeSession(id: $userId, $expires)';
  }
}
