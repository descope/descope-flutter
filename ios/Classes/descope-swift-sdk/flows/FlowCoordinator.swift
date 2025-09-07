
import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowCoordinator``.
@MainActor
public protocol DescopeFlowCoordinatorDelegate: AnyObject {
    /// Called directly after the flow state is updated.
    ///
    /// Where appropriate, this delegate method is always called before other delegate methods.
    /// For example, if there's an error in the flow this method is called first to report the
    /// state change to ``DescopeFlowState/failed`` and then the failure delegate method is
    /// called with the specific ``DescopeError`` value.
    func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState)

    /// Called when the flow is fully loaded and rendered and is ready to be displayed.
    ///
    /// You can use this method to show a loading state until the flow is fully loaded,
    /// and do a quick animatad transition to show the flow once this method is called.
    func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator)

    /// Called when the user taps on a web link in the flow.
    ///
    /// The `external` parameter is `true` if the link would open in a new browser tab
    /// if the flow was runnning in a regular browser app.
    ///
    /// If your flow doesn't show any web links you can either use an empty implementation
    /// or simply call `UIApplication.shared.open(url)` so that links open in the user's
    /// default browser app.
    func coordinatorDidInterceptNavigation(_ coordinator: DescopeFlowCoordinator, url: URL, external: Bool)

    /// Called when an error occurs in the flow.
    ///
    /// The most common failures are due to internet issues, in which case the `error` will
    /// usually be ``DescopeError/networkError``.
    func coordinatorDidFail(_ coordinator: DescopeFlowCoordinator, error: DescopeError)

    /// Called when the flow completes the authentication successfully.
    ///
    /// The `response` parameter can be used to create a ``DescopeSession`` as with other
    /// authentication methods.
    func coordinatorDidFinish(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse)
}

/// A helper class for running Descope Flows.
///
/// You can use a ``DescopeFlowCoordinator`` to run a flow in a `WKWebView` that was created
/// manually and attached to the coordinator, but in almost all scenarios it should be more
/// convenient to use a ``DescopeFlowViewController`` or a ``DescopeFlowView`` instead.
///
/// To start a flow in a ``DescopeFlowCoordinator``, first create a `WKWebViewConfiguration`
/// object and bootstrap it by calling the coordinator's ``prepare(configuration:)`` method.
/// Create an instance of `WKWebView` and pass the bootstrapped configuration object to the
/// initializer. Attach the webview to the coordinator by setting the ``webView`` property,
/// and finally call the ``start(flow:)`` function.
@MainActor
public class DescopeFlowCoordinator {

    /// A delegate object for receiving events about the state of the flow.
    public weak var delegate: DescopeFlowCoordinatorDelegate?

    /// The flow that's currently running in the ``DescopeFlowCoordinator``.
    public private(set) var flow: DescopeFlow? {
        didSet {
            sdk.resume = resumeClosure
            logger = sdk.config.logger
            bridge.flow = flow
            bridge.logger = logger
        }
    }

    /// The current state of the flow in the ``DescopeFlowCoordinator``.
    public private(set) var state: DescopeFlowState = .initial {
        didSet {
            delegate?.coordinatorDidUpdateState(self, to: state, from: oldValue)
        }
    }

    /// The instance of `WKWebView` that was attached to the coordinator.
    ///
    /// When using a ``DescopeFlowView`` or ``DescopeFlowViewController`` this property
    /// is set automatically to the webview created by them.
    public var webView: WKWebView? {
        didSet {
            bridge.webView = webView
            updateLayoutObserver()
        }
    }

    // Initialization

    private let bridge: FlowBridge

    private var logger: DescopeLogger?

    /// Creates a new ``DescopeFlowCoordinator`` object.
    public init() {
        bridge = FlowBridge()
        bridge.delegate = self
    }

    /// This method must be called on the `WKWebViewConfiguration` instance that's used
    /// when calling the initializer when creating this coordinator's `WKWebView`.
    public func prepare(configuration: WKWebViewConfiguration) {
        bridge.prepare(configuration: configuration)
    }

    // Flow

    /// Loads and displays a Descope Flow.
    ///
    /// The ``delegate`` property should be set before calling this function to ensure
    /// no delegate updates are missed.
    public func start(flow: DescopeFlow) {
        self.flow = flow

        #if !canImport(React)
        if sdk.config.projectId.isEmpty {
            logger.error("The Descope singleton must be setup or an instance of DescopeSDK must be set on the flow")
        }
        #endif

        logger.info("Starting flow authentication", flow)
        handleStarted()

        bridge.start()
    }

    private var sdk: DescopeSDK {
        return flow?.descope ?? Descope.sdk
    }

    // WebView
    
