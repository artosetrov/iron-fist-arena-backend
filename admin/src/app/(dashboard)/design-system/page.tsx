import { DesignSystemClient } from './design-system-client'

export default function DesignSystemPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Design System</h1>
        <p className="text-muted-foreground">
          Hexbound DS — shared tokens, Figma-aligned component previews, and live reference screens.
        </p>
      </div>
      <DesignSystemClient />
    </div>
  )
}
