# Combat Screen — UX Audit & Prototype Proposals

> **Status:** Historical discovery / proposal. Superseded by the B2/B2-v3 direction; keep for rationale and alternatives.
> **Author:** Claude (orchestrator)
> **Date:** 2026-04-14
> **Scope:** Interactive Combat v1 fight screen (Phase 3.B shipped). Not dungeon PvE combat.

---

## 1. Problems Artem flagged

| # | Problem | Severity |
|---|---|---|
| P1 | Selected stance is echoed both in the top 2×2 readout **and** in the bottom picker — duplicate info, user reads twice. | High |
| P2 | YOU/FOE stance rows are laid out **horizontally** next to each other — ownership of each cell is not obvious at a glance. | High |
| P3 | Timer progress bar lives far away from STRIKE — the player races a clock at the top while the button they must press is at the bottom. | High |
| P4 | STRIKE is on the **left**. iOS primary actions sit on the right, and the right half is the thumb's rest zone. | Medium |
| P5 | No dedicated space for **active talents** (Phase 3.B wired the backend, iOS HUD has one strip — but it's visually disconnected from the decision surface). | High |

## 2. Additional heuristic findings (Claude)

| # | Problem | Severity | Why it matters |
|---|---|---|---|
| H1 | HP numbers are tiny red text **above** the bar. Red = damage code, but here it just means "current HP". | Medium | Scans as "I'm hurt" even at full HP. Use `textPrimary` / `gold`. |
| H2 | Enemy intent is a flat "?" — no telegraph, no prior-round memory. | High | Turn-based stance games (Shadow Fight, For Honor) rely on *reading* the opponent. "?" is a black box. |
| H3 | STRIKE and SKIP are visually almost equal. | High | Primary/secondary hierarchy violated (Nielsen #6 recognition). |
| H4 | "Finalizing…" screen is dead air — no damage animation, no feedback. | Medium | Perceived latency feels worse when nothing is happening. |
| H5 | Attack / Defend readout boxes waste vertical space on micro-labels. | Low | Dense screen, real estate is precious. |
| H6 | No persistent **momentum/streak** indicator (wins in a row, HP diff). | Low | Missed opportunity for meta-tension. |
| H7 | No access to consumables (HP potion) during the fight. | Medium | Phase 3.B only wires talent actives. Potions are a retention lever. |
| H8 | YOU vs ENEMY is communicated by tiny green/red label + border color only. | Medium | Border is thin, color-only signal fails WCAG; position should reinforce. |

## 3. Competitor research — how others solve turn-based fight UI

| Game | Turn model | Ownership | Timer placement | Actives | Takeaway for Hexbound |
|---|---|---|---|---|---|
| **Shadow Fight 3/4** | Real-time + commits | Both fighters side view, you always on left | Round timer top | Special icons bottom hotbar w/ cooldown fill | Cooldown as **radial fill** on the icon is instantly readable |
| **For Honor** | Stance mindgame | First-person-ish, enemy's stance visible as 3-arrow indicator | No clock | N/A | **Telegraphed enemy intent** is the whole game — Hexbound's "?" leaves the mindgame on the table |
| **Raid: Shadow Legends** | Turn-based | Party bottom, enemies top | Turn meter | 4-slot ability bar, each with cooldown number | Bottom hotbar of actives next to tap zone is standard |
| **Marvel Snap** | Simultaneous reveal | You bottom, enemy top | Integrated — **timer pulses around the "End Turn" button** | N/A | Timer + primary CTA as a **single object** is the gold standard |
| **Clash Royale** | Real-time | You bottom, enemy top | Elixir bar = resource | 4-card hotbar bottom | Bottom-third is the player's world, top-third is the enemy's |
| **HS Battlegrounds** | Phase-based | Your board bottom | Turn timer as arc around "Ready" gem | Hero power as icon | Again: **arc timer around the primary CTA** |
| **Honkai: Star Rail** | Turn-based | Enemies top, party bottom | Action order bar left | Ultimate icons bottom | Spatial separation: top = them, bottom = you, center = action |

**Three patterns repeat:**

1. **Vertical ownership:** enemy top, you bottom. Never side-by-side when the player has to *act* quickly — the brain needs unambiguous "mine / theirs".
2. **Timer fused with primary CTA:** either a radial arc, a fill, or a pulsing border on the button you're racing to press.
3. **Active abilities in a hotbar adjacent to the tap zone** with radial cooldown fill.

## 4. Information Architecture — what the player needs, when

| Moment | What player must see | Current gap |
|---|---|---|
| **T₀ — Round opens** | Both HP. My stance (empty). Enemy intent hint (based on last round / class). Timer starting. Actives available. | No intent hint. Actives visually disconnected. |
| **T₁ — Picking** | My Attack pick confirmed. My Defend pick confirmed. Time remaining *visually urgent*. | Picks echo in two places (P1). Timer is far from action (P3). |
| **T₂ — Commit window** | STRIKE ready. SKIP as safety valve. Actives still usable. | STRIKE hierarchy weak (H3). |
| **T₃ — Resolving** | Reveal enemy stance. Damage numbers. HP anim. Active trigger banner. | Blank "Finalizing…" (H4). |
| **T₄ — Breath (~0.8s)** | Status tick. Next-round indicator. Streak update. | No streak shown (H6). |

## 5. Accessibility / readability pass (WCAG 2.1 AA, game-UX lens)

| Check | Status | Fix |
|---|---|---|
| Touch targets ≥ 44pt | ✅ Stance buttons ~60pt | — |
| Primary CTA in thumb zone | ⚠️ STRIKE on left — right-thumb users reach across | Move to right (P4) |
| HP numbers contrast | ⚠️ `#E63946` on `#0D0D14` ~6:1 — passes AA-Large but semantically wrong | Use `textPrimary` or `gold` |
| Color-only ownership cue | ❌ Tiny "YOU"/"ENEMY" labels + border color | Add position (vertical layout) + icon |
| Motion-reduced users | ❌ No `prefers-reduced-motion` handling | Respect in finalizing spinner |
| Timer urgency for color-blind | ✅ Gold→red transition **and** numeric countdown | — |
| One-hand play | ⚠️ Everything reachable, but STRIKE on left forces cross-hand | Right-align primary |

## 6. Three prototype proposals

All three fix **P1–P5** and **H1–H3**. They diverge on *how* actives and telegraphs are expressed.

### Variant A — **"Marvel Snap" vertical**
- Enemy fighter collapsed to a **top strip** (portrait + HP + intent telegraph).
- You in the bottom strip (portrait + HP + streak).
- Stance picker in center — one row of 3 Attack zones, one row of 3 Defend zones, nothing duplicated.
- **STRIKE fills with the timer as it elapses** (progress = button background fill). Right side.
- **2 active talents** docked left of STRIKE as circular icons with radial cooldown.
- SKIP as a ghost text button top-right of the picker (de-emphasized).
- Best for: clarity, first-timers, one-hand play.

### Variant B — **"Shadow Fight" hotbar**
- Keeps the side-by-side portrait layout (Artem's visual identity).
- Removes the duplicate 2×2 stance readout. Picks are shown as **glowing zones on each portrait's silhouette** (attack = gold flash on target body part, defend = shield overlay).
- Enemy shows an **intent hint** — a semi-transparent ghost arrow on their portrait based on class tendency.
- Bottom bar: **3-slot active hotbar** on the left, **STRIKE button on the right with a radial timer arc** around it.
- SKIP is a small icon button above STRIKE.
- Best for: keeping current aesthetic, maximum tactical depth.

### Variant C — **"Stance silhouette"**
- One shared full-body silhouette in the center — tap a body part to choose Attack zone (flashes gold), tap again to choose Defend zone (flashes blue). No duplicate boxes.
- Opponent shown smaller top-right, their intent as ghost arrows on the same silhouette you're picking on.
- Bottom bar: 2 actives + STRIKE (right, large, timer fill) + SKIP (small ghost, top-right of bar).
- Most space-efficient, most readable. Higher design risk — unfamiliar.
- Best for: long-term vision, most novel.

## 7. Recommendation

Start with **Variant A** as the safest upgrade — it resolves every flagged problem, keeps the existing portrait assets, and its pattern (Snap / HS / Raid) is battle-tested. **Variant B** is my close second if preserving the current two-portrait composition is a priority. **Variant C** is an ambitious bet worth a round of playtest before committing.

After you pick a direction, I'll produce a Figma screen in `Hexbound-Design` (fileKey `PalemJ36B97ZdC0cd8jzv4`) using only DS components, then we plan the Swift implementation.

## 8. Files

- Variant A — Vertical / integrated STRIKE *(historical HTML prototype removed during later repository cleanup)*
- Variant B — Hotbar + side portraits *(historical HTML prototype removed during later repository cleanup)*
- Variant C — Stance silhouette *(historical HTML prototype removed during later repository cleanup)*
- Side-by-side comparison launcher *(historical HTML prototype removed during later repository cleanup)*
