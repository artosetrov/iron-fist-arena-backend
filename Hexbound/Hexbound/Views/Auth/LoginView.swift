import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var vm = LoginViewModel()

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Branding
                Spacer()

                Image("hexbound-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280)

                Spacer()

                // Bottom form block
                VStack(spacing: LayoutConstants.spaceLG) {
                    // 2. Form
                    VStack(spacing: LayoutConstants.spaceMD) {
                        StyledTextField(
                            placeholder: "Email",
                            text: $vm.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        StyledSecureField(
                            placeholder: "Password",
                            text: $vm.password,
                            icon: "lock.fill"
                        )
                    }

                    // 3. Primary action
                    Button {
                        Task { await vm.login(appState: appState) }
                    } label: {
                        Text("LOG IN")
                    }
                    .buttonStyle(.primary(enabled: !vm.isLoading))
                    .disabled(vm.isLoading)

                    // Error
                    if !vm.errorMessage.isEmpty {
                        Text(vm.errorMessage)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.textDanger)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    // 4. Alternative login
                    VStack(spacing: LayoutConstants.spaceMD) {
                        HStack(spacing: LayoutConstants.spaceMD) {
                            Rectangle()
                                .fill(DarkFantasyTheme.borderSubtle)
                                .frame(height: 1)
                            Text("CONNECT WITH")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                                .tracking(1)
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .fixedSize()
                            Rectangle()
                                .fill(DarkFantasyTheme.borderSubtle)
                                .frame(height: 1)
                        }

                        HStack(spacing: LayoutConstants.spaceMD) {
                            // Apple
                            ZStack {
                                SignInWithAppleButton(.signIn) { request in
                                    request.requestedScopes = [.email, .fullName]
                                } onCompletion: { result in
                                    Task { await vm.handleAppleSignIn(result: result, appState: appState) }
                                }
                                .signInWithAppleButtonStyle(.white)
                                .blendMode(.overlay)

                                Image(systemName: "apple.logo")
                                    .font(.system(size: 22, weight: .medium)) // SF Symbol icon — keep as is
                                    .foregroundStyle(Color.white)
                                    .allowsHitTesting(false)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: LayoutConstants.buttonHeightLG)
                            .background(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .fill(Color.black)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                                    .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                            )

                            // Google
                            Button {
                                Task { await vm.handleGoogleSignIn(appState: appState) }
                            } label: {
                                Text("G")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white)
                            }
                            .buttonStyle(.socialAuth)
                        }
                    }

                    // 5. Secondary actions
                    HStack(spacing: LayoutConstants.spaceLG) {
                        Button("Forgot Password?") {
                            vm.showForgotPassword = true
                        }
                        .buttonStyle(.ghost)

                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Button("Sign Up") {
                            appState.authPath.append(AppRoute.register)
                        }
                        .buttonStyle(.ghost)
                    }
                    .padding(.top, LayoutConstants.spaceXS)

                    // 6. Guest login with warning
                    VStack(spacing: LayoutConstants.spaceXS) {
                        Button {
                            Task { await vm.guestLogin(appState: appState) }
                        } label: {
                            Text("PLAY AS GUEST")
                        }
                        .buttonStyle(.neutral)

                        Text("⚠️ Guest progress may be lost. Link your account later in Settings to save.")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.textWarning)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, LayoutConstants.spaceSM)

                    // DEV: Quick admin login
                    #if DEBUG
                    Button {
                        Task { await vm.devLogin(appState: appState) }
                    } label: {
                        Text("DEV: Admin Login")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(DarkFantasyTheme.danger)
                    }
                    #endif
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, 60)
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            vm.setup(appState: appState)
        }
        .alert("Reset Password", isPresented: $vm.showForgotPassword) {
            TextField("Email", text: $vm.forgotEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Link") {
                Task { await vm.sendPasswordReset(appState: appState) }
            }
        } message: {
            Text("Enter your email and we'll send a password reset link.")
        }
    }
}

// MARK: - Styled Text Field

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 20)
            }

            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(DarkFantasyTheme.textTertiary))
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .frame(height: LayoutConstants.inputHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Styled Secure Field

struct StyledSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 20)
            }

            Group {
                if isVisible {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(DarkFantasyTheme.textTertiary))
                } else {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(DarkFantasyTheme.textTertiary))
                }
            }
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .frame(height: LayoutConstants.inputHeight)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
