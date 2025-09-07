
import Foundation
#if os(iOS)
import UIKit
#endif

/// Returned from user authentication calls.
public struct AuthenticationResponse: Sendable {
    public var sessionToken: DescopeToken
    public var refreshToken: DescopeToken
    public var user: DescopeUser
    public var isFirstAuthentication: Bool
}

/// Returned from the ``DescopeAuth/refreshSession(refreshJwt:)`` call.
public struct RefreshResponse: Sendable {
    public var sessionToken: DescopeToken
    public var refreshToken: DescopeToken?
}

/// Returned from calls that start an enchanted link flow.
///
/// The ``linkId`` value needs to be displayed to the user so they know which
/// link should be clicked on in the enchanted link email. The ``maskedEmail``
/// field can also be shown to inform the user to which address the email
/// was sent. The ``pendingRef`` field is used to poll the server for the
/// enchanted link flow result.
public struct EnchantedLinkResponse: Sendable {
    public var linkId: String
    public var pendingRef: String
    public var maskedEmail: String
}

/// Returned from TOTP calls that create a new seed.
///
/// The ``provisioningURL`` field wraps the key (seed) in a `URL` that can be
/// opened by authenticator apps. The ``image`` field encodes the key (seed)
/// in a QR code image.
public struct TOTPResponse: Sendable {
    public var provisioningURL: URL
    #if os(iOS)
    public var image: UIImage
    #else
    public var image: Data
    #endif
    public var key: String
}

/// Represents the rules for valid passwords.
///
/// The policy is configured in the password settings in the Descope console, and
/// these values can be used to implement client-side validation of new user passwords
/// for a better user experience.
///
/// In any case, all password rules are enforced by Descope on the server side as well.
public struct PasswordPolicyResponse: Sendable {
    public var minLength: Int
    public var lowercase: Bool
    public var uppercase: Bool
    public var number: Bool
    public var nonAlphanumeric: Bool
}
