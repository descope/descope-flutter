import 'package:descope/src/session/token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jwt decoding', () {
    const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ikdvb2dseSBNY0ZsdXR0ZXIiLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6Imh0dHBzOi8vZGVzY29wZS5jb20vYmxhL1AxMjMiLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.MuAWVKcw4xLNTvgTa-1lilcTcu8bd7sNV7xS55LD55M';

    var token = Token.decode(jwt);

    // Token decode failure
    try {
      Token.decode('');
      throw 'Empty string decode should fail';
    } on Exception {
      // ok
    }

    // Basic fields
    expect(token.jwt, jwt);
    expect(token.id, '1234567890');
    expect(token.projectId, 'P123');

    // Expiration
    expect(token.expiresAt?.day, 20);
    expect(token.expiresAt?.month, 10);
    expect(token.expiresAt?.year, 2020);
    expect(token.isExpired, true);

    // Custom claims
    expect(token.customClaims.length, 1);
    expect(token.customClaims['name'], 'Googly McFlutter');

    // Authorization
    expect(token.getPermissions(tenant: null), <String>['d', 'e']);
    expect(token.getRoles(tenant: null), <String>['user']);

    // Tenant Authorization
    expect(token.getPermissions(tenant: 'tenant'), <String>['a', 'b', 'c']);
    expect(token.getRoles(tenant: 'tenant'), <String>['admin']);

    // Missing tenant
    expect(token.getPermissions(tenant: 'no-such-tenant'), <String>[]);
    expect(token.getRoles(tenant: 'no-such-tenant'), <String>[]);
  });
}
