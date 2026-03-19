import 'package:descope/src/internal/others/stubs/stub_html.dart';
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
      window.sessionStorage['key'] = 'value';
      expect(await store.loadItem('key'), 'value');
      expect(window.localStorage, isEmpty);
    });

    test('loadItem falls back to localStorage without clearing it', () async {
      window.localStorage['key'] = 'legacy';
      final result = await store.loadItem('key');
      expect(result, 'legacy');
      expect(window.localStorage.containsKey('key'), isTrue); // not cleared on load
    });

    test('loadItem returns null when nothing is stored', () async {
      expect(await store.loadItem('key'), isNull);
    });

    test('saveItem writes to sessionStorage and clears localStorage', () async {
      window.localStorage['key'] = 'legacy';
      await store.saveItem(key: 'key', data: 'value');
      expect(window.sessionStorage['key'], 'value');
      expect(window.localStorage.containsKey('key'), isFalse); // cleared on save
    });

    test('removeItem clears both sessionStorage and localStorage', () async {
      window.sessionStorage['key'] = 'new';
      window.localStorage['key'] = 'old';
      await store.removeItem('key');
      expect(window.sessionStorage.containsKey('key'), isFalse);
      expect(window.localStorage.containsKey('key'), isFalse);
    });
  });
}
