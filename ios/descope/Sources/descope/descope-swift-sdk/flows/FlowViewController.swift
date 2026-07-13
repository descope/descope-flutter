
#if os(iOS)

import WebKit

/// A set of delegate methods for events about the flow running in a ``DescopeFlowViewController``.
@MainActor
public protocol DescopeFlowViewControllerDelegate: AnyObject {
    /// Called directly after the flow state is updated.
    ///
    /// Where appropriate, this delegate method is always called before other delegate methods.
    /// For example, if there's an error in the flow this method is called first to report the
    /// state change to ``DescopeFlowState/failed`` and then the failure delegate method is
    /// called with the specific ``DescopeError`` value.
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState)

    /// Called when the flow is fully loaded and rendered and the view can be displayed.
    ///
    /// You can use this method to show a loading state until the flow is fully loaded,
    /// and do a quick animatad transition to show the flow once this method is called.
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController)

    /// Called when the user taps on a web link in the flow.
    ///
    /// The `external` parameter is `true` if the link would open in a new browser tab
    /// if the flow was runnning in a regular browser app.
    ///
    /// Return `true` for the default behavior of opening any links in the users's default
    /// browser app, or return `false` and do whatever handling you prefer with the link.
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool

    /// Called when the flow is cancelled.
    ///
    /// The flow is cancelled either by the user tapping the Cancel button in the navigation bar,
    /// if the ``DescopeFlowViewController/cancel()`` method is called programmatically, or if
    /// the flow fails with a ``DescopeError/flowCancelled`` error.
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController)

    /// Called when an error occurs in the flow.
    ///
    /// The most common failures are due to internet issues, in which case the `error` will
    /// usually be ``DescopeError/networkError``.
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError)

    /// Called when the flow completes the authentication successfully.
    ///
    /// The `response` parameter can be used to create a ``DescopeSession`` as with other
    /// authentication methods.
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse)
}

/// A utility class for presenting a Descope Flow.
///
/// You can use an instance of ``DescopeFlowViewController`` as a standalone view controller or
/// in a navigation controller stack. In the latter case, if the flow view controller is at the
/// top of the stack, it shows a `Cancel` button where the back arrow usually is.
///
/// ```swift
/// fun showLoginScreen() {
///     let flow = DescopeFlow(url: "https://example.com/myflow")
///
///     let flowViewController = DescopeFlowViewController()
///     flowViewController.delegate = self
///     flowViewController.start(flow: flow)
///
///     navigationController?.pushViewController(flowViewController, animated: true)
/// }
///
/// func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
///     let session = DescopeSession(from: response)
///     Descope.sessionManager.manageSession(session)
///     showMainScreen()
/// }
/// ```
///
/// You can also use the source code for this class as an example of how to incorporate
/// a ``DescopeFlowView`` into your own view controller.
open class DescopeFlowViewController: UIViewController {

    /// A delegate object for receiving events about the state of the flow.
    public weak var delegate: DescopeFlowViewControllerDelegate?

    /// Returns the flow that's currently running in the ``DescopeFlowViewController``.
    public var flow: DescopeFlow? {
        return flowView.flow
    }

    /// Returns the current state of the flow in the ``DescopeFlowViewController``.
    public var state: DescopeFlowState {
        return flowView.state
    }

    /// The underlying ``DescopeFlowView`` used by this controller.
    public var flowView: DescopeFlowView {
        return underlyingView
    }

    // UIViewController

    /// Called after the controller's view is loaded into memory.
    ///
    /// You can override this method to perform additional initialization in
    /// your controller subclass. You must call through to `super.viewDidLoad`
    /// in your implementation.
    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .secondarySystemBackground

        activityView.color = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)

        flowView.frame = view.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(flowView)
    }

    /// Called just before the view controller is added or removed from a container
    /// view controller.
    ///
    /// You must call through to `super.willMove(toParent: parent)` in your implementation.
    open override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if navigationController?.viewControllers.first == self {
            navigationItem.leftBarButtonItem = cancelBarButton
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    // Flow

    /// Override this method if you want your controller to use your own subclass
    /// of ``DescopeFlowView`` as its underlying view.
    open func createFlowView() -> DescopeFlowView {
        return DescopeFlowView(frame: isViewLoaded ? view.bounds : UIScreen.main.bounds)
    }

    /// Loads and displays a Descope Flow.
    ///
    /// The ``delegate`` property should be set before calling this function to ensure
    /// no delegate updates are missed.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flowViewController.start(flow: flow)
    /// ```
    ///
    /// You can call this method while the view is hidden to prepare the flow ahead of time,
    /// watching for updates via the delegate, and showing the view when it's ready.
    public func start(flow: DescopeFlow) {
        flowView.delegate = self
        flowView.start(flow: flow)
    }

    /// Cancels the view controller.
    ///
    /// This function is called when the user taps on the Cancel button in the navigation bar
    /// and it notifies the delegate about the cancellation. Apps or subclasses can call this
    /// method to preserve the same behavior even if they use a different interaction for
    /// letting users cancel the flow.`
    public func cancel() {
        flowView.delegate = nil
        delegate?.flowViewControllerDidCancel(self)
    }

    // Internal

    private lazy var underlyingView = createFlowView()

    private lazy var activityView = UIActivityIndicatorView()

    private lazy var cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))

    @objc private func handleCancel() {
        cancel()
    }
}

extension DescopeFlowViewController: DescopeFlowViewDelegate {
    public func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        if state == .started {
            activityView.startAnimating()
        } else {
            activityView.stopAnimating()
        }
        delegate?.flowViewControllerDidUpdateState(self, to: state, from: previous)
    }
    
    public func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        delegate?.flowViewControllerDidBecomeReady(self)
    }

    public func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
        let open = delegate?.flowViewControllerShouldShowURL(self, url: url, external: external) ?? true
        if open {
            UIApplication.shared.open(url)
        }
    }

    public func flowViewDidFail(_ flowView: DescopeFlowView, error: DescopeError) {
        if error == .flowCancelled {
            delegate?.flowViewControllerDidCancel(self)
        } else {
            delegate?.flowViewControllerDidFail(self, error: error)
        }
    }
    
    public func flowViewDidFinish(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
        delegate?.flowViewControllerDidFinish(self, response: response)
    }
}

#endif
