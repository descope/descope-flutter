
import AuthenticationServices

enum WebAuth {
    static let redirectScheme = "descopewebauth"
    static let redirectURL = "\(redirectScheme)://redirect"

    @MainActor
    static func performAuthentication(url: URL, accessSharedUserData: Bool, logger: DescopeLogger?) async throws(DescopeError) -> String {
        let callbackURL = try await presentWebAuthentication(url: url, accessSharedUserData: accessSharedUserData, logger: logger)
        return try parseExchangeCode(from: callbackURL)
    }
}

@MainActor
private func presentWebAuthentication(url: URL, accessSharedUserData: Bool, logger: DescopeLogger?) async throws(DescopeError) -> URL? {
    // create a constant class instance to wrap the cancellation closure because
    // the onCancel closure below is nonisolated and can be called concurrently
    // with the main async closure that sets its value
    let cancellation = CancellationWrapper()

    let contextProvider = DefaultPresentationContextProvider()
    #if os(iOS) && canImport(React)
    await contextProvider.waitKeyWindow()
    #endif

    let result: Result<URL?, Error> = await withTaskCancellationHandler {
        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: WebAuth.redirectScheme) { callbackURL, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(callbackURL))
                }
            }

            cancellation.closure = { @MainActor [weak session] in
                logger.info("Web authentication cancelled programmatically")
                session?.cancel()
            }

            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = !accessSharedUserData
            session.start()
        }
    } onCancel: {
        Task { @MainActor in
            cancellation.closure()
        }
    }

    switch result {
    case .failure(ASWebAuthenticationSessionError.canceledLogin):
        logger.info("Web authentication cancelled by user")
        throw DescopeError.webAuthCancelled
    case .failure(ASWebAuthenticationSessionError.presentationContextInvalid):
        logger.error("Invalid presentation context for web authentication")
        throw DescopeError.webAuthFailed.with(message: "Invalid presentation context")
    case .failure(ASWebAuthenticationSessionError.presentationContextNotProvided):
        logger.error("No presentation context for web authentication")
        throw DescopeError.webAuthFailed.with(message: "No presentation context")
    case .failure(let error):
        logger.error("Unexpected error from web authentication", error)
        throw DescopeError.webAuthFailed.with(cause: error)
    case .success(let callbackURL):
        logger.debug("Processing OAuth web authentication", callbackURL)
        return callbackURL
    }
}

@MainActor
private final class CancellationWrapper {
    var closure: @MainActor () -> Void = {}
}

private func parseExchangeCode(from callbackURL: URL?) throws(DescopeError) -> String {
    guard let callbackURL, let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else { throw DescopeError.webAuthFailed.with(message: "Web authentication finished with invalid callback") }
    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { throw DescopeError.webAuthFailed.with(message: "Web authentication finished without authorization code") }
    return code
}
