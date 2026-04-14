---
title: Screen Inventory
category: entities
tags: [ui, screens, navigation, flows]
sources: [docs/07_ui_ux/SCREEN_INVENTORY.md]
updated: 2026-04-14
---

# Screen Inventory

70+ Swift views, 46 Figma screens, 28 routing paths.

## Navigation

`NavigationStack` with `AppRouter` enum. 3 conceptual areas: Hub, Arena, Hero.

## Screen Map

| Area | Screens | Key Flow |
|------|---------|----------|
| Auth | 6 | Welcome → Login/Register → Character Creation → Email Confirmation |
| Hub | 8 | City Map, Hero Detail, Stance Selector, Dungeon Map |
| Arena | 5 | Opponent selection → Comparison → Fight |
| Combat | 4 + VFX | Active combat → Results → Loot |
| Inventory | 2 | Equipment/Consumables tabs, Item Detail Sheet |
| Shop | 4 | Equipment, Consumables, Premium, Currency |
| Dungeons | 7 | Select → Room progression → Boss → Victory/Defeat |
| Minigames | 5 | Gold Mine, Shell Game, Dungeon Rush, Tavern, Fortune Wheel |
| Progression | 7 | Daily Quests, Login Streaks, Achievements, Battle Pass |
| Social | 4 | Leaderboard, Player Detail, Inbox, Guild Hall |
| Settings | 4 | Settings, Appearance, Profile, Session Summary |

## Component Library

- 30+ reusable components
- 20 button styles (6 families)
- 9 card styles
- 47 Figma component sets, 235 variants

## See Also

- [[design-system]]
- [[combat]]
- [[economy]]
