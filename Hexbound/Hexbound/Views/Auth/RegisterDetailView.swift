import SwiftUI

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

                    // Back to login
                    Button("Already have an account? LOG IN") {
                        if !appState.authPath.isEmpty { appState.authPath.removeLast() }
                    }
                    .buttonStyle(.ghost)

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
            }
        }
        .onAppear { vm.setup(appState: appState) }
    }
}
