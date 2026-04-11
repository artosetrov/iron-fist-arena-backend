/**
 * Scripted opponents for tutorial fights.
 *
 * These are NOT real Characters in the DB — they are synthetic CharacterStats
 * used only by runCombat() for scripted, deterministic tutorial battles.
 * No persistence, no ratings, no ELO, no stamina, no consequences.
 *
 * DESIGN GOALS:
 *   1. Guaranteed hero victory against all 4 classes × default Lv1 loadouts.
 *   2. Determinism via seed — one seed must produce the same outcome every time.
 *   3. Extensible — future scripted tutorials (pre-dungeon, guild, event) reuse this catalog.
 *
 * WHY synthetic instead of real NPC bot:
 *   - Real NPCs cost stamina, grant ELO, trigger achievements — all wrong for tutorial.
 *   - Synthetic stats allow perfect balance tuning without polluting the NPC bot table.
 *   - Catalog pattern means LiveOps can add new scripted fights without touching endpoint code.
 *
 * SEED SEARCH:
 *   The `guaranteedVictorySeed` value is found offline via `scripts/find-tutorial-seed.ts`,
 *   which brute-forces seeds 0..1M and picks the first seed where hero wins for ALL 4 classes
 *   in ≤5 turns. If balance changes break the seed, re-run the script and update this value.
 *   SANITY CHECK in /api/tutorial/scripted-fight/resolve will log any drift.
 *
 * See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
 */

import type { CharacterStats } from './combat';

/** Catalog keys — one per scripted opponent. Add new entries here. */
export type ScriptedOpponentKey =
  | 'tutorial_orc_grunt'          // W2.D3: first PvP tutorial fight
  | 'tutorial_dungeon_skeleton'   // future: pre-dungeon tutorial (W3+)
  | 'tutorial_boss_preview';      // future: chapter boss teaser (LiveOps)

export interface ScriptedOpponent {
  key: ScriptedOpponentKey;
  /** Human-readable display name shown in opponent card. */
  displayName: string;
  /** Synthetic CharacterStats — fed directly into runCombat(). */
  character: CharacterStats;
  /**
   * Seed that guarantees hero victory against this opponent for ALL 4 classes
   * at default Lv1 loadout. Found offline via find-tutorial-seed.ts.
   * Placeholder 0xDEADBEEF until seed search runs — will be replaced before ship.
   */
  guaranteedVictorySeed: number;
  /**
   * Forced stance for determinism. runCombat's seed handles RNG, but stance
   * selection happens before combat — forcing it ensures the seed's outcome.
   */
  forcedStance: {
    attack: 'head' | 'chest' | 'legs';
    defense: 'head' | 'chest' | 'legs';
  };
  /**
   * Max turns hero should take to win. If actual > this, pacing is off and the
   * tutorial feels slow. Used by seed-search as an additional filter.
   */
  maxTurnsForVictory: number;
}

/**
 * Tutorial Orc Grunt — the player's first opponent.
 *
 * STATS RATIONALE:
 *   Default Lv1 hero has ~10 STR, ~8 VIT (→ ~100 maxHp), base weapon damage 8-12.
 *   Orc Grunt is intentionally weaker: 6 STR, 6 VIT (→ ~60 maxHp), no skills.
 *   Hero should 2-3 shot the orc while taking glancing damage (tension without risk).
 *
 *   Final expected combat flow:
 *     Turn 1: Hero crits orc for ~25 → orc 60→35 HP
 *     Turn 2: Orc hits hero for ~8   → hero 100→92 HP
 *     Turn 3: Hero finishes orc for ~25 → orc 35→10 HP
 *     Turn 4: Orc hits hero for ~8   → hero 92→84 HP
 *     Turn 5: Hero finishes orc      → VICTORY
 */
export const TUTORIAL_OPPONENTS: Record<ScriptedOpponentKey, ScriptedOpponent> = {
  tutorial_orc_grunt: {
    key: 'tutorial_orc_grunt',
    displayName: 'Orc Grunt',
    character: {
      id: 'tutorial_orc_grunt',
      name: 'Orc Grunt',
      class: 'warrior',
      level: 1,
      // Primary stats — intentionally weak so hero wins decisively.
      str: 6,
      agi: 4,
      vit: 6,
      end: 4,
      int: 2,
      wis: 2,
      luk: 2,
      cha: 2,
      // HP — 60 so hero kills in 2-3 turns, not 1 (1-shot feels anticlimactic).
      maxHp: 60,
      currentHp: 60,
      // Defenses — low so hero damage numbers look big and satisfying.
      armor: 5,
      magicResist: 2,
      // No skills — pure basic attacks only. Keeps tutorial simple.
      equippedSkills: [],
      passiveBonuses: undefined,
    },
    // Placeholder — replaced by find-tutorial-seed.ts result.
    // DO NOT SHIP WITH THIS VALUE. Run seed-search before W2.D3 commit.
    guaranteedVictorySeed: 0xDEADBEEF,
    forcedStance: { attack: 'head', defense: 'chest' },
    maxTurnsForVictory: 5,
  },

  // ── Future entries (placeholders, not yet implemented) ─────────────────
  tutorial_dungeon_skeleton: {
    key: 'tutorial_dungeon_skeleton',
    displayName: 'Skeleton Warrior',
    character: {
      id: 'tutorial_dungeon_skeleton',
      name: 'Skeleton Warrior',
      class: 'warrior',
      level: 2,
      str: 8, agi: 4, vit: 7, end: 4, int: 2, wis: 2, luk: 2, cha: 2,
      maxHp: 75,
      currentHp: 75,
      armor: 8,
      magicResist: 2,
      equippedSkills: [],
      passiveBonuses: undefined,
    },
    guaranteedVictorySeed: 0xDEADBEEF,
    forcedStance: { attack: 'chest', defense: 'head' },
    maxTurnsForVictory: 6,
  },

  tutorial_boss_preview: {
    key: 'tutorial_boss_preview',
    displayName: 'Shadow Lord',
    character: {
      id: 'tutorial_boss_preview',
      name: 'Shadow Lord',
      class: 'mage',
      level: 5,
      str: 6, agi: 8, vit: 10, end: 6, int: 12, wis: 8, luk: 4, cha: 6,
      maxHp: 150,
      currentHp: 150,
      armor: 10,
      magicResist: 15,
      equippedSkills: [],
      passiveBonuses: undefined,
    },
    guaranteedVictorySeed: 0xDEADBEEF,
    forcedStance: { attack: 'head', defense: 'legs' },
    maxTurnsForVictory: 10,
  },
};

/**
 * Retrieve a scripted opponent by key. Throws if key is unknown.
 * Used by /api/tutorial/scripted-fight/{preload,resolve} endpoints.
 */
export function getScriptedOpponent(key: ScriptedOpponentKey): ScriptedOpponent {
  const opponent = TUTORIAL_OPPONENTS[key];
  if (!opponent) {
    throw new Error(`Unknown scripted opponent: ${key}`);
  }
  return opponent;
}

/**
 * List all scripted opponent keys — used by seed-search script
 * to verify every catalog entry has a working seed.
 */
export function listScriptedOpponentKeys(): ScriptedOpponentKey[] {
  return Object.keys(TUTORIAL_OPPONENTS) as ScriptedOpponentKey[];
}
