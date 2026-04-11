import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited(message: String)
    case serverError(statusCode: Int, message: String)
    /// 4xx error from the server. `body` carries the parsed JSON payload
    /// when one was returned — useful for callers that need error `code`,
    /// hints, or typed fields (e.g. NO_PLAYABLE_SLOTS + unplayed indices).
    case clientError(statusCode: Int, message: String, body: [String: Any]?)
    case decodingError(Error)
    case networkError(Error)
    case noData
    case unknown(String)

    /// User-friendly message suitable for display in the UI
    var userMessage: String {
        errorDescription ?? "Something went wrong. Please try again."
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .unauthorized:
            "Session expired, please login again"
        case .rateLimited(let message):
            message
        case .serverError(_, let message):
            message
        case .clientError(_, let message, _):
            message
        case .decodingError(let error):
            "Data error: \(error.localizedDescription)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .noData:
            "No data received"
        case .unknown(let message):
            message
        }
    }

    /// True when the error represents a 401. Screens should suppress their
    /// local error state for this case — the global unauthorized handler
    /// (session expired modal or guest silent re-auth) will take over.
    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    /// Parsed JSON body from a 4xx response (when present). Lets callers
    /// branch on server-supplied error codes and typed hints without
    /// re-parsing the error message.
    var responsePayload: [String: Any]? {
        if case .clientError(_, _, let body) = self { return body }
        return nil
    }
}

extension Error {
    /// Convenience — checks for `APIError.unauthorized` on any Error.
    var isUnauthorizedAPIError: Bool {
        (self as? APIError)?.isUnauthorized == true
    }
}

struct APIResponse {
    let success: Bool
    let data: [String: Any]?
    let error: String?
    let statusCode: Int

    init(data: [String: Any]? = nil, error: String? = nil, statusCode: Int = 200) {
        self.success = error == nil && (200..<300).contains(statusCode)
        self.data = data
        self.error = error
        self.statusCode = statusCode
    }
}
