
import Foundation

/// The ``DescopeSession`` class represents a successful sign in operation.
///
/// After a user finishes a sign in flow successfully you should create
/// a ``DescopeSession`` object from the ``AuthenticationResponse`` value returned
/// by all the authentication APIs.
///
///     let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
///     let session = DescopeSession(from: authResponse)
///
/// The session can then be used to authenticate outgoing requests to your backend
/// with a bearer token authorization header.
///
///     var request = URLRequest(url: url)
///     request.setAuthorizationHTTPHeaderField(from: session)
///     let (data, response) = try await URLSession.shared.data(for: request)
///
/// If your backend uses a different authorization mechanism you can of course
/// use the session JWT directly instead of the extension function:
///
///     request.setValue(session.sessionJwt, forHTTPHeaderField: "X-Auth-Token")
///
/// As shown above the session can be used directly but in most circumstances
/// it's recommended to let a ``DescopeSessionManager`` object manage it instead,
/// and the code examples above are only slightly different. See the documentation
/// for ``DescopeSessionManager`` for more details.
public struct DescopeSession: Sendable {
    /// The wrapper for the short lived JWT that can be sent with every server
    /// request that requires authentication.
    public private(set) var sessionToken: DescopeToken
    
    /// The wrapper for the longer lived JWT that is used to create
    /// new session JWTs until it expires.
    public private(set) var refreshToken: DescopeToken
    
    /// The user to whom the ``DescopeSession`` belongs to.
    public private(set) var user: DescopeUser
    
    /// Creates a new ``DescopeSession`` object from an ``AuthenticationResponse``.
    ///
    /// Use this initializer to create a ``DescopeSession`` after the user completes
    /// a sign in or sign up flow in the application.
    public init(from response: AuthenticationResponse) {
        self.init(sessionToken: response.sessionToken, refreshToken: response.refreshToken, user: response.user)
    }
    
    /// Creates a new ``DescopeSession`` object from two JWT strings.
    ///
    /// This initializer can be used to manually recreate a user's ``DescopeSession`` after
    /// the application is relaunched if not using a ``DescopeSessionManager`` for this.
    public init(sessionJwt: String, refreshJwt: String, user: DescopeUser) throws(DescopeError) {
        let sessionToken = try Token(jwt: sessionJwt)
        let refreshToken = try Token(jwt: refreshJwt)
        self.init(sessionToken: sessionToken, refreshToken: refreshToken, user: user)
    }
    
    /// Creates a new ``DescopeSession`` object.
    public init(sessionToken: DescopeToken, refreshToken: DescopeToken, user: DescopeUser) {
        self.sessionToken = sessionToken
        self.refreshToken = refreshToken
        self.user = user
    }
}

/// Convenience accessors for getting values from the underlying JWTs.
public extension DescopeSession {
    /// The short lived JWT that is sent with every request that
    /// requires authentication.
    var sessionJwt: String { sessionToken.jwt }
    
    /// The longer lived JWT that is used to create new session JWTs
    /// until it expires.
    var refreshJwt: String { refreshToken.jwt }
    
    /// A map with all the custom claims in the underlying JWT. It includes
    /// any claims whose values aren't already exposed by other accessors or
    /// authorization functions.
    var claims: [String: Any] { sessionToken.claims }

    /// Returns the list of permissions granted for the user. Pass `nil` for
    /// the `tenant` parameter if the user isn't associated with any tenant.
    func permissions(tenant: String?) -> [String] { sessionToken.permissions(tenant: tenant) }
    
    /// Returns the list of roles for the user. Pass `nil` for the `tenant`
    /// parameter if the user isn't associated with any tenant.
    func roles(tenant: String?) -> [String] { sessionToken.roles(tenant: tenant) }
}

/// Updating the session manually when not using a ``DescopeSessionManager``.
public extension DescopeSession {
    /// Updates the underlying JWTs with those from a ``RefreshResponse``.
    ///
    ///     if session.sessionToken.isExpired {
    ///         let refreshResponse = try await Descope.auth.refreshSession(refreshJwt: session.refreshJwt)
    ///         session.updateTokens(with: refreshResponse)
    ///     }
    ///
    /// - Important: It's recommended to use a ``DescopeSessionManager`` to manage sessions,
    ///     in which case you should call `updateTokens` on the manager itself, or
    ///     just call `refreshSessionIfNeeded` on the manager to do everything for you.
    mutating func updateTokens(with refreshResponse: RefreshResponse) {
        sessionToken = refreshResponse.sessionToken
        refreshToken = refreshResponse.refreshToken ?? refreshToken
    }
    
    /// Updates the session user's details with those from another ``DescopeUser`` value.
    ///
    ///     let userResponse = try await Descope.auth.me(refreshJwt: session.refreshJwt)
    ///     session.updateUser(with: userResponse)
    ///
    /// - Important: It's recommended to use a ``DescopeSessionManager`` to manage sessions,
    ///     in which case you should call `updateUser` on the manager itself instead
    ///     to ensure that the updated user details are saved.
    mutating func updateUser(with user: DescopeUser) {
        self.user = user
    }
}

extension DescopeSession: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeSession`` object.
    ///
    /// It returns a string with the unique id of the session user as well as
    /// the refresh token's expiry time.
    public var description: String {
        let expires = refreshToken.isExpired ? "expired" : "expires"
        return "DescopeSession(userId: \"\(user.userId)\", \(expires): \(refreshToken.expiresAt))"
    }
}
