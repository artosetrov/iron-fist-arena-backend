import SwiftUI

struct TavernDetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // Header
                    Text("Welcome, traveler.\nPick your game.")
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, LayoutConstants.spaceSM)

                    // Minigame cards
                    VStack(spacing: LayoutConstants.spaceSM) {
                        TavernGameCard(
                            icon: "🐚",
                            title: "SHELL GAME",
                            subtitle: "Bet gold, find the ball. Double or nothing.",
                            accentColor: DarkFantasyTheme.gold
                        ) {
                            appState.mainPath.append(AppRoute.shellGame)
                        }

                        TavernGameCard(
                            icon: "💀",
                            title: "DUNGEON RUSH",
                            subtitle: "Endless waves. How far can you go?",
                            accentColor: DarkFantasyTheme.danger
                        ) {
                            appState.mainPath.append(AppRoute.dungeonRush)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)

                    Spacer().frame(height: LayoutConstants.spaceLG)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("TAVERN")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }
}

// MARK: - Tavern Game Card

struct TavernGameCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Text(icon)
                        .font(.system(size: 26)) // emoji — keep
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(DarkFantasyTheme.section(size: 15))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Text(subtitle)
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold)) // SF Symbol icon — keep
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(LayoutConstants.bannerPadding)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.97))
    }
}
