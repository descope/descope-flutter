import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/src/sdk/sdk.dart';

/// The configuration of the Descope SDK.
class DescopeConfig {
  /// The id of the Descope project.
  String projectId;

  /// An optional override for the base URL of the Descope server,
  /// in case you need to access it through a CNAME record.
  String? baseUrl;

  /// An optional object to handle logging in the Descope SDK.
  ///
  /// The default value of this property is `null` and thus logging will be completely
  /// disabled. During development if you encounter any issues you can create an
  /// instance of the [DescopeLogger] class to enable logging.
  ///
  ///     Descope.config = DescopeConfig(projectId: "...", logger: DescopeLogger())
  ///
  /// If your application uses some logging framework or third party service you can forward
  /// the Descope SDK log messages to it by creating a new subclass of [DescopeLogger] and
  /// overriding the [DescopeLogger.output] method.
  DescopeLogger? logger;

  /// An optional object to override how HTTP requests are performed.
  ///
  /// The default value of this property is always `null`, and the SDK uses its own
  /// internal client object to perform HTTP requests.
  ///
  /// This property can be useful to test code that uses the Descope SDK without any
  /// network requests actually taking place. In most other cases there shouldn't be
  /// any need to use it.
  DescopeNetworkClient? networkClient;

  /// Creates a new `DescopeConfig` object.
  DescopeConfig({required this.projectId, this.baseUrl, this.logger, this.networkClient});
}

/// The [DescopeLogger] class can be used to customize logging functionality in the Descope SDK.
///
/// The default behavior is for log messages to be written to the standard output using
/// the `print()` function.
///
/// You can also customize how logging functions in the Descope SDK by creating a subclass
/// of [DescopeLogger] and overriding the [DescopeLogger.output] method. See the
/// documentation for that method for more details.
class DescopeLogger {
  /// The severity of a log message.
  static const error = 0;
  static const info = 1;
  static const debug = 2;

  /// The maximum log level that should be printed.
  int level;

  /// Creates a new [DescopeLogger] object. Log level defaults to `debug`
  DescopeLogger({this.level = debug});

  /// Formats the log message and prints it.
  ///
  /// Override this method to customize how to handle log messages from the Descope SDK.
  /// The [message] parameter is guaranteed to be a constant compile-time string, so
  /// you can assume it doesn't contain private user data or secrets and that it can
  /// be sent to whatever logging target or service you use.
  /// The [debug] array has runtime values that might be useful when debugging
  /// issues with the Descope SDK. Since it might contain sensitive information
  /// its contents are only provided in `debug` builds. In `release` builds it
  /// is always an empty array.
  void output({required int level, required String message, required List<dynamic> debug}) {
    var text = "[${DescopeSdk.name}] $message";
    if (debug.isNotEmpty) {
      text += " (${debug.map((v) => v.toString()).join(", ")})";
    }
    // ignore: avoid_print
    print(text);
  }

  /// Called by other code in the Descope SDK to output log messages.
  void log({required int level, required String message, List<dynamic> values = const []}) {
    if (level <= this.level) {
      output(level: level, message: message, debug: kDebugMode ? values : const []);
    }
  }
}

/// The [DescopeNetworkClient] abstract class can be used to override how HTTP requests
/// are performed by the SDK when calling the Descope server.
///
/// If you want to provide your own client for testing or other purposes, implement the
/// [sendRequest] function and either return some value or throw an exception.
abstract class DescopeNetworkClient {
  /// Send a [request] and expect an [http.Response] to be returned asynchronously
  /// or an exception to be thrown
  Future<http.Response> sendRequest(http.Request request);
}
