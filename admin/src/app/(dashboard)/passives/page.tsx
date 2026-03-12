import { prisma } from '@/lib/prisma'
import { PassivesClient } from './passives-client'

async function getPassiveData() {
  const [nodes, connections] = await Promise.all([
    prisma.passiveNode.findMany({
      orderBy: [{ tier: 'asc' }, { name: 'asc' }],
    }),
    prisma.passiveConnection.findMany({
      include: {
        fromNode: { select: { id: true, name: true, nodeKey: true } },
        toNode: { select: { id: true, name: true, nodeKey: true } },
      },
    }),
  ])
  return { nodes, connections }
}

export default async function PassivesPage() {
  const { nodes, connections } = await getPassiveData()
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Passive Skill Tree</h1>
        <p className="text-muted-foreground">
          Manage passive nodes and tree connections. {nodes.length} nodes, {connections.length} connections.
        </p>
      </div>
      <PassivesClient
        nodes={JSON.parse(JSON.stringify(nodes))}
        connections={JSON.parse(JSON.stringify(connections))}
      />
    </div>
  )
}
