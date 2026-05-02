import SwiftUI

/// Interactive combat opponent type — drives server-side logic fork in
/// /pvp/match/start + /strike + /complete. Raw values match the backend's
/// `opponent_type` string enum, so this encodes directly to the wire.
enum InteractiveOpponentType: String, Hashable, Codable, Sendable {
    case pvp
    case bot
    case dungeonBoss = "dungeon_boss"
}

enum AppRoute: Hashable, Codable {
    // Auth
    case login
    case register
    case onboarding
    case characterSelection

    // Hub
    case hub
    case hero
    case stanceSelector
    case buyStatPoints

    // Combat
    case combat
    case combatResult
    case loot
    /// Interactive Combat v1 — match-lifecycle fight screen.
    /// `opponentType` lets the same UI drive PvP, bot, and dungeon boss fights —
    /// the server forks its logic in /pvp/match/start by reading this field.
    /// `.pvp` — real opponent, ELO + revenge queue.
    /// `.bot` — NPC bot (npc_* ids), client-side AI picks server-side zones,
    /// no ELO swing, no revenge queue.
    /// `.dungeonBoss` — boss from an active DungeonRun. `dungeonRunId` must be
    /// set. Server advances the run's floor counter on win.
    case interactiveBattle(
        characterId: String,
        opponentId: String,
        attackerMaxHp: Int,
        defenderMaxHp: Int,
        opponentType: InteractiveOpponentType = .pvp,
        dungeonRunId: String? = nil
    )

    // Arena
    case arena

    // Shop
    case shop
    case currencyPurchase(initialTab: Int = 0)
    case premiumPurchase

    // Dungeon
    case dungeonMap
    case dungeonMapEditor
    case dungeonSelect
    case dungeonRoom

    // Social
    case guildHall
    case guildHallMessage(characterId: String, characterName: String, avatar: String? = nil, characterClass: String? = nil)
    case characterProfile(characterId: String, characterName: String)

    // Minigames
    case tavern
    case stash
    case shellGame
    case fortuneWheel
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

    // Session Summary
    case sessionSummary(characterId: String)

    // Settings
    case settings
    case appearanceEditor

    // Guest upgrade
    case upgradeGuest

    // Tutorial
    case tutorial

    // Dev (routed to UnavailableRouteView in Release builds)
    case screenCatalog
    case designSystem
    case hubEditor
    case cardsCatalog
    case progressBarsCatalog
    case badgesCatalog
    case componentsCatalog
    case modalsCatalog
}

