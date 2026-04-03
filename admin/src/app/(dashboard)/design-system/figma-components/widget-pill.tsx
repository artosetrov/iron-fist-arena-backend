'use client'

/**
 * AUTO-GENERATED FROM FIGMA DS via get_design_context
 * Component: Widget Pill (10 styles)
 * File: Hexbound-DS (uDjXIz7CdJxcEOI5jCBcjY)
 * DO NOT EDIT MANUALLY — regenerate from Figma
 */

type WidgetPillStyle = 'Heal' | 'Urgent' | 'Energy' | 'Stat' | 'Warn' | 'PvP' | 'Streak' | 'Bonus' | 'Error' | 'Offline'

type WidgetPillProps = {
  style?: WidgetPillStyle
  label?: string
}

const PILL_CONFIG: Record<WidgetPillStyle, { bg: string; border: string; color: string; icon: string; label: string }> = {
  Heal:    { bg: 'bg-[rgba(46,204,113,0.12)]', border: 'border-[rgba(46,204,113,0.25)]', color: 'text-[#7bed9f]', icon: '💊', label: 'Use Potion' },
  Urgent:  { bg: 'bg-[rgba(230,57,70,0.12)]',  border: 'border-[rgba(230,57,70,0.3)]',  color: 'text-[#ff6b6b]', icon: '❗', label: 'Critical HP!' },
  Energy:  { bg: 'bg-[rgba(230,126,34,0.12)]', border: 'border-[rgba(230,126,34,0.25)]', color: 'text-[#e67e22]', icon: '⚡', label: 'Refill Stamina' },
  Stat:    { bg: 'bg-[rgba(212,165,55,0.12)]', border: 'border-[rgba(212,165,55,0.3)]',  color: 'text-[#ffd700]', icon: '⭐', label: '3 Stat Points' },
  Warn:    { bg: 'bg-[rgba(230,57,70,0.1)]',   border: 'border-[rgba(230,57,70,0.2)]',   color: 'text-[#ff6b6b]', icon: '⚠',  label: 'Repair Gear' },
  PvP:     { bg: 'bg-[rgba(212,165,55,0.08)]', border: 'border-[rgba(212,165,55,0.15)]', color: 'text-[#d4a537]', icon: '⚔️', label: '1,245' },
  Streak:  { bg: 'bg-[rgba(230,57,70,0.08)]',  border: 'border-[rgba(230,57,70,0.15)]',  color: 'text-[#e63946]', icon: '🔥', label: '5 Win Streak' },
  Bonus:   { bg: 'bg-[rgba(46,204,113,0.1)]',  border: 'border-[rgba(46,204,113,0.2)]',  color: 'text-[#2ecc71]', icon: '🎁', label: 'First Win Bonus' },
  Error:   { bg: 'bg-[rgba(230,57,70,0.1)]',   border: 'border-[rgba(230,57,70,0.2)]',   color: 'text-[#ff6b6b]', icon: '✖',  label: 'Connection Lost' },
  Offline: { bg: 'bg-[rgba(255,255,255,0.04)]', border: 'border-[rgba(255,255,255,0.08)]', color: 'text-[#a0a0b0]', icon: '☁',  label: 'Offline Mode' },
}

export function DSWidgetPill({ style = 'Heal', label }: WidgetPillProps) {
  const cfg = PILL_CONFIG[style]
  const text = label || cfg.label

  return (
    <div
      className={`h-[44px] w-[200px] rounded-[6px] px-[14px] gap-[8px] border border-solid flex items-center ${cfg.bg} ${cfg.border}`}
    >
      <span className="text-[16px] leading-none">{cfg.icon}</span>
      <span className={`font-['Inter'] font-medium text-[14px] leading-none ${cfg.color}`}>
        {text}
      </span>
    </div>
  )
}

const ALL_STYLES: WidgetPillStyle[] = ['Heal', 'Urgent', 'Energy', 'Stat', 'Warn', 'PvP', 'Streak', 'Bonus', 'Error', 'Offline']

export function WidgetPillAllVariants() {
  return (
    <>
      <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
      <div className="flex flex-col gap-[12px] p-[24px]">
        <h2 className="font-['Oswald'] text-[22px] text-[#ffd700] uppercase tracking-[2px] mb-[8px]">
          Widget Pill — All Styles
        </h2>
        {ALL_STYLES.map((s) => (
          <div key={s} className="flex items-center gap-[16px]">
            <span className="font-['Inter'] text-[12px] text-[#6b6b80] w-[80px]">{s}</span>
            <DSWidgetPill style={s} />
          </div>
        ))}
      </div>
    </>
  )
}
