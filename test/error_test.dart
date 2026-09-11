import 'package:descope/descope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flowScriptletFailed passthrough errors from either native SDK carry the original thrown message', () {
    // This mirrors how DescopeFlowView reconstructs a DescopeException from the raw
    // code/desc/message payload sent by the native iOS/Android SDKs over the platform channel.
    // Each platform uses its own code for this error, so apps must match on message content
    // rather than comparing against DescopeException.flowScriptletFailed by equality.
    final fromIOS = DescopeException(code: 'S100003', desc: 'Flow scriptlet failed', message: 'USER_NOT_FOUND: no such user');
    final fromAndroid = DescopeException(code: 'K100004', desc: 'Flow scriptlet failed', message: 'USER_NOT_FOUND: no such user');
    expect(fromIOS.message, 'USER_NOT_FOUND: no such user');
    expect(fromAndroid.message, 'USER_NOT_FOUND: no such user');
    expect(fromIOS, isNot(DescopeException.flowScriptletFailed));
    expect(fromAndroid, isNot(DescopeException.flowScriptletFailed));
  });

  test('flowScriptletFailed does not match unrelated flow errors', () {
    expect(DescopeException.flowScriptletFailed, isNot(DescopeException.flowFailed));
    expect(DescopeException.flowScriptletFailed, isNot(DescopeException.flowCancelled));
  });
}
