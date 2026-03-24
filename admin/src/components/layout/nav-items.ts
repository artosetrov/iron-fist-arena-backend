import type { LucideIcon } from 'lucide-react'
import {
  LayoutDashboard, Database, Users, Swords, Package, Trophy,
  Calendar, Sliders, Scroll, ImageIcon, Settings, Shield, Dice3,
  Coins, ScrollText, Castle, Zap, GitBranch, Scale, Gauge, Palette,
  FlaskConical, Archive, Gift, Award, Mail, Flag, ShoppingBag, Bell,
  Map, MessageSquare,
} from 'lucide-react'

export interface NavItem {
  label: string
  href: string
  icon: LucideIcon
}

export interface NavGroup {
  label: string
  items: NavItem[]
}

/** Flat list for backwards compat */
export const navItems: NavItem[] = [
  { label: 'Dashboard', href: '/', icon: LayoutDashboard },
  { label: 'Tables', href: '/tables', icon: Database },
  { label: 'Players', href: '/players', icon: Users },
  { label: 'Arena', href: '/matches', icon: Swords },
  { label: 'Social', href: '/social', icon: MessageSquare },
  { label: 'Dungeons', href: '/dungeons', icon: Castle },
  { label: 'Economy', href: '/economy', icon: Coins },
  { label: 'Items', href: '/items', icon: ScrollText },
  { label: 'Consumables', href: '/consumables', icon: FlaskConical },
  { label: 'Skills', href: '/skills', icon: Zap },
  { label: 'Passives', href: '/passives', icon: GitBranch },
  { label: 'Loot Tables', href: '/loot', icon: Dice3 },
  { label: 'Game Balance', href: '/balance', icon: Gauge },
  { label: 'Item Balance', href: '/item-balance', icon: Scale },
  { label: 'Events', href: '/events', icon: Calendar },
  { label: 'Seasons', href: '/seasons', icon: Trophy },
  { label: 'Battle Pass', href: '/battle-pass', icon: Award },
  { label: 'Achievements', href: '/achievements', icon: Shield },
  { label: 'Quests', href: '/quests', icon: Scroll },
  { label: 'Daily Login', href: '/daily-login', icon: Gift },
  { label: 'Mail / Inbox', href: '/mail', icon: Mail },
  { label: 'Shop Offers', href: '/offers', icon: ShoppingBag },
  { label: 'Push Notifications', href: '/push', icon: Bell },
  { label: 'Feature Flags', href: '/flags', icon: Flag },
  { label: 'Live Config', href: '/config', icon: Sliders },
  { label: 'Config Snapshots', href: '/snapshots', icon: Archive },
  { label: 'Appearances', href: '/appearances', icon: Palette },
  { label: 'Assets', href: '/assets', icon: ImageIcon },
  { label: 'Settings', href: '/settings', icon: Settings },
]

/** Grouped navigation for sidebar */
export const navGroups: NavGroup[] = [
  {
    label: 'Overview',
    items: [
      { label: 'Dashboard', href: '/', icon: LayoutDashboard },
      { label: 'Players', href: '/players', icon: Users },
      { label: 'Arena', href: '/matches', icon: Swords },
      { label: 'Social', href: '/social', icon: MessageSquare },
    ],
  },
  {
    label: 'Content',
    items: [
      { label: 'Items', href: '/items', icon: ScrollText },
      { label: 'Consumables', href: '/consumables', icon: FlaskConical },
      { label: 'Skills', href: '/skills', icon: Zap },
      { label: 'Passives', href: '/passives', icon: GitBranch },
      { label: 'Dungeons', href: '/dungeons', icon: Castle },
      { label: 'Dungeon Map', href: '/dungeon-map', icon: Map },
      { label: 'Appearances', href: '/appearances', icon: Palette },
      { label: 'Assets', href: '/assets', icon: ImageIcon },
    ],
  },
  {
    label: 'Gameplay',
    items: [
      { label: 'Quests', href: '/quests', icon: Scroll },
      { label: 'Achievements', href: '/achievements', icon: Shield },
      { label: 'Events', href: '/events', icon: Calendar },
      { label: 'Seasons', href: '/seasons', icon: Trophy },
    ],
  },
  {
    label: 'Economy',
    items: [
      { label: 'Economy', href: '/economy', icon: Coins },
      { label: 'Loot Tables', href: '/loot', icon: Dice3 },
      { label: 'Shop Offers', href: '/offers', icon: ShoppingBag },
      { label: 'Battle Pass', href: '/battle-pass', icon: Award },
      { label: 'Daily Login', href: '/daily-login', icon: Gift },
    ],
  },
  {
    label: 'Balance',
    items: [
      { label: 'Game Balance', href: '/balance', icon: Gauge },
      { label: 'Item Balance', href: '/item-balance', icon: Scale },
    ],
  },
  {
    label: 'LiveOps',
    items: [
      { label: 'Mail / Inbox', href: '/mail', icon: Mail },
      { label: 'Push Notifications', href: '/push', icon: Bell },
      { label: 'Live Config', href: '/config', icon: Sliders },
      { label: 'Feature Flags', href: '/flags', icon: Flag },
      { label: 'Config Snapshots', href: '/snapshots', icon: Archive },
    ],
  },
  {
    label: 'System',
    items: [
      { label: 'Tables', href: '/tables', icon: Database },
      { label: 'Settings', href: '/settings', icon: Settings },
    ],
  },
]
