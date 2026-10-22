import 'package:descope/descope.dart';
import 'package:descope/src/internal/http/descope_client.dart';
import 'package:descope/src/internal/http/http_client.dart';
import 'package:descope/src/internal/others/error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('server error carries traceId from cf-ray header', () async {
    final client = _mockClient(400, '{"errorCode":"E061102","errorDescription":"server description"}', headers: {'CF-Ray': '8c8e3f5a1b2c3d4e-TLV'});
    final e = await _expectException(client);
    expect(e, DescopeException.wrongOTPCode);
    expect(e.traceId, '8c8e3f5a1b2c3d4e-TLV');
  });

  test('http error carries traceId from cf-ray header', () async {
    final client = _mockClient(500, 'internal error', headers: {'cf-ray': '8c8e3f5a1b2c3d4e-TLV'});
    final e = await _expectException(client);
    expect(e, InternalErrors.httpError);
    expect(e.traceId, '8c8e3f5a1b2c3d4e-TLV');
  });

  test('error without cf-ray header has null traceId', () async {
    final client = _mockClient(400, '{"errorCode":"E061102","errorDescription":"server description"}');
    final e = await _expectException(client);
    expect(e, DescopeException.wrongOTPCode);
    expect(e.traceId, isNull);
  });

  test('successful response is decoded', () async {
    final client = _mockClient(200, '{"value":"response body"}');
    expect(await client.post('auth/test', (json, headers) => json['value']), 'response body');
  });
}

DescopeClient _mockClient(int statusCode, String body, {Map<String, String> headers = const {}}) {
  final config = DescopeConfig(projectId: 'P123', baseUrl: 'https://example.com', networkClient: _MockNetworkClient(http.Response(body, statusCode, headers: headers)));
  return DescopeClient(config);
}

Future<DescopeException> _expectException(DescopeClient client) async {
  try {
    await client.post('auth/test', emptyResponse);
  } on DescopeException catch (e) {
    return e;
  }
  fail('Expected a DescopeException to be thrown');
}

class _MockNetworkClient extends DescopeNetworkClient {
  final http.Response response;

  _MockNetworkClient(this.response);

  @override
  Future<http.Response> sendRequest(http.Request request) async => response;
}
