// =============================================================================
// descent/server.ts — database side of the Descent (scaling, loot, effects)
// =============================================================================

import type { Prisma } from '@prisma/client'
import { chaGoldBonus, levelScaledReward } from '../balance'
import { claimPreviewedLoot, previewLootDrop, type LootResponseItem, type PreviewedLoot } from '../loot'
import { grantRewardEntries } from '../reward-grants'
import { DESCENT } from './content'
import type { BagEntry, DescentState, Effect, FightKind, RunScale } from './engine'
import type { MobKey } from './content'

/** Multipliers fixed at run start so prices and rewards stay consistent for the whole run. */
export function runScaleFor(level: number, cha: number, premiumGoldMult: number): RunScale {
  const levelMult = levelScaledReward(10_000, Math.max(1, level)) / 10_000 // R3: +4% per level
  const chaMult = chaGoldBonus(10_000, cha) / 10_000
  return {
    gold: DESCENT.GOLD_SCALE * levelMult * chaMult * premiumGoldMult,
    price: DESCENT.GOLD_SCALE * levelMult,
    xp: DESCENT.XP_SCALE * levelMult,
  }
}

export function toBagEntry(loot: PreviewedLoot | null): BagEntry | null {
  if (!loot) return null
  if (loot.kind === 'shard') return { kind: 'shard', tier: loot.tier, amount: loot.amount, rarity: loot.rarity }
  return {
    kind: 'item',
    catalogItemId: loot.catalogItemId,
    name: loot.name,
    itemType: loot.itemType,
    rarity: loot.rarity,
    itemLevel: loot.itemLevel,
    baseStats: loot.baseStats,
    rolledStats: loot.rolledStats,
    imageKey: loot.imageKey,
    imageUrl: loot.imageUrl,
    sellPrice: loot.sellPrice,
  }
}

function toPreviewed(e: BagEntry): PreviewedLoot {
  if (e.kind === 'shard') return { kind: 'shard', tier: e.tier, amount: e.amount, rarity: e.rarity }
  return { ...e, kind: 'item' }
}

export async function previewBagEntry(
  tx: Prisma.TransactionClient,
  characterId: string,
  level: number,
): Promise<BagEntry | null> {
  return toBagEntry(await previewLootDrop(tx, characterId, level))
}

export interface AppliedEffects {
  ended: boolean
  goldClaimed: number
  xpGranted: number
  itemsGranted: LootResponseItem[]
  kills: Array<{ kind: FightKind; mob: MobKey }>
  character: {
    gold: number
    xp: number
    level: number
    leveledUp: boolean
    newLevel: number | null
    statPointsAwarded: number
    passivePointsAwarded: number
  } | null
}

/** Apply engine effects inside the run's transaction. */
export async function applyDescentEffects(
  tx: Prisma.TransactionClient,
  args: { userId: string; characterId: string; effects: Effect[] },
): Promise<AppliedEffects> {
  const out: AppliedEffects = { ended: false, goldClaimed: 0, xpGranted: 0, itemsGranted: [], kills: [], character: null }
  const entries: BagEntry[] = []
  for (const e of args.effects) {
    switch (e.type) {
      case 'xp': out.xpGranted += e.amount; break
      case 'claim':
        out.goldClaimed += e.gold
        entries.push(...e.entries)
        break
      case 'kill': out.kills.push({ kind: e.kind, mob: e.mob }); break
      case 'end': out.ended = true; break
    }
  }

  if (entries.length) {
    out.itemsGranted = await claimPreviewedLoot(tx, args.characterId, entries.map(toPreviewed))
  }

  const gold = Math.max(0, Math.floor(out.goldClaimed))
  const xp = Math.max(0, Math.floor(out.xpGranted))
  if (gold > 0 || xp > 0) {
    const res = await grantRewardEntries(tx, {
      userId: args.userId,
      characterId: args.characterId,
      rewards: [
        ...(gold > 0 ? [{ type: 'gold' as const, quantity: gold }] : []),
        ...(xp > 0 ? [{ type: 'xp' as const, quantity: xp }] : []),
      ],
    })
    out.character = {
      gold: res.gold,
      xp: res.xp,
      level: res.level,
      leveledUp: res.levelUpResult?.leveledUp ?? false,
      newLevel: res.levelUpResult?.leveledUp ? res.levelUpResult.newLevel : null,
      statPointsAwarded: res.levelUpResult?.statPointsAwarded ?? 0,
      passivePointsAwarded: res.levelUpResult?.passivePointsAwarded ?? 0,
    }
  }
  return out
}

export function serializeState(state: DescentState): Prisma.InputJsonValue {
  return JSON.parse(JSON.stringify(state)) as Prisma.InputJsonValue
}
