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
///
/// You can set the logger to [DescopeLogger.basicLogger] to print error and info
/// log messages to the console.
///
/// If you encounter any issues you can also use [DescopeLogger.debugLogger] to enable
/// more verbose logging. This will configure a simple logger that prints all logs to the
/// console. If the app is built in debug mode it will also output potentially sensitive
/// runtime values, such as full network request and response payloads, secrets and tokens
/// in cleartext, etc.
///
/// In rare cases you might need to use [DescopeLogger.unsafeLogger] which skips the
/// debug mode check and always prints all log data including all sensitive runtime values.
/// Make sure you don't use [DescopeLogger.unsafeLogger] in release builds intended
/// for production.
class DescopeLogger {
  /// The severity of a log message.
  static const error = 0;
  static const info = 1;
  static const debug = 2;

  /// A simple logger that prints basic error and info logs to the console.
  static final basicLogger = DescopeLogger(level: info, unsafe: false);

  /// A simple logger that prints all logs to the console, but does not output any
  /// potentially unsafe runtime values unless the app is built in debug mode.
  static final debugLogger = DescopeLogger(level: debug, unsafe: kDebugMode);

  /// A simple logger that prints all logs to the console, including potentially unsafe
  /// runtime values such as secrets, personal information, network payloads, etc.
  ///
  /// - **Important**: Do not use unsafeLogger in release builds intended for production.
  static final unsafeLogger = DescopeLogger(level: debug, unsafe: true);

  /// The maximum log level that should be printed.
  int level;

  /// Whether to print unsafe runtime values.
  ///
  /// When set to `true`, log output will include potentially sensitive runtime values
  /// such as personal information, network payloads, etc. This should not
  /// be enabled in release builds intended for production.
  bool unsafe;

  /// Creates a new [DescopeLogger] object. Log level defaults to `debug`, unsafe defaults to `false`.
  DescopeLogger({this.level = debug, this.unsafe = false});

  /// Formats the log message and prints it.
  ///
  /// Override this method to customize how to handle log messages from the Descope SDK.
  /// The [message] parameter is guaranteed to be a constant compile-time string, so
  /// you can assume it doesn't contain private user data or secrets and that it can
  /// be sent to whatever logging target or service you use.
  /// The [values] array has runtime values that might be useful when debugging
  /// issues with the Descope SDK. Since it might contain sensitive information
  /// its contents are only provided when [unsafe] is set to `true`. Otherwise it
  /// is always an empty array.
  void output({required int level, required String message, required List<dynamic> values}) {
    var text = "[${DescopeSdk.name}] $message";
    if (values.isNotEmpty) {
      text += " (${values.map((v) => v.toString()).join(", ")})";
    }
    // ignore: avoid_print
    print(text);
  }

  /// Called by other code in the Descope SDK to output log messages.
  void log({required int level, required String message, List<dynamic> values = const []}) {
    if (level <= this.level) {
      output(level: level, message: message, values: unsafe ? values : const []);
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
