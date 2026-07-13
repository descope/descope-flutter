
import Foundation

/// The delivery method for an OTP or Magic Link message.
public enum DeliveryMethod: String, Sendable {
    case whatsapp
    case sms
    case email
}

/// Which sessions are revoked when calling ``DescopeAuth/revokeSessions(_:refreshJwt:)``.
public enum RevokeType: Sendable {
    /// Revoke the session for the provided refresh JWT.
    case currentSession

    /// Revoke all sessions for the user, including the session for the provided refresh JWT.
    case allSessions
}

/// The provider to use in an OAuth flow.
public struct OAuthProvider: Sendable, ExpressibleByStringLiteral {
    public static let facebook: OAuthProvider = "facebook"
    public static let github: OAuthProvider = "github"
    public static let google: OAuthProvider = "google"
    public static let microsoft: OAuthProvider = "microsoft"
    public static let gitlab: OAuthProvider = "gitlab"
    public static let apple: OAuthProvider = "apple"
    public static let slack: OAuthProvider = "slack"
    public static let discord: OAuthProvider = "discord"

    public let name: String
    
    public init(stringLiteral value: String) {
        name = value
    }
}

/// Used to provide additional details about a user in sign up calls.
public struct SignUpDetails: Sendable {
    public var name: String?
    public var email: String?
    public var phone: String?
    public var givenName: String?
    public var middleName: String?
    public var familyName: String?
    
    public init(name: String? = nil, phone: String? = nil, email: String? = nil, givenName: String? = nil, middleName: String? = nil, familyName: String? = nil) {
        self.name = name
        self.phone = phone
        self.email = email
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
    }
}

/// Used to require additional behaviors when authenticating a user.
public enum SignInOptions: @unchecked Sendable {
    /// Adds additional custom claims to the user's JWT during authentication.
    ///
    /// For example, the following code starts an OTP sign in and requests a custom claim
    /// with the authenticated user's full name:
    ///
    ///     try await Descope.otp.signIn(with: .email, loginId: "andy@example.com", options: [
    ///         .customClaims(["name": "{{user.name}}"]),
    ///     ])
    ///
    /// - Important: Any custom claims added via this method are considered insecure and will
    /// be nested under the `nsec` custom claim.
    case customClaims([String: Any])
    
    /// Used to add layered security to your app by implementing Step-up authentication.
    ///
    ///     guard let session = Descope.sessionManager.session else { return }
    ///     try await Descope.otp.signIn(with: .email, loginId: "andy@example.com", options: [
    ///         .stepup(refreshJwt: session.refreshJwt),
    ///     ])
    ///
    /// After the Step-up authentication completes successfully the returned session JWT will
    /// have an `su` claim with a value of `true`.
    ///
    /// - Note: The `su` claim is not set on the refresh JWT.
    case stepup(refreshJwt: String)
    
    /// Used to add layered security to your app by implementing Multi-factor authentication.
    ///
    /// Assuming the user has already signed in successfully with one authentication method,
    /// we can take the `refreshJwt` and pass it as an `mfa` option to another authentication
    /// method.
    ///
    ///     guard let session = Descope.sessionManager.session else { return }
    ///     try await Descope.otp.signIn(with: .email, loginId: "andy@example.com", options: [
    ///         .mfa(refreshJwt: session.refreshJwt),
    ///     ])
    ///
    /// After the MFA authentication completes successfully the `amr` claim in both the session
    /// and refresh JWTs will be an array with an entry for each authentication method used.
    case mfa(refreshJwt: String)

    /// Revoke all other active sessions for the user.
    ///
    /// Use this option to ensure the user only ever has one active sign in at a time, and that
    /// refresh JWTs from previous sign ins and on other devices are revoked.
    case revokeOtherSessions
}

/// Used to configure how users are updated.
public struct UpdateOptions: OptionSet, Sendable {
    /// Whether to allow sign in from a new `loginId` after an update.
    ///
    /// When a user's email address or phone number are updated and this option is set
    /// the new value is added to the user's list of `loginIds`, and the user from that
    /// point on will be able to use it to sign in.
    public static let addToLoginIds = UpdateOptions(rawValue: 1)
    
    /// Whether to keep or delete the current user when merging two users after an update.
    ///
    /// When updating a user's email address or phone number with the ``addToLoginIds``
    /// option set, if another user in the the system already has the same email address
    /// or phone number as the one being added in their list of `loginIds` the two users
    /// are merged and one of them is deleted.
    ///
    /// This scenario can happen when a user uses multiple authentication methods
    /// and ends up with multiple accounts. For example, a user might sign in with
    /// their email address at first. Then at some point later they reinstall the
    /// app and use OAuth to authenticate, and a new user account is created. If
    /// the user then updates their account and adds their email address the
    /// two accounts need to be merged.
    ///
    /// Let's define the "updated user" to be the user being updated and whom
    /// the `refreshJwt` belongs to, and the "existing user" to be another user in
    /// the system with the same `loginId`.
    ///
    /// By default, the updated user is kept, the existing user's details are merged
    /// into the updated user, and the existing user is then deleted.
    ///
    /// If this option is set however then the current user is merged into the existing
    /// user, and the current user is deleted. In this case the ``DescopeSession`` and
    /// its `refreshJwt` that was used to initiate the update operation will no longer
    /// be valid, and an ``AuthenticationResponse`` is returned for the existing user
    /// instead.
    public static let onMergeUseExisting = UpdateOptions(rawValue: 2)
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
