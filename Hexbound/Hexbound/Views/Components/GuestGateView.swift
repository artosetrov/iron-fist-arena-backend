import SwiftUI

/// Overlay shown when a guest user tries to access a gated feature.
/// Prompts registration to continue. Dismissible via close button.
struct GuestGateView: View {
    @Environment(AppState.self) private var appState
    let feature: String // e.g. "PvP Arena", "Customization"
    let onRegister: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed backdrop
            DarkFantasyTheme.bgBackdropLight
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: LayoutConstants.spaceLG) {
                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48)) // SF Symbol icon — keep as is
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .padding(.top, LayoutConstants.spaceMD)

                // Title
                Text("REGISTRATION REQUIRED")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                // Description
                Text("\(feature) is available for registered players.\nCreate an account to unlock it and keep all your progress!")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceMD)

                // Benefits list
                VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                    benefitRow(icon: "checkmark.shield.fill", text: "Keep all your progress")
                    benefitRow(icon: "person.2.fill", text: "Access PvP Arena")
                    benefitRow(icon: "icloud.fill", text: "Cloud save across devices")
                    benefitRow(icon: "paintbrush.fill", text: "Customize your hero")
                }
                .padding(.horizontal, LayoutConstants.spaceLG)

                // Register button
                Button {
                    onRegister()
                } label: {
                    Text("CREATE ACCOUNT")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, LayoutConstants.spaceLG)

                // Dismiss
                Button("Not now") {
                    onDismiss()
                }
                .buttonStyle(.ghost)
                .padding(.bottom, LayoutConstants.spaceMD)
            }
            .padding(LayoutConstants.spaceMD)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.panelRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.08, bottomShadow: 0.14)
            .innerBorder(cornerRadius: LayoutConstants.panelRadius - 3, inset: 3, color: DarkFantasyTheme.goldDim.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 2)
            )
            .cornerBrackets(color: DarkFantasyTheme.goldDim, length: 12, thickness: 1.5)
            .cornerDiamonds(color: DarkFantasyTheme.gold.opacity(0.4), size: 4)
            .shadow(color: DarkFantasyTheme.gold.opacity(0.1), radius: 8)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 6, y: 3)
            .padding(.horizontal, LayoutConstants.screenPadding * 2)
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: icon)
                .font(.system(size: 14)) // SF Symbol icon — keep as is
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: 24)
            Text(text)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
    }
}
