// Native log bridging is only available on iOS and Android.
// On other platforms, a no-op stub will be used.
export 'native_log_bridge_unsupported.dart' if (dart.library.io) 'native_log_bridge_native.dart';