    /// Adds the specified raw CSS to the flow page.
    ///
    /// ```swift
    /// func updateMargins() {
    ///     flowCoordinator.addStyles("body { margin: 16px; }")
    /// }
    /// ```
    ///
    /// - Parameter css: The raw CSS to add, e.g., `".footer { display: none; }"`.
    public func addStyles(_ css: String) {
        bridge.addStyles(css)
    }
    
    /// Runs the specified JavaScript code on the flow page.
    ///
    /// The code is implicitly wrapped in an immediately invoked function expression, so you
    /// can safely declare variables and not worry about polluting the global namespace.
    ///
    /// ```swift
    /// func removeFooter() {
    ///     flowCoordinator.runJavaScript("""
    ///         const footer = document.querySelector('#footer')
    ///         footer?.remove()
    ///     """)
    /// }
    /// ```
    ///
    /// - Parameter code: The JavaScript code to run, e.g., `"console.log('Hello world')"`.
    public func runJavaScript(_ code: String) {
        bridge.runJavaScript(code)
    }

    // Hooks

    private func executeHooks(event: DescopeFlowHook.Event) {
        var hooks = DescopeFlowHook.defaults
        if let flow {
            hooks.append(contentsOf: flow.hooks)
        }
        for hook in hooks where hook.events.contains(event) {
            hook.execute(event: event, coordinator: self)
        }
    }

    // Layout

    private var layoutObserver: WebViewLayoutObserver?

    private func updateLayoutObserver() {
        if let webView {
            layoutObserver = WebViewLayoutObserver(webView: webView, handler: { [weak self] in self?.handleLayoutChange() })
        } else {
            layoutObserver = nil
        }
    }

    private func handleLayoutChange() {
        executeHooks(event: .layout)
    }

    // State

    private func ensureState(_ states: DescopeFlowState...) -> Bool {
        guard states.contains(state) else {
            logger.error("Unexpected flow state", state, states)
            return false
        }
        return true
    }

    private func sendResponse(_ response: FlowBridgeResponse) {
        guard ensureState(.started, .ready) else { return } // we get here in started state if the flow has no screens
        bridge.postResponse(response)
    }

    // Session

