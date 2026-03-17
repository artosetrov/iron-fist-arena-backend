import { getConfig } from '@/actions/config'
import { DailyLoginClient } from './daily-login-client'

export default async function DailyLoginPage() {
  const rewards = await getConfig('daily_login_rewards')
  const defaultRewards = [
    { type: 'gold', amount: 200 },
    { type: 'consumable', amount: 1, itemId: 'stamina_potion_small' },
    { type: 'gold', amount: 500 },
    { type: 'consumable', amount: 2, itemId: 'stamina_potion_small' },
    { type: 'gold', amount: 1000 },
    { type: 'consumable', amount: 1, itemId: 'stamina_potion_large' },
    { type: 'gems', amount: 5 },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Daily Login Rewards</h1>
        <p className="text-muted-foreground">
          Configure the 7-day reward cycle for daily login.
        </p>
      </div>
      <DailyLoginClient rewards={(rewards ?? defaultRewards) as any[]} />
    </div>
  )
}
