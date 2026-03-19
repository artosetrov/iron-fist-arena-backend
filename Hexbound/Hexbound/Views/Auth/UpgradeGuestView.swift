import SwiftUI

/// Full registration screen for upgrading a guest account.
/// Preserves all progress — same Supabase user ID stays.
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

                    // Form
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

                    // Register button
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
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
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

    var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6 && !username.isEmpty
    }

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
}
