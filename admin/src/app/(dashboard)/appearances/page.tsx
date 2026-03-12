import { getAppearances } from '@/actions/appearances'
import { AppearancesClient } from './appearances-client'

export default async function AppearancesPage() {
  const skins = await getAppearances()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Appearances</h1>
        <p className="text-muted-foreground">
          Manage hero skins and avatars for the Change Appearance feature. {skins.length} skins total.
        </p>
      </div>
      <AppearancesClient skins={JSON.parse(JSON.stringify(skins))} />
    </div>
  )
}
