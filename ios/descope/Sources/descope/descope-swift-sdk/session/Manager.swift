
import Foundation

/// A set of delegate methods for events about the session managed by a ``DescopeSessionManager``.
@MainActor
public protocol DescopeSessionManagerDelegate: AnyObject {
    /// Called after the session tokens are updated due to a successful refresh or by
    /// a call to ``DescopeSessionManager/updateTokens(with:)``.
    func sessionManagerDidUpdateTokens(_ sessionManager: DescopeSessionManager, session: DescopeSession)

    /// Called after the session user is updated by a call to ``DescopeSessionManager/updateUser(with:)``.
    func sessionManagerDidUpdateUser(_ sessionManager: DescopeSessionManager, session: DescopeSession)
}

/// The ``DescopeSessionManager`` class is used to manage an authenticated
/// user session for an application.
///
/// The session manager takes care of loading and saving the session as well
/// as ensuring that it's refreshed when needed. For the default instances of
/// the ``DescopeSessionManager`` class this means using the keychain for secure
/// storage of the session and refreshing it a short while before it expires.
///
/// Once the user completes a sign in flow successfully you should set the
/// ``DescopeSession`` object as the active session of the session manager.
///
/// ```swift
/// let authResponse = try await Descope.otp.verify(with: .email, loginId: "andy@example.com", code: "123456")
/// let session = DescopeSession(from: authResponse)
/// Descope.sessionManager.manageSession(session)
/// ```
///
/// The session manager can then be used at any time to ensure the session
/// is valid and to authenticate outgoing requests to your backend with a
/// bearer token authorization header.
///
/// ```swift
/// var request = URLRequest(url: url)
/// try await request.setAuthorizationHTTPHeaderField(from: Descope.sessionManager)
/// let (data, response) = try await URLSession.shared.data(for: request)
/// ```
///
/// If your backend uses a different authorization mechanism you can of course
/// use the session JWT directly instead of the extension function. You can either
/// add another extension function on `URLRequest` such as the one above, or you
/// can do the following.
///
/// ```swift
/// try await Descope.sessionManager.refreshSessionIfNeeded()
/// guard let sessionJwt = Descope.sessionManager.session?.sessionJwt else { throw ServerError.unauthorized }
/// request.setValue(sessionJwt, forHTTPHeaderField: "X-Auth-Token")
/// ```
///
/// When the application is relaunched the ``DescopeSessionManager`` loads any
/// existing session automatically, so you can check straight away if there's
/// an authenticated user.
///
/// ```swift
/// func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
///     Descope.setup(projectId: "...")
///     if let session = Descope.sessionManager.session, !session.refreshToken.isExpired {
///         print("User is logged in: \(session)")
///     }
///     return true
/// }
/// ```
///
/// When the user wants to sign out of the application you only need to call
/// the `clearSession()` method to make the session manager clear its session
/// and also delete it from the keychain.
///
/// ```swift
/// Descope.sessionManager.clearSession()
/// ```
///
/// You can also remove the user's refresh token from the Descope servers once\
/// it becomes redundant after the user is signed out. See the documentation for
/// the ``DescopeAuth/revokeSessions(_:refreshJwt:)`` function for more details.
///
/// The session manager periodically checks if the session needs to be refreshed
/// (every 30 seconds by default), and refreshes it if it's about to expire (within
/// 60 seconds by default) or if it's already expired.
///
/// You can customize how the ``DescopeSessionManager`` stores the session by using
/// your own `storage` object. See the documentation for the ``init(storage:auth:config:)``
/// initializer below for more details.
@MainActor
public class DescopeSessionManager {
    /// The object that handles session storage for this manager.
    private let storage: DescopeSessionStorage

    /// The object used to refresh the session.
    private let auth: DescopeAuth

    /// The logger used by this manager.
    private let logger: DescopeLogger?

    /// The ``DescopeSession`` managed by this object.
    public private(set) var session: DescopeSession? {
        didSet {
            if session?.refreshJwt != oldValue?.refreshJwt {
                resetTimer()
            }
            if let session, session.refreshToken.isExpired {
                logger.debug("Session has an expired refresh token", session.refreshToken.expiresAt)
            }
        }
    }

    /// How long before the session JWT expires the session is considered to need a refresh.
    public var refreshTriggerInterval: TimeInterval = 60 /* seconds */

