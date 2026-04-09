import SwiftUI

/// Soft nudge banner shown to guest users at level 3+.
/// Encourages registration without blocking gameplay.
struct GuestNudgeBanner: View {
    @Environment(AppState.self) private var appState
    @State private var dismissed = false

    var body: some View {
        if appState.isGuest,
           !dismissed,
           (appState.currentCharacter?.level ?? 0) >= 3 {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.gold)

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("Save your progress!")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("Create an account to keep everything")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer()

                Button {
                    appState.mainPath.append(AppRoute.upgradeGuest)
                } label: {
                    Text("SIGN UP")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(DarkFantasyTheme.gold)
                        .clipShape(Capsule())
                }

                Button {
                    withAnimation { dismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
