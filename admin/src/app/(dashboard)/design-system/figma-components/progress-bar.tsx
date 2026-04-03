'use client'

type ProgressBarProps = {
  className?: string
  size?: 'compact' | 'widget' | 'large'
  type?: 'HP Full' | 'HP Medium' | 'HP Critical' | 'XP' | 'Stamina'
}

export function DSProgressBar({ size = 'compact', type = 'HP Full' }: ProgressBarProps) {
  const isLarge = size === 'large'
  const isWidget = size === 'widget'
  const showText = isLarge || isWidget

  const height = isLarge ? 'h-[24px]' : isWidget ? 'h-[22px]' : 'h-[14px]'
  const radius = size === 'compact' ? 'rounded-[4px]' : 'rounded-[6px]'

  const fillColors: Record<string, string> = {
    'HP Full': 'from-[#2ecc71] to-[#55efc4]',
    'HP Medium': 'from-[#e67e22] to-[#f1c40f]',
    'HP Critical': 'from-[#c0392b] to-[#e74c3c]',
    'XP': 'from-[#9b59b6] to-[#8e44ad]',
    'Stamina': 'from-[#e67e22] to-[#d35400]',
  }

  const fillWidths: Record<string, string> = {
    'HP Full': 'w-[238px]',
    'HP Medium': 'w-[126px]',
    'HP Critical': 'w-[50.4px]',
    'XP': 'w-[173.6px]',
    'Stamina': 'w-[198.8px]',
  }

  const labels: Record<string, string> = {
    'HP Full': '245 / 320',
    'HP Medium': '245 / 320',
    'HP Critical': '245 / 320',
    'XP': '1,240 / 2,000',
    'Stamina': '85 / 120',
  }

  const highlightH = isLarge ? 'h-[12px]' : isWidget ? 'h-[11px]' : 'h-[7px]'

  return (
    <div className={`bg-[#16213e] overflow-clip relative w-[280px] ${height} ${radius}`}>
      <div className={`absolute bg-gradient-to-r left-0 top-0 ${fillColors[type]} ${fillWidths[type]} ${height} ${radius}`} />
      <div className={`absolute bg-gradient-to-b from-[rgba(255,255,255,0.28)] to-[rgba(255,255,255,0)] left-0 top-0 ${fillWidths[type]} ${highlightH} ${radius}`} />
      {showText && (
        <p className={`absolute left-1/2 -translate-x-1/2 font-["Inter",sans-serif] font-bold text-center text-white whitespace-nowrap ${isLarge ? 'text-[13px] top-[4px]' : 'text-[11px] top-[4.5px]'}`} style={{ textShadow: '0px 1px 2px rgba(0,0,0,0.5)' }}>
          {labels[type]}
        </p>
      )}
    </div>
  )
}

export function ProgressBarAllVariants() {
  const types: Array<ProgressBarProps['type']> = ['HP Full', 'HP Medium', 'HP Critical', 'XP', 'Stamina']
  const sizes: Array<ProgressBarProps['size']> = ['compact', 'widget', 'large']
  return (
    <div className="space-y-1">
      <div className="grid grid-cols-3 gap-4 mb-2">
        <p className="text-xs text-[#6B6B80]">Compact</p>
        <p className="text-xs text-[#6B6B80]">Widget</p>
        <p className="text-xs text-[#6B6B80]">Large</p>
      </div>
      {types.map(t => (
        <div key={t} className="grid grid-cols-3 gap-4 items-center">
          {sizes.map(s => (
            <DSProgressBar key={`${t}-${s}`} type={t} size={s} />
          ))}
        </div>
      ))}
    </div>
  )
}
