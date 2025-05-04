import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/src/internal/others/error.dart';
import '/src/sdk/config.dart';
import '/src/types/error.dart';

typedef ResponseDecoder<T> = T Function(Map<String, dynamic> json, Map<String, String> headers);

ResponseDecoder<void> emptyResponse = (json, headers) => {};

class HttpClient {
  final String baseUrl;
  final DescopeLogger? logger;
  final DescopeNetworkClient networkClient;

  HttpClient(this.baseUrl, this.logger, DescopeNetworkClient? client) : networkClient = client ?? _DefaultNetworkClient();

  // Convenience functions

  Future<T> get<T>(String route, ResponseDecoder<T> decoder, {Map<String, String> headers = const {}, Map<String, String?> params = const {}}) async {
    final request = await makeRequest(route, 'GET', headers, params.compacted(), null);
    return call(request, decoder);
  }

  Future<T> post<T>(String route, ResponseDecoder<T> decoder, {Map<String, String> headers = const {}, Map<String, String?> params = const {}, Map<String, dynamic> body = const {}}) async {
    String json;
    try {
      json = jsonEncode(body.compacted());
      if (kDebugMode) {
        logger?.log(level: DescopeLogger.debug, message: 'Preparing request body', values: [json]);
      }
    } catch (e) {
      throw InternalErrors.encodeError.add(cause: e);
    }
    final request = await makeRequest(route, 'POST', headers, params.compacted(), json);
    return call(request, decoder);
  }

  // Override points

  String get basePath => '/';

  Future<Map<String, String>> get defaultHeaders async => {};

  DescopeException? exceptionFromResponse(String response) {
    return null;
  }

  // Internal

  Future<T> call<T>(http.Request request, ResponseDecoder<T> decoder) async {
    logger?.log(level: DescopeLogger.info, message: 'Starting network call', values: [request.url]);
    final response = await networkClient.sendRequest(request);
    if (kDebugMode) {
      logger?.log(level: DescopeLogger.debug, message: 'Received response body', values: [request.url, response.body]);
    }
    try {
      final data = parseResponse(response);
      final json = jsonDecode(data) as Map<String, dynamic>;
      return decoder(json, response.headers);
    } catch (e) {
      if (e == DescopeException.networkError) {
        logger?.log(level: DescopeLogger.info, message: 'Network called failed with http error', values: [request.url, e]);
      } else {
        logger?.log(level: DescopeLogger.info, message: 'Network called failed with server error', values: [request.url, e]);
      }
      rethrow;
    }
  }

  Future<http.Request> makeRequest(String route, String method, Map<String, String> headers, Map<String, String> params, String? body) async {
    final url = makeUrl(route, params);
    final request = http.Request(method, url);
    // TODO request.headers['User-Agent'] = '';
    if (body != null) {
      request.encoding = utf8;
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
    }
    request.headers.addAll(await defaultHeaders);
    request.headers.addAll(headers);
    return request;
  }

  Uri makeUrl(String route, Map<String, String?> params) {
    var url = Uri.parse('$baseUrl$basePath$route');
    if (params.isNotEmpty) {
      url = url.replace(queryParameters: params.compacted());
    }
    return url;
  }

  String parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return response.body;
    }
    throw exceptionFromResponse(response.body) ?? generalServerError(response.statusCode);
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

// Errors

const String invalidResponse = 'The server returned an unexpected response';

DescopeException generalServerError(int statusCode) {
  String desc;
  switch (statusCode) {
    case 400:
      desc = 'The request was invalid';
      break;
    case 401:
      desc = 'The request was unauthorized';
      break;
    case 403:
      desc = 'The request was forbidden';
      break;
    case 404:
      desc = 'The resource was not found';
      break;
    case 500:
    case 503:
      desc = 'The server failed with status code $statusCode';
      break;
    default:
      desc = statusCode >= 500 ? 'The server was unreachable' : 'The server returned status code $statusCode';
  }
  return InternalErrors.httpError.add(desc: desc);
}

// Default Network Client

class _DefaultNetworkClient extends DescopeNetworkClient {
  final _client = http.Client();

  _DefaultNetworkClient() {
    attachFinalizer();
  }

  @override
  Future<http.Response> sendRequest(http.Request request) async {
    final stream = await _client.send(request);
    try {
      return http.Response.fromStream(stream);
    } catch (e) {
      throw InternalErrors.httpError.add(desc: invalidResponse);
    }
  }

  // Cleanup

  static final Finalizer<http.Client> _finalizer = Finalizer((client) => client.close()); // TODO test cleanup

  void attachFinalizer() {
    _finalizer.attach(this, _client);
  }
}
