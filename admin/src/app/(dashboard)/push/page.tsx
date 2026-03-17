import { listCampaigns, getPushStats } from '@/actions/push'
import { PushClient } from './push-client'

export default async function PushPage() {
  const [campaigns, stats] = await Promise.all([
    listCampaigns(),
    getPushStats(),
  ])
  return <PushClient initialCampaigns={JSON.parse(JSON.stringify(campaigns))} stats={stats} />
}
