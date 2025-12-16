
import Foundation

public extension DescopeOAuth {
    @available(*, unavailable, renamed: "webStart")
    func start(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions]) async throws -> URL {
        return try await webStart(provider: provider, redirectURL: redirectURL, options: options)
    }

    @available(*, unavailable, renamed: "webExchange")
    func exchange(code: String) async throws -> AuthenticationResponse {
        return try await webExchange(code: code)
    }
}

public extension DescopeAuth {
    @available(*, unavailable, message: "Call revokeSessions(.currentSession, refreshJwt: refreshJwt) instead")
    func logout(refreshJwt: String) async throws {
        return try await revokeSessions(.currentSession, refreshJwt: refreshJwt)
    }
}

public extension DescopeLogger {
    @available(*, unavailable, message: "Use DescopeLogger.basicLogger or DescopeLogger.debugLogger to diagnose issues during development")
    convenience init(level: Level = .debug) {
        self.init(level: level, unsafe: false)
    }
}

public extension DescopeFlow {
    @available(*, unavailable, renamed: "oauthNativeProvider")
    var oauthProvider: OAuthProvider? {
        get { oauthNativeProvider }
        set { oauthNativeProvider = newValue }
    }
}

public extension SessionStorage.KeychainStore {
    @available(*, unavailable, message: "Use the init() initializer instead and set the accessibility property manually")
    convenience init(accessibility: String) {
        self.init()
        self.accessibility = accessibility
    }
}
