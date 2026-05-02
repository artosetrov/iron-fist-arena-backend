# Talent Detail Modal — Redesign Report
**Date:** 2026-05-01
**Owner:** Artem
**Status:** Awaiting approval before implementation
**Related:** `Hexbound/Views/Hero/Talents/TalentDetailSheet.swift`, `TalentsTabView.swift`, `backend/prisma/schema.prisma` (PassiveNode), `backend/prisma/seeds/passives-tank-v2.sql`

---

## 1. Problem

Current Talent Detail modal (Talents tab → tap node):

1. Opens via `.sheet(...).presentationDetents([.medium])` — fixed at ~50% of screen, regardless of content. Result: large empty area below the LOCKED pill (see screenshot 2026-05-01).
2. No prose description of what the talent actually does. Field `PassiveNode.description` currently stores a stat-effect string (e.g. `"+5%/+10%/+15% Damage"`), not narrative copy. Bonus row with sparkles icon does not render at all because Tank-class nodes have `bonusStat = NULL` (proxy bonuses, see `passives-tank-v2.sql` header).

## 2. Proposed Solution

### 2.1 Data model change

Add a new optional column `flavor` to `PassiveNode`. Keep `description` as the stat-effect line.

```prisma
model PassiveNode {
  // ... existing fields
  description String?  // stat-effect line, e.g. "+5%/+10%/+15% Damage"
  flavor      String?  // NEW: narrative prose, 1–2 sentences
  // ... rest unchanged
}
```

iOS DTO mirrors:
```swift
struct PassiveNode {
    let description: String   // existing — non-optional on iOS
    let flavor: String?       // NEW — optional, forward-compat with old backends
}
```

### 2.2 Visual layout (see prototype above)

Order inside the card:
1. Header — icon + tier label + name + close ×.
2. **Effect chip** — sparkles icon + `description` text on bgTertiary chip with subtle border. Always rendered (drop the legacy `bonusStat`-derived bonus row entirely; `description` is the canonical effect string).
3. **Flavor line** — italic serif body text (`DarkFantasyTheme.body` italic, color `textTertiary`). Rendered only when `node.flavor != nil`. 1–2 sentences max.
4. Rank ladder (when `isRanked`).
5. Divider.
6. CTA (LOCKED / UNLOCK / RANK UP / etc).
7. Active slot CTA (when activatable + unlocked).

### 2.3 Presentation change (sheet → overlay-card)

Replace `.sheet(item: ...).presentationDetents([.medium])` with an in-tree ZStack overlay:

```swift
// In TalentsTabView body, replace the .sheet modifier with:
.overlay {
    if let node = vm.selectedNode {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { vm.selectedNode = nil }
                .transition(.opacity)

            TalentDetailSheet(node: node, /* ... */ )
                .padding(.horizontal, LayoutConstants.spaceLG)
                .frame(maxWidth: 420)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
        .animation(.easeOut(duration: 0.2), value: vm.selectedNode?.id)
    }
}
```

Result: card hugs content vertically, dim backdrop, tap-out dismisses, close × still works. Per `feedback_no_scale_animations.md` — opacity-only enter/exit is acceptable; if scale is forbidden by that rule, drop the `.scale` and use plain `.opacity`. **Flag for confirmation.**

### 2.4 Why this approach

| Concern | Sheet+detents | Overlay-card |
|---------|---------------|--------------|
| Hugs content | Needs measured `.height(...)` per-node; fragile | Native — `.fixedSize(vertical:)` does it |
| Dismiss UX | Drag handle + swipe down | Backdrop tap + close × |
| Animation control | iOS-managed | Project-managed, fits no-scale rule |
| Stack with other sheets | Conflicts with Active Skill Picker `.sheet` | Lives in ZStack overlay layer above tree |

The ActiveSkillPicker still uses `.sheet` → no collision, since both are gated by separate VM state.

---

## 3. Tank Tree Flavor Drafts (20 nodes)

Voice: dark-fantasy, second-person, lean. 1–2 short sentences. Hints at the proxy semantics noted in the seed file (so a player who reads carefully picks up *why* this stat exists — e.g. why Rebuke says "Damage" but feels like threat).

