'use client'
type StateViewProps = { type?: 'Empty Inventory' | 'No Quests' | 'Network Error' | 'Server Error' }

export function DSStateView({ type = 'Empty Inventory' }: StateViewProps) {
  const config: Record<string, { icon: string; title: string; desc: string; showCta: boolean }> = {
    'Empty Inventory': { icon: '🛒', title: 'INVENTORY EMPTY', desc: 'Visit the shop to equip your hero with powerful gear.', showCta: true },
    'No Quests': { icon: '⚔️', title: 'ALL QUESTS DONE', desc: 'Come back tomorrow for new challenges!', showCta: false },
    'Network Error': { icon: '⚡', title: 'CONNECTION LOST', desc: 'Check your internet connection and try again.', showCta: true },
    'Server Error': { icon: '⚔️', title: 'SERVER ERROR', desc: 'Something went wrong. Our smiths are working on it.', showCta: true },
  }
  const c = config[type]
  return (
    <div className="bg-[#1a1a2e] border border-[#2a2a3e] border-solid flex flex-col gap-[16px] h-[280px] items-center justify-center px-[24px] py-[32px] rounded-[12px] w-[320px]">
      <span className="text-[40px]">{c.icon}</span>
      <p className='font-["Oswald",sans-serif] font-normal text-[22px] text-[#f5f5f5] text-center'>{c.title}</p>
      <p className='font-["Inter",sans-serif] font-normal text-[14px] text-[#a0a0b0] text-center'>{c.desc}</p>
      {c.showCta && (
        <div className="bg-[#d4a537] flex h-[44px] items-center justify-center rounded-[8px] w-[200px]">
          <p className='font-["Oswald",sans-serif] font-normal text-[16px] text-[#1a1a2e] tracking-[2px]'>TAKE ACTION</p>
        </div>
      )}
    </div>
  )
}

export function StateViewAllVariants() {
  return (
    <div className="grid grid-cols-2 gap-4">
      <DSStateView type="Empty Inventory" />
      <DSStateView type="No Quests" />
      <DSStateView type="Network Error" />
      <DSStateView type="Server Error" />
    </div>
  )
}
