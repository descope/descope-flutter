import AuthenticationServices
import Flutter

private let redirectScheme = "descopeauth"
private let redirectURL = "\(redirectScheme)://flow"

public class DescopePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let defaultContextProvider = DefaultContextProvider()
    private let keychainStore = KeychainStore()
    private var eventSink: FlutterEventSink?
    private var sessions: [ASWebAuthenticationSession] = []
    
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
        case "oauthNative":
            oauthNative(call: call, result: result)
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
        guard let clientId = args["clientId"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'clientId' is required for oauthNative", details: nil)) }
        guard let nonce = args["nonce"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'nonce' is required for oauthNative", details: nil)) }
        guard let implicit = args["implicit"] as? Bool else { return result(FlutterError(code: "MISSINGARGS", message: "'implicit' is required for oauthNative", details: nil)) }

        if clientId != Bundle.main.bundleIdentifier {
            return result(FlutterError(code: "FAILED", message: "OAuth provider clientId doesn't match bundle identifier", details: nil))
        }

        Task { @MainActor in
            do {
                let authorization = try await performAuthorization(nonce: nonce)
                let (authorizationCode, identityToken, user) = try parseCredential(authorization.credential, implicit: implicit)

                let values = [
                    "authorizationCode": authorizationCode,
                    "identityToken": identityToken,
                    "user": user,
                ]

                let json = try JSONSerialization.data(withJSONObject: values, options: [])
                guard let response = String(bytes: json, encoding: .utf8) else { return result(FlutterError(code: "FAILED", message: "Response encoding failed", details: nil)) }

                return result(response)
            } catch OAuthNativeError.cancelled {
                return result(FlutterError(code: "CANCELLED", message: "OAuth authentication cancelled", details: nil))
            } catch OAuthNativeError.failed(let reason) {
                return result(FlutterError(code: "FAILED", message: reason, details: nil))
            } catch {
                return result(FlutterError(code: "FAILED", message: "OAuth authentication failed", details: nil))
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

    // Internal OAuth

    enum OAuthNativeError: Error {
        case cancelled
        case failed(String)
    }

    @MainActor
    private func performAuthorization(nonce: String) async throws -> ASAuthorization {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce

        let authDelegate = AuthorizationDelegate()
        let authController = ASAuthorizationController(authorizationRequests: [ request ] )
        authController.delegate = authDelegate
        authController.presentationContextProvider = defaultContextProvider
        authController.performRequests()

        let result = await withCheckedContinuation { continuation in
            authDelegate.completion = { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .failure(ASAuthorizationError.canceled):
            throw OAuthNativeError.cancelled
        case .failure(ASAuthorizationError.unknown):
            throw OAuthNativeError.cancelled
        case .failure(let error):
            throw OAuthNativeError.failed("\(error)")
        case .success(let authorization):
            return authorization
        }
    }

    private func parseCredential(_ credential: ASAuthorizationCredential, implicit: Bool) throws -> (authorizationCode: String?, identityToken: String?, user: String?) {
        guard let credential = credential as? ASAuthorizationAppleIDCredential else { throw OAuthNativeError.failed("Invalid Apple credential type") }

        var authorizationCode: String?
        if !implicit, let data = credential.authorizationCode, let value = String(bytes: data, encoding: .utf8) {
            authorizationCode = value
        }

        var identityToken: String?
        if implicit, let data = credential.identityToken, let value = String(bytes: data, encoding: .utf8) {
            identityToken = value
        }

        var user: String?
        if let names = credential.fullName, names.givenName != nil || names.middleName != nil || names.familyName != nil {
            var name: [String: Any] = [:]
            if let givenName = names.givenName {
                name["firstName"] = givenName
            }
            if let middleName = names.middleName {
                name["middleName"] = middleName
            }
            if let familyName = names.familyName {
                name["lastName"] = familyName
            }
            let object = ["name": name]
            if let data = try? JSONSerialization.data(withJSONObject: object), let value = String(bytes: data, encoding: .utf8) {
                user = value
            }
        }

        return (authorizationCode, identityToken, user)
    }
}

typealias AuthorizationDelegateCompletion = (Result<ASAuthorization, Error>) -> Void

class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    var completion: AuthorizationDelegateCompletion?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion?(.success(authorization))
        completion = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}

private class DefaultContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
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