### Foundation (tier 1)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.found.stoneform` | Stoneform | +5/10/15% Max HP | Stand like the mountain. Each rank thickens flesh into bedrock — harder to chip, harder to break. |
| `tank.found.plate` | Plate | +3/6/9 Armor | Forged steel between your skin and the world. Reduces incoming physical bite. |
| `tank.found.resilience` | Resilience | +2/4/6% DR | You learn where blades land. Every wound teaches; every scar shaves a little off the next one. |
| `tank.found.rebuke` | Rebuke | +5/10/15% Damage *(threat)* | A challenge in every swing. Your strikes pull the enemy's eyes — and their wrath — away from your allies. |
| `tank.found.stability` | Stability | +5/10/15% DR *(CC resist)* | Roots run deep. Hexes, stuns, and shoves slip off you like rain off a battlement. |
| `tank.found.vigor` | Vigor | +3/6/9% Lifesteal *(HP regen)* | The body that endures, mends. A slow tide of strength returns with every passing breath. |

### Protector lane (tier 2 — offense)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.prot.cleave` | Cleave | +5/10/15% Damage | One swing carves through more than one foe. The blade keeps moving until the line breaks. |
| `tank.prot.challenge` | Challenge | +3/6/9% Crit Chance *(vs highest-HP)* | Mark the strongest, then strike for the seam. The bigger they are, the better you read them. |
| `tank.prot.retaliation` | Retaliation | +5/10/15% Damage *(after being hit)* | Every blow you take is loaned. The next swing of yours lands with the weight of every wound. |

### Warden lane (tier 2 — balance)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.ward.shield` | Shield | +5/10/15% Damage *(shield-bash)* | The shield is not just a wall. Slammed forward, its rim is a hammer; its boss, a club. |
| `tank.ward.reflect` | Reflect | +3/6/9% DR *(reflect)* | Hatred is contagious. A measure of every blade brought against you finds its way back to its master. |
| `tank.ward.absolution` | Absolution | +10/20/30% Lifesteal *(heal on block)* | Hold the line, and the line holds you. Each blow you turn aside knits the flesh beneath the steel. |

### Juggernaut lane (tier 2 — defense)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.jug.fortify` | Fortify | +3/6/9% DR | Brace, breathe, refuse to fall. Your stance grows wider, your guard heavier. |
| `tank.jug.immovable` | Immovable | +10/20/30% DR *(CC duration)* | The earth does not flinch. Stuns, fears, and chains slip their hold on you sooner. |
| `tank.jug.unbreakable` | Unbreakable | +10/20/30% Lifesteal *(regen <30%)* | Wounded beasts are the most dangerous. The closer to the edge, the harder you claw your way back. |

### Keystones (tier 3, single-rank)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.key.taunt` | Taunt | +15% Damage (AoE taunt 10s) | You scream the warband's name and a dozen heads turn. None will turn away while you still stand. |
| `tank.key.aegis_wall` | Aegis Wall | +15% DR (active shield) | Plant the shield, raise the wall. For a moment, nothing passes through you that you do not allow. |
| `tank.key.unstoppable` | Unstoppable | +15% DR (CC immune <50%) | Past a certain point, pain stops mattering. Below half-blood, no chain holds, no spell binds. |

### Ultimates (tier 4, single-rank, activatable)

| Key | Name | Effect | Flavor |
|-----|------|--------|--------|
| `tank.ult.fortress` | Fortress | +25% Max HP, Active: Bastion | You are not a soldier. You are the wall the enemy breaks against. Bastion layers your hide in absorbing stone. |
| `tank.ult.earthshatter` | Earthshatter | +30% Damage, Active: Quake | Strike the ground hard enough and the world remembers it. Quake sunders the field beneath every foe. |

---

## 4. Implementation Plan

Order matters — migration before code deploy (per `feedback_migration_mcp_apply_to_prod.md`, `feedback_prisma_schema_without_migration.md`).

### Phase A — Schema + data (backend)
1. Create migration `backend/prisma/migrations/20260501_passive_node_flavor/migration.sql`:
   ```sql
   ALTER TABLE "passive_nodes" ADD COLUMN "flavor" TEXT;
   ```
