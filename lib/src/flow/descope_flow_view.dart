// If imported on flutter web, a no-op stub will be used.
// Beyond that, unfortunately flutter won't let export mobile only
// so we must use platform checks in the code as well
export 'descope_flow_view_unsupported.dart' if (dart.library.io) 'descope_flow_view_native.dart';
