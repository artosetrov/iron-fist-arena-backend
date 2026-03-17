import { getQuestDefinitions } from '@/actions/quest-definitions'
import { QuestsClient } from './quests-client'

export default async function QuestsPage() {
  const quests = await getQuestDefinitions()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Quest Definitions</h1>
        <p className="text-muted-foreground">
          Manage daily quest configurations and rewards.
        </p>
      </div>
      <QuestsClient initialQuests={quests} />
    </div>
  )
}
