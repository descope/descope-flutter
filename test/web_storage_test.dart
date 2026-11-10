import 'package:descope/src/internal/others/stubs/stub_web.dart';
import 'package:descope/src/session/storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // SessionStorageWebStore uses the stub window's in-memory maps, so these
  // tests exercise the migration logic on non-web platforms without mocking.
  group('SessionStorageWebStore', () {
    late SessionStorageWebStore store;

    setUp(() {
      store = SessionStorageWebStore();
      window.localStorage.clear();
      window.sessionStorage.clear();
    });

    test('loadItem returns data from sessionStorage', () async {
      window.sessionStorage.setItem('key', 'value');
      expect(await store.loadItem('key'), 'value');
      expect(window.localStorage.getItem('key'), isNull);
    });

    test('loadItem falls back to localStorage and copies to sessionStorage', () async {
      window.localStorage.setItem('key', 'legacy');
      final result = await store.loadItem('key');
      expect(result, 'legacy');
      expect(window.sessionStorage.getItem('key'), 'legacy'); // copied to sessionStorage on load
      expect(window.localStorage.getItem('key'), isNotNull); // not cleared until next save
    });

    test('loadItem returns null when nothing is stored', () async {
      expect(await store.loadItem('key'), isNull);
    });

    test('saveItem writes to sessionStorage and clears localStorage', () async {
      window.localStorage.setItem('key', 'legacy');
      await store.saveItem(key: 'key', data: 'value');
      expect(window.sessionStorage.getItem('key'), 'value');
      expect(window.localStorage.getItem('key'), isNull); // cleared on save
    });

    test('removeItem clears both sessionStorage and localStorage', () async {
      window.sessionStorage.setItem('key', 'new');
      window.localStorage.setItem('key', 'old');
      await store.removeItem('key');
      expect(window.sessionStorage.getItem('key'), isNull);
      expect(window.localStorage.getItem('key'), isNull);
    });
  });
}
