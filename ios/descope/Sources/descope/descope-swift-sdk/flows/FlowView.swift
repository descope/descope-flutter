
#if os(iOS)

import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowView``.
@MainActor
public protocol DescopeFlowViewDelegate: AnyObject {
    /// Called directly after the flow state is updated.
    ///
    /// Where appropriate, this delegate method is always called before other delegate methods.
    /// For example, if there's an error in the flow this method is called first to report the
    /// state change to ``DescopeFlowState/failed`` and then the failure delegate method is
    /// called with the specific ``DescopeError`` value.
    func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState)

    /// Called when the flow is fully loaded and rendered and the view can be displayed.
    ///
    /// You can use this method to show a loading state until the flow is fully loaded,
    /// and do a quick animatad transition to show the flow once this method is called.
    func flowViewDidBecomeReady(_ flowView: DescopeFlowView)

    /// Called when the user taps on a web link in the flow.
    ///
    /// The `external` parameter is `true` if the link would open in a new browser tab
    /// if the flow was runnning in a regular browser app.
    ///
    /// If your flow doesn't show any web links you can either use an empty implementation
    /// or simply call `UIApplication.shared.open(url)` so that links open in the user's
    /// default browser app.
    func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool)

    /// Called when an error occurs in the flow.
    ///
    /// The most common failures are due to internet issues, in which case the `error` will
    /// usually be ``DescopeError/networkError``.
    func flowViewDidFail(_ flowView: DescopeFlowView, error: DescopeError)

    /// Called when the flow completes the authentication successfully.
    ///
    /// The `response` parameter can be used to create a ``DescopeSession`` as with other
    /// authentication methods.
    func flowViewDidFinish(_ flowView: DescopeFlowView, response: AuthenticationResponse)
}

/// A view for showing authentication screens built using [Descope Flows](https://app.descope.com/flows).
///
/// You can use a flow view as the main view of a modal authentication screen or as part of a
/// more complex view hierarchy. In the former case you might consider using a ``DescopeFlowViewController``
/// instead, as it provides a simpler way to present an authentication flow modally.
///
/// You can create an instance of ``DescopeFlowView``, add it to the view hierarchy, and call
/// ``start(flow:)`` to load the flow.
///
/// ```swift
/// override func viewDidLoad() {
///     super.viewDidLoad()
///
///     let flowView = DescopeFlowView(frame: bounds)
///     flowView.delegate = self
///     flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
///     view.addSubview(flowView)
///
///     let flow = DescopeFlow(url: "https://example.com/myflow")
///     flowView.start(flow: flow)
/// }
/// ```
///
/// The flow view only handles presentation and its `delegate` is expected to handle the
/// events as appropriate.
///
/// ```swift
/// extension MyClass: DescopeFlowViewDelegate {
///     public func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
///         // for example, show a loading indicator when state is .started and hide it otherwise
///     }
///
///     public func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
///         // for example, animate the view in if it's been hidden until now
///     }
///
///     public func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
///         UIApplication.shared.open(url) // open any links in the user's default browser app
///     }
///
///     public func flowViewDidFail(_ flowView: DescopeFlowView, error: DescopeError) {
///         // called when the flow fails, because of a network error or some other reason
///         let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
///         alert.addAction(UIAlertAction(title: "OK", style: .cancel))
///         self.present(alert, animated: true)
///     }
///
///     public func flowViewDidFinish(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
///         let session = DescopeSession(from: response)
///         Descope.sessionManager.manageSession(session)
///         // for example, transition the app to some other screen
///     }
/// }
/// ```
///
/// - Important: There are many possibilities for customization when you consider all
///     the various `UIKit` properties on the view itself and the various CSS rules in
///     the flow webpage being displayed. If you need any additional customization
///     options that are not currently exposed by ``DescopeFlowView`` you can open
///     an issue or pull request [here](https://github.com/descope/descope-swift).
open class DescopeFlowView: UIView {

    /// A delegate object for receiving events about the state of the flow.
    public weak var delegate: DescopeFlowViewDelegate?

    /// Returns the flow that's currently running in the ``DescopeFlowView``.
    public var flow: DescopeFlow? {
        return coordinator.flow
    }

    /// Returns the current state of the flow in the ``DescopeFlowView``.
    public var state: DescopeFlowState {
        return coordinator.state
    }

    // Initialization

    private let coordinator = DescopeFlowCoordinator()

