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

    /// Extract a compact, actionable message from a `DecodingError` that
    /// names the failing key / path — so toasts show something like
    /// "Decode: keyNotFound 'max_hp' at attacker" instead of the opaque
    /// "The data couldn't be read because it is missing".
    private static func describeDecodingError(_ error: Error) -> String {
        guard let decErr = error as? DecodingError else {
            return "Data error: \(error.localizedDescription)"
        }
        func pathStr(_ ctx: DecodingError.Context) -> String {
            ctx.codingPath.map { $0.stringValue }.joined(separator: ".")
        }
        switch decErr {
        case .keyNotFound(let key, let ctx):
            let p = pathStr(ctx)
            return "Decode: missing '\(key.stringValue)'\(p.isEmpty ? "" : " at \(p)")"
        case .typeMismatch(let type, let ctx):
            let p = pathStr(ctx)
            return "Decode: type mismatch \(type) at \(p.isEmpty ? "root" : p)"
        case .valueNotFound(let type, let ctx):
            let p = pathStr(ctx)
            return "Decode: null \(type) at \(p.isEmpty ? "root" : p)"
        case .dataCorrupted(let ctx):
            let p = pathStr(ctx)
            return "Decode: corrupted at \(p.isEmpty ? "root" : p) — \(ctx.debugDescription)"
        @unknown default:
            return "Data error: \(decErr.localizedDescription)"
        }
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
            Self.describeDecodingError(error)
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

    /// Decode a typed view of the parsed 4xx response body. Keeps the one
    /// raw JSON body extraction centralized in networking while letting
    /// callers stay on typed DTOs for recoverable error flows.
    func decodedResponseBody<T: Decodable>(_ type: T.Type) -> T? {
        guard let body = responsePayload,
              JSONSerialization.isValidJSONObject(body),
              let data = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(T.self, from: data)
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
