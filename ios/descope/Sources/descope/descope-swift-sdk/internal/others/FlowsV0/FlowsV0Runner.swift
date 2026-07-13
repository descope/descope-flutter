
import AuthenticationServices

/// A deprecated object that encapsulates a single flow run. Use a `DescopeFlowViewController`
/// to show a `DescopeFlow` instead.
///
/// Create a runner by providing the URL for a webpage where the flow is hosted. You
/// can start the flow by calling `start(runner:)`. When the authentication
/// completes successfully it returns a ``AuthenticationResponse`` value as in all other
/// authentication methods.
///
///     class LoginScreen: UIViewController {
///         // ...
///         func runFlow() async {
///             do {
///                 let runner = DescopeFlowRunner(flowURL: "https://example.com/flows/signup")
///                 let authResponse = try await Descope.flow.start(runner: runner)
///                 let session = DescopeSession(from: authResponse)
///                 Descope.sessionManager.manageSession(session)
///                 showHomeScreen()
///             } catch DescopeError.flowCancelled {
///                 // do nothing
///             } catch {
///                 showErrorAlert(error)
///             }
///         }
///     }
///
/// - Important: In case the flow uses Magic Link authentication you'll need to call
///     ``resume(with:)`` after intercepting the Universal Link from the authentication
///     email. See the documentation for ``resume(with:)`` for more details.
@MainActor
public class DescopeFlowRunner {
    /// Provide authentication info if the flow is being run by an already
    /// authenticated user.
    public struct Authentication {
        /// The flow ID about to be run
        public var flowId: String
        /// The refresh JWT from and active descope session
        public var refreshJwt: String
        
        /// Creates a new ``DescopeFlowRunner/Authentication`` object that encapsulates the
        /// information required to run a flow for an authenticated user.
        ///
        /// - Parameter flowId: The flow ID about to be run.
        /// - Parameter refreshJwt: The refresh JWT from and active descope session
        public init(flowId: String, refreshJwt: String) {
            self.flowId = flowId
            self.refreshJwt = refreshJwt
        }
    }
    
    /// The URL where the flow is hosted.
    public let flowURL: String

    /// Optional authentication info to allow running flows for authenticated users
    public var flowAuthentication: Authentication?
    
    /// Whether the authentication view is allowed to access shared user data.
    ///
    /// Setting this to `true` allows the sandboxed browser in the authentication view
    /// to access cookies and other browsing data from the user's regular browser in the
    /// device.
    ///
    /// This can be helpful in flows that use SSO or OAuth authentication. Users are
    /// often logged in to their provider in the device's regular browser, and enabling
    /// this setting should let them use their active session when authenticating in the
    /// flow rather than forcing them to login to the provider again.
    ///
    /// A side effect of enabling this is that the device will show a dialog before
    /// the authentication view is presented, asking the user to allow the app to share
    /// information with the browser.
    public var shouldAccessSharedUserData: Bool = false
    
    /// Determines where in an application's UI the authentication view for the flow
    /// should be shown.
    ///
    /// Setting this delegate object is optional as the ``DescopeFlowRunner`` will look for
    /// a suitable anchor to show the authentication view. In case you need to override the
    /// default behavior set your own delegate on this property.
    ///
    /// - Note: This property is marked as `weak` like all delegate properties, so if you
    ///     set a custom object make sure it's retained elsewhere.
    public weak var presentationContextProvider: ASWebAuthenticationPresentationContextProviding?
    
    /// Creates a new ``DescopeFlowRunner`` object that encapsulates a single flow run.
    ///
    /// - Parameter flowURL: The URL where the flow is hosted.
    public init(flowURL: String) {
        self.flowURL = flowURL
    }

    /// Resumes a running flow that's waiting for Magic Link authentication.
    ///
    /// When a flow performs authentication with Magic Link at some point it will wait
    /// for the user to receive an email and tap on the authentication URL provided inside.
    /// The host application is expected to intercept this URL via Universal Links and
    /// resume the running flow with it.
    ///
    ///     @main
    ///     struct MyApp: App {
    ///         // ...
    ///
    ///         var body: some Scene {
    ///             WindowGroup {
    ///                 ContentView().onOpenURL { url in
    ///                     Descope.flow.current?.resume(with: url)
    ///                 }
    ///             }
    ///         }
    ///     }
    public func resume(with url: URL) {
        pendingURL = url
    }

    /// Cancels the flow run.
    ///
    /// You can cancel any ongoing flow via the `current` property on the
    /// ``Descope/flow`` object, or by holding on to the ``DescopeFlowRunner`` instance
    /// directly.  This method can be safely called multiple times.
    ///
    ///     do {
    ///         let runner = DescopeFlowRunner(...)
    ///         let authResponse = try await Descope.flow.start(runner: runner)
    ///     } catch DescopeError.flowCancelled {
    ///         print("The flow was cancelled")
    ///     } catch {
    ///         // ...
    ///     }
    ///
    ///     // somewhere else
    ///     Descope.flow.current?.cancel()
    ///
    /// Note that cancelling the `Task` that started the flow with `start(runner:)`
    /// has the same effect as calling this ``cancel()`` function.
    ///
    /// In any case, when a runner is cancelled the `start(runner:)` call always
    /// throws a ``DescopeError/flowCancelled`` error.
    ///
    /// - Important: Keep in mind that the cancellation is asynchronous and the calling code
    ///     shouldn't rely on the user interface state being updated immediately after this
    ///     function is called.
    public func cancel() {
        isCancelled = true
    }

    /// Returns whether this runner was cancelled.
    ///
    /// After the flow is started by calling `start(runner:)` it periodically
    /// checks this property to see if the flow was cancelled.
    public private(set) var isCancelled: Bool = false

    // Internal

    /// The running flow periodically checks this property to for any redirect URL from calls
    /// to the ``handleURL(_:)`` function.
    var pendingURL: URL?
    
    /// Returns the ``presentationContextProvider`` or the default provider if none was set.
    var contextProvider: ASWebAuthenticationPresentationContextProviding {
        return presentationContextProvider ?? defaultContextProvider
    }
    
    /// The default context provider that looks for the first key window in the active scene.
    private let defaultContextProvider = DefaultPresentationContextProvider()
}
