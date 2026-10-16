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
 * Carts per expedition (the chest opens on the last one).
 * Every collected cart counts as one haul — see gold-mine-expedition.ts.
 * Balance: see docs/features/gold-mine/GOLD_MINE_MINIGAME_BALANCE_AUDIT.md Section 6.
 */
export const SHAFT_TOTAL_EXTRACTIONS = 5

/**
 * Mini-game session config (Variant D locked defaults).
 */
export const MINIGAME_DURATION_SEC = 60
export const MINIGAME_CAP_PERCENT = 0.15 // 15% cap on passive pool
// Max bonus gems per 60s session. Was 3 while the design note 40 lines below
// said 1 — at 3 gems × 3 slots × ~2 cycles this was the single largest hard
// currency faucet in the game (~90 gems/day/account). Back to the documented
// value.
export const MINIGAME_GEM_CAP = 1
// Share of spawned coins a player must catch to earn the gem. Below this the
// gem is not awarded at all — it is meant to be a reward for playing well, not
// a participation payout.
export const MINIGAME_GEM_CATCH_THRESHOLD = 0.75
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
 * Gem cap stays at MINIGAME_GEM_CAP regardless of level — gems are designed to
 * be rare high-value drops, not a scaling bonus.
 */
/**
 * Coin spawn schedule for the 60-second falling-coins minigame.
 *
 * The client drives the actual spawning (it is a real-time action game), but
 * the SERVER must own the denominator: `caught / spawned`. Before this, both
 * numbers came from the request body, so a client could send any pair it liked
 * and the "derived" reward was still whatever it asked for.
 *
 * Mirrors `MinigameWave` in GoldMineMiniGameView.swift — keep the two in sync.
 */
const MINIGAME_WAVES: ReadonlyArray<{ durationSec: number; spawnIntervalSec: number }> = [
  { durationSec: 15, spawnIntervalSec: 0.50 }, // warmup
  { durationSec: 15, spawnIntervalSec: 0.40 }, // building
  { durationSec: 15, spawnIntervalSec: 0.32 }, // gold rush
  { durationSec: 7, spawnIntervalSec: 0.38 },  // gem storm
  { durationSec: 8, spawnIntervalSec: 0.25 },  // final frenzy
]

/**
 * How many coins a full 60-second session spawns, per the schedule above.
 * Pinned into the session row at /start so a later balance change cannot
 * retroactively alter the denominator of a session already in flight.
 */
export function expectedSpawnCount(): number {
  return Math.floor(
    MINIGAME_WAVES.reduce(
      (total, wave) => total + wave.durationSec / wave.spawnIntervalSec,
      0,
    ),
  )
}

/**
 * Derive the bonus a minigame session actually earned.
 *
 * `spawned` MUST be the server's own number (see `expectedSpawnCount`), never
 * a value from the request body — otherwise the ratio is whatever the client
 * decides it is. `caught` is still client-reported and clamped to `spawned`;
 * bounding a real-time action game further would need a per-coin protocol.
 * What this does guarantee: the payout can never exceed the per-slot cap, the
 * passive pool, or what the player claimed.
 */
export function deriveMinigameBonus(input: {
  capGold: number
  passivePool: number
  caught: number
  spawned: number
}): { gold: number; gems: number; catchRatio: number } {
  const spawned = Math.max(0, Math.floor(input.spawned))
  const caught = Math.min(Math.max(0, Math.floor(input.caught)), spawned)
  const catchRatio = spawned > 0 ? caught / spawned : 0

  const goldCeiling = Math.max(0, Math.min(input.capGold, input.passivePool))

  return {
    gold: Math.floor(goldCeiling * catchRatio),
    gems: catchRatio >= MINIGAME_GEM_CATCH_THRESHOLD ? MINIGAME_GEM_CAP : 0,
    catchRatio,
  }
}

export function calcSlotMinigameCap(
  slotReward: number,
  goldMineSlotsLevel: number
): number {
  if (slotReward <= 0) return 0
  return Math.floor(slotReward * slotMinigameCapFraction(goldMineSlotsLevel))
}

/** Share of a slot's haul the bonus round can add at this mine level (0.15, 0.1725, 0.195…). */
export function slotMinigameCapFraction(goldMineSlotsLevel: number): number {
  const levelMult = 1.0 + 0.15 * Math.max(0, goldMineSlotsLevel - 1)
  return MINIGAME_CAP_PERCENT * levelMult
}
