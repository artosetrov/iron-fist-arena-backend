'use client'

export function DSHeroWidget() {
  return (
    <div className="border border-[rgba(64,64,89,0.15)] border-solid flex gap-[12px] items-center px-[16px] py-[12px] relative rounded-[12px] shadow-[0px_3px_6px_0px_rgba(8,8,12,0.4)] w-[361px] bg-[#1a1a2e]">
      {/* Surface lighting */}
      <div className="absolute bg-gradient-to-b from-[rgba(255,255,255,0.08)] to-[rgba(255,255,255,0)] h-[52px] left-[-1px] rounded-[12px] top-[-1px] w-[361px]" />
      <div className="absolute bg-gradient-to-b from-[rgba(0,0,0,0)] to-[rgba(0,0,0,0.12)] h-[52px] left-[-1px] rounded-[12px] top-[51px] w-[361px]" />
      {/* Corner brackets */}
      <div className="absolute top-[44px] left-[15px] w-[14px] h-[1.5px] bg-[#8b6914]" />
      <div className="absolute top-[44px] left-[15px] w-[1.5px] h-[14px] bg-[#8b6914]" />
      <div className="absolute bottom-[44px] right-[15px] w-[14px] h-[1.5px] bg-[#8b6914]" />
      <div className="absolute bottom-[44px] right-[15px] w-[1.5px] h-[14px] bg-[#8b6914]" />

      {/* Avatar + XP Ring */}
      <div className="relative shrink-0 size-[72px]">
        <div className="absolute border-[3px] border-[#262640] border-solid left-0 rounded-[10px] size-[72px] top-0" />
        <div className="absolute border-[3px] border-[#3498db] border-dashed left-0 rounded-[10px] shadow-[0px_0px_4px_0px_rgba(52,152,219,0.4)] size-[72px] top-0" />
        <div className="absolute bg-[#1e2240] left-[4px] rounded-[8px] size-[64px] top-[4px] flex items-center justify-center text-2xl">👤</div>
        {/* XP corner diamonds */}
        <div className="absolute left-[-0.5px] top-[-2.62px] flex items-center justify-center size-[4.243px]"><div className="-rotate-45 bg-[rgba(52,152,219,0.6)] size-[3px]" /></div>
        <div className="absolute right-[-1.5px] top-[-2.62px] flex items-center justify-center size-[4.243px]"><div className="-rotate-45 bg-[rgba(52,152,219,0.6)] size-[3px]" /></div>
        <div className="absolute left-[-0.5px] bottom-[-2.62px] flex items-center justify-center size-[4.243px]"><div className="-rotate-45 bg-[rgba(52,152,219,0.6)] size-[3px]" /></div>
        <div className="absolute right-[-1.5px] bottom-[-2.62px] flex items-center justify-center size-[4.243px]"><div className="-rotate-45 bg-[rgba(52,152,219,0.6)] size-[3px]" /></div>
        {/* Level badge */}
        <div className="absolute bg-[#1e2240] border border-[#3498db] border-solid flex items-center justify-center left-[10px] px-[6px] py-[2px] rounded-[10px] shadow-[0px_0px_4px_0px_rgba(52,152,219,0.3)] top-[62px]">
          <p className='font-["Inter",sans-serif] font-bold text-[#f5f5f5] text-[11px]'>Lv. 16</p>
        </div>
      </div>

      {/* Info */}
      <div className="flex flex-1 flex-col gap-[4px] overflow-clip">
        <p className='font-["Inter",sans-serif] font-bold text-[#f5f5f5] text-[16px]'>SHADOWBLADE</p>
        {/* HP Bar */}
        <div className="bg-[#16213e] border-[0.5px] border-[rgba(51,51,77,0.5)] border-solid h-[26px] overflow-clip relative rounded-[6px] w-full">
          <div className="absolute bg-gradient-to-r from-[#2ecc71] to-[#e5b21a] h-[26px] left-[-0.5px] rounded-[6px] top-[-0.5px] w-[153px]" />
          <div className="absolute bg-gradient-to-b from-[rgba(255,255,255,0.15)] to-[rgba(255,255,255,0)] h-[8px] left-[-0.5px] rounded-[6px] top-[-0.5px] w-[153px]" />
          <p className='absolute font-["Inter",sans-serif] font-bold text-[#f5f5f5] text-[13px] left-1/2 -translate-x-1/2 top-[4.5px]' style={{ textShadow: '0px 1px 1px rgba(8,8,12,0.6)' }}>245 / 320</p>
        </div>
        {/* Stamina Bar */}
        <div className="bg-[#16213e] border-[0.5px] border-[rgba(51,51,77,0.5)] border-solid h-[26px] overflow-clip relative rounded-[6px] w-full">
          <div className="absolute bg-gradient-to-r from-[#e67e22] to-[#ffb233] h-[26px] left-[-0.5px] rounded-[6px] top-[-0.5px] w-[142px]" />
          <div className="absolute bg-gradient-to-b from-[rgba(255,255,255,0.15)] to-[rgba(255,255,255,0)] h-[8px] left-[-0.5px] rounded-[6px] top-[-0.5px] w-[142px]" />
          <p className='absolute font-["Inter",sans-serif] font-bold text-[#f5f5f5] text-[13px] left-1/2 -translate-x-1/2 top-[4.5px]' style={{ textShadow: '0px 1px 1px rgba(8,8,12,0.6)' }}>85 / 120</p>
        </div>
        {/* Currency */}
        <div className="flex gap-[8px] items-center h-[24px]">
          <div className="flex gap-[4px] items-center"><div className="rounded-[4px] size-[16px] bg-[#d4a537]" /><p className='font-["Oswald",sans-serif] text-[18px] text-[#ffd700]'>12,450</p></div>
          <div className="flex gap-[4px] items-center"><div className="rounded-[4px] size-[16px] bg-[#00d4ff]" /><p className='font-["Oswald",sans-serif] text-[18px] text-[#00d4ff]'>385</p></div>
        </div>
      </div>
    </div>
  )
}

export function HeroWidgetAllVariants() {
  return (
    <div>
      <DSHeroWidget />
    </div>
  )
}
