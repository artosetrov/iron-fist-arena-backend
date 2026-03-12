import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { SettingsClient } from './settings-client'

async function getAdminUsers() {
  return prisma.user.findMany({
    where: {
      role: { in: ['admin', 'moderator', 'developer'] },
    },
    select: {
      id: true,
      email: true,
      username: true,
      role: true,
      lastLogin: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'asc' },
  })
}

async function getConfigCount() {
  return prisma.gameConfig.count()
}

async function getDatabaseStatus() {
  try {
    await prisma.$queryRaw`SELECT 1`
    return true
  } catch {
    return false
  }
}

export default async function SettingsPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')
  if (admin.role !== 'admin') {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-bold tracking-tight">Settings</h1>
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          You do not have permission to access admin settings. Only admins can view this page.
        </div>
      </div>
    )
  }

  const [adminUsers, configCount, dbConnected] = await Promise.all([
    getAdminUsers(),
    getConfigCount(),
    getDatabaseStatus(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">
          Admin dashboard settings and system information.
        </p>
      </div>
      <SettingsClient
        adminUsers={JSON.parse(JSON.stringify(adminUsers))}
        configCount={configCount}
        dbConnected={dbConnected}
        currentAdminId={admin.id}
      />
    </div>
  )
}
