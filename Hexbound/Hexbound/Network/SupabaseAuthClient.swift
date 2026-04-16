import Foundation

actor SupabaseAuthClient {
    static let shared = SupabaseAuthClient()

    private let authURL: String
    private let anonKey: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.authURL = AppConstants.supabaseAuthURL
        self.anonKey = AppConstants.supabaseAnonKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Token Refresh

    func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, refreshToken: String, expiresIn: Int) {
        guard let url = URL(string: "\(authURL)/token?grant_type=refresh_token") else {
            throw APIError.clientError(statusCode: 0, message: "Invalid auth URL", body: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        request.httpBody = try encoder.encode(SupabaseRefreshTokenRequest(refreshToken: refreshToken))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unauthorized
        }

        let payload = try decodeResponse(SupabaseSessionResponse.self, from: data)
        guard let accessToken = payload.accessToken,
              let newRefreshToken = payload.refreshToken else {
            throw APIError.noData
        }

        let expiresIn = payload.expiresIn ?? 3600
        return (accessToken, newRefreshToken, expiresIn)
    }

    // MARK: - Token Validation

    func getUser(accessToken: String) async throws -> SupabaseUserResponse {
        guard let url = URL(string: "\(authURL)/user") else {
            throw APIError.clientError(statusCode: 0, message: "Invalid auth URL", body: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unauthorized
        }

        return try decodeResponse(SupabaseUserResponse.self, from: data)
    }

    // MARK: - Resend Confirmation Email

    func resendConfirmation(email: String) async throws {
        guard let url = URL(string: "\(authURL)/resend") else {
            throw APIError.clientError(statusCode: 0, message: "Invalid auth URL", body: nil)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        request.httpBody = try encoder.encode(SupabaseResendConfirmationRequest(type: "signup", email: email))

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.clientError(statusCode: 400, message: "Failed to resend confirmation", body: nil)
        }
    }

    private func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

private struct SupabaseRefreshTokenRequest: Encodable {
    let refreshToken: String
}

private struct SupabaseResendConfirmationRequest: Encodable {
    let type: String
    let email: String
}

struct SupabaseUserResponse: Decodable {
    let id: String
    let email: String?
}

private struct SupabaseSessionResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: SupabaseUserResponse?
}
