import { getConfig } from '@/actions/config'
import { DailyLoginClient } from './daily-login-client'

interface DailyLoginReward {
  type: 'gold' | 'gems' | 'consumable'
  amount: number
  itemId?: string
}

export default async function DailyLoginPage() {
  const rewards = await getConfig('daily_login_rewards')
  const defaultRewards: DailyLoginReward[] = [
    { type: 'gold', amount: 200 },
    { type: 'consumable', amount: 1, itemId: 'stamina_potion_small' },
    { type: 'gold', amount: 500 },
    { type: 'consumable', amount: 2, itemId: 'stamina_potion_small' },
    { type: 'gold', amount: 1000 },
    { type: 'consumable', amount: 1, itemId: 'stamina_potion_large' },
    { type: 'gems', amount: 5 },
  ]

  const rewardsData = (rewards as DailyLoginReward[] | null) ?? defaultRewards

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Daily Login Rewards</h1>
        <p className="text-muted-foreground">
          Configure the 7-day reward cycle for daily login.
        </p>
      </div>
      <DailyLoginClient rewards={rewardsData} />
    </div>
  )
}
