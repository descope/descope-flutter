
import Foundation

/// This protocol can be used to customize how a ``DescopeSessionManager`` object
/// manages its ``DescopeSession`` while the application is running.
@MainActor
public protocol DescopeSessionLifecycle: AnyObject {
    /// Holds the latest session value for the session manager.
    var session: DescopeSession? { get set }

    /// Called by the session manager to conditionally refresh the active session.
    func refreshSessionIfNeeded() async throws(DescopeError) -> Bool

    /// The session manager sets this closure so it can be notified of successful periodic refreshes.
    var onPeriodicRefresh: () -> Void { get set }
}

/// The default implementation of the ``DescopeSessionLifecycle`` protocol.
///
/// The ``SessionLifecycle`` class periodically checks if the session needs to be
/// refreshed (every 30 seconds by default). The `refreshSessionIfNeeded` function
/// will refresh the session if it's about to expire (within 60 seconds by default)
/// or if it's already expired.
public class SessionLifecycle: DescopeSessionLifecycle {
    private let auth: DescopeAuth
    private let logger: DescopeLogger?

    public init(auth: DescopeAuth, config: DescopeConfig) {
        self.auth = auth
        self.logger = config.logger
    }

    public var onPeriodicRefresh: () -> Void = {}

    public var refreshTriggerInterval: TimeInterval = 60 /* seconds */
    
    public var periodicCheckFrequency: TimeInterval = 30 /* seconds */ {
        didSet {
            if periodicCheckFrequency != oldValue {
                resetTimer()
            }
        }
    }

    public var session: DescopeSession? {
        didSet {
            if session?.refreshJwt != oldValue?.refreshJwt {
                resetTimer()
            }
            if let session, session.refreshToken.isExpired {
                logger.debug("Session has an expired refresh token", session.refreshToken.expiresAt)
            }
        }
    }
    
    public func refreshSessionIfNeeded() async throws(DescopeError) -> Bool {
        guard let current = session, shouldRefresh(current) else { return false }

        logger.info("Refreshing session that is about to expire", current.sessionToken.expiresAt.timeIntervalSinceNow)
        let response = try await auth.refreshSession(refreshJwt: current.refreshJwt)

        guard session?.sessionJwt == current.sessionJwt else {
            logger.info("Skipping refresh because session has changed in the meantime")
            return false
        }

        session?.updateTokens(with: response)
        return true
    }
    
    // Conditional refresh
    
    private func shouldRefresh(_ session: DescopeSession) -> Bool {
        // don't bother trying to refresh if according to device time the refresh token is already expired
        guard !session.refreshToken.isExpired else { return false }
        // only bother refreshing if we're close enough to the session token expiration
        guard session.sessionToken.expiresAt.timeIntervalSinceNow <= refreshTriggerInterval else { return false }
        // don't bother trying to refresh if the new session token will just have the same expiration
        guard session.refreshToken.expiresAt.timeIntervalSince(session.sessionToken.expiresAt) >= 1 else { return false }
        return true
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
            guard let lifecycle = self else { return timer.invalidate() }
            Task {
                await lifecycle.periodicRefresh()
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
            let refreshed = try await refreshSessionIfNeeded()
            if refreshed {
                logger.debug("Periodic session refresh succeeded")
                onPeriodicRefresh()
            }
        } catch .networkError {
            logger.debug("Ignoring network error in periodic refresh")
        } catch {
            logger.error("Stopping periodic refresh after failure", error)
            stopTimer()
        }
    }
}
