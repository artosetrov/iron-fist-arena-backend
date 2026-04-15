import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { type Prisma } from '@prisma/client'
import { invalidatePassiveCache, invalidateSkillCache } from '@/lib/game/combat-loader'
import { grantRewardEntries } from '@/lib/game/reward-grants'

// ──── Contraband System ────
//
// "The Scavenger" — a dark merchant who appears every 2 hours with
// goods looted from arena kills and dungeon expeditions.
//
// - 2-hour cooldown between claims
// - Random loot pool tiered by player level
// - Alternating free / paid (odd claim = free, even = costs gold)
// - Server-authoritative: loot is generated per-request, seeded by
//   character ID + claim number for deterministic replay

const COOLDOWN_SECONDS = 2 * 60 * 60 // 2 hours

// ──── Loot Pool ────

interface LootItem {
  type: 'gold' | 'gems' | 'consumable' | 'xp'
  id?: string
  quantity: number
  weight: number // relative probability
}

interface LootTier {
  minLevel: number
  maxLevel: number
  pool: LootItem[]
  goldCostBase: number // base gold cost for paid drops
}

const LOOT_TIERS: LootTier[] = [
  {
    minLevel: 1,
    maxLevel: 10,
    goldCostBase: 50,
    pool: [
      { type: 'gold', quantity: 75, weight: 30 },
      { type: 'gold', quantity: 120, weight: 15 },
      { type: 'xp', quantity: 30, weight: 20 },
      { type: 'consumable', id: 'health_potion_small', quantity: 2, weight: 25 },
      { type: 'consumable', id: 'stamina_potion_small', quantity: 2, weight: 25 },
      { type: 'consumable', id: 'health_potion_medium', quantity: 1, weight: 10 },
      { type: 'gems', quantity: 5, weight: 5 },
    ],
  },
  {
    minLevel: 11,
    maxLevel: 20,
    goldCostBase: 120,
    pool: [
      { type: 'gold', quantity: 150, weight: 25 },
      { type: 'gold', quantity: 250, weight: 10 },
      { type: 'xp', quantity: 60, weight: 15 },
      { type: 'consumable', id: 'health_potion_medium', quantity: 2, weight: 20 },
      { type: 'consumable', id: 'stamina_potion_medium', quantity: 2, weight: 20 },
      { type: 'consumable', id: 'health_potion_large', quantity: 1, weight: 10 },
      { type: 'consumable', id: 'stamina_potion_large', quantity: 1, weight: 10 },
      { type: 'gems', quantity: 10, weight: 8 },
    ],
  },
  {
    minLevel: 21,
    maxLevel: 999,
    goldCostBase: 200,
    pool: [
      { type: 'gold', quantity: 300, weight: 20 },
      { type: 'gold', quantity: 500, weight: 8 },
      { type: 'xp', quantity: 100, weight: 12 },
      { type: 'consumable', id: 'health_potion_large', quantity: 3, weight: 20 },
      { type: 'consumable', id: 'stamina_potion_large', quantity: 3, weight: 20 },
      { type: 'consumable', id: 'health_potion_large', quantity: 2, weight: 15 },
      { type: 'consumable', id: 'stamina_potion_large', quantity: 2, weight: 15 },
      { type: 'gems', quantity: 15, weight: 6 },
      { type: 'gems', quantity: 25, weight: 3 },
    ],
  },
]

/**
 * Simple seeded PRNG (mulberry32) for deterministic loot generation.
 * Seed = hash of characterId + claimNumber so the same claim always
 * generates the same loot (idempotent GET).
 */
