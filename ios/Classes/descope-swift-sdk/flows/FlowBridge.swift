
import WebKit

@MainActor
protocol FlowBridgeDelegate: AnyObject {
    func bridgeDidStartLoading(_ bridge: FlowBridge)
    func bridgeDidFailLoading(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinishLoading(_ bridge: FlowBridge)
    func bridgeDidBecomeReady(_ bridge: FlowBridge)
    func bridgeDidInterceptNavigation(_ bridge: FlowBridge, url: URL, external: Bool)
    func bridgeDidReceiveRequest(_ bridge: FlowBridge, request: FlowBridgeRequest)
    func bridgeDidFailAuthentication(_ bridge: FlowBridge, error: DescopeError)
    func bridgeDidFinish(_ bridge: FlowBridge, data: Data?)
}

enum FlowBridgeRequest {
    case oauthNative(clientId: String, stateId: String, nonce: String, implicit: Bool)
    case webAuth(variant: String, startURL: URL, finishURL: URL?)
}

enum FlowBridgeResponse {
    case oauthNative(stateId: String, authorizationCode: String?, identityToken: String?, user: String?)
    case webAuth(variant: String, exchangeCode: String)
    case magicLink(url: String)
    case failure(String)
}

struct FlowBridgeAttributes: Decodable {
    var refreshCookieName: String?
}

@MainActor
class FlowBridge: NSObject {
    /// The coordinator sets the flow automatically.
    var flow: DescopeFlow?

    /// The coordinator sets a logger automatically.
    var logger: DescopeLogger?

    /// Attributes that are set on the web component that are needed by the coordinator.
    var attributes = FlowBridgeAttributes()

    /// The coordinator sets itself as the bridge delegate.
    weak var delegate: FlowBridgeDelegate?

    /// This property is weak since the bridge is not considered the "owner" of the webview, and in
    /// addition, it helps prevent retain cycles as the webview itself retains the bridge when the
    /// latter is added as a scriptMessageHandler to the webview configuration.
    weak var webView: WKWebView? {
        willSet {
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
        }
        didSet {
            webView?.navigationDelegate = self
            webView?.uiDelegate = self
        }
    }

    // Lifecycle

    /// A proxy object to handle WKWebView messages without causing a retain cycle.
    private lazy var messageHandler = FlowBridgeMessageHandler(bridge: self)

    /// Injects the JavaScript code below that's required for the bridge to work, as well as
    /// handlers for messages sent from the webpage to the bridge.
    func prepare(configuration: WKWebViewConfiguration) {
        let logging = WKUserScript(source: loggingScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(logging)

        let setup = WKUserScript(source: setupScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(setup)

        let start = WKUserScript(source: startScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(start)

        if #available(iOS 17.0, macOS 14.0, *) {
            configuration.preferences.inactiveSchedulingPolicy = .none
        }

        for name in FlowBridgeMessage.allCases {
            configuration.userContentController.add(messageHandler, name: name.rawValue)
        }
    }
    
    /// Called by the coordinator to start loading the flow in the webview
    func start() {
        retries.until = Date().addingTimeInterval(retryWindow)
        load()
    }
    
    private func load() {
        let url = URL(string: flow?.url ?? "") ?? URL(string: "invalid://")!
        var request = URLRequest(url: url)
        if let timeout = flow?.requestTimeoutInterval {
            request.timeoutInterval = timeout
        }
        webView?.load(request)
    }
    
    // Retry
    
    private let retryWindow: TimeInterval = 10
    private let retryBackoff: TimeInterval = 1.25
    
    private var retries: (scheduled: Bool, attempts: Int, until: Date) = (false, 0, .distantFuture)
    
    private func scheduleRetryAfterError(_ error: DescopeError) {
        // defend against multiple errors from the same attempt
        guard !retries.scheduled else { return }
        
        // we only allow a retry if the scheduled time will still fit in the retry window
        retries.attempts += 1
        let delay = retryBackoff * TimeInterval(retries.attempts)
        guard retries.until > Date() + delay else {
            logger.info("Aborting flow loading after retry timeout")
            delegate?.bridgeDidFailLoading(self, error: error)
            return
        }
        
        logger.info("Scheduling flow loading attempt", retries.attempts)
        retries.scheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.retryLoad()
        }
    }
    
    private func retryLoad() {
        logger.info("Retrying flow loading")
        retries.scheduled = false
        load()
    }
}

extension FlowBridge {
    /// Called by the bridge after the found event
    func initialize() {
        guard let flow else { return }
        
        var nativeOptions = FlowNativeOptions()
        nativeOptions.oauthProvider = flow.oauthNativeProvider?.name ?? ""
        nativeOptions.magicLinkRedirect = flow.magicLinkRedirect ?? ""

        var refreshJwt = ""
        if let session = flow.providedSession {
            logger.info("Passing refreshJwt to flow initialization", session.refreshJwt)
            refreshJwt = session.refreshJwt
        }
        
        var clientInputs = ""
        if !flow.clientInputs.isEmpty {
            if !JSONSerialization.isValidJSONObject(flow.clientInputs) {
                logger.error("Invalid flow client parameters provided")
            } else if let data = try? JSONSerialization.data(withJSONObject: flow.clientInputs, options: []), let json = String(bytes: data, encoding: .utf8) {
                logger.info("Passing clientInputs to flow initialization", json)
                clientInputs = json
            }
        }
        
        call(function: "initialize", params: nativeOptions.payload, refreshJwt, clientInputs)
    }

