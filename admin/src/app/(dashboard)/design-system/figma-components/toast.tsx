'use client'

type ToastProps = {
  type?: 'Achievement' | 'Level Up' | 'Rank Up' | 'Quest' | 'Reward' | 'Info' | 'Error'
}

export function DSToast({ type = 'Achievement' }: ToastProps) {
  const isError = type === 'Error'

  const iconBgs: Record<string, string> = {
    'Achievement': 'bg-[rgba(255,215,0,0.15)]',
    'Level Up': 'bg-[rgba(102,255,102,0.15)]',
    'Rank Up': 'bg-[rgba(153,102,255,0.15)]',
    'Quest': 'bg-[rgba(0,212,255,0.15)]',
    'Reward': 'bg-[rgba(230,126,34,0.15)]',
    'Info': 'bg-[rgba(204,204,218,0.15)]',
    'Error': 'bg-[rgba(255,107,107,0.15)]',
  }

  const icons: Record<string, string> = {
    'Achievement': '🏆', 'Level Up': '⬆', 'Rank Up': '👑',
    'Quest': '📜', 'Reward': '🎁', 'Info': 'ℹ', 'Error': '✖',
  }

  const titles: Record<string, string> = {
    'Achievement': 'Achievement Unlocked!', 'Level Up': 'Level Up!',
    'Rank Up': 'Rank Up!', 'Quest': 'Quest Complete!',
    'Reward': 'Reward Claimed', 'Info': 'Opponents Refreshed',
    'Error': 'Connection Failed',
  }

  const subtitles: Record<string, string> = {
    'Achievement': 'First Blood — Win your first battle',
    'Level Up': 'You reached Level 15', 'Rank Up': 'Gold III → Gold II',
    'Quest': 'Win 3 PvP Battles', 'Reward': '+500 Gold, +2 Gems',
    'Info': 'New challengers available', 'Error': 'Check your internet connection',
  }

  return (
    <div className="bg-[#1a1a2e] border border-[#2a2a3e] border-solid flex gap-[12px] h-[64px] items-center pl-[12px] pr-[16px] py-[10px] relative rounded-[8px] w-[360px]">
      <div className={`flex items-center justify-center rounded-[6px] shrink-0 size-[28px] ${iconBgs[type]}`}>
        <span className="text-[14px]">{icons[type]}</span>
      </div>
      <div className="flex flex-1 flex-col gap-[2px] overflow-hidden">
        <p className='font-["Inter",sans-serif] font-bold text-[14px] text-[#f5f5f5] whitespace-nowrap'>{titles[type]}</p>
        <p className='font-["Inter",sans-serif] font-normal text-[12px] text-[#a0a0b0] whitespace-nowrap'>{subtitles[type]}</p>
      </div>
      {isError && (
        <div className="bg-[rgba(255,107,107,0.15)] flex items-center justify-center px-[12px] py-[6px] rounded-[12px] shrink-0">
          <p className='font-["Inter",sans-serif] font-medium text-[#ff6b6b] text-[12px]'>Retry</p>
        </div>
      )}
      {/* Inner border */}
      <div className="absolute border border-[rgba(255,255,255,0.08)] border-solid inset-px rounded-[6px]" />
      {/* Corner brackets */}
      <div className="absolute top-[26px] right-[16px] w-[10px] h-px bg-[#3a3a50]" />
      <div className="absolute top-[26px] right-[16px] w-px h-[10px] bg-[#3a3a50]" />
      <div className="absolute bottom-[26px] left-[16px] w-[10px] h-px bg-[#3a3a50]" />
      <div className="absolute bottom-[26px] left-[16px] w-px h-[10px] bg-[#3a3a50]" />
    </div>
  )
}

export function ToastAllVariants() {
  const types: Array<ToastProps['type']> = ['Achievement', 'Level Up', 'Rank Up', 'Quest', 'Reward', 'Info', 'Error']
  return (
    <div className="flex flex-col gap-2">
      {types.map(t => <DSToast key={t} type={t} />)}
    </div>
  )
}
