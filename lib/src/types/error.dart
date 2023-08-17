/// A list of common `DescopeException` values that can be thrown by the Descope SDK.
class DescopeException implements Exception {
  /// Thrown when a call to the Descope API fails due to a network error.
  ///
  /// You can catch this kind of error to handle error cases such as the user being
  /// offline or the network request timing out.
  static const networkError = DescopeException._sdkError(code: 'S010001', desc: 'Network error');

  static const badRequest = DescopeException._apiError(code: 'E011001');
  static const missingArguments = DescopeException._apiError(code: 'E011002');
  static const invalidRequest = DescopeException._apiError(code: 'E011003');
  static const invalidArguments = DescopeException._apiError(code: 'E011004');

  static const wrongOTPCode = DescopeException._apiError(code: 'E061102');
  static const tooManyOTPAttempts = DescopeException._apiError(code: 'E061103');

  static const enchantedLinkPending = DescopeException._apiError(code: 'E062503');
  static const enchantedLinkExpired = DescopeException._sdkError(code: 'S060001', desc: 'Enchanted link expired');

  static const flowFailed = DescopeException._sdkError(code: 'S100001', desc: 'Flow failed to run');
  static const flowCancelled = DescopeException._sdkError(code: 'S100002', desc: 'Flow cancelled');

  final String code;
  final String desc;
  final String? message;
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
