import { getBattlePassRewards, getSeasons } from '@/actions/battle-pass-rewards'
import { BattlePassClient } from './battle-pass-client'

export default async function BattlePassPage() {
  const [rewards, seasons] = await Promise.all([
    getBattlePassRewards(),
    getSeasons(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Battle Pass Rewards</h1>
        <p className="text-muted-foreground">
          Manage rewards for each Battle Pass level by season.
        </p>
      </div>
      <BattlePassClient
        rewards={JSON.parse(JSON.stringify(rewards))}
        seasons={JSON.parse(JSON.stringify(seasons))}
      />
    </div>
  )
}
