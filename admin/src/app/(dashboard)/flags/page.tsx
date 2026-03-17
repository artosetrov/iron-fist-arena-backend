import { listFeatureFlags, getFeatureFlagStats } from '@/actions/feature-flags'
import { FlagsClient } from './flags-client'

export default async function FlagsPage() {
  const [flags, stats] = await Promise.all([
    listFeatureFlags(),
    getFeatureFlagStats(),
  ])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Feature Flags</h1>
        <p className="text-muted-foreground">
          Control feature rollouts, A/B tests, and kill switches.
        </p>
      </div>
      <FlagsClient initialFlags={flags} stats={stats} />
    </div>
  )
}
