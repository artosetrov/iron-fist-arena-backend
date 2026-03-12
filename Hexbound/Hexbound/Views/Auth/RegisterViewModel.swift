import SwiftUI

@MainActor @Observable
final class RegisterViewModel {
    var username = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var errorMessage = ""
    var isLoading = false

    private var authService: AuthService?

    func setup(appState: AppState) {
        authService = AuthService(appState: appState)
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
