
import AuthenticationServices
import CryptoKit

private let flowRedirectScheme = "descopeflow"
private let flowRedirectURL = "\(flowRedirectScheme)://redirect"

final class _Flow: _DescopeFlow, Route {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }

    var current: DescopeFlowRunner?

    func start(runner: DescopeFlowRunner) async throws -> AuthenticationResponse {
        // adds some required query parameters to the flow URL to facilitate PKCE and
        // redirection at the end of the flow
        let (initialURL, codeVerifier, codeChallenge) = try prepareInitialRequest(for: runner)
        // prime the flow if the runner has flow authentication info
        if let flowAuthentication = runner.flowAuthentication {
            try await client.flowPrime(codeChallenge: codeChallenge, flowId: flowAuthentication.flowId, refreshJwt: flowAuthentication.refreshJwt)
        }
        logger.info("Starting flow authentication", initialURL)
        
        // sets the flow we're about to present as the current flow
        current = runner
        
        // ensure that whatever the result of this method is we remove the reference
        // to the runner from the current property
        defer { resetRunner(runner) }
        
        // we wrap the callback based work with ASWebAuthenticationSession so it fits
        // an async/await code style as any other action the SDK performs. The onCancel
        // closure ensures that we handle task cancellation properly by calling `cancel()`
        // on the runner, which is then handled internally by the `run` function.
        return try await withTaskCancellationHandler {
            // flows are presenteed using AuthenticationServices which only supports callbacks
            // based methods, so we wrap the entire flow running in a continuation that returns
            // either an error or an authorization code
            let authorizationCode = try await withCheckedThrowingContinuation { continuation in
                // opens the URL in sandboxed browser via ASWebAuthenticationSession
                run(runner, url: initialURL, codeVerifier: codeVerifier, sessions: []) { result in
                    continuation.resume(with: result)
                }
            }
            // if the above call didn't throw we can exchange the authorization code for
            // an authenticated user session
            return try await exchange(runner, authorizationCode: authorizationCode, codeVerifier: codeVerifier)
        } onCancel: {
            // the task that called `start(runner:)` was cancelled, so we treat it as if
            // `cancel()` was called on the runner itself
            Task { @MainActor in
                runner.cancel()
            }
        }
    }
    
    @MainActor
    private func run(_ runner: DescopeFlowRunner, url: URL, codeVerifier: String, sessions: [ASWebAuthenticationSession], completion: @escaping (Result<String, Error>) -> Void) {
        // tracks whether this call to `run` still needs to call its completion handler
        var completed = false
        
        // opens the URL in a sandboxed browser, when the flow completes it will know
        // to redirect to a URL that starts with `descopeauth://flow` and that contains
        // the authorization code we need. At that point the session will catch this
        // and call our completion handler.
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: flowRedirectScheme) { [self] callbackURL, error in
            Task {
                // protects against the completion handler being called multiple times, e.g.,
                // in case the session is cancelled or another call to `run` in recursion
                // will be responsible to call it
                guard !completed else { return logger.debug("Skipping previous web session completion") }
                completed = true
                
                // parse the URL we got from the flow to get the authorization code
                let result: Result<String, Error>
                do {
                    let code = try parseAuthorizationCode(callbackURL, error)
                    logger.info("Received flow authorization code")
                    result = .success(code)
                } catch {
                    result = .failure(error)
                }

                // if this is a recursive call to `run` we close any previous sessions,
                // otherwise we might have lingering browser windows
                for session in sessions {
                    logger.debug("Cancelling previous web session", session)
                    session.cancel()
                }
                
                // hands back control to the initial `start` method call
                completion(result)
            }
        }
        
        // gets a presentation anchor from the runner or uses the default one if none was set
        let contextProvider = runner.contextProvider
        
        // when presenting the flow initially we only ask for shared user data if that option
        // was set, in subsequent sessions after magic link authentication we always set this
        // to true so the user won't get a confirmation dialog twice
        if sessions.isEmpty {
            session.prefersEphemeralWebBrowserSession = !runner.shouldAccessSharedUserData
        } else {
            session.prefersEphemeralWebBrowserSession = true
        }
        
        // opens the flow in a sandboxed browser view
        logger.info("Presenting web session", session)
        session.presentationContextProvider = contextProvider
        session.start()
        
        Task {
            do {
                logger.debug("Polling for runner cancellation or redirect")
                while !completed {
                    guard !runner.isCancelled else { throw DescopeError.flowCancelled }
                    
                    if let pendingURL = runner.pendingURL {
                        logger.debug("Handling redirect url for flow authentication", pendingURL)
                        runner.pendingURL = nil
                        guard let nextURL = prepareRedirectRequest(for: runner, redirectURL: pendingURL) else { continue }
                        logger.info("Redirecting flow authentication", nextURL)
                        completed = true
                        return run(runner, url: nextURL, codeVerifier: codeVerifier, sessions: sessions+[session], completion: completion)
                    }
                    
                    try await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                }
            } catch {
                logger.info("Flow authentication cancelled")
                completed = true
                for session in sessions {
                    session.cancel()
                }
                session.cancel()
                completion(.failure(DescopeError.flowCancelled))
            }
        }
    }
    
    @MainActor
    private func exchange(_ runner: DescopeFlowRunner, authorizationCode: String, codeVerifier: String) async throws -> AuthenticationResponse {
        guard !runner.isCancelled else { throw DescopeError.flowCancelled }
        let jwtResponse = try await client.flowExchange(authorizationCode: authorizationCode, codeVerifier: codeVerifier)
        guard !runner.isCancelled else { throw DescopeError.flowCancelled }
        return try jwtResponse.convert()
    }

    private func parseAuthorizationCode(_ callbackURL: URL?, _ error: Error?) throws -> String {
        if let error {
            switch error {
            case ASWebAuthenticationSessionError.canceledLogin:
                logger.info("Flow authentication cancelled by user")
                throw DescopeError.flowCancelled
            case ASWebAuthenticationSessionError.presentationContextInvalid:
                logger.error("Invalid presentation context for flow authentication web session", error)
            case ASWebAuthenticationSessionError.presentationContextNotProvided:
                logger.error("No presentation context for flow authentication web session", error)
            default:
                logger.error("Unexpected error from flow authentication web session", error)
            }
            throw DescopeError.flowFailed.with(cause: error)
        }

        guard let callbackURL else { throw DescopeError.flowFailed.with(message: "Authentication session finished without callback") }
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else { throw DescopeError.flowFailed.with(message: "Authentication session finished with invalid callback") }
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else { throw DescopeError.flowFailed.with(message: "Authentication session finished without authorization code") }
        
        return code
    }
    
    @MainActor
    private func resetRunner(_ runner: DescopeFlowRunner) {
        guard current === runner else { return }
        logger.debug("Resetting current flow runner property")
        current = nil
    }
}

