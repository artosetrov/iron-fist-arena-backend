'use client'
type SkeletonProps = { type?: 'Rectangle' | 'Card' | 'Item Cell' }

export function DSSkeleton({ type = 'Rectangle' }: SkeletonProps) {
  if (type === 'Item Cell') {
    return <div className="bg-[rgba(22,33,62,0.4)] border border-[rgba(42,42,62,0.3)] border-solid rounded-[8px] size-[80px]" />
  }
  if (type === 'Card') {
    return (
      <div className="bg-[rgba(22,33,62,0.4)] border border-[rgba(42,42,62,0.3)] border-solid flex flex-col gap-[12px] items-start px-[12px] py-[16px] rounded-[12px] w-[160px]">
        <div className="bg-[rgba(22,33,62,0.6)] h-[100px] rounded-[8px] w-[136px]" />
        <div className="bg-[rgba(22,33,62,0.5)] h-[14px] rounded-[4px] w-[100px]" />
        <div className="bg-[rgba(22,33,62,0.3)] h-[12px] rounded-[4px] w-[70px]" />
      </div>
    )
  }
  return <div className="bg-[rgba(22,33,62,0.6)] border border-[rgba(42,42,62,0.3)] border-solid h-[24px] rounded-[6px] w-[280px]" />
}

export function SkeletonAllVariants() {
  return (
    <div className="flex items-start gap-4">
      <div><p className="text-xs text-[#6B6B80] mb-2">Rectangle</p><DSSkeleton type="Rectangle" /></div>
      <div><p className="text-xs text-[#6B6B80] mb-2">Card</p><DSSkeleton type="Card" /></div>
      <div><p className="text-xs text-[#6B6B80] mb-2">Item Cell</p><DSSkeleton type="Item Cell" /></div>
    </div>
  )
}
