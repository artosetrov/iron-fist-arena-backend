'use client'

export function DSStanceDisplay() {
  return (
    <div className="bg-[#1a1a2e] border border-[#2a2a3e] border-solid flex h-[64px] items-center px-[12px] py-[8px] relative rounded-[8px] w-[360px]">
      {/* Attack */}
      <div className="flex flex-1 gap-[8px] items-center overflow-clip">
        <span className="text-[20px]">🎯</span>
        <div className="flex flex-col gap-[2px]">
          <p className='font-["Inter",sans-serif] text-[10px] text-[#6b6b80] tracking-[1px]'>ATTACK</p>
          <p className='font-["Oswald",sans-serif] text-[16px] text-[#f5f5f5]'>HEAD</p>
        </div>
      </div>
      {/* Divider */}
      <div className="flex items-center shrink-0">
        <div className="bg-[#3b3b4f] h-[40px] w-px" />
        <div className="flex items-center justify-center size-[7.071px]"><div className="-rotate-45 bg-[#8b6915] size-[5px]" /></div>
      </div>
      {/* Defense */}
      <div className="flex flex-1 gap-[8px] items-center justify-end overflow-clip">
        <div className="flex flex-col gap-[2px] items-end">
          <p className='font-["Inter",sans-serif] text-[10px] text-[#6b6b80] tracking-[1px]'>DEFENSE</p>
          <p className='font-["Oswald",sans-serif] text-[16px] text-[#f5f5f5]'>CHEST</p>
        </div>
        <span className="text-[20px]">🛡️</span>
      </div>
      {/* Surface lighting */}
      <div className="absolute bg-gradient-to-b from-[rgba(255,255,255,0.08)] via-[rgba(255,255,255,0)] via-50% to-[rgba(0,0,0,0.12)] inset-[-1px] rounded-[8px]" />
      <div className="absolute border border-[rgba(255,255,255,0.08)] border-solid inset-px rounded-[6px]" />
      {/* Corner brackets */}
      <div className="absolute top-[25px] right-[12px] w-[12px] h-[1.5px] bg-[#8b6914]" />
      <div className="absolute top-[25px] right-[12px] w-[1.5px] h-[12px] bg-[#8b6914]" />
      <div className="absolute bottom-[25px] left-[12px] w-[12px] h-[1.5px] bg-[#8b6914]" />
      <div className="absolute bottom-[25px] left-[12px] w-[1.5px] h-[12px] bg-[#8b6914]" />
    </div>
  )
}

export function StanceDisplayAllVariants() {
  return (
    <div>
      <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;700&display=swap" rel="stylesheet" />
      <DSStanceDisplay />
    </div>
  )
}
