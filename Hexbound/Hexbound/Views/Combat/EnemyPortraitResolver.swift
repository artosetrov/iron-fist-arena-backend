//
//  EnemyPortraitResolver.swift
//  Hexbound
//
//  Shared portrait-asset lookup for combat views (classic and interactive).
//  Combat surfaces need to map a fighter's display name → bundled portrait
//  asset for two enemy categories that don't carry a character `skinKey`:
//    • Dungeon bosses — name is matched against `DungeonInfo.bosses`.
//    • Rush mobs       — name is slugified into `rush-<slug>-portrait`,
//                        with a `-full` fallback before giving up.
//
//  Single source of truth so `CombatDetailView` (classic) and
//  `InteractiveBattleView.DuelFighterCard` (interactive combat) render the
//  same enemy art instead of one of them silently falling back to a class
//  icon. Keep this lookup centralized here rather than duplicating slightly
//  different heuristics across combat views.
//
//  Every boss has two pieces of art: a portrait (head & shoulders) for
//  lists, medallions and result cards, and a full-body cutout for anything
//  that puts the boss on a stage (dungeon screen, dossier, dice combat).
//

import SwiftUI

/// Resolves bundled portrait asset names for non-PvP enemies (dungeon
/// bosses, rush mobs). Both call sites must use this resolver — do not
/// duplicate the lookup heuristics inline in views.
@MainActor
enum EnemyPortraitResolver {

    /// Every dungeon known to the cache, or the bundled fallback list when
    /// the cache is cold.
    private static func dungeonSources(_ cache: GameDataCache) -> [DungeonInfo] {
        if let cached = cache.cachedDungeonList(), !cached.isEmpty {
            return cached
        }
        return DungeonInfo.fallback
    }

    /// The dungeon boss whose name matches `name` (case-insensitive, exact).
    static func bossInfo(for name: String, cache: GameDataCache) -> BossInfo? {
        let lowered = name.lowercased()
        for dungeon in dungeonSources(cache) {
            if let boss = dungeon.bosses.first(where: { $0.name.lowercased() == lowered }) {
                return boss
            }
        }
        return nil
    }

    /// The opponent id a dungeon boss fight is started with
    /// ("Rusty Golem" → "boss_rusty_golem").
    static func opponentId(for boss: BossInfo) -> String {
        "boss_\(boss.name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }

    /// The boss behind a dungeon-fight `opponentId` — lets the battle screen
    /// paint the boss on its first frame, before `/match/start` answers.
    static func bossInfo(forOpponentId id: String, cache: GameDataCache) -> BossInfo? {
        guard id.hasPrefix("boss_") else { return nil }
        for dungeon in dungeonSources(cache) {
            if let boss = dungeon.bosses.first(where: { opponentId(for: $0) == id }) {
                return boss
            }
        }
        return nil
    }

    /// Find the boss portrait asset by matching the fighter's name against
    /// every dungeon boss known to the cache (or the bundled fallback list
    /// when the cache is cold). Case-insensitive, exact-match.
    static func bossPortraitImage(for name: String, cache: GameDataCache) -> String? {
        bossInfo(for: name, cache: cache)?.portraitImage
    }

    /// Portrait art for a boss (lists, medallions), falling back to the
    /// full-body art. nil when neither is bundled.
    static func portraitAsset(_ boss: BossInfo) -> String? {
        if UIImage(named: boss.portraitImage) != nil { return boss.portraitImage }
        if UIImage(named: boss.fullImage) != nil { return boss.fullImage }
        return nil
    }

    /// Full-body art for a boss (stage, dossier, combat), falling back to
    /// the portrait. nil when neither is bundled.
    static func fullBodyAsset(_ boss: BossInfo) -> String? {
        if UIImage(named: boss.fullImage) != nil { return boss.fullImage }
        if UIImage(named: boss.portraitImage) != nil { return boss.portraitImage }
        return nil
    }

    /// Derive a rush enemy portrait asset from the fighter's name.
    /// "Flame Sprite" → "rush-flame-sprite-portrait", with a `-full`
    /// fallback before returning nil. The slug strips apostrophes and
    /// the standalone word "of" (e.g. "Lord of Ash" → "lord-ash") so the
    /// asset catalog stays terse.
    static func rushEnemyPortrait(for name: String) -> String? {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "of", with: "")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let portrait = "rush-\(slug)-portrait"
        if UIImage(named: portrait) != nil { return portrait }
        let full = "rush-\(slug)-full"
        if UIImage(named: full) != nil { return full }
        return nil
    }
}
