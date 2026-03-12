import { searchPlayers } from '@/actions/players'
import { PlayersClient } from './players-client'

export default async function PlayersPage() {
  const result = await searchPlayers('', 1)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Players</h1>
        <p className="text-muted-foreground">
          Search and manage player accounts. {result.total} players total.
        </p>
      </div>
      <PlayersClient
        initialPlayers={JSON.parse(JSON.stringify(result.users))}
        initialTotal={result.total}
        initialPage={result.page}
        pageSize={result.pageSize}
      />
    </div>
  )
}
