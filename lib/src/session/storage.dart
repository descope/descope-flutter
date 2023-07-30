import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import '/src/types/user.dart';
import 'manager.dart';
import 'session.dart';

part 'storage.g.dart';

/// This abstract class can be used to customize how a [DescopeSessionManager] object
/// stores the active [DescopeSession] between application launches.
abstract class DescopeSessionStorage {
  /// Called by the session manager when a new [DescopeSession] is set or an
  /// existing session is updated.
  void saveSession(DescopeSession session);

  /// Called by the session manager when it's initialized to load any
  /// existing [DescopeSession].
  DescopeSession? loadSession();

  /// Called by the session manager when the [DescopeSessionManager.clearSession] function
  /// is called.
  void removeSession();
}

/// The default implementation of the [DescopeSessionStorage].
///
/// For your convenience, you can implement the [Store] class and
/// override the [Store.loadItem], [Store.saveItem] and [Store.removeItem] functions,
/// then pass an instance of that class to the constructor to create a [SessionStorage] object
/// that uses a different backing store.
class SessionStorage implements DescopeSessionStorage {
  final String _projectId;
  final Store _store;
  _Value? _lastValue;

  SessionStorage(this._projectId, [this._store = const Store()]);

  @override
  void saveSession(DescopeSession session) {
    final value = _Value(session.sessionJwt, session.refreshJwt, session.user);
    if (value != _lastValue) {
      final json = jsonEncode(_Value.toJson(value));
      _store.saveItem(key: _projectId, data: json);
      _lastValue = value;
    }
  }

  @override
  DescopeSession? loadSession() {
    final data = _store.loadItem(_projectId);
    if (data != null) {
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        final value = _Value.fromJson(decoded);
        return DescopeSession.fromJwt(value.sessionJwt, value.refreshJwt, value.user);
      } on Exception {
        return null;
      }
    }
    return null;
  }

  @override
  void removeSession() {
    _lastValue = null;
    _store.removeItem(_projectId);
  }
}

/// A helper class that takes care of the actual storage of session data.
/// The default function implementations in this class do nothing or return `null`.
class Store {
  const Store();

  void saveItem({required String key, required String data}) {}

  String? loadItem(String key) => null;

  void removeItem(String key) {}
}

@JsonSerializable()
class _Value {
  String sessionJwt;
  String refreshJwt;
  DescopeUser user;

  _Value(this.sessionJwt, this.refreshJwt, this.user);

  static var fromJson = _$ValueFromJson;
  static var toJson = _$ValueToJson;
}
