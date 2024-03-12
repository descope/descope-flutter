import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

import '/src/internal/others/stub_html.dart' if (dart.library.js) 'dart:html' hide Platform;
import '/src/types/user.dart';
import 'manager.dart';
import 'session.dart';

part 'storage.g.dart';

/// This abstract class can be used to customize how a [DescopeSessionManager] object
/// stores the active [DescopeSession] between application launches.
abstract class DescopeSessionStorage {
  /// Called by the session manager when a new [DescopeSession] is set or an
  /// existing session is updated.
  Future<void> saveSession(DescopeSession session);

  /// Called by the session manager when it's initialized to load any
  /// existing [DescopeSession].
  Future<DescopeSession?> loadSession();

  /// Called by the session manager when the [DescopeSessionManager.clearSession] function
  /// is called.
  Future<void> removeSession();
}

/// The default implementation of the [DescopeSessionStorage].
///
/// By default this class persists the session securely to the keychain on iOS, or
/// vie `EncryptedSharedPreferences` on Android.
/// For your convenience, you can implement the [Store] class and
/// override the [Store.loadItem], [Store.saveItem] and [Store.removeItem] functions,
/// then pass an instance of that class to the constructor to create a [SessionStorage] object
/// that uses a different backing store.
class SessionStorage implements DescopeSessionStorage {
  final String _projectId;
  final SessionStorageStore _store;
  _Value? _lastValue;

  SessionStorage({required String projectId, SessionStorageStore? store})
      : _projectId = projectId,
        _store = store ?? SessionStorageMobileStore.ifSupported() ?? SessionStorageWebStore.ifSupported() ?? const SessionStorageStore();

  @override
  Future<void> saveSession(DescopeSession session) async {
    final value = _Value(session.sessionJwt, session.refreshJwt, session.user);
    if (value != _lastValue) {
      final json = jsonEncode(_Value.toJson(value));
      _store.saveItem(key: _projectId, data: json);
      _lastValue = value;
    }
  }

  @override
  Future<DescopeSession?> loadSession() async {
    final data = await _store.loadItem(_projectId);
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
  Future<void> removeSession() async {
    _lastValue = null;
    _store.removeItem(_projectId);
  }
}

/// A helper class that takes care of the actual storage of session data. The default
/// function implementations in this class do nothing or return `null`.
class SessionStorageStore {
  const SessionStorageStore();

  Future<void> saveItem({required String key, required String data}) async {}

  Future<String?> loadItem(String key) async => null;

  Future<void> removeItem(String key) async {}
}

class SessionStorageMobileStore implements SessionStorageStore {
  static const _mChannel = MethodChannel('descope_flutter/methods');

  SessionStorageMobileStore();

  static SessionStorageMobileStore? ifSupported() {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      return SessionStorageMobileStore();
    }
    return null;
  }

  @override
  Future<String?> loadItem(String key) async {
    final result = await _mChannel.invokeMethod('loadItem', {'key': key});
    if (result == null) {
      return null;
    }
    try {
      final serialized = result as String;
      return serialized;
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> removeItem(String key) async {
    await _mChannel.invokeMethod('removeItem', {'key': key});
  }

  @override
  Future<void> saveItem({required String key, required String data}) async {
    await _mChannel.invokeMethod('saveItem', {'key': key, 'data': data});
  }
}

class SessionStorageWebStore implements SessionStorageStore {
  final Storage _localStorage = window.localStorage;

  static SessionStorageWebStore? ifSupported() {
    return kIsWeb ? SessionStorageWebStore() : null;
  }

  @override
  Future<String?> loadItem(String key) async {
    return _localStorage[key];
  }

  @override
  Future<void> removeItem(String key) async {
    _localStorage.remove(key);
  }

  @override
  Future<void> saveItem({required String key, required String data}) async {
    _localStorage[key] = data;
  }
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
