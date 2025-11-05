
import Foundation

private let defaultPollDuration: TimeInterval = 2 /* mins */ * 60 /* secs */

final class EnchantedLink: DescopeEnchantedLink, Route {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func signUp(loginId: String, details: SignUpDetails?, redirectURL: String?) async throws(DescopeError) -> EnchantedLinkResponse {
        return try await client.enchantedLinkSignUp(loginId: loginId, details: details, redirectURL: redirectURL).convert()
    }
    
    func signIn(loginId: String, redirectURL: String?, options: [SignInOptions]) async throws(DescopeError) -> EnchantedLinkResponse {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.enchantedLinkSignIn(loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions).convert()
    }
    
    func signUpOrIn(loginId: String, redirectURL: String?, options: [SignInOptions]) async throws(DescopeError) -> EnchantedLinkResponse {
        let (refreshJwt, loginOptions) = try options.convert()
        return try await client.enchantedLinkSignUpOrIn(loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: loginOptions).convert()
    }
    
    func updateEmail(_ email: String, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions) async throws(DescopeError) -> EnchantedLinkResponse {
        return try await client.enchantedLinkUpdateEmail(email, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options).convert()
    }
    
    func checkForSession(pendingRef: String) async throws(DescopeError) -> AuthenticationResponse {
        return try await client.enchantedLinkPendingSession(pendingRef: pendingRef).convert()
    }
    
    func pollForSession(pendingRef: String, timeout: TimeInterval?) async throws(DescopeError) -> AuthenticationResponse {
        let pollingEndsAt = Date() + (timeout ?? defaultPollDuration)
        logger.info("Polling for enchanted link", timeout ?? defaultPollDuration)
        while true {
            do {
                // ensure that the async task hasn't been cancelled
                try Task.checkCancellation(throwing: .enchantedLinkCancelled)
                // check for the session once, any errors not specifically handled
                // below are intentionally let through to the calling code
                let response = try await checkForSession(pendingRef: pendingRef)
                logger.info("Enchanted link authentication succeeded")
                return response
            } catch .enchantedLinkPending {
                logger.debug("Waiting for enchanted link")
                // sleep for a second before checking again
                try await Task.sleep(seconds: 1, throwing: .enchantedLinkCancelled)
                // if the timer's expired then we throw a specific error that
                // can be handled appropriately by the calling code
                guard Date() < pollingEndsAt else {
                    logger.error("Timed out while polling for enchanted link")
                    throw DescopeError.enchantedLinkExpired
                }
            } catch let error where error ~= .networkError {
                // we managed to start the enchanted link authentication
                // so any network errors we get now are probably temporary
                try await Task.sleep(seconds: 1, throwing: .enchantedLinkCancelled)
                // if the timer's expired then we rethrow the network
                // error as that was probably the cause, rather than the
                // user not verifying the enchanted link email
                guard Date() < pollingEndsAt else {
                    logger.error("Timed out with network error while polling for enchanted link", error)
                    throw error
                }
                logger.debug("Ignoring network error while polling for enchanted link", error)
            }
        }
    }
}

private extension DescopeClient.EnchantedLinkResponse {
    func convert() -> EnchantedLinkResponse {
        return EnchantedLinkResponse(linkId: linkId, pendingRef: pendingRef, maskedEmail: maskedEmail)
    }
}