    /// Called by the coordinator when it needs to update the refresh token in the page.
    func updateRefreshJwt(_ refreshJwt: String) {
        call(function: "updateRefreshJwt", params: refreshJwt)
    }

    /// Called by the coordinator when it's done handling a bridge request
    func postResponse(_ response: FlowBridgeResponse) {
        call(function: "handleResponse", params: response.type, response.payload)
    }

    /// Helper method to run one of the internal bridge functions with escaped string parameters
    private func call(function: String, params: String...) {
        let escaped = params.map { $0.javaScriptLiteralString() }.joined(separator: ", ")
        let javascript = "window.descopeBridge.internal.\(function)(\(escaped))"
        webView?.evaluateJavaScript(javascript)
    }
}

extension FlowBridge {
    func handleScriptMessage(_ message: WKScriptMessage) {
        switch FlowBridgeMessage(rawValue: message.name) {
        case .log:
            guard let json = message.body as? [String: Any], let tag = json["tag"] as? String, let message = json["message"] as? String else { return }
            if tag == "fail" {
                logger.error("Bridge encountered script error in webpage", message)
            } else if logger.isUnsafeEnabled {
                logger.debug("Webview console.\(tag): \(message)")
            }
        case .found:
            logger.info("Bridge received found event")
            guard let json = message.body as? [String: Any] else { return }
            attributes.refreshCookieName = json["refreshCookieName"] as? String
            initialize()
        case .ready:
            logger.info("Bridge received ready event", message.body)
            delegate?.bridgeDidBecomeReady(self)
        case .bridge:
            logger.info("Bridge received native event")
            guard let json = message.body as? [String: Any], let request = FlowBridgeRequest(json: json) else {
                logger.error("Invalid JSON data in flow native event", message.body)
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Invalid JSON data in flow native event"))
                return
            }
            delegate?.bridgeDidReceiveRequest(self, request: request)
        case .abort:
            if let reason = message.body as? String, !reason.isEmpty {
                logger.error("Bridge received abort event with failure reason")
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: reason))
            } else {
                logger.info("Bridge received abort event for cancellation")
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowCancelled)
            }
        case .failure:
            logger.error("Bridge received failure event", message.body)
            if let dict = message.body as? [String: Any], let error = DescopeError(errorResponse: dict) {
                delegate?.bridgeDidFailAuthentication(self, error: error)
            } else if let reason = message.body as? String, !reason.isEmpty {
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: reason))
            } else {
                delegate?.bridgeDidFailAuthentication(self, error: DescopeError.flowFailed.with(message: "Unexpected authentication failure"))
            }
        case .success:
            if let json = message.body as? String, case let data = Data(json.utf8), !data.isEmpty {
                logger.info("Bridge received success event")
                delegate?.bridgeDidFinish(self, data: data)
            } else {
                logger.info("Bridge received success event without authentication data")
                delegate?.bridgeDidFinish(self, data: nil)
            }
        case nil:
            logger.error("Bridge received unexpected message", message.name)
        }
    }
}

