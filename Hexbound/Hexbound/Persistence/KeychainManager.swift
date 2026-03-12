import Foundation
import Security

final class KeychainManager: Sendable {
    static let shared = KeychainManager()
    private let service = "com.ironfist.arena"

    private init() {}

    // MARK: - Token Helpers

    func saveAccessToken(_ token: String) {
        save(token, for: AppConstants.keychainAccessToken)
    }

    func saveRefreshToken(_ token: String) {
        save(token, for: AppConstants.keychainRefreshToken)
    }

    var accessToken: String? {
        load(for: AppConstants.keychainAccessToken)
    }

    var refreshToken: String? {
        load(for: AppConstants.keychainRefreshToken)
    }

    func clearAll() {
        delete(for: AppConstants.keychainAccessToken)
        delete(for: AppConstants.keychainRefreshToken)
    }

    // MARK: - Generic Keychain Operations

    func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
