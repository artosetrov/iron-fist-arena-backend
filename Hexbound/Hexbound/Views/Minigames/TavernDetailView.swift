import SwiftUI

// MARK: - Tavern Game Host Data

private struct TavernGame: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let hostName: String
    let hostImage: String  // asset name
    let accentColor: Color
    let route: AppRoute

    static let allGames: [TavernGame] = [
        TavernGame(
            id: "shell",
            title: "SHELL GAME",
            subtitle: "Bet gold, find the ball. Double or nothing.",
            hostName: "The Trickster",
            hostImage: "icon-shell-game",
            accentColor: DarkFantasyTheme.gold,
            route: .shellGame
        ),
        TavernGame(
            id: "wheel",
            title: "FORTUNE WHEEL",
            subtitle: "Spin the wheel. Up to x5 your wager!",
            hostName: "Lady Fortuna",
            hostImage: "building-tavern",
            accentColor: DarkFantasyTheme.purple,
            route: .fortuneWheel
        ),
        TavernGame(
            id: "rush",
            title: "DUNGEON RUSH",
            subtitle: "Endless waves. How far can you go?",
            hostName: "The Warden",
            hostImage: "icon-dungeon-rush",
            accentColor: DarkFantasyTheme.danger,
            route: .dungeonRush
        ),
    ]
}

// MARK: - Tavern Detail View

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

                    // Minigame cards with host images
                    VStack(spacing: LayoutConstants.spaceSM) {
                        ForEach(TavernGame.allGames) { game in
                            TavernGameCard(game: game) {
                                appState.mainPath.append(game.route)
                            }
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

// MARK: - Tavern Game Card (with Host Image)

private struct TavernGameCard: View {
    let game: TavernGame
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Host image panel
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(game.accentColor.opacity(0.12))

                    if UIImage(named: game.hostImage) != nil {
                        Image(game.hostImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 86)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(game.accentColor.opacity(0.6))
                    }
                }
                .frame(width: 72, height: 86)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(game.accentColor.opacity(0.25), lineWidth: 1)
                )

                // Info section
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(DarkFantasyTheme.section(size: 15))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    Text(game.hostName)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(game.accentColor.opacity(0.8))

                    Text(game.subtitle)
                        .font(DarkFantasyTheme.body(size: 12))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }
                .padding(.leading, LayoutConstants.spaceSM)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(game.accentColor.opacity(0.6))
                    .padding(.trailing, LayoutConstants.spaceSM)
            }
            .padding(LayoutConstants.spaceSM)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: game.accentColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(game.accentColor.opacity(0.3), lineWidth: 1)
            )
            .cornerBrackets(color: game.accentColor.opacity(0.3), length: 14, thickness: 1.5)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.97))
    }
}
