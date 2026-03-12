import { AssetsClient } from './assets-client'

export default function AssetsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Assets</h1>
        <p className="text-muted-foreground">
          Manage uploaded images and game assets in Supabase Storage.
        </p>
      </div>
      <AssetsClient />
    </div>
  )
}
