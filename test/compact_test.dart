import 'package:descope/src/internal/http/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compacted map', () {
    Map<String, String?> params = {
      'a': 'b',
      'c': null,
    };
    expect(params.compacted(), {'a': 'b'});

    Map<String, dynamic> body = {
      'a': 'b',
      'c': null,
      'd': ['e', 'f'],
      'g': {'h': null, 'i': {'j': null}},
    };
    expect(body.compacted(), {'a': 'b', 'd': ['e', 'f'], 'g': {'i': {}}});
  });
}
