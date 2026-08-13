import 'package:descope/src/internal/http/responses.dart';
import 'package:descope/src/internal/routes/shared.dart';
import 'package:flutter_test/flutter_test.dart';

const _jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ikdvb2dseSBNY0ZsdXR0ZXIiLCJpYXQiOjE1MTYyMzkwMjIsImlzcyI6Imh0dHBzOi8vZGVzY29wZS5jb20vYmxhL1AxMjMiLCJleHAiOjE2MDMxNzY2MTQsInBlcm1pc3Npb25zIjpbImQiLCJlIl0sInJvbGVzIjpbInVzZXIiXSwidGVuYW50cyI6eyJ0ZW5hbnQiOnsicGVybWlzc2lvbnMiOlsiYSIsImIiLCJjIl0sInJvbGVzIjpbImFkbWluIl19fX0.MuAWVKcw4xLNTvgTa-1lilcTcu8bd7sNV7xS55LD55M';

Map<String, dynamic> _payload({Map<String, dynamic>? flowOutput}) => {
      'sessionJwt': _jwt,
      'refreshJwt': _jwt,
      'firstSeen': true,
      'user': {
        'userId': 'userId',
        'loginIds': ['loginId'],
        'verifiedEmail': true,
        'verifiedPhone': false,
        'createdTime': 1234567890,
        'password': false,
        'status': 'enabled',
        'roleNames': <String>[],
        'ssoAppIds': <String>[],
      },
      if (flowOutput != null) 'flowOutput': flowOutput,
    };

void main() {
  test('flow output is parsed when present', () {
    final response = JWTServerResponse.fromJson(_payload(flowOutput: {
      'key': 'value',
      'count': 3,
      'nested': {'inner': true},
    })).toAuthenticationResponse();

    expect(response.flowOutput['key'], 'value');
    expect(response.flowOutput['count'], 3);
    expect((response.flowOutput['nested'] as Map)['inner'], true);
  });

  test('flow output is empty when missing', () {
    final response = JWTServerResponse.fromJson(_payload()).toAuthenticationResponse();
    expect(response.flowOutput, isEmpty);
  });
}
