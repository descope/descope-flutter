import 'package:descope/descope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('hosted constructor builds URL from project ID', () {
    final sdk = DescopeSdk('Puse12aAc4T2V93bddihGEx2Ryhc8e5Z');
    final config = DescopeFlowConfig.hosted('sign-in', sdk: sdk);
    expect(config.url, 'https://api.use1.descope.com/login/Puse12aAc4T2V93bddihGEx2Ryhc8e5Z?wide=true&platform=mobile&flow=sign-in');
  });

  test('hosted constructor uses custom baseUrl when configured', () {
    final sdk = DescopeSdk('Puse12aAc4T2V93bddihGEx2Ryhc8e5Z', (config) {
      config.baseUrl = 'https://auth.example.com';
    });
    final config = DescopeFlowConfig.hosted('sign-up', sdk: sdk);
    expect(config.url, 'https://auth.example.com/login/Puse12aAc4T2V93bddihGEx2Ryhc8e5Z?wide=true&platform=mobile&flow=sign-up');
  });
}
