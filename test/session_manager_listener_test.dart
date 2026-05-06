import 'package:descope/descope.dart';
import 'package:descope/src/session/token.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingListener implements DescopeSessionManagerListener {
  final List<String> tokenEvents = [];
  final List<String> userEvents = [];

  @override
  void onUpdateTokens(DescopeSession session) {
    tokenEvents.add(session.sessionJwt);
  }

  @override
  void onUpdateUser(DescopeSession session) {
    userEvents.add(session.user.userId);
  }
}

class _MemoryStorage implements DescopeSessionStorage {
  DescopeSession? saved;
  int saveCount = 0;

  @override
  Future<DescopeSession?> loadSession() async => saved;

  @override
  Future<void> removeSession() async {
    saved = null;
  }

  @override
  Future<void> saveSession(DescopeSession session) async {
    saved = session;
    saveCount++;
  }
}

class _NoopLifecycle implements DescopeSessionLifecycle {
  @override
  DescopeSession? session;

  @override
  void Function()? onRefresh;

  @override
  Future<void> refreshSessionIfNeeded() async {}
}

// Three distinct JWT strings sharing a valid header.payload (lifted from
// jwt_test.dart) with different signature suffixes, so Token.decode succeeds
// and the manager's string comparison treats them as distinct.
const _jwtHeaderPayload =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ikdvb2dseSBNY0ZsdXR0ZXIiLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6Imh0dHBzOi8vZGVzY29wZS5jb20vYmxhL1AxMjMiLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0';
const _jwtA = '$_jwtHeaderPayload.sigA';
const _jwtB = '$_jwtHeaderPayload.sigB';
const _jwtC = '$_jwtHeaderPayload.sigC';

DescopeUser _user(String id) => DescopeUser(
      id,
      const ['someone@example.com'],
      0,
      null,
      null,
      'someone@example.com',
      true,
      null,
      false,
      const {},
      null,
      null,
      null,
      false,
      'enabled',
      const [],
      const [],
      const [],
    );

DescopeSession _session({String session = _jwtA, String refresh = _jwtB, String userId = 'u1'}) {
  return DescopeSession.fromJwt(session, refresh, _user(userId));
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('DescopeSessionManager listeners', () {
    late _MemoryStorage storage;
    late _NoopLifecycle lifecycle;
    late DescopeSessionManager manager;
    late _RecordingListener listener;

    setUp(() {
      storage = _MemoryStorage();
      lifecycle = _NoopLifecycle();
      manager = DescopeSessionManager(storage, lifecycle);
      listener = _RecordingListener();
      manager.addListener(listener);
    });

    test('manageSession fires token and user events on first set', () {
      final session = _session();
      manager.manageSession(session);
      expect(listener.tokenEvents, [session.sessionJwt]);
      expect(listener.userEvents, [session.user.userId]);
    });

    test('manageSession with identical jwts and user does not fire events', () {
      final session = _session();
      manager.manageSession(session);
      listener.tokenEvents.clear();
      listener.userEvents.clear();

      manager.manageSession(_session());
      expect(listener.tokenEvents, isEmpty);
      expect(listener.userEvents, isEmpty);
    });

    test('manageSession with different jwts fires only tokens event', () {
      final initial = _session();
      manager.manageSession(initial);
      listener.tokenEvents.clear();
      listener.userEvents.clear();

      final rotated = DescopeSession.fromJwt(_jwtC, _jwtB, initial.user);
      manager.manageSession(rotated);
      expect(listener.tokenEvents, [_jwtC]);
      expect(listener.userEvents, isEmpty);
    });

    test('updateTokens fires onUpdateTokens', () {
      manager.manageSession(_session());
      listener.tokenEvents.clear();

      final newSessionToken = Token.decode(_jwtC);
      final newRefreshToken = Token.decode(_jwtB);
      manager.updateTokens(RefreshResponse(newSessionToken, newRefreshToken));
      expect(listener.tokenEvents, [_jwtC]);
    });

    test('updateUser fires onUpdateUser', () {
      manager.manageSession(_session());
      listener.userEvents.clear();

      manager.updateUser(_user('u2'));
      expect(listener.userEvents, ['u2']);
    });

    test('removeListener stops further events', () {
      manager.manageSession(_session());
      manager.removeListener(listener);
      listener.tokenEvents.clear();
      listener.userEvents.clear();

      manager.updateTokens(RefreshResponse(Token.decode(_jwtC), Token.decode(_jwtB)));
      manager.updateUser(_user('u9'));
      expect(listener.tokenEvents, isEmpty);
      expect(listener.userEvents, isEmpty);
    });
  });
}
