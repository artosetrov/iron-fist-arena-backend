import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = AppConstants.apiBaseURL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?
    /// Shared refresh task — parallel 401s await the same refresh instead of failing.
    private var refreshTask: Task<String?, Never>?

    /// Phase 2 (2026-04-13, M-1): in-flight GET dedup. Two rapid taps
    /// hitting the same endpoint+params await the same URLSession task
    /// instead of firing duplicate network requests. Cleared as soon as
    /// the underlying task completes (success or failure). Mutations
    /// (POST/PATCH/DELETE) are never deduped — they have side effects.
    private var inFlightGETs: [String: Task<Data, Error>] = [:]

    // Callback for 401 handling
    var onUnauthorized: (@Sendable () -> Void)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.requestTimeout
        config.httpMaximumConnectionsPerHost = 5
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Token Management

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    func getAuthToken() -> String? {
        authToken
    }

    func clearAuthToken() {
        authToken = nil
    }

    // MARK: - Typed Requests

    func get<T: Decodable>(_ endpoint: String, params: [String: String] = [:]) async throws -> T {
        let data = try await request(method: "GET", endpoint: endpoint, params: params)
        return try decodeOrThrow(T.self, from: data, endpoint: endpoint)
    }

    func post<T: Decodable>(_ endpoint: String, body: Encodable? = nil) async throws -> T {
        let data = try await request(method: "POST", endpoint: endpoint, body: body)
        return try decodeOrThrow(T.self, from: data, endpoint: endpoint)
    }

    func patch<T: Decodable>(_ endpoint: String, body: Encodable? = nil) async throws -> T {
        let data = try await request(method: "PATCH", endpoint: endpoint, body: body)
        return try decodeOrThrow(T.self, from: data, endpoint: endpoint)
    }

    /// Decode and wrap `DecodingError` as `APIError.decodingError` so callers
    /// that branch on `APIError` (and surface `errorDescription` in toasts)
    /// see a useful message instead of the generic fallback.
    private func decodeOrThrow<T: Decodable>(
        _ type: T.Type, from data: Data, endpoint: String
    ) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodeErr {
            let bodyPreview = String(data: data, encoding: .utf8)?.prefix(500) ?? ""
            print("[APIClient] decode failed \(endpoint): \(decodeErr)\nbody: \(bodyPreview)")
            throw APIError.decodingError(decodeErr)
        }
    }

    func delete(_ endpoint: String) async throws {
        _ = try await request(method: "DELETE", endpoint: endpoint)
    }

    // MARK: - Core Request

    private func request(
        method: String,
        endpoint: String,
        params: [String: String] = [:],
        body: Encodable? = nil
    ) async throws -> Data {
        // Phase 2 (2026-04-13, M-1): dedup concurrent GETs. Same
        // endpoint+params → one URLSession task shared across callers.
        // Never applied to mutations.
        if method == "GET" {
            let key = dedupKey(endpoint: endpoint, params: params)
            if let existing = inFlightGETs[key] {
                return try await existing.value
            }
            let task = Task<Data, Error> { [weak self] in
                guard let self else { throw APIError.unknown("APIClient deallocated") }
                return try await self.performRequest(
                    method: "GET", endpoint: endpoint, params: params
                )
            }
            inFlightGETs[key] = task
            defer { inFlightGETs.removeValue(forKey: key) }
            return try await task.value
        }
        return try await performRequest(
            method: method, endpoint: endpoint, params: params, body: body
        )
    }

    private func dedupKey(endpoint: String, params: [String: String]) -> String {
        let sorted = params.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return "\(endpoint)?\(sorted)"
    }

    private func performRequest(
        method: String,
        endpoint: String,
        params: [String: String] = [:],
        body: Encodable? = nil
    ) async throws -> Data {
        // Build URL
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }

        // Build request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Body
        if let body = body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        // Execute
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        // Handle status codes
        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            let isAuthEndpoint = endpoint.contains("/auth/")
            if !isAuthEndpoint {
                // Attempt token refresh — parallel 401s share the same task
                if let refreshed = await attemptTokenRefresh() {
                    self.authToken = refreshed
                    // Retry the original request once with new token.
                    // Skip the dedup wrapper — we're already inside the
                    // in-flight Task for this GET, and re-entering
                    // `request()` would deadlock awaiting ourselves.
                    return try await performRequest(
                        method: method, endpoint: endpoint, params: params, body: body
                    )
                }
                onUnauthorized?()
            }
            throw APIError.unauthorized
        case 429:
            let message = extractErrorMessage(from: data) ?? "Too many requests. Please try again later."
            throw APIError.rateLimited(message: message)
        case 400..<500:
            let message = extractErrorMessage(from: data) ?? "Client error"
            // Attach parsed JSON body (if any) so callers can inspect typed
            // server codes like NO_PLAYABLE_SLOTS without re-parsing.
            let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw APIError.clientError(
                statusCode: httpResponse.statusCode,
                message: message,
                body: body
            )
        case 500...:
            let message = extractErrorMessage(from: data) ?? "Server error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw APIError.unknown("Unexpected status: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Token Refresh

    private func attemptTokenRefresh() async -> String? {
        // If a refresh is already in-flight, await that same task instead of
        // failing immediately. This prevents the second parallel 401 from
        // throwing unauthorized while the first is still refreshing.
        if let existing = refreshTask {
            return await existing.value
        }

        let task = Task<String?, Never> {
            guard let refreshToken = KeychainManager.shared.refreshToken else { return nil }
            do {
                let result = try await SupabaseAuthClient.shared.refreshToken(refreshToken)
                KeychainManager.shared.saveAccessToken(result.accessToken)
                KeychainManager.shared.saveRefreshToken(result.refreshToken)
                return result.accessToken
            } catch {
                return nil
            }
        }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        return result
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let err = json["error"] as? String ?? json["message"] as? String
            // If server returned a `detail` field (stack summary), surface it
            // alongside the short error string so callers can debug 500s.
            if let err, let detail = json["detail"] as? String, !detail.isEmpty {
                return "\(err): \(detail)"
            }
            return err
        }
        return String(data: data, encoding: .utf8)
    }
}
