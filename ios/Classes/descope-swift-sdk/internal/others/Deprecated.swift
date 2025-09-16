
import Foundation

public extension DescopeOAuth {
    @available(*, deprecated, renamed: "webStart")
    func start(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions]) async throws -> URL {
        return try await webStart(provider: provider, redirectURL: redirectURL, options: options)
    }

    @available(*, deprecated, renamed: "webExchange")
    func exchange(code: String) async throws -> AuthenticationResponse {
        return try await webExchange(code: code)
    }
}

public extension DescopeAuth {
    @available(*, deprecated, message: "Call revokeSessions(.currentSession, refreshJwt: refreshJwt) instead")
    func logout(refreshJwt: String) async throws {
        return try await revokeSessions(.currentSession, refreshJwt: refreshJwt)
    }
}

public extension DescopeSDK {
    @available(*, unavailable, message: "Use the DescopeSDK.init(projectId:with:) initializer instead")
    convenience init(config: DescopeConfig) {
        self.init(projectId: config.projectId, with: { $0 = config })
    }
}

public extension Descope {
    static var projectId: String {
        get { Descope.sdk.config.projectId }
        @available(*, unavailable, message: "Use the setup() function to initialize the Descope singleton")
        set { Descope.sdk = DescopeSDK(projectId: newValue) }
    }

    static var config: DescopeConfig {
        get { Descope.sdk.config }
        @available(*, unavailable, message: "Use the setup() function to initialize the Descope singleton")
        set { Descope.sdk = DescopeSDK(projectId: newValue.projectId, with: { $0 = newValue }) }
    }
}

public extension DescopeConfig {
    @available(*, unavailable, message: "Use the Descope.setup() function or DescopeSDK.init(projectId:with:) initializer instead")
    init(projectId: String, baseURL: String? = nil, logger: DescopeLogger? = nil) {
        self.projectId = projectId
        self.baseURL = baseURL
        self.logger = logger
    }
}

public extension DescopeLogger {
    @available(*, deprecated, message: "Use DescopeLogger.basicLogger or DescopeLogger.debugLogger to diagnose issues during development")
    convenience init(level: Level = .debug) {
        self.init(level: level, unsafe: false)
    }
}

public extension DescopeFlow {
    @available(*, deprecated, renamed: "oauthNativeProvider")
    var oauthProvider: OAuthProvider? {
        get { oauthNativeProvider }
        set { oauthNativeProvider = newValue }
    }
}

public extension SessionStorage.KeychainStore {
    @available(*, deprecated, message: "Use the init() initializer instead and set the accessibility property manually")
    public convenience init(accessibility: String) {
        self.init()
        self.accessibility = accessibility
    }
}
