import SwiftUI
import AuthenticationServices

/// Full registration screen for upgrading a guest account.
/// Supports email/password, Google, and Apple sign-in.
/// Preserves all progress — character data is transferred to the new identity.
struct UpgradeGuestView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = UpgradeGuestViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    // Header
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 44)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.gold)

                        Text("SAVE YOUR PROGRESS")
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text("Create an account to keep your character,\ninventory, and all progress forever.")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, LayoutConstants.spaceLG)

                    // OAuth buttons — Apple & Google
                    VStack(spacing: LayoutConstants.spaceMD) {
                        // Apple Sign In — programmatic
                        Button {
                            vm.triggerAppleSignIn(appState: appState)
                        } label: {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 22, weight: .medium))
                                Text("CONTINUE WITH APPLE")
                                    .font(DarkFantasyTheme.title(size: LayoutConstants.textBody))
                            }
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightLG)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .fill(DarkFantasyTheme.bgSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                        }
                        .disabled(vm.isLoading)
                        .accessibilityLabel("Continue with Apple")

                        // Google Sign In
                        Button {
                            Task { await vm.handleGoogleSignIn(appState: appState) }
                        } label: {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Text("G")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                Text("CONTINUE WITH GOOGLE")
                                    .font(DarkFantasyTheme.title(size: LayoutConstants.textBody))
                            }
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightLG)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .fill(DarkFantasyTheme.bgSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isLoading)
                        .accessibilityLabel("Continue with Google")
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // Divider — "OR"
                    HStack(spacing: LayoutConstants.spaceMD) {
                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                        Text("OR")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .tracking(1)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .fixedSize()
                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // Email/Password Form
                    VStack(spacing: LayoutConstants.spaceMD) {
                        // Email
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                            Text("Email")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)

                            TextField("", text: $vm.email)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .frame(height: LayoutConstants.buttonHeightMD)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .fill(DarkFantasyTheme.bgTertiary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                                )
                        }

                        // Username
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                            Text("Username")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)

                            TextField("", text: $vm.username)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .frame(height: LayoutConstants.buttonHeightMD)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .fill(DarkFantasyTheme.bgTertiary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                                )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                            Text("Password")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)

                            SecureField("", text: $vm.password)
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                                .textContentType(.newPassword)
                                .padding(.horizontal, LayoutConstants.spaceSM)
                                .frame(height: LayoutConstants.buttonHeightMD)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .fill(DarkFantasyTheme.bgTertiary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                                )

                            if vm.password.count > 0 && vm.password.count < 6 {
                                Text("Minimum 6 characters")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                    .foregroundStyle(DarkFantasyTheme.danger)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // Error message
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.danger)
                            .padding(.horizontal, LayoutConstants.screenPadding)
                    }

                    // Register button (email/password)
                    Button {
                        Task { await vm.upgrade(appState: appState) }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text("CREATE ACCOUNT")
                        }
                    }
                    .buttonStyle(.primary(enabled: vm.isValid))
                    .disabled(!vm.isValid || vm.isLoading)
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    // Reassurance
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14)) // SF Symbol icon — keep as is
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                        Text("All your progress will be kept")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textSuccess)
                    }
                }
                .padding(.bottom, LayoutConstants.spaceLG)
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("REGISTER")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor @Observable
final class UpgradeGuestViewModel {
    var email = ""
    var username = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    private var appleSignInHelper: AppleSignInHelper?

    var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6 && !username.isEmpty
    }

    // MARK: - Email/Password Upgrade

    func upgrade(appState: AppState) async {
        guard isValid else { return }
        isLoading = true
        errorMessage = nil

        do {
            let body: [String: Any] = [
                "email": email,
                "password": password,
                "username": username,
            ]
            let result = try await APIClient.shared.postRaw(APIEndpoints.authUpgradeGuest, body: body)

            // Save new tokens
            if let accessToken = result["access_token"] as? String,
               let refreshToken = result["refresh_token"] as? String {
                KeychainManager.shared.saveAccessToken(accessToken)
                KeychainManager.shared.saveRefreshToken(refreshToken)
                await APIClient.shared.setAuthToken(accessToken)
            }

            // No longer a guest
            appState.isGuest = false
            appState.showToast("Account created!", subtitle: "Your progress is now saved forever", type: .reward)

            // Pop back to settings
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
        } catch let error as APIError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
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

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, appState: AppState) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Apple Sign In failed"
                return
            }

            await upgradeWithOAuth(
                idToken: idToken,
                accessToken: nil,
                provider: "apple",
                appState: appState
            )

        case .failure(let error):
            // User cancelled — don't show error for cancellation
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In

    func handleGoogleSignIn(appState: AppState) async {
        do {
            let googleResult = try await GoogleSignInHelper.signIn()
            await upgradeWithOAuth(
                idToken: googleResult.idToken,
                accessToken: googleResult.accessToken,
                provider: "google",
                appState: appState
            )
        } catch {
            // Don't show error if user cancelled
            let nsError = error as NSError
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                return // user cancelled
            }
            errorMessage = "Google Sign In failed: \(error.localizedDescription)"
        }
    }

    // MARK: - OAuth Upgrade (shared)

    private func upgradeWithOAuth(
        idToken: String,
        accessToken: String?,
        provider: String,
        appState: AppState
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            var body: [String: Any] = [
                "id_token": idToken,
                "provider": provider,
            ]
            if let accessToken {
                body["access_token"] = accessToken
            }

            let result = try await APIClient.shared.postRaw(
                APIEndpoints.authUpgradeGuestOAuth,
                body: body
            )

            // Save new tokens from OAuth session
            guard let newAccessToken = result["access_token"] as? String,
                  let newRefreshToken = result["refresh_token"] as? String else {
                errorMessage = "Invalid server response"
                isLoading = false
                return
            }

            KeychainManager.shared.saveAccessToken(newAccessToken)
            KeychainManager.shared.saveRefreshToken(newRefreshToken)
            await APIClient.shared.setAuthToken(newAccessToken)

            // No longer a guest
            appState.isGuest = false
            appState.showToast(
                "Account linked!",
                subtitle: "Your progress is now saved forever",
                type: .reward
            )

            // Pop back to settings
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
        } catch let error as APIError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}
