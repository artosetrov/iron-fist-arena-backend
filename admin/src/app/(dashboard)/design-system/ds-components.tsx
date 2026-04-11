'use client'

/**
 * Web previews of Hexbound DS components.
 * These mirror SwiftUI components visually using the same design tokens.
 * NOT production components — only for preview/verification.
 */

import tokens from '@/lib/design-tokens.json'

// Compatibility alias: old code used c.accent.* — map to real token groups
const accent = {
  gold: tokens.colors.gold.gold,
  goldBright: tokens.colors.gold.goldBright,
  goldDim: tokens.colors.gold.goldDim,
  goldGlow: tokens.colors.gold.goldGlow,
  danger: tokens.colors.feedback.danger,
  success: tokens.colors.feedback.success,
  info: tokens.colors.feedback.info,
  purple: tokens.colors.feedback.purple,
  cyan: tokens.colors.feedback.cyan,
  stamina: tokens.colors.feedback.stamina,
}
const c = { ...tokens.colors, accent }
const t = tokens.typography
const s = tokens.spacing
const r = tokens.radius

// ─── Button Previews ─────────────────────────────────────────────

const buttonStyles = {
  primary: { bg: 'linear-gradient(180deg, #D4A537, #B8860B)', text: c.text.textOnGold, border: c.border.borderOrnament },
  secondary: { bg: 'transparent', text: c.text.textPrimary, border: c.border.borderMedium },
  danger: { bg: '#8B1A22', text: '#FF6B6B', border: '#5A0A10' },
  ghost: { bg: 'transparent', text: c.accent.gold, border: 'transparent' },
  fight: { bg: 'linear-gradient(180deg, #FF6600, #D35400)', text: c.text.textPrimary, border: '#4A1500' },
  premium: { bg: 'linear-gradient(180deg, #7B2D8E, #6C3483)', text: '#C77DDF', border: '#6C3483' },
} as const

function DSButton({ variant, label, disabled }: { variant: keyof typeof buttonStyles; label: string; disabled?: boolean }) {
  const style = buttonStyles[variant]
  return (
    <div
      style={{
        background: style.bg,
        color: style.text,
        border: `2px solid ${style.border}`,
        borderRadius: r.radiusMD,
        padding: `${s.spaceMS}px ${s.spaceLG}px`,
        fontFamily: '"Oswald", sans-serif',
        fontSize: t.buttonLabel.fontSize,
        letterSpacing: 1,
        textAlign: 'center',
        opacity: disabled ? 0.5 : 1,
        textTransform: 'uppercase' as const,
        cursor: disabled ? 'not-allowed' : 'pointer',
        position: 'relative' as const,
        overflow: 'hidden',
      }}
    >
      {/* Surface lighting overlay */}
      <div style={{
        position: 'absolute', inset: -2, borderRadius: r.radiusMD,
        background: 'linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 50%, rgba(0,0,0,0.18) 100%)',
        pointerEvents: 'none',
      }} />
      {label}
    </div>
  )
}

export function ButtonPreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      {(Object.keys(buttonStyles) as (keyof typeof buttonStyles)[]).map(v => (
        <DSButton key={v} variant={v} label={v.toUpperCase()} />
      ))}
      <DSButton variant="primary" label="DISABLED" disabled />
    </div>
  )
}

// ─── Card Previews ───────────────────────────────────────────────

const cardVariants = [
  { name: 'Panel', bg: c.background.bgSecondary, border: c.border.borderSubtle, glow: '' },
  { name: 'Highlight', bg: c.background.bgSecondary, border: c.accent.gold, glow: c.accent.gold },
  { name: 'Info', bg: c.background.bgTertiary, border: c.accent.info, glow: c.accent.info },
  { name: 'Modal', bg: c.background.bgSecondary, border: c.border.borderMedium, glow: '' },
]

const rarityCards = [
  { name: 'Common', color: c.rarity.rarityCommon },
  { name: 'Uncommon', color: c.rarity.rarityUncommon },
  { name: 'Rare', color: c.rarity.rarityRare },
  { name: 'Epic', color: c.rarity.rarityEpic },
  { name: 'Legendary', color: c.rarity.rarityLegendary },
]

