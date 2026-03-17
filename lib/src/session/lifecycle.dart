import 'dart:async';

import 'package:flutter/widgets.dart';

import '/src/sdk/config.dart';
import '/src/types/error.dart';
import '../sdk/routes.dart';
import 'session.dart';

/// This abstract class can be used to customize how a [DescopeSessionManager] object
/// manages its [DescopeSession] while the application is running.
abstract class DescopeSessionLifecycle {
  /// Set by the session manager whenever the current active session changes.
  DescopeSession? session;

  /// Called by the session manager to conditionally refresh the active session.
  Future<void> refreshSessionIfNeeded();

  /// Called by the [SessionLifecycle] after a periodic session refresh succeeds.
  ///
  /// The session manager sets this to persist the updated session to storage.
  void Function()? onRefresh;
}

/// The default implementation of the [DescopeSessionLifecycle] interface.
///
/// The [SessionLifecycle] class periodically checks if the session needs to be
/// refreshed (every 30 seconds by default). The [refreshSessionIfNeeded] function
/// will refresh the session if it's about to expire (within 60 seconds by default)
/// or if it's already expired.
///
/// The periodic check is paused when the application is moved to the background
/// and resumed when it returns to the foreground.
class SessionLifecycle with WidgetsBindingObserver implements DescopeSessionLifecycle {
  var stalenessAllowedInterval = const Duration(seconds: 60);
  var stalenessCheckFrequency = const Duration(seconds: 30);

  DescopeSession? _session;
  final DescopeAuth _auth;
  final DescopeLogger? _logger;
  Timer? _timer;
  bool _observingLifecycle = false;
  bool _refreshing = false;

  @override
  void Function()? onRefresh;

  SessionLifecycle(this._auth, [this._logger]);

  @override
  DescopeSession? get session => _session;

  @override
  set session(DescopeSession? session) {
    if (session == _session) return;
    _session = session;
    if (session != null && session.refreshToken.isExpired) {
      _logger?.log(level: DescopeLogger.info, message: 'Session has an expired refresh token', values: [session.refreshToken.expiresAt]);
    }
    _resetTimer();
  }

  @override
  Future<void> refreshSessionIfNeeded() async {
    final session = _session;
    if (session != null && shouldRefresh(session)) {
      _logger?.log(level: DescopeLogger.info, message: 'Refreshing session that is about to expire', values: [session.sessionToken.expiresAt]);
      final response = await _auth.refreshSession(session.refreshJwt);
      if (_session != session) {
        _logger?.log(level: DescopeLogger.info, message: 'Skipping refresh because session has changed in the meantime');
        return;
      }
      session.updateTokens(response);
    }
  }

  // Internal

  bool shouldRefresh(DescopeSession session) {
    if (session.refreshToken.isExpired) return false;
    final expiresAt = session.sessionToken.expiresAt;
    if (expiresAt != null) {
      return DateTime.now().add(stalenessAllowedInterval).isAfter(expiresAt);
    }
    return false;
  }

  // Timer

  void _resetTimer() {
    final refreshToken = _session?.refreshToken;
    if (refreshToken != null && !refreshToken.isExpired) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopPeriodicTimer();
    _startPeriodicTimer();
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
  }

  void _stopTimer() {
    _stopPeriodicTimer();
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
  }

  void _startPeriodicTimer() {
    _timer = Timer.periodic(stalenessCheckFrequency, (_) => _periodicRefresh());
  }

  void _stopPeriodicTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Periodic refresh

  Future<void> _periodicRefresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final refreshToken = _session?.refreshToken;
      if (refreshToken == null || refreshToken.isExpired) {
        _logger?.log(level: DescopeLogger.debug, message: 'Stopping periodic refresh for session with expired refresh token');
        _stopTimer();
        return;
      }
      final session = _session;
      if (session != null && shouldRefresh(session)) {
        _logger?.log(level: DescopeLogger.info, message: 'Refreshing session that is about to expire', values: [session.sessionToken.expiresAt]);
        final response = await _auth.refreshSession(session.refreshJwt);
        if (_session != session) {
          _logger?.log(level: DescopeLogger.info, message: 'Skipping refresh because session has changed in the meantime');
          return;
        }
        session.updateTokens(response);
        _logger?.log(level: DescopeLogger.debug, message: 'Periodic session refresh succeeded');
        onRefresh?.call();
      }
    } on DescopeException catch (e) {
      if (e == DescopeException.networkError) {
        _logger?.log(level: DescopeLogger.debug, message: 'Ignoring network error in periodic refresh');
      } else {
        _logger?.log(level: DescopeLogger.error, message: 'Stopping periodic refresh after failure', values: [e]);
        _stopTimer();
      }
    } catch (e) {
      _logger?.log(level: DescopeLogger.error, message: 'Stopping periodic refresh after unexpected failure', values: [e]);
      _stopTimer();
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetTimer();
      _periodicRefresh();
    } else if (state == AppLifecycleState.paused) {
      _stopPeriodicTimer();
    }
  }
}