    /// How often the session manager checks if the session needs to be refreshed, or 0 to disable.
    public var periodicCheckFrequency: TimeInterval = 30 /* seconds */ {
        didSet {
            if periodicCheckFrequency != oldValue {
                resetTimer()
            }
        }
    }

    /// Creates a new ``DescopeSessionManager`` object.
    ///
    /// This initializer can be used to create a ``DescopeSessionManager`` instance
    /// with a custom storage.
    ///
    /// - Parameters:
    ///   - storage: An instance of the ``SessionStorage`` class or some other custom
    ///     implementation of the ``DescopeSessionStorage`` protocol.
    ///   - auth: The ``DescopeAuth`` object used to refresh the session.
    ///   - config: The ``DescopeConfig`` object used to configure the session manager.
    public init(storage: DescopeSessionStorage, auth: DescopeAuth, config: DescopeConfig) {
        self.storage = storage
        self.auth = auth
        self.logger = config.logger
        self.session = storage.loadSession()
        resetTimer()
    }

    /// Set an active ``DescopeSession`` in this manager.
    ///
    /// You should call this function after a user finishes logging in to the
    /// host application.
    ///
    /// The parameter is set as the value of the ``session`` property and is saved
    /// to the keychain so it can be reloaded on the next application launch or
    /// ``DescopeSessionManager`` instantiation.
    ///
    /// - Important: The default ``DescopeSessionStorage`` only keeps at most
    ///     one session in the keychain for simplicity. If for some reason you
    ///     have multiple ``DescopeSessionManager`` objects then be aware that
    ///     unless they use custom `storage` objects they might overwrite
    ///     each other's saved sessions.
    public func manageSession(_ session: DescopeSession) {
        let current = self.session

        self.session = session
        storage.saveSession(session)

        if let current, current.sessionJwt != session.sessionJwt || current.refreshJwt != session.refreshJwt {
            delegates.forEach { $0.sessionManagerDidUpdateTokens(self, session: session) }
        }
        if let current, current.user != session.user {
            delegates.forEach { $0.sessionManagerDidUpdateUser(self, session: session) }
        }
    }

    /// Clears any active ``DescopeSession`` from this manager and removes it
    /// from the keychain.
    ///
    /// You should call this function as part of a logout flow in the host application.
    /// The ``session`` property is set to `nil` and the session won't be reloaded in
    /// subsequent application launches.
    ///
    /// - Important: The default ``DescopeSessionStorage`` only keeps at most
    ///     one session in the keychain for simplicity. If for some reason you
    ///     have multiple ``DescopeSessionManager`` objects then be aware that
    ///     unless they use custom `storage` objects they might clear each
    ///     other's saved sessions.
    public func clearSession() {
        session = nil
        storage.removeSession()
    }

    /// Ensures that the session is valid and refreshes it if needed.
    ///
    /// The session manager checks whether there's an active ``DescopeSession`` and if
    /// its session JWT expires within the next 60 seconds. If that's the case then
    /// the session is refreshed and saved to the keychain before returning.
    ///
    /// Concurrent calls share a single refresh, and all of them return or throw
    /// with its result once it completes.
    ///
    /// - Note: When using a custom `storage` object the exact behavior of saving
    ///     the refreshed session depends on its implementation.
    public func refreshSessionIfNeeded() async throws(DescopeError) {
        guard let current = session, shouldRefresh(current) else { return }

        // join the refresh already in flight for this session or start a new one
        let refresh = refreshes[current.sessionJwt] ?? startRefresh(current)

        do {
            try await refresh.value.get()
        } catch {
            // the failure doesn't matter anymore if the session was replaced in the meantime
            guard session?.sessionJwt == current.sessionJwt else { return }
            throw error
        }
    }

    /// Adds a delegate object to the session manager.
    ///
    /// - Important: The session manager keeps `weak` references to its delegate objects,
    ///     so make make sure any object you add as a delegate is retained elsewhere.
    public func addDelegate(_ delegate: DescopeSessionManagerDelegate) {
        delegates.add(delegate)
    }

    /// Removes a delegate object that was previously added.
    ///
    /// The session manager keeps `weak` references to its delegate objects, so there's
    /// usually no need to call this method for objects that are about to be deallocated
    /// anyway.
    public func removeDelegate(_ delegate: DescopeSessionManagerDelegate) {
        delegates.remove(delegate)
    }

