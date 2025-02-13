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
                let response = try await performRegister(options: options)
                result(response)
            } catch PasskeyError.cancelled {
                return result(FlutterError(code: "CANCELLED", message: "Passkey authentication cancelled", details: nil))
            } catch PasskeyError.failed(let reason) {
                return result(FlutterError(code: "FAILED", message: reason, details: nil))
            } catch {
                return result(FlutterError(code: "FAILED", message: "Passkey authentication failed", details: nil))
            }
        }
    }
    
    private func usePasskey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15, *) else { return result(FlutterError(code: "OSVERSION", message: "Passkeys require iOS 15 and above", details: nil)) }
        guard let args = call.arguments as? [String: Any] else { return result(FlutterError(code: "MISSINGARGS", message: "Unexpected empty arguments in passkeyAuthenticate", details: nil)) }
        guard let options = args["options"] as? String else { return result(FlutterError(code: "MISSINGARGS", message: "'options' is required for passkeyAuthenticate", details: nil)) }
        Task { @MainActor in
            do {
                let response = try await performAssertion(options: options)
                result(response)
            } catch PasskeyError.cancelled {
                return result(FlutterError(code: "CANCELLED", message: "Passkey authentication cancelled", details: nil))
            } catch PasskeyError.failed(let reason) {
                return result(FlutterError(code: "FAILED", message: reason, details: nil))
            } catch {
                return result(FlutterError(code: "FAILED", message: "Passkey authentication failed", details: nil))
            }
        }
    }
    
    // Internal Passkeys
    
    enum PasskeyError: Error {
        case cancelled
        case failed(String)
    }
    
    @available(iOS 15.0, *)
    private func performRegister(options: String) async throws -> String {
        let registerOptions = try RegisterOptions(from: options)
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: registerOptions.rpId)
        
        let registerRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: registerOptions.challenge, name: registerOptions.user.name, userID: registerOptions.user.id)
        registerRequest.displayName = registerOptions.user.displayName
        registerRequest.userVerificationPreference = .required
        
        let authorization = try await performAuthorization(request: registerRequest)
        let response = try RegisterFinish.encodedResponse(from: authorization.credential)
        
        return response
    }
    
    @available(iOS 15.0, *)
    private func performAssertion(options: String) async throws -> String {
        let assertionOptions = try AssertionOptions(from: options)
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: assertionOptions.rpId)
        
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: assertionOptions.challenge)
        assertionRequest.allowedCredentials = assertionOptions.allowCredentials.map { ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0) }
        assertionRequest.userVerificationPreference = .required
        
        let authorization = try await performAuthorization(request: assertionRequest)
        let response = try AssertionFinish.encodedResponse(from: authorization.credential)
        
        return response
    }
    
    private func performAuthorization(request: ASAuthorizationRequest) async throws -> ASAuthorization {
        let authDelegate = AuthorizationDelegate()
        
        let authController = ASAuthorizationController(authorizationRequests: [ request ] )
        authController.delegate = authDelegate
        authController.performRequests()

        // now that we have a reference to the ASAuthorizationController object we setup
        // a cancellation handler to be invoked if the async task is cancelled
        let cancellation = { @MainActor [weak authController] in
            guard #available(iOS 16.0, macOS 13, *) else { return }
            authController?.cancel()
        }

        // we pass a completion handler to the delegate object we can use an async/await code
        // style even though we're waiting for a regular callback. The onCancel closure ensures
        // that we handle task cancellation properly by dismissing the authentication view.
        let result = await withTaskCancellationHandler {
            return await withCheckedContinuation { continuation in
                authDelegate.completion = { result in
                    continuation.resume(returning: result)
                }
            }
        } onCancel: {
            Task { @MainActor in
                cancellation()
            }
        }

        switch result {
        case .failure(ASAuthorizationError.canceled):
            throw PasskeyError.cancelled
        case .failure(let error as NSError) where error.domain == "WKErrorDomain" && error.code == 31:
            throw PasskeyError.cancelled
        case .failure(let error):
            throw PasskeyError.failed(error.localizedDescription)
        case .success(let authorization):
            return authorization
        }
    }
    
    private struct RegisterOptions {
        var challenge: Data
        var rpId: String
        var user: (id: Data, name: String, displayName: String?)

        init(from options: String) throws {
            guard let root = try? JSONDecoder().decode(Root.self, from: Data(options.utf8)) else { throw PasskeyError.failed("Invalid passkey register options") }
            guard let challengeData = Data(base64URLEncoded: root.publicKey.challenge) else { throw PasskeyError.failed("Invalid passkey challenge") }
            guard let userId = Data(base64URLEncoded: root.publicKey.user.id) else { throw PasskeyError.failed("Invalid passkey user id") }
            challenge = challengeData
            rpId = root.publicKey.rp.id
            user = (id: userId, name: root.publicKey.user.name, displayName: root.publicKey.user.displayName)
        }
        
        private struct Root: Codable {
            var publicKey: PublicKey
        }

        private struct PublicKey: Codable {
            var challenge: String
            var rp: RelyingParty
            var user: User
        }
        
        private struct User: Codable {
            var id: String
            var name: String
            var displayName: String?
        }
        
        private struct RelyingParty: Codable {
            var id: String
        }
    }

    private struct AssertionOptions {
        var challenge: Data
        var rpId: String
        var allowCredentials: [Data]
        
        init(from options: String) throws {
            guard let root = try? JSONDecoder().decode(Root.self, from: Data(options.utf8)) else { throw PasskeyError.failed("Invalid passkey assertion options") }
            guard let challengeData = Data(base64URLEncoded: root.publicKey.challenge) else { throw PasskeyError.failed("Invalid passkey challenge") }
            challenge = challengeData
            rpId = root.publicKey.rpId
            allowCredentials = try root.publicKey.allowCredentials.map {
                guard let credentialId = Data(base64URLEncoded: $0.id) else { throw PasskeyError.failed("Invalid credential id") }
                return credentialId
            }
        }
        
        private struct Root: Codable {
            var publicKey: PublicKey
        }

        private struct PublicKey: Codable {
            var challenge: String
            var rpId: String
            var allowCredentials: [Credential] = []
        }
        
        struct Credential: Codable {
            var id: String
        }
    }

    private struct RegisterFinish: Codable {
        var id: String
        var rawId: String
        var response: Response
        var type: String = "public-key"
        
        struct Response: Codable {
            var attestationObject: String
            var clientDataJSON: String
        }
        
        @available(iOS 15.0, *)
        static func encodedResponse(from credential: ASAuthorizationCredential) throws -> String {
            guard let registration = credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration else { throw PasskeyError.failed("Invalid register credential type") }
            
            let credentialId = registration.credentialID.base64URLEncodedString()
            guard let attestationObject = registration.rawAttestationObject?.base64URLEncodedString() else { throw PasskeyError.failed( "Missing credential attestation object") }
            let clientDataJSON = registration.rawClientDataJSON.base64URLEncodedString()
            
            let response = Response(attestationObject: attestationObject, clientDataJSON: clientDataJSON)
            let object = RegisterFinish(id: credentialId, rawId: credentialId, response: response)
            
            guard let encodedObject = try? JSONEncoder().encode(object), let encoded = String(bytes: encodedObject, encoding: .utf8) else { throw PasskeyError.failed("Invalid register finish object") }
            return encoded
        }
    }

    private struct AssertionFinish: Codable {
        var id: String
        var rawId: String
        var response: Response
        var type: String = "public-key"
        
        struct Response: Codable {
            var authenticatorData: String
            var clientDataJSON: String
            var signature: String
            var userHandle: String
        }
        
        @available(iOS 15.0, *)
        static func encodedResponse(from credential: ASAuthorizationCredential) throws -> String {
            guard let assertion = credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else { throw PasskeyError.failed("Invalid assertion credential type") }

            let credentialId = assertion.credentialID.base64URLEncodedString()
            let authenticatorData = assertion.rawAuthenticatorData.base64URLEncodedString()
            let clientDataJSON = assertion.rawClientDataJSON.base64URLEncodedString()
            let userHandle = try parseUserHandle(assertion.userID)
            let signature = assertion.signature.base64URLEncodedString()

            let response = Response(authenticatorData: authenticatorData, clientDataJSON: clientDataJSON, signature: signature, userHandle: userHandle)
            let object = AssertionFinish(id: credentialId, rawId: credentialId, response: response)

            guard let encodedObject = try? JSONEncoder().encode(object), let encoded = String(bytes: encodedObject, encoding: .utf8) else { throw PasskeyError.failed("Invalid assertion finish object") }
            return encoded
        }

        static func parseUserHandle(_ value: Data) throws -> String {
            guard let stringValue = String(bytes: value, encoding: .utf8) else { throw PasskeyError.failed("Invalid user handle") }
            if stringValue.count >= 30, stringValue.hasPrefix("V") {
                return stringValue
            }
            return value.base64URLEncodedString()
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

extension Data {
    init?(base64URLEncoded base64URLString: String, options: Base64DecodingOptions = []) {
        var str = base64URLString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if str.count % 4 > 0 {
            str.append(String(repeating: "=", count: 4 - str.count % 4))
        }
        self.init(base64Encoded: str, options: options)
    }
    
    func base64URLEncodedString(options: Base64EncodingOptions = []) -> String {
        return base64EncodedString(options: options)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
