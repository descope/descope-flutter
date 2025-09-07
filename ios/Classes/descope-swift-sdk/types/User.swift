
import Foundation

/// The ``DescopeUser`` struct represents an existing user in Descope.
///
/// After a user is signed in with any authentication method the ``DescopeSession`` object
/// keeps a ``DescopeUser`` value in its `user` property so the user's details are always
/// available.
///
/// In the example below we finalize an OTP authentication for the user by verifying the
/// code. The authentication response has a `user` property which can be used
/// directly or later on when it's kept in the ``DescopeSession``.
///
///     let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
///     print("Finished OTP login for user: \(authResponse.user)")
///
///     Descope.sessionManager.session = DescopeSession(from: authResponse)
///     print("Created session for user \(descopeSession.user.userId)")
///
/// The details for a signed in user can be updated manually by calling `auth.me` with
/// the `refreshJwt` from the active ``DescopeSession``. If the operation is successful the call
/// returns a new ``DescopeUser`` value.
///
///     guard let session = Descope.sessionManager.session else { return }
///     let descopeUser = try await Descope.auth.me(refreshJwt: session.refreshJwt)
///     session.update(with: descopeUser)
///
/// In the code above we check that there's an active ``DescopeSession`` in the shared
/// session manager. If so we ask the Descope server for the latest user details and
/// then update the ``DescopeSession`` with them.
public struct DescopeUser: @unchecked Sendable {
    /// The unique identifier for the user in Descope.
    ///
    /// This value never changes after the user is created, and it always matches
    /// the `Subject` (`sub`) claim value in the user's JWT after signing in.
    public var userId: String
    
    /// The identifiers the user can sign in with.
    ///
    /// This is a list of one or more email addresses, phone numbers, usernames, or any
    /// custom identifiers the user can authenticate with.
    public var loginIds: [String]
    
    /// The time at which the user was created in Descope.
    public var createdAt: Date
    
    /// The user's email address.
    ///
    /// If this is non-nil and the ``isVerifiedEmail`` flag is `true` then this email address
    /// can be used to do email based authentications such as magic link, OTP, etc.
    public var email: String?
    
    /// Whether the email address has been verified to be a valid authentication method
    /// for this user. If ``email`` is `nil` then this is always `false`.
    public var isVerifiedEmail: Bool
    
    /// The user's phone number.
    ///
    /// If this is non-nil and the ``isVerifiedPhone`` flag is `true` then this phone number
    /// can be used to do phone based authentications such as OTP.
    public var phone: String?
    
    /// Whether the phone number has been verified to be a valid authentication method
    /// for this user. If ``phone`` is `nil` then this is always `false`.
    public var isVerifiedPhone: Bool
    
    /// The user's full name.
    public var name: String?

    /// The user's given name.
    public var givenName: String?
    
    /// The user's middle name.
    public var middleName: String?
    
    /// The user's family name.
    public var familyName: String?
    
    /// The user's profile picture.
    public var picture: URL?

    /// A mapping of any custom attributes associated with this user. The custom attributes
    /// are managed via the Descope console.
    public var customAttributes: [String: Any]

    public init(userId: String, loginIds: [String], createdAt: Date, email: String? = nil, isVerifiedEmail: Bool = false, phone: String? = nil, isVerifiedPhone: Bool = false, name: String? = nil, givenName: String? = nil, middleName: String? = nil, familyName: String? = nil, picture: URL? = nil, customAttributes: [String: Any] = [:]) {
        self.userId = userId
        self.loginIds = loginIds
        self.createdAt = createdAt
        self.email = email
        self.isVerifiedEmail = isVerifiedEmail
        self.phone = phone
        self.isVerifiedPhone = isVerifiedPhone
        self.name = name
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.picture = picture
        self.customAttributes = customAttributes
    }
}

extension DescopeUser: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeUser`` object.
    ///
    /// It returns a string with the user's unique id, login id, and name.
    public var description: String {
        var extras = ""
        if let loginId = loginIds.first {
            extras += ", loginId: \"\(loginId)\""
        }
        if let name {
            extras += ", name: \"\(name)\""
        }
        return "DescopeUser(id: \"\(userId)\"\(extras))"
    }
}

extension DescopeUser: Equatable {
    public static func == (lhs: DescopeUser, rhs: DescopeUser) -> Bool {
        let attrs = lhs.customAttributes as NSDictionary
        return lhs.userId == rhs.userId && lhs.loginIds == rhs.loginIds &&
            lhs.createdAt == rhs.createdAt && lhs.picture == rhs.picture &&
            lhs.email == rhs.email && lhs.isVerifiedEmail == rhs.isVerifiedEmail &&
            lhs.phone == rhs.phone && lhs.isVerifiedPhone == rhs.isVerifiedPhone &&
            lhs.name == rhs.name && lhs.givenName == rhs.givenName &&
            lhs.middleName == rhs.middleName && lhs.familyName == rhs.familyName &&
            attrs.isEqual(to: rhs.customAttributes)
    }
}

// Unfortunately we can't rely on the compiler for automatic conformance
// to Codable because the customAttributes dictionary isn't serializable
extension DescopeUser: Codable {
    enum CodingKeys: CodingKey {
        case userId, loginIds, createdAt, email, isVerifiedEmail, phone, isVerifiedPhone, name, givenName, middleName, familyName, picture, customAttributes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        userId = try values.decode(String.self, forKey: .userId)
        loginIds = try values.decode([String].self, forKey: .loginIds)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        isVerifiedEmail = try values.decode(Bool.self, forKey: .isVerifiedEmail)
        phone = try values.decodeIfPresent(String.self, forKey: .phone)
        isVerifiedPhone = try values.decode(Bool.self, forKey: .isVerifiedPhone)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        givenName = try values.decodeIfPresent(String.self, forKey: .givenName)
        middleName = try values.decodeIfPresent(String.self, forKey: .middleName)
        familyName = try values.decodeIfPresent(String.self, forKey: .familyName)
        picture = try values.decodeIfPresent(URL.self, forKey: .picture)
        if let value = try values.decodeIfPresent(String.self, forKey: .customAttributes), let json = try? JSONSerialization.jsonObject(with: Data(value.utf8)) {
            customAttributes = json as? [String: Any] ?? [:]
        } else {
            customAttributes = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(userId, forKey: .userId)
        try values.encode(loginIds, forKey: .loginIds)
        try values.encode(createdAt, forKey: .createdAt)
        try values.encodeIfPresent(email, forKey: .email)
        try values.encode(isVerifiedEmail, forKey: .isVerifiedEmail)
        try values.encodeIfPresent(phone, forKey: .phone)
        try values.encode(isVerifiedPhone, forKey: .isVerifiedPhone)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encodeIfPresent(givenName, forKey: .givenName)
        try values.encodeIfPresent(middleName, forKey: .middleName)
        try values.encodeIfPresent(familyName, forKey: .familyName)
        try values.encodeIfPresent(picture, forKey: .picture)
        // check before trying to serialize to prevent a runtime exception from being triggered
        if JSONSerialization.isValidJSONObject(customAttributes), let data = try? JSONSerialization.data(withJSONObject: customAttributes), let value = String(bytes: data, encoding: .utf8) {
            try values.encode(value, forKey: .customAttributes)
        }
    }
}
