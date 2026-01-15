import AuthenticationServices
import Flutter

private let redirectScheme = "descopeauth"
private let redirectURL = "\(redirectScheme)://flow"

public class DescopePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let defaultContextProvider = FlowsV0DefaultContextProvider()
    private let keychainStore = KeychainStore()
    private var eventSink: FlutterEventSink?
    private var sessions: [ASWebAuthenticationSession] = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "descope_flutter/methods", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "descope_flutter/events", binaryMessenger: registrar.messenger())
        let logChannel = FlutterMethodChannel(name: "descope_flutter/logs", binaryMessenger: registrar.messenger())
        
        let instance = DescopePlugin()

        // Set up log channel handler for logger configuration from Flutter
        logChannel.setMethodCallHandler { call, result in
            if call.method == "configure" {
                guard let args = call.arguments as? [String: Any],
                      let levelString = args["level"] as? String,
                      let unsafe = args["unsafe"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing level or unsafe arguments", details: nil))
                    return
                }

                let level: DescopeLogger.Level
                switch levelString {
                case "error":
                    level = .error
                case "info":
                    level = .info
                default:
                    level = .debug
                }

                // Initialize SDK with the logger configured from Flutter
                // Descope.setup is @MainActor so we ensure we're on the main thread
                DispatchQueue.main.async {
                    Descope.setup(projectId: "") { config in
                        config.logger = FlutterDescopeLogger(channel: logChannel, level: level, unsafe: unsafe)
                    }
                }

                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let factory = FlutterDescopeFlowViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "descope_flutter/descope_flow_view")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSystemInfo":
            getSystemInfo(result: result)
        case "startFlow":
            startFlow(call: call, result: result)
        case "oauthNative":
            oauthNative(call: call, result: result)
        case "passkeySupported":
            passkeySupported(result: result)
        case "passkeyOrigin":
            result("") // No need for passkey origin on iOS
        case "passkeyCreate":
            createPasskey(call: call, result: result)
        case "passkeyAuthenticate":
            usePasskey(call: call, result: result)
        case "loadItem":
            loadItem(call: call, result: result)
        case "saveItem":
            saveItem(call: call, result: result)
        case "removeItem":
            removeItem(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // General

    private func getSystemInfo(result: @escaping FlutterResult) {
        result([
            "platformName": SystemInfo.osName,
            "platformVersion": SystemInfo.osVersion,
            "appName": SystemInfo.appName,
            "appVersion": SystemInfo.appVersion,
            "device": SystemInfo.device,
        ])
    }
    
    // Flows
    
    private func startFlow(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any], let urlString = args["url"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'url' is required for startFlow", details: nil)) }
        DispatchQueue.main.async { [self] in
            startFlow(urlString)
        }
        result(urlString)
    }
    
    // OAuth

    private func oauthNative(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else { return result(FlutterError(code: "MISSINGARGS", message: "Unexpected empty arguments in oauthNative", details: nil)) }
        guard let nonce = args["nonce"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'nonce' is required for oauthNative", details: nil)) }
        guard let implicit = args["implicit"] as? Bool else { return result(FlutterError(code: "MISSINGARGS", message: "'implicit' is required for oauthNative", details: nil)) }

        Task { @MainActor in
            do {
                let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthentication(nonce: nonce, implicit: implicit, logger: nil)

                let values = [
                    "authorizationCode": authorizationCode,
                    "identityToken": identityToken,
                    "user": user,
                ]

                let json = try JSONSerialization.data(withJSONObject: values, options: [])
                guard let response = String(bytes: json, encoding: .utf8) else { return result(FlutterError(code: "FAILED", message: "Response encoding failed", details: nil)) }

                return result(response)
            } catch let error as DescopeError {
                return result(FlutterError(from: error))
            }
        }
    }
    
    // Passkeys
    
    private func passkeySupported(result: @escaping FlutterResult) {
        if #available(iOS 15, *) {
            result(true)
        }
        result(false)
    }
    
    private func createPasskey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15, *) else { return result(FlutterError(code: "OSVERSION", message: "Passkeys require iOS 15 and above", details: nil)) }
        guard let args = call.arguments as? [String: Any] else { return result(FlutterError(code: "MISSINGARGS", message: "Unexpected empty arguments in passkeyCreate", details: nil)) }
        guard let options = args["options"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'options' is required for passkeyCreate", details: nil)) }
        Task { @MainActor in
            do {
                let response = try await Passkey.performRegister(options: options, logger: nil)
                result(response)
            } catch let error as DescopeError {
                return result(FlutterError(from: error))
            }
        }
    }
    
    private func usePasskey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15, *) else { return result(FlutterError(code: "OSVERSION", message: "Passkeys require iOS 15 and above", details: nil)) }
        guard let args = call.arguments as? [String: Any] else { return result(FlutterError(code: "MISSINGARGS", message: "Unexpected empty arguments in passkeyAuthenticate", details: nil)) }
        guard let options = args["options"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'options' is required for passkeyAuthenticate", details: nil)) }
        Task { @MainActor in
            do {
                let response = try await Passkey.performAssertion(options: options, logger: nil)
                result(response)
            } catch let error as DescopeError {
                return result(FlutterError(from: error))
            }
        }
    }
    
    // Storage
    
    private func loadItem(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any], let key = args["key"] as? String else { return result(FlutterError(code: "MISSINARGS", message: "'key' is required for loadItem", details: nil)) }
        guard let data = keychainStore.loadItem(key: key) else { return result(nil) }
        let value = String(bytes: data, encoding: .utf8)
        result(value)
    }
    
    private func saveItem(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any], let key = args["key"] as? String, let value = args["data"] as? String else { return result(FlutterError(code: "MISSINARGS", message: "'key' and 'data' are required for saveItem", details: nil)) }
        keychainStore.saveItem(key: key, data: Data(value.utf8))
        result(key)
    }
    
    private func removeItem(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any], let key = args["key"] as? String else { return result(FlutterError(code: "MISSINARGS", message: "'key' is required for removeItem", details: nil)) }
        keychainStore.removeItem(key: key)
        result(key)
    }
    
    // FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // Internal Flows

    @MainActor
    private func startFlow(_ urlString: String) {
        startFlow(urlString, attempts: 5)
    }

    @MainActor
    private func startFlow(_ urlString: String, attempts: Int) {
        if attempts > 0, defaultContextProvider.findKeyWindow() == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                startFlow(urlString, attempts: attempts - 1)
            }
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { [self] callbackURL, error in
            if let error {
                switch error {
                case ASWebAuthenticationSessionError.canceledLogin:
                    respond(with: "canceled")
                    return
                case ASWebAuthenticationSessionError.presentationContextInvalid,
                    ASWebAuthenticationSessionError.presentationContextNotProvided:
                    // not handled for now
                    fallthrough
                default:
                    respond(with: "")
                    return
                }
            }
            respond(with: callbackURL?.absoluteString ?? "")
        }
        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = defaultContextProvider
        sessions += [session]
        session.start()
    }
    
    @MainActor
    private func respond(with response: String) {
        eventSink?(response)
        for session in sessions {
            session.cancel()
        }
        sessions = []
    }
}

