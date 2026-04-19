import SwiftUI

/// Data payload for `BossRevealOverlayView`. Decouples the ceremonial
/// overlay from domain models (`BossInfo`, `RushRoom`) so the same
/// component can drive both the dungeon progression reveal and the
/// Dungeon Rush miniboss reveal without importing either codepath.
///
/// Two variants are supported via `Kind`:
/// - `.dungeonBoss` — full ceremony (~2.2s), CTA dismisses the overlay
///   and returns the player to `BossDetailSheet` (once-per-boss).
/// - `.rushMiniboss` — compact reveal (~1.2s), CTA fires `onChallenge`
///   which should commit to `vm.fight()` immediately (every run).
struct BossRevealData: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let level: Int
    let hp: Int          // 0 means "unknown" — chip is hidden
    let dropCount: Int   // 0 means "unknown" — chip is hidden
    let imageKey: String
    let accent: Color
    let kind: Kind
    let onChallenge: () -> Void
    let onSkip: () -> Void

    enum Kind {
        case dungeonBoss
        case rushMiniboss
    }
}

// MARK: - Factories

extension BossRevealData {
    /// Build a dungeon-boss reveal from the rich `BossInfo` model.
    /// Subtitle preference order:
    ///   1. `boss.tagline` — authored hook from `dungeon_bosses.tagline`
    ///   2. First sentence of `boss.extendedLore`, trimmed to ≤110 chars
    static func fromDungeonBoss(
        _ boss: BossInfo,
        accent: Color = DarkFantasyTheme.arenaRankGold,
        onChallenge: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> BossRevealData {
        let subtitle: String = {
            if let tagline = boss.tagline?.trimmingCharacters(in: .whitespacesAndNewlines),
               !tagline.isEmpty {
                return tagline
            }
            return Self.shortenLore(boss.extendedLore)
        }()
        return BossRevealData(
            name: boss.name,
            subtitle: subtitle,
            level: boss.level,
            hp: boss.hp,
            dropCount: boss.loot.count,
            imageKey: boss.fullImage,
            accent: accent,
            kind: .dungeonBoss,
            onChallenge: onChallenge,
            onSkip: onSkip
        )
    }

    /// Build a rush-miniboss reveal. Rush bosses don't expose HP/drop
    /// counts client-side pre-fight, so those chips render the run
    /// progress instead ("FINAL ROOM · 12/12").
    static func fromRushMiniboss(
        name: String,
        level: Int,
        floor: Int,
        totalRooms: Int,
        imageKey: String,
        accent: Color = DarkFantasyTheme.purple,
        onChallenge: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> BossRevealData {
        BossRevealData(
            name: name,
            subtitle: "FINAL ROOM · \(floor) / \(totalRooms)",
            level: level,
            hp: 0,
            dropCount: 0,
            imageKey: imageKey,
            accent: accent,
            kind: .rushMiniboss,
            onChallenge: onChallenge,
            onSkip: onSkip
        )
    }

    // MARK: - Helpers

    private static func shortenLore(_ lore: String) -> String {
        let trimmed = lore.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let terminators: Set<Swift.Character> = [".", "!", "?"]
        if let end = trimmed.firstIndex(where: { terminators.contains($0) }) {
            let sentence = trimmed[..<end].trimmingCharacters(in: .whitespaces)
            if sentence.count >= 20 && sentence.count <= 110 {
                return sentence + String(trimmed[end])
            }
        }
        if trimmed.count <= 110 { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: 108)
        return trimmed[..<idx].trimmingCharacters(in: .whitespaces) + "…"
    }
}