extension FlowBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        switch navigationAction.navigationType {
        case .linkActivated:
            logger.info("Webview intercepted link", navigationAction.request.url?.absoluteString)
            if let url = navigationAction.request.url {
                delegate?.bridgeDidInterceptNavigation(self, url: url, external: false)
            }
            return .cancel
        default:
            logger.info("Webview will load url", navigationAction.navigationType == .other ? nil : "type=\(navigationAction.navigationType.rawValue)", navigationAction.request.url?.absoluteString)
            return .allow
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        logger.info("Webview started loading webpage")
        delegate?.bridgeDidStartLoading(self)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        logger.info("Webview received server redirect", webView.url)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        if let response = navigationResponse.response as? HTTPURLResponse, let error = HTTPError(statusCode: response.statusCode) {
            logger.error("Webview failed loading page", error)
            let networkError = DescopeError.networkError.with(message: error.description)
            if response.statusCode >= 500 {
                scheduleRetryAfterError(networkError)
            } else {
                delegate?.bridgeDidFailLoading(self, error: networkError)
            }
            return .cancel
        }
        logger.info("Webview will receive response")
        return .allow
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        // Don't print an error log if this was triggered by a non-2xx status code that was caught
        // above and causing the delegate function to return `.cancel`. We rely on the coordinator
        // to not notify about errors multiple times.
        if case let error = error as NSError, error.domain == "WebKitErrorDomain", error.code == 102 { // https://chromium.googlesource.com/chromium/src/+/2233628f5f5b32c7b458428f8d5cfbd0a18be82e/ios/web/public/web_kit_constants.h#25
            logger.debug("Webview loading has already been cancelled")
        } else {
            logger.error("Webview failed loading url", error)
        }
        scheduleRetryAfterError(DescopeError.networkError.with(cause: error))
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        logger.info("Webview received response")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        logger.info("Webview finished loading webpage")
        delegate?.bridgeDidFinishLoading(self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        logger.error("Webview failed loading webpage", error)
        scheduleRetryAfterError(DescopeError.networkError.with(cause: error))
    }
}

extension FlowBridge: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        logger.info("Webview intercepted external link", navigationAction.request.url?.absoluteString)
        if let url = navigationAction.request.url {
            delegate?.bridgeDidInterceptNavigation(self, url: url, external: true)
        }
        return nil
    }
}

extension FlowBridge {
    func addStyles(_ css: String) {
        runJavaScript("""
            const styles = \(css.javaScriptLiteralString())
            const element = document.createElement('style')
            element.textContent = styles
            document.head.appendChild(element)
        """)
    }

    func runJavaScript(_ code: String) {
        let javascript = anonymousFunction(body: code)
        webView?.evaluateJavaScript(javascript)
    }

    private func anonymousFunction(body: String) -> String {
        return """
            (function() {
                \(body)
            })()
        """
    }
}

private enum FlowBridgeMessage: String, CaseIterable {
    case log, found, ready, bridge, abort, failure, success
}

private extension FlowBridgeRequest {
    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any] else { return nil }
        let type = json["type"] as? String ?? ""
        switch type {
        case "oauthNative":
            guard let start = payload["start"] as? [String: Any] else { return nil }
            guard let clientId = start["clientId"] as? String, let stateId = start["stateId"] as? String, let nonce = start["nonce"] as? String, let implicit = start["implicit"] as? Bool else { return nil }
            self = .oauthNative(clientId: clientId, stateId: stateId, nonce: nonce, implicit: implicit)
        case "oauthWeb", "sso":
            guard let startString = payload["startUrl"] as? String, let startURL = URL(string: startString) else { return nil }
            var finishURL: URL?
            if let str = payload["finishUrl"] as? String, !str.isEmpty, let url = URL(string: str) {
                finishURL = url
            }
            self = .webAuth(variant: type, startURL: startURL, finishURL: finishURL)
        default:
            return nil
        }
    }
}

