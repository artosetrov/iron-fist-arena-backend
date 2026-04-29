import SwiftUI

// MARK: - Building Lock Overlay (BUG-57)
//
// Reusable lock indicator drawn OVER a dim/grayscale building sprite in
// `CityBuildingView`. The previous implementation was a bare padlock
// icon with a tiny "LV.4" label that QA couldn't tell apart from an
// open building — this version is unmistakable: dark vignette + gold
// padlock disc + gold level pill so the player sees what's blocking
// them at a glance.
//
// All values go through `DarkFantasyTheme` / `LayoutConstants` per the
// design system rules. No hardcoded colors, no custom font sizes.
//
// **Reusability**: any screen that needs a "level-locked sprite" marker
// (future: building previews, Coming-Soon teasers, mini-game slots)
// can reuse this overlay unchanged.
struct BuildingLockOverlay: View {
    /// Required character level for unlock. `nil` renders the "SOON"
    /// pill for buildings that have no route wired yet (Coming Soon).
    let requiredLevel: Int?

    /// Scales the padlock + pill proportionally with the building
    /// sprite so a tall building gets a bigger lock and a small kiosk
    /// gets a compact one. Passed as the sprite's `buildingHeight`.
    let spriteHeight: CGFloat

    private var padlockSize: CGFloat {
        // 28…52pt, scales with sprite height
        min(max(spriteHeight * 0.32, 28), 52)
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            padlockBadge
            levelPill
        }
        // Soft dark vignette behind the entire stack — lifts the lock
        // marker off the grayscale sprite so it never blends in.
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(DarkFantasyTheme.gold.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Padlock badge (ornamental lock asset with soft gold glow)

    private var padlockBadge: some View {
        ZStack {
            // Soft gold halo behind the lock — lifts it off the sprite
            // without redrawing a flat disc.
            Circle()
                .fill(DarkFantasyTheme.gold.opacity(0.22))
                .frame(width: padlockSize * 1.6, height: padlockSize * 1.6)
                .blur(radius: padlockSize * 0.22)

            Image("icon-padlock")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: padlockSize, height: padlockSize)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 4, y: 2)
        }
    }

    // MARK: - Level pill (gold capsule under the padlock)

    @ViewBuilder
    private var levelPill: some View {
        let text = requiredLevel.map { "LV \($0)" } ?? "SOON"
        Text(text)
            .font(DarkFantasyTheme.badge)
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                Capsule().fill(DarkFantasyTheme.gold)
            )
            .overlay(
                Capsule()
                    .stroke(DarkFantasyTheme.bgAbyss.opacity(0.5), lineWidth: 1)
            )
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        if let lvl = requiredLevel {
            return "Locked. Unlocks at level \(lvl)."
        }
        return "Locked. Coming soon."
    }
}

// MARK: - Building Unlock Config
//
// Client-side mirror for hub unlock visibility + local unlock ceremonies.
// Character level remains server-authoritative; this table must stay aligned
// with `backend/src/lib/game/tutorial.ts::BUILDING_UNLOCK_LEVELS`.
//
// Important: the IDs here are hub/view IDs (`battlepass`, `ranks`,
// `guild-hall`, `black-market`), while the backend tutorial helper uses its own
// snake_case keys (`battle_pass`, `leaderboard`, `guild`, `black_market`).
// Keep LEVELS aligned even though the key names differ.
enum BuildingUnlockConfig {
    /// Maps CityBuilding.id → required character level
    static let levels: [String: Int] = [
        "arena": 1,            // tutorial baseline
        "shop": 1,             // tutorial baseline
        "achievements": 2,     // first post-tutorial reward loop
        "dungeon": 4,          // first PvE branch
        "gold-mine": 6,        // idle loop
        "tavern": 6,           // minigame/social beat
        "battlepass": 8,       // long-term progression
        "ranks": 8,            // leaderboard layer
        "guild-hall": 12,      // social hub
        "black-market": 99,    // Coming Soon — effectively locked ("SOON")
    ]

    /// Check if building is unlocked for given character level
    static func isUnlocked(_ buildingId: String, characterLevel: Int) -> Bool {
        guard let required = levels[buildingId] else { return true }
        return characterLevel >= required
    }

    /// Get required level for a building (nil = always unlocked)
    static func requiredLevel(for buildingId: String) -> Int? {
        levels[buildingId]
    }

    /// Buildings that unlock at exactly this level (used by ceremony
    /// dispatcher).
    static func buildingsUnlocking(at level: Int) -> [String] {
        levels
            .filter { $0.value == level && $0.value < 99 && $0.value > 1 }
            .map(\.key)
            .sorted()
    }

    /// Buildings that will unlock at level+1 — used for anticipation
    /// toasts on the level BEFORE the unlock ("One more level — Gold
    /// Mine awakens.")
    static func buildingsUnlockingNext(currentLevel: Int) -> [String] {
        buildingsUnlocking(at: currentLevel + 1)
    }
}
