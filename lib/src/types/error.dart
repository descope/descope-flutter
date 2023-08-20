/// The concrete type of `Exception` thrown by all operations in the Descope SDK.
///
/// There are several ways to catch and handle a `DescopeException` thrown by a Descope SDK
/// operation, and you can use whichever one is more appropriate in each specific use case.
///
///     try {
///       final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: loginId, code: code);
///       final session = DescopeSession.fromAuthenticationResponse(authResponse);
///     } on DescopeException catch (e) {
///       switch(e) {
///         case DescopeException.wrongOTPCode:
///         case DescopeException.invalidRequest:
///           showBadCodeAlert();
///         case DescopeException.networkError:
///           showNetworkErrorRetry();
///         default:
///           showUnexpectedErrorAlert(with: e);
///       }
///     } catch (e) {
///       // You can have a general catch-all as well
///       showUnexpectedErrorAlert(with: e);
///     }
class DescopeException implements Exception {
  // A list of common `DescopeException` values that can be thrown by the Descope SDK.

  /// Thrown when a call to the Descope API fails due to a network error.
  ///
  /// You can catch this kind of error to handle error cases such as the user being
  /// offline or the network request timing out.
  static const networkError = DescopeException._sdkError(code: 'F010001', desc: 'Network error');

  static const badRequest = DescopeException._apiError(code: 'E011001');
  static const missingArguments = DescopeException._apiError(code: 'E011002');
  static const invalidRequest = DescopeException._apiError(code: 'E011003');
  static const invalidArguments = DescopeException._apiError(code: 'E011004');

  static const wrongOTPCode = DescopeException._apiError(code: 'E061102');
  static const tooManyOTPAttempts = DescopeException._apiError(code: 'E061103');

  static const enchantedLinkPending = DescopeException._apiError(code: 'E062503');
  static const enchantedLinkExpired = DescopeException._sdkError(code: 'F060001', desc: 'Enchanted link expired');

  static const flowFailed = DescopeException._sdkError(code: 'F100001', desc: 'Flow failed to run');
  static const flowCancelled = DescopeException._sdkError(code: 'F100002', desc: 'Flow cancelled');

  /// A string of 7 characters that represents a specific Descope error.
  ///
  /// For example, the value of [code] is `"E011003"` when an API request fails validation.
  final String code;

  /// A short description of the error message.
  ///
  /// For example, the value of [desc] is `"Request is invalid"` when an API request
  /// fails validation.
  final String desc;

  /// An optional message with more details about the error.
  ///
  /// For example, the value of [message] might be `"The email field is required"` when
  /// attempting to authenticate via enchanted link with an empty email address.
  final String? message;

  /// An optional underlying error that caused this error.
  ///
  /// For example, when a [DescopeException.networkError] is caught the [cause] property
  /// will usually have the object thrown by the internal `http.Request` call.
  final dynamic cause;

  const DescopeException({
    required this.code,
    required this.desc,
    this.message,
    this.cause,
  });

  const DescopeException._sdkError({
    required String code,
    required String desc,
  }) : this(code: code, desc: desc);

  const DescopeException._apiError({required String code}) : this(code: code, desc: 'Descope API error');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DescopeException && other.code == code;
  }

  @override
  int get hashCode => Object.hash(code, desc);
}
