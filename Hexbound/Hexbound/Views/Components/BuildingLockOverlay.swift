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

    // MARK: - Padlock badge (circular gold disc with SF Symbol)

    private var padlockBadge: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.gold)
                .frame(width: padlockSize, height: padlockSize)
                .shadow(color: DarkFantasyTheme.goldGlow, radius: 4, y: 0)

            Image(systemName: "lock.fill")
                .font(DarkFantasyTheme.section.weight(.bold))
                .foregroundStyle(DarkFantasyTheme.textOnGold)
        }
        .overlay(
            Circle()
                .stroke(DarkFantasyTheme.bgAbyss.opacity(0.5), lineWidth: 1.5)
        )
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
// Client-side static config for the hub unlock schedule. The character
// level is server-authoritative — this just controls UI visibility.
//
// W2.D4 — Front-loaded Epic Seven schedule (2/4/6/6/8/8/12). Arena
// opens immediately after tutorial victory (the player is already
// there). Rationale: dense early-game unlock cadence creates a constant
// "what unlocks next?" anticipation loop during the first week of play.
//
// See: docs/07_ui_ux/W2_D4_UNLOCK_SCHEDULE.md
enum BuildingUnlockConfig {
    /// Maps CityBuilding.id → required character level
    static let levels: [String: Int] = [
        "arena": 1,            // Entered during tutorial — always open
        "shop": 2,             // First post-tutorial unlock (immediate hook)
        "achievements": 4,     // Reward tracking kicks in
        "dungeon": 6,          // PvE content gate
        "gold-mine": 6,        // Passive income unlock (paired with dungeon)
        "tavern": 8,           // Social / daily loop hook
        "battlepass": 8,       // Long-term progression (paired with tavern)
        "ranks": 12,           // Endgame competitive tier
        "guild-hall": 99,      // Coming Soon — effectively locked ("SOON")
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
