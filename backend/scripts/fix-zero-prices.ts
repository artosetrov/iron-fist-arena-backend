/**
 * One-off script: fix items with buyPrice = 0
 * Formula from seed-balance.ts:
 *   sellPrice = baseSellPrice[rarity] * itemLevel
 *   buyPrice  = sellPrice * 4
 *
 * Run: cd backend && npx tsx scripts/fix-zero-prices.ts
 */

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

const SELL_PRICE_BY_RARITY: Record<string, number> = {
  common: 10,
  uncommon: 25,
  rare: 60,
  epic: 150,
  legendary: 400,
}

const BUY_MULTIPLIER = 4

async function main() {
  const items = await prisma.item.findMany({
    where: {
      OR: [{ buyPrice: 0 }, { sellPrice: 0 }],
    },
    select: {
      id: true,
      itemName: true,
      rarity: true,
      itemLevel: true,
      buyPrice: true,
      sellPrice: true,
    },
  })

  if (items.length === 0) {
    console.log('No items with zero prices found. Nothing to fix.')
    return
  }

  console.log(`Found ${items.length} item(s) with zero prices:\n`)

  for (const item of items) {
    const baseSell = SELL_PRICE_BY_RARITY[item.rarity] ?? 10
    const newSellPrice = item.sellPrice > 0 ? item.sellPrice : baseSell * item.itemLevel
    const newBuyPrice = item.buyPrice > 0 ? item.buyPrice : newSellPrice * BUY_MULTIPLIER

    console.log(
      `  ${item.itemName} (${item.rarity}, lvl ${item.itemLevel}): ` +
        `sell ${item.sellPrice} → ${newSellPrice}, buy ${item.buyPrice} → ${newBuyPrice}`
    )

    await prisma.item.update({
      where: { id: item.id },
      data: {
        sellPrice: newSellPrice,
        buyPrice: newBuyPrice,
      },
    })
  }

  console.log(`\nDone. Updated ${items.length} item(s).`)
}

main()
  .catch((e) => {
    console.error('Error:', e)
    process.exit(1)
  })
  .finally(async () => await prisma.$disconnect())
