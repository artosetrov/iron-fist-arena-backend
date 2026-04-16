---
title: Block 066 — admin skills and passives editor async-state hardening
category: audit
tags: [audit, admin, skills, passives, async-state, editors]
sources:
  - admin/src/app/(dashboard)/skills/skills-client.tsx
  - admin/src/app/(dashboard)/passives/passives-client.tsx
updated: 2026-04-15
status: Fixed
---

# Block 066 — admin skills and passives editor async-state hardening

## Scope

- `admin/src/app/(dashboard)/skills/skills-client.tsx`
- `admin/src/app/(dashboard)/passives/passives-client.tsx`

## Why this block

After the earlier admin cleanup, the content editors for combat skills and passive-tree structure were still using transition state as if it described the real save/delete lifecycle.

That is a poor fit for these screens because they are not simple read views. They are editor surfaces where operators create, update, and delete canonical combat content. If the pending model is vague there, the UI becomes easy to mistrust.

## Related pages

- [[audit-index]]
- [[project-file-inventory]]
- [[block-050-admin-skills-passives-proxy-alignment]]
- [[block-064-admin-config-and-balance-editor-async-state-hardening]]
- [[block-065-admin-snapshots-and-item-balance-editor-async-state-hardening]]

## File notes

### `admin/src/app/(dashboard)/skills/skills-client.tsx`

- **Zone:** admin / skills
- **Purpose:** create, edit, filter, and delete active skills
- **Problems found:**
  - form submit and delete still relied on one generic pending state
  - row actions did not clearly respect whether save or delete was already running
- **What was fixed:**
  - removed `useTransition`
  - added explicit `isSavingSkill` and `isDeletingSkill`
  - disabled row actions while a skill mutation is in flight
  - aligned dialog buttons with the actual save/delete lifecycle
- **Status:** Fixed

### `admin/src/app/(dashboard)/passives/passives-client.tsx`

- **Zone:** admin / passives
- **Purpose:** manage passive nodes and directed connections
- **Problems found:**
  - node save, node delete, connection create, and connection delete all leaned on one shared pending state
  - node and connection dialogs could not truthfully indicate which mutation path was active
- **What was fixed:**
  - removed `useTransition`
  - introduced dedicated state for `isSavingNode`, `isDeletingNode`, `isCreatingConnection`, and `isDeletingConnection`
  - disabled conflicting row/dialog actions while the matching mutation is running
  - updated action labels so the operator sees the real active operation
- **Status:** Fixed

## Problems found

1. **Editor dialogs were still using a generic pending flag for distinct mutation paths**
   - Risk: operators could see “Saving” or “Deleting” state that did not actually map to the active skill/passive operation.
   - Fix: split async state by mutation type instead of sharing one transition flag.

2. **Content-authoring surfaces had weaker action isolation than live config screens**
   - Risk: an operator could attempt conflicting skill/passive actions while the editor was already mutating content.
   - Fix: disabled row and dialog controls according to the actual mutation in flight.

3. **Tree and skill editors lagged behind the admin-wide async-state cleanup**
   - Risk: the project would end up with inconsistent operator behavior across equally important admin screens.
   - Fix: brought these editors onto the same explicit awaited lifecycle pattern used in the newer cleaned-up admin surfaces.

## Verification

- targeted admin `eslint`:
  - `src/app/(dashboard)/skills/skills-client.tsx`
  - `src/app/(dashboard)/passives/passives-client.tsx`
- `npx next build` in `admin/`
- `git diff --check`
- `rg -n "startTransition\\(async|isPending|useTransition"` on the touched files

## Follow-up

- the next obvious admin shell for the same cleanup pattern is `tables/[tableName]/table-client.tsx`
- after that, the remaining admin debt is much less about misleading mutation state and much more about smaller consistency/documentation tails
