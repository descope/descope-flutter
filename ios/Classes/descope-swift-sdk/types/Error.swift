
import Foundation

/// The concrete type of `Error` thrown by all operations in the Descope SDK.
///
/// The ``DescopeError`` objects implement the `LocalizedError` protocol so you can use the value
/// of the `localizedDescription` property to get a relatively user friendly error string.
///
///     } catch let err as DescopeError {
///         showErrorAlert(text: err.localizedDescription)
///     }
///
/// There are several ways to catch and handle a ``DescopeError`` thrown by a Descope SDK
/// operation, and you can use whichever one is more appropriate in each specific use case.
///
///     do {
///         let authResponse = try await Descope.otp.verify(with: .email, loginId: loginId, code: code)
///         showLoginSuccess(with: authResponse)
///     } catch DescopeError.wrongOTPCode, DescopeError.invalidRequest {
///         // catch one or more kinds of errors where we don't
///         // need to use the actual error object
///         showBadCodeAlert()
///     } catch let err as DescopeError where err == .networkError {
///         // catch a specific kind of error and do something
///         // with the error object
///         logError("A network error has occurred", err.cause)
///         showNetworkErrorRetry()
///     } catch {
///         // catch any other error
///         logError("Unexpected authentication failure: \(error)")
///         showUnexpectedErrorAlert(with: error)
///     }
///
/// See the ``DescopeError`` extension for specific error values. Note that not all API errors
/// are listed in the SDK yet. Please let us know via a Github issue or pull request if you
/// need us to add any entries to make your code simpler.
public struct DescopeError: Error {
    /// A string of 7 characters that represents a specific Descope error.
    ///
    /// For example, the value of ``code`` is `"E011003"` when an API request fails validation.
    public var code: String
    
    /// A short description of the error message.
    ///
    /// For example, the value of ``desc`` is `"Request is invalid"` when an API request
    /// fails validation.
    public var desc: String
    
    /// An optional message with more details about the error.
    ///
    /// For example, the value of ``message`` might be `"The email field is required"` when
    /// attempting to authenticate via enchanted link with an empty email address.
    public var message: String?
    
    /// An optional underlying error that caused this error.
    ///
    /// For example, when a ``DescopeError/networkError`` error is thrown the ``cause``
    /// property will always contain the `NSError` object thrown by the internal `URLSession`
    /// call. When a ``DescopeError/passkeyFailed`` error is thrown the ``cause`` property
    /// will often contain an instance of AuthorizationError.
    public var cause: Error?
}

/// A list of common ``DescopeError`` values that can be thrown by the Descope SDK.
extension DescopeError {
    /// Thrown when a call to the Descope API fails due to a network error.
    ///
    /// You can catch this kind of error to handle error cases such as the user being
    /// offline or the network request timing out.
    public static let networkError = DescopeError.sdkError("S010001", "Network error")

    public static let badRequest = DescopeError.apiError("E011001")
    public static let missingArguments = DescopeError.apiError("E011002")
    public static let invalidRequest = DescopeError.apiError("E011003")
    public static let invalidArguments = DescopeError.apiError("E011004")

    public static let missingAccessKey = DescopeError.apiError("E062802")
    public static let invalidAccessKey = DescopeError.apiError("E062803")
    
    public static let wrongOTPCode = DescopeError.apiError("E061102")
    public static let tooManyOTPAttempts = DescopeError.apiError("E061103")
    
    public static let enchantedLinkPending = DescopeError.apiError("E062503")
    public static let enchantedLinkExpired = DescopeError.sdkError("S060001", "Enchanted link expired")
    
    public static let flowFailed = DescopeError.sdkError("S100001", "Flow failed to run")
    public static let flowCancelled = DescopeError.sdkError("S100002", "Flow cancelled")
    
    public static let passkeyFailed = DescopeError.sdkError("S110001", "Passkey authentication failed")
    public static let passkeyCancelled = DescopeError.sdkError("S110002", "Passkey authentication cancelled")
    public static let passkeyNoneAdded = DescopeError.sdkError("E067010", "User has not added any passkeys")