private extension FlowBridgeResponse {
    var type: String {
        switch self {
        case .oauthNative: return "oauthNative"
        case .webAuth(let variant, _): return variant
        case .magicLink: return "magicLink"
        case .failure: return "failure"
        }
    }

    var payload: String {
        guard let json = try? JSONSerialization.data(withJSONObject: payloadDictionary), let str = String(bytes: json, encoding: .utf8) else { return "{}" }
        return str
    }

    private var payloadDictionary: [String: Any] {
        switch self {
        case let .oauthNative(stateId, authorizationCode, identityToken, user):
            var nativeOAuth: [String: Any] = [:]
            nativeOAuth["stateId"] = stateId
            if let authorizationCode {
                nativeOAuth["code"] = authorizationCode
            }
            if let identityToken {
                nativeOAuth["idToken"] = identityToken
            }
            if let user {
                nativeOAuth["user"] = user
            }
            return [
                "nativeOAuth": nativeOAuth,
            ]
        case let .webAuth(_, exchangeCode):
            return [
                "exchangeCode": exchangeCode,
            ]
        case let .magicLink(url):
            return [
                "url": url
            ]
        case let .failure(failure):
            return [
                "failure": failure
            ]
        }
    }
}

private class FlowBridgeMessageHandler: NSObject, WKScriptMessageHandler {
    weak var bridge: FlowBridge?

    init(bridge: FlowBridge) {
        self.bridge = bridge
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        bridge?.handleScriptMessage(message)
    }
}

private struct FlowNativeOptions: Encodable {
    var platform = "ios"
    var bridgeVersion = 1
    var oauthProvider = ""
    var oauthRedirect = WebAuth.redirectURL
    var ssoRedirect = WebAuth.redirectURL
    var magicLinkRedirect = ""

    var payload: String {
        guard let data = try? JSONEncoder().encode(self), let value = String(bytes: data, encoding: .utf8) else { return "{}" }
        return value
    }
}

/// Redirects errors and console logs to the bridge
private let loggingScript = """

window.onerror = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'fail', message: s }) }
window.console.error = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'error', message: s }) }
window.console.warn = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'warn', message: s }) }
window.console.info = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'info', message: s }) }
window.console.debug = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'debug', message: s }) }
window.console.log = (s) => { window.webkit.messageHandlers.\(FlowBridgeMessage.log.rawValue).postMessage({ tag: 'log', message: s }) }

"""

