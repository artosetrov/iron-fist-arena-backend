import { prisma } from '@/lib/prisma'
import { SeasonsClient } from './seasons-client'

async function getSeasons() {
  return prisma.season.findMany({
    orderBy: { number: 'desc' },
  })
}

export default async function SeasonsPage() {
  const seasons = await getSeasons()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Seasons</h1>
        <p className="text-muted-foreground">
          Manage competitive seasons and battle passes. {seasons.length} seasons total.
        </p>
      </div>
      <SeasonsClient seasons={JSON.parse(JSON.stringify(seasons))} />
    </div>
  )
}
