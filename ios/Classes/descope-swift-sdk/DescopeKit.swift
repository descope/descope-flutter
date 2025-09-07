
import Foundation

/// Provides functions for working with the Descope API.
///
/// This singleton object is provided as a simple way to access the Descope SDK from anywhere
/// in your code. It should be suitable for most app architectures, but if you prefer a different
/// approach you can also create an instance of the ``DescopeSDK`` class instead and pass it
/// to wherever it's needed.
public enum Descope {
    /// Initialize the Descope SDK to prepare it for use.
    ///
    /// You will most likely want to call this function in your application's initialization code,
    /// and in most cases you'll only need to specify the `projectId`:
    ///
    /// ```swift
    /// func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ///     Descope.setup(projectId: "<Your-Project-Id>")
    /// }
    /// ```
    ///
    /// You can also pass a closure to this function to perform additional configuration.
    /// For example, if you want to enable debugging logs in the Descope SDK during development
    /// and you have a separate Descope project you use as a staging environment when building
    /// and testing beta versions, you can do something like this:
    ///
    /// ```swift
    /// func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ///     Descope.setup(projectId: "<Production-Project-Id>") { config in
    ///         #if DEBUG
    ///         config.logger = .debugLogger
    ///         #endif
    ///         if AppConfig.isBetaBuild {
    ///             config.projectId = "<Staging-Project-Id>"
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - projectId: The id of the Descope project can be found in
    ///     the project page in the Descope console.
    ///   - closure: An optional closure that performs additional configuration
    ///     by setting values on the provided ``DescopeConfig`` instance.
    @MainActor
    public static func setup(projectId: String, with closure: (_ config: inout DescopeConfig) -> Void = { _ in }) {
        sdk = DescopeSDK(projectId: projectId, with: closure)
    }

    /// Manages the storage and lifetime of a ``DescopeSession``.
    ///
    /// You can use this ``DescopeSessionManager`` object as a shared instance to manage
    /// authenticated sessions in your application.
    ///
    /// ```swift
    /// let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
    /// let session = DescopeSession(from: authResponse)
    /// Descope.sessionManager.manageSession(session)
    /// ```
    ///
    /// See the documentation for ``DescopeSessionManager`` for more details.
    @MainActor
    public static var sessionManager: DescopeSessionManager {
        get { sdk.sessionManager }
        set { sdk.sessionManager = newValue }
    }

    /// The underlying ``DescopeSDK`` object used by the ``Descope`` singleton.
    static nonisolated(unsafe) var sdk: DescopeSDK = .initial
}

/// Authentication functions that call the Descope API.
public extension Descope {
    /// Provides functions for managing authenticated sessions.
    static var auth: DescopeAuth { sdk.auth }
    
    /// Provides functions for authentication with OTP codes via email or phone.
    static var otp: DescopeOTP { sdk.otp }
    
    /// Provides functions for authentication with TOTP codes.
    static var totp: DescopeTOTP { sdk.totp }
    
    /// Provides functions for authentication with passkeys.
    static var passkey: DescopePasskey { sdk.passkey }

    /// Provides functions for authentication with passwords.
    static var password: DescopePassword { sdk.password }

    /// Provides functions for authentication with magic links.
    static var magicLink: DescopeMagicLink { sdk.magicLink }
    
    /// Provides functions for authentication with enchanted links.
    static var enchantedLink: DescopeEnchantedLink { sdk.enchantedLink }
    
    /// Provides functions for authentication with OAuth.
    static var oauth: DescopeOAuth { sdk.oauth }
    
    /// Provides functions for authentication with SSO.
    static var sso: DescopeSSO { sdk.sso }
    
    /// Provides functions for exchanging access keys for session tokens.
    static var accessKey: DescopeAccessKey { sdk.accessKey }
}

/// Support for working with Universal Links.
public extension Descope {
    /// Resumes an ongoing authentication that's waiting for Magic Link authentication.
    ///
    /// When a flow performs authentication with Magic Link at some point it will wait for
    /// the user to receive an email and tap on the authentication link provided inside.
    /// The host application is expected to intercept this URL via Universal Links and
    /// resume the running flow with it.
    ///
    /// You can do this by calling this function and passing the URL from the Universal Link.
    /// For example, in a SwiftUI application:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     // ...
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView().onOpenURL { url in
    ///                 Descope.handleURL(url)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// You can pass the return value of this function directly to the `UIApplicationDelegate`
    /// method for handling Universal Links. For example:
    ///
    /// ```swift
    /// @main
    /// class AppDelegate: UIResponder, UIApplicationDelegate {
    ///     // ...
    ///     func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    ///         guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return false }
    ///         return Descope.handleURL(url)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter url: The `url` to use for resuming the authentication.
    ///
    /// - Returns: `true` when an ongoing authentication handled the URL or `false` to
    ///     let the caller know that the function didn't handle it.
    @MainActor @discardableResult
    static func handleURL(_ url: URL) -> Bool {
        return sdk.handleURL(url)
    }
}
