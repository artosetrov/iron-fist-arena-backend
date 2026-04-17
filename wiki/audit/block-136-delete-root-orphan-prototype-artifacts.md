---
title: Block 136 — delete root orphan prototype artifacts
category: audit
tags: [audit, root, prototypes, deletion, cleanup]
sources:
  - review-choose-hero-guest-gating-before-after.jsx
  - gold-mine-ux-prototype.jsx
  - gold-mine-ux-prototype-ds.jsx
updated: 2026-04-16
status: Fixed
---

# Block 136 — delete root orphan prototype artifacts

## Scope

- `review-choose-hero-guest-gating-before-after.jsx`
- `gold-mine-ux-prototype.jsx`
- `gold-mine-ux-prototype-ds.jsx`

## Why this block

After the placeholder and duplicate-doc deletions, the next safe residue class was root-level prototype code that no longer had a real product or documentation role.

This block focuses on the highest-confidence cases:

- one **tracked** guest-gating review artifact that had already been marked in `block-001` as an orphan candidate
- two **local Gold Mine JSX prototypes** that were not part of the tracked repo contract and had no live references outside generated graph residue

That makes this a safe cleanup block, not a speculative design-history purge.

## Related pages

- [[block-001-root-files]]
- [[block-121-prototypes-link-parity-and-transition-state]]
- [[bug-patterns]]

## What was removed

### `review-choose-hero-guest-gating-before-after.jsx`

- **Previous role:** standalone React/Tailwind-like visual review for the guest-gating version of the Choose Hero flow
- **Why removal was safe:** no app imports, no live docs depended on it, and the product direction is already reflected in current iOS auth/guest-gate surfaces plus the tracked auth-flow prototype/history
- **Result:** deleted from the working tree

### `gold-mine-ux-prototype.jsx`

- **Previous role:** large standalone local React prototype for a Gold Mine UX exploration
- **Why removal was safe:** it was not part of the tracked repo contract, had no live doc or code references in the audited tree, and overlapped with the maintained HTML prototype/history surfaces already kept elsewhere
- **Result:** removed from the local working tree

### `gold-mine-ux-prototype-ds.jsx`

- **Previous role:** design-system-flavored local React prototype variant for Gold Mine UX
- **Why removal was safe:** same orphan profile as the non-DS variant; no tracked consumer, no source-of-truth role, no live reference outside generated graph residue
- **Result:** removed from the local working tree

## Problems resolved

1. **Root artifact drift**
   - Risk before: root-level prototype residue kept signaling “maybe still important” despite having no live ownership.
   - Resolution: deleted the orphan surfaces instead of leaving them in a permanent `Needs review` limbo.

2. **Generated-graph-only references**
   - Risk before: files appeared to have repo presence because graph caches mentioned them, even though no maintained docs or product code relied on them.
   - Resolution: treated graph residue as non-canonical and removed the orphan source files.

3. **Old design-review noise**
   - Risk before: standalone exploration files diluted the meaning of the remaining prototype set that actually still has documented historical value.
   - Resolution: narrowed the root/prototype layer to the artifacts that still have an explicit audit story.

## Verification

- confirmed `review-choose-hero-guest-gating-before-after.jsx` no longer exists in the working tree
- confirmed `gold-mine-ux-prototype.jsx` and `gold-mine-ux-prototype-ds.jsx` no longer exist in the working tree
- confirmed no live references remained outside historical audit/inventory surfaces that were updated in the same pass
- `git diff --check`

## Follow-up

- Continue the same rule for root/prototype cleanup: delete only when the file is already proven to be orphaned, duplicated, or replaced by a clearer historical source.
