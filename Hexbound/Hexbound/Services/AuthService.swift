import Foundation

enum AutoLoginResult {
    case noTokens
    case hasCharacter        // exactly 1 hero, auto-selected
    case multipleCharacters  // 2+ heroes, needs selection screen
    case noCharacter         // 0 heroes
}

@MainActor
final class AuthService {
    private let appState: AppState
    private var cache: GameDataCache?

    init(appState: AppState, cache: GameDataCache? = nil) {
        self.appState = appState
        self.cache = cache
    }

    // MARK: - Login

    func login(email: String, password: String) async -> Result<Void, APIError> {
        do {
            let body: [String: Any] = ["email": email, "password": password]
            let result = try await APIClient.shared.postRaw(APIEndpoints.authLogin, body: body)

            guard let accessToken = result["access_token"] as? String,
                  let refreshToken = result["refresh_token"] as? String else {
                return .failure(.noData)
            }

            // Save tokens
            KeychainManager.shared.saveAccessToken(accessToken)
            KeychainManager.shared.saveRefreshToken(refreshToken)
            KeychainManager.shared.saveIsGuest(false)
            await APIClient.shared.setAuthToken(accessToken)

            // Not a guest
            appState.isGuest = false

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Load characters and route appropriately
            // Fresh login always goes to character selection
            // (auto-login on app restart handles the "skip to hub" path)
            _ = await loadCharacters()
            appState.currentScreen = .characterSelect

            return .success(())
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Register

    func register(email: String, password: String, username: String) async -> Result<Bool, APIError> {
        do {
            let body: [String: Any] = ["email": email, "password": password, "username": username]
            let result = try await APIClient.shared.postRaw(APIEndpoints.authRegister, body: body)

            let needsConfirmation = result["needs_confirmation"] as? Bool ?? false

            if !needsConfirmation {
                // Auto-login after register
                guard let accessToken = result["access_token"] as? String,
                      let refreshToken = result["refresh_token"] as? String else {
                    return .failure(.noData)
                }
                KeychainManager.shared.saveAccessToken(accessToken)
                KeychainManager.shared.saveRefreshToken(refreshToken)
                await APIClient.shared.setAuthToken(accessToken)

                // Setup 401 handler
                setupUnauthorizedHandler()

                // Do NOT set isAuthenticated here — new account has no character.
                // RegisterViewModel will append .onboarding, and OnboardingViewModel
                // sets isAuthenticated = true after character creation.
            }

            return .success(needsConfirmation)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Guest Login

    func guestLogin() async -> Result<Void, APIError> {
        do {
            let result = try await APIClient.shared.postRaw(APIEndpoints.authGuestLogin)

            guard let accessToken = result["access_token"] as? String,
                  let refreshToken = result["refresh_token"] as? String else {
                return .failure(.noData)
            }

            KeychainManager.shared.saveAccessToken(accessToken)
            KeychainManager.shared.saveRefreshToken(refreshToken)
            KeychainManager.shared.saveIsGuest(true)
            await APIClient.shared.setAuthToken(accessToken)

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Mark as guest
            appState.isGuest = true

            // Load characters and route appropriately
            let charResult = await loadCharacters()
            switch charResult {
            case .hasCharacter:
                if let cache = cache {
                    let initService = GameInitService(appState: appState, cache: cache)
                    await initService.loadGameData()
                }
                appState.currentScreen = .game
            case .multipleCharacters:
                appState.currentScreen = .characterSelect
            case .noCharacter:
                appState.currentScreen = .characterSelect
            case .noTokens:
                break
            }

            return .success(())
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Auto Login

    func tryAutoLogin() async -> AutoLoginResult {
        // Try refresh token first
        guard let refreshToken = KeychainManager.shared.refreshToken else {
            return .noTokens
        }

        // Restore guest flag from Keychain
        appState.isGuest = KeychainManager.shared.isGuest

        do {
            let result = try await SupabaseAuthClient.shared.refreshToken(refreshToken)

            // Save new tokens
            KeychainManager.shared.saveAccessToken(result.accessToken)
            KeychainManager.shared.saveRefreshToken(result.refreshToken)
            await APIClient.shared.setAuthToken(result.accessToken)

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Load characters (multi-hero)
            let characterResult = await loadCharacters()
            return characterResult
        } catch {
            // Try validating existing access token
            if let accessToken = KeychainManager.shared.accessToken {
                do {
                    _ = try await SupabaseAuthClient.shared.getUser(accessToken: accessToken)
                    await APIClient.shared.setAuthToken(accessToken)

                    // Setup 401 handler on fallback path too
                    setupUnauthorizedHandler()

                    let characterResult = await loadCharacters()
                    return characterResult
                } catch {
                    // Token invalid
                    KeychainManager.shared.clearAll()
                    appState.isGuest = false
                    return .noTokens
                }
            }
            KeychainManager.shared.clearAll()
            appState.isGuest = false
            return .noTokens
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async -> Result<Void, APIError> {
        do {
            let body: [String: Any] = ["email": email]
            _ = try await APIClient.shared.postRaw(APIEndpoints.authForgotPassword, body: body)
            return .success(())
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - Load Characters (public accessor for Apple/Google Sign In)

    /// Returns the auto-login result for use by external callers (LoginViewModel).
    func loadCharactersPublic() async -> AutoLoginResult {
        setupUnauthorizedHandler()
        return await loadCharacters()
    }

    /// Legacy accessor — returns true if single character was auto-selected.
    func loadCharacterPublic() async -> Bool {
        let result = await loadCharacters()
        return result == .hasCharacter
    }

    // MARK: - Logout

    func logout() async {
        await APIClient.shared.clearAuthToken()
        appState.logout()
    }

    // MARK: - Private

    private func setupUnauthorizedHandler() {
        Task {
            await APIClient.shared.setOnUnauthorized { [weak appState] in
                Task { @MainActor in
                    // Show blocking modal instead of silent logout — user sees what happened
                    appState?.triggerSessionExpired()
                }
            }
        }
    }

    /// Load all characters for the user and determine navigation result.
    /// If exactly 1 character, auto-selects it on appState.
    /// If 2+, stores them on appState.userCharacters for selection screen.
    private func loadCharacters() async -> AutoLoginResult {
        do {
            let result = try await APIClient.shared.getRaw(APIEndpoints.characters)

            // Parse character array from API response
            var charArray: [[String: Any]] = []
            if let characters = result["characters"] as? [[String: Any]] {
                charArray = characters
            } else if let data = result["data"] as? [[String: Any]] {
                charArray = data
            } else if result["id"] != nil {
                charArray = [result]
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            var decoded: [Character] = []
            for charData in charArray {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                if let character = try? decoder.decode(Character.self, from: jsonData) {
                    decoded.append(character)
                }
            }

            // Sort by level descending
            decoded.sort { $0.level > $1.level }
            appState.userCharacters = decoded

            switch decoded.count {
            case 0:
                return .noCharacter
            case 1:
                // Auto-select the single hero
                appState.currentCharacter = decoded[0]
                return .hasCharacter
            default:
                // 2+ heroes — need selection screen
                return .multipleCharacters
            }
        } catch {
            #if DEBUG
            print("[AuthService] loadCharacters failed: \(error)")
            #endif
            return .noCharacter
        }
    }

    /// Legacy single-character loader (used by loadCharacterPublic)
    @discardableResult
    private func loadCharacter() async -> Bool {
        let result = await loadCharacters()
        return result == .hasCharacter
    }
}

extension APIClient {
    func setOnUnauthorized(_ handler: @escaping @Sendable () -> Void) {
        onUnauthorized = handler
    }
}
