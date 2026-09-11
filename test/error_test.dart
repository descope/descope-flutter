import 'package:descope/descope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flowScriptletFailed matches a passthrough error reconstructed from the platform channel', () {
    // This mirrors how DescopeFlowView reconstructs a DescopeException from the raw
    // code/desc/message payload sent by the native iOS/Android SDKs over the platform channel.
    final received = DescopeException(code: 'S100003', desc: 'Flow scriptlet failed', message: 'USER_NOT_FOUND: no such user');
    expect(received, DescopeException.flowScriptletFailed);
    expect(received.code, DescopeException.flowScriptletFailed.code);
  });

  test('flowScriptletFailed does not match unrelated flow errors', () {
    expect(DescopeException.flowScriptletFailed, isNot(DescopeException.flowFailed));
    expect(DescopeException.flowScriptletFailed, isNot(DescopeException.flowCancelled));
  });
}
