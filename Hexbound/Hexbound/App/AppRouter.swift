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
    case premiumPurchase

    // Dungeon
    case dungeonSelect
    case dungeonRoom

    // Minigames
    case tavern
    case shellGame
    case goldMine
    case dungeonRush

    // Inbox
    case inbox

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
    case designSystem
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
        // Hub
        case .hub: HubView()
        case .hero: HeroDetailView()
        case .character: CharacterDetailView()
        case .stanceSelector: StanceSelectorDetailView()
        
        // Combat
        case .combat: CombatDetailView()
        case .combatResult: CombatResultDetailView()
        case .loot: LootDetailView()
        
        // Arena
        case .arena: ArenaDetailView()
        
        // Shop
        case .shop: ShopDetailView()
        case .currencyPurchase: CurrencyPurchaseView()
        case .premiumPurchase: PremiumPurchaseView()
        
        // Dungeon
        case .dungeonSelect: DungeonSelectDetailView()
        case .dungeonRoom: DungeonRoomDetailView()
        
        // Minigames
        case .tavern: TavernDetailView()
        case .shellGame: ShellGameDetailView()
        case .goldMine: GoldMineDetailView()
        case .dungeonRush: DungeonRushDetailView()
        
        // Inbox
        case .inbox: InboxDetailView()

        // Quests & Achievements
        case .dailyLogin: DailyLoginDetailView()
        case .dailyQuests: DailyQuestsDetailView()
        case .achievements: AchievementsDetailView()
        
        // Leaderboard
        case .leaderboard: LeaderboardDetailView()
        
        // Battle Pass
        case .battlePass: BattlePassDetailView()
        
        // Settings
        case .settings: SettingsDetailView()
        case .appearanceEditor: AppearanceEditorDetailView()
        
        #if DEBUG
        case .screenCatalog: ScreenCatalogView()
        case .designSystem: DesignSystemPreview()
        #endif
        
        // Auth (should not reach here in MainRouter)
        case .login, .register, .onboarding:
            PlaceholderView()
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
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("Coming Soon")
                    .font(DarkFantasyTheme.title(size: 28))
                    .foregroundStyle(DarkFantasyTheme.gold)
                
                Text("This feature is under development")
                    .font(DarkFantasyTheme.body(size: 16))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Безопасное удаление из стека навигации
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    } else if !appState.authPath.isEmpty {
                        appState.authPath.removeLast()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(DarkFantasyTheme.gold)
                }
            }
        }
    }
}

