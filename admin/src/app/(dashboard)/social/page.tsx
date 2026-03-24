import { prisma } from '@/lib/prisma'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Users, Swords, MessageSquare, ShieldAlert, Clock } from 'lucide-react'
import Link from 'next/link'

async function getSocialStats() {
  const now = new Date()
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate())

  const [
    totalFriendships,
    activeFriendships,
    blockedCount,
    totalMessages,
    messagesToday,
    totalChallenges,
    pendingChallenges,
    completedChallenges,
  ] = await Promise.all([
    prisma.friendship.count(),
    prisma.friendship.count({ where: { status: 'accepted' } }),
    prisma.friendship.count({ where: { status: 'blocked' } }),
    prisma.directMessage.count(),
    prisma.directMessage.count({ where: { createdAt: { gte: startOfDay } } }),
    prisma.challenge.count(),
    prisma.challenge.count({ where: { status: 'pending' } }),
    prisma.challenge.count({ where: { status: 'completed' } }),
  ])

  return {
    totalFriendships,
    activeFriendships,
    blockedCount,
    totalMessages,
    messagesToday,
    totalChallenges,
    pendingChallenges,
    completedChallenges,
  }
}

async function getRecentMessages() {
  return prisma.directMessage.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
    select: {
      id: true,
      content: true,
      isQuick: true,
      quickId: true,
      isRead: true,
      createdAt: true,
      sender: { select: { id: true, characterName: true, user: { select: { id: true } } } },
      receiver: { select: { id: true, characterName: true, user: { select: { id: true } } } },
    },
  })
}

async function getRecentChallenges() {
  return prisma.challenge.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
    select: {
      id: true,
      status: true,
      message: true,
      goldWager: true,
      createdAt: true,
      expiresAt: true,
      respondedAt: true,
      completedAt: true,
      matchId: true,
      challenger: { select: { id: true, characterName: true, user: { select: { id: true } } } },
      defender: { select: { id: true, characterName: true, user: { select: { id: true } } } },
    },
  })
}

async function getRecentFriendships() {
  return prisma.friendship.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
    select: {
      id: true,
      status: true,
      createdAt: true,
      user: { select: { id: true, characterName: true, user: { select: { id: true } } } },
      friend: { select: { id: true, characterName: true, user: { select: { id: true } } } },
    },
  })
}

function formatDate(date: Date | string) {
  return new Date(date).toLocaleString('en-GB', {
    day: '2-digit', month: 'short',
    hour: '2-digit', minute: '2-digit',
  })
}

function statusBadge(status: string) {
  switch (status) {
    case 'pending': return <Badge variant="warning">Pending</Badge>
    case 'accepted': return <Badge variant="success">Accepted</Badge>
    case 'declined': return <Badge variant="destructive">Declined</Badge>
    case 'completed': return <Badge variant="success">Completed</Badge>
    case 'expired': return <Badge variant="secondary">Expired</Badge>
    case 'blocked': return <Badge variant="destructive">Blocked</Badge>
    default: return <Badge variant="secondary">{status}</Badge>
  }
}

function PlayerLink({ name, userId }: { name: string; userId?: string }) {
  if (userId) {
    return (
      <Link href={`/players/${userId}`} className="font-medium text-primary hover:underline">
        {name}
      </Link>
    )
  }
  return <span className="font-medium">{name}</span>
}

export default async function SocialPage() {
  const [stats, messages, challenges, friendships] = await Promise.all([
    getSocialStats(),
    getRecentMessages(),
    getRecentChallenges(),
    getRecentFriendships(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Social Hub</h1>
        <p className="text-muted-foreground">Friendships, messages, and challenge duels.</p>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Friendships</CardTitle>
            <Users className="h-4 w-4 text-blue-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeFriendships}</div>
            <p className="text-xs text-muted-foreground">
              {stats.totalFriendships} total · {stats.blockedCount} blocked
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Messages</CardTitle>
            <MessageSquare className="h-4 w-4 text-green-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalMessages.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              {stats.messagesToday} today
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Challenges</CardTitle>
            <Swords className="h-4 w-4 text-amber-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalChallenges}</div>
            <p className="text-xs text-muted-foreground">
              {stats.pendingChallenges} pending · {stats.completedChallenges} completed
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Blocked</CardTitle>
            <ShieldAlert className="h-4 w-4 text-red-400" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.blockedCount}</div>
            <p className="text-xs text-muted-foreground">blocked relationships</p>
          </CardContent>
        </Card>
      </div>

      {/* Messages Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MessageSquare className="h-5 w-5" />
            Recent Messages (last 50)
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="rounded-b-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">From</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">To</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Content</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Read</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                </tr>
              </thead>
              <tbody>
                {messages.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">No messages yet.</td>
                  </tr>
                ) : (
                  messages.map((msg) => (
                    <tr key={msg.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <PlayerLink name={msg.sender.characterName} userId={msg.sender.user?.id} />
                      </td>
                      <td className="px-4 py-3">
                        <PlayerLink name={msg.receiver.characterName} userId={msg.receiver.user?.id} />
                      </td>
                      <td className="px-4 py-3 max-w-[300px] truncate text-muted-foreground">
                        {msg.content}
                      </td>
                      <td className="px-4 py-3">
                        {msg.isQuick ? (
                          <Badge variant="secondary">{msg.quickId ?? 'quick'}</Badge>
                        ) : (
                          <Badge variant="outline">text</Badge>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        {msg.isRead ? (
                          <span className="text-green-400 text-xs">✓</span>
                        ) : (
                          <span className="text-amber-400 text-xs">unread</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(msg.createdAt)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Challenges Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Swords className="h-5 w-5" />
            Recent Challenges (last 50)
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="rounded-b-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Challenger</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Defender</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Message</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Wager</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Created</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Expires</th>
                </tr>
              </thead>
              <tbody>
                {challenges.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">No challenges yet.</td>
                  </tr>
                ) : (
                  challenges.map((ch) => (
                    <tr key={ch.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <PlayerLink name={ch.challenger.characterName} userId={ch.challenger.user?.id} />
                      </td>
                      <td className="px-4 py-3">
                        <PlayerLink name={ch.defender.characterName} userId={ch.defender.user?.id} />
                      </td>
                      <td className="px-4 py-3">
                        {statusBadge(ch.status)}
                      </td>
                      <td className="px-4 py-3 max-w-[200px] truncate text-xs text-muted-foreground">
                        {ch.message ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground">
                        {ch.goldWager > 0 ? `${ch.goldWager}g` : '—'}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(ch.createdAt)}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {ch.status === 'pending' ? formatDate(ch.expiresAt) : '—'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Friendships Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Recent Friendships (last 50)
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="rounded-b-lg overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Player 1</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Player 2</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Date</th>
                </tr>
              </thead>
              <tbody>
                {friendships.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-muted-foreground">No friendships yet.</td>
                  </tr>
                ) : (
                  friendships.map((f) => (
                    <tr key={f.id} className="border-b border-border hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <PlayerLink name={f.user.characterName} userId={f.user.user?.id} />
                      </td>
                      <td className="px-4 py-3">
                        <PlayerLink name={f.friend.characterName} userId={f.friend.user?.id} />
                      </td>
                      <td className="px-4 py-3">
                        {statusBadge(f.status)}
                      </td>
                      <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">
                        {formatDate(f.createdAt)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
