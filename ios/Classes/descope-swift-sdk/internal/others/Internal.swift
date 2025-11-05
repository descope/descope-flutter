
import AuthenticationServices

extension DescopeSDK {
    static nonisolated(unsafe) let initial: DescopeSDK = DescopeSDK(projectId: "")
}

extension DescopeError {
    func with(desc: String) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
    
    func with(message: String) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
    
    func with(cause: Error) -> DescopeError {
        return DescopeError(code: code, desc: desc, message: message, cause: cause)
    }
}

extension DescopeLogger {
    class ConsoleLogger: DescopeLogger, @unchecked Sendable {
        static let basic = ConsoleLogger(level: .info, unsafe: false)

        static let debug = ConsoleLogger(level: .debug, unsafe: isDebuggerAttached())

        static let unsafe = ConsoleLogger(level: .debug, unsafe: true)

        override func output(level: Level, message: String, unsafe values: [Any]) {
            var text = "[\(DescopeSDK.name)] \(message)"
            if !values.isEmpty {
                text += " (" + values.map { String(describing: $0) }.joined(separator: ", ") + ")"
            }
            print(text)
        }

        private static func isDebuggerAttached() -> Bool {
            var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
            var result = kinfo_proc()
            var size = MemoryLayout.size(ofValue: result)
            guard sysctl(&mib, UInt32(mib.count), &result, &size, nil, 0) == EXIT_SUCCESS else { return false }
            return result.kp_proc.p_flag & P_TRACED != 0
        }
    }
}

extension DescopeLogger? {
    var isUnsafeEnabled: Bool {
        return self?.unsafe == true
    }

    func error(_ message: String, _ values: Any?...) {
        self?.log(.error, message, values)
    }

    func info(_ message: String, _ values: Any?...) {
        self?.log(.info, message, values)
    }

    func debug(_ message: String, _ values: Any?...) {
        self?.log(.debug, message, values)
    }
}

extension DescopeFlow {
    @MainActor
    var providedSession: DescopeSession? {
        // if there's a non-nil provider always use its value, no matter if the value is nil or not
        if let provider = sessionProvider {
            return provider()
        }
        // only take the session from the manager if it's not expired, in case the app is running
        // a login flow and it didn't clear the previous session from its manager by mistake
        let sdk = descope ?? Descope.sdk
        if let session = sdk.sessionManager.session, !session.refreshToken.isExpired {
            return session
        }
        return nil
    }
}

extension Data {
    init?(base64URLEncoded base64URLString: String, options: Base64DecodingOptions = []) {
        var str = base64URLString.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
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

extension String {
    func javaScriptLiteralString() -> String {
        return "`" + replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: #"$"#, with: #"\$"#)
            .replacingOccurrences(of: #"`"#, with: #"\`"#) + "`"
    }
}

extension Task where Success == Never, Failure == Never {
    static func checkCancellation(throwing err: DescopeError) throws(DescopeError) {
        do {
            try checkCancellation()
        } catch {
            throw err
        }
    }
    
    static func sleep(seconds: TimeInterval, throwing err: DescopeError) async throws(DescopeError) {
        do {
            let nanoseconds = UInt64(seconds * TimeInterval(NSEC_PER_SEC))
            try await Task.sleep(nanoseconds: nanoseconds)
        } catch {
            throw err
        }
    }
}

class DefaultPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationAnchor
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor
    }

    private var presentationAnchor: ASPresentationAnchor {
        #if os(iOS)
        return findKeyWindow() ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }

    #if os(iOS) && canImport(React)
    func waitKeyWindow() async {
        for _ in 1...10 {
            guard findKeyWindow() == nil else { return }
            try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
        }
    }
    #endif

    #if os(iOS)
    private func findKeyWindow() -> UIWindow? {
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first

        let window = scene?.windows
            .first { $0.isKeyWindow }

        return window
    }
    #endif
}

class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
    typealias Completion = (Result<ASAuthorization, Error>) -> Void

    var completion: Completion?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion?(.success(authorization))
        completion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion?(.failure(error))
        completion = nil
    }
}

extension AuthenticationResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case sessionToken = "sessionJwt"
        case refreshToken = "refreshJwt"
        case user
        case isFirstAuthentication
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sessionToken = try Token(jwt: values.decode(String.self, forKey: .sessionToken))
        refreshToken = try Token(jwt: values.decode(String.self, forKey: .refreshToken))
        user = try values.decode(DescopeUser.self, forKey: .user)
        isFirstAuthentication = try values.decode(Bool.self, forKey: .isFirstAuthentication)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(sessionToken.jwt, forKey: .sessionToken)
        try values.encode(refreshToken.jwt, forKey: .refreshToken)
        try values.encode(user, forKey: .user)
        try values.encode(isFirstAuthentication, forKey: .isFirstAuthentication)
    }
}

extension DescopeUser {
    struct SerializedUser: Codable, Equatable {
        var userId: String
        var loginIds: [String]
        var status: String?
        var createdAt: Date
        var email: String?
        var isVerifiedEmail: Bool
        var phone: String?
        var isVerifiedPhone: Bool
        var name: String?
        var givenName: String?
        var middleName: String?
        var familyName: String?
        var picture: URL?
        var authentication: Authentication?
        var authorization: Authorization?
        var customAttributes: String?
        var isUpdateRequired: Bool?
    }
    
    static func serialize(_ user: DescopeUser) -> SerializedUser {
        var customAttributes = "{}"
        if JSONSerialization.isValidJSONObject(user.customAttributes), let data = try? JSONSerialization.data(withJSONObject: user.customAttributes), let value = String(bytes: data, encoding: .utf8) {
            customAttributes = value
        }
        
        return SerializedUser(
            userId: user.userId,
            loginIds: user.loginIds,
            status: user.status.rawValue,
            createdAt: user.createdAt,
            email: user.email,
            isVerifiedEmail: user.isVerifiedEmail,
            phone: user.phone,
            isVerifiedPhone: user.isVerifiedPhone,
            name: user.name,
            givenName: user.givenName,
            middleName: user.middleName,
            familyName: user.familyName,
            picture: user.picture,
            authentication: user.authentication,
            authorization: user.authorization,
            customAttributes: customAttributes,
            isUpdateRequired: user.isUpdateRequired,
        )
    }
    
    static func deserialize(_ user: SerializedUser) -> DescopeUser {
        var customAttributes: [String: Any] = [:]
        if let value = user.customAttributes, let json = try? JSONSerialization.jsonObject(with: Data(value.utf8)) {
            customAttributes = json as? [String: Any] ?? [:]
        }
        
        return DescopeUser(
            userId: user.userId,
            loginIds: user.loginIds,
            status: Status(rawValue: user.status ?? "") ?? .enabled,
            createdAt: user.createdAt,
            email: user.email,
            isVerifiedEmail: user.isVerifiedEmail,
            phone: user.phone,
            isVerifiedPhone: user.isVerifiedPhone,
            name: user.name,
            givenName: user.givenName,
            middleName: user.middleName,
            familyName: user.familyName,
            picture: user.picture,
            authentication: user.authentication ?? Authentication(passkey: false, password: false, totp: false, oauth: [], sso: false, scim: false),
            authorization: user.authorization ?? Authorization(roles: [], ssoAppIds: []),
            customAttributes: customAttributes,
            isUpdateRequired: user.isUpdateRequired ?? true, // if the flag doesn't exist we've got old data without the new fields
        )
    }
}
