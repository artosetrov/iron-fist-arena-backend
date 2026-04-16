'use client'

import { useState } from 'react'
import tokens from '@/lib/design-tokens.json'
// Pixel-perfect Figma DS components
import { ButtonAllVariants } from './figma-components/button'
import { CardAllVariants } from './figma-components/card'
import { DividerAllVariants } from './figma-components/divider'
import { ProgressBarAllVariants } from './figma-components/progress-bar'
import { WidgetPillAllVariants } from './figma-components/widget-pill'
import { CurrencyDisplayAllVariants } from './figma-components/currency-display'
import { TabSwitcherAllVariants } from './figma-components/tab-switcher'
import { ToastAllVariants } from './figma-components/toast'
import { NavigationAllVariants } from './figma-components/navigation'
import { InputFieldAllVariants } from './figma-components/input-field'
import { OrnamentalTitleAllVariants } from './figma-components/ornamental-title'
import { AvatarAllVariants } from './figma-components/avatar'
import { SkeletonAllVariants } from './figma-components/skeleton'
import { CardLevelBadgeAllVariants } from './figma-components/card-level-badge'
import { PayoutPillAllVariants } from './figma-components/payout-pill'
import { WagerButtonAllVariants } from './figma-components/wager-button'
import { StateViewAllVariants } from './figma-components/state-view'
import { HeroWidgetAllVariants } from './figma-components/hero-widget'
import { StanceDisplayAllVariants } from './figma-components/stance-display'
import { LoadingOverlayAllVariants } from './figma-components/loading-overlay'

// Fallback for remaining domain components
import { ItemCardPreviews } from './ds-components'
import {
  ArenaOpponentCardPreviews,
  BattleResultCardPreviews, LeaderboardRowPreviews, PvPStatsWidgetPreviews,
  DungeonBossCardPreviews, AchievementCardPreviews, ActiveQuestBannerPreviews,
  BPRewardNodePreviews, InboxRowPreviews, NPCGuideWidgetPreviews,
  EventBannerPreviews, CelebrationBannerPreviews, GuestGatePreviews,
  SessionExpiredPreviews, ItemDetailSheetPreviews, LevelUpModalPreviews,
} from './ds-components-2'

type TabId = 'colors' | 'typography' | 'spacing' | 'components' | 'screens'

const tabs: { id: TabId; label: string }[] = [
  { id: 'colors', label: 'Colors' },
  { id: 'typography', label: 'Typography' },
  { id: 'spacing', label: 'Spacing & Radius' },
  { id: 'components', label: 'Components' },
  { id: 'screens', label: 'Screens' },
]

export function DesignSystemClient() {
  const [activeTab, setActiveTab] = useState<TabId>('colors')

  return (
    <div className="space-y-6">
      {/* Tab nav */}
      <div className="flex gap-1 rounded-lg bg-[#1A1A2E] p-1">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
              activeTab === tab.id
                ? 'bg-[#D4A537] text-[#1A1A2E]'
                : 'text-[#A0A0B0] hover:text-[#F5F5F5]'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === 'colors' && <ColorsTab />}
      {activeTab === 'typography' && <TypographyTab />}
      {activeTab === 'spacing' && <SpacingTab />}
      {activeTab === 'components' && <ComponentsTab />}
      {activeTab === 'screens' && <ScreensTab />}
    </div>
  )
}

/* ─── Colors Tab ────────────────────────────────────────────────── */

