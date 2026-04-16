'use client'

/**
 * AUTO-GENERATED FROM FIGMA DS via get_design_context
 * Component: Currency Display (Standard, Compact, Mini)
 * File: Hexbound-DS (uDjXIz7CdJxcEOI5jCBcjY)
 * DO NOT EDIT MANUALLY — regenerate from Figma
 */

type CurrencyDisplaySize = 'Standard' | 'Compact' | 'Mini'

type CurrencyDisplayProps = {
  size?: CurrencyDisplaySize
  gold?: string
  gems?: string
}

function GoldIcon({ diameter }: { diameter: number }) {
  return (
    <div
      className="rounded-full flex-shrink-0"
      style={{ width: diameter, height: diameter, backgroundColor: '#d4a537' }}
    />
  )
}

function GemIcon({ diameter }: { diameter: number }) {
  return (
    <div
      className="rounded-full flex-shrink-0"
      style={{ width: diameter, height: diameter, backgroundColor: '#00d4ff' }}
    />
  )
}

export function DSCurrencyDisplay({ size = 'Standard', gold = '12,450', gems = '385' }: CurrencyDisplayProps) {
  if (size === 'Standard') {
    return (
      <div className="h-[36px] flex items-center gap-[12px]">
        {/* Gold */}
        <div className="flex items-center gap-[6px]">
          <GoldIcon diameter={28} />
          <span className="font-['Oswald'] text-[22px] text-[#ffd700] leading-none">{gold}</span>
        </div>
        {/* Gems */}
        <div className="flex items-center gap-[6px]">
          <GemIcon diameter={28} />
          <span className="font-['Oswald'] text-[22px] text-[#00d4ff] leading-none">{gems}</span>
        </div>
      </div>
    )
  }

  if (size === 'Compact') {
    return (
      <div className="h-[24px] flex items-center gap-[8px]">
        {/* Gold */}
        <div className="flex items-center gap-[4px]">
          <GoldIcon diameter={16} />
          <span className="font-['Oswald'] text-[18px] text-[#ffd700] leading-none">{gold}</span>
        </div>
        {/* Gems */}
        <div className="flex items-center gap-[4px]">
          <GemIcon diameter={16} />
          <span className="font-['Oswald'] text-[18px] text-[#00d4ff] leading-none">{gems}</span>
        </div>
      </div>
    )
  }

  // Mini — gold only
  return (
    <div className="h-[24px] flex items-center gap-[4px]">
      <GoldIcon diameter={16} />
      <span className="font-['Oswald'] text-[18px] tracking-[2px] text-[#ffd700] leading-none">
        {gold === '12,450' ? '500' : gold}
      </span>
    </div>
  )
}

const ALL_SIZES: CurrencyDisplaySize[] = ['Standard', 'Compact', 'Mini']

export function CurrencyDisplayAllVariants() {
  return (
    <>
      <div className="flex flex-col gap-[24px] p-[24px]">
        <h2 className="font-['Oswald'] text-[22px] text-[#ffd700] uppercase tracking-[2px] mb-[8px]">
          Currency Display — All Sizes
        </h2>
        {ALL_SIZES.map((s) => (
          <div key={s} className="flex flex-col gap-[8px]">
            <span className="font-['Inter'] text-[12px] text-[#6b6b80]">{s}</span>
            <DSCurrencyDisplay size={s} />
          </div>
        ))}
      </div>
    </>
  )
}
