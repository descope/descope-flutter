import 'package:flutter/services.dart';

import '/src/sdk/config.dart';

/// Bridges log streaming from native SDK layers (iOS/Android) to Flutter.
///
/// This class listens on the `descope_flutter/logs` MethodChannel and forwards
/// received native logs to the Flutter DescopeLogger, which filters based on
/// its own `level` and `unsafe` settings.
class NativeLogBridge {
  static const _logChannel = MethodChannel('descope_flutter/logs');
  static DescopeLogger? _logger;
  static bool _isInitialized = false;

  /// Sets the logger to receive native logs and initializes the channel listener.
  ///
  /// This should be called once during SDK initialization. If [logger] is null,
  /// native logging will not be initialized on the native side.
  static void pipeNativeLogs(DescopeLogger? logger) {
    _logger = logger;
    _initChannelIfNeeded();

    // Send logger configuration to native if a logger is set
    if (logger != null) {
      final levelString = switch (logger.level) {
        DescopeLogger.error => 'error',
        DescopeLogger.info => 'info',
        _ => 'debug',
      };
      _logChannel.invokeMethod('configure', {
        'level': levelString,
        'unsafe': logger.unsafe,
      });
    }
  }

  /// Ensures the channel listener is set up.
  static void _initChannelIfNeeded() {
    if (!_isInitialized) {
      _isInitialized = true;
      _logChannel.setMethodCallHandler(_handleNativeLog);
    }
  }

  static Future<dynamic> _handleNativeLog(MethodCall call) async {
    if (call.method == 'log') {
      final logger = _logger;
      if (logger == null) return;

      final args = call.arguments as Map<dynamic, dynamic>;
      final levelString = args['level'] as String;
      final message = args['message'] as String;
      final values = (args['values'] as List<dynamic>).cast<String>();

      // Convert level string to DescopeLogger level constant
      final int level;
      switch (levelString) {
        case 'error':
          level = DescopeLogger.error;
          break;
        case 'info':
          level = DescopeLogger.info;
          break;
        case 'debug':
        default:
          level = DescopeLogger.debug;
          break;
      }

      // Forward to the Flutter logger, which will filter based on its settings
      // Timestamp is available in `timestamp` variable for future ordering if needed
      logger.log(
        level: level,
        message: message,
        values: values,
      );
    }
  }
}