2. Apply via Supabase MCP `apply_migration` to **prod** before any code merge.
3. Update `backend/prisma/schema.prisma` PassiveNode model (`flavor String?`).
4. Sync to `admin/prisma/schema.prisma` (per CLAUDE.md root rule).
5. Run `python3 scripts/check_schema_drift.py`.
6. Update `passives-tank-v2.sql` — add `flavor` column to INSERT, populate all 20 rows from the table above. Re-run seed against prod.

### Phase B — API
7. Audit `getPassiveTree` / wherever PassiveNode is serialized — confirm Prisma auto-includes `flavor`. No explicit `select` filter is dropping it.
8. Smoke test: `GET /api/passive-tree?class=tank` → response includes `flavor` for Retaliation.

### Phase C — iOS model
9. Add `let flavor: String?` to `Hexbound/Models/PassiveTree.swift` PassiveNode struct.
10. Decode test (existing decoder is plain Codable — adding optional doesn't break older payloads).

### Phase D — iOS view
11. `TalentDetailSheet.swift`:
    - Always render description as the bonus chip (drop `bonusText` computation that depended on `bonusStat`).
    - Add `flavorLine` view, render only if `node.flavor != nil`.
    - Order: header → effect chip → flavor line → rank ladder (if ranked) → divider → CTA → active CTA.
12. `TalentsTabView.swift`:
    - Replace `.sheet(item: sheetBinding()) { node in ... }` with `.overlay { ... }` ZStack as in §2.3.
    - Confirm interaction with existing `.sheet(isPresented: $vm.showActiveSkillPicker)` — they're independent.

### Phase E — Figma DS sync (per `feedback_sync_figma_swift_always.md`)
13. Update `Hexbound-DS` Figma file — add new "TalentDetailModal" component variant (overlay-card) using DS tokens. Match new layout.
14. Document in `docs/07_ui_ux/DESIGN_SYSTEM.md` if a new pattern is added (modal-overlay vs sheet).

### Phase F — pbxproj + ship
15. No new .swift files → pbxproj untouched.
16. Run `gatekeeper` agent preflight.
17. Deploy via `.git-trigger` (per `feedback_deploy_via_tmp_clone.md`). Backend first, then iOS build.

### Phase G — verification
18. Verify on prod simulator: tap each Tank talent, confirm flavor renders, modal sizes to content, backdrop tap dismisses.
19. Verify non-Tank classes (Warrior/Mage/Rogue) — `flavor = NULL` → modal renders without flavor line, no layout collapse.

---

## 5. Risks / Open Questions

1. **No-scale-animation rule** — the prototype suggests a small `.scale(0.96)` enter transition. If `feedback_no_scale_animations.md` covers ALL views (not just buttons/cards), drop scale and use opacity-only. **Need confirmation.**
2. **Other classes** — Warrior/Mage/Rogue currently have no v2 seeds (per `feedback_no_rotting_scaffolds.md`?). If their nodes exist with `flavor = NULL`, modal should render gracefully. Drafting their flavor is out of scope here.
3. **Bonus-row removal** — dropping the `bonusText`-from-`bonusStat` computation makes the `bonusStat`/`bonusValue` fields inert in the modal. They're still used elsewhere (TalentNodeView icons?). Need to confirm before deleting the helper. Safe path: leave the helper, just stop calling it.
4. **Length budget** — the flavor lines above are 1–2 sentences (~120 chars max). Keystones with longer effect strings could clip on iPhone SE width. Will visually QA on small device.

---

## 6. Approval Checklist

Reply OK or with edits on each:

- [ ] Field name `flavor` (vs `effectText` / `loreText` / something else)
- [ ] Visual layout per prototype (effect chip → flavor → ladder)
- [ ] Overlay-card vs sheet-with-measured-height
- [ ] Tank flavor copy — any rewrites/tone changes
- [ ] No-scale-animation interpretation (drop scale entirely?)
- [ ] Phase ordering — migration-first via Supabase MCP, then code

Once OK on all six, I run Phase A → G.
