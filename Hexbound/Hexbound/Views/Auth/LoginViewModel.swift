import SwiftUI
import AuthenticationServices

@MainActor @Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var isLoading = false
    var showEmailConfirmation = false
    var showForgotPassword = false
    var forgotEmail = ""

    private var authService: AuthService?

    func setup(appState: AppState) {
        authService = AuthService(appState: appState)
    }

    func login(appState: AppState) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = ""

        let result = await authService?.login(email: email, password: password)
        isLoading = false
        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
        }
    }

    func guestLogin(appState: AppState) async {
        isLoading = true
        errorMessage = ""

        let result = await authService?.guestLogin()
        isLoading = false
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        default:
            // Navigate to onboarding for guest
            appState.mainPath.append(AppRoute.onboarding)
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, appState: AppState) async {
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

                let hasCharacter = await authService?.loadCharacterPublic() ?? false

                isLoading = false
                appState.isAuthenticated = true
                if !hasCharacter {
                    appState.authPath.append(AppRoute.onboarding)
                }
            } catch {
                isLoading = false
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User cancelled — don't show error for cancellation
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    func sendPasswordReset(appState: AppState) async {
        let trimmed = forgotEmail.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed.contains("@") else {
            errorMessage = "Please enter a valid email"
            return
        }

        let result = await authService?.forgotPassword(email: trimmed)
        switch result {
        case .success:
            appState.showToast("Password reset email sent", type: .info)
            forgotEmail = ""
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .none:
            errorMessage = "Failed to send reset email"
        }
    }

    #if DEBUG
    func devLogin(appState: AppState) async {
        // Try Xcode scheme environment variables first, then fall back to text fields
        let devEmail = ProcessInfo.processInfo.environment["DEV_EMAIL"] ?? email
        let devPassword = ProcessInfo.processInfo.environment["DEV_PASSWORD"] ?? password

        guard !devEmail.isEmpty, !devPassword.isEmpty else {
            errorMessage = "Set DEV_EMAIL / DEV_PASSWORD in Xcode Scheme, or type credentials above"
            return
        }

        email = devEmail
        password = devPassword
        isLoading = true
        errorMessage = ""

        let result = await authService?.login(email: devEmail, password: devPassword)
        isLoading = false
        if case .failure(let error) = result {
            errorMessage = error.localizedDescription
        }
    }
    #endif

    private func validate() -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        if password.isEmpty {
            errorMessage = "Please enter your password"
            return false
        }
        return true
    }
}
