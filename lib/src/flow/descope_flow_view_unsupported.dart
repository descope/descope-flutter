import 'package:flutter/widgets.dart';

import '/src/flow/descope_flow_callbacks.dart';
import '/src/flow/descope_flow_config.dart';
import '/src/internal/others/error.dart';
import '/src/types/error.dart';

/// Stub implementation for DescopeFlowController on unsupported platforms.
class DescopeFlowController {
  void resumeFromDeepLink(Uri uri) {
    // No-op
  }
}

/// A widget that displays a Descope flow.
///
/// **Note:** This feature is only available on Android and iOS.
class DescopeFlowView extends StatelessWidget {
  final DescopeFlowConfig config;
  final DescopeFlowCallbacks? callbacks;
  final DescopeFlowController? controller;

  const DescopeFlowView({
    super.key,
    required this.config,
    this.callbacks,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callbacks?.onError?.call(DescopeException.flowFailed.add(message: 'DescopeFlowView is not supported on this platform'));
    });
    return const SizedBox.shrink();
  }
}
