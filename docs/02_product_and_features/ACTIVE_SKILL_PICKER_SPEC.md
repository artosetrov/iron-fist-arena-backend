# Active Skill Picker — Full Spec & Implementation Plan

> Status: **Draft** · Owner: Artem · Target: Interactive Combat v1 — Phase 4
> Historical note: the exploratory `active-skills-picker-prototype.html` was removed during later repository cleanup; treat this spec plus the shipped native picker implementation as the current reference.
> Depends on: Interactive Combat v1 Phase 1, Phase 3, Phase 3.B (all shipped 2026-04-13)

## 1. Problem & Goal

### Current state (2026-04-13)
- Players equip activatable talents via **TalentDetailSheet** (one-at-a-time, per talent).
- The `+` button on an empty **ActiveSlotsBar** slot is a no-op — there is no entry point from the slot itself.
- Consumables (`health_potion_small/medium/large`) exist in the inventory schema but are **not equipable** into combat slots. They can only be used from the inventory screen outside of battle.

### Goal
Unify the "combat loadout" composition into a single sheet the player opens from the Talents tab. The sheet lets them pick **up to 3 items** for the 3 combat slots in one go, mixing talents and up to **one consumable**. The chosen loadout is what fires during `/pvp/strike`.

### Non-goals (Phase 4 scope)
- Multiple consumables per loadout — explicitly **max 1**.
- Stamina / buff / utility potions in slots — only battle-usable HP potions for this phase.
- Per-slot visual customization (hotkey label, color scheme).
- Loadout presets / multiple saved builds.

## 2. UX Flow

### Entry points
1. Tap any `+` on `ActiveSlotsBar` (Hero > Talents).
2. Tap the "ACTIVE SKILLS" label / the row area itself.
3. Tap a **filled** slot — opens the picker. **No fast-unequip-on-tap** (decided 2026-04-14). All clears happen via the preview `✕` inside the sheet. Rationale: single entry point = fewer modes to explain, no accidental unequip mid-flow.

### Sheet composition
The picker is a bottom sheet (`.sheet` / `PresentationDetent.large` in iOS) with four stacked regions:

| Region | Content | Height |
|---|---|---|
| **Header** | Title `EQUIP ACTIVE SKILLS` · counter `X of 3 selected · N of 8 unlocked` | ~64pt |
| **Loadout preview** | 3 slot tiles (64×64) showing live pending selection, order-indexed, tap = unequip | ~96pt |
| **List** | Two sticky-header sections: `Active Skills` · `Consumables` | flex |
| **Footer** | `Clear all` · `Cancel` · `Save` | 60pt + safe area |

### State & interactions
- On open, `pending` is seeded from the current committed loadout → preview shows what's already equipped.
- Tapping a list row **toggles** membership in `pending`:
  - Not selected + room available → append to `pending[]`, show badge `1/2/3` on row = position in preview.
  - Already selected → remove from `pending[]`, shift later selections left.
- When `pending.length === 3`, all other rows get `.disabled` state (opacity 0.45, `title` tooltip "Loadout full").
- When any consumable is in `pending`, all other consumable rows get `.disabled` with tooltip "Only one consumable per loadout". Talents remain toggleable.
- Tapping a filled slot in the preview unequips it (slide `✕` appears on press-down). Remaining pending items keep their order.
- **Save** is disabled unless `pending` differs from the committed `equipped`. On commit: optimistic UI, single backend call, rollback on failure (existing pattern per `feedback_optimistic_ui_everywhere.md`).
- **Cancel** / backdrop tap — discards `pending`.
- **Clear all** — empties `pending` but does NOT close. User must Save (or Cancel) to commit / discard.