function formatGroupName(name: string): string {
  // Convert camelCase to Title Case
  // e.g. "bgDungeonDeep" → "BG Dungeon Deep"
  // "hp" → "HP", "vfx" → "VFX", "xp" → "XP"

  const acronyms: { [key: string]: string } = {
    hp: 'HP',
    xp: 'XP',
    vfx: 'VFX',
    pvp: 'PvP',
    bg: 'BG',
    btn: 'Button',
    npc: 'NPC',
  }

  // Check if entire name is an acronym
  if (acronyms[name]) return acronyms[name]

  // Split camelCase and replace known prefixes
  let result = name.replace(/([A-Z])/g, ' $1').trim()

  // Replace common prefixes with acronyms
  result = result.replace(/^Bg /, 'BG ')
  result = result.replace(/^Btn /, 'Button ')
  result = result.replace(/^Hp /, 'HP ')
  result = result.replace(/^Xp /, 'XP ')
  result = result.replace(/^Vfx /, 'VFX ')
  result = result.replace(/^Pvp /, 'PvP ')
  result = result.replace(/^Npc /, 'NPC ')

  // Capitalize first letter of each word
  result = result.replace(/\b\w/g, (char) => char.toUpperCase())

  return result
}

function ColorsTab() {
  const colorGroups = tokens.colors
  return (
    <div className="space-y-8">
      {Object.entries(colorGroups).map(([groupName, group]) => (
        <div key={groupName}>
          <h3 className="text-lg font-semibold mb-3 text-[#F5F5F5]">
            {formatGroupName(groupName)}
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {Object.entries(group).map(([name, hex]) => (
              <ColorSwatch key={name} name={name} hex={hex} />
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

function ColorSwatch({ name, hex }: { name: string; hex: string }) {
  const isTransparent = hex.startsWith('rgba')
  return (
    <div className="group">
      <div
        className="h-16 rounded-lg border border-[#2A2A3E] mb-1.5 cursor-pointer transition-transform hover:scale-105"
        style={{ backgroundColor: hex }}
        title={hex}
        onClick={() => navigator.clipboard.writeText(hex)}
      >
        {isTransparent && (
          <div className="h-full w-full rounded-lg" style={{
            backgroundImage: 'repeating-conic-gradient(#333 0% 25%, #222 0% 50%)',
            backgroundSize: '12px 12px',
          }}>
            <div className="h-full w-full rounded-lg" style={{ backgroundColor: hex }} />
          </div>
        )}
      </div>
      <p className="text-xs text-[#A0A0B0] truncate">{name}</p>
      <p className="text-[10px] text-[#6B6B80] font-mono truncate">{hex}</p>
    </div>
  )
}

/* ─── Typography Tab ────────────────────────────────────────────── */

function TypographyTab() {
  return (
    <div className="space-y-4 rounded-xl bg-[#0D0D12] p-6 border border-[#2A2A3E]">
      {Object.entries(tokens.typography).map(([token, def]) => (
        <div key={token} className="flex items-baseline gap-6 py-3 border-b border-[#1A1A2E] last:border-0">
          <div className="w-40 shrink-0">
            <p className="text-xs text-[#D4A537] font-mono">.{token}</p>
            <p className="text-[10px] text-[#6B6B80]">
              {def.fontFamily} {def.fontSize}px {def.fontWeight === 'bold' ? 'Bold' : ''}
            </p>
          </div>
          <p
            style={{
              fontFamily: def.fontFamily === 'Oswald' ? '"Oswald", sans-serif' : '"Inter", sans-serif',
              fontSize: `${def.fontSize}px`,
              fontWeight: def.fontWeight === 'bold' ? 700 : 400,
              color: '#F5F5F5',
            }}
          >
            The wheel turns. Destinies are forged.
          </p>
        </div>
      ))}
    </div>
  )
}

/* ─── Spacing & Radius Tab ──────────────────────────────────────── */

function SpacingTab() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
      {/* Spacing */}
      <div className="rounded-xl bg-[#0D0D12] p-6 border border-[#2A2A3E]">
        <h3 className="text-lg font-semibold mb-4">Spacing Scale</h3>
        <div className="space-y-3">
          {Object.entries(tokens.spacing).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="text-xs text-[#D4A537] font-mono w-24">.{name}</span>
              <div
                className="h-4 rounded bg-[#D4A537]"
                style={{ width: `${value * 4}px` }}
              />
              <span className="text-xs text-[#6B6B80]">{value}pt</span>
            </div>
          ))}
        </div>
      </div>

      {/* Radius */}
      <div className="rounded-xl bg-[#0D0D12] p-6 border border-[#2A2A3E]">
        <h3 className="text-lg font-semibold mb-4">Radius Scale</h3>
        <div className="space-y-3">
          {Object.entries(tokens.radius).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="text-xs text-[#D4A537] font-mono w-24">.{name}</span>
              <div
                className="w-16 h-16 border-2 border-[#D4A537] bg-[#1A1A2E]"
                style={{ borderRadius: `${value}px` }}
              />
              <span className="text-xs text-[#6B6B80]">{value}px</span>
            </div>
          ))}
        </div>
      </div>

      {/* Opacity */}
      <div className="rounded-xl bg-[#0D0D12] p-6 border border-[#2A2A3E]">
        <h3 className="text-lg font-semibold mb-4">Opacity Scale</h3>
        <div className="space-y-3">
          {Object.entries(tokens.opacity).map(([name, value]) => (
            <div key={name} className="flex items-center gap-4">
              <span className="text-xs text-[#D4A537] font-mono w-24">.{name}</span>
              <div className="w-16 h-8 rounded bg-[#D4A537]" style={{ opacity: value }} />
              <span className="text-xs text-[#6B6B80]">{value}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Icon Sizes */}
      <div className="rounded-xl bg-[#0D0D12] p-6 border border-[#2A2A3E]">
        <h3 className="text-lg font-semibold mb-4">Icon & Button Sizing</h3>
        <div className="space-y-3">
          {Object.entries(tokens.sizing).flatMap(([groupName, group]) =>
            typeof group === 'object' && group !== null
              ? Object.entries(group as Record<string, number>).map(([name, value]) => ({
                  key: `${groupName}.${name}`,
                  name,
                  value,
                }))
              : []
          ).map(({ key, name, value }) => (
            <div key={key} className="flex items-center gap-4">
              <span className="text-xs text-[#D4A537] font-mono w-36">.{name}</span>
              <div
                className="rounded border border-[#D4A537] bg-[#1A1A2E]"
                style={{ width: `${Math.min(value, 80)}px`, height: `${Math.min(value, 40)}px` }}
              />
              <span className="text-xs text-[#6B6B80]">{value}pt</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

/* ─── Components Tab (preview with Figma screenshots) ──────────── */

function ComponentsTab() {
  const sections = [
    { name: 'Button', variants: '18 variants (6 styles × 3 states)', swift: 'ButtonStyles.swift', preview: <ButtonAllVariants /> },
    { name: 'Card', variants: '9 variants (4 styles + 5 rarities)', swift: 'CardStyles.swift', preview: <CardAllVariants /> },
    { name: 'Progress Bar', variants: '15 variants (5 types × 3 sizes)', swift: 'HPBarView, XPBarView, StaminaBarView', preview: <ProgressBarAllVariants /> },
    { name: 'Widget Pill', variants: '10 styles', swift: 'WidgetPill.swift', preview: <WidgetPillAllVariants /> },
    { name: 'Toast', variants: '7 types', swift: 'ToastOverlayView.swift', preview: <ToastAllVariants /> },
    { name: 'Item Card', variants: '5 rarities', swift: 'ItemCardView.swift', preview: <ItemCardPreviews /> },
    { name: 'Currency Display', variants: '3 sizes', swift: 'CurrencyDisplay.swift', preview: <CurrencyDisplayAllVariants /> },
    { name: 'Divider', variants: '3 styles', swift: 'OrnamentalStyles.swift', preview: <DividerAllVariants /> },
    { name: 'Tab Switcher', variants: '2 (2-tab/3-tab)', swift: 'TabSwitcher.swift', preview: <TabSwitcherAllVariants /> },
    { name: 'Navigation', variants: '3 (NavGrid/BackButton/ScreenHeader)', swift: 'ScreenLayout.swift', preview: <NavigationAllVariants /> },
    { name: 'Ornamental Title', variants: '2 (ScreenTitle/SectionHeader)', swift: 'OrnamentalTitle.swift', preview: <OrnamentalTitleAllVariants /> },
    { name: 'Input Field', variants: '3 (Default/Focused/Error)', swift: 'Auth screens', preview: <InputFieldAllVariants /> },
    { name: 'Avatar', variants: '3 sizes (72/56/40)', swift: 'AvatarImageView.swift', preview: <AvatarAllVariants /> },
    { name: 'Skeleton', variants: '3 types', swift: 'SkeletonViews.swift', preview: <SkeletonAllVariants /> },
    { name: 'Loading Overlay', variants: '1', swift: 'LoadingOverlay.swift', preview: <LoadingOverlayAllVariants /> },
    { name: 'Card Level Badge', variants: '2 (Standard/Compact)', swift: 'CardLevelBadge.swift', preview: <CardLevelBadgeAllVariants /> },
    { name: 'Payout Pill', variants: '4 (x1.5/x2/x3/x5)', swift: 'FortuneWheelDetailView.swift', preview: <PayoutPillAllVariants /> },
    { name: 'Wager Button', variants: '3 states', swift: 'FortuneWheelDetailView.swift', preview: <WagerButtonAllVariants /> },
    { name: 'State View', variants: '4 (Empty/Error)', swift: 'EmptyStateView.swift', preview: <StateViewAllVariants /> },
    { name: 'Hero Widget', variants: '1', swift: 'UnifiedHeroWidget.swift', preview: <HeroWidgetAllVariants /> },
    { name: 'Stance Display', variants: '1', swift: 'StanceDisplayView.swift', preview: <StanceDisplayAllVariants /> },
    { name: 'Arena Opponent Card', variants: '1', swift: 'ArenaOpponentCard.swift', preview: <ArenaOpponentCardPreviews /> },
    { name: 'Battle Result Card', variants: '2 (Victory/Defeat)', swift: 'BattleResultCardView.swift', preview: <BattleResultCardPreviews /> },
    { name: 'Leaderboard Row', variants: '2 (Default/Self)', swift: 'LeaderboardRowView.swift', preview: <LeaderboardRowPreviews /> },
    { name: 'PvP Stats Widget', variants: '2+1', swift: 'PvPStatsWidget.swift', preview: <PvPStatsWidgetPreviews /> },
    { name: 'Dungeon Boss Card', variants: '3 states', swift: 'DungeonBossCard.swift', preview: <DungeonBossCardPreviews /> },
    { name: 'Achievement Card', variants: '4 states', swift: 'AchievementCardView.swift', preview: <AchievementCardPreviews /> },
    { name: 'Active Quest Banner', variants: '2 (Active/Complete)', swift: 'ActiveQuestBanner.swift', preview: <ActiveQuestBannerPreviews /> },
    { name: 'BP Reward Node', variants: '4 states', swift: 'BPRewardNodeView.swift', preview: <BPRewardNodePreviews /> },
    { name: 'Inbox Row', variants: '2 (Unread/Read)', swift: 'InboxRowView.swift', preview: <InboxRowPreviews /> },
    { name: 'NPC Guide Widget', variants: '3 (Full/Mini/Wheel)', swift: 'NPCGuideWidget.swift', preview: <NPCGuideWidgetPreviews /> },
    { name: 'Event Banner', variants: '2 (Normal/Urgent)', swift: 'EventBannerView.swift', preview: <EventBannerPreviews /> },
    { name: 'Celebration Banner', variants: '5 types', swift: 'CelebrationBannerView.swift', preview: <CelebrationBannerPreviews /> },
    { name: 'Guest Gate', variants: '1', swift: 'GuestGateView.swift', preview: <GuestGatePreviews /> },
    { name: 'Session Expired Modal', variants: '1', swift: 'SessionExpiredModalView.swift', preview: <SessionExpiredPreviews /> },
    { name: 'Item Detail Sheet', variants: '1', swift: 'ItemDetailSheet.swift', preview: <ItemDetailSheetPreviews /> },
    { name: 'Level Up Modal', variants: '1', swift: 'LevelUpModalView.swift', preview: <LevelUpModalPreviews /> },
  ]

  return (
    <div className="space-y-6">
      <p className="text-sm text-[#A0A0B0]">
        33 component sets, 130+ variants. Live web previews using DS tokens.
      </p>
      {sections.map((section) => (
        <div
          key={section.name}
          className="rounded-xl bg-[#0D0D12] border border-[#2A2A3E] overflow-hidden"
        >
          <div className="flex items-baseline justify-between px-5 py-3 border-b border-[#1A1A2E]">
            <div>
              <h4 className="text-sm font-semibold text-[#F5F5F5]">{section.name}</h4>
              <p className="text-[10px] text-[#6B6B80]">{section.variants}</p>
            </div>
            <p className="text-[10px] text-[#D4A537] font-mono">{section.swift}</p>
          </div>
          <div className="p-5 bg-[#08080C]">
            {section.preview}
          </div>
        </div>
      ))}

    </div>
  )
}

/* ─── Screens Tab ───────────────────────────────────────────────── */

function ScreensTab() {
  const figmaScreensFile = 'PalemJ36B97ZdC0cd8jzv4'
  const screens = [
    { name: 'Hub (City Map)', route: 'hub', nodeId: '0:194' },
    { name: 'Hero Page', route: 'hero', nodeId: '0:195' },
    { name: 'Arena (Opponents)', route: 'arena', nodeId: '0:196' },
    { name: 'Combat', route: 'combat', nodeId: '0:197' },
    { name: 'Shop', route: 'shop', nodeId: '0:198' },
    { name: 'Fortune Wheel', route: 'fortune-wheel', nodeId: '49:361' },
    { name: 'Tavern', route: 'tavern', nodeId: '0:200' },
    { name: 'Quest Log', route: 'quests', nodeId: '0:201' },
    { name: 'Achievements', route: 'achievements', nodeId: '0:202' },
    { name: 'Leaderboard', route: 'leaderboard', nodeId: '0:203' },
    { name: 'Battle Pass', route: 'battle-pass', nodeId: '0:204' },
    { name: 'Guild Hall', route: 'guild-hall', nodeId: '0:205' },
    { name: 'Inbox', route: 'inbox', nodeId: '0:206' },
    { name: 'Auth (Login)', route: 'auth', nodeId: '0:207' },
  ]

  return (
    <div className="space-y-4">
      <p className="text-sm text-[#A0A0B0]">
        All app screens. Click to open in Figma Screens file.
      </p>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {screens.map((screen) => (
          <a
            key={screen.route}
            href={`https://www.figma.com/design/${figmaScreensFile}/Hexbound-Design?node-id=${screen.nodeId.replace(':', '-')}`}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-xl bg-[#0D0D12] border border-[#2A2A3E] overflow-hidden hover:border-[#D4A537] transition-colors block"
          >
            <div className="aspect-[9/16] bg-[#1A1A2E] flex items-center justify-center relative">
              <div className="text-center">
                <span className="text-[#D4A537] text-2xl block mb-2">📱</span>
                <span className="text-[#6B6B80] text-xs">Open in Figma</span>
              </div>
            </div>
            <div className="p-3">
              <p className="text-sm text-[#F5F5F5] font-medium">{screen.name}</p>
              <p className="text-[10px] text-[#3498DB] font-mono mt-0.5">View in Figma &rarr;</p>
            </div>
          </a>
        ))}
      </div>
    </div>
  )
}
