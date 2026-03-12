import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = AppConstants.apiBaseURL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var authToken: String?
    private var isRefreshing = false

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
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable>(_ endpoint: String, body: Encodable? = nil) async throws -> T {
        let data = try await request(method: "POST", endpoint: endpoint, body: body)
        return try decoder.decode(T.self, from: data)
    }

    func patch<T: Decodable>(_ endpoint: String, body: Encodable? = nil) async throws -> T {
        let data = try await request(method: "PATCH", endpoint: endpoint, body: body)
        return try decoder.decode(T.self, from: data)
    }

    func delete(_ endpoint: String) async throws {
        _ = try await request(method: "DELETE", endpoint: endpoint)
    }

    // MARK: - Raw Requests (for dynamic/untyped responses)

    func getRaw(_ endpoint: String, params: [String: String] = [:]) async throws -> [String: Any] {
        let data = try await request(method: "GET", endpoint: endpoint, params: params)
        return try parseJSON(data)
    }

    func postRaw(_ endpoint: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        let data = try await request(method: "POST", endpoint: endpoint, rawBody: body)
        return try parseJSON(data)
    }

    func patchRaw(_ endpoint: String, body: [String: Any] = [:]) async throws -> [String: Any] {
        let data = try await request(method: "PATCH", endpoint: endpoint, rawBody: body)
        return try parseJSON(data)
    }

    // MARK: - Core Request

    private func request(
        method: String,
        endpoint: String,
        params: [String: String] = [:],
        body: Encodable? = nil,
        rawBody: [String: Any]? = nil
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
        } else if let rawBody = rawBody {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: rawBody)
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
            if !isAuthEndpoint && !isRefreshing {
                // Attempt token refresh before logout
                if let refreshed = await attemptTokenRefresh() {
                    self.authToken = refreshed
                    // Retry the original request once with new token
                    return try await request(
                        method: method, endpoint: endpoint,
                        params: params, body: body, rawBody: rawBody
                    )
                }
                onUnauthorized?()
            }
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        case 400..<500:
            let message = extractErrorMessage(from: data) ?? "Client error"
            throw APIError.clientError(statusCode: httpResponse.statusCode, message: message)
        case 500...:
            let message = extractErrorMessage(from: data) ?? "Server error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        default:
            throw APIError.unknown("Unexpected status: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Token Refresh

    private func attemptTokenRefresh() async -> String? {
        guard !isRefreshing else { return nil }
        isRefreshing = true
        defer { isRefreshing = false }

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

    // MARK: - Helpers

    private func parseJSON(_ data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.noData
        }
        return json
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json["error"] as? String ?? json["message"] as? String
        }
        return String(data: data, encoding: .utf8)
    }
}
