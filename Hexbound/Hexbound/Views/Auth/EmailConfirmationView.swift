import SwiftUI

struct EmailConfirmationView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache

    let email: String

    @State private var isResending = false
    @State private var resendMessage = ""
    @State private var resendCooldown = 0
    @State private var envelopeScale: CGFloat = 0.5
    @State private var envelopeOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Animated envelope icon
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.gold.opacity(0.12 * glowOpacity))
                        .frame(width: 180, height: 180)
                        .blur(radius: 40)

                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .scaleEffect(envelopeScale)
                .opacity(envelopeOpacity)

                // Title
                VStack(spacing: LayoutConstants.spaceSM) {
                    Text("CHECK YOUR EMAIL")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text("We sent a confirmation link to")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)

                    Text(email)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text("Tap the link in the email to verify your account. The app will open automatically.")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceLG)

                Spacer()

                // Resend button
                VStack(spacing: LayoutConstants.spaceSM) {
                    Button {
                        Task { await resendEmail() }
                    } label: {
                        HStack(spacing: LayoutConstants.spaceSM) {
                            if isResending {
                                ProgressView()
                                    .tint(DarkFantasyTheme.gold)
                                    .scaleEffect(0.8)
                            }
                            Text(resendCooldown > 0
                                 ? "RESEND IN \(resendCooldown)s"
                                 : "RESEND EMAIL")
                        }
                    }
                    .buttonStyle(.secondary(enabled: !isResending && resendCooldown == 0))
                    .disabled(isResending || resendCooldown > 0)

                    if !resendMessage.isEmpty {
                        Text(resendMessage)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                            .foregroundStyle(
                                resendMessage.contains("sent")
                                    ? DarkFantasyTheme.textSuccess
                                    : DarkFantasyTheme.textDanger
                            )
                            .transition(.opacity)
                    }
                }

                // Back to login
                Button("BACK TO LOGIN") {
                    appState.pendingConfirmationEmail = nil
                    appState.authPath = NavigationPath()
                    appState.authPath.append(AppRoute.login)
                }
                .buttonStyle(.ghost)

                Spacer().frame(height: LayoutConstants.spaceXL)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            appState.pendingConfirmationEmail = email
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                envelopeScale = 1.0
                envelopeOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).delay(0.3).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
        .onDisappear {
            glowOpacity = 0
        }
    }

    private func resendEmail() async {
        isResending = true
        resendMessage = ""

        do {
            try await SupabaseAuthClient.shared.resendConfirmation(email: email)
            resendMessage = "Confirmation email sent!"
            startCooldown()
        } catch {
            resendMessage = "Failed to resend. Try again later."
            #if DEBUG
            print("[EmailConfirmation] resend error: \(error)")
            #endif
        }

        isResending = false
    }

    private func startCooldown() {
        resendCooldown = 60
        Task {
            while resendCooldown > 0 {
                try? await Task.sleep(for: .seconds(1))
                resendCooldown -= 1
            }
        }
    }
}
