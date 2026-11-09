@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:descope/descope.dart';
import 'package:descope/src/internal/others/system_info.dart';
import 'package:descope/src/internal/others/web_passkeys.dart';
import 'package:descope/src/session/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

const _jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ikdvb2dseSBNY0ZsdXR0ZXIiLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6Imh0dHBzOi8vZGVzY29wZS5jb20vYmxhL1AxMjMiLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.MuAWVKcw4xLNTvgTa-1lilcTcu8bd7sNV7xS55LD55M';

const _successDetail = {
  'sessionJwt': _jwt,
  'refreshJwt': _jwt,
  'firstSeen': true,
  'user': {
    'userId': 'U123',
    'loginIds': ['user@example.com'],
    'email': 'user@example.com',
    'verifiedEmail': true,
    'verifiedPhone': false,
    'createdTime': 1700000000,
    'customAttributes': {'level': 3, 'nested': {'flag': true}},
    'password': false,
    'status': 'enabled',
    'roleNames': ['admin'],
    'ssoAppIds': <String>[],
  },
};

@JS('JSON.parse')
external JSAny _jsonParse(String value);

void _dispatch(String type, Map<String, dynamic> detail) {
  final element = web.document.querySelector('descope-wc')!;
  element.dispatchEvent(web.CustomEvent(type, web.CustomEventInit(detail: _jsonParse(jsonEncode(detail)))));
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    debugPrint('Running browser tests compiled to ${kIsWasm ? 'wasm' : 'js'}');
    // keeps the real web component from loading and talking to the network, and
    // moves itself into a form when connected like the real one does
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.text = '''customElements.define('descope-wc', class extends HTMLElement {
      connectedCallback() {
        if (this.parentElement?.tagName === 'FORM') return;
        const form = document.createElement('form');
        this.replaceWith(form);
        form.appendChild(this);
      }
    });''';
    web.document.head!.append(script);
  });

  group('SessionStorageWebStore', () {
    final store = SessionStorageWebStore();

    setUp(() {
      web.window.localStorage.clear();
      web.window.sessionStorage.clear();
    });

    test('saves to sessionStorage and clears localStorage', () async {
      web.window.localStorage.setItem('key', 'legacy');
      await store.saveItem(key: 'key', data: 'value');
      expect(web.window.sessionStorage.getItem('key'), 'value');
      expect(web.window.localStorage.getItem('key'), isNull);
      expect(await store.loadItem('key'), 'value');
    });

    test('loads legacy value from localStorage and copies it', () async {
      web.window.localStorage.setItem('key', 'legacy');
      expect(await store.loadItem('key'), 'legacy');
      expect(web.window.sessionStorage.getItem('key'), 'legacy');
    });

    test('removes from both storages', () async {
      web.window.sessionStorage.setItem('key', 'new');
      web.window.localStorage.setItem('key', 'old');
      await store.removeItem('key');
      expect(web.window.sessionStorage.getItem('key'), isNull);
      expect(web.window.localStorage.getItem('key'), isNull);
      expect(await store.loadItem('key'), isNull);
    });
  });

  group('SystemInfo', () {
    test('detects the browser', () async {
      final info = await SystemInfo.get();
      expect(info.platformName, 'chromium');
      expect(info.platformVersion, isNotEmpty);
    });
  });

  group('WebPasskeys', () {
    test('reports support without throwing', () {
      expect(WebPasskeys().isSupported(), isA<bool>());
    });

    test('returns the window origin', () {
      expect(WebPasskeys().getOrigin(), web.window.location.origin);
    });
  });

  group('Web flow', () {
    // ignore: deprecated_member_use_from_same_package
    late DescopeFlow flow;

    setUp(() {
      // ignore: deprecated_member_use_from_same_package
      flow = DescopeSdk('P123').flow;
    });

    test('mounts the web component and completes on success', () async {
      final future = flow.start(DescopeFlowOptions(web: DescopeWebFlowOptions(flowId: 'sign-in')));

      final wc = web.document.querySelector('descope-wc');
      expect(wc, isNotNull);
      expect(wc!.getAttribute('project-id'), 'P123');
      expect(wc.getAttribute('flow-id'), 'sign-in');
      expect(web.document.querySelector('.web-component-style'), isNotNull);

      _dispatch('ready', {});
      expect(web.document.querySelector('.login-container'), isNotNull);

      _dispatch('success', _successDetail);
      final response = await future;
      expect(response.sessionToken.jwt, _jwt);
      expect(response.isFirstAuthentication, isTrue);
      expect(response.user.userId, 'U123');
      expect(response.user.loginIds, ['user@example.com']);
      expect(response.user.createdAt, 1700000000);
      expect(response.user.customAttributes['level'], 3);
      expect(web.document.querySelector('descope-wc'), isNull);
      expect(web.document.querySelector('.login-container'), isNull);
    });

    test('fails with the flow error message', () async {
      final future = flow.start(DescopeFlowOptions(web: DescopeWebFlowOptions(flowId: 'sign-in')));
      _dispatch('ready', {});
      _dispatch('error', {'errorMessage': 'boom'});
      await expectLater(future, throwsA(isA<DescopeException>().having((e) => e.message, 'message', contains('boom'))));
      expect(web.document.querySelector('descope-wc'), isNull);
    });

    test('removes the hidden container when cancelled before ready', () async {
      final future = flow.start(DescopeFlowOptions(web: DescopeWebFlowOptions(flowId: 'sign-in')));
      expect(web.document.querySelector('.hidden-container'), isNotNull);
      flow.cancel();
      await expectLater(future, throwsA(DescopeException.flowCancelled));
      expect(web.document.querySelector('descope-wc'), isNull);
      expect(web.document.querySelector('.hidden-container'), isNull);
    });
  });
}
