'use client'

type CardProps = {
  className?: string
  style?: 'Panel' | 'Panel Highlight' | 'Info' | 'Modal' | 'Rarity Common' | 'Rarity Uncommon' | 'Rarity Rare' | 'Rarity Epic' | 'Rarity Legendary'
}

export function DSCard({ className, style = 'Panel' }: CardProps) {
  const isInfo = style === 'Info'
  const isModal = style === 'Modal'
  const isPanelHighlight = style === 'Panel Highlight'
  const isRarityCommon = style === 'Rarity Common'
  const isRarityUncommon = style === 'Rarity Uncommon'
  const isRarityRare = style === 'Rarity Rare'
  const isRarityEpic = style === 'Rarity Epic'
  const isRarityLegendary = style === 'Rarity Legendary'
  const isRarity = ['Rarity Common', 'Rarity Uncommon', 'Rarity Rare', 'Rarity Epic', 'Rarity Legendary'].includes(style)

  const bg = isRarity ? 'bg-[#16213e]' : isModal ? 'bg-[#1a1a2e]' : isInfo ? 'bg-[#0d0d12]' : isPanelHighlight ? 'bg-[#1a1a2e]' : 'bg-[#1a1a2e]'

  const borderColor = isRarityLegendary ? 'border-[#ffbf1a]' : isRarityEpic ? 'border-[#a64de6]' : isRarityRare ? 'border-[#4d80ff]' : isRarityUncommon ? 'border-[#4dcc4d]' : isRarityCommon ? 'border-[#999999]' : isModal ? 'border-[#b8860b]' : isPanelHighlight ? 'border-[#d4a537]' : 'border-[#2a2a3e]'

  const borderWidth = isRarity ? 'border-[2.5px]' : isModal ? 'border-2' : isPanelHighlight ? 'border-[1.5px]' : 'border'

  const radius = isModal ? 'rounded-[16px]' : isInfo ? 'rounded-[8px]' : 'rounded-[12px]'

  const titleColor = isRarityLegendary ? 'text-[#ffbf1a]' : isRarityEpic ? 'text-[#a64de6]' : isRarityRare ? 'text-[#4d80ff]' : isRarityUncommon ? 'text-[#4dcc4d]' : isRarityCommon ? 'text-[#999999]' : isPanelHighlight ? 'text-[#ffd700]' : 'text-[#f5f5f5]'

  const title = isRarityLegendary ? 'Legendary Item' : isRarityEpic ? 'Epic Item' : isRarityRare ? 'Rare Item' : isRarityUncommon ? 'Uncommon Item' : isRarityCommon ? 'Common Item' : 'Card Title'

  return (
    <div className={className || `border-solid flex flex-col gap-[12px] h-[200px] items-start p-[16px] relative w-[320px] ${bg} ${borderColor} ${borderWidth} ${radius}`}>
      <p className={`font-["Oswald",sans-serif] font-normal text-[18px] ${titleColor}`}>{title}</p>
      <p className='font-["Inter",sans-serif] font-normal text-[14px] text-[#a0a0b0]'>Card content goes here. This is a placeholder for the card body text.</p>
      {/* Surface Lighting */}
      <div className={`absolute bg-gradient-to-b from-[rgba(255,255,255,0.08)] via-[rgba(255,255,255,0)] via-50% to-[rgba(0,0,0,0.12)] ${isRarity ? 'inset-[-2.5px] rounded-[12px]' : isModal ? 'inset-[-2px] rounded-[16px]' : isInfo ? 'inset-[-1px] rounded-[8px]' : isPanelHighlight ? 'inset-[-1.5px] rounded-[12px]' : 'inset-[-1px] rounded-[12px]'}`} />
      {/* Inner Border */}
      <div className={`absolute border border-[rgba(255,255,255,0.1)] border-solid ${isRarity ? 'inset-[1.5px] rounded-[8px]' : isModal ? 'inset-[2px] rounded-[12px]' : 'inset-[3px] rounded-[8px]'}`} />
    </div>
  )
}

export function CardAllVariants() {
  const styles: Array<CardProps['style']> = ['Panel', 'Panel Highlight', 'Info', 'Modal', 'Rarity Common', 'Rarity Uncommon', 'Rarity Rare', 'Rarity Epic', 'Rarity Legendary']
  return (
    <div>
      <div className="grid grid-cols-3 gap-4">
        {styles.map(s => (
          <DSCard key={s} style={s} />
        ))}
      </div>
    </div>
  )
}
