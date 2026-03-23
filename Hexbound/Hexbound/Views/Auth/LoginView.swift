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
                        .accessibilityLabel("Email address")

                        StyledSecureField(
                            placeholder: "Password",
                            text: $vm.password,
                            icon: "lock.fill"
                        )
                        .accessibilityLabel("Password")
                    }

                    // 3. Primary action
                    Button {
                        Task { await vm.login(appState: appState) }
                    } label: {
                        Text("LOG IN")
                    }
                    .buttonStyle(.primary(enabled: !vm.isLoading))
                    .disabled(vm.isLoading)
                    .accessibilityLabel("Log in")

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
                                .signInWithAppleButtonStyle(.black)
                                .blendMode(.destinationOver)
                                .opacity(0.01)

                                HStack(spacing: LayoutConstants.spaceSM) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 22, weight: .medium))
                                    Text("Apple")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundStyle(.white)
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
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius))
                            .accessibilityLabel("Sign in with Apple")

                            // Google
                            Button {
                                Task { await vm.handleGoogleSignIn(appState: appState) }
                            } label: {
                                HStack(spacing: LayoutConstants.spaceSM) {
                                    Text("G")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                    Text("Google")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.socialAuth)
                            .accessibilityLabel("Sign in with Google")
                        }
                    }

                    // 5. Secondary actions
                    HStack(spacing: LayoutConstants.spaceLG) {
                        Button("Forgot Password?") {
                            vm.showForgotPassword = true
                        }
                        .buttonStyle(.ghost)
                        .accessibilityLabel("Reset your password")

                        Text("·")
                            .foregroundStyle(DarkFantasyTheme.textTertiary)

                        Button("Sign Up") {
                            appState.authPath.append(AppRoute.register)
                        }
                        .buttonStyle(.ghost)
                        .accessibilityLabel("Create new account")
                    }
                    .padding(.top, LayoutConstants.spaceXS)

                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, 60)
            }

            if vm.isLoading {
                LoadingOverlay()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if !appState.authPath.isEmpty {
                        appState.authPath.removeLast()
                    }
                } label: {
                    Image("ui-arrow-left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Go back")
            }
        }
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
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
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
