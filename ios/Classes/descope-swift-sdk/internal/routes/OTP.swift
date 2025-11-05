
final class OTP: DescopeOTP {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    func signUp(with method: DeliveryMethod, loginId: String, details: SignUpDetails?) async throws(DescopeError) -> String {
        return try await client.otpSignUp(with: method, loginId: loginId, details: details).convert(method: method)
    }
    
    func signIn(with method: DeliveryMethod, loginId: String, options: [SignInOptions]) async throws(DescopeError) -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.otpSignIn(with: method, loginId: loginId, refreshJwt: refreshJwt, options: loginOptions).convert(method: method)
    }
    
    func signUpOrIn(with method: DeliveryMethod, loginId: String, options: [SignInOptions]) async throws(DescopeError) -> String {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.otpSignUpIn(with: method, loginId: loginId, refreshJwt: refreshJwt, options: loginOptions).convert(method: method)
    }
    
    func verify(with method: DeliveryMethod, loginId: String, code: String) async throws(DescopeError) -> AuthenticationResponse {
        return try await client.otpVerify(with: method, loginId: loginId, code: code).convert()
    }
    
    func updateEmail(_ email: String, loginId: String, refreshJwt: String, options: UpdateOptions) async throws(DescopeError) -> String {
        return try await client.otpUpdateEmail(email, loginId: loginId, refreshJwt: refreshJwt, options: options).convert(method: .email)
    }
    
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, options: UpdateOptions) async throws(DescopeError) -> String {
        return try await client.otpUpdatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt, options: options).convert(method: method)
    }
}
