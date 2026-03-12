'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { seedDefaultConfigs } from '@/actions/config'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { Database, Users, RefreshCw, CheckCircle, XCircle, Shield } from 'lucide-react'
import { formatDate } from '@/lib/utils'

type AdminUser = {
  id: string
  email: string | null
  username: string | null
  role: string
  lastLogin: string | null
  createdAt: string
}

export function SettingsClient({
  adminUsers,
  configCount,
  dbConnected,
  currentAdminId,
}: {
  adminUsers: AdminUser[]
  configCount: number
  dbConnected: boolean
  currentAdminId: string
}) {
  const router = useRouter()
  const [isPending, startTransition] = useTransition()
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  async function handleSeedDefaults() {
    setMessage('')
    setError('')
    startTransition(async () => {
      try {
        const result = await seedDefaultConfigs()
        setMessage(`Seeded ${result.created} configs (${result.skipped} already existed, ${result.total} total defaults)`)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to seed configs')
      }
    })
  }

  async function handleRoleChange(userId: string, newRole: string) {
    setMessage('')
    setError('')
    startTransition(async () => {
      try {
        const res = await fetch('/api/settings/role', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId, role: newRole }),
        })
        if (!res.ok) {
          const data = await res.json()
          setError(data.error || 'Failed to update role')
          return
        }
        setMessage(`Role updated successfully`)
        router.refresh()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to update role')
      }
    })
  }

  return (
    <>
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/30 px-4 py-3 text-sm text-destructive">
          {error}
        </div>
      )}
      {message && (
        <div className="rounded-md bg-green-600/10 border border-green-600/30 px-4 py-3 text-sm text-green-400">
          {message}
        </div>
      )}

      {/* Server Info */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Database className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Server Information</CardTitle>
          </div>
          <CardDescription>Current system status and database connectivity.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="rounded-lg border border-border p-4">
              <p className="text-xs text-muted-foreground mb-1">Database Connection</p>
              <div className="flex items-center gap-2">
                {dbConnected ? (
                  <>
                    <CheckCircle className="h-4 w-4 text-green-400" />
                    <span className="text-sm font-medium text-green-400">Connected</span>
                  </>
                ) : (
                  <>
                    <XCircle className="h-4 w-4 text-destructive" />
                    <span className="text-sm font-medium text-destructive">Disconnected</span>
                  </>
                )}
              </div>
            </div>
            <div className="rounded-lg border border-border p-4">
              <p className="text-xs text-muted-foreground mb-1">Game Configs</p>
              <p className="text-sm font-medium">{configCount} keys</p>
            </div>
            <div className="rounded-lg border border-border p-4">
              <p className="text-xs text-muted-foreground mb-1">Admin Users</p>
              <p className="text-sm font-medium">{adminUsers.length} users</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Seed Defaults */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <RefreshCw className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Game Config Defaults</CardTitle>
          </div>
          <CardDescription>
            Seed the default game configuration values. Existing keys will not be overwritten.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={handleSeedDefaults} disabled={isPending}>
            <RefreshCw className="mr-2 h-4 w-4" />
            {isPending ? 'Seeding...' : 'Seed Default Configs'}
          </Button>
        </CardContent>
      </Card>

      {/* Admin Role Management */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Admin Users</CardTitle>
          </div>
          <CardDescription>
            Manage admin roles. Only users with admin, moderator, or developer roles can access this dashboard.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {adminUsers.length === 0 ? (
            <p className="text-sm text-muted-foreground">No admin users found.</p>
          ) : (
            <div className="rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/50">
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">User</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Email</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Role</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Last Login</th>
                    <th className="px-4 py-3 text-left font-medium text-muted-foreground">Joined</th>
                  </tr>
                </thead>
                <tbody>
                  {adminUsers.map((user) => (
                    <tr key={user.id} className="border-b border-border">
                      <td className="px-4 py-3 font-medium">
                        {user.username || '---'}
                        {user.id === currentAdminId && (
                          <Badge variant="secondary" className="ml-2 text-xs">You</Badge>
                        )}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{user.email || '---'}</td>
                      <td className="px-4 py-3">
                        {user.id === currentAdminId ? (
                          <Badge>{user.role}</Badge>
                        ) : (
                          <Select
                            value={user.role}
                            onValueChange={(v) => handleRoleChange(user.id, v)}
                            disabled={isPending}
                          >
                            <SelectTrigger className="w-[140px] h-8">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="admin">admin</SelectItem>
                              <SelectItem value="moderator">moderator</SelectItem>
                              <SelectItem value="developer">developer</SelectItem>
                              <SelectItem value="player">player (revoke)</SelectItem>
                            </SelectContent>
                          </Select>
                        )}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {user.lastLogin ? formatDate(user.lastLogin) : 'Never'}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground text-xs">
                        {formatDate(user.createdAt)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </>
  )
}