export function CardPreviews() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
      {cardVariants.map(card => (
        <div key={card.name} style={{
          background: card.bg, border: `1px solid ${card.border}`, borderRadius: r.radiusLG,
          padding: s.spaceMD, boxShadow: card.glow ? `0 0 12px ${card.glow}33` : 'none',
        }}>
          <p style={{ color: c.text.textPrimary, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>{card.name}</p>
          <p style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 11, marginTop: 4 }}>Card variant</p>
        </div>
      ))}
      {rarityCards.map(card => (
        <div key={card.name} style={{
          background: c.background.bgSecondary, border: `1px solid ${card.color}`,
          borderRadius: r.radiusLG, padding: s.spaceMD,
          boxShadow: `0 0 12px ${card.color}33`,
        }}>
          <p style={{ color: card.color, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>{card.name}</p>
          <p style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 11, marginTop: 4 }}>Rarity</p>
        </div>
      ))}
    </div>
  )
}

// ─── Widget Pill Previews ────────────────────────────────────────

const pillStyles = [
  { name: 'Heal', bg: 'rgba(46,204,113,0.12)', border: 'rgba(46,204,113,0.25)', text: '#7BED9F', icon: '❤️‍🩹' },
  { name: 'Urgent', bg: 'rgba(230,57,70,0.12)', border: 'rgba(230,57,70,0.30)', text: '#FF6B6B', icon: '⚠️' },
  { name: 'Energy', bg: 'rgba(230,126,34,0.12)', border: 'rgba(230,126,34,0.25)', text: '#E67E22', icon: '⚡' },
  { name: 'Stat', bg: 'rgba(212,165,55,0.12)', border: 'rgba(212,165,55,0.30)', text: '#FFD700', icon: '📊' },
  { name: 'PvP', bg: 'rgba(212,165,55,0.08)', border: 'rgba(212,165,55,0.15)', text: '#D4A537', icon: '⚔️' },
  { name: 'Error', bg: 'rgba(230,57,70,0.10)', border: 'rgba(230,57,70,0.20)', text: '#FF6B6B', icon: '✕' },
  { name: 'Offline', bg: 'rgba(255,255,255,0.04)', border: 'rgba(255,255,255,0.08)', text: '#A0A0B0', icon: '📡' },
]

export function WidgetPillPreviews() {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
      {pillStyles.map(pill => (
        <div key={pill.name} style={{
          display: 'flex', alignItems: 'center', gap: 6,
          background: pill.bg, border: `1px solid ${pill.border}`,
          borderRadius: 12, padding: '6px 12px',
        }}>
          <span style={{ fontSize: 12 }}>{pill.icon}</span>
          <span style={{ color: pill.text, fontFamily: 'Inter', fontSize: 12, fontWeight: 600 }}>{pill.name}</span>
        </div>
      ))}
    </div>
  )
}

// ─── Currency Display Previews ───────────────────────────────────

export function CurrencyDisplayPreviews() {
  const sizes = [
    { name: 'Standard', fontSize: 22, iconSize: 28 },
    { name: 'Compact', fontSize: 14, iconSize: 18 },
    { name: 'Mini', fontSize: 12, iconSize: 14 },
  ]
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {sizes.map(size => (
        <div key={size.name} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10, width: 60 }}>{size.name}</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: size.iconSize, height: size.iconSize, borderRadius: 4, background: c.accent.gold }} />
            <span style={{ color: c.accent.goldBright, fontFamily: '"Oswald", sans-serif', fontSize: size.fontSize }}>12,450</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: size.iconSize, height: size.iconSize, borderRadius: 4, background: c.accent.cyan }} />
            <span style={{ color: c.accent.cyan, fontFamily: '"Oswald", sans-serif', fontSize: size.fontSize }}>385</span>
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── Progress Bar Previews ───────────────────────────────────────

function ProgressBar({ label, fill, track, pct }: { label: string; fill: string; track: string; pct: number }) {
  return (
    <div style={{ marginBottom: 8 }}>
      <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>{label}</span>
      <div style={{ height: 20, borderRadius: 6, background: track, overflow: 'hidden', position: 'relative' }}>
        <div style={{ height: '100%', width: `${pct}%`, background: fill, borderRadius: 6 }} />
        <span style={{
          position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
          color: c.text.textPrimary, fontFamily: 'Inter', fontSize: 10, fontWeight: 700,
        }}>{pct}%</span>
      </div>
    </div>
  )
}

