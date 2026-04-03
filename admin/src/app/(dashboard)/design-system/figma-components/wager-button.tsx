'use client'
type WagerButtonProps = { state?: 'Default' | 'Selected' | 'Disabled' }

export function DSWagerButton({ state = 'Default' }: WagerButtonProps) {
  const cls = state === 'Disabled'
    ? 'bg-[#16213e] border border-[#2a2a3e] opacity-40'
    : state === 'Selected'
    ? 'bg-gradient-to-b from-[#d4a537] to-[#b8860b] border-[1.5px] border-[rgba(255,215,0,0.6)]'
    : 'bg-[#16213e] border border-[#2a2a3e]'
  const textColor = state === 'Selected' ? 'text-[#1a1a2e]' : 'text-[#f5f5f5]'
  return (
    <div className={`border-solid flex h-[34px] items-center justify-center px-[12px] rounded-[6px] ${cls}`}>
      <p className={`font-["Oswald",sans-serif] font-normal leading-[24px] text-[18px] tracking-[2px] ${textColor}`}>100</p>
    </div>
  )
}

export function WagerButtonAllVariants() {
  return (
    <div className="flex gap-3 items-center">
      <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;700&display=swap" rel="stylesheet" />
      <div><p className="text-xs text-[#6B6B80] mb-1">Default</p><DSWagerButton state="Default" /></div>
      <div><p className="text-xs text-[#6B6B80] mb-1">Selected</p><DSWagerButton state="Selected" /></div>
      <div><p className="text-xs text-[#6B6B80] mb-1">Disabled</p><DSWagerButton state="Disabled" /></div>
    </div>
  )
}
