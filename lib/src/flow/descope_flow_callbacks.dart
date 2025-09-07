
import '/src/types/error.dart';
import '/src/types/responses.dart';

/// The [DescopeFlowCallbacks] class is used to communicate Flow lifecycle events back to the caller.
class DescopeFlowCallbacks {
  /// Called when a flow is fully loaded and ready to be displayed
  void Function()? onReady;
  /// Called with an [AuthenticationResponse] when a flow has completed successfully.
  /// Typically create a [DescopeSession] and manage it using [Descope.sessionManager]
  void Function(AuthenticationResponse)? onSuccess;
  /// Called with a [DescopeException] when a flow has encountered an error.
  /// Typically a flow will not to be restarted at this point.
  void Function(DescopeException error)? onError;

  DescopeFlowCallbacks({this.onReady, this.onSuccess, this.onError});
}
