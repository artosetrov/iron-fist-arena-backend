'use client'

type NavigationProps = {
  type?: 'Nav Grid' | 'Back Button' | 'Screen Header'
}

export function DSNavigation({ type = 'Nav Grid' }: NavigationProps) {
  if (type === 'Back Button') {
    return (
      <div className="flex items-center justify-center rounded-[8px] size-[48px]">
        <span className="text-[24px] text-[#a0a0b0]">←</span>
      </div>
    )
  }

  if (type === 'Screen Header') {
    return (
      <div className="flex items-center h-[48px] px-[8px] w-[360px]">
        <div className="flex items-center justify-center shrink-0 w-[48px]">
          <span className="text-[24px] text-[#a0a0b0]">←</span>
        </div>
        <p className='flex-1 font-["Oswald",sans-serif] font-normal text-[22px] text-[#f5f5f5] text-center tracking-[2px]'>ARENA</p>
        <div className="shrink-0 size-[48px]" />
      </div>
    )
  }

  // Nav Grid
  return (
    <div className="bg-[#1a1a2e] border border-[#2a2a3e] border-solid flex flex-col gap-[6px] h-[72px] items-center justify-center rounded-[12px] w-[170px]">
      <span className="text-[24px]">⚔️</span>
      <p className='font-["Oswald",sans-serif] font-normal text-[14px] text-[#f5f5f5] tracking-[1px]'>ARENA</p>
    </div>
  )
}

export function NavigationAllVariants() {
  return (
    <div className="flex flex-col gap-4">
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Nav Grid</p>
        <DSNavigation type="Nav Grid" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Back Button</p>
        <DSNavigation type="Back Button" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Screen Header</p>
        <DSNavigation type="Screen Header" />
      </div>
    </div>
  )
}
