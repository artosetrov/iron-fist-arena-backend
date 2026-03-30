import SwiftUI
import AuthenticationServices

@MainActor @Observable
final class RegisterViewModel {
    var username = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var errorMessage = ""
    var isLoading = false

    private var authService: AuthService?
    private var appleSignInHelper: AppleSignInHelper?

    func setup(appState: AppState) {
        authService = AuthService(appState: appState)
    }

    // MARK: - Apple Sign In

    func triggerAppleSignIn(appState: AppState) {
        let helper = AppleSignInHelper()
        appleSignInHelper = helper
        helper.signIn { [weak self] result in
            Task { @MainActor in
                await self?.handleAppleSignIn(result: result, appState: appState)
                self?.appleSignInHelper = nil
            }
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>, appState: AppState) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Apple Sign In failed"
                return
            }

            isLoading = true; errorMessage = ""

            do {
                let body: [String: Any] = ["id_token": idToken, "provider": "apple"]
                let data = try await APIClient.shared.postRaw(APIEndpoints.authApple, body: body)

                guard let accessToken = data["access_token"] as? String,
                      let refreshToken = data["refresh_token"] as? String else {
                    isLoading = false; errorMessage = "Invalid server response"
                    return
                }

                KeychainManager.shared.saveAccessToken(accessToken)
                KeychainManager.shared.saveRefreshToken(refreshToken)
                await APIClient.shared.setAuthToken(accessToken)

                let charResult = await authService?.loadCharactersPublic() ?? .noCharacter

                isLoading = false
                switch charResult {
                case .hasCharacter, .multipleCharacters, .noCharacter:
                    appState.currentScreen = .characterSelect
                case .noTokens:
                    break
                }
            } catch {
                isLoading = false
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In

    func handleGoogleSignIn(appState: AppState) async {
        isLoading = true; errorMessage = ""

        do {
            let googleResult = try await GoogleSignInHelper.signIn()

            let body: [String: Any] = [
                "id_token": googleResult.idToken,
                "access_token": googleResult.accessToken,
                "provider": "google"
            ]
            let data = try await APIClient.shared.postRaw(APIEndpoints.authGoogle, body: body)

            guard let accessToken = data["access_token"] as? String,
                  let refreshToken = data["refresh_token"] as? String else {
                isLoading = false; errorMessage = "Invalid server response"
                return
            }

            KeychainManager.shared.saveAccessToken(accessToken)
            KeychainManager.shared.saveRefreshToken(refreshToken)
            await APIClient.shared.setAuthToken(accessToken)

            let charResult = await authService?.loadCharactersPublic() ?? .noCharacter

            isLoading = false
            switch charResult {
            case .hasCharacter, .multipleCharacters, .noCharacter:
                appState.currentScreen = .characterSelect
            case .noTokens:
                break
            }
        } catch {
            isLoading = false
            let nsError = error as NSError
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                return // user cancelled
            }
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
        }
    }

    func register(appState: AppState) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = ""

        // Auto-generate username from email prefix (hero name is set later in onboarding)
        let autoUsername = email.split(separator: "@").first.map(String.init) ?? "player"

        let result = await authService?.register(
            email: email,
            password: password,
            username: autoUsername
        )

        isLoading = false
        switch result {
        case .success(let needsConfirmation):
            if needsConfirmation {
                errorMessage = "Check your email to confirm your account."
            } else {
                // Go to onboarding to create character
                appState.authPath.append(AppRoute.onboarding)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .none:
            errorMessage = "Registration failed"
        }
    }

    private func validate() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            errorMessage = "Please enter a valid email"
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        if password != confirmPassword {
            errorMessage = "Passwords don't match"
            return false
        }
        return true
    }
}
