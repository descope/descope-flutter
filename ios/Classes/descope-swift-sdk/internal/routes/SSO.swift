
import Foundation

final class SSO: DescopeSSO {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func start(emailOrTenantName: String, redirectURL: String?, options: [SignInOptions]) async throws(DescopeError) -> URL {
        let (refreshJwt, loginOptions) = try options.convert()
        let response = try await client.ssoStart(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions)
        guard let url = URL(string: response.url) else { throw DescopeError.decodeError.with(message: "Invalid redirect URL") }
        return url
    }
    
    func exchange(code: String) async throws(DescopeError) -> AuthenticationResponse {
        return try await client.ssoExchange(code: code).convert()
    }
}
