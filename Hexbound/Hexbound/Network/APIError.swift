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

    /// User-friendly message suitable for display in the UI.
    /// Maps common technical backend error strings to player-friendly text.
    var userMessage: String {
        let raw = errorDescription ?? "Something went wrong. Please try again."
        return Self.friendlyMessage(for: raw)
    }

    private static let friendlyMap: [(pattern: String, friendly: String)] = [
        ("Insufficient gold", "Not enough gold"),
        ("Insufficient gems", "Not enough gems"),
        ("Not enough gold", "Not enough gold"),
        ("Not enough gems", "Not enough gems"),
        ("Inventory full", "Your inventory is full"),
        ("inventory is full", "Your inventory is full"),
        ("Item not found", "Item no longer available"),
        ("Character not found", "Character not found — try restarting"),
        ("Already claimed", "Already claimed"),
        ("Quest not completed", "Quest not completed yet"),
        ("Not eligible", "Not eligible for this action"),
        ("Too many requests", "Slow down — try again in a moment"),
        ("Failed to fetch", "Connection error — check your internet"),
        ("ECONNREFUSED", "Server unavailable — try again later"),
        ("Internal Server Error", "Server error — try again later"),
    ]

    private static func friendlyMessage(for raw: String) -> String {
        let lowered = raw.lowercased()
        for entry in friendlyMap {
            if lowered.contains(entry.pattern.lowercased()) {
                return entry.friendly
            }
        }
        // If the message looks like a technical error (contains stack-trace markers,
        // prisma keywords, or raw SQL), replace with a generic message
        if lowered.contains("prisma") || lowered.contains("sql") ||
           lowered.contains("constraint") || lowered.contains("enotfound") ||
           lowered.contains("column") || lowered.contains("relation") {
            return "Something went wrong. Please try again."
        }
        return raw
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

    /// HTTP status code for cases that carry one (4xx/5xx). Returns `nil`
    /// for transport/decoding/unknown errors. Lets callers branch on
    /// specific codes (e.g. 409 NO_PLAYABLE_SLOTS) without unwrapping
    /// the enum case manually.
    var statusCode: Int? {
        switch self {
        case .serverError(let statusCode, _):
            return statusCode
        case .clientError(let statusCode, _, _):
            return statusCode
        case .unauthorized:
            return 401
        default:
            return nil
        }
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
