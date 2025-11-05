
import Foundation

final class MagicLink: DescopeMagicLink {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(with method: DeliveryMethod, loginId: String, details: SignUpDetails?, redirectURL: String?) async throws(DescopeError) -> String {
        return try await client.magicLinkSignUp(with: method, loginId: loginId, details: details, redirectURL: redirectURL).convert(method: method)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String, redirectURL: String?, options: [SignInOptions]) async throws(DescopeError) -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.magicLinkSignIn(with: method, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions).convert(method: method)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String, redirectURL: String?, options: [SignInOptions]) async throws(DescopeError) -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.magicLinkSignUpOrIn(with: method, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions).convert(method: method)
    }
    
    func updateEmail(_ email: String, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions) async throws(DescopeError) -> String {
        return try await client.magicLinkUpdateEmail(email, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options).convert(method: .email)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions) async throws(DescopeError) -> String {
        return try await client.magicLinkUpdatePhone(phone, with: method, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options).convert(method: method)
    }
    
    func verify(token: String) async throws(DescopeError) -> AuthenticationResponse {
        return try await client.magicLinkVerify(token: token).convert()
    }
}