### Open design decision — collapse vs null-at-index
Prototype currently **collapses** (`pending.splice(idx, 1)` shifts later items). Alternative: keep `null` at the slot index so removing "slot 2" leaves slots 1 and 3 intact.
**Recommendation:** **collapse**. Hexbound's combat resolver doesn't care about slot index semantics (each slot's `active_action_type` is read independently), and the player's mental model is "I picked 2 things" not "I picked slot 1 and slot 3". Collapse minimizes cognitive friction.

## 3. UI Spec (Design System Compliance)

### Tokens used (all from `DarkFantasyTheme`)

**Colors**
- Sheet background: `bgSecondary` (`#1A1A2E`)
- Preview host background: `bgPrimary` with top-centered `gold` radial glow @6%
- Empty preview slot border: `borderMedium` dashed 1.5
- Filled talent slot: border `gold`, glow `rgba(212,165,55,0.3)` radius 14
- Filled consumable slot: border `info` (`#3498DB`), glow `rgba(52,152,219,0.3)` radius 14
- Row selected state: background `gold @ 8%`, icon stroke `gold`
- Row disabled state: opacity 0.45
- Section header text: `textTertiary` · header hint: `textDisabled`
- Footer primary button (Save): gradient `goldBright → gold`, text `textOnGold`
- Footer ghost button (Clear all): text `textSecondary`, border `borderMedium`
- Footer secondary button (Cancel): `bgTertiary` fill, `textPrimary`

**Spacing** — `spaceXS`, `spaceSM`, `spaceMS`, `spaceMD`, `spaceLG`
**Radius** — `radiusMD` for slot tiles & buttons; sheet top corners 20pt
**Typography**
- Title: `Heading/Section` (Oswald 22) with letter-spacing 2, uppercase
- Subtitle: `Body/Caption` (Inter 12), highlight = `gold-bright`
- Section header: `Body/Badge` (Inter 11 bold, letter-spacing 2)
- Row name: `Heading/Button Label` (Oswald 18)
- Row desc: `Body/Caption` (Inter 12, line-height 1.35)
- Meta pills: Inter 10 bold, letter-spacing 0.5, uppercase
- Save button: `Heading/Button Label`

**Effects**
- Sheet top border: `borderOrnament` 1px + corner brackets ::before/::after (gold 2px, L-shape 18×18)
- Save button: `Shadow/Gold Glow` + inset white highlight + 2px bottom drop
- Modal shadow: `Shadow/Modal`

### iOS components to create / reuse

| Component | New / Reuse | File |
|---|---|---|
| `ActiveSkillPickerSheet` | **New** | `Views/Hero/Talents/ActiveSkillPickerSheet.swift` |
| `LoadoutPreviewSlot` | **New** (private to picker) | same file |
| `SkillPickerRow` | **New** (private to picker) | same file |
| `SectionHeader` (sticky-ish) | **New** foundational | `Views/Components/PickerSectionHeader.swift` |
| Button styles | **Reuse** — `.primary`, `.secondary`, `.ghost` from `ButtonStyles.swift` | — |
| Meta pills | **Reuse** — `WidgetPill` with variants `type` / `cooldown` / `consumable` | `Views/Components/WidgetPill.swift` (extend if needed) |
| Count badge (`×N`) | **New** micro-component | `Views/Components/InventoryCountBadge.swift` |

### Figma DS deliverables

Under the Hexbound-DS file (`uDjXIz7CdJxcEOI5jCBcjY`):

| Page | Component | Variants |
|---|---|---|
| **Modals & Sheets** | `Active Skill Picker Sheet` | State=WithList / Empty |
| **Badges & Pills** | `Inventory Count Badge` | Size=Sm / Md · State=Normal / Out |
| **Badges & Pills** | `Meta Pill` (extend existing) | Kind=Type / Cooldown / Consumable |
| **Cards** (or new atom page) | `Skill Picker Row` | State=Default / Selected / Equipped-elsewhere / Disabled · Kind=Talent / Consumable |
| **Cards** | `Loadout Preview Slot` | State=Empty / Talent / Consumable · Selected=No / Yes |

After creation, run the **post-creation audit** per `CLAUDE.md` FIGMA_SCREEN_RULES.md (0 hardcoded colors, 0 unstyled text, 0 fake-component frames).

Screen example goes into Hexbound-Design (`PalemJ36B97ZdC0cd8jzv4`), page `Hero / Talents`, frame `Talents — Picker Open`.

## 4. Data Model

### Schema changes — `character_active_slots`

Current (Phase 1):
```
character_active_slots(
  id, character_id, node_id NOT NULL, slot_index 0-2, equipped_at
)
UNIQUE (character_id, slot_index)
UNIQUE (character_id, node_id)
```

Required changes (migration `20260414_active_slot_consumables`):
1. `ALTER COLUMN node_id DROP NOT NULL`
2. Add `consumable_type ConsumableType NULL`
3. Add `CHECK ((node_id IS NULL) != (consumable_type IS NULL))` — exactly one set.
4. Drop existing `UNIQUE (character_id, node_id)` → recreate as **partial**: `UNIQUE (character_id, node_id) WHERE node_id IS NOT NULL`
5. Add partial unique: `UNIQUE (character_id, consumable_type) WHERE consumable_type IS NOT NULL` — prevents the same potion in two slots (though max-1 rule catches this earlier).

**Why this shape:** backward-compatible, minimal code-side branching, keeps FK integrity for talents. Rejected alternatives: polymorphic `slot_ref_id` (breaks every existing query) and separate table (duplicates join logic).

### pvp_matches — 1/battle tracking

Reuse existing `pvp_matches.interactive_actives` JSONB blob. Add two keys on fire:
- `consumable_used.player_char_id: ConsumableType`
- `consumable_used.opponent_char_id: ConsumableType`

Resolver rejects further consumable-slot fires for the same side after this key is set for this match. No schema change required.

## 5. API Changes

### `GET /api/passives/active-slots?charId=...`
Response extended:
```ts
{
  slots: Array<{
    slotIndex: 0|1|2,
    kind: 'talent' | 'consumable',
    // kind === 'talent':
    nodeId?: string,
    actionType?: TalentSlotAction,
    cooldown?: number,
    magnitude?: number,
    // kind === 'consumable':
    consumableType?: ConsumableType,
    inventoryCount?: number,  // denormalized read
    consumableEffect?: { kind: 'heal_percent', value: number }
  }>,
  maxSlots: 3
}
```
Cache key bumped to `active-slots:char:{id}:v3`.

### `POST /api/passives/active-slots/batch` (NEW)
Accepts the full 3-slot loadout atomically. Replaces current per-slot `POST`/`DELETE` when user hits Save.
```ts
Request: {
  charId: string,
  slots: Array<
    | { slotIndex: 0|1|2, kind: 'talent', nodeId: string }
    | { slotIndex: 0|1|2, kind: 'consumable', consumableType: ConsumableType }
    | { slotIndex: 0|1|2, kind: 'empty' }
  >
}
Response: { ok: true, slots: [...same as GET] }
```

**Validation (server-authoritative per CLAUDE.md §Architecture):**
1. `slots.length <= 3`, `slotIndex` unique and in `{0,1,2}`.
2. For `talent`: node is `is_activatable=true`, unlocked for this character, class matches.
3. For `consumable`: must be in **allowed list** (see §7 Balance), player owns ≥1 in inventory *at equip time* (not deducted yet).
4. At most **one** `kind === 'consumable'` across all slots.
5. All-or-nothing: transaction rollback on any failure. Cache invalidated once on success.

Old endpoints `/active-slots` POST and DELETE remain for backward compat but iOS picker uses batch.

### `POST /pvp/strike` — consumable firing

Client passes `pending_active_slot: 0|1|2|null` as today. Resolver now:
1. Look up slot → if `consumable_type` set:
   - If `match.interactive_actives.consumable_used[attackerId]` already set → return 400 `CONSUMABLE_ALREADY_USED`.
   - If `character_inventory.count_by_type(consumableType) === 0` → return 400 `CONSUMABLE_EMPTY`.
   - Apply heal: `attacker.hp = min(maxHp, hp + round(maxHp * effect.value))`.
   - Deduct 1 from inventory (transactional, same as current consumable-use endpoint).
   - Write `consumable_used[attackerId] = consumableType` into `interactive_actives`.
2. Response extends:
   ```ts
   {
     ...existing,
     consumable_fired?: { type: ConsumableType, heal: number, remaining: number }
   }
   ```

**Opponent AI** — `pickOpponentActive` extended:
- If opp has consumable-slot AND opp HP% ≤ 35% AND consumable not yet used → fire it **before** picking a talent action.
- Otherwise fall through to existing priority (execute > burst > heal_self > shield_self > stun).

## 6. Combat Integration

### iOS — `InteractiveBattleViewModel`
- `InteractiveStrikeResponse` gains `consumableFired: ConsumableFireInfo?`.
- New banner style in `ActiveSkillsHUD.swift`: `ConsumableFireBanner` — cyan tint (`info`) instead of gold, icon = consumable's `icon`, label e.g. `"Health Potion — +480 HP"`.
- After fire, slot tile grays out with "Used" overlay (consumable is spent for this match).
- `×N` count on the slot decrements optimistically; rolls back if server returned `CONSUMABLE_ALREADY_USED` (shouldn't happen if client state is fresh).

### Combat HUD cooldown row
- Talent slots: keep existing cooldown pill (rounds remaining).
- Consumable slot: no cooldown — show `1/1` charge, and after fire `0/1` + grayed-out overlay (can't fire again this match even if inventory still has charges).

## 7. Balance & Economy

### Allowed consumables in slots (Phase 4 scope)
Only battle-usable heals. **Values read from `items` table seed `20260320_seed_consumable_items` + fix `20260409_fix_consumable_special_effects` — NOT re-proposed by this spec:**

| ConsumableType | Rarity | Heal (% max HP) | Shop price | Inventory source |
|---|---|---|---|---|
| `health_potion_small` | common | **25%** | **150 gold** | Shop · random drops |
| `health_potion_medium` | uncommon | **50%** | **350 gold** | Shop · dungeon drops |
| `health_potion_large` | rare | **100% (full)** | **700 gold** | Shop · boss drops |

Source of truth: `items.buy_price` and `items.description`/`special_effect` columns.

Stamina potions, protection_scroll, legendary_shard — **NOT** equipable in slots (non-combat items).

**All three are gold-only.** No gem-priced or IAP-exclusive HP potion exists → this feature is structurally free of P2W concerns. Any future gem/IAP-priced HP potion requires a separate review before being allow-listed here.

### Pricing & caps

No daily caps currently exist on potion purchases — not introducing them with this feature unless telemetry forces it (§9). Shop `buy_price` is the live source.

**If telemetry shows abuse** (e.g. whales buying 50 large potions a day to brute-force ladder climbs), the Phase 5 fix is a per-character daily cap on `health_potion_large` purchases (proposal: 5/day). Not shipping with Phase 4.

### Expected frequency of use
Target numbers per 100 ranked PvP matches for a mid-tier player:
- `small` equipped in ~40% of loadouts, fired in ~60% of those = **24 fires / 100**.
- `medium` in ~30% of loadouts, fired in ~70% = **21 fires / 100**.
- `large` in ~10% of loadouts, fired in ~85% = **9 fires / 100**.

Total consumable fires **~54% of matches** — meaningful, not a potion-duel every match.

### Economy impact
Gold-sink projection for average player:
- ~2 × small + 1 × medium + 0.3 × large per week ≈ **860 gold / week** new drain per active PvP player.
- Expected **+6–10% weekly gold sink** across the PvP-active cohort. Not huge — mostly reinforces existing potion purchase behavior rather than creating new demand.

### Inline "Buy" CTA (picker UX for empty inventory)

When a player opens the picker and a whitelisted potion has `inventoryCount === 0`, the row is **not hidden**. Instead it renders a "Buy" variant:

```
🧪  Small Health Potion              ┌─ 150g ─┐   ┌──────┐
    Restores 25% of your max HP      │  Buy   │   │  ○   │  (disabled check)
    CONSUMABLE · 1/BATTLE            └────────┘   └──────┘
```

- **Tap "Buy" CTA** → inline purchase (one API call to `/shop/buy`, same path as Shop screen). On success: row becomes selectable, `×1` count appears, user can now toggle it into a slot without leaving the picker.
- **Affordability check** — if `player.gold < price`, CTA shows `150g` with gold icon in `textDisabled` and is non-interactive; tap → toast "Not enough gold — earn from PvP or dungeons".
- **No confirmation modal** for ≤ 700g purchases — matches Shop's quick-buy pattern. Over 700g → standard shop confirm dialog (future-proof; N/A for current whitelist).
- **Analytics event**: `consumable_inline_purchase { type, price, source: 'picker' }` — separate from regular shop buys so we can see conversion lift.

Rationale: removing the context switch ("go to Shop, buy, come back") is a measurable conversion boost for consumable attach rate, while the 1/battle rule still caps combat impact.

### Interaction with existing systems
- `quests.consumable_use` QuestType — **already counts** when a consumable is used from inventory. Resolver should emit the same quest event when firing from a slot → reuse existing `consumable-use` internal helper.
- `achievements.progression` — none directly tied. Consider adding Phase 5: "Drink 100 potions in PvP" → progression achievement.
- `arena_rewards` — no change. Ratings/ELO unaffected.

## 8. Implementation Plan

### Phase 4.A — Backend foundation (2–3 days)
1. **Migration** `20260414_active_slot_consumables` — apply via **Supabase MCP `apply_migration` to prod BEFORE code deploy** per `feedback_migration_mcp_apply_to_prod.md`.
2. **Prisma schema** — update `CharacterActiveSlot`, regen client, copy schema to `admin/prisma/schema.prisma`.
3. **New endpoint** `/api/passives/active-slots/batch` — validation rules per §5. Unit tests for all 5 validation cases.
4. **Existing endpoints** — mark POST/DELETE deprecated (keep working), bump cache key `v3`.
5. **`check_schema_drift.py`** must pass before pushing.

### Phase 4.B — Resolver extension (1–2 days)
1. Extend `/pvp/strike` to handle consumable-slot fire (check match-level flag, deduct inventory, apply heal, write `consumable_used` key).
2. Extend `pickOpponentActive` priority logic.
3. Add error codes `CONSUMABLE_ALREADY_USED`, `CONSUMABLE_EMPTY`.
4. Unit test: concurrency — two simultaneous strike calls don't both fire the potion. (Wrap inventory deduct + flag write in single transaction.)

### Phase 4.C — iOS UI (3–4 days)
1. Create `ActiveSkillPickerSheet.swift` per §3 spec.
   - `@Bindable var vm: PassiveTreeViewModel` + local `@State var pending: [PendingSlot]`.
   - Preview slots + 2-section list + footer.
   - Collapse-on-remove semantics.
2. Extend `PassiveTreeViewModel`:
   - `var availableConsumables: [ConsumableEntry]` — derived from `InventoryViewModel` for 3 whitelisted HP potion types only.
   - `func saveLoadout(_ slots: [PendingSlot])` — optimistic update + batch POST + rollback.
3. Wire `ActiveSlotsBar` — tap any slot (empty or filled) opens `ActiveSkillPickerSheet`. Remove the current fast-clear-on-tap (use preview `✕` instead).
4. Extend `InteractiveStrikeResponse` + HUD banner (`ConsumableFireBanner`).
5. Register new file in `pbxproj` (4 sections per `CLAUDE.md` §Xcode Project File).

### Phase 4.D — Figma DS (1 day, parallel with 4.C)
1. Invoke `cc-figma-component` skill for each component listed in §3 (Skill Picker Row, Loadout Preview Slot, Inventory Count Badge, extend Meta Pill, Active Skill Picker Sheet).
2. Run post-creation audit per `CLAUDE.md` FIGMA_SCREEN_RULES.md §7.
3. Build screen `Talents — Picker Open` on Hexbound-Design.

### Phase 4.E — QA & polish (1 day)
1. Manual playtest matrix:
   - Equip 3 talents, fire in order.
   - Equip 2 talents + 1 consumable, fire consumable first, fire talent after.
   - Opponent fires consumable first — verify heal applies before counter-strike.
   - Inventory runs out mid-match — verify slot shows `×0` + grayed.
   - Optimistic save + rollback when server errors.
2. Run `hexbound-swift-review`, `hexbound-backend-review`, `hexbound-ux-audit`, `hexbound-preflight` agents.
3. CDO scan per `CLAUDE.md` §CDO Verification.

### Phase 4.F — Ship (0.5 day)
1. `scripts/check_schema_drift.py` → 0.
2. Backend push to `origin main` → Vercel deploys.
3. `git subtree push admin-deploy` (admin schema updated).
4. iOS TestFlight build.
5. Post-deploy: verify `character_active_slots` column shape in prod, smoke-test one PvP match with each consumable type.

### Total: ~7–10 working days

## 9. Telemetry / Success Metrics

Events to emit (via existing analytics pipeline):
- `loadout_saved` — props: `{ slot_count, has_consumable, consumable_type?, talent_node_ids[] }`
- `consumable_fired_pvp` — props: `{ consumable_type, heal_amount, player_hp_before, player_hp_after, match_id }`
- `loadout_composition_churn` — session-level count of times the picker was opened and Save was clicked.

Success criteria (30-day window post-launch):
- ≥60% of ranked PvP players save at least one loadout with a consumable.
- Consumable fire rate per match lands in **45–65%** band (per §7 estimate).
- Ranked PvP match length **does not decrease** by more than 10% (big heals shouldn't collapse pacing).
- Gold sink via HP potion purchases rises ≥8% vs pre-launch baseline.

If fire rate >75% → potions too strong or too cheap → halve daily cap or drop heal % by 5pt.
If fire rate <30% → potions too weak or too scarce → raise heal % by 5pt or lower price 20%.

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Migration drift (schema vs prod) | **Med** — 3rd repeat in project history | High — prod 500s | Apply via Supabase MCP before code deploy. Run `check_schema_drift.py` before push. |
| Optimistic save race — user taps Save twice | Low | Low — backend dedup by `pending_active_slot` | `isMutating` flag on VM disables footer buttons mid-request. |
| AI fires consumable poorly — always uses large at 60% HP | Med | Med — feels dumb | Threshold tuning in `pickOpponentActive`: only fire if HP% ≤ 35 OR next-incoming-damage estimate > current HP. |
| Economy inflation — potions too cheap | Med | Med — trivializes combat | Daily cap + post-launch telemetry fire rate → tune after 14 days. |
| Pay-to-win perception | Low | High if vocal | `large` is hard-capped to 2/day in shop, and one-per-match rule prevents stacking. Messaging: `large` is for emergency, not advantage. |
| "1 per battle" gotcha — player confused why second fire blocked | Med | Low | Slot shows "Used" overlay after fire. Toast: "Only one consumable per battle". |

## 11. Open Questions (decide before Phase 4.A)

### Resolved (2026-04-14)
- ✅ **Entry points** — picker is the sole surface. No fast-unequip-on-tap. All clears go through preview `✕`.
- ✅ **Heal % values** — aligned to DB (`items.special_effect` + shop prices): 25% / 50% / 100% → 150 / 350 / 700 gold. No PvP-specific override.
- ✅ **Inline Buy CTA** — yes, ship in Phase 4 with shop pricing (see §7 "Inline Buy CTA").

### Still open
1. **Collapse vs null-at-index** — recommendation is **collapse** per §2; Artem to sign off before Phase 4.A.
2. **Preset builds / multiple loadouts** — out of scope for Phase 4. Track as Phase 5+.

## 12. References

- Historical prototype: removed later during repository cleanup; use this spec and the shipped native picker flow as the retained reference
- Phase 1 shipped: `auto-memory/project_interactive_combat_phase1.md`
- Phase 3.B shipped: `auto-memory/project_interactive_combat_phase3b_shipped.md`
- Migration safety: `auto-memory/feedback_migration_mcp_apply_to_prod.md`
- Schema drift checker: `scripts/check_schema_drift.py`
- Figma rules: `docs/07_ui_ux/FIGMA_SCREEN_RULES.md`
- Current `ActiveSlotsBar`: `Hexbound/Hexbound/Views/Hero/Talents/ActiveSlotsBar.swift`
- Current native picker: `Hexbound/Hexbound/Views/Hero/Talents/ActiveSkillPickerSheet.swift`
