'use client'

/**
 * AUTO-GENERATED FROM FIGMA DS via get_design_context
 * Component: Button (node 16:26)
 * File: Hexbound-DS (uDjXIz7CdJxcEOI5jCBcjY)
 * DO NOT EDIT MANUALLY — regenerate from Figma
 */

type ButtonProps = {
  className?: string
  state?: 'Default' | 'Pressed' | 'Disabled'
  style?: 'Primary' | 'Secondary' | 'Danger' | 'Ghost' | 'Fight' | 'Premium'
  label?: string
}

export function DSButton({ state = 'Default', style = 'Primary', label }: ButtonProps) {
  const isPrimary = style === 'Primary'
  const isSecondary = style === 'Secondary'
  const isDanger = style === 'Danger'
  const isGhost = style === 'Ghost'
  const isFight = style === 'Fight'
  const isPremium = style === 'Premium'
  const isDefault = state === 'Default'
  const isPressed = state === 'Pressed'
  const isDisabled = state === 'Disabled'
  const isActive = isDefault || isPressed

  const text = label || (isFight ? 'ENTER BATTLE' : isPremium ? 'PREMIUM' : 'BUTTON LABEL')

  // Background
  const bg = isDisabled
    ? 'bg-[#333340]'
    : isPrimary ? 'bg-[#d4a537]'
    : isSecondary ? 'bg-transparent'
    : isDanger ? 'bg-[#8b1a22]'
    : isGhost ? 'bg-transparent'
    : isFight ? 'bg-[#ff6600]'
    : isPremium ? 'bg-[#7b2d8e]'
    : ''

  // Border
  const border = isDisabled
    ? 'border-[#2a2a3e]'
    : isPrimary ? 'border-[#b8860b]'
    : isSecondary ? 'border-[#8b6914]'
    : isDanger ? 'border-[#5a0a10]'
    : isGhost ? 'border-transparent'
    : isFight ? 'border-[#4a1500]'
    : isPremium ? 'border-[#6c3483]'
    : ''

  const borderWidth = isDanger || isSecondary ? 'border-[1.5px]' : 'border-2'

  // Text color
  const textColor = isDisabled
    ? 'text-[#555566]'
    : isPrimary ? 'text-[#1a1a2e]'
    : isSecondary ? 'text-[#d4a537]'
    : isDanger ? 'text-[#f5f5f5]'
    : isGhost ? 'text-[#a0a0b0]'
    : isFight ? 'text-[#f5f5f5]'
    : isPremium ? 'text-[#e5a0ff]'
    : ''

  // Height
  const height = (isPrimary || isFight) ? 'h-[56px]' : 'h-[48px]'

  // Accent color for ornaments
  const accentColor = isPrimary ? '#ffd700'
    : isSecondary ? '#d4a537'
    : isDanger ? '#e63946'
    : isFight ? '#ff8833'
    : isPremium ? '#e5a0ff'
    : '#ffd700'

  const showOrnaments = isActive && !isGhost
  const opacity = isPressed ? 'opacity-[0.88]' : ''

  return (
    <div className={`content-stretch flex items-center justify-center px-[24px] relative rounded-[8px] w-[280px] border-solid ${bg} ${border} ${borderWidth} ${height} ${opacity}`}>
      {/* Label */}
      <p className={`flex-1 font-["Oswald",sans-serif] font-normal text-[18px] text-center tracking-[2px] uppercase ${textColor}`}>
        {text}
      </p>

      {/* Surface Lighting */}
      {showOrnaments && (
        <div className={`absolute bg-gradient-to-b from-[rgba(255,255,255,0.12)] via-[rgba(255,255,255,0)] via-50% to-[rgba(0,0,0,0.18)] rounded-[8px] ${isDanger || isSecondary ? 'inset-[-1.5px]' : 'inset-[-2px]'}`} />
      )}

      {/* Inner Border */}
      {showOrnaments && (
        <div className={`absolute border border-[rgba(255,255,255,0.1)] border-solid rounded-[5px] ${isDanger || isSecondary ? 'inset-[1.5px]' : 'inset-px'}`} />
      )}

      {/* Corner Brackets */}
      {showOrnaments && (
        <>
          {/* Top-right brackets */}
          <div className="absolute top-[6px] right-[6px] w-[18px] h-[2px]" style={{ backgroundColor: accentColor }} />
          <div className="absolute top-[6px] right-[6px] w-[2px] h-[18px]" style={{ backgroundColor: accentColor }} />
          {/* Bottom-left brackets */}
          <div className="absolute bottom-[6px] left-[6px] w-[18px] h-[2px]" style={{ backgroundColor: accentColor }} />
          <div className="absolute bottom-[6px] left-[6px] w-[2px] h-[18px]" style={{ backgroundColor: accentColor }} />
          {/* Top-left brackets */}
          <div className="absolute top-[6px] left-[6px] w-[18px] h-[2px]" style={{ backgroundColor: accentColor }} />
          <div className="absolute top-[6px] left-[6px] w-[2px] h-[18px]" style={{ backgroundColor: accentColor }} />
          {/* Bottom-right brackets */}
          <div className="absolute bottom-[6px] right-[6px] w-[18px] h-[2px]" style={{ backgroundColor: accentColor }} />
          <div className="absolute bottom-[6px] right-[6px] w-[2px] h-[18px]" style={{ backgroundColor: accentColor }} />
          {/* Corner diamonds */}
          <div className="absolute top-1/2 right-[4px] -translate-y-1/2">
            <div className="-rotate-45 w-[6px] h-[6px]" style={{ backgroundColor: accentColor }} />
          </div>
          <div className="absolute top-1/2 left-[4px] -translate-y-1/2">
            <div className="-rotate-45 w-[6px] h-[6px]" style={{ backgroundColor: accentColor }} />
          </div>
        </>
      )}
    </div>
  )
}

/** Renders ALL button variants in a grid matching Figma component set layout */
export function ButtonAllVariants() {
  const styles: Array<ButtonProps['style']> = ['Primary', 'Secondary', 'Danger', 'Ghost', 'Fight', 'Premium']
  const states: Array<ButtonProps['state']> = ['Default', 'Pressed', 'Disabled']

  return (
    <div>
      <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;700&display=swap" rel="stylesheet" />
      <div className="grid grid-cols-3 gap-4">
        {/* Column headers */}
        <p className="text-xs text-[#6B6B80] text-center">Default</p>
        <p className="text-xs text-[#6B6B80] text-center">Pressed</p>
        <p className="text-xs text-[#6B6B80] text-center">Disabled</p>

        {styles.map(s => (
          states.map(st => (
            <div key={`${s}-${st}`} className="flex justify-center">
              <DSButton style={s} state={st} />
            </div>
          ))
        ))}
      </div>
    </div>
  )
}