private class FlowsV0DefaultContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return findKeyWindow() ?? ASPresentationAnchor()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return findKeyWindow() ?? ASPresentationAnchor()
    }

    func findKeyWindow() -> UIWindow? {
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first

        let keyWindow = scene?.windows
            .first { $0.isKeyWindow }

        return keyWindow
    }
}

private class KeychainStore {
    public func loadItem(key: String) -> Data? {
        var query = queryForItem(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var value: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &value)
        return value as? Data
    }
    
    public func saveItem(key: String, data: Data) {
        let values: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let query = queryForItem(key: key)
        let result = SecItemCopyMatching(query as CFDictionary, nil)
        if result == errSecSuccess {
            SecItemUpdate(query as CFDictionary, values as CFDictionary)
        } else if result == errSecItemNotFound {
            let merged = query.merging(values, uniquingKeysWith: { $1 })
            SecItemAdd(merged as CFDictionary, nil)
        }
    }
    
    public func removeItem(key: String) {
        let query = queryForItem(key: key)
        SecItemDelete(query as CFDictionary)
    }
    
    private func queryForItem(key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.descope.Flutter",
            kSecAttrLabel as String: "DescopeSession",
            kSecAttrAccount as String: key,
        ]
    }
}

// Passkey & OAuth Errors

extension FlutterError {
    convenience init(from error: DescopeError) {
        let code: String
        switch error {
        case DescopeError.passkeyCancelled, DescopeError.oauthNativeCancelled, DescopeError.flowCancelled:
            code = "CANCELLED"
        default:
            code = "FAILED"
        }

        let message: String
        if let msg = error.message {
            message = "\(error.desc): \(msg)"
        } else {
            message = error.desc
        }

        self.init(code: code, message: message, details: nil)
    }
}

/// A DescopeLogger subclass that forwards all logs to Flutter via a MethodChannel.
/// This logger is configured with the level and unsafe settings from the Flutter layer.
private class FlutterDescopeLogger: DescopeLogger {
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel, level: Level, unsafe: Bool) {
        self.channel = channel
        super.init(level: level, unsafe: unsafe)
    }

    override func output(level: Level, message: String, unsafe values: [Any]) {
        let levelString: String
        switch level {
        case .error:
            levelString = "error"
        case .info:
            levelString = "info"
        case .debug:
            levelString = "debug"
        }

        let valuesArray = values.map { String(describing: $0) }

        DispatchQueue.main.async {
            self.channel.invokeMethod("log", arguments: [
                "level": levelString,
                "message": message,
                "values": valuesArray,
            ])
        }
    }
}
