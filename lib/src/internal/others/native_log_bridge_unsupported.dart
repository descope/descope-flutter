import '/src/sdk/config.dart';

/// Stub implementation for NativeLogBridge on unsupported platforms.
///
/// Native log bridging is only available on iOS and Android. On other platforms,
/// this no-op implementation is used.
class NativeLogBridge {
  /// No-op on unsupported platforms.
  ///
  /// Native log bridging requires platform-specific MethodChannel communication
  /// which is only implemented on iOS and Android.
  static void pipeNativeLogs(DescopeLogger? logger) {
    // No-op on unsupported platforms
  }
}

