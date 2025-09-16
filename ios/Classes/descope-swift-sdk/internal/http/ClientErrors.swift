
import Foundation

// API errors

extension DescopeError {
    init?(errorResponse data: Data) {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        self.init(errorResponse: dict)
    }

    init?(errorResponse dict: [String: Any]) {
        guard let code = dict["errorCode"] as? String else { return nil }
        var desc = "Descope server error" // is always supposed to be overwritten below
        if let value = dict["errorDescription"] as? String, !value.isEmpty {
            desc = value
        }
        var message: String? = nil
        if let value = dict["errorMessage"] as? String, !value.isEmpty {
            message = value
        }
        self = DescopeError(code: code, desc: desc, message: message)
    }
}

// HTTP errors

extension DescopeError {
    init?(httpStatusCode: Int) {
        guard let err = HTTPError(statusCode: httpStatusCode) else { return nil }
        self = DescopeError(httpError: err)
    }

    init(httpError: HTTPError) {
        self = DescopeError.httpError.with(desc: httpError.description)
    }
}

enum HTTPError: Error {
    case invalidRoute
    case invalidResponse
    case unexpectedResponse(Int)
    case badRequest
    case notFound
    case unauthorized
    case forbidden
    case serverFailure(Int)
    case serverUnreachable(Int)
}

extension HTTPError {
    init?(statusCode: Int) {
        switch statusCode {
        case 200...299: return nil
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound
        case 500, 501, 503: self = .serverFailure(statusCode)
        case 500...: self = .serverUnreachable(statusCode)
        default: self = .unexpectedResponse(statusCode)
        }
    }
}

extension HTTPError: CustomStringConvertible {
    var description: String {
        switch self {
        case .invalidRoute: return "The request URL was invalid"
        case .invalidResponse: return "The server returned an unexpected response"
        case .unexpectedResponse(let code): return "The server returned status code \(code)"
        case .badRequest: return "The request was invalid"
        case .notFound: return "The resource was not found"
        case .unauthorized: return "The request was unauthorized"
        case .forbidden: return "The request was forbidden"
        case .serverFailure(let code): return "The server failed with status code \(code)"
        case .serverUnreachable(let code): return "The server was unreachable with status code \(code)"
        }
    }
}
