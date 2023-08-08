import '../sdk/routes.dart';
import 'manager.dart';
import 'session.dart';

/// This abstract class can be used to customize how a [DescopeSessionManager] object
/// manages its [DescopeSession] while the application is running.
abstract class DescopeSessionLifecycle {
  /// Set by the session manager whenever the current active session changes.
  DescopeSession? session;

  /// Called the session manager to conditionally refresh the active session.
  Future<void> refreshSessionIfNeeded();
}

/// The default implementation of the [DescopeSessionLifecycle] interface.
///
/// The `SessionLifecycle` class periodically checks if the session needs to be
/// refreshed (every 30 seconds by default). The [refreshSessionIfNeeded] function
/// will refresh the session if it's about to expire (within 60 seconds by default)
/// or if it's already expired.
///
/// [DescopeAuth] used to refresh the session when needed
class SessionLifecycle implements DescopeSessionLifecycle {
  var stalenessAllowedInterval = Duration(seconds: 60);
  var stalenessCheckFrequency = Duration(seconds: 30);

  DescopeSession? _session;
  final DescopeAuth _auth;

  SessionLifecycle(this._auth);

  @override
  DescopeSession? get session => _session;

  @override
  set session(DescopeSession? session) {
    if (session == _session) return;
    _session = session;
    if (session == null) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  @override
  Future<void> refreshSessionIfNeeded() async {
    final session = _session;
    if (session != null) {
      if (shouldRefresh(session)) {
        final response = await _auth.refreshSession(session.refreshJwt);
        session.updateTokens(response);
      }
    }
  }

  // Internal

  bool shouldRefresh(DescopeSession session) {
    final expiresAt = session.sessionToken.expiresAt;
    if (expiresAt != null) {
      return DateTime.timestamp().add(stalenessAllowedInterval).isAfter(expiresAt);
    }
    return false;
  }

  void startTimer() {
    // TODO: not implemented yet
  }

  void stopTimer() {
    // TODO: not implemented yet
  }
}
