
import AuthenticationServices
import CryptoKit

final class Passkey: DescopePasskey, Route {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    @MainActor
    @available(iOS 15.0, *)
    func signUp(loginId: String, details: SignUpDetails?) async throws(DescopeError) -> AuthenticationResponse {
        logger.info("Starting passkey sign up", loginId)
        let startResponse = try await client.passkeySignUpStart(loginId: loginId, details: details)
        
        logger.info("Requesting register authorization for passkey sign up", startResponse.transactionId)
        let registerResponse = try await Passkey.performRegister(options: startResponse.options, logger: logger)
        
        logger.info("Finishing passkey sign up", startResponse.transactionId)
        let jwtResponse = try await client.passkeySignUpFinish(transactionId: startResponse.transactionId, response: registerResponse)

        guard !Task.isCancelled else { throw DescopeError.passkeyCancelled }
        return try jwtResponse.convert()
    }
    
    @MainActor
    @available(iOS 15.0, *)
    func signIn(loginId: String, options: [SignInOptions]) async throws(DescopeError) -> AuthenticationResponse {
        logger.info("Starting passkey sign in", loginId)
        let (refreshJwt, loginOptions) = try options.convert()
        let startResponse = try await client.passkeySignInStart(loginId: loginId, refreshJwt: refreshJwt, options: loginOptions)
        
        logger.info("Requesting assertion authorization for passkey sign in", startResponse.transactionId)
        let assertionResponse = try await Passkey.performAssertion(options: startResponse.options, logger: logger)

        logger.info("Finishing passkey sign in", startResponse.transactionId)
        let jwtResponse = try await client.passkeySignInFinish(transactionId: startResponse.transactionId, response: assertionResponse)
        
        guard !Task.isCancelled else { throw DescopeError.passkeyCancelled }
        return try jwtResponse.convert()
    }
    
    @MainActor
    @available(iOS 15.0, *)
    func signUpOrIn(loginId: String, options: [SignInOptions]) async throws(DescopeError) -> AuthenticationResponse {
        logger.info("Starting passkey sign up or in", loginId)
        let (refreshJwt, loginOptions) = try options.convert()
        let startResponse = try await client.passkeySignUpInStart(loginId: loginId, refreshJwt: refreshJwt, options: loginOptions)
        
        let jwtResponse: DescopeClient.JWTResponse
        if startResponse.create {
            logger.info("Requesting register authorization for passkey sign up or in", startResponse.transactionId)
            let registerResponse = try await Passkey.performRegister(options: startResponse.options, logger: logger)
            logger.info("Finishing passkey sign up", startResponse.transactionId)
            jwtResponse = try await client.passkeySignUpFinish(transactionId: startResponse.transactionId, response: registerResponse)
        } else {
            logger.info("Requesting assertion authorization for passkey sign up or in", startResponse.transactionId)
            let assertionResponse = try await Passkey.performAssertion(options: startResponse.options, logger: logger)
            logger.info("Finishing passkey sign in", startResponse.transactionId)
            jwtResponse = try await client.passkeySignInFinish(transactionId: startResponse.transactionId, response: assertionResponse)
        }
        
        guard !Task.isCancelled else { throw DescopeError.passkeyCancelled }
        return try jwtResponse.convert()
    }
    
    @MainActor
    @available(iOS 15.0, *)
    func add(loginId: String, refreshJwt: String) async throws(DescopeError) {
        logger.info("Starting passkey update", loginId)
        let startResponse = try await client.passkeyAddStart(loginId: loginId, refreshJwt: refreshJwt)
        
        logger.info("Requesting register authorization for passkey update", startResponse.transactionId)
        let registerResponse = try await Passkey.performRegister(options: startResponse.options, logger: logger)
        
        logger.info("Finishing passkey update", startResponse.transactionId)
        try await client.passkeyAddFinish(transactionId: startResponse.transactionId, response: registerResponse)
    }

    @MainActor
    @available(iOS 15.0, *)
    static func performRegister(options: String, logger: DescopeLogger?) async throws(DescopeError) -> String {
        let registerOptions = try RegisterOptions(from: options)
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: registerOptions.rpId)

        let registerRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: registerOptions.challenge, name: registerOptions.user.name, userID: registerOptions.user.id)
        registerRequest.displayName = registerOptions.user.displayName
        registerRequest.userVerificationPreference = .required
        
        let authorization = try await performAuthorization(request: registerRequest, logger: logger)
        let response = try RegisterFinish.encodedResponse(from: authorization.credential)
        
        return response
    }
    
    @MainActor
    @available(iOS 15.0, *)
    static func performAssertion(options: String, logger: DescopeLogger?) async throws(DescopeError) -> String {
        let assertionOptions = try AssertionOptions(from: options)
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: assertionOptions.rpId)
        
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: assertionOptions.challenge)
        assertionRequest.allowedCredentials = assertionOptions.allowCredentials.map { ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0) }
        assertionRequest.userVerificationPreference = .required
        
        let authorization = try await performAuthorization(request: assertionRequest, logger: logger)
        let response = try AssertionFinish.encodedResponse(from: authorization.credential)
        
        return response
    }
}