/// Sets up the descopeBridge object in the webpage
private let setupScript = """

window.descopeBridge = {
    hostInfo: {
        sdkName: 'swift',
        sdkVersion: \(DescopeSDK.version.javaScriptLiteralString()),
        platformName: \(SystemInfo.osName.javaScriptLiteralString()),
        platformVersion: \(SystemInfo.osVersion.javaScriptLiteralString()),
        appName: \(SystemInfo.appName?.javaScriptLiteralString() ?? "''"),
        appVersion: \(SystemInfo.appVersion?.javaScriptLiteralString() ?? "''"), 
        device: \(SystemInfo.device?.javaScriptLiteralString() ?? "''"),
        webauthn: true,
    },

    abortFlow(reason) {
        this.internal.aborted = true
        window.webkit.messageHandlers.\(FlowBridgeMessage.abort.rawValue).postMessage(typeof reason == 'string' ? reason : '')
    },

    startFlow() {
        this.internal.start()
    },

    internal: {
        component: null,

        aborted: false,

        start() {
            if (this.aborted || this.connect()) {
                return
            }

            console.debug('Waiting for Descope component')

            let interval
            interval = setInterval(() => {
                if (this.aborted || this.connect()) {
                    clearInterval(interval)
                }
            }, 20)
        },

        connect() {
            this.component ||= document.querySelector('descope-wc')
            if (!this.component) {
                return false
            }

            const attributes = {
                refreshCookieName: this.component.refreshCookieName || null,
            }

            window.webkit.messageHandlers.\(FlowBridgeMessage.found.rawValue).postMessage(attributes)
            return true
        },

        initialize(nativeOptions, refreshJwt, clientInputs) {
            // update webpage sdk headers and print sdk type and version to native log
            this.updateConfigHeaders()

            this.component.nativeOptions = JSON.parse(nativeOptions)
            this.updateRefreshJwt(refreshJwt)
            this.updateClientInputs(clientInputs)
            
            if (this.component.flowStatus === 'error') {
                window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage('The flow failed during initialization')
            } else if (this.component.flowStatus === 'ready' || this.component.shadowRoot?.querySelector('descope-container')) {
                this.postReady('immediate') // can only happen in old web-components without lazy init
            } else {
                this.component.addEventListener('ready', () => {
                    this.postReady('listener')
                })
            }

            this.component.addEventListener('bridge', (event) => {
                window.webkit.messageHandlers.\(FlowBridgeMessage.bridge.rawValue).postMessage(event.detail)
            })

            this.component.addEventListener('error', (event) => {
                window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage(event.detail)
            })

            this.component.addEventListener('success', (event) => {
                const response = (event.detail && Object.keys(event.detail).length) ? JSON.stringify(event.detail) : ''
                window.webkit.messageHandlers.\(FlowBridgeMessage.success.rawValue).postMessage(response)
            })

            // ensure we support old web-components without this function
            this.component.lazyInit?.()

            return true
        },

        postReady(tag) {
            if (!this.component.bridgeVersion) {
                window.webkit.messageHandlers.\(FlowBridgeMessage.failure.rawValue).postMessage('The flow is using an unsupported web component version')
            } else {
                window.webkit.messageHandlers.\(FlowBridgeMessage.ready.rawValue).postMessage(tag)
            }
            this.disableTouchInteractions()
        },

        updateConfigHeaders() {
            const config = window.customElements?.get('descope-wc')?.sdkConfigOverrides || {}

            const headers = config?.baseHeaders || {}
            console.debug(`Descope ${headers['x-descope-sdk-name'] || 'unknown'} package version "${headers['x-descope-sdk-version'] || 'unknown'}"`)

            const hostInfo = window.descopeBridge.hostInfo
            headers['x-descope-bridge-name'] = hostInfo.sdkName
            headers['x-descope-bridge-version'] = hostInfo.sdkVersion
            headers['x-descope-platform-name'] = hostInfo.platformName
            headers['x-descope-platform-version'] = hostInfo.platformVersion
            if (hostInfo.appName) {
                headers['x-descope-app-name'] = hostInfo.appName
            }
            if (hostInfo.appVersion) {
                headers['x-descope-app-version'] = hostInfo.appVersion
            }
            if (hostInfo.device) {
                headers['x-descope-device'] = hostInfo.device
            }
        },

        disableTouchInteractions() {
            this.component.injectStyle?.(`
                #content-root * {
                    -webkit-touch-callout: none;
                    -webkit-user-select: none;
                }
            `)

            this.component.shadowRoot?.querySelectorAll('descope-enriched-text').forEach(t => {
                t.shadowRoot?.querySelectorAll('a').forEach(a => {
                    a.draggable = false
                })
            })

            this.component.shadowRoot?.querySelectorAll('img').forEach(a => {
                a.draggable = false
            })
        },

        updateRefreshJwt(refreshJwt) {
            if (refreshJwt) {
                const storagePrefix = this.component.storagePrefix || ''
                const storageKey = `${storagePrefix}\(DescopeClient.refreshCookieName)`
                window.localStorage.setItem(storageKey, refreshJwt)
            }
        },

        updateClientInputs(inputs) {
            let client = {}
            try {
                client = JSON.parse(this.component.getAttribute('client') || '{}')
            } catch (e) {}
            client = {
                ...client,
                ...JSON.parse(inputs || '{}'),
            }
            this.component.setAttribute('client', JSON.stringify(client))
        },

        handleResponse(type, payload) {
            this.component.nativeResume(type, payload)
        },
    }
}

"""

/// Connects the bridge to the Descope web-component
private let startScript = """

window.descopeBridge.startFlow()

"""
