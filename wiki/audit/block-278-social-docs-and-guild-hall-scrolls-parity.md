---
title: Audit Block 278 — Social Docs and Guild Hall Scrolls Parity
category: audit
tags: [audit, docs, wiki, social, guild-hall]
sources:
  - wiki/features/social.md
  - docs/features/guild-hall/GUILD_HALL_OVERVIEW.md
  - docs/features/social/SOCIAL_OVERVIEW.md
  - docs/PROJECT_INDEX.md
  - docs/01_source_of_truth/DOCUMENTATION_INDEX.md
  - Hexbound/Hexbound/Views/Social/GuildHallScrollsTab.swift
  - Hexbound/Hexbound/Views/Social/GuildHallViewModel.swift
  - Hexbound/Hexbound/Models/Message.swift
updated: 2026-04-30
status: Fixed
---

# Audit Block 278 — Social Docs and Guild Hall Scrolls Parity

## Scope

This block aligns the checked-in social docs with the current Guild Hall
runtime, especially the meaning of the Scrolls tab.

## Why this block

The live iOS/runtime layer clearly shows Scrolls as **direct-message
conversations + thread view**:

- `Conversation`
- `DirectMessageItem`
- `getConversations(...)`
- `getThread(...)`
- `GuildHallScrollsTab.swift`

But the docs were split across two older layers:

- `wiki/features/social.md` still called Scrolls "guild-wide messaging/notes"
- `docs/features/guild-hall/GUILD_HALL_OVERVIEW.md` and
  `docs/features/social/SOCIAL_OVERVIEW.md` still read like older standalone
  source-of-truth docs rather than secondary notes under the now-primary wiki
  layer

## Changes shipped

### `wiki/features/social.md`

- Replaced the stale "guild-wide messaging/notes" wording with the actual DM
  conversation / thread model used by `GuildHallScrollsTab.swift`.

### `docs/features/guild-hall/GUILD_HALL_OVERVIEW.md`

- Added a clear secondary-doc boundary.
- Corrected the runtime description so Scrolls are direct-message
  conversations, not a guild-wide notes/feed surface.
- Pointed readers back to `wiki/features/social.md` for live truth.

### `docs/features/social/SOCIAL_OVERVIEW.md`

- Added the same secondary-doc boundary.
- Pointed source-of-truth ownership back to `wiki/features/social.md`.
- Narrowed the runtime wording to the shipped friends + DMs + challenges
  surface instead of a broader implicit guild-management layer.

### `docs/PROJECT_INDEX.md` + `docs/01_source_of_truth/DOCUMENTATION_INDEX.md`

- Updated the social/Guild Hall pointers so they now acknowledge the wiki
  feature map as the live source-of-truth and treat the older feature docs as
  secondary overviews.

## Result

The social documentation stack now speaks with one voice again:

- Scrolls = DM conversations and thread replies
- Guild Hall = shipped social hub, not a full guild-management runtime
- `wiki/features/social.md` = live source-of-truth
- `docs/features/*social*` = secondary overview material
