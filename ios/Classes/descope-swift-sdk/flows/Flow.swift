
import Foundation

/// The state of the flow or presenting object.
public enum DescopeFlowState: String {
    /// The flow hasn't been started yet.
    case initial

    /// The flow is being loaded but is not ready yet.
    case started

    /// The flow finished loading and can be shown.
    case ready

    /// The flow failed to load or there was some other error.
    case failed

    /// The flow completed the authentication successfully.
    case finished
}

/// A helper object that encapsulates a single flow run for authenticating a user.
///
/// You can use Descope Flows as a visual no-code interface to build screens and
/// authentication flows for common user interactions with your application.
///
/// Flows are hosted on a webpage and are run by creating an instance of
/// ``DescopeFlowViewController``, ``DescopeFlowView``, or ``DescopeFlowCoordinator``
/// and calling `start(flow:)`.
///
/// For example, this code shows a flow in a navigation controller stack using a
/// flow view controller:
///
/// ```swift
/// // create a flow object with the URL where the flow is hosted
/// let flow = DescopeFlow(url: "https://example.com/myflow")
///
/// // use a hook to customize the flow presentation, in this case overriding
/// // the background to be transparent
/// flow.hooks = [ .setTransparentBody ]
///
/// // set the optional oauthProvider property so that OAuth authentications are
/// // upgraded to use native "Sign in with Apple" instead of a web-based login:
/// flow.oauthNativeProvider = .apple
///
/// // create a DescopeFlowViewController to run the flow
/// let flowViewController = DescopeFlowViewController()
/// flowViewController.delegate = self
/// flowViewController.start(flow: flow)
///
/// // push the DescopeFlowViewController onto the navigation controller to show it
/// navigationController.pushViewController(flowViewController, animated: true)
/// ```
///
/// There are some preliminary setup steps you might need to do:
///
/// - As a prerequisite, the flow itself must be created and hosted somewhere on
///     the web. You can either host it on your own web server or use Descope's
///     auth hosting. Read more [here](https://docs.descope.com/auth-hosting-app).
///
/// - You should configure any required Descope authentication methods in the
///     [Descope console](https://app.descope.com/settings/authentication) before
///     making use of them in a Descope Flow. Some of the default configurations
///     might work well enough to start with, but it is likely that some changes
///     will be needed before release.
///
/// - For flows that use `Magic Link` authentication you will need to set up
///     [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
///     in your app. See the documentation for ``Descope for more details.
///
/// - You can leverage the native `Sign in with Apple` automatically for flows that use `OAuth`
///     by setting the ``oauthProvider`` property and configuring native OAuth in your app. See the
///     documentation for ``DescopeOAuth/native(provider:options:)`` for more details.
///
/// - SeeAlso: You can read more about Descope Flows on the [docs website](https://docs.descope.com/flows).
@MainActor
public class DescopeFlow {
    /// The URL where the flow is hosted.
    public let url: String

    /// An optional instance of ``DescopeSDK`` to use for running the flow.
    ///
    /// If you're not using the shared ``Descope`` singleton and passing around an instance of
    /// the ``DescopeSDK`` class instead you must set this property before starting the flow.
    public var descope: DescopeSDK?

    /// A list of hooks that customize how the flow webpage looks or behaves.
    ///
    /// You can use the built-in hooks or create custom ones. See the documentation
    /// for ``DescopeFlowHook`` for more details.
    public var hooks: [DescopeFlowHook] = []

    /// The id of the OAuth provider that should leverage the native "Sign in with Apple"
    /// dialog instead of opening a web browser modal.
    ///
    /// This will usually either be `.apple` or the name of a custom OAuth provider you've
    /// created in the [Descope Console](https://app.descope.com/settings/authentication/social)
    /// that's been configured for Apple.
    public var oauthNativeProvider: OAuthProvider?

    /// An optional universal link URL to use when sending magic link emails.
    ///
    /// You only need to set this if you explicitly want to override whichever URL is
    /// configured in the flow or in the Descope project, perhaps because the app cannot
    /// be configured for universal links using the same redirect URL as on the web.
    public var magicLinkRedirect: String?

    /// An optional timeout interval to set on the `URLRequest` object used for loading
    /// the flow webpage. If this is not set the platform default value is be used.
    public var requestTimeoutInterval: TimeInterval?
    
    /// An optional map of client inputs that will be provided to the flow.
    ///
    /// These values can be used in the flow editor to customize the flow's behavior
    /// during execution. The values set on the map must be valid JSON types.
    public var clientInputs: [String: Any] = [:]
    
    /// An object that provides the ``DescopeSession`` value for the currently authenticated
    /// user if there is one, or `nil` otherwise.
    ///
    /// This is used when running a flow that expects the user to already be signed in.
    /// For example, a flow to update a user's email or account recovery details, or that
    /// does step-up authentication.
    ///
    /// The default behavior is to check whether the ``DescopeSessionManager`` is currently
    /// managing a valid session, and return it if that's the case.
    ///
    /// - Note: The default behavior checks the ``DescopeSessionManager`` from the ``Descope``
    ///     singleton, or the one from the flow's ``descope`` property if it is set.
    ///
    /// If you're not using the ``DescopeSessionManager`` but rather managing the tokens
    /// manually, and if you also need to start a flow for an authenticated user, then you
    /// should set your own ``sessionProvider``. For example:
    ///
    /// ```swift
    /// // create a flow object with the URL where the flow is hosted
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    ///
    /// // fetch the latest session from our model layer when needed
    /// flow.sessionProvider = { [weak self] in
    ///     return self?.modelLayer.fetchDescopeSession()
    /// }
    /// ```
    ///
    /// - Important: The provider may be called multiple times to ensure that the flow uses
    ///     the newest tokens, even if the session is refreshed while the flow is running.
    ///     This is especially important for projects that use refresh token rotation.
    public var sessionProvider: (() -> DescopeSession?)?

    /// Creates a new ``DescopeFlow`` object that encapsulates a single flow run.
    ///
    /// - Parameter url: The URL where the flow is hosted.
    public init(url: String) {
        self.url = url
    }

    /// Creates a new ``DescopeFlow`` object that encapsulates a single flow run.
    ///
    /// - Parameter url: The URL where the flow is hosted.
    public init(url: URL) {
        self.url = url.absoluteString
    }
}

extension DescopeFlow: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeFlow`` object.
    ///
    /// It returns a string with the initial URL of the flow.
    public nonisolated var description: String {
        return "DescopeFlow(url: \"\(url)\")"
    }
}
