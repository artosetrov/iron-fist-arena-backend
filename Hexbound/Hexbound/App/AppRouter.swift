import SwiftUI

enum AppRoute: Hashable {
    // Auth
    case login
    case register
    case onboarding

    // Hub
    case hub
    case hero
    case character
    case stanceSelector

    // Combat
    case combat
    case combatResult
    case loot

    // Arena
    case arena

    // Shop
    case shop
    case currencyPurchase

    // Dungeon
    case dungeonSelect
    case dungeonRoom

    // Minigames
    case tavern
    case shellGame
    case goldMine
    case dungeonRush

    // Quests & Achievements
    case dailyLogin
    case dailyQuests
    case achievements

    // Leaderboard
    case leaderboard

    // Battle Pass
    case battlePass

    // Settings
    case settings
    case appearanceEditor

    // Dev (routed to PlaceholderView in Release builds)
    case screenCatalog
}

// MARK: - Bottom Tab

enum HubTab: Int, CaseIterable {
    case hub = 0
    case arena = 1
    case hero = 2

    var icon: String {
        switch self {
        case .hub: "house.fill"
        case .arena: "shield.fill"
        case .hero: "person.fill"
        }
    }

    var label: String {
        switch self {
        case .hub: "HUB"
        case .arena: "ARENA"
        case .hero: "HERO"
        }
    }
}

// MARK: - Main Router

struct MainRouterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack(path: $state.mainPath) {
            HubView()
                .navigationDestination(for: AppRoute.self) { routeView(for: $0) }
        }
    }

    @ViewBuilder
    private func routeView(for route: AppRoute) -> some View {
        switch route {
        case .hub: HubView()
        case .hero: HeroDetailView()
        case .character: CharacterDetailView()
        case .stanceSelector: StanceSelectorDetailView()
        case .combat: CombatDetailView()
        case .combatResult: CombatResultDetailView()
        case .loot: LootDetailView()
        case .arena: ArenaDetailView()
        case .shop: ShopDetailView()
        case .currencyPurchase: ShopDetailView()
        case .dungeonSelect: DungeonSelectDetailView()
        case .dungeonRoom: DungeonRoomDetailView()
        case .tavern: TavernDetailView()
        case .shellGame: ShellGameDetailView()
        case .goldMine: GoldMineDetailView()
        case .dungeonRush: DungeonRushDetailView()
        case .dailyLogin: DailyLoginDetailView()
        case .dailyQuests: DailyQuestsDetailView()
        case .achievements: AchievementsDetailView()
        case .leaderboard: LeaderboardDetailView()
        case .battlePass: BattlePassDetailView()
        case .settings: SettingsDetailView()
        case .appearanceEditor: AppearanceEditorDetailView()
        #if DEBUG
        case .screenCatalog: ScreenCatalogView()
        #endif
        default: PlaceholderView()
        }
    }
}

// MARK: - Auth Router

struct AuthRouterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack(path: $state.authPath) {
            LoginView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .register: RegisterDetailView()
                    case .onboarding: OnboardingDetailView()
                    default: LoginView()
                    }
                }
        }
    }
}

// MARK: - Placeholder

struct PlaceholderView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        ZStack {
            DarkFantasyTheme.bgDark.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Coming Soon")
                    .font(DarkFantasyTheme.title(size: 28))
                    .foregroundStyle(DarkFantasyTheme.gold)
                Text("This feature is under development")
                    .font(DarkFantasyTheme.body(size: 16))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !appState.mainPath.isEmpty {
                    Button("Back") { appState.mainPath.removeLast() }
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
        }
    }
}

// All route stubs have been replaced with real views
