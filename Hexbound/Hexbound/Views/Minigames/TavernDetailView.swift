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
            subtitle: "Bet gold, find the ball.\nDouble or nothing.",
            hostName: "The Trickster",
            hostImage: "npc-shell-master",
            accentColor: DarkFantasyTheme.gold,
            route: .shellGame
        ),
        TavernGame(
            id: "wheel",
            title: "FORTUNE WHEEL",
            subtitle: "Spin the wheel.\nUp to x5 your wager!",
            hostName: "Lady Fortuna",
            hostImage: "lady-fortuna",
            accentColor: DarkFantasyTheme.purple,
            route: .fortuneWheel
        ),
        TavernGame(
            id: "rush",
            title: "DUNGEON RUSH",
            subtitle: "Endless waves.\nHow far can you go?",
            hostName: "The Warden",
            hostImage: "icon-dungeon-rush",
            accentColor: DarkFantasyTheme.danger,
            route: .dungeonRush
        ),
        TavernGame(
            id: "gold-mine",
            title: "GOLD MINE",
            subtitle: "Collect your gold.\nCatch bonus drops!",
            hostName: "The Foreman",
            hostImage: "building-gold-mine",
            accentColor: DarkFantasyTheme.gold,
            route: .goldMine
        ),
    ]
}

// MARK: - Tavern Detail View

struct TavernDetailView: View {
    @Environment(AppState.self) private var appState

    /// Number of items currently stored in the Shared Chest.
    /// `nil` while loading (shows a placeholder dash).
    @State private var stashItemCount: Int?

    private let columns = [
        GridItem(.flexible(), spacing: LayoutConstants.spaceSM),
        GridItem(.flexible(), spacing: LayoutConstants.spaceSM)
    ]

    // MARK: - Aggregated currency totals (account-wide)

    /// Sum of gold across every character on the account. Falls back to the
    /// current character's gold when `userCharacters` hasn't been loaded yet.
    private var totalGold: Int {
        if !appState.userCharacters.isEmpty {
            return appState.userCharacters.reduce(0) { $0 + $1.gold }
        }
        return appState.currentCharacter?.gold ?? 0
    }

    /// Sum of gems across every character on the account. Falls back to the
    /// current character's gems when `userCharacters` hasn't been loaded yet.
    private var totalGems: Int {
        if !appState.userCharacters.isEmpty {
            return appState.userCharacters.reduce(0) { $0 + ($1.gems ?? 0) }
        }
        return appState.currentCharacter?.gems ?? 0
    }

    // MARK: - Shared Chest Card

    private var stashCard: some View {
        Button {
            appState.mainPath.append(AppRoute.stash)
        } label: {
            VStack(spacing: 0) {
                stashIllustration
                stashInfoPanel
            }
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
            .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.gold.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .shadow(color: DarkFantasyTheme.gold.opacity(0.15), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.97))
    }

    /// Top banner — chest illustration matching the visual treatment of
    /// `TavernGameCard.gameIllustration` (gradient base + asset image + bottom fade).
    private var stashIllustration: some View {
        ZStack {
            LinearGradient(
                colors: [DarkFantasyTheme.gold.opacity(0.2), DarkFantasyTheme.bgTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if UIImage(named: "rush-ui-treasure-chest") != nil {
                Image("rush-ui-treasure-chest")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(.vertical, LayoutConstants.spaceXS)
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
            }

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.bgSecondary.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
            }
        }
        .frame(height: 130)
        .clipped()
    }

    /// Bottom info panel — title, item count, and currency totals.
    private var stashInfoPanel: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("SHARED CHEST")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Item count line
            HStack(spacing: LayoutConstants.space2XS) {
                Image(systemName: "shippingbox.fill")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.gold.opacity(0.8))

                Text(stashItemCount.map { "\($0) / 100 items" } ?? "— / 100 items")
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.gold.opacity(0.8))
            }

            // Account-wide currency totals
            CurrencyDisplay(
                gold: totalGold,
                gems: totalGems,
                size: .compact,
                animated: false
            )
            .padding(.top, LayoutConstants.space2XS)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity)
    }

    /// Loads the stash item count for the header card. Cheap call —
    /// reuses the same endpoint StashDetailView hits on its own .task.
    private func loadStashCount() async {
        let service = StashService(appState: appState)
        if let response = await service.loadStash() {
            stashItemCount = response.usedSlots
        }
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    // Header
                    Text("Welcome, traveler.\nPick your game.")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, LayoutConstants.spaceSM)

                    // Shared Chest — full width card
                    stashCard
                        .padding(.horizontal, LayoutConstants.screenPadding)

                    // Minigame cards — 2-column grid (like Gold Mine)
                    LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("TAVERN")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            await loadStashCount()
        }
    }
}

// MARK: - Tavern Game Card (Vertical — like MineSlotCard)

private struct TavernGameCard: View {
    let game: TavernGame
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Host illustration (top section)
                gameIllustration

                // Info panel (bottom section)
                infoPanel
            }
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
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .shadow(color: game.accentColor.opacity(0.15), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.scalePress(0.97))
    }

    // MARK: - Game Illustration

    private var gameIllustration: some View {
        ZStack {
            // Accent gradient background
            LinearGradient(
                colors: [game.accentColor.opacity(0.2), DarkFantasyTheme.bgTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Host NPC / scene image
            if UIImage(named: game.hostImage) != nil {
                Image(game.hostImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(game.accentColor.opacity(0.6))
            }

            // Bottom gradient fade into info panel
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.bgSecondary.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
            }
        }
        .frame(height: 110)
        .clipped()
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text(game.title)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(game.hostName)
                .font(DarkFantasyTheme.body.weight(.semibold))
                .foregroundStyle(game.accentColor.opacity(0.8))

            Text(game.subtitle)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceMS)
    }
}
