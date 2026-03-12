// =============================================================================
// seed-battle-pass.ts — Seed Season + BattlePassReward data
// Run: npx tsx prisma/seed-battle-pass.ts
// =============================================================================

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding battle pass data...')

  // Create Season 1 (active for 90 days from now)
  const now = new Date()
  const endDate = new Date(now)
  endDate.setDate(endDate.getDate() + 90)

  const season = await prisma.season.upsert({
    where: { number: 1 },
    update: {
      startAt: now,
      endAt: endDate,
    },
    create: {
      number: 1,
      theme: 'Season 1: Dark Forge',
      startAt: now,
      endAt: endDate,
    },
  })

  console.log(`Season created/updated: ${season.id} (${season.theme})`)

  const milestoneCatalogIds: Record<number, string> = {
    10: 'chest_chain_mail',
    20: 'chest_plate_armor',
    30: 'chest_titan_cuirass',
  }

  const milestoneItems = await prisma.item.findMany({
    where: {
      catalogId: { in: Object.values(milestoneCatalogIds) },
    },
    select: {
      id: true,
      catalogId: true,
      itemName: true,
    },
  })

  const itemIdByCatalogId = new Map(
    milestoneItems.map((item) => [item.catalogId, item.id]),
  )

  for (const catalogId of Object.values(milestoneCatalogIds)) {
    if (!itemIdByCatalogId.has(catalogId)) {
      throw new Error(
        `Battle pass seed requires item catalog "${catalogId}". Run the main item seed before seeding battle pass rewards.`,
      )
    }
  }

  // Delete existing rewards for this season to re-seed
  await prisma.battlePassReward.deleteMany({
    where: { seasonId: season.id },
  })

  // Define 30 levels of rewards (free + premium per level)
  const rewards: {
    bpLevel: number
    isPremium: boolean
    rewardType: string
    rewardId: string | null
    rewardAmount: number
  }[] = []

  for (let level = 1; level <= 30; level++) {
    // Free rewards
    if (level % 5 === 0) {
      // Every 5th level: gems
      rewards.push({
        bpLevel: level,
        isPremium: false,
        rewardType: 'gems',
        rewardId: null,
        rewardAmount: level <= 10 ? 5 : level <= 20 ? 10 : 20,
      })
    } else if (level % 3 === 0) {
      // Every 3rd level: XP
      rewards.push({
        bpLevel: level,
        isPremium: false,
        rewardType: 'xp',
        rewardId: null,
        rewardAmount: 200 + level * 50,
      })
    } else {
      // Other levels: gold
      rewards.push({
        bpLevel: level,
        isPremium: false,
        rewardType: 'gold',
        rewardId: null,
        rewardAmount: 100 + level * 30,
      })
    }

    // Premium rewards (better versions)
    if (level % 10 === 0) {
      // Every 10th level: curated milestone item
      rewards.push({
        bpLevel: level,
        isPremium: true,
        rewardType: 'item',
        rewardId: itemIdByCatalogId.get(milestoneCatalogIds[level]) ?? null,
        rewardAmount: 1,
      })
    } else if (level % 5 === 0) {
      // Every 5th level: gems (more than free)
      rewards.push({
        bpLevel: level,
        isPremium: true,
        rewardType: 'gems',
        rewardId: null,
        rewardAmount: level <= 10 ? 15 : level <= 20 ? 25 : 50,
      })
    } else if (level % 2 === 0) {
      // Even levels: gold (more)
      rewards.push({
        bpLevel: level,
        isPremium: true,
        rewardType: 'gold',
        rewardId: null,
        rewardAmount: 200 + level * 50,
      })
    } else {
      // Odd levels: stamina or XP
      rewards.push({
        bpLevel: level,
        isPremium: true,
        rewardType: level % 4 === 1 ? 'stamina' : 'xp',
        rewardId: null,
        rewardAmount: level % 4 === 1 ? 30 + level * 2 : 300 + level * 60,
      })
    }
  }

  // Insert all rewards
  await prisma.battlePassReward.createMany({
    data: rewards.map((r) => ({
      seasonId: season.id,
      ...r,
    })),
  })

  console.log(`Created ${rewards.length} battle pass rewards (${rewards.length / 2} levels × 2 tracks)`)
  console.log('Done!')
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
