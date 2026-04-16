import { PrismaClient } from '@prisma/client'
import { backfillReferralRewardClaims } from './referral-reward-backfill'

const prisma = new PrismaClient()

async function main() {
  const apply = process.argv.includes('--apply')

  console.log(
    apply
      ? 'Applying referral qualification reward backfill...'
      : 'Dry-running referral qualification reward backfill...',
  )

  const result = await backfillReferralRewardClaims(prisma, { apply })

  console.log(JSON.stringify(result, null, 2))

  if (!apply) {
    console.log('Dry run only. Re-run with --apply to persist referral reward claims and currency grants.')
  }
}

main()
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
