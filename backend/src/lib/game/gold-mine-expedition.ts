/**
 * Gold Mine expedition (the "shaft 3/5" track) — 2026-10-16 rework.
 *
 * Every cart collected is one haul — the same whether it is collected on its
 * own or by Collect All, so neither path is the "better" one. Five hauls
 * finish the expedition and open its chest; extra carts from the same
 * Collect All carry over into the next expedition. The next expedition starts on its own:
 * there is no picker any more (the two shafts only change the bonus-round
 * backdrop), so collecting never stops to ask a question.
 *
 * Server-authoritative: the client only renders `activeShaftJson` and the
 * `chest` it is handed.
 */
import type { Prisma } from '@prisma/client'
import {
  SHAFTS,
  SHAFT_TOTAL_EXTRACTIONS,
  getUnlockedShaftKeys,
  isValidShaftKey,
  type ShaftKey,
} from './shaft-catalog'

/**
 * Expedition chest — paid when the 5th cart lands. Tune here.
 * Per cart that is +30 gold (carts average ~70) and +0.4 gems (carts average
 * ~0.2): a 3-slot player collecting three times a day opens ~1.8 chests.
 */
export const EXPEDITION_CHEST_GOLD = 150
export const EXPEDITION_CHEST_GEMS = 2

export interface ExpeditionChest {
  gold: number
  gems: number
  shaftKey: ShaftKey
}

export interface ExpeditionState {
  activeShaftKey: ShaftKey
  shaftProgress: number
  shaftTotal: number
  chest: ExpeditionChest | null
}

interface ExpeditionCharacter {
  id: string
  userId: string
  goldMineSlots: number
  activeShaftKey: string | null
  shaftProgress: number
  shaftTotal: number
}

/**
 * The shaft an expedition runs in: the requested one when unlocked,
 * otherwise the one after `previous` in unlock order (so players who own the
 * Ice shaft alternate backdrops), otherwise the first unlocked shaft.
 */
export function nextShaftKey(
  goldMineSlots: number,
  previous: ShaftKey | null,
  requested?: string | null
): ShaftKey {
  const unlocked = getUnlockedShaftKeys(goldMineSlots)
  if (requested && isValidShaftKey(requested) && unlocked.includes(requested)) {
    return requested
  }
  if (unlocked.length === 0) return 'stone'
  if (!previous) return unlocked[0]
  const index = unlocked.indexOf(previous)
  return unlocked[(index + 1) % unlocked.length]
}

/** The character's running expedition, starting one if none is active. */
export function currentShaft(
  character: Pick<ExpeditionCharacter, 'goldMineSlots' | 'activeShaftKey' | 'shaftProgress' | 'shaftTotal'>,
  requested?: string | null
): { key: ShaftKey; progress: number; total: number; isNew: boolean } {
  const total = character.shaftTotal || SHAFT_TOTAL_EXTRACTIONS
  if (character.activeShaftKey && isValidShaftKey(character.activeShaftKey)) {
    return { key: character.activeShaftKey, progress: character.shaftProgress, total, isNew: false }
  }
  return { key: nextShaftKey(character.goldMineSlots, null, requested), progress: 0, total, isNew: true }
}

/**
 * Counts `hauls` carts. Runs inside the collect transaction, after the carts'
 * own gold/gems were credited: when the expedition fills it credits the chest
 * to the user and immediately starts the next expedition, carrying over any
 * carts beyond the fifth (at most one chest per call — a call drains at most
 * MAX_GOLD_MINE_SLOTS carts, fewer than an expedition).
 */
export async function advanceExpedition(
  tx: Prisma.TransactionClient,
  character: ExpeditionCharacter,
  requested?: string | null,
  hauls = 1
): Promise<ExpeditionState> {
  const shaft = currentShaft(character, requested)
  let key = shaft.key
  let progress = shaft.progress + Math.max(1, Math.floor(hauls))
  let chest: ExpeditionChest | null = null

  if (progress >= shaft.total) {
    chest = { gold: EXPEDITION_CHEST_GOLD, gems: EXPEDITION_CHEST_GEMS, shaftKey: key }
    await tx.user.update({
      where: { id: character.userId },
      data: {
        gold: { increment: EXPEDITION_CHEST_GOLD },
        gems: { increment: EXPEDITION_CHEST_GEMS },
      },
    })
    key = nextShaftKey(character.goldMineSlots, key)
    progress = Math.min(progress - shaft.total, shaft.total - 1)
  }

  await tx.character.update({
    where: { id: character.id },
    data: { activeShaftKey: key, shaftProgress: progress, shaftTotal: shaft.total },
  })

  return { activeShaftKey: key, shaftProgress: progress, shaftTotal: shaft.total, chest }
}

/** `active_shaft` as every gold-mine route returns it. */
export function activeShaftJson(key: ShaftKey, progress: number, total: number) {
  return {
    key,
    progress,
    total,
    display_name: SHAFTS[key].displayName,
    background_asset: SHAFTS[key].backgroundAssetName,
    thumb_asset: SHAFTS[key].thumbAssetName,
  }
}

/** `expedition_chest` in collect responses (null when no chest opened). */
export function chestJson(chest: ExpeditionChest | null) {
  return chest ? { gold: chest.gold, gems: chest.gems, shaft_key: chest.shaftKey } : null
}
