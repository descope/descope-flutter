
import Foundation

public extension URLRequest {
    /// Ensures that the active session in a ``DescopeSessionManager`` is valid and
    /// then sets its session JWT as the Bearer Token value of the Authorization
    /// header field in the `URLRequest`.
    mutating func setAuthorizationHTTPHeaderField(from sessionManager: DescopeSessionManager) async throws {
        try await sessionManager.refreshSessionIfNeeded()
        if let session = await sessionManager.session {
            setAuthorizationHTTPHeaderField(from: session)
        }
    }
    
    /// Sets the session JWT from a ``DescopeSession`` as the Bearer Token value of
    /// the Authorization header field in the `URLRequest`.
    mutating func setAuthorizationHTTPHeaderField(from session: DescopeSession) {
        setAuthorizationHTTPHeaderField(from: session.sessionToken)
    }

    /// Sets the JWT from a ``DescopeToken`` as the Bearer Token value of
    /// the Authorization header field in the `URLRequest`.
    mutating func setAuthorizationHTTPHeaderField(from token: DescopeToken) {
        setValue("Bearer \(token.jwt)", forHTTPHeaderField: "Authorization")
    }
}
