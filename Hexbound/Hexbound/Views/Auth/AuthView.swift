import SwiftUI

// MARK: - Auth Mode

enum AuthMode: Hashable {
    case signin
    case signup

    var headerTitle: String {
        switch self {
        case .signin: return "LOG IN"
        case .signup: return "CREATE ACCOUNT"
        }
    }

    var headerSubtitle: String {
        switch self {
        case .signin: return "Welcome back, warrior"
        case .signup: return "Join the Arena"
        }
    }

    var ctaLabel: String {
        switch self {
        case .signin: return "LOG IN"
        case .signup: return "CREATE ACCOUNT"
        }
    }

    var passwordPlaceholder: String {
        switch self {
        case .signin: return "Password"
        case .signup: return "Password (6+ chars)"
        }
    }
}

// MARK: - Unified Auth View

/// Unified Log in / Sign up screen. Replaces the old LoginView + RegisterDetailView
/// split. Driven by a tab toggle at the top so the user can switch modes without
/// leaving the screen. No social auth here — Apple / Google live on WelcomeView only.
struct AuthView: View {
    @Environment(AppState.self) private var appState

    @State private var mode: AuthMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var loginVM = LoginViewModel()
    @State private var registerVM = RegisterViewModel()

    init(initialMode: AuthMode) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    Spacer().frame(height: LayoutConstants.space2XL)

                    // Header
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text(mode.headerTitle)
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.goldBright)

                        Text(mode.headerSubtitle)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .padding(.bottom, LayoutConstants.spaceXS)

                    // Mode toggle — two ghost labels with gold underline on active
                    HStack(spacing: LayoutConstants.spaceLG) {
                        modeToggleButton(label: "LOG IN", target: .signin)
                        modeToggleButton(label: "SIGN UP", target: .signup)
                    }

                    // Form
                    VStack(spacing: LayoutConstants.spaceMD) {
                        StyledTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )
                        .accessibilityLabel("Email address")

                        StyledSecureField(
                            placeholder: mode.passwordPlaceholder,
                            text: $password,
                            icon: "lock.fill"
                        )
                        .accessibilityLabel("Password")

                        if mode == .signup {
                            StyledSecureField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                icon: "lock.fill"
                            )
                            .accessibilityLabel("Confirm password")
                            .transition(.opacity)
                        }
                    }

                    // Primary CTA
                    Button {
                        SFXManager.shared.play(.uiConfirm)
                        submit()
                    } label: {
                        Text(mode.ctaLabel)
                    }
                    .buttonStyle(.primary(enabled: !isLoading))
                    .disabled(isLoading)
                    .accessibilityLabel(mode.ctaLabel)

                    // Error / status message
                    if !currentMessage.isEmpty {
                        Text(currentMessage)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(
                                currentMessage.contains("Check your email")
                                    ? DarkFantasyTheme.textSuccess
                                    : DarkFantasyTheme.textDanger
                            )
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    // Forgot password link — sign in only
                    if mode == .signin {
                        Button("Forgot Password?") {
                            SFXManager.shared.play(.uiTap)
                            loginVM.forgotEmail = email
                            loginVM.showForgotPassword = true
                        }
                        .buttonStyle(.ghost)
                        .accessibilityLabel("Reset your password")
                        .padding(.top, LayoutConstants.spaceXS)
                    }

                    Spacer()
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.authBottomInset)
            }

            if isLoading {
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
        .onAppear {
            loginVM.setup(appState: appState)
            registerVM.setup(appState: appState)
        }
        .alert("Reset Password", isPresented: $loginVM.showForgotPassword) {
            TextField("Email", text: $loginVM.forgotEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Link") {
                Task { await loginVM.sendPasswordReset(appState: appState) }
            }
        } message: {
            Text("Enter your email and we'll send a password reset link.")
        }
    }

    // MARK: - Derived State

    private var isLoading: Bool {
        loginVM.isLoading || registerVM.isLoading
    }

    private var currentMessage: String {
        mode == .signin ? loginVM.errorMessage : registerVM.errorMessage
    }

    // MARK: - Actions

    private func submit() {
        switch mode {
        case .signin:
            loginVM.email = email
            loginVM.password = password
            Task { await loginVM.login(appState: appState) }
        case .signup:
            registerVM.email = email
            registerVM.password = password
            registerVM.confirmPassword = confirmPassword
            Task { await registerVM.register(appState: appState) }
        }
    }

    // MARK: - Mode Toggle

    @ViewBuilder
    private func modeToggleButton(label: String, target: AuthMode) -> some View {
        let isActive = mode == target
        Button {
            guard mode != target else { return }
            SFXManager.shared.play(.uiTap)
            // Clear errors and confirm field when switching modes so the form feels fresh.
            loginVM.errorMessage = ""
            registerVM.errorMessage = ""
            if target == .signin {
                confirmPassword = ""
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = target
            }
        } label: {
            VStack(spacing: LayoutConstants.spaceXS) {
                Text(label)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(isActive ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)

                Rectangle()
                    .fill(isActive ? DarkFantasyTheme.gold : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch to \(label.lowercased())")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
