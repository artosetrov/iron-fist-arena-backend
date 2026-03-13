import { PrismaClient } from '@prisma/client'
import { repairBattlePassRewards } from './battle-pass-reward-repair'

const prisma = new PrismaClient()

async function main() {
  console.log('Repairing legacy battle pass milestone rewards...')
  const updatedCount = await repairBattlePassRewards(prisma)
  console.log(`Battle pass repair complete. Updated ${updatedCount} reward rows.`)
}

main()
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