export function ProgressBarPreviews() {
  return (
    <div>
      <ProgressBar label="HP (Full)" fill="linear-gradient(90deg, #2ECC71, #55EFC4)" track="#1A1A2E" pct={100} />
      <ProgressBar label="HP (Medium)" fill="linear-gradient(90deg, #E67E22, #F1C40F)" track="#1A1A2E" pct={55} />
      <ProgressBar label="HP (Critical)" fill="linear-gradient(90deg, #C0392B, #E74C3C)" track="#1A1A2E" pct={18} />
      <ProgressBar label="XP" fill="linear-gradient(90deg, #9B59B6, #8E44AD)" track="#1A1A2E" pct={72} />
      <ProgressBar label="Stamina" fill="linear-gradient(90deg, #E67E22, #D35400)" track="#1A1A2E" pct={85} />
    </div>
  )
}

// ─── Divider Previews ────────────────────────────────────────────

export function DividerPreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Gold */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Gold</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 0, marginTop: 4 }}>
          <div style={{ flex: 1, height: 1.5, background: `linear-gradient(90deg, transparent, ${c.accent.goldDim}, ${c.accent.gold})` }} />
          <div style={{ width: 8, height: 8, background: c.accent.gold, transform: 'rotate(45deg)', margin: '0 4px' }} />
          <div style={{ flex: 1, height: 1.5, background: `linear-gradient(90deg, ${c.accent.gold}, ${c.accent.goldDim}, transparent)` }} />
        </div>
      </div>
      {/* Ornamental */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Ornamental</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4 }}>
          <div style={{ flex: 1, height: 1, background: `linear-gradient(90deg, transparent, ${c.border.borderMedium})` }} />
          <div style={{ display: 'flex', gap: 3 }}>
            <div style={{ width: 4, height: 4, background: c.border.borderMedium, transform: 'rotate(45deg)' }} />
            <div style={{ width: 6, height: 6, background: c.accent.gold, transform: 'rotate(45deg)' }} />
            <div style={{ width: 4, height: 4, background: c.border.borderMedium, transform: 'rotate(45deg)' }} />
          </div>
          <div style={{ flex: 1, height: 1, background: `linear-gradient(90deg, ${c.border.borderMedium}, transparent)` }} />
        </div>
      </div>
      {/* Etched Groove */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Etched Groove</span>
        <div style={{ marginTop: 4 }}>
          <div style={{ height: 1, background: c.background.bgAbyss }} />
          <div style={{ height: 1, background: `${c.border.borderSubtle}` }} />
        </div>
      </div>
    </div>
  )
}

// ─── Toast Previews ──────────────────────────────────────────────

const toastTypes = [
  { type: 'Achievement', color: c.accent.gold, icon: '🏆' },
  { type: 'Level Up', color: c.toast.toastLevelUp, icon: '⬆️' },
  { type: 'Rank Up', color: c.toast.toastRankUp, icon: '👑' },
  { type: 'Quest', color: c.accent.cyan, icon: '📜' },
  { type: 'Reward', color: c.accent.goldBright, icon: '🎁' },
  { type: 'Info', color: c.toast.toastInfo, icon: 'ℹ️' },
  { type: 'Error', color: c.accent.danger, icon: '❌' },
]