extension AppRoute {
    /// Bounded push deep-link parser for string payloads sent by the admin
    /// campaign tool. Only supports routes that can be opened without extra
    /// typed payload like character IDs.
    static func pushDeepLink(from rawRoute: String) -> AppRoute? {
        let normalized = rawRoute
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")

        switch normalized {
        case "hub":
            return .hub
        case "hero":
            return .hero
        case "arena":
            return .arena
        case "shop":
            return .shop
        case "guild-hall", "guildhall":
            return .guildHall
        case "tavern":
            return .tavern
        case "stash":
            return .stash
        case "shell-game", "shellgame":
            return .shellGame
        case "fortune-wheel", "fortunewheel":
            return .fortuneWheel
        case "gold-mine", "goldmine":
            return .goldMine
        case "dungeon-rush", "dungeonrush":
            return .dungeonRush
        case "inbox":
            return .inbox
        case "daily-quests", "dailyquests", "quests":
            return .dailyQuests
        case "achievements":
            return .achievements
        case "leaderboard", "ranks":
            return .leaderboard
        case "battle-pass", "battlepass":
            return .battlePass
        case "settings":
            return .settings
        default:
            return nil
        }
    }
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
                .navigationDestination(for: AppRoute.self) { MainRouterView.destination(for: $0) }
        }
    }

    @ViewBuilder
    static func destination(for route: AppRoute) -> some View {
        switch route {
        // Hub
        case .hub: HubView()
        case .hero: HeroDetailView()
        case .stanceSelector: StanceSelectorDetailView()
        case .buyStatPoints: BuyStatPointsView()
        
        // Combat
        case .combat: CombatDetailView()
        case .combatResult: CombatResultDetailView()
        case .loot: LootDetailView()
        case .interactiveBattle(let characterId, let opponentId, let attackerMaxHp, let defenderMaxHp, let opponentType, let dungeonRunId):
            InteractiveBattleRouteView(
                characterId: characterId,
                opponentId: opponentId,
                attackerMaxHp: attackerMaxHp,
                defenderMaxHp: defenderMaxHp,
                opponentType: opponentType,
                dungeonRunId: dungeonRunId
            )
        
        // Arena
        case .arena: ArenaDetailView()
        
        // Shop
        case .shop: ShopDetailView()
        case .currencyPurchase(let tab): CurrencyPurchaseView(initialTab: tab)
        case .premiumPurchase: PremiumPurchaseView()
        
        // Dungeon
        case .dungeonMap: DungeonMapView()
        case .dungeonSelect: DungeonSelectDetailView()
        case .dungeonRoom: DungeonRoomDetailView()
        
        // Social
        case .guildHall: GuildHallDetailView()
        case .guildHallMessage(let characterId, let characterName, let avatar, let characterClass):
            GuildHallDetailView(openMessageTo: characterId, messageName: characterName, messageAvatar: avatar, messageCharacterClass: characterClass)
        case .characterProfile(let characterId, let characterName):
            CharacterProfileView(characterId: characterId, characterName: characterName)

        // Minigames
        case .tavern: TavernDetailView()
        case .stash: StashDetailView()
        case .shellGame: ShellGameDetailView()
        case .fortuneWheel: FortuneWheelDetailView()
        case .goldMine: GoldMineDetailView()
        case .dungeonRush: DungeonRushDetailView()
        
        // Inbox
        case .inbox: InboxDetailView()

        // Quests & Achievements
        case .dailyLogin: DailyLoginDetailView() // BUG-53: route is legacy — modal is now a root overlay driven by appState.showDailyLoginPopup. Keep the case for the dev screen catalog.
        case .dailyQuests: DailyQuestsDetailView()
        case .achievements: AchievementsDetailView()
        
        // Leaderboard
        case .leaderboard: LeaderboardDetailView()
        
        // Battle Pass
        case .battlePass: BattlePassDetailView()
        
        // Session Summary
        case .sessionSummary(let characterId):
            SessionSummaryNavigationWrapper(characterId: characterId)

        // Settings
        case .settings: SettingsDetailView()
        case .appearanceEditor: AppearanceEditorDetailView()
        case .upgradeGuest: UpgradeGuestView()
        
        // Dev screens
        #if DEBUG
        case .screenCatalog: ScreenCatalogView()
        case .designSystem: DesignSystemPreview()
        case .hubEditor: HubEditorDetailView()
        case .dungeonMapEditor: DungeonMapEditorView()
        case .cardsCatalog: CardsCatalogView()
        case .progressBarsCatalog: ProgressBarsCatalogView()
        case .badgesCatalog: BadgesCatalogView()
        case .componentsCatalog: ComponentsCatalogView()
        case .modalsCatalog: ModalsCatalogView()
        #else
        case .screenCatalog, .designSystem, .hubEditor, .dungeonMapEditor,
             .cardsCatalog, .progressBarsCatalog, .badgesCatalog, .componentsCatalog, .modalsCatalog:
            UnavailableRouteView()
        #endif
        
        // Tutorial
        case .tutorial: TutorialView()

        // Auth (should not reach here in MainRouter)
        case .login, .register, .onboarding, .characterSelection:
            UnavailableRouteView()
        }
    }
}

// MARK: - Auth Router

struct AuthRouterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack(path: $state.authPath) {
            WelcomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .login: AuthView(initialMode: .signin)
                    case .register: AuthView(initialMode: .signup)
                    case .onboarding: OnboardingDetailView()
                    default: WelcomeView()
                    }
                }
        }
    }
}

// MARK: - Placeholder

struct UnavailableRouteView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .modifier(BounceEffectModifier())
                
                Text("Unavailable")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.gold)

                Text("This screen isn't available right now.")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceXL)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton {
                    if !appState.mainPath.isEmpty {
                        appState.mainPath.removeLast()
                    } else if !appState.authPath.isEmpty {
                        appState.authPath.removeLast()
                    }
                }
            }
        }
    }
}

// MARK: - Session Summary Navigation Wrapper

/// Wraps SessionSummaryView for NavigationStack routing, providing a dismiss closure
/// that pops the current route off the navigation path.
struct SessionSummaryNavigationWrapper: View {
    @Environment(AppState.self) private var appState
    let characterId: String

    var body: some View {
        SessionSummaryView(characterId: characterId) {
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Availability-safe bounce symbol effect

private struct BounceEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.symbolEffect(.bounce, options: .repeating)
        } else {
            content
        }
    }
}
