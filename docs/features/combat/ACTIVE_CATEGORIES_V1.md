# Active Abilities — UX Categories v1

Status: proposal, awaiting Artem's approval.
Owner: Active Slot UX.
Date: 2026-04-19.
Inspiration: Duels RPG (fandom wiki) — "Preparation" / "Direct" / "Trap" skill
archetypes. We keep it narrower: only Direct + a single Preparation bucket fit
the current 5 effects.

## Goal

Give players a clear mental model for what each active does *before* they tap
it. Today the 5 `active_action_type` values are flat and opaque — a player sees
an icon, a gold stroke, and a cooldown number. A pill that reads `STRIKE` or
`GUARD` tells them in one glance which slot is for offense, which is for
survival, which is for control.

## Non-goals

- Do **not** change any formula, magnitude, cooldown, or balance number.
- Do **not** rename the `active_action_type` enum values in DB / backend — they
  stay as `burst_damage`, `execute`, `stun_enemy`, `shield_self`, `heal_self`.
  Categories live in the iOS client as a presentation-layer grouping.
- Do **not** introduce a real "Preparation" mechanic (delayed buff that fires
  on the *next* strike). Shield is already de-facto Preparation-shaped; the
  other four are Direct. Real Preparation is a separate v2 proposal.
- Do **not** add "Trap" (reactive) actives. No such effect exists in the Active
  Slot infrastructure today. That is also a v2 proposal.

## Categories

Five pills, one per existing `TalentSlotAction` enum case. Derivable from the
raw action type — no new DB column, no new server field.

| Category  | TalentSlotAction | Timing     | Player-facing promise                                |
|-----------|------------------|------------|------------------------------------------------------|
| STRIKE    | `.burstDamage`   | Direct     | "Your next strike deals +N% damage."                 |
| FINISHER  | `.execute`       | Direct     | "If enemy HP is low, your next strike hits harder."  |
| CONTROL   | `.stunEnemy`     | Direct     | "Interrupt the enemy — they skip a turn."            |
| GUARD     | `.shieldSelf`    | Preparation| "Absorb part of the next hit you take."              |
| RECOVERY  | `.healSelf`      | Direct     | "Restore HP right now."                              |

### Color tokens (DarkFantasyTheme)

Reuse the existing `ActiveFireStyle` colors — consistent with the fire banner
the player already sees when the active triggers:

- STRIKE    → `DarkFantasyTheme.danger`   (red — aggression)
- FINISHER  → `DarkFantasyTheme.danger`   (red — aggression, condition spelled out in copy)
- CONTROL   → `DarkFantasyTheme.gold`     (gold — tempo / tactical)
- GUARD     → `DarkFantasyTheme.info`     (blue — protection)
- RECOVERY  → `DarkFantasyTheme.success`  (green — sustain)

FINISHER shares `danger` with STRIKE on purpose — it *is* damage — but the
copy always leads with the HP-threshold condition so the player reads it as a
distinct gameplay idea.

## Where the category shows up

Three surfaces, ordered by implementation effort:

1. **Active Fire Banner** (cheapest): today shows `BURST!`, `HEAL!`, `SHIELD!`,
   `STUN!`, `EXECUTE!`. Replace with the category label so all five banners
   feel like members of the same system: `STRIKE!`, `RECOVERY!`, `GUARD!`,
   `CONTROL!`, `FINISHER!`. The `ActiveFireStyle` struct already centralizes
   this mapping — single-file change.

2. **Active Slot Catalog / Details view** (where players pick actives): add a
   small category pill above the name. Pill uses the category color + uppercase
   label, matching the fire-banner vocabulary. The node's own name (e.g.
   "Fury Swing") becomes the title below the pill.

3. **Combat HUD slot button** (optional for v1): the 56×56 slot button is
   tight. Option A: keep icon-only, use the stroke color (or a 4-pixel corner
   pip) to hint at category. Option B: show a 3-letter abbreviation in a tiny
   chip at the bottom. Recommendation: Option A for v1 — don't overload the
   HUD; the pill lives in the catalog / details / banner.

## Open questions (for Artem)

1. **Ability names**. Current seeds use node keys as labels in the backend
   (`warrior_3_fury`, `rogue_5_ult`, etc.). Before we ship pills, Narrative
   (hexbound-studio:lore) should give each of the 8 seeded actives a real
   name. Placeholders in the prototype — not final copy.
2. **FINISHER color**. Sharing `danger` with STRIKE is intentional but risks
   visual collision in the banner. Alternative: a different red-orange shade
   if the DS has one. I recommend leaving it until after first playtest.
3. **HUD pip (Option A)**. Do we want a category tint on the slot button
   stroke, or keep the uniform gold stroke everyone already recognizes as
   "active slot"? My lean: keep gold, put category only on pill surfaces.

## Rollout

Phased, so we can ship (1) alone without waiting for naming.

- **Phase A (hours, no design system change):** swap the five labels inside
  `ActiveFireStyle.forAction(...)`. No visual change anywhere else. Low risk,
  easy revert.
- **Phase B (design + code):** add category pill component + final ability
  names into the catalog / details view. Blocks on the Narrative pass.
- **Phase C (optional):** HUD pip / color-by-category decision after first
  playtest of A+B.

## Non-risks

- No server change.
- No `active_action_type` enum migration.
- No balance implication.
- No wallet/economy coupling.
- Reversible in one commit.
