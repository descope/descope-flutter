
import Foundation

/// This protocol can be used to customize how a ``DescopeSessionManager`` object
/// stores the active ``DescopeSession`` between application launches.
@MainActor
public protocol DescopeSessionStorage: AnyObject {
    /// Called by the session manager when a new session is set or an
    /// existing session is updated.
    func saveSession(_ session: DescopeSession)
    
    /// Called by the session manager when it's initialized to load any
    /// existing session.
    func loadSession() -> DescopeSession?
    
    /// Called by the session manager when the `clearSession` function
    /// is called.
    func removeSession()
}

/// The default implementation of the ``DescopeSessionStorage`` protocol.
///
/// The ``SessionStorage`` class ensures that the ``DescopeSession`` is kept in
/// a secure manner in the device's keychain.
///
/// When running on iOS the keychain guarantees that the tokens are encrypted at
/// rest with an encryption key that only becomes available to the operating system
/// after the device is unlocked at least once following a device restart.
///
/// To change the default storage behavior, create an instance of this class
/// and pass your own `SessionStorage.KeychainStore` object to the initializer,
/// after changing whatever properties you need from their default values.
/// Alternatively, to use a different backing store implementation you can
/// also subclass the `SessionStorage.Store` class and override the `loadItem`,
/// `saveItem` and `removeItem` functions, then pass it to the initializer.
public class SessionStorage: DescopeSessionStorage {
    public let projectId: String
    public let store: Store
    
    private var lastSaved: EncodedSession?

    public init(projectId: String, store: Store) {
        self.projectId = projectId
        self.store = store
    }
    
    public func saveSession(_ session: DescopeSession) {
        let encoded = EncodedSession(sessionJwt: session.sessionJwt, refreshJwt: session.refreshJwt, user: session.user)
        guard lastSaved != encoded else { return }
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        try? store.saveItem(key: projectId, data: data)
        lastSaved = encoded
    }
    
    public func loadSession() -> DescopeSession? {
        guard let data = try? store.loadItem(key: projectId) else { return nil }
        guard let encoded = try? JSONDecoder().decode(EncodedSession.self, from: data) else { return nil }
        let session = try? DescopeSession(sessionJwt: encoded.sessionJwt, refreshJwt: encoded.refreshJwt, user: encoded.user)
        lastSaved = encoded
        return session
    }
    
    public func removeSession() {
        lastSaved = nil
        try? store.removeItem(key: projectId)
    }
    
    /// A helper class that takes care of the actual storage of session data.
    ///
    /// The default function implementations in this class do nothing or return `nil`.
    @MainActor
    open class Store {
        public init() {
        }
        
        open func loadItem(key: String) throws -> Data? {
            return nil
        }
        
        open func saveItem(key: String, data: Data) throws {
        }
        
        open func removeItem(key: String) throws {
        }
    }
    
    /// A helper struct for serializing the ``DescopeSession`` data.
    private struct EncodedSession: Codable, Equatable {
        var sessionJwt: String
        var refreshJwt: String
        var user: DescopeUser
    }
}

extension SessionStorage.Store {
    /// A store that does nothing.
    public static let none = SessionStorage.Store()

    /// A store that saves the session data to the default keychain.
    public static let keychain: SessionStorage.Store = SessionStorage.KeychainStore()
}

extension SessionStorage {
    /// A store that saves the session data using the iOS keychain.
    public class KeychainStore: Store {
        /// The accessibility level to use when saving to the keychain.
        ///
        /// The default value is `kSecAttrAccessibleAfterFirstUnlock` which allows the session
        /// to be loaded after the device is unlocked at least once. This level should be appropriate
        /// for most apps including those that might run in the background.
        ///
        /// - Note: In some special cases, applications and app extensions might be launched by
        ///     the operating system in the background, before the user had a chance to unlock
        ///     their device after it had been restarted. For example, an iOS app that's scanning
        ///     for Bluetooth peripherals in the background using the `bluetooth-central` background
        ///     mode. In such cases care should be taken to ensure the app isn't started in a logged
        ///     out state just because the session could not be loaded.
        public var accessibility: String = kSecAttrAccessibleAfterFirstUnlock as String
        
        /// An optional override to force keychain items to belong to a specific keychain
        /// access group when sessions are saved.
        ///
        /// In most cases there's no need to set this property, as the regular behavior is
        /// for keychain items to be saved to your app’s default access group.
        ///
        /// - Note: When sessions are loaded this property is ignored and the store looks
        ///     searches in all the app's keychain access groups.
        ///
        /// - SeeAlso: For more details see the [Apple documentation](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps#Set-a-keychain-items-access-group).
        public var accessGroup: String?
        
        /// The value to use for the kSecAttrService attribute.
        ///
        /// - Important: If this value is changed in an app update any existing sessions for
        ///     users will not be found and users will need to sign in again.
        public var service = "com.descope.DescopeKit"
        
        /// The value to use for the kSecAttrLabel attribute.
        ///
        /// - Important: If this value is changed in an app update any existing sessions for
        ///     users will not be found and users will need to sign in again.
        public var label = "DescopeSession"

        public override func loadItem(key: String) -> Data? {
            var query = queryForItem(key: key)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var value: AnyObject?
            SecItemCopyMatching(query as CFDictionary, &value)
            return value as? Data
        }
        
        public override func saveItem(key: String, data: Data) {
            var values: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: accessibility,
            ]
            
            if let accessGroup {
                values[kSecAttrAccessGroup as String] = accessGroup
            }
            
            #if os(macOS) // XXX the #if check can be removed according to docs
            values[kSecUseDataProtectionKeychain as String] = true
            #endif

            let query = queryForItem(key: key)
            let result = SecItemCopyMatching(query as CFDictionary, nil)
            if result == errSecSuccess {
                SecItemUpdate(query as CFDictionary, values as CFDictionary)
            } else if result == errSecItemNotFound {
                let merged = query.merging(values, uniquingKeysWith: { $1 })
                SecItemAdd(merged as CFDictionary, nil)
            }
        }
        
        public override func removeItem(key: String) {
            let query = queryForItem(key: key)
            SecItemDelete(query as CFDictionary)
        }
        
        private func queryForItem(key: String) -> [String: Any] {
            return [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrLabel as String: label,
                kSecAttrAccount as String: key,
            ]
        }
    }
}
