# Feature: Guild Hall (Social Hub)

> **Status boundary:** secondary feature note. Useful as a short product overview, but not the live source of truth.
> Re-check `/Users/artosetrov/Documents/Cursor AI/PVP RPG/wiki/features/social.md`,
> current `Hexbound/Hexbound/Views/Social/`, and current backend social routes
> before using this file for implementation decisions.
> **Last updated:** 2026-04-30

---

## Overview

Guild Hall is the shipped social hub with 3 tabs: Allies (friends), Scrolls
(direct-message conversations), and Duels (PvP challenges). The broader guild
entity / raid / bank / buff layer still belongs to the separate historical
guild-system draft, not to the live runtime.

## Tabs

| Tab | Real name | Game name | Purpose |
|-----|-----------|-----------|---------|
| Friends | Allies | Союзники | Friend list, requests, online status |
| Messages | Scrolls | Свитки | Direct-message conversations and thread replies |
| Challenges | Duels | Дуэли | Send/accept/decline challenges |

## Key Files

- iOS: `Views/Social/GuildHallDetailView.swift`, `Views/Social/GuildHallViewModel.swift`, `Views/Social/GuildHallScrollsTab.swift`
- Models: `Social.swift`, `Challenge.swift`, `Message.swift`
- Services: `SocialService.swift`, `ChallengeService.swift`, `MessageService.swift`
- Backend: `backend/src/app/api/social/` (friends, challenges, messages, status)

## Anti-abuse

- Friends: 20 requests/day, 24h cooldown after decline, 7-day expiry, max 50 friends
- Challenges: max 5 pending, max 10/day, 24h expiry, 1 stamina per send
- Messages: Any player can message any player (not friend-restricted); Scrolls are DM threads, not guild-wide notes/feed

## Related Docs

- Live feature map: `/Users/artosetrov/Documents/Cursor AI/PVP RPG/wiki/features/social.md`
- Historical UX spec: `/Users/artosetrov/Documents/Cursor AI/PVP RPG/docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md`