function mulberry32(seed: number) {
  return function () {
    let t = (seed += 0x6d2b79f5)
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

function hashString(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = (hash << 5) - hash + char
    hash |= 0
  }
  return Math.abs(hash)
}

/**
 * Pick 2-3 random items from the tier's pool using weighted selection.
 */
function generateLoot(
  characterId: string,
  claimNumber: number,
  level: number
): { type: string; id?: string; quantity: number }[] {
  const tier = LOOT_TIERS.find(
    (t) => level >= t.minLevel && level <= t.maxLevel
  ) ?? LOOT_TIERS[0]

  const seed = hashString(`${characterId}-${claimNumber}`)
  const rng = mulberry32(seed)

  const totalWeight = tier.pool.reduce((sum, item) => sum + item.weight, 0)
  const pickCount = rng() < 0.4 ? 2 : 3 // 40% chance of 2 items, 60% of 3

  const picked: { type: string; id?: string; quantity: number }[] = []
  const usedIndices = new Set<number>()

  for (let i = 0; i < pickCount; i++) {
    let roll = rng() * totalWeight
    for (let j = 0; j < tier.pool.length; j++) {
      roll -= tier.pool[j].weight
      if (roll <= 0) {
        if (usedIndices.has(j)) {
          // Re-roll: pick next available
          for (let k = 0; k < tier.pool.length; k++) {
            const idx = (j + k + 1) % tier.pool.length
            if (!usedIndices.has(idx)) {
              usedIndices.add(idx)
              const item = tier.pool[idx]
              picked.push({ type: item.type, ...(item.id ? { id: item.id } : {}), quantity: item.quantity })
              break
            }
          }
        } else {
          usedIndices.add(j)
          const item = tier.pool[j]
          picked.push({ type: item.type, ...(item.id ? { id: item.id } : {}), quantity: item.quantity })
        }
        break
      }
    }
  }

  return picked
}

/**
 * Gold cost for paid drops — scales with level.
 */
function getGoldCost(level: number): number {
  const tier = LOOT_TIERS.find(
    (t) => level >= t.minLevel && level <= t.maxLevel
  ) ?? LOOT_TIERS[0]
  return tier.goldCostBase
}

// ──── Lore flavor text ────

const FLAVOR_TEXTS = [
  "Salvaged from a fallen warrior's pouch...",
  "Found in the wreckage after last night's arena brawl...",
  "Pulled from a collapsed dungeon passage...",
  "Intercepted from a merchant caravan... don't ask questions.",
  "Confiscated from a bandit hideout nearby...",
  "A traveler left this behind. Their loss, your gain.",
  "Scraped from the battlefield before the crows got to it...",
  "Recovered from the depths — still warm...",
]

/**
 * GET /api/shop/contraband?character_id=xxx
 *
 * Returns the current contraband state:
 * - status: "available" | "cooldown"
 * - If available: the generated offer (contents, price, isFree, flavorText)
 * - If cooldown: nextAvailableAt, cooldownSeconds, totalCooldownSeconds
 * - Always: claimNumber (next), totalClaims
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    // Run character lookup, last-claim lookup, and total-claim count in
    // parallel — they have no inter-dependency. Saves one round-trip vs.
    // the previous sequential character → findFirst → count chain.
    const [character, lastClaim, totalClaims] = await Promise.all([
      prisma.character.findUnique({
        where: { id: characterId },
        select: { id: true, userId: true, level: true },
      }),
      prisma.contrabandClaim.findFirst({
        where: { characterId },
        orderBy: { claimedAt: 'desc' },
      }),
      prisma.contrabandClaim.count({ where: { characterId } }),
    ])
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    const nextClaimNumber = totalClaims + 1
    const now = new Date()

    if (lastClaim) {
      const cooldownEnd = new Date(lastClaim.claimedAt.getTime() + COOLDOWN_SECONDS * 1000)
      if (cooldownEnd > now) {
        // Still on cooldown
        const cooldownRemaining = Math.ceil((cooldownEnd.getTime() - now.getTime()) / 1000)
        return NextResponse.json({
          status: 'cooldown',
          next_available_at: cooldownEnd.toISOString(),
          cooldown_seconds: cooldownRemaining,
          total_cooldown_seconds: COOLDOWN_SECONDS,
          claim_number: nextClaimNumber,
          total_claims: totalClaims,
        })
      }
    }

    // Available! Generate the loot
    const isFree = nextClaimNumber % 2 === 1 // odd = free, even = paid
    const contents = generateLoot(characterId, nextClaimNumber, character.level)
    const price = isFree ? 0 : getGoldCost(character.level)

    // Deterministic flavor text
    const seed = hashString(`${characterId}-flavor-${nextClaimNumber}`)
    const flavorIndex = seed % FLAVOR_TEXTS.length

    return NextResponse.json({
      status: 'available',
      offer: {
        contents,
        price,
        currency: 'gold',
        is_free: isFree,
        flavor_text: FLAVOR_TEXTS[flavorIndex],
        claim_number: nextClaimNumber,
      },
      total_claims: totalClaims,
    })
  } catch (error) {
    console.error('contraband GET error:', error)
    return NextResponse.json({ error: 'Failed to fetch contraband' }, { status: 500 })
  }
}

/**
 * POST /api/shop/contraband
 * Body: { character_id }
 *
 * Claims the current contraband drop. Validates cooldown, deducts
 * currency if paid, grants contents atomically.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: { id: true, userId: true, level: true },
    })
    if (!character || character.userId !== user.id) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    // Atomic transaction
    const result = await prisma.$transaction(async (tx) => {
      // Lock character row to serialize concurrent claims
      await tx.$queryRaw`SELECT id FROM characters WHERE id = ${character_id} FOR UPDATE`

      // Check cooldown inside transaction
      const lastClaim = await tx.contrabandClaim.findFirst({
        where: { characterId: character_id },
        orderBy: { claimedAt: 'desc' },
      })

      const now = new Date()
      if (lastClaim) {
        const cooldownEnd = new Date(lastClaim.claimedAt.getTime() + COOLDOWN_SECONDS * 1000)
        if (cooldownEnd > now) {
          throw new Error('COOLDOWN_ACTIVE')
        }
      }

      const totalClaims = await tx.contrabandClaim.count({
        where: { characterId: character_id },
      })
      const claimNumber = totalClaims + 1

      // Generate loot (deterministic — same as GET)
      const isFree = claimNumber % 2 === 1
      const contents = generateLoot(character_id, claimNumber, character.level)
      const price = isFree ? 0 : getGoldCost(character.level)

      // Deduct currency if paid
      if (price > 0) {
        const freshUser = await tx.user.findUnique({
          where: { id: user.id },
          select: { gold: true },
        })
        if (!freshUser || freshUser.gold < price) {
          throw new Error('INSUFFICIENT_GOLD')
        }
        await tx.user.update({
          where: { id: user.id },
          data: { gold: { decrement: price } },
        })
      }

      const rewardResult = await grantRewardEntries(tx, {
        userId: user.id,
        characterId: character_id,
        rewards: contents,
      })

      // Record the claim
      await tx.contrabandClaim.create({
        data: {
          characterId: character_id,
          contents: contents as Prisma.InputJsonValue,
          price,
          currency: 'gold',
          claimNumber,
        },
      })

      return {
        gold: rewardResult.gold,
        gems: rewardResult.gems,
        xp: rewardResult.xp,
        levelUpResult: rewardResult.levelUpResult,
        contents,
        claim_number: claimNumber,
      }
    }, { isolationLevel: 'Serializable', timeout: 10000 })

    if (result.levelUpResult?.leveledUp) {
      await invalidateSkillCache(character_id)
      await invalidatePassiveCache(character_id)
    }

    return NextResponse.json({
      success: true,
      gold: result.gold,
      gems: result.gems,
      xp: result.xp,
      contents: result.contents,
      claim_number: result.claim_number,
      leveled_up: result.levelUpResult?.leveledUp ?? false,
      new_level: result.levelUpResult?.newLevel,
      stat_points_awarded: result.levelUpResult?.statPointsAwarded,
    })
  } catch (error) {
    if (error instanceof Error && error.message === 'COOLDOWN_ACTIVE') {
      return NextResponse.json({ error: 'Contraband not yet available' }, { status: 400 })
    }
    if (error instanceof Error && error.message === 'INSUFFICIENT_GOLD') {
      return NextResponse.json({ error: 'Not enough gold' }, { status: 400 })
    }
    if (error instanceof Error && error.message === 'INVENTORY_FULL') {
      return NextResponse.json({ error: 'Inventory is full' }, { status: 400 })
    }
    console.error('contraband POST error:', error)
    return NextResponse.json({ error: 'Failed to claim contraband' }, { status: 500 })
  }
}
