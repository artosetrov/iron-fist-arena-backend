import Foundation

enum AutoLoginResult {
    case noTokens
    case hasCharacter
    case noCharacter
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
            await APIClient.shared.setAuthToken(accessToken)

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Load character first
            let hasCharacter = await loadCharacter()

            if hasCharacter {
                // Load game data (inventory, quests, daily login, config)
                if let cache = cache {
                    let initService = GameInitService(appState: appState, cache: cache)
                    await initService.loadGameData()
                }
                appState.isAuthenticated = true
            } else {
                // No character — stay on AuthRouterView, navigate to onboarding.
                // OnboardingViewModel sets isAuthenticated after character creation.
                appState.authPath.append(AppRoute.onboarding)
            }

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
            await APIClient.shared.setAuthToken(accessToken)

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Load character (guest may already have one)
            let hasCharacter = await loadCharacter()

            if hasCharacter, let cache = cache {
                let initService = GameInitService(appState: appState, cache: cache)
                await initService.loadGameData()
                appState.isAuthenticated = true
            } else {
                // No character — stay on AuthRouterView, navigate to onboarding.
                // OnboardingViewModel sets isAuthenticated after character creation.
                appState.authPath.append(AppRoute.onboarding)
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

        do {
            let result = try await SupabaseAuthClient.shared.refreshToken(refreshToken)

            // Save new tokens
            KeychainManager.shared.saveAccessToken(result.accessToken)
            KeychainManager.shared.saveRefreshToken(result.refreshToken)
            await APIClient.shared.setAuthToken(result.accessToken)

            // Setup 401 handler
            setupUnauthorizedHandler()

            // Load character
            let hasCharacter = await loadCharacter()
            return hasCharacter ? .hasCharacter : .noCharacter
        } catch {
            // Try validating existing access token
            if let accessToken = KeychainManager.shared.accessToken {
                do {
                    _ = try await SupabaseAuthClient.shared.getUser(accessToken: accessToken)
                    await APIClient.shared.setAuthToken(accessToken)

                    // Setup 401 handler on fallback path too
                    setupUnauthorizedHandler()

                    let hasCharacter = await loadCharacter()
                    return hasCharacter ? .hasCharacter : .noCharacter
                } catch {
                    // Token invalid
                    KeychainManager.shared.clearAll()
                    return .noTokens
                }
            }
            KeychainManager.shared.clearAll()
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

    // MARK: - Load Character (public accessor for Apple Sign In)

    func loadCharacterPublic() async -> Bool {
        return await loadCharacter()
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
                    appState?.logout()
                }
            }
        }
    }

    @discardableResult
    private func loadCharacter() async -> Bool {
        do {
            let result = try await APIClient.shared.getRaw(APIEndpoints.characters)

            // API returns array or single character
            var charData: [String: Any]?
            if let characters = result["characters"] as? [[String: Any]], let first = characters.first {
                charData = first
            } else if let data = result["data"] as? [[String: Any]], let first = data.first {
                charData = first
            } else if result["id"] != nil {
                charData = result
            }

            if let charData = charData {
                let jsonData = try JSONSerialization.data(withJSONObject: charData)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let character = try decoder.decode(Character.self, from: jsonData)
                appState.currentCharacter = character
                return true
            }
            return false
        } catch {
            #if DEBUG
            print("[AuthService] loadCharacter failed: \(error)")
            #endif
            return false
        }
    }
}

extension APIClient {
    func setOnUnauthorized(_ handler: @escaping @Sendable () -> Void) {
        onUnauthorized = handler
    }
}
