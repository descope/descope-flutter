import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '/src/internal/others/stubs/stub_html.dart' if (dart.library.js) 'dart:html' hide Platform;

class SystemInfo {
  String platformName = '';
  String platformVersion = '';
  String appName = '';
  String appVersion = '';
  String device = '';

  static Future<SystemInfo> get() async {
    final systemInfo = _instance ?? await _create();
    _instance ??= systemInfo;
    return systemInfo;
  }

  // Singleton

  SystemInfo._();

  static SystemInfo? _instance;

  static Future<SystemInfo> _create() async {
    if (kIsWeb) {
      return await _createWeb();
    }
    return await _createMobile();
  }

  // Mobile

  static const _mChannel = MethodChannel('descope_flutter/methods');

  static Future<SystemInfo> _createMobile() async {
    final systemInfo = SystemInfo._();
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        Map<Object?, Object?> data = await _mChannel.invokeMethod('getSystemInfo');
        systemInfo.platformName = data['platformName'] as String? ?? '';
        systemInfo.platformVersion = data['platformVersion'] as String? ?? '';
        systemInfo.appName = data['appName'] as String? ?? '';
        systemInfo.appVersion = data['appVersion'] as String? ?? '';
        systemInfo.device = data['device'] as String? ?? '';
      } catch (e) {
        // ignore
      }
    }
    return systemInfo;
  }

  // Web

  static const _versionPattern = r'(MSIE|(?!Gecko.+)Firefox|(?!AppleWebKit.+Chrome.+)Safari|(?!AppleWebKit.+)Chrome|AppleWebKit(?!.+Chrome|.+Safari)|Gecko(?!.+Firefox))(?: |\/)([\d\.apre]+)';

  static Future<SystemInfo> _createWeb() async {
    final systemInfo = SystemInfo._();

    try {
      final agent = window.navigator.userAgent;
      final vendor = window.navigator.vendor;

      // see: https://github.com/flutter/flutter/blob/7cfaf04fa9781d5287af8b348ea1cc1cf5ef701d/engine/src/flutter/lib/web_ui/lib/ui_web/src/ui_web/browser_detection.dart
      if (vendor == 'Google Inc.') {
        systemInfo.platformName = 'chromium';
      } else if (vendor == 'Apple Computer, Inc.') {
        systemInfo.platformName = 'webkit';
      } else if (agent.contains('Edg/')) {
        systemInfo.platformName = 'edge';
      } else if (vendor == '' && agent.contains('firefox')) {
        systemInfo.platformName = 'firefox';
      }

      final regexp = RegExp(_versionPattern);
      final match = regexp.firstMatch(agent);
      if (match != null && match.groupCount == 2) {
        systemInfo.platformVersion = match[2] ?? '';
        if (systemInfo.platformName.isEmpty) {
          final browser = (match[1] ?? '').toLowerCase();
          if (browser == 'chrome') {
            systemInfo.platformName = agent.contains('Edg/') ? 'edge' : 'chromium';
          } else if (browser == 'safari') {
            systemInfo.platformName = 'webkit';
          } else {
            systemInfo.platformName = browser;
          }
        }
      }
    } catch (e) {
      // ignore
    }

    return systemInfo;
  }
}
