
/// The ``DescopeLogger`` class can be used if you need to customize how logging works in the
/// Descope SDK, but in most cases you can simply use ``DescopeLogger/debugLogger`` (see the
/// documentation for the ``DescopeConfig/logger`` property in ``DescopeConfig`` for more details).
///
/// Create a subclass of ``DescopeLogger`` and override the ``output(level:message:unsafe:)``
/// method. See the documentation for that method for more details.
///
/// ```swift
/// Descope.setup(projectId: "...") { config in
///     config.logger = RemoteDescopeLogger()
/// }
///
/// // elsewhere
///
/// class RemoteDescopeLogger: DescopeLogger {
///     init() {
///         super.init(level: .info, unsafe: false)
///     }
///
///     override func output(level: Level, message: String, unsafe values: [Any]) {
///         RemoteLogger.sendLog("Descope: \(message)")
///     }
/// }
/// ```
///
/// The logging functions might be called concurrently on multiple threads, so you
/// should make sure your subclass implementation is thread safe.
open class DescopeLogger: @unchecked Sendable {
    /// The severity of a log message.
    public enum Level: Int, Sendable {
        case error, info, debug
    }

    /// The maximum log level that should be printed.
    public let level: Level

    /// Whether to print unsafe runtime value.
    public let unsafe: Bool

    /// Creates a new ``DescopeLogger`` object.
    ///
    /// - Parameters:
    ///   - level: The maximum log level that should be printed.
    ///   - unsafe: Whether logs should include unsafe runtime values such as secrets,
    ///     personal information, network payloads, etc. This flag should never be
    ///     enabled in release builds intended for production.
    public init(level: Level, unsafe: Bool) {
        self.level = level
        self.unsafe = unsafe
    }

    /// Called by other code in the Descope SDK to output log messages.
    public func log(_ level: Level, _ message: String, _ values: Any?...) {
        guard level.rawValue <= self.level.rawValue else { return }
        let values = unsafe ? values : []
        output(level: level, message: message, unsafe: values.compactMap { $0 })
    }

    /// Override this method to implement formatting and printing of logs from the Descope SDK.
    ///
    /// - Parameters:
    ///   - level: The log level of the message.
    ///   - message: The log message is guaranteed to be a plain string that's safe for logging.
    ///     You can assume it doesn't contain any secrets, user data, or personal information
    ///     and that it can be safely printed or sent to a third party logging service.
    ///   - values: This array has runtime values that might be useful when debugging issues
    ///     with the Descope SDK. As these values are not considered safe this array is always
    ///     empty unless the logger was created with `unsafe` set to `true`.
    open func output(level: Level, message: String, unsafe values: [Any]) {
    }
}
