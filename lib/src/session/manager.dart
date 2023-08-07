import '/src/types/responses.dart';
import '/src/types/user.dart';
import 'lifecycle.dart';
import 'session.dart';
import 'storage.dart';

/// The `DescopeSessionManager` class is used to manage an authenticated
/// user session for an application.
///
/// The session manager takes care of loading and saving the session as well
/// as ensuring that it's refreshed when needed.
///
/// Once the user completes a sign in flow successfully you should set the
/// [DescopeSession] object as the active session of the session manager.
///
///     final authResponse = await Descope.otp.verify(method: DeliverMethod.Email, loginId: "andy@example.com", code: "123456");
///     final session = DescopeSession.fromAuthenticationResponse(authResponse);
///     Descope.sessionManager.manageSession(session);
///
/// The session manager can then be used at any time to ensure the session
/// is valid and to authenticate outgoing requests to your backend with a
/// bearer token authorization header.
///
///     await request.setAuthorization(Descope.sessionManager);
///
/// If your backend uses a different authorization mechanism you can of course
/// use the session JWT directly instead of the extension function. You can either
/// add another extension function on [URLConnection] such as the one above, or you
/// can do the following.
///
///     await Descope.sessionManager.refreshSessionIfNeeded();
///     final session = Descope.sessionManager.session;
///     if (session != null) {
///       request.headers['X-Auth-Token'] = session.sessionJwt;
///     } else {
///       throw ServerError.unauthorized;
///     }
///
/// The same principals can be used in the various networking libraries available,
/// if those are used in your application.
///
/// When the application is relaunched the `DescopeSessionManager` loads any
/// existing session automatically, so you can check straight away if there's
/// an authenticated user.
///
///     Descope.projectId = "...";
///     final session = Descope.sessionManager.session;
///     if (session != null) {
///         print("User is logged in: ${session.user}");
///     }
///
/// When the user wants to sign out of the application we revoke the active
/// session and clear it from the session manager:
///
///     final refreshJwt = Descope.sessionManager.session?.refreshJwt;
///     if (refreshJwt != null) {
///       Descope.auth.logout(refreshJwt);
///       Descope.sessionManager.clearSession();
///     }
///
/// You can customize how the `DescopeSessionManager` behaves by using your own
/// [DescopeSessionStorage] and [DescopeSessionLifecycle]` objects. See the documentation for the initializer
/// below for more details.
class DescopeSessionManager {
  final DescopeSessionStorage storage;
  final DescopeSessionLifecycle lifecycle;

  DescopeSessionManager(this.storage, this.lifecycle);

  DescopeSession? _session;

  DescopeSession? get session => _session;

  Future<void> load() async {
    _session = await storage.loadSession();
    lifecycle.session = _session;
  }

  /// Set an active [DescopeSession] in this manager.
  ///
  /// You should call this function after a user finishes logging in to the
  /// host application.
  ///
  /// The parameter is set as the value of the [session] property and is persisted
  /// so it can be reloaded on the next application launch or
  /// [DescopeSessionManager] instantiation.
  ///
  /// - **Important:** The default [DescopeSessionStorage] only keeps at most
  ///     one session in the storage for simplicity. If for some reason you
  ///     have multiple [DescopeSessionManager] objects then be aware that
  ///     unless they use custom `storage` objects they might overwrite
  ///     each other's saved sessions.
  void manageSession(DescopeSession session) {
    _session = session;
    lifecycle.session = session;
    storage.saveSession(session);
  }

  /// Clears any active [DescopeSession] from this manager.
  ///
  /// You should call this function as part of a logout flow in the host application.
  /// The `session` property is set to `null` and the session won't be reloaded in
  /// subsequent application launches.
  ///
  /// - **Important:** The default [DescopeSessionStorage] only keeps at most
  ///     one session in the storage for simplicity. If for some reason you
  ///     have multiple [DescopeSessionManager] objects then be aware that
  ///     unless they use custom `storage` objects they might clear
  ///     each other's saved sessions.
  void clearSession() {
    _session = null;
    lifecycle.session = null;
    storage.removeSession();
  }

  /// Ensures that the session is valid and refreshes it if needed.
  ///
  /// The session manager checks whether there's an active [DescopeSession] and if
  /// its session JWT expires within the next 60 seconds. If that's the case then
  /// the session is refreshed and persisted before returning.
  ///
  /// - **Note:** When using a custom [DescopeSessionManager] object the exact behavior
  ///     here depends on the `storage` and `lifecycle` objects.
  Future<void> refreshSessionIfNeeded() async {
    final session = _session;
    if (session == null) {
      return;
    }
    await lifecycle.refreshSessionIfNeeded();
    await storage.saveSession(session);
  }

  /// Updates the active session's underlying JWTs.
  ///
  /// This function accepts a [RefreshResponse] value as a parameter which is returned
  /// by calls to `Descope.auth.refreshSession`. The manager persists the updated session
  /// before returning (by default).
  ///
  /// - **Important:** In most circumstances it's best to use `refreshSessionIfNeeded` and let
  ///     it update the session unless you need to invoke `Descope.auth.refreshSession`
  ///     manually.
  ///
  /// - **Note:** If the [DescopeSessionManager] object was created with a custom `storage`
  ///     object then the exact behavior depends on the specific implementation of the
  ///     `DescopeSessionStorage` interface.
  void updateTokens(RefreshResponse refreshResponse) {
    final session = _session;
    if (session != null) {
      session.updateTokens(refreshResponse);
      storage.saveSession(session);
    }
  }

  /// Updates the active session's user details.
  ///
  /// This function accepts a [DescopeUser] value as a parameter which is returned by
  /// calls to `Descope.auth.me`. The manager saves the updated session to the
  /// storage before returning.
  ///
  ///     final userResponse = await Descope.auth.me(session.refreshJwt);
  ///     Descope.sessionManager.updateUser(userResponse);
  void updateUser(DescopeUser user) {
    final session = _session;
    if (session != null) {
      session.updateUser(user);
      storage.saveSession(session);
    }
  }
}
