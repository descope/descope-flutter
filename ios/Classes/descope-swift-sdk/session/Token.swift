
import Foundation

/// A ``DescopeToken`` is a utility wrapper around a single JWT value.
///
/// The session and refresh JWTs in a ``DescopeSession`` are stored as
/// instances of ``DescopeToken``. It's also returned directly when
/// exchanging an access key for a session JWT.
public protocol DescopeToken: Sendable {
    /// The underlying JWT value
    var jwt: String { get }
    
    /// The value of the "sub" (subject) claim, which is the unique id
    /// of the user or access key the JWT was generated for.
    var entityId: String { get }

    /// The value of the "iss" (issuer) claim which is the unique id
    /// of the Descope project the JWT was generated for.
    var projectId: String { get }
    
    /// The value of the "iat" (issue time) claim which is the time at
    /// which the JWT was created.
    var issuedAt: Date { get }

    /// The value of the "exp" (expiration time) claim which is the time
    /// after which the JWT expires.
    var expiresAt: Date { get }
    
    /// Whether the JWT expiry time has already passed.
    var isExpired: Bool { get }
    
    /// A map with all the custom claims in the JWT value. It includes
    /// any claims whose values aren't already exposed by other accessors
    /// or authorization functions.
    var claims: [String: Any] { get }
    
    /// Returns the list of permissions granted in the JWT claims. Pass
    /// a value of `nil` for the `tenant` parameter if the project
    /// doesn't use multiple tenants.
    func permissions(tenant: String?) -> [String]
    
    /// Returns the list of roles granted in the JWT claims. Pass
    /// a value of `nil` for the `tenant` parameter if the project
    /// doesn't use multiple tenants.
    func roles(tenant: String?) -> [String]
}

// Internal

final class Token: DescopeToken, @unchecked Sendable {
    let jwt: String
    let entityId: String
    let projectId: String
    let issuedAt: Date
    let expiresAt: Date
    let claims: [String: Any]
    let allClaims: [String: Any]
    
    init(jwt: String) throws(DescopeError) {
        do {
            let dict = try decodeJWT(jwt)
            self.jwt = jwt
            self.entityId = try getClaim(.subject, in: dict)
            self.projectId = try decodeIssuer(getClaim(.issuer, in: dict))
            self.issuedAt = try Date(timeIntervalSince1970: getClaim(.issuedAt, in: dict))
            self.expiresAt = try Date(timeIntervalSince1970: getClaim(.expiration, in: dict))
            self.claims = dict.filter { Claim.isCustom($0.key) }
            self.allClaims = dict
        } catch {
            throw DescopeError.tokenError.with(cause: error)
        }
    }
    
    var isExpired: Bool {
        return expiresAt.timeIntervalSinceNow <= 0
    }
    
    func permissions(tenant: String?) -> [String] {
        let items = try? authorizationItems(tenant: tenant, claim: .permissions)
        return items ?? []
    }
    
    func roles(tenant: String?) -> [String] {
        let items = try? authorizationItems(tenant: tenant, claim: .roles)
        return items ?? []
    }
    
    private func authorizationItems(tenant: String?, claim: Claim) throws -> [String] {
        let items: [String]
        if let tenant {
            items = try getValueForTenant(tenant, key: claim.rawValue) ?? []
        } else {
            items = try getClaim(claim, in: allClaims)
        }
        return items
    }
    
    private func getValueForTenant<T>(_ tenant: String, key: String) throws -> T {
        let tenants = try getTenants()
        guard let object = tenants[tenant] else { throw TokenError.missingTenant(tenant) }
        guard let info = object as? [String: Any] else { throw TokenError.invalidTenant(tenant) }
        guard let value = info[key] as? T else { throw TokenError.invalidTenant(tenant) }
        return value
    }
    
    private func getTenants() throws -> [String: Any] {
        return try getClaim(.tenants, in: allClaims)
    }
}

// Description

extension Token: CustomStringConvertible {
    var description: String {
        let expires = isExpired ? "expired" : "expires"
        return "DescopeToken(entityId: \"\(entityId)\", \(expires): \(expiresAt))"
    }
}

// Error

enum TokenError: Error {
    case invalidFormat
    case invalidEncoding
    case invalidData
    case missingClaim(String)
    case invalidClaim(String)
    case missingTenant(String)
    case invalidTenant(String)
}

extension TokenError: CustomStringConvertible, LocalizedError {
    var description: String {
        return "TokenError(description: \(desc))"
    }
    
    var errorDescription: String? {
        return desc
    }
    
    private var desc: String {
        switch self {
        case .invalidFormat: return "Invalid token format"
        case .invalidEncoding: return "Invalid token encoding"
        case .invalidData: return "Invalid token data"
        case .missingClaim(let claim): return "Missing \(claim) claim in token"
        case .invalidClaim(let claim): return "Invalid \(claim) claim in token"
        case .missingTenant(let tenant): return "Tenant \(tenant) not found in token"
        case .invalidTenant(let tenant): return "Invalid data for tenant \(tenant) in token"
        }
    }
}

// Claims

private enum Claim: String {
    case subject = "sub"
    case issuer = "iss"
    case issuedAt = "iat"
    case expiration = "exp"
    case tenants = "tenants"
    case permissions = "permissions"
    case roles = "roles"
    
    static func isCustom(_ name: String) -> Bool {
        return Claim(rawValue: name) == nil
    }
}

private func getClaim<T>(_ claim: Claim, in dict: [String: Any]) throws -> T {
    return try getClaim(claim.rawValue, in: dict)
}

private func getClaim<T>(_ claim: String, in dict: [String: Any]) throws -> T {
    guard let object = dict[claim] else { throw TokenError.missingClaim(claim) }
    guard let value = object as? T else { throw TokenError.invalidClaim(claim) }
    return value
}

// JWT Decoding

private func decodeEncodedFragment(_ string: String) throws -> Data {
    let length = 4 * ((string.count + 3) / 4)
    let base64 = string
        .replacingOccurrences(of: "_", with: "/")
        .replacingOccurrences(of: "-", with: "+")
        .padding(toLength: length, withPad: "=", startingAt: 0)
    guard let data = Data(base64Encoded: base64) else { throw TokenError.invalidEncoding }
    return data
}

private func decodeFragment(_ string: String) throws -> [String: Any] {
    let data = try decodeEncodedFragment(string)
    guard let json = try? JSONSerialization.jsonObject(with: data) else { throw TokenError.invalidData }
    guard let dict = json as? [String: Any] else { throw TokenError.invalidData }
    return dict
}

private func decodeJWT(_ jwt: String) throws -> [String: Any] {
    guard case let fragments = jwt.components(separatedBy: "."), fragments.count == 3 else { throw TokenError.invalidFormat }
    return try decodeFragment(fragments[1])
}

private func decodeIssuer(_ issuer: String) -> String {
    guard let projectId = issuer.split(separator: "/").last else { return issuer }
    return String(projectId)
}