    private lazy var proxy = FlowCoordinatorDelegateProxy(view: self)

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        prepareView()
    }

    private func prepareView() {
        coordinator.delegate = proxy
        coordinator.webView = webView
        addSubview(webView)
    }

    // UIView

    open override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
    }

    // Flow

    /// Loads and displays a Descope Flow.
    ///
    /// The ``delegate`` property should be set before calling this function to ensure
    /// no delegate updates are missed.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flowView.start(flow: flow)
    /// ```
    ///
    /// You can call this method while the view is hidden to prepare the flow ahead of time,
    /// watching for updates via the delegate, and showing the view when it's ready.
    public func start(flow: DescopeFlow) {
        coordinator.start(flow: flow)
    }

    // WebView

    private lazy var webView: WKWebView = createWebView()

    private func createWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        willCreateWebView(configuration)
        coordinator.prepare(configuration: configuration)

        let webView = Self.webViewClass.init(frame: bounds, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.keyboardDismissMode = .interactiveWithAccessory
        didCreateWebView(webView)

        return webView
    }

    // Override points

    /// Override this getter if you want your ``DescopeFlowView`` to use a specific
    /// type of `WKWebView` for its webview instance.
    open class var webViewClass: WKWebView.Type {
        return DescopeCustomWebView.self
    }

    /// Override this method if you need to customize the webview's configuration
    /// before it's created.
    ///
    /// The default implementation of this method does nothing.
    open func willCreateWebView(_ configuration: WKWebViewConfiguration) {
    }

    /// Override this method if you need to customize the webview itself after it's created.
    ///
    /// The default implementation of this method does nothing.
    open func didCreateWebView(_ webView: WKWebView) {
    }

    /// Override this method if your subclass needs to do something when the flow state is updated.
    ///
    /// The default implementation of this method does nothing.
    open func didUpdateState(to state: DescopeFlowState, from previous: DescopeFlowState) {
    }

    /// Override this method if your subclass needs to do something when the flow is
    /// fully loaded and rendered and the view can be displayed.
    ///
    /// The default implementation of this method does nothing.
    open func didBecomeReady() {
    }

    /// Override this method if your subclass needs to do something when the user taps
    /// on a web link in the flow.
    ///
    /// The default implementation of this method does nothing.
    open func didInterceptNavigation(url: URL, external: Bool) {
    }

    /// Override this method if your subclass needs to do something when an error occurs
    /// in the flow.
    ///
    /// The default implementation of this method does nothing.
    open func didFail(error: DescopeError) {
    }

    /// Override this method if your subclass needs to do something when the flow completes
    /// the authentication successfully.
    ///
    /// The default implementation of this method does nothing.
    open func didFinish(response: AuthenticationResponse) {
    }
}

/// A helper class to not expose the coordinator delegate conformance.
private class FlowCoordinatorDelegateProxy: DescopeFlowCoordinatorDelegate {
    private weak var view: DescopeFlowView?

    init(view: DescopeFlowView) {
        self.view = view
    }

    func coordinatorDidUpdateState(_ coordinator: DescopeFlowCoordinator, to state: DescopeFlowState, from previous: DescopeFlowState) {
        guard let view else { return }
        view.didUpdateState(to: state, from: previous)
        view.delegate?.flowViewDidUpdateState(view, to: state, from: previous)
    }

    func coordinatorDidBecomeReady(_ coordinator: DescopeFlowCoordinator) {
        guard let view else { return }
        view.didBecomeReady()
        view.delegate?.flowViewDidBecomeReady(view)
    }

    func coordinatorDidInterceptNavigation(_ coordinator: DescopeFlowCoordinator, url: URL, external: Bool) {
        guard let view else { return }
        view.didInterceptNavigation(url: url, external: external)
        view.delegate?.flowViewDidInterceptNavigation(view, url: url, external: external)
    }

    func coordinatorDidFail(_ coordinator: DescopeFlowCoordinator, error: DescopeError) {
        guard let view else { return }
        view.didFail(error: error)
        view.delegate?.flowViewDidFail(view, error: error)
    }

    func coordinatorDidFinish(_ coordinator: DescopeFlowCoordinator, response: AuthenticationResponse) {
        guard let view else { return }
        view.didFinish(response: response)
        view.delegate?.flowViewDidFinish(view, response: response)
    }
}

/// A custom WKWebView subclass to hide the form navigation bar.
class DescopeCustomWebView: WKWebView {
    var showsInputAccessoryView: Bool = false

    override var inputAccessoryView: UIView? {
        return showsInputAccessoryView ? super.inputAccessoryView : nil
    }
}

#endif
