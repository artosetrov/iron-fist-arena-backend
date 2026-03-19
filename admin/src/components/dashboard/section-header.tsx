export function SectionHeader({ title, description }: { title: string; description?: string }) {
  return (
    <div className="pt-2">
      <h2 className="text-base font-semibold tracking-tight">{title}</h2>
      {description && <p className="text-xs text-muted-foreground">{description}</p>}
    </div>
  )
}
