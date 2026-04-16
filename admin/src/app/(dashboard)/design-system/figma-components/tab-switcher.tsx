'use client'

/**
 * AUTO-GENERATED FROM FIGMA DS via get_design_context
 * Component: Tab Switcher (2-tab, 3-tab)
 * File: Hexbound-DS (uDjXIz7CdJxcEOI5jCBcjY)
 * DO NOT EDIT MANUALLY — regenerate from Figma
 */

type TabSwitcherTabs = '2' | '3'

type TabSwitcherProps = {
  tabs?: TabSwitcherTabs
  activeIndex?: number
}

const TAB_LABELS: Record<TabSwitcherTabs, string[]> = {
  '2': ['OPPONENTS', 'REVENGE'],
  '3': ['INVENTORY', 'STATUS', 'SKILLS'],
}

function Tab({ label, active }: { label: string; active: boolean }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center gap-[4px] relative">
      <span
        className={`font-['Oswald'] text-[14px] tracking-[2px] uppercase leading-none ${
          active ? 'text-[#ffd700]' : 'text-[#6b6b80]'
        }`}
      >
        {label}
      </span>
      {active && (
        <div className="w-[40px] h-[2px] bg-gradient-to-r from-[#ffd600] via-[#d4a638] to-[#8b6915] rounded-full" />
      )}
    </div>
  )
}

function CornerBracket({ position }: { position: 'tl' | 'tr' | 'bl' | 'br' }) {
  const pos =
    position === 'tl' ? 'top-0 left-0' :
    position === 'tr' ? 'top-0 right-0' :
    position === 'bl' ? 'bottom-0 left-0' :
    'bottom-0 right-0'

  return (
    <div className={`absolute ${pos} w-[6px] h-[6px]`}>
      {/* Horizontal arm */}
      <div
        className={`absolute bg-[#8b6914] h-[1px] w-[6px] ${
          position.startsWith('t') ? 'top-0' : 'bottom-0'
        } ${position.endsWith('l') ? 'left-0' : 'right-0'}`}
      />
      {/* Vertical arm */}
      <div
        className={`absolute bg-[#8b6914] w-[1px] h-[6px] ${
          position.startsWith('t') ? 'top-0' : 'bottom-0'
        } ${position.endsWith('l') ? 'left-0' : 'right-0'}`}
      />
    </div>
  )
}

export function DSTabSwitcher({ tabs = '2', activeIndex = 0 }: TabSwitcherProps) {
  const labels = TAB_LABELS[tabs]

  return (
    <div className="relative h-[44px] w-[360px] rounded-[8px] bg-[#1a1a2e] border border-[#2a2a3e] flex items-center overflow-hidden">
      {/* Surface lighting overlay */}
      <div className="absolute inset-0 rounded-[8px] bg-gradient-to-b from-white/[0.03] to-transparent pointer-events-none" />

      {/* Inner border */}
      <div className="absolute inset-[1px] rounded-[7px] border border-white/[0.04] pointer-events-none" />

      {/* Corner brackets */}
      <CornerBracket position="tl" />
      <CornerBracket position="tr" />
      <CornerBracket position="bl" />
      <CornerBracket position="br" />

      {/* Tabs */}
      {labels.map((label, i) => (
        <Tab key={label} label={label} active={i === activeIndex} />
      ))}
    </div>
  )
}

export function TabSwitcherAllVariants() {
  return (
    <>
      <div className="flex flex-col gap-[24px] p-[24px]">
        <h2 className="font-['Oswald'] text-[22px] text-[#ffd700] uppercase tracking-[2px] mb-[8px]">
          Tab Switcher — All Variants
        </h2>

        {/* 2-tab */}
        <div className="flex flex-col gap-[8px]">
          <span className="font-['Inter'] text-[12px] text-[#6b6b80]">2-Tab</span>
          <DSTabSwitcher tabs="2" activeIndex={0} />
        </div>

        {/* 3-tab */}
        <div className="flex flex-col gap-[8px]">
          <span className="font-['Inter'] text-[12px] text-[#6b6b80]">3-Tab</span>
          <DSTabSwitcher tabs="3" activeIndex={0} />
        </div>
      </div>
    </>
  )
}
