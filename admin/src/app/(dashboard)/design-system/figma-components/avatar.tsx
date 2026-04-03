'use client'
type AvatarProps = { size?: 'Large' | 'Medium' | 'Small' }

export function DSAvatar({ size = 'Large' }: AvatarProps) {
  const sizeClass = size === 'Small' ? 'rounded-[6px] size-[40px]' : size === 'Medium' ? 'rounded-[6px] size-[56px]' : 'rounded-[8px] size-[72px]'
  return (
    <div className={`bg-[#16213e] border border-[#2a2a3e] border-solid overflow-clip relative ${sizeClass}`}>
      <div className="absolute inset-0 flex items-center justify-center text-[#6b6b80]" style={{ fontSize: size === 'Small' ? 16 : size === 'Medium' ? 22 : 28 }}>👤</div>
    </div>
  )
}

export function AvatarAllVariants() {
  return (
    <div className="flex items-end gap-4">
      <div className="text-center"><DSAvatar size="Large" /><p className="text-xs text-[#6B6B80] mt-1">72px</p></div>
      <div className="text-center"><DSAvatar size="Medium" /><p className="text-xs text-[#6B6B80] mt-1">56px</p></div>
      <div className="text-center"><DSAvatar size="Small" /><p className="text-xs text-[#6B6B80] mt-1">40px</p></div>
    </div>
  )
}
