
import Foundation

/// Provides functions for working with the Descope API.
///
/// The ``Descope`` singleton object exposes the same properties as the ``DescopeSDK`` class,
/// and in most app architectures it might be more convenient to use it instead.
public class DescopeSDK {
    /// The configuration of the ``DescopeSDK`` instance.
    public let config: DescopeConfig
    
    /// Provides functions for managing authenticated sessions.
    public let auth: DescopeAuth
    
    /// Provides functions for authentication with OTP codes via email or phone.
    public let otp: DescopeOTP
    
    /// Provides functions for authentication with TOTP codes.
    public let totp: DescopeTOTP
    
    /// Provides functions for authentication with passkeys.
    public let passkey: DescopePasskey

    /// Provides functions for authentication with passwords.
    public let password: DescopePassword
    
    /// Provides functions for authentication with magic links.
    public let magicLink: DescopeMagicLink
    
    /// Provides functions for authentication with enchanted links.
    public let enchantedLink: DescopeEnchantedLink
    
    /// Provides functions for authentication with OAuth.
    public let oauth: DescopeOAuth
    
    /// Provides functions for authentication with SSO.
    public let sso: DescopeSSO
    
    /// Provides functions for exchanging access keys for session tokens.
    public let accessKey: DescopeAccessKey

    /// Manages the storage and lifetime of a ``DescopeSession``.
    ///
    /// You can use this ``DescopeSessionManager`` object to manage authenticated sessions
    /// in your application whereever you pass this ``DescopeSDK`` instance.
    ///
    ///     class ViewController: UIViewController {
    ///         let descope: DescopeSDK
    ///
    ///         init(descope: DescopeSDK) {
    ///             self.descope = descope
    ///         }
    ///
    ///         func verifyOTP(phone: String, code: String) async throws {
    ///             let authResponse = try await descope.otp.verify(with: .sms, loginId: phone, code: code)
    ///             let session = DescopeSession(from: authResponse)
    ///             descope.sessionManager.manageSession(session)
    ///         }
    ///
    /// See the documentation for ``DescopeSessionManager`` for more details.
    ///
    /// - Note: You can set your own instance of ``DescopeSessionManager`` directly after
    ///     creating a ``DescopeSDK`` object. Since the initial value of ``sessionManager``
    ///     is created lazily this will ensure that the default instance doesn't get a
    ///     chance to perform any keychain queries before being replaced.
    @MainActor
    public lazy var sessionManager: DescopeSessionManager = DescopeSessionManager(sdk: self)
    
    /// Creates a new ``DescopeSDK`` object.
    ///
    /// You can create a ``DescopeSDK`` object and pass a reference to it wherever it's needed,
    /// in particular if you prefer to do dependency injection style programming instead of relying
    /// on the ``Descope`` singleton.
    ///
    ///     let descope = DescopeSDK(projectId: "<Your-Project-Id>")
    ///     let viewModel = AuthViewModel(descope: descope)
    ///     showAuthScreen(with: viewModel)
    ///
    /// You can also pass a closure to this initializer to perform additional configuration.
    /// For example, if we want to test failure conditions in code that uses Descope, we might
    /// override the ``DescopeSDK`` object's default networking client with one that always
    /// fails, using code such as this (see ``DescopeNetworkClient``):
    ///
    ///     let descope = DescopeSDK(projectId: "test") { config in
    ///         config.networkClient = FailingNetworkClient()
    ///     }
    ///     testOTPNetworkError(descope)
    ///
    /// - Parameters:
    ///   - projectId: The id of the Descope project can be found in
    ///     the project page in the Descope console.
    ///   - closure: An optional closure that performs additional configuration
    ///     by setting values on the provided ``DescopeConfig`` instance.
    public convenience init(projectId: String, with closure: (_ config: inout DescopeConfig) -> Void = { _ in }) {
        var config = DescopeConfig()
        config.projectId = projectId
        closure(&config)
        self.init(config: config, client: DescopeClient(config: config))
    }

    /// Resumes an ongoing authentication that's waiting for Magic Link authentication.
    @discardableResult @MainActor
    public func handleURL(_ url: URL) -> Bool {
        return resume(url)
    }

    // Internal

    /// The internal client used to perform API calls.
    let client: DescopeClient

    /// Creates a new ``DescopeSDK`` object.
    ///
    /// - Parameters:
    ///   - config: The configuration of the ``DescopeSDK`` instance.
    ///   - client: The ``DescopeClient`` object used by route implementations.
    init(config: DescopeConfig, client: DescopeClient) {
        self.config = config
        self.client = client
        self.auth = Auth(client: client)
        self.otp = OTP(client: client)
        self.totp = TOTP(client: client)
        self.passkey = Passkey(client: client)
        self.password = Password(client: client)
        self.magicLink = MagicLink(client: client)
        self.enchantedLink = EnchantedLink(client: client)
        self.oauth = OAuth(client: client)
        self.sso = SSO(client: client)
        self.accessKey = AccessKey(client: client)
    }

    /// The type of the closure set in ``resume(with:)`` by SDK components.
    typealias ResumeClosure = @MainActor (URL) -> (Bool)

    /// While the flow is running this is set to a closure with a weak reference to
    /// the ``DescopeFlowCoordinator`` to provide it with the resume URL.
    var resume: ResumeClosure = { _ in return false }
}

/// SDK information
public extension DescopeSDK {
    /// The Descope SDK name
    static let name = "DescopeKit"
    
    /// The Descope SDK version
    static let version = "0.9.19"
}

// Internal

private extension DescopeSessionManager {
    convenience init(sdk: DescopeSDK) {
        let storage = SessionStorage(projectId: sdk.config.projectId, store: .keychain)
        let lifecycle = SessionLifecycle(auth: sdk.auth, config: sdk.config)
        self.init(storage: storage, lifecycle: lifecycle)
    }
}
