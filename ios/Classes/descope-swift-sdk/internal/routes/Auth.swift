
final class Auth: DescopeAuth {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func me(refreshJwt: String) async throws(DescopeError) -> DescopeUser {
        return try await client.me(refreshJwt: refreshJwt).convert()
    }

    func tenants(dct: Bool, tenantIds: [String], refreshJwt: String) async throws(DescopeError) -> [DescopeTenant] {
        return try await client.tenants(dct: dct, tenantIds: tenantIds, refreshJwt: refreshJwt).convert()
    }

    func refreshSession(refreshJwt: String) async throws(DescopeError) -> RefreshResponse {
        return try await client.refresh(refreshJwt: refreshJwt).convert()
    }
    
    func migrateSession(externalToken: String) async throws(DescopeError) -> AuthenticationResponse {
        let response: MigrateResponse = try await client.migrate(externalToken: externalToken).convert()
        let user = try await me(refreshJwt: response.refreshToken.jwt)
        return AuthenticationResponse(sessionToken: response.sessionToken, refreshToken: response.refreshToken, user: user, isFirstAuthentication: false)
    }

    func revokeSessions(_ revoke: RevokeType, refreshJwt: String) async throws(DescopeError) {
        try await client.logout(type: revoke, refreshJwt: refreshJwt)
    }
}

private struct MigrateResponse {
    public var sessionToken: DescopeToken
    public var refreshToken: DescopeToken
}

private extension DescopeClient.JWTResponse {
    func convert() throws(DescopeError) -> RefreshResponse {
        guard let sessionJwt, !sessionJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing session JWT") }
        var refreshToken: DescopeToken?
        if let refreshJwt, !refreshJwt.isEmpty {
            refreshToken = try Token(jwt: refreshJwt)
        }
        return try RefreshResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: refreshToken)
    }

    func convert() throws(DescopeError) -> MigrateResponse {
        guard let sessionJwt, !sessionJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing session JWT") }
        guard let refreshJwt, !refreshJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        return try MigrateResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: Token(jwt: refreshJwt))
    }
}