@MainActor
private func performAuthorization(request: ASAuthorizationRequest, logger: DescopeLogger?) async throws(DescopeError) -> ASAuthorization {
    let authDelegate = AuthorizationDelegate()
    
    let authController = ASAuthorizationController(authorizationRequests: [ request ] )
    authController.delegate = authDelegate

    // now that we have a reference to the ASAuthorizationController object we setup
    // a cancellation handler to be invoked if the async task is cancelled
    let cancellation = { @MainActor [weak authController] in
        guard #available(iOS 16.0, macOS 13, *) else { return }
        authController?.cancel()
    }

    // we pass a completion handler to the delegate object so we can use an async/await code
    // style even though we're waiting for a regular callback. The onCancel closure ensures
    // that we handle task cancellation properly by dismissing the authentication view.
    let result = await withTaskCancellationHandler {
        return await withCheckedContinuation { continuation in
            authDelegate.completion = { result in
                continuation.resume(returning: result)
            }
            authController.performRequests()
        }
    } onCancel: {
        Task { @MainActor in
            cancellation()
        }
    }

    switch result {
    case .failure(ASAuthorizationError.canceled):
        logger.info("Passkey authorization cancelled")
        throw DescopeError.passkeyCancelled
    case .failure(let error as NSError) where error.domain == "WKErrorDomain" && error.code == 31:
        logger.error("Passkey authorization timed out", error)
        throw DescopeError.passkeyCancelled.with(message: "The operation timed out")
    case .failure(let error):
        logger.error("Passkey authorization failed", error)
        throw DescopeError.passkeyFailed.with(cause: error)
    case .success(let authorization):
        logger.debug("Processing passkey authorization", authorization)
        return authorization
    }
}

private struct RegisterOptions {
    var challenge: Data
    var rpId: String
    var user: (id: Data, name: String, displayName: String?)

    init(from options: String) throws(DescopeError) {
        guard let root = try? JSONDecoder().decode(Root.self, from: Data(options.utf8)) else { throw DescopeError.decodeError.with(message: "Invalid passkey register options") }
        guard let challengeData = Data(base64URLEncoded: root.publicKey.challenge) else { throw DescopeError.decodeError.with(message: "Invalid passkey challenge") }
        guard let userId = Data(base64URLEncoded: root.publicKey.user.id) else { throw DescopeError.decodeError.with(message: "Invalid passkey user id") }
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
    
    init(from options: String) throws(DescopeError) {
        guard let root = try? JSONDecoder().decode(Root.self, from: Data(options.utf8)) else { throw DescopeError.decodeError.with(message: "Invalid passkey assertion options") }
        guard let challengeData = Data(base64URLEncoded: root.publicKey.challenge) else { throw DescopeError.decodeError.with(message: "Invalid passkey challenge") }
        challenge = challengeData
        rpId = root.publicKey.rpId
        allowCredentials = try root.publicKey.allowCredentials.map { (credential) throws(DescopeError) -> Data in
            guard let credentialId = Data(base64URLEncoded: credential.id) else { throw DescopeError.decodeError.with(message: "Invalid credential id") }
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
    static func encodedResponse(from credential: ASAuthorizationCredential) throws(DescopeError) -> String {
        guard let registration = credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration else { throw DescopeError.passkeyFailed.with(message: "Invalid register credential type") }
        
        let credentialId = registration.credentialID.base64URLEncodedString()
        guard let attestationObject = registration.rawAttestationObject?.base64URLEncodedString() else { throw DescopeError.passkeyFailed.with(message: "Missing credential attestation object") }
        let clientDataJSON = registration.rawClientDataJSON.base64URLEncodedString()
        
        let response = Response(attestationObject: attestationObject, clientDataJSON: clientDataJSON)
        let object = RegisterFinish(id: credentialId, rawId: credentialId, response: response)
        
        guard let encodedObject = try? JSONEncoder().encode(object), let encoded = String(bytes: encodedObject, encoding: .utf8) else { throw DescopeError.encodeError.with(message: "Invalid register finish object") }
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
    static func encodedResponse(from credential: ASAuthorizationCredential) throws(DescopeError) -> String {
        guard let assertion = credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else { throw DescopeError.passkeyFailed.with(message: "Invalid assertion credential type") }
        
        let credentialId = assertion.credentialID.base64URLEncodedString()
        let authenticatorData = assertion.rawAuthenticatorData.base64URLEncodedString()
        let clientDataJSON = assertion.rawClientDataJSON.base64URLEncodedString()
        let userHandle = try parseUserHandle(assertion.userID)
        let signature = assertion.signature.base64URLEncodedString()
        
        let response = Response(authenticatorData: authenticatorData, clientDataJSON: clientDataJSON, signature: signature, userHandle: userHandle)
        let object = AssertionFinish(id: credentialId, rawId: credentialId, response: response)
        
        guard let encodedObject = try? JSONEncoder().encode(object), let encoded = String(bytes: encodedObject, encoding: .utf8) else { throw DescopeError.encodeError.with(message: "Invalid assertion finish object") }
        return encoded
    }

    static func parseUserHandle(_ value: Data) throws(DescopeError) -> String {
        guard let stringValue = String(bytes: value, encoding: .utf8) else { throw DescopeError.passkeyFailed.with(message: "Invalid user handle") }
        if stringValue.count >= 30, stringValue.hasPrefix("V") {
            return stringValue
        }
        return value.base64URLEncodedString()
    }
}
