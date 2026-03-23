#if DEBUG
import SwiftUI

// MARK: - Screen Catalog

struct ScreenCatalogView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    ForEach(CatalogSection.allCases) { section in
                        catalogCard(section)
                    }
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceMD)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("SCREEN CATALOG")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func catalogCard(_ section: CatalogSection) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(section.title)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.gold)

            ForEach(section.items) { item in
                Button {
                    navigate(to: item)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: item.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(DarkFantasyTheme.gold.opacity(0.7))
                            .frame(width: 24)

                        Text(item.name)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(DarkFantasyTheme.textPrimary)

                        Spacer()

                        if item.isModal {
                            Text("MODAL")
                                .font(DarkFantasyTheme.body(size: 10))
                                .foregroundStyle(DarkFantasyTheme.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                        .fill(DarkFantasyTheme.bgTertiary)
                                )
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .padding(.vertical, LayoutConstants.spaceXS)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }

    // MARK: - Navigation

    private func navigate(to item: CatalogItem) {
        MockData.injectIntoAppState(appState)

        if let route = item.route {
            appState.mainPath.append(route)
        }

        // Modals — trigger flags
        switch item.id {
        case "daily-login-popup":
            appState.enqueueModal(.dailyLogin)
        case "level-up-modal":
            appState.triggerLevelUpModal(newLevel: 26, statPoints: 3)
        case "toast-overlay":
            appState.showToast("Achievement Unlocked!", subtitle: "First Blood", type: .achievement)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.showToast("Level Up!", subtitle: "You reached level 26", type: .levelUp)
            }
        default:
            break
        }
    }
}

// MARK: - Data

private enum CatalogSection: String, CaseIterable, Identifiable {
    case auth, hub, hero, arena, combat, shop
    case dungeon, minigames, quests, achievements
    case leaderboard, battlePass, profile, settings, modals
    case devTools

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auth: "Auth"
        case .hub: "Hub"
        case .hero: "Hero"
        case .arena: "Arena / PvP"
        case .combat: "Combat"
        case .shop: "Shop"
        case .dungeon: "Dungeon"
        case .minigames: "Minigames"
        case .quests: "Quests"
        case .achievements: "Achievements"
        case .leaderboard: "Leaderboard"
        case .battlePass: "Battle Pass"
        case .profile: "Profile"
        case .settings: "Settings"
        case .modals: "Modals / Overlays"
        case .devTools: "Dev Tools"
        }
    }

    var items: [CatalogItem] {
        switch self {
        case .auth:
            return [
                CatalogItem(id: "login", name: "Login", icon: "person.crop.circle", route: .login),
                CatalogItem(id: "register", name: "Register", icon: "person.badge.plus", route: .register),
                CatalogItem(id: "onboarding", name: "Onboarding (Character Creation)", icon: "sparkles", route: .onboarding),
            ]
        case .hub:
            return [
                CatalogItem(id: "hub", name: "Hub (Main Screen)", icon: "house.fill", route: .hub),
                CatalogItem(id: "stance-selector", name: "Stance Selector", icon: "figure.martial.arts", route: .stanceSelector),
            ]
        case .hero:
            return [
                CatalogItem(id: "hero", name: "Hero Detail (Equipment + Stats)", icon: "person.fill", route: .hero),
            ]
        case .arena:
            return [
                CatalogItem(id: "arena", name: "Arena (Opponents / Revenge / History)", icon: "shield.fill", route: .arena),
            ]
        case .combat:
            return [
                CatalogItem(id: "combat", name: "Combat (Battle)", icon: "bolt.fill", route: .combat),
                CatalogItem(id: "combat-result", name: "Combat Result", icon: "flag.checkered", route: .combatResult),
                CatalogItem(id: "loot", name: "Loot Screen", icon: "gift.fill", route: .loot),
            ]
        case .shop:
            return [
                CatalogItem(id: "shop", name: "Shop", icon: "cart.fill", route: .shop),
            ]
        case .dungeon:
            return [
                CatalogItem(id: "dungeon-select", name: "Dungeon Select", icon: "map.fill", route: .dungeonSelect),
                CatalogItem(id: "dungeon-room", name: "Dungeon Room", icon: "door.left.hand.closed", route: .dungeonRoom),
            ]
        case .minigames:
            return [
                CatalogItem(id: "tavern", name: "Tavern (Minigame Hub)", icon: "mug.fill", route: .tavern),
                CatalogItem(id: "shell-game", name: "Shell Game", icon: "cup.and.saucer.fill", route: .shellGame),
                CatalogItem(id: "gold-mine", name: "Gold Mine", icon: "hammer.fill", route: .goldMine),
                CatalogItem(id: "dungeon-rush", name: "Dungeon Rush", icon: "flame.fill", route: .dungeonRush),
            ]
        case .quests:
            return [
                CatalogItem(id: "daily-quests", name: "Daily Quests", icon: "checklist", route: .dailyQuests),
            ]
        case .achievements:
            return [
                CatalogItem(id: "achievements", name: "Achievements", icon: "trophy.fill", route: .achievements),
            ]
        case .leaderboard:
            return [
                CatalogItem(id: "leaderboard", name: "Leaderboard", icon: "chart.bar.fill", route: .leaderboard),
            ]
        case .battlePass:
            return [
                CatalogItem(id: "battle-pass", name: "Battle Pass", icon: "star.fill", route: .battlePass),
            ]
        case .profile:
            return [
                CatalogItem(id: "appearance-editor", name: "Appearance Editor", icon: "paintbrush.fill", route: .appearanceEditor),
            ]
        case .settings:
            return [
                CatalogItem(id: "settings", name: "Settings", icon: "gearshape.fill", route: .settings),
            ]
        case .modals:
            return [
                CatalogItem(id: "daily-login-popup", name: "Daily Login Popup", icon: "calendar.badge.plus", route: nil, isModal: true),
                CatalogItem(id: "level-up-modal", name: "Level Up Modal", icon: "arrow.up.circle.fill", route: nil, isModal: true),
                CatalogItem(id: "toast-overlay", name: "Toast Notifications", icon: "bell.fill", route: nil, isModal: true),
            ]
        case .devTools:
            return [
                CatalogItem(id: "design-system", name: "Design System", icon: "paintpalette.fill", route: .designSystem),
            ]
        }
    }
}

private struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let route: AppRoute?
    var isModal: Bool = false
}
#endif
