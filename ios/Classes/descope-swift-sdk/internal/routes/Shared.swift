
import Foundation

protocol Route {
    var client: DescopeClient { get }
}

extension Route {
    var logger: DescopeLogger? {
        return client.config.logger
    }
}

extension DescopeClient.UserResponse.Fields {
    func convert() -> DescopeUser {
        var pictureURL: URL?
        if let picture, !picture.isEmpty {
            pictureURL = URL(string: picture)
        }
        
        let user = DescopeUser(
            userId: userId,
            loginIds: loginIds,
            status: DescopeUser.Status(rawValue: status) ?? .enabled,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdTime)),
            email: email == "" ? nil : email,
            isVerifiedEmail: verifiedEmail ?? false,
            phone: phone == "" ? nil : phone,
            isVerifiedPhone: verifiedPhone ?? false,
            name: name == "" ? nil : name,
            givenName: givenName == "" ? nil : givenName,
            middleName: middleName == "" ? nil : middleName,
            familyName: familyName == "" ? nil : familyName,
            picture: pictureURL,
            authentication: DescopeUser.Authentication(
                passkey: webauthn,
                password: password,
                totp: TOTP,
                oauth: Set(OAuth.keys),
                sso: SAML,
                scim: SCIM,
            ),
            authorization: DescopeUser.Authorization(
                roles: Set(roleNames),
                ssoAppIds: Set(ssoAppIds),
            ),
            customAttributes: [:], // copied in UserResponse's convert
            isUpdateRequired: false,
        )
        
        return user
    }
}

extension DescopeClient.UserResponse {
    func convert() -> DescopeUser {
        var user = fields.convert()
        user.customAttributes = customAttributes
        return user
    }
}

extension DescopeClient.TenantsResponse {
    func convert() -> [DescopeTenant] {
        return tenants.map { tenant in
            return DescopeTenant(tenantId: tenant.id, name: tenant.name, customAttributes: tenant.customAttributes)
        }
    }
}

extension DescopeClient.JWTResponse {
    func convert() throws(DescopeError) -> AuthenticationResponse {
        guard let sessionJwt, !sessionJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing session JWT") }
        guard let refreshJwt, !refreshJwt.isEmpty else { throw DescopeError.decodeError.with(message: "Missing refresh JWT") }
        guard let user else { throw DescopeError.decodeError.with(message: "Missing user details") }
        return try AuthenticationResponse(sessionToken: Token(jwt: sessionJwt), refreshToken: Token(jwt: refreshJwt), user: user.convert(), isFirstAuthentication: firstSeen)
    }
}

extension DescopeClient.MaskedAddress {
    func convert(method: DeliveryMethod) throws(DescopeError) -> String {
        switch method {
        case .email:
            guard let maskedEmail else { throw DescopeError.decodeError.with(message: "Missing masked email") }
            return maskedEmail
        case .sms, .whatsapp:
            guard let maskedPhone else { throw DescopeError.decodeError.with(message: "Missing masked phone") }
            return maskedPhone
        }
    }
}

extension [SignInOptions] {
    func convert() throws(DescopeError) -> (refreshJwt: String?, loginOptions: DescopeClient.LoginOptions?) {
        guard !isEmpty else { return (nil, nil) }
        var refreshJwt: String?
        var loginOptions = DescopeClient.LoginOptions()
        for option in self {
            switch option {
            case .customClaims(let dict):
                guard JSONSerialization.isValidJSONObject(dict) else { throw DescopeError.encodeError.with(message: "Invalid custom claims payload") }
                loginOptions.customClaims = dict
            case .stepup(let value):
                loginOptions.stepup = true
                refreshJwt = value
            case .mfa(let value):
                loginOptions.mfa = true
                refreshJwt = value
            case .revokeOtherSessions:
                loginOptions.revokeOtherSessions = true
            }
        }
        return (refreshJwt, loginOptions)
    }
}
