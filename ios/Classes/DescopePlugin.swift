import AuthenticationServices
import Flutter

private let redirectScheme = "descopeauth"
private let redirectURL = "\(redirectScheme)://flow"

public class DescopePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let defaultContextProvider = DefaultContextProvider()
    private let keychainStore = KeychainStore()
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "descope_flutter/methods", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "descope_flutter/events", binaryMessenger: registrar.messenger())
        
        let instance = DescopePlugin()
        
        eventChannel.setStreamHandler(instance)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startFlow":
            startFlow(call: call, result: result)
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
    
    // Flows
    
    private func startFlow(call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any], let urlString = args["url"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'url' is required for startFlow", details: nil)) }
        startFlow(urlString)
        result(urlString)
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
    
    // Internal
    
    private func startFlow(_ urlString: String) {
        Task { @MainActor in
            guard var url = URL(string: urlString) else { return }
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { callbackURL, error in
                if let error {
                    switch error {
                    case ASWebAuthenticationSessionError.canceledLogin:
                        self.eventSink?("canceled")
                        return
                    case ASWebAuthenticationSessionError.presentationContextInvalid, ASWebAuthenticationSessionError.presentationContextNotProvided:
                        // not handled for now
                        fallthrough
                    default:
                        self.eventSink?("")
                        return
                    }
                }
                self.eventSink?(callbackURL?.absoluteString ?? "")
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = defaultContextProvider
            session.start()
        }
    }
}


private class DefaultContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first
        
        let keyWindow = scene?.windows
            .first { $0.isKeyWindow }
        
        return keyWindow ?? ASPresentationAnchor()
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
