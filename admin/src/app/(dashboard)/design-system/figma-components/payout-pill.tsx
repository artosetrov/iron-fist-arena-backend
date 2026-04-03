'use client'
type PayoutPillProps = { multiplier?: 'x1.5' | 'x2' | 'x3' | 'x5' }

export function DSPayoutPill({ multiplier = 'x1.5' }: PayoutPillProps) {
  const config: Record<string, { bg: string; border: string; textColor: string; sectors: string; icon: string }> = {
    'x1.5': { bg: 'bg-[rgba(212,165,55,0.06)]', border: 'border-[rgba(212,165,55,0.15)]', textColor: 'text-[#d4a537]', sectors: '3 sectors', icon: '🪙' },
    'x2': { bg: 'bg-[rgba(255,215,0,0.06)]', border: 'border-[rgba(255,215,0,0.15)]', textColor: 'text-[#ffd700]', sectors: '1 sector', icon: '📦' },
    'x3': { bg: 'bg-[rgba(155,89,182,0.06)]', border: 'border-[rgba(155,89,182,0.15)]', textColor: 'text-[#9b59b6]', sectors: '1 sector', icon: '⬆️' },
    'x5': { bg: 'bg-[rgba(52,152,219,0.06)]', border: 'border-[rgba(52,152,219,0.15)]', textColor: 'text-[#3498db]', sectors: '1 sector', icon: '💎' },
  }
  const c = config[multiplier]
  return (
    <div className={`border border-solid flex flex-col gap-[4px] items-center px-[4px] py-[8px] rounded-[8px] w-[80px] ${c.bg} ${c.border}`}>
      <div className="flex items-center justify-center rounded-[4px] size-[48px] bg-[rgba(255,255,255,0.05)]">
        <span className="text-[24px]">{c.icon}</span>
      </div>
      <p className={`font-["Inter",sans-serif] font-normal text-[14px] ${c.textColor}`}>{multiplier}</p>
      <p className='font-["Inter",sans-serif] font-normal text-[11px] text-[#6b6b80]'>{c.sectors}</p>
    </div>
  )
}

export function PayoutPillAllVariants() {
  return (
    <div className="flex gap-3">
      <DSPayoutPill multiplier="x1.5" />
      <DSPayoutPill multiplier="x2" />
      <DSPayoutPill multiplier="x3" />
      <DSPayoutPill multiplier="x5" />
    </div>
  )
}
