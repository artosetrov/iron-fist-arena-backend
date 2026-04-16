'use client'
type OrnamentalTitleProps = { style?: 'Screen Title' | 'Section Header' }

export function DSOrnamentalTitle({ style = 'Screen Title' }: OrnamentalTitleProps) {
  if (style === 'Section Header') {
    return (
      <div className="flex gap-[8px] items-center w-[360px] h-[24px]">
        <div className="bg-gradient-to-r from-[rgba(0,0,0,0)] to-[#3a3a50] flex-1 h-px" />
        <div className="flex items-center justify-center size-[7.071px]">
          <div className="-rotate-45 bg-[#8b6915] size-[5px]" />
        </div>
        <p className='font-["Oswald",sans-serif] font-normal text-[14px] text-[#a0a0b0] tracking-[2px] whitespace-nowrap'>EQUIPMENT</p>
        <div className="flex items-center justify-center size-[7.071px]">
          <div className="-rotate-45 bg-[#8b6915] size-[5px]" />
        </div>
        <div className="bg-gradient-to-r from-[#3a3a50] to-[rgba(0,0,0,0)] flex-1 h-px" />
      </div>
    )
  }
  return (
    <div className="flex flex-col gap-[8px] items-center justify-center w-[360px] h-[80px]">
      <p className='font-["Oswald",sans-serif] font-normal text-[28px] text-[#f5f5f5] text-center tracking-[3px] whitespace-nowrap'>ARENA OF CHAMPIONS</p>
      <div className="flex items-center w-[200px] h-[8px] overflow-clip">
        <div className="bg-gradient-to-r from-[rgba(0,0,0,0)] to-[#d4a537] flex-1 h-[1.5px]" />
        <div className="flex items-center justify-center shrink-0 size-[8.485px]">
          <div className="-rotate-45 bg-[#d4a537] size-[6px]" />
        </div>
        <div className="bg-gradient-to-r from-[#d4a537] to-[rgba(0,0,0,0)] flex-1 h-[1.5px]" />
      </div>
    </div>
  )
}

export function OrnamentalTitleAllVariants() {
  return (
    <div className="flex flex-col gap-6">
      <div><p className="text-xs text-[#6B6B80] mb-2">Screen Title</p><DSOrnamentalTitle style="Screen Title" /></div>
      <div><p className="text-xs text-[#6B6B80] mb-2">Section Header</p><DSOrnamentalTitle style="Section Header" /></div>
    </div>
  )
}
