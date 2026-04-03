'use client'
type CardLevelBadgeProps = { size?: 'Standard' | 'Compact' }

export function DSCardLevelBadge({ size = 'Standard' }: CardLevelBadgeProps) {
  const isCompact = size === 'Compact'
  return (
    <div className={`bg-[#1a1a2e] border-[#d4a537] border-solid flex flex-col items-center justify-center ${isCompact ? 'border-[1.5px] rounded-[18px] w-[36px] h-[36px]' : 'border-2 rounded-[24px] w-[48px] h-[48px]'}`}>
      <p className={`font-["Inter",sans-serif] font-bold text-[#ffd700] text-center whitespace-nowrap ${isCompact ? 'text-[15px]' : 'text-[18px]'}`}>25</p>
    </div>
  )
}

export function CardLevelBadgeAllVariants() {
  return (
    <div className="flex items-center gap-6">
      <div className="text-center"><DSCardLevelBadge size="Standard" /><p className="text-xs text-[#6B6B80] mt-1">Standard 48px</p></div>
      <div className="text-center"><DSCardLevelBadge size="Compact" /><p className="text-xs text-[#6B6B80] mt-1">Compact 36px</p></div>
    </div>
  )
}