export function ToastPreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {toastTypes.map(toast => (
        <div key={toast.type} style={{
          display: 'flex', alignItems: 'center', gap: 10,
          background: c.background.bgSecondary, border: `1px solid ${toast.color}40`,
          borderRadius: r.radiusLG, padding: '8px 14px',
          borderLeft: `3px solid ${toast.color}`,
        }}>
          <span style={{ fontSize: 14 }}>{toast.icon}</span>
          <div>
            <p style={{ color: toast.color, fontFamily: '"Oswald", sans-serif', fontSize: 14 }}>{toast.type}</p>
            <p style={{ color: c.text.textSecondary, fontFamily: 'Inter', fontSize: 11 }}>Toast notification sample</p>
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── Rarity Item Card Previews ───────────────────────────────────

export function ItemCardPreviews() {
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      {rarityCards.map(rarity => (
        <div key={rarity.name} style={{
          width: 72, background: c.background.bgSecondary,
          border: `1.5px solid ${rarity.color}`, borderRadius: r.radiusLG,
          overflow: 'hidden',
        }}>
          <div style={{
            height: 72, background: c.background.bgTertiary,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `inset 0 0 20px ${rarity.color}20`,
          }}>
            <div style={{ width: 32, height: 32, borderRadius: 4, background: `${rarity.color}40` }} />
          </div>
          <div style={{ padding: '4px 6px', textAlign: 'center' }}>
            <p style={{ color: rarity.color, fontFamily: 'Inter', fontSize: 9, fontWeight: 600 }}>{rarity.name}</p>
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── Tab Switcher Previews ──────────────────────────────────────

function TabBar({ tabs, activeIndex }: { tabs: string[]; activeIndex: number }) {
  return (
    <div style={{ display: 'flex', borderBottom: `1px solid ${c.border.borderSubtle}` }}>
      {tabs.map((tab, i) => (
        <div key={tab} style={{
          flex: 1, textAlign: 'center', padding: '10px 0 8px',
          fontFamily: '"Oswald", sans-serif', fontSize: 14, letterSpacing: 1,
          color: i === activeIndex ? c.accent.goldBright : c.text.textTertiary,
          borderBottom: i === activeIndex ? `2px solid ${c.accent.gold}` : '2px solid transparent',
          cursor: 'pointer',
        }}>
          {tab}
        </div>
      ))}
    </div>
  )
}

export function TabSwitcherPreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>2-tab</span>
        <TabBar tabs={['OPPONENTS', 'HISTORY']} activeIndex={0} />
      </div>
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>3-tab</span>
        <TabBar tabs={['PVP', 'PROGRESS', 'RANKING']} activeIndex={1} />
      </div>
    </div>
  )
}

// ─── Navigation Previews ────────────────────────────────────────

export function NavigationPreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {/* NavGrid */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>NavGrid</span>
        <div style={{
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column', gap: 4,
          width: 80, height: 72, marginTop: 4,
          background: c.background.bgSecondary,
          border: `1.5px solid ${c.accent.gold}`,
          borderRadius: r.radiusMD,
        }}>
          <span style={{ fontSize: 22 }}>⚔️</span>
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 11, color: c.accent.goldBright, letterSpacing: 1 }}>ARENA</span>
        </div>
      </div>
      {/* BackButton */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>BackButton</span>
        <div style={{
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          width: 36, height: 36, marginTop: 4,
          borderRadius: r.radiusSM,
        }}>
          <span style={{ fontSize: 24, color: c.text.textSecondary }}>←</span>
        </div>
      </div>
      {/* ScreenHeader */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>ScreenHeader</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 4 }}>
          <span style={{ fontSize: 20, color: c.text.textSecondary }}>←</span>
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 22, color: c.accent.goldBright, letterSpacing: 1 }}>FORTUNE WHEEL</span>
        </div>
      </div>
    </div>
  )
}

// ─── Ornamental Title Previews ──────────────────────────────────

export function OrnamentalTitlePreviews() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      {/* ScreenTitle */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>ScreenTitle</span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
          <div style={{ flex: 1, height: 1.5, background: `linear-gradient(90deg, transparent, ${c.accent.gold})` }} />
          <div style={{ width: 6, height: 6, background: c.accent.gold, transform: 'rotate(45deg)' }} />
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 28, color: c.accent.goldBright, letterSpacing: 2, textTransform: 'uppercase' as const }}>
            Inventory
          </span>
          <div style={{ width: 6, height: 6, background: c.accent.gold, transform: 'rotate(45deg)' }} />
          <div style={{ flex: 1, height: 1.5, background: `linear-gradient(90deg, ${c.accent.gold}, transparent)` }} />
        </div>
      </div>
      {/* SectionHeader */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>SectionHeader</span>
        <div style={{ marginTop: 6 }}>
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 22, color: c.accent.gold, letterSpacing: 1, textTransform: 'uppercase' as const }}>
            Equipment
          </span>
        </div>
      </div>
    </div>
  )
}

// ─── Input Field Previews ───────────────────────────────────────

