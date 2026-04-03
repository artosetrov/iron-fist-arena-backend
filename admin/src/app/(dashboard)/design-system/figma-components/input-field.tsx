'use client'

type InputFieldProps = {
  state?: 'Default' | 'Focused' | 'Error'
}

export function DSInputField({ state = 'Default' }: InputFieldProps) {
  const isError = state === 'Error'
  const isFocused = state === 'Focused'

  const borderClass = isError
    ? 'border-[1.5px] border-[#e63946]'
    : isFocused
    ? 'border-[1.5px] border-[#d4a537]'
    : 'border border-[#2a2a3e]'

  const textColor = isError ? 'text-[#ff6b6b]' : 'text-[#6b6b80]'
  const text = isError ? 'Invalid email' : 'Enter email address'

  return (
    <div className={`bg-[#16213e] border-solid flex h-[52px] items-center px-[16px] rounded-[8px] w-[320px] ${borderClass}`}>
      <p className={`flex-1 font-["Inter",sans-serif] font-normal text-[16px] ${textColor}`}>{text}</p>
    </div>
  )
}

export function InputFieldAllVariants() {
  return (
    <div className="flex gap-4">
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Default</p>
        <DSInputField state="Default" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Focused</p>
        <DSInputField state="Focused" />
      </div>
      <div>
        <p className="text-xs text-[#6B6B80] mb-2">Error</p>
        <DSInputField state="Error" />
      </div>
    </div>
  )
}
