# Feature: Guild Hall (Social Hub)

> **Status:** Complete
> **Owner:** Social systems
> **Last updated:** 2026-03-26
> **Source of truth:** `Hexbound/Hexbound/Views/GuildHall/` + `backend/src/app/api/social/`

---

## Overview

Guild Hall — социальный хаб с 3 вкладками: Allies (друзья), Scrolls (сообщения), Duels (вызовы). Тематические названия в стиле dark fantasy.

## Tabs

| Tab | Real name | Game name | Purpose |
|-----|-----------|-----------|---------|
| Friends | Allies | Союзники | Friend list, requests, online status |
| Messages | Scrolls | Свитки | Direct messaging, conversations |
| Challenges | Duels | Дуэли | Send/accept/decline challenges |

## Key Files

- iOS: `GuildHallDetailView.swift`, `GuildHallViewModel.swift`
- Models: `Social.swift`, `Challenge.swift`, `Message.swift`
- Services: `SocialService.swift`, `ChallengeService.swift`, `MessageService.swift`
- Backend: `backend/src/app/api/social/` (friends, challenges, messages, status)

## Anti-abuse

- Friends: 20 requests/day, 24h cooldown after decline, 7-day expiry, max 50 friends
- Challenges: max 5 pending, max 10/day, 24h expiry, 1 stamina per send
- Messages: Any player can message any player (not friend-restricted)

## Related Docs

- Rules: `docs/rules/rules-swift.md`, `docs/rules/rules-backend.md`
- UX spec: `docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md`