// Internal

private extension Data {
    init?(randomBytesCount count: Int) {
        var bytes = [Int8](repeating: 0, count: count)
        guard SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else { return nil }
        self = Data(bytes: bytes, count: count)
    }
}

private func prepareInitialRequest(for runner: DescopeFlowRunner) throws -> (url: URL, codeVerifier: String, codeChallenge: String) {
    guard let randomBytes = Data(randomBytesCount: 32) else { throw DescopeError.flowFailed.with(message: "Error generating random bytes") }
    let hashedBytes = Data(SHA256.hash(data: randomBytes))
    
    let codeVerifier = randomBytes.base64URLEncodedString()
    let codeChallenge = hashedBytes.base64URLEncodedString()

    guard let url = URL(string: runner.flowURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw DescopeError.flowFailed.with(message: "Malformed flow URL") }
    components.queryItems = components.queryItems ?? []
    components.queryItems?.append(URLQueryItem(name: "ra-callback", value: flowRedirectURL))
    components.queryItems?.append(URLQueryItem(name: "ra-challenge", value: codeChallenge))
    #if os(macOS)
    components.queryItems?.append(URLQueryItem(name: "ra-initiator", value: "macos"))
    #else
    components.queryItems?.append(URLQueryItem(name: "ra-initiator", value: "ios"))
    #endif

    guard let initialURL = components.url else { throw DescopeError.flowFailed.with(message: "Failed to create flow URL") }
    
    return (initialURL, codeVerifier, codeChallenge)
}

private func prepareRedirectRequest(for runner: DescopeFlowRunner, redirectURL: URL) -> URL? {
    guard let pendingComponents = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false) else { return nil }
    guard let url = URL(string: runner.flowURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    components.queryItems = components.queryItems ?? []
    for item in pendingComponents.queryItems ?? [] {
        components.queryItems?.append(item)
    }
    return components.url
}