    private var sessionTimer: Timer?

    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let coordinator = self else { return timer.invalidate() }
            Task { @MainActor in
                coordinator.updateRefreshJwt()
            }
        }
    }

    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }

    private func updateRefreshJwt() {
        guard let session = flow?.providedSession else { return }
        bridge.updateRefreshJwt(session.refreshJwt)
    }

    // Resume

    private func resume(_ url: URL) -> Bool {
        guard state == .ready else {
            logger.debug("Ignoring resume URL", state)
            return false
        }
        logger.info("Received URL for resuming flow", url)
        sendResponse(.magicLink(url: url.absoluteString))
        return true
    }

    private lazy var resumeClosure: DescopeSDK.ResumeClosure = { [weak self] url in
        return self?.resume(url) ?? false
    }

    // Events

    private func handleStarted() {
        guard ensureState(.initial) else { return }
        state = .started
        executeHooks(event: .started)
    }

    private func handleLoading() {
        guard ensureState(.started) else { return }
        executeHooks(event: .loading)
    }

    private func handleLoaded() {
        guard ensureState(.started) else { return }
        executeHooks(event: .loaded)
    }

    private func handleReady() {
        guard ensureState(.started) else { return }
        state = .ready
        executeHooks(event: .ready)
        startSessionTimer() // XXX session won't be updated if the flow doesn't have any screens
        delegate?.coordinatorDidBecomeReady(self)
    }

    private func handleRequest(_ request: FlowBridgeRequest) {
        guard ensureState(.started, .ready) else { return } // we get here in started state if the flow has no screens
        switch request {
        case let .oauthNative(clientId, stateId, nonce, implicit):
            handleOAuthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case let .webAuth(variant, startURL, finishURL):
            handleWebAuth(variant: variant, startURL: startURL, finishURL: finishURL)
        }
    }

    private func handleError(_ error: DescopeError) {
        guard ensureState(.started, .ready, .failed) else { return }

        // we allow multiple failure events and swallow them here instead of showing a warning above,
        // so that the bridge can just delegate any failures to the coordinator without having to
        // keep its own state to ensure it only reports a single failure
        guard state != .failed  else { return }

        logger.error("Flow failed with \(error.code) error", error)

        state = .failed
        stopSessionTimer()
        delegate?.coordinatorDidFail(self, error: error)
    }

    private func handleSuccess(_ authResponse: AuthenticationResponse) {
        guard ensureState(.started, .ready) else { return } // we get here in started state if the flow has no screens

        logger.info("Flow finished successfully")
        if logger.isUnsafeEnabled, let data = try? JSONEncoder().encode(authResponse), let value = String(bytes: data, encoding: .utf8) {
            logger.debug("Received flow response", value)
        }

        state = .finished
        stopSessionTimer()
        delegate?.coordinatorDidFinish(self, response: authResponse)
    }

    // Authentication

    private func handleAuthentication(_ data: Data) {
        logger.info("Finishing flow authentication")
        Task {
            guard let authResponse = await parseAuthentication(data) else { return }
            handleSuccess(authResponse)
        }
    }

    private func parseAuthentication(_ data: Data) async -> AuthenticationResponse? {
        do {
            guard let webView else { return nil }
            let cookies = await webView.configuration.websiteDataStore.httpCookieStore.cookies(for: webView.url)
            var jwtResponse = try JSONDecoder().decode(DescopeClient.JWTResponse.self, from: data)
            try jwtResponse.setValues(from: data, cookies: cookies, refreshCookieName: bridge.attributes.refreshCookieName)
            return try jwtResponse.convert()
        } catch {
            logger.error("Unexpected error parsing authentication response", error, String(bytes: data, encoding: .utf8))
            handleError(DescopeError.flowFailed.with(message: "No valid authentication response found"))
            return nil
        }
    }

    // OAuth Native

    private func handleOAuthNative(clientId: String, stateId: String, nonce: String, implicit: Bool) {
        logger.info("Requesting authentication using Sign in with Apple", clientId)
        Task {
            await performOAuthNative(stateId: stateId, nonce: nonce, implicit: implicit)
        }
    }

    private func performOAuthNative(stateId: String, nonce: String, implicit: Bool) async {
        do {
            let (authorizationCode, identityToken, user) = try await OAuth.performNativeAuthentication(nonce: nonce, implicit: implicit, logger: logger)
            sendResponse(.oauthNative(stateId: stateId, authorizationCode: authorizationCode, identityToken: identityToken, user: user))
        } catch .oauthNativeCancelled {
            sendResponse(.failure("OAuthNativeCancelled"))
        } catch {
            sendResponse(.failure("OAuthNativeFailed"))
        }
    }

    // OAuth / SSO

    private func handleWebAuth(variant: String, startURL: URL, finishURL: URL?) {
        logger.info("Requesting web authentication", startURL)
        Task {
            await performWebAuth(variant: variant, startURL: startURL, finishURL: finishURL)
        }
    }

    private func performWebAuth(variant: String, startURL: URL, finishURL: URL?) async {
        do {
            let exchangeCode = try await WebAuth.performAuthentication(url: startURL, accessSharedUserData: true, logger: logger)
            sendResponse(.webAuth(variant: variant, exchangeCode: exchangeCode))
        } catch .webAuthCancelled {
            sendResponse(.failure("WebAuthCancelled"))
        } catch {
            sendResponse(.failure("WebAuthFailed"))
        }
    }
}

extension DescopeFlowCoordinator: FlowBridgeDelegate {
    func bridgeDidStartLoading(_ bridge: FlowBridge) {
        handleLoading()
    }

    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError) {
        handleError(error)
    }

    func bridgeDidFinishLoading(_ bridge: FlowBridge) {
        handleLoaded()
    }

    func bridgeDidBecomeReady(_ bridge: FlowBridge) {
        handleReady()
    }

    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, url: URL, external: Bool) {
        delegate?.coordinatorDidInterceptNavigation(self, url: url, external: external)
    }

    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest) {
        handleRequest(request)
    }

    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError) {
        handleError(error)
    }

    func bridgeDidFinish(_ bridge: FlowBridge, data: Data?) {
        if let data {
            handleAuthentication(data)
        } else if let session = flow?.providedSession {
            handleSuccess(AuthenticationResponse(sessionToken: session.sessionToken, refreshToken: session.refreshToken, user: session.user, isFirstAuthentication: false))
        } else {
            logger.error("Couldn't find session to finish flow", flow?.sessionProvider == nil ? "nil provider" : "custom provider")
            handleError(DescopeError.flowFailed.with(message: "No valid authentication tokens found"))
        }
    }
}

private extension WKHTTPCookieStore {
    func cookies(for url: URL?) async -> [HTTPCookie] {
        return await allCookies().filter { cookie in
            guard let domain = url?.host else { return true }
            if cookie.domain.hasPrefix(".") {
                return domain.hasSuffix(cookie.domain) || domain == cookie.domain.dropFirst()
            }
            return domain == cookie.domain
        }
    }
}

@MainActor
private class WebViewLayoutObserver: NSObject {
    @objc let webView: WKWebView
    var observation: NSKeyValueObservation?

    init(webView: WKWebView, handler: @escaping @MainActor () -> Void) {
        self.webView = webView
        super.init()

        observation = observe(\.webView.frame, changeHandler: { observer, change in
            Task { @MainActor in
                handler()
            }
        })
    }
}