export function InputFieldPreviews() {
  return (
    <div style={{ display: 'flex', gap: 12 }}>
      {/* Default */}
      <div style={{ flex: 1 }}>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Default</span>
        <div style={{
          marginTop: 4, padding: '10px 12px',
          background: c.background.bgTertiary,
          border: `1px solid ${c.border.borderSubtle}`,
          borderRadius: r.radiusMD,
        }}>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 14 }}>Enter username</span>
        </div>
      </div>
      {/* Focused */}
      <div style={{ flex: 1 }}>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Focused</span>
        <div style={{
          marginTop: 4, padding: '10px 12px',
          background: c.background.bgTertiary,
          border: `1px solid ${c.accent.gold}`,
          borderRadius: r.radiusMD,
          boxShadow: `0 0 6px ${c.accent.gold}33`,
        }}>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 14 }}>Enter username</span>
        </div>
      </div>
      {/* Error */}
      <div style={{ flex: 1 }}>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Error</span>
        <div style={{
          marginTop: 4, padding: '10px 12px',
          background: c.background.bgTertiary,
          border: `1px solid ${c.accent.danger}`,
          borderRadius: r.radiusMD,
        }}>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 14 }}>Enter username</span>
        </div>
        <span style={{ color: c.accent.danger, fontFamily: 'Inter', fontSize: 11, marginTop: 4, display: 'block' }}>Invalid email</span>
      </div>
    </div>
  )
}

// ─── Avatar Previews ────────────────────────────────────────────

