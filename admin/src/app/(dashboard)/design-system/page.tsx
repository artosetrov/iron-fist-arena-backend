import { DesignSystemClient } from './design-system-client'

export default function DesignSystemPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Design System</h1>
        <p className="text-muted-foreground">
          Hexbound DS — tokens, components, and screens. Mirrors Figma DS and SwiftUI code 1:1.
        </p>
      </div>
      <DesignSystemClient />
    </div>
  )
}
