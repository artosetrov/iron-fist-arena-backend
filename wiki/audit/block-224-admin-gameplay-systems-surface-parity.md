---
title: Audit Block 224 — Admin Gameplay Systems Surface Parity
category: audit
tags: [audit, docs, admin, skills, passives, quests, events, seasons]
sources:
  - docs/05_admin_panel/ADMIN_CAPABILITIES.md
  - admin/src/app/(dashboard)/skills/skills-client.tsx
  - admin/src/app/(dashboard)/passives/passives-client.tsx
  - admin/src/app/(dashboard)/quests/quests-client.tsx
  - admin/src/app/(dashboard)/events/events-client.tsx
  - admin/src/app/(dashboard)/seasons/seasons-client.tsx
updated: 2026-04-19
status: Fixed
---

# Audit Block 224 — Admin Gameplay Systems Surface Parity

## Scope

- `docs/05_admin_panel/ADMIN_CAPABILITIES.md`
- `admin/src/app/(dashboard)/skills/skills-client.tsx`
- `admin/src/app/(dashboard)/passives/passives-client.tsx`
- `admin/src/app/(dashboard)/quests/quests-client.tsx`
- `admin/src/app/(dashboard)/events/events-client.tsx`
- `admin/src/app/(dashboard)/seasons/seasons-client.tsx`

## Why this block

The next gameplay-systems cluster in `ADMIN_CAPABILITIES.md` was still describing a broader design/ops suite than the live admin dashboard actually ships:

- Skills still implied an embedded combat simulator and richer rank-analysis workflow
- Passives still implied a visual drag-and-drop tree editor with path simulation
- Quests still implied date windows, ordering, and a seasonal planner
- Events still implied linked-content pickers, broadcast-message authoring, and participation analytics
- Seasons still implied that the season screen directly manages battle-pass rewards, grants, and sales

## Fix applied

### Skills

- rewrote the section around the live CRUD form:
  - `skillKey`
  - class restriction
  - damage base / scaling / type
  - target type
  - cooldown / mana
  - effect JSON
  - unlock level
  - max rank / rank scaling
  - icon
  - sort order
  - active toggle
- removed the implied embedded combat simulator and separate rank-analysis tooling

### Passives

- rewrote the section around the live nodes + connections workflow:
  - node CRUD
  - manual position fields
  - bonus metadata
  - connection create/delete by selected nodes
- removed the implied drag canvas, visual tree preview, and path simulation tooling

### Quests

- rewrote the section around the live quest-definition form:
  - quest type
  - title / description / icon
  - min/max target
  - gold / XP / gems rewards
  - active toggle
  - seed defaults
- removed active date range, display-order editing, and seasonal-planner wording

### Events

- rewrote the section around the live event CRUD cards:
  - event key
  - title / description
  - event type
  - config JSON
  - start / end times
  - active toggle
  - create/edit/delete
- removed association pickers, broadcast-message authoring, and participation analytics

### Seasons

- narrowed the section to the actual season CRUD screen:
  - season number
  - theme
  - start / end times
  - status review
  - create/edit/delete
- removed the implication that this screen is also the battle-pass rewards / grants / sales control center

## Result

The gameplay-systems section in `ADMIN_CAPABILITIES.md` now matches the real admin CRUD/editor surfaces much more closely instead of promising a larger design/ops toolkit than the repo currently ships.

## Verification

- compared the docs against the live skills, passives, quests, events, and seasons admin screens
- `git diff --check`

This closes the next stale gameplay-systems capability block inside `ADMIN_CAPABILITIES.md`.
