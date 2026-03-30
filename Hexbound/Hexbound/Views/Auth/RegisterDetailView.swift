import SwiftUI
import AuthenticationServices

struct RegisterDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = RegisterViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.space2XL)

                    // Header
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text("CREATE ACCOUNT")
                            .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text("Join the Arena")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .padding(.bottom, LayoutConstants.spaceMD)

                    // Form
                    VStack(spacing: LayoutConstants.spaceMD) {
                        StyledTextField(
                            placeholder: "Email",
                            text: $vm.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        StyledSecureField(
                            placeholder: "Password (6+ chars)",
                            text: $vm.password,
                            icon: "lock.fill"
                        )

                        StyledSecureField(
                            placeholder: "Confirm Password",
                            text: $vm.confirmPassword,
                            icon: "lock.fill"
                        )
                    }

                    // Register Button
                    Button {
                        Task { await vm.register(appState: appState) }
                    } label: {
                        Text("CREATE ACCOUNT")
                    }
                    .buttonStyle(.primary(enabled: !vm.isLoading))
                    .disabled(vm.isLoading)
                    .accessibilityLabel("Create account")

                    // Social divider
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

                    // Social auth row — matching WelcomeView
                    HStack(spacing: LayoutConstants.spaceMD) {
                        // Apple
                        Button {
                            vm.triggerAppleSignIn(appState: appState)
                        } label: {
                            HStack(spacing: LayoutConstants.spaceSM) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Apple")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
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
                        .accessibilityLabel("Sign up with Apple")

                        // Google
                        ZStack {
                            Button {
                                Task { await vm.handleGoogleSignIn(appState: appState) }
                            } label: {
                                Color.clear
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            HStack(spacing: LayoutConstants.spaceSM) {
                                Text("G")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text("Google")
                                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            }
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .allowsHitTesting(false)
                        }
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
                        .contentShape(Rectangle())
                        .accessibilityLabel("Sign up with Google")
                    }

                    // Back to login
                    Button("Already have an account? LOG IN") {
                        if !appState.authPath.isEmpty { appState.authPath.removeLast() }
                    }
                    .buttonStyle(.ghost)
                    .accessibilityLabel("Go to login")

                    // Error
                    if !vm.errorMessage.isEmpty {
                        Text(vm.errorMessage)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(
                                vm.errorMessage.contains("Check your email")
                                    ? DarkFantasyTheme.textSuccess
                                    : DarkFantasyTheme.textDanger
                            )
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Spacer()
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton {
                    if !appState.authPath.isEmpty {
                        appState.authPath.removeLast()
                    }
                }
            }
        }
        .onAppear { vm.setup(appState: appState) }
    }
}
