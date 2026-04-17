/**
 * Gold Mine Expedition Shafts (Variant D mini-game)
 *
 * Players commit to one shaft at a time. Each shaft cycle takes N extractions
 * (Collect All plays) to clear. While a shaft is active, the player cannot
 * switch. Background art + thumb art change per shaft; the mini-game mechanics
 * are identical.
 *
 * Unlock is gated by gold_mine_slots (level of mine expansion).
 *
 * New shafts are added by appending to SHAFTS and bumping SHAFT_KEY_VALUES.
 * See docs/06_game_systems/BALANCE_CONSTANTS.md for economy rationale.
 */

export type ShaftKey = 'stone' | 'ice'

export const SHAFT_KEY_VALUES: ShaftKey[] = ['stone', 'ice']

export interface ShaftConfig {
  key: ShaftKey
  displayName: string
  backgroundAssetName: string
  thumbAssetName: string
  unlockSlotLevel: number
}

export const SHAFTS: Record<ShaftKey, ShaftConfig> = {
  stone: {
    key: 'stone',
    displayName: 'Stone Shaft',
    backgroundAssetName: 'mine-slot-1',
    thumbAssetName: 'mine-slot-1',
    unlockSlotLevel: 1,
  },
  ice: {
    key: 'ice',
    displayName: 'Ice Shaft',
    backgroundAssetName: 'mine-slot-4',
    thumbAssetName: 'mine-slot-4',
    unlockSlotLevel: 2,
  },
}

/**
 * Number of extraction plays required to clear one shaft cycle.
 * Each successful Collect All counts as one extraction (~20%).
 * Balance: see docs/features/gold-mine/GOLD_MINE_MINIGAME_BALANCE_AUDIT.md Section 6.
 */
export const SHAFT_TOTAL_EXTRACTIONS = 5

/**
 * Mini-game session config (Variant D locked defaults).
 */
export const MINIGAME_DURATION_SEC = 60
export const MINIGAME_CAP_PERCENT = 0.15 // 15% cap on passive pool
export const MINIGAME_GEM_CAP = 3 // max 3 bonus gems per 60s session
export const MINIGAME_SESSION_TTL_SEC = 180 // session must be claimed within 3 min (game is 60s)
export const MINIGAME_GAME_TYPE = 'gold_mine_rush' as const

export function isValidShaftKey(value: unknown): value is ShaftKey {
  return typeof value === 'string' && (SHAFT_KEY_VALUES as string[]).includes(value)
}

/**
 * Returns the list of shafts unlocked at a given gold-mine slot level.
 * Shafts unlock at slot level 1 (stone) and 2 (ice) — gated by the mine
 * expansion the player has already purchased via gems.
 */
export function getUnlockedShaftKeys(goldMineSlots: number): ShaftKey[] {
  return SHAFT_KEY_VALUES.filter((key) => SHAFTS[key].unlockSlotLevel <= goldMineSlots)
}

/**
 * Server-authoritative cap calculation (legacy — aggregate pool Variant D
 * Phase 1). Kept for backward compatibility with old clients still calling
 * /collect-all + /minigame-bonus; new per-slot flow uses `calcSlotMinigameCap`.
 * c = floor(passivePool * 0.15)
 */
export function calcMinigameCap(passiveGoldAmount: number): number {
  if (passiveGoldAmount <= 0) return 0
  return Math.floor(passiveGoldAmount * MINIGAME_CAP_PERCENT)
}

/**
 * Per-slot bonus cap (Variant D Phase 2).
 *
 * Each gold-mine slot has its own 15s minigame. The cap scales with the
 * player's gold-mine expansion level so that higher-level mines reward more
 * bonus gold per play:
 *
 *   cap = floor(slotReward * 0.15 * (1 + 0.15 * (slotsLevel - 1)))
 *
 * Level 1 mine → 15% of slot reward (baseline).
 * Level 2 mine → 17.25%.
 * Level 3 mine → 19.5%.
 *
 * Gem cap stays at MINIGAME_GEM_CAP (1) regardless of level — gems are
 * designed to be rare high-value drops, not a scaling bonus.
 */
export function calcSlotMinigameCap(
  slotReward: number,
  goldMineSlotsLevel: number
): number {
  if (slotReward <= 0) return 0
  const levelMult = 1.0 + 0.15 * Math.max(0, goldMineSlotsLevel - 1)
  return Math.floor(slotReward * MINIGAME_CAP_PERCENT * levelMult)
}
