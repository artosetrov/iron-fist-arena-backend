import { prisma } from '@/lib/prisma'
import { DungeonsClient } from './dungeons-client'

async function getDungeons() {
  return prisma.dungeon.findMany({
    include: {
      bosses: { orderBy: { floorNumber: 'asc' }, select: { id: true, name: true, floorNumber: true } },
      _count: { select: { waves: true, drops: true } },
    },
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
  })
}

export default async function DungeonsPage() {
  const dungeons = await getDungeons()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dungeon Editor</h1>
        <p className="text-muted-foreground">
          Create, edit and balance dungeons. {dungeons.length} dungeons total.
        </p>
      </div>
      <DungeonsClient dungeons={JSON.parse(JSON.stringify(dungeons))} />
    </div>
  )
}
