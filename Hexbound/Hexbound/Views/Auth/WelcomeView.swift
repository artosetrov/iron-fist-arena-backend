import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = LoginViewModel()

    var body: some View {
        ZStack {
            AuthBackground()

            VStack(spacing: 0) {
                Spacer()

                // 1. Branding
                Image("hexbound-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280)

                Spacer()

                // 2. Actions — hug the bottom
                VStack(spacing: LayoutConstants.spaceLG) {
                    // PLAY — hero CTA. One tap = in the game.
                    Button {
                        SFXManager.shared.play(.uiConfirm)
                        Task { await vm.guestLogin(appState: appState) }
                    } label: {
                        Text("PLAY")
                    }
                    .buttonStyle(.primary(enabled: !vm.isLoading))
                    .disabled(vm.isLoading)
                    .accessibilityLabel("Play now, no account needed")

                    // Social divider
                    HStack(spacing: LayoutConstants.spaceMD) {
                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                        Text("OR CONTINUE WITH")
                            .font(DarkFantasyTheme.body)
                            .tracking(1)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                            .fixedSize()
                        Rectangle()
                            .fill(DarkFantasyTheme.borderSubtle)
                            .frame(height: 1)
                    }

                    // Social auth row — consistent background on both buttons
                    HStack(spacing: LayoutConstants.spaceMD) {
                        // Apple — programmatic sign in via regular Button
                        Button {
                            SFXManager.shared.play(.uiTap)
                            vm.triggerAppleSignIn(appState: appState)
                        } label: {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Image(systemName: "apple.logo")
                                    .font(DarkFantasyTheme.section.weight(.medium))
                                Text("Apple")
                                    .font(DarkFantasyTheme.cardTitle.weight(.semibold))
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
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sign in with Apple")

                        // Google
                        Button {
                            SFXManager.shared.play(.uiTap)
                            Task { await vm.handleGoogleSignIn(appState: appState) }
                        } label: {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Text("G")
                                    .font(DarkFantasyTheme.googleLogo)
                                Text("Google")
                                    .font(DarkFantasyTheme.cardTitle.weight(.semibold))
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
                        .buttonStyle(.plain)
                        .accessibilityLabel("Sign in with Google")
                    }

                    // Email auth — text links (sign up / log in). No more duplicate social row.
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Button("Sign up with email →") {
                            SFXManager.shared.play(.uiTap)
                            appState.authPath.append(AppRoute.register)
                        }
                        .buttonStyle(.ghost)
                        .accessibilityLabel("Sign up with email")

                        Button("Already have an account? Log in") {
                            SFXManager.shared.play(.uiTap)
                            appState.authPath.append(AppRoute.login)
                        }
                        .buttonStyle(.ghost)
                        .accessibilityLabel("Log in to existing account")
                    }
                    .padding(.top, LayoutConstants.spaceXS)

                    // Guest warning
                    Text("сделано в Osetrov Design")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.authBottomInset)

                // Error
                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LayoutConstants.screenPadding)
                        .padding(.bottom, LayoutConstants.spaceMD)
                        .transition(.opacity)
                }
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.setup(appState: appState)
            AudioManager.shared.playBGM("main-theme.mp3")
        }
    }
}
