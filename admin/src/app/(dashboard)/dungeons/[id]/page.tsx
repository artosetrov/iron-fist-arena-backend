import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { DungeonEditor } from './dungeon-editor'

async function getDungeon(id: string) {
  return prisma.dungeon.findUnique({
    where: { id },
    include: {
      bosses: { include: { abilities: true }, orderBy: { floorNumber: 'asc' } },
      waves: { include: { enemies: true }, orderBy: { waveNumber: 'asc' } },
      drops: { include: { item: true } },
    },
  })
}

async function getItems() {
  return prisma.item.findMany({
    select: { id: true, itemName: true, rarity: true, itemType: true, itemLevel: true },
    orderBy: [{ rarity: 'desc' }, { itemName: 'asc' }],
  })
}

export default async function DungeonEditorPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const [dungeon, items] = await Promise.all([getDungeon(id), getItems()])

  if (!dungeon) notFound()

  return (
    <DungeonEditor
      dungeon={JSON.parse(JSON.stringify(dungeon))}
      items={JSON.parse(JSON.stringify(items))}
    />
  )
}
