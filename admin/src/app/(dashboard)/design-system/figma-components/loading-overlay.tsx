'use client'

export function DSLoadingOverlay() {
  return (
    <div className="bg-[#0d0d12] flex flex-col gap-[24px] h-[320px] items-center justify-center py-[60px] w-[360px]">
      <div className="bg-[#1a1a2e] border-2 border-[#d4a537] border-solid flex flex-col h-[80px] items-center justify-center overflow-clip px-[26px] py-[18px] rounded-[16px] w-[81px]">
        <p className='font-["Inter",sans-serif] font-bold text-[#d4a537] text-[32px]'>H</p>
      </div>
      <p className='font-["Oswald",sans-serif] font-normal text-[18px] text-[#a0a0b0] tracking-[4px]'>LOADING</p>
      <div className="flex gap-[8px]">
        <div className="flex items-center justify-center size-[8.485px]"><div className="-rotate-45 bg-[rgba(212,165,55,0.4)] rounded-[3px] size-[6px]" /></div>
        <div className="flex items-center justify-center size-[8.485px]"><div className="-rotate-45 bg-[rgba(212,165,55,0.6)] rounded-[3px] size-[6px]" /></div>
        <div className="flex items-center justify-center size-[8.485px]"><div className="-rotate-45 bg-[rgba(212,165,55,0.8)] rounded-[3px] size-[6px]" /></div>
      </div>
    </div>
  )
}

export function LoadingOverlayAllVariants() {
  return (
    <div>
      <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;700&display=swap" rel="stylesheet" />
      <DSLoadingOverlay />
    </div>
  )
}
