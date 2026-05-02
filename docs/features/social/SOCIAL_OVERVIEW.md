# Feature: Social System

> **Status boundary:** secondary feature note. Keep this file as a compact
> overview only; the live source of truth is the checked-in wiki feature map.
> **Last updated:** 2026-04-30
> **Source of truth:** `/Users/artosetrov/Documents/Cursor AI/PVP RPG/wiki/features/social.md`

---

## Overview

The shipped social system is centered on **Guild Hall** as a social hub, but
the live runtime today is narrower than a full guild-management feature:
friends, direct messages, PvP challenges, and adjacent guild-challenge
scaffolding.

Secondary overview: [`../guild-hall/GUILD_HALL_OVERVIEW.md`](../guild-hall/GUILD_HALL_OVERVIEW.md)

## Subsystems

- **Allies (Friends):** friend requests, online status, context menu actions
- **Scrolls (Messages):** direct-message conversations, conversation threads, deep-links
- **Duels (Challenges):** send/accept/decline challenges, combat + rewards

## Additional UX Spec

`docs/07_ui_ux/SOCIAL_FLOWS_UX_SPEC.md` — historical UX proposal/spec for the broader social/guild direction

## Key Services

- `SocialService.swift` — friends CRUD
- `ChallengeService.swift` — duels CRUD
- `MessageService.swift` — messaging
- Backend: `backend/src/app/api/social/` (friends, challenges, messages, status)
