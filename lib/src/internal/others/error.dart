import '/src/types/error.dart';

extension InternalErrors on DescopeException {
  /// Thrown if a call to the Descope API fails in an unexpected manner.
  ///
  /// This should only be thrown when there's no error response body to parse or the body
  /// isn't in the expected format. The value of [desc] is overwritten with a more specific
  /// value when possible.
  static const httpError = DescopeException(code: 'F010002', desc: 'Server request failed');

  /// Thrown if a response from the Descope API can't be parsed for an unexpected reason.
  static const decodeError = DescopeException(code: 'F010003', desc: 'Failed to decode response');

  /// Thrown if a request to the Descope API fails to encode for an unexpected reason.
  static const encodeError = DescopeException(code: 'F010004', desc: 'Failed to encode request');

  /// Thrown if a JWT string fails to decode.
  ///
  /// This might be thrown if the `DescopeSession` initializer is called with an invalid
  /// `sessionJwt` or `refreshJwt` value.
  static const tokenError = DescopeException(code: 'F010005', desc: 'Failed to parse token');

  DescopeException add({String? desc, String? message, dynamic cause}) => DescopeException(code: code, desc: desc ?? this.desc, message: message ?? this.message, cause: cause ?? this.cause);
}
