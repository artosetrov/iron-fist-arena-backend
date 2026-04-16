import { getBalanceConfigs } from '@/actions/balance'
import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { BalanceClient } from './balance-client'

export default async function BalancePage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  const configs = await getBalanceConfigs()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Game Balance</h1>
        <p className="text-muted-foreground">
          Manage primary live balance tuning surfaces. Specialized potion values stay on
          Consumables, and raw fallback keys remain available in Live Config. {configs.length}{' '}
          values loaded.
        </p>
      </div>
      <BalanceClient configs={JSON.parse(JSON.stringify(configs))} />
    </div>
  )
}
