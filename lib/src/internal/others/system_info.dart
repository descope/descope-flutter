import 'dart:io';
import 'dart:ui_web' as uiweb;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

    systemInfo.platformName = 'chromium';
    if (uiweb.browser.isSafari) {
      systemInfo.platformName = 'safari';
    } else if (uiweb.browser.isFirefox) {
      systemInfo.platformName = 'firefox';
    } else if (uiweb.browser.isEdge) {
      systemInfo.platformName = 'edge';
    }

    if (uiweb.browser.isMobile) {
      systemInfo.platformName = 'mobile ${systemInfo.platformName}';
    }

    try {
      final regexp = RegExp(_versionPattern);
      final match = regexp.firstMatch(uiweb.browser.userAgent);
      if (match != null && match.groupCount == 2) {
        systemInfo.platformVersion = match[2] ?? '';
      }
    } catch (e) {
      // ignore
    }

    return systemInfo;
  }
}
