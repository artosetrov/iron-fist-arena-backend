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

    // MARK: - Guest Flag

    func saveIsGuest(_ isGuest: Bool) {
        save(isGuest ? "1" : "0", for: AppConstants.keychainIsGuest)
    }

    var isGuest: Bool {
        load(for: AppConstants.keychainIsGuest) == "1"
    }

    // MARK: - Device ID (for guest account persistence)

    /// Stable device identifier used to restore guest progress across
    /// session expiry / reinstall-on-same-device. Lazily generated on
    /// first access and stored in Keychain (survives app deletion via
    /// `kSecAttrAccessibleAfterFirstUnlock`). NEVER cleared by `clearAll()`.
    var deviceId: String {
        if let existing = load(for: AppConstants.keychainDeviceId), !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        save(generated, for: AppConstants.keychainDeviceId)
        return generated
    }

    func saveDeviceId(_ id: String) {
        save(id, for: AppConstants.keychainDeviceId)
    }

    /// Clears tokens and guest flag but PRESERVES deviceId so guest
    /// progress can be restored on the next `guestLogin()` call.
    func clearAll() {
        delete(for: AppConstants.keychainAccessToken)
        delete(for: AppConstants.keychainRefreshToken)
        delete(for: AppConstants.keychainIsGuest)
        // NOTE: deviceId intentionally preserved.
    }

    /// Hard reset — clears everything including deviceId. Use only for
    /// explicit "forget this device" flows (e.g. settings → wipe account).
    func clearAllIncludingDevice() {
        clearAll()
        delete(for: AppConstants.keychainDeviceId)
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
