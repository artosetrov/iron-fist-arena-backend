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
                    .font(.system(size: 18)) // SF Symbol icon — keep as is
                    .foregroundStyle(DarkFantasyTheme.gold)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Save your progress!")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("Create an account to keep everything")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                Spacer()

                Button {
                    appState.mainPath.append(AppRoute.upgradeGuest)
                } label: {
                    Text("SIGN UP")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
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
                        .font(.system(size: 12, weight: .bold)) // SF Symbol icon — keep as is
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