    public static let oauthNativeFailed = DescopeError.sdkError("S120001", "Sign in with Apple failed")
    public static let oauthNativeCancelled = DescopeError.sdkError("S120002", "Sign in with Apple cancelled")
    
    public static let webAuthFailed = DescopeError.sdkError("S130001", "Web authentication failed")
    public static let webAuthCancelled = DescopeError.sdkError("S130002", "Web authentication cancelled")
}

/// Extension functions for catching ``DescopeError`` values.
extension DescopeError: Equatable {
    /// Returns true if the two ``DescopeError`` instances have the same ``code``.
    ///
    /// This allows catching specific kinds of ``DescopeError`` with syntax such as:
    ///
    ///     do {
    ///        try await Descope.sso.exchange(code: mycode)
    ///     } catch let err as DescopeError where err == .networkError {
    ///        print("The network request failed: \(err)")
    ///     }
    public static func == (lhs: DescopeError, rhs: DescopeError) -> Bool {
        return lhs.code == rhs.code
    }

    /// Returns true if the other error object is also a ``DescopeError`` and they have
    /// the same ``code``.
    ///
    /// This allows catching specific kinds of ``DescopeError`` with syntax such as:
    ///
    ///     do {
    ///        authResponse = try await Descope.otp.verify(with: .email, loginId: loginId, code: code)
    ///     } catch DescopeError.wrongOTPCode {
    ///        showBadCodeAlert()
    ///     }
    public static func ~= (lhs: DescopeError, rhs: Error) -> Bool {
        guard let rhs = rhs as? DescopeError else { return false }
        return lhs == rhs
    }
}

extension DescopeError: CustomStringConvertible {
    /// Returns a textual representation of this ``DescopeError``.
    public var description: String {
        var str = "DescopeError(code: \"\(code)\", description: \"\(desc)\""
        if let message {
            str += ", message: \"\(message)\""
        }
        if let cause {
            str += ", cause: {\(cause)}"
        }
        str += ")"
        return str
    }
}

extension DescopeError: LocalizedError {
    /// Returns a user friendly message describing what error occurred.
    public var errorDescription: String? {
        var str = "\(desc)"
        if let cause = cause as? NSError {
            str += ": \(cause.localizedDescription) [\(cause.code)]"
        } else if let message {
            str += ": \(message) [\(code)]"
        } else {
            str += " [\(code)]"
        }
        return str
    }
}

// Internal

/// These errors are not expected to happen in common usage and there shouldn't be
/// a need to catch them specifically.
extension DescopeError {
    /// Thrown if a call to the Descope API fails in an unexpected manner.
    ///
    /// This should only be thrown when there's no error response body to parse or the body
    /// isn't in the expected format. The value of ``desc`` is overwritten with a more specific
    /// value when possible.
    static let httpError = DescopeError.sdkError("S010002", "Server request failed")
    
    /// Thrown if a response from the Descope API can't be parsed for an unexpected reason.
    static let decodeError = DescopeError.sdkError("S010003", "Failed to decode response")
    
    /// Thrown if a request to the Descope API fails to encode for an unexpected reason.
    static let encodeError = DescopeError.sdkError("S010004", "Failed to encode request")
    
    /// Thrown if a JWT string fails to decode.
    ///
    /// This might be thrown if the ``DescopeSession`` initializer is called with an invalid
    /// `sessionJwt` or `refreshJwt` value.
    static let tokenError = DescopeError.sdkError("S010005", "Failed to parse token")
}

private extension DescopeError {
    /// Creates a ``DescopeError`` object that represents an error that's created by the SDK,
    /// rather than one that's expected to be returned by API calls.
    static func sdkError(_ code: String, _ desc: String) -> DescopeError {
        return DescopeError(code: code, desc: desc)
    }

    /// Creates a ``DescopeError`` object that matches an error code returned by the Descope API.
    ///
    /// The value of ``desc`` here is a placeholder for the ``DescopeError`` objects created
    /// above. In an actual instance of `DescopeError`` returned by an API call the error
    /// description is taken from the error JSON response.
    static func apiError(_ code: String) -> DescopeError {
        return DescopeError(code: code, desc: "Descope API error")
    }
}