export function AvatarPreviews() {
  const sizes = [
    { name: 'Large', size: 72 },
    { name: 'Medium', size: 56 },
    { name: 'Small', size: 40 },
  ]
  return (
    <div style={{ display: 'flex', alignItems: 'end', gap: 16 }}>
      {sizes.map(avatar => (
        <div key={avatar.name} style={{ textAlign: 'center' }}>
          <div style={{
            width: avatar.size, height: avatar.size,
            borderRadius: '50%',
            background: c.background.bgTertiary,
            border: `2px solid ${c.border.borderSubtle}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: avatar.size * 0.4,
          }}>
            👤
          </div>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10, marginTop: 4, display: 'block' }}>{avatar.name} {avatar.size}px</span>
        </div>
      ))}
    </div>
  )
}

// ─── Skeleton Previews ──────────────────────────────────────────

export function SkeletonPreviews() {
  const shimmerBg = `linear-gradient(90deg, ${c.background.bgTertiary} 25%, ${c.border.borderSubtle} 50%, ${c.background.bgTertiary} 75%)`
  return (
    <div style={{ display: 'flex', gap: 16, alignItems: 'start' }}>
      {/* Rectangle */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Rectangle</span>
        <div style={{
          width: 160, height: 20, marginTop: 4,
          borderRadius: r.radiusSM,
          background: shimmerBg,
        }} />
      </div>
      {/* Card */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>Card</span>
        <div style={{
          width: 200, height: 120, marginTop: 4,
          borderRadius: r.radiusLG,
          background: shimmerBg,
        }} />
      </div>
      {/* ItemCell */}
      <div>
        <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>ItemCell</span>
        <div style={{
          width: 64, height: 64, marginTop: 4,
          borderRadius: r.radiusMD,
          background: shimmerBg,
        }} />
      </div>
    </div>
  )
}

// ─── Loading Overlay Previews ───────────────────────────────────

export function LoadingOverlayPreviews() {
  return (
    <div style={{
      position: 'relative', width: 240, height: 140,
      borderRadius: r.radiusLG, overflow: 'hidden',
      background: c.background.bgSecondary,
    }}>
      {/* Simulated content behind */}
      <div style={{ padding: 16, opacity: 0.3 }}>
        <div style={{ width: 120, height: 12, background: c.border.borderSubtle, borderRadius: 4, marginBottom: 8 }} />
        <div style={{ width: 180, height: 12, background: c.border.borderSubtle, borderRadius: 4, marginBottom: 8 }} />
        <div style={{ width: 90, height: 12, background: c.border.borderSubtle, borderRadius: 4 }} />
      </div>
      {/* Overlay */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'rgba(8, 8, 12, 0.75)',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8,
      }}>
        <span style={{ fontSize: 24 }}>⏳</span>
        <span style={{ color: c.text.textSecondary, fontFamily: 'Inter', fontSize: 13 }}>Loading...</span>
      </div>
    </div>
  )
}

// ─── Card Level Badge Previews ──────────────────────────────────

export function CardLevelBadgePreviews() {
  const badges = [
    { name: 'Standard', size: 48, fontSize: 13 },
    { name: 'Compact', size: 36, fontSize: 10 },
  ]
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
      {badges.map(badge => (
        <div key={badge.name} style={{ textAlign: 'center' }}>
          <div style={{
            width: badge.size, height: badge.size,
            borderRadius: '50%',
            background: `linear-gradient(180deg, ${c.background.bgSecondary}, ${c.background.bgTertiary})`,
            border: `2px solid ${c.accent.gold}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 0 8px ${c.accent.gold}33`,
          }}>
            <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: badge.fontSize, color: c.accent.goldBright }}>Lv.25</span>
          </div>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10, marginTop: 4, display: 'block' }}>{badge.name} {badge.size}px</span>
        </div>
      ))}
    </div>
  )
}

// ─── Payout Pill Previews ───────────────────────────────────────

export function PayoutPillPreviews() {
  const payouts = [
    { multiplier: 'x1.5', color: c.accent.gold, sectors: 8, icon: '🪙' },
    { multiplier: 'x2', color: c.accent.goldBright, sectors: 6, icon: '💰' },
    { multiplier: 'x3', color: c.accent.purple, sectors: 3, icon: '💎' },
    { multiplier: 'x5', color: c.accent.info, sectors: 1, icon: '⭐' },
  ]
  return (
    <div style={{ display: 'flex', gap: 8 }}>
      {payouts.map(p => (
        <div key={p.multiplier} style={{
          display: 'flex', alignItems: 'center', gap: 6,
          background: `${p.color}15`,
          border: `1px solid ${p.color}40`,
          borderRadius: 12, padding: '6px 12px',
        }}>
          <span style={{ fontSize: 12 }}>{p.icon}</span>
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 14, color: p.color, fontWeight: 700 }}>{p.multiplier}</span>
          <span style={{ fontFamily: 'Inter', fontSize: 10, color: c.text.textTertiary }}>({p.sectors})</span>
        </div>
      ))}
    </div>
  )
}

// ─── Wager Button Previews ──────────────────────────────────────

export function WagerButtonPreviews() {
  const wagers = [
    { name: 'Default', bg: c.background.bgTertiary, border: c.border.borderSubtle, text: c.text.textPrimary, opacity: 1 },
    { name: 'Selected', bg: `linear-gradient(180deg, ${c.accent.gold}, ${c.accent.goldDim})`, border: c.accent.gold, text: c.text.textOnGold, opacity: 1 },
    { name: 'Disabled', bg: c.background.bgTertiary, border: c.border.borderSubtle, text: c.text.textPrimary, opacity: 0.4 },
  ]
  return (
    <div style={{ display: 'flex', gap: 12 }}>
      {wagers.map(w => (
        <div key={w.name} style={{ textAlign: 'center' }}>
          <span style={{ color: c.text.textTertiary, fontFamily: 'Inter', fontSize: 10 }}>{w.name}</span>
          <div style={{
            marginTop: 4, padding: '10px 20px',
            background: w.bg,
            border: `1.5px solid ${w.border}`,
            borderRadius: r.radiusMD,
            opacity: w.opacity,
          }}>
            <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 18, color: w.text, letterSpacing: 1 }}>100</span>
          </div>
        </div>
      ))}
    </div>
  )
}

// ─── State View Previews ────────────────────────────────────────

export function StateViewPreviews() {
  const states = [
    { name: 'EmptyInventory', icon: '🎒', title: 'No Items Yet', desc: 'Complete quests and defeat bosses to earn loot.', color: c.text.textTertiary },
    { name: 'NoQuests', icon: '📜', title: 'No Active Quests', desc: 'Visit the quest board for new adventures.', color: c.accent.gold },
    { name: 'NetworkError', icon: '📡', title: 'Connection Lost', desc: 'Check your internet and try again.', color: c.accent.danger },
    { name: 'ServerError', icon: '🔥', title: 'Server Error', desc: 'Something went wrong. Please try later.', color: c.accent.danger },
  ]
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 10 }}>
      {states.map(state => (
        <div key={state.name} style={{
          background: c.background.bgSecondary,
          border: `1px solid ${c.border.borderSubtle}`,
          borderRadius: r.radiusLG,
          padding: s.spaceLG,
          textAlign: 'center',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        }}>
          <span style={{ fontSize: 28 }}>{state.icon}</span>
          <span style={{ fontFamily: '"Oswald", sans-serif', fontSize: 16, color: state.color, letterSpacing: 1 }}>{state.title}</span>
          <span style={{ fontFamily: 'Inter', fontSize: 11, color: c.text.textSecondary, lineHeight: '16px' }}>{state.desc}</span>
        </div>
      ))}
    </div>
  )
}
