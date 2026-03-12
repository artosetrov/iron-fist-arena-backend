import Foundation

actor SupabaseAuthClient {
    static let shared = SupabaseAuthClient()

    private let authURL: String
    private let anonKey: String
    private let session: URLSession

    private init() {
        self.authURL = AppConstants.supabaseAuthURL
        self.anonKey = AppConstants.supabaseAnonKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - Token Refresh

    func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, refreshToken: String, expiresIn: Int) {
        let url = URL(string: "\(authURL)/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unauthorized
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String else {
            throw APIError.noData
        }

        let expiresIn = json["expires_in"] as? Int ?? 3600
        return (accessToken, newRefreshToken, expiresIn)
    }

    // MARK: - Token Validation

    func getUser(accessToken: String) async throws -> [String: Any] {
        let url = URL(string: "\(authURL)/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unauthorized
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.noData
        }
        return json
    }

    // MARK: - Anonymous Sign In

    func signInAnonymous() async throws -> (accessToken: String, refreshToken: String, user: [String: Any]) {
        let url = URL(string: "\(authURL)/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = ["data": [:] as [String: Any]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.clientError(statusCode: 400, message: "Anonymous sign-in failed")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any] else {
            throw APIError.noData
        }

        return (accessToken, refreshToken, user)
    }
}
