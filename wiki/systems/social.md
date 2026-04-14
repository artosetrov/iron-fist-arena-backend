---
title: Social Systems
category: systems
tags: [social, guild-hall, friends, messaging, challenges, duels]
sources: [docs/features/social/, docs/features/guild-hall/]
updated: 2026-04-14
---

# Social Systems

Guild Hall hub with 3 tabs: Allies, Scrolls, Duels.

## Friends (Allies Tab)

- Max **50 friends**
- **20 friend requests/day** limit
- **24h cooldown** after decline
- **7-day expiry** on pending requests
- Online status: online / away / offline

## Messaging (Scrolls Tab)

- Any player can message any player (not restricted to friends)
- Conversation list with unread counts
- Thread view (ChatGPT-style bubbles)
- Quick reply chips
- Deep-link: `AppRoute.guildHallMessage(characterId:characterName:)`

## Challenges (Duels Tab)

- Max **5 pending challenges** at once
- Max **10 challenge sends/day**
- **24h challenge expiry**
- **1 stamina per send** (prevents spam)
- Accept → navigates to CombatDetailView for full combat playback
- Decline → optimistic UI with revert on failure

## See Also

- [[pvp-rating]]
- [[combat]]
- [[stamina]] (challenge cost)
