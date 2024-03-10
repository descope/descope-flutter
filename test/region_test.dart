import 'package:descope/src/internal/http/descope_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('region extraction from project ID', () {
    expect(baseUrlForProjectId(""), "https://api.descope.com");
    expect(baseUrlForProjectId("Puse"), "https://api.descope.com");
    expect(baseUrlForProjectId("Puse1ar"), "https://api.descope.com");
    expect(baseUrlForProjectId("Puse12aAc4T2V93bddihGEx2Ryhc8e5Z"), "https://api.use1.descope.com");
    expect(baseUrlForProjectId("Puse12aAc4T2V93bddihGEx2Ryhc8e5Zfoobar"), "https://api.use1.descope.com");
  });
}