    /// Updates the active session's underlying JWTs.
    ///
    /// This function accepts a ``RefreshResponse`` value as a parameter which is returned
    /// by calls to `Descope.auth.refreshSession`. The manager saves the updated session
    /// to the keychain before returning (by default).
    ///
    /// - Important: In most circumstances it's best to use `refreshSessionIfNeeded` and let
    ///     it update the session unless you need to invoke `Descope.auth.refreshSession`
    ///     manually.
    ///
    /// - Note: If the ``DescopeSessionManager`` object was created with a custom `storage`
    ///     object then the exact behavior depends on the specific implementation of the
    ///     ``DescopeSessionStorage`` protocol.
    public func updateTokens(with refreshResponse: RefreshResponse) {
        session?.updateTokens(with: refreshResponse)
        didUpdateTokens()
    }

    /// Updates the active session's user details.
    ///
    /// This function accepts a ``DescopeUser`` value as a parameter which is returned by
    /// calls to `Descope.auth.me`. The manager saves the updated session to the
    /// keychain before returning.
    ///
    /// ```swift
    /// let userResponse = try await Descope.auth.me(refreshJwt: session.refreshJwt)
    /// Descope.sessionManager.updateUser(with: userResponse)
    /// ```
    ///
    /// By default, the manager saves the updated session to the keychain before returning,
    /// but this can be overridden with a custom ``DescopeSessionStorage`` object.
    public func updateUser(with user: DescopeUser) {
        session?.updateUser(with: user)
        didUpdateUser()
    }

    // Internal

    private var delegates = WeakCollection<DescopeSessionManagerDelegate>()

    private func didUpdateTokens() {
        guard let session else { return }
        storage.saveSession(session)
        delegates.forEach { $0.sessionManagerDidUpdateTokens(self, session: session) }
    }

    private func didUpdateUser() {
        guard let session else { return }
        storage.saveSession(session)
        delegates.forEach { $0.sessionManagerDidUpdateUser(self, session: session) }
    }

    // Refresh

    private typealias RefreshTask = Task<Result<Void, DescopeError>, Never>

    private var refreshes: [String: RefreshTask] = [:]

    private func shouldRefresh(_ session: DescopeSession) -> Bool {
        // don't bother trying to refresh if according to device time the refresh token is already expired
        guard !session.refreshToken.isExpired else { return false }
        // only bother refreshing if we're close enough to the session token expiration
        guard session.sessionToken.expiresAt.timeIntervalSinceNow <= refreshTriggerInterval else { return false }
        // don't bother trying to refresh if the new session token will just have the same expiration
        guard session.refreshToken.expiresAt.timeIntervalSince(session.sessionToken.expiresAt) >= 1 else { return false }
        return true
    }

    private func startRefresh(_ current: DescopeSession) -> RefreshTask {
        let refresh = Task { await performRefresh(current) }
        refreshes[current.sessionJwt] = refresh
        return refresh
    }

    private func performRefresh(_ current: DescopeSession) async -> Result<Void, DescopeError> {
        defer { refreshes[current.sessionJwt] = nil }
        logger.info("Refreshing session that is about to expire", current.sessionToken.expiresAt.timeIntervalSinceNow)
        do {
            let response = try await auth.refreshSession(refreshJwt: current.refreshJwt)
            if session?.sessionJwt == current.sessionJwt {
                session?.updateTokens(with: response)
                didUpdateTokens()
            } else {
                logger.info("Skipping refresh because session has changed in the meantime")
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    // Periodic refresh

    private var timer: Timer?

    private func resetTimer() {
        if periodicCheckFrequency > 0, let refreshToken = session?.refreshToken, !refreshToken.isExpired {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: periodicCheckFrequency, repeats: true) { [weak self] timer in
            guard let manager = self else { return timer.invalidate() }
            Task {
                await manager.periodicRefresh()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func periodicRefresh() async {
        if let refreshToken = session?.refreshToken, refreshToken.isExpired {
            logger.debug("Stopping periodic refresh for session with expired refresh token")
            stopTimer()
            return
        }

        do {
            try await refreshSessionIfNeeded()
        } catch .networkError {
            logger.debug("Ignoring network error in periodic refresh")
        } catch {
            logger.error("Stopping periodic refresh after failure", error)
            stopTimer()
        }
    }
}
