# Feature: Social System

> **Status:** Complete
> **Owner:** Social systems
> **Last updated:** 2026-03-26
> **Source of truth:** See [`../guild-hall/GUILD_HALL_OVERVIEW.md`](../guild-hall/GUILD_HALL_OVERVIEW.md)

---

## Overview

Социальная система реализована через **Guild Hall** — единый social hub.

Полная документация: [`../guild-hall/GUILD_HALL_OVERVIEW.md`](../guild-hall/GUILD_HALL_OVERVIEW.md)

## Subsystems

- **Allies (Friends):** friend requests, online status, context menu actions
- **Scrolls (Messages):** direct messaging, conversation threads, deep-links
- **Duels (Challenges):** send/accept/decline challenges, combat + rewards

## Additional UX Spec

`docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md` — detailed UX flows for all social interactions

## Key Services

- `SocialService.swift` — friends CRUD
- `ChallengeService.swift` — duels CRUD
- `MessageService.swift` — messaging
- Backend: `backend/src/app/api/social/` (friends, challenges, messages, status)
