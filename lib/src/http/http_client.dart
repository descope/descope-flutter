import 'dart:convert';

import 'package:http/http.dart' as http;

typedef ResponseDecoder<T> = T Function(Map<String, dynamic> json, Map<String, String> headers);

ResponseDecoder<void> emptyResponse = (json, headers) => {};

class HttpClient {
  final String baseURL;
  final _client = http.Client();

  HttpClient(this.baseURL) {
    attachFinalizer();
  }

  // Convenience functions

  Future<T> get<T>(String route, ResponseDecoder<T> decoder, {Map<String, String> headers = const {}, Map<String, String?> params = const {}}) async {
    final request = makeRequest(route, 'GET', headers, params.compacted(), null);
    return call(request, decoder);
  }

  Future<T> post<T>(String route, ResponseDecoder<T> decoder, {Map<String, String> headers = const {}, Map<String, String?> params = const {}, Map<String, dynamic> body = const {}}) async {
    final json = jsonEncode(body.compacted());
    final request = makeRequest(route, 'POST', headers, params.compacted(), json);
    return call(request, decoder);
  }

  // Override points

  String get basePath => '/';

  Map<String, String> get defaultHeaders => {};

  // Internal

  Future<T> call<T>(http.Request request, ResponseDecoder<T> decoder) async {
    final response = await sendRequest(request);
    final data = parseResponse(response);
    final json = jsonDecode(data) as Map<String, dynamic>;
    return decoder(json, response.headers);
  }

  http.Request makeRequest(String route, String method, Map<String, String> headers, Map<String, String> params, String? body) {
    final url = makeUrl(route, params);
    final request = http.Request(method, url);
    // TODO request.headers['User-Agent'] = '';
    if (body != null) {
      request.encoding = utf8;
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
    }
    request.headers.addAll(defaultHeaders);
    request.headers.addAll(headers);
    return request;
  }

  Uri makeUrl(String route, Map<String, String?> params) {
    var url = Uri.parse('$baseURL$basePath$route');
    if (params.isNotEmpty) {
      url = url.replace(queryParameters: params.compacted());
    }
    return url;
  }

  Future<http.Response> sendRequest(http.Request request) async {
    final stream = await _client.send(request);
    return http.Response.fromStream(stream);
  }

  String parseResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      // TODO parse error body
      throw Exception('Server request failed with status code ${response.statusCode}');
    }
    return response.body;
  }

  // Cleanup

  static final Finalizer<http.Client> _finalizer = Finalizer((client) => client.close()); // TODO test cleanup

  void attachFinalizer() {
    _finalizer.attach(this, _client);
  }
}

extension CompactMap<T> on Map<String, T?> {
  Map<String, T> compacted() {
    final result = <String, T>{};
    forEach((key, value) {
      if (value is Map<String, T?>) {
        result[key] = value.compacted() as T;
      } else if (value != null) {
        result[key] = value;
      }
    });
    return result;
  }
}
