import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited(message: String)
    case serverError(statusCode: Int, message: String)
    case clientError(statusCode: Int, message: String)
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
        case .clientError(_, let message):
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
