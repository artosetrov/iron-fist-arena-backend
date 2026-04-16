'use client'

type DividerProps = {
  className?: string
  style?: 'Gold' | 'Ornamental' | 'Etched Groove'
}

export function DSDivider({ className, style = 'Gold' }: DividerProps) {
  const isOrnamental = style === 'Ornamental'
  const isEtched = style === 'Etched Groove'

  if (isEtched) {
    return (
      <div className={className || 'flex flex-col h-[2px] w-[360px] relative'}>
        <div className="bg-[rgba(0,0,0,0.25)] h-px w-full" />
        <div className="bg-[rgba(255,255,255,0.06)] h-px w-full" />
      </div>
    )
  }

  return (
    <div className={className || `flex items-center justify-center relative w-[360px] ${isOrnamental ? 'h-[8px]' : 'h-[10px]'}`}>
      <div className={`bg-gradient-to-r from-[rgba(0,0,0,0)] flex-1 min-h-px ${isOrnamental ? 'h-px to-[#3a3a50] via-[#2a2a3e] via-50%' : 'h-[1.5px] to-[#d4a537] via-[#8b6915] via-50%'}`} />
      <div className={`flex items-center justify-center shrink-0 ${isOrnamental ? 'size-[8.485px]' : 'size-[11.314px]'}`}>
        <div className="-rotate-45">
          <div className={isOrnamental ? 'bg-[#8b6914] size-[6px]' : 'bg-[#d4a537] size-[8px]'} />
        </div>
      </div>
      <div className={`bg-gradient-to-r flex-1 to-[rgba(0,0,0,0)] min-h-px ${isOrnamental ? 'from-[#3a3a50] h-px via-[#2a2a3e] via-50%' : 'from-[#d4a537] h-[1.5px] via-[#8b6915] via-50%'}`} />
    </div>
  )
}

export function DividerAllVariants() {
  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Gold</p>
        <DSDivider style="Gold" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Ornamental</p>
        <DSDivider style="Ornamental" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Etched Groove</p>
        <DSDivider style="Etched Groove" />
      </div>
    </div>
  )
}
