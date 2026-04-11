# Gold Mine Mini-game — Balance Audit

**Status:** Phase 1 LOCKED (Variant D — Pick-a-Shaft + Expedition Progress)
**Date:** 2026-04-11
**Owner:** CDO / Vault / Heartbeat / Ledger / Psyche / Ascent
**Reference:** `docs/06_game_systems/BALANCE_CONSTANTS.md`, `backend/src/lib/game/gold-mine.ts`, `Hexbound/Hexbound/Views/Minigames/GoldMineViewModel.swift`, `GOLD_MINE_MINIGAME_PLAN.md`

---

## 1. TL;DR

A skill-based 15-second mini-game awards **up to $+14.8\%$ gold** and **0–1 gem per session**, with a hard server-side cap. Maximum daily upside for a fully-optimizing top player: **$+186$ gold/day** and **$+6$ gems/day**. This is **less** than a single PvP win (150 gold) and **less** than the gap between "I collect lazily every 8 h" and "I collect every 4 h". Economic risk is minimal; the primary upside is engagement and short-term retention.

Variant D adds an **expedition meta-loop** on top: the player commits to one shaft per 5 Collect Alls, the Gold Mine screen shows an expedition progress bar, and the picker reopens on shaft clear. **The meta-loop does not change any EV calculations** — it changes shape (commitment, variety, closure), not magnitude (gold, gems).

**Verdict:** Ship Phase 1. Gem velocity requires live-market monitoring; everything else is safe.

---

## 2. Baseline — Real Economy v2 Numbers

Source: `docs/06_game_systems/BALANCE_CONSTANTS.md` + `GoldMineViewModel.swift`.

| Metric | Value |
|---|---|
| Gold per slot per 4h session | 40–100 (avg **70**) |
| Sessions per day per slot (4h cycle) | 6 |
| Gold/day/slot | 420 |
| Max slots (no purchases) | 3 |
| Gold/day all 3 slots | **1 260** |
| Gem chance per session | $10\%$ → 1–3 gems (avg 2) |
| Gems/day baseline ($3 \times 6 \times 0.1 \times 2$) | **3.6** |
| PvP gold win (lvl 1) | 150 |
| PvP gold loss (lvl 1) | 50 |
| Stamina regen | $1/8$ min $\to 7.5/$h $\to 180/$day max |
| PvP/day max (180 stamina / 10 cost) | 18 fights |
| PvP gold/day at $100\%$ wins | $18 \times 150 = $ **2 700** |

**Key observation:** in Economy v2, PvP is already $\sim 2\times$ more productive than Gold Mine. The "passive outpaces active" concern was already resolved before this feature. Gold Mine is a secondary, lazy source; the mini-game exists to turn the routine "tap Collect" moment into an emotional micro-beat, not to rebalance the economy.

---

## 3. Mini-game Design Parameters (Phase 1)

| Parameter | Value | Rationale |
|---|---|---|
| Session duration | 15 s | Hamster Kombat / Notcoin 5–15 s sweet spot |
| Trigger | $1\times$ per **Collect All** (not per slot) | Reduces collect spam from 3 to 1 |
| Passive pool ($G_p$) | 210 gold (sum across 3 slots) | Mirrors backend `claimAllSlots()` |
| Bonus cap | $c = \lfloor 0.15 \cdot G_p \rfloor = 31$ gold | Upper bound of $+15\%$ |
| Gem cap per session | 1 gem | Gem velocity guard |
| Expected spawns per session | 26 | Ramped interval $700 \to 350$ ms |

**Drop table:**

| Drop | Weight | Gold | Gems | $E[\text{gold}]$ per spawn | $E[\text{gems}]$ per spawn |
|---|---|---|---|---|---|
| coin | $76\%$ | +1 | 0 | 0.76 | 0 |
| bag  | $20\%$ | +3 | 0 | 0.60 | 0 |
| gem  | $4\%$  | 0  | +1 | 0 | 0.04 |
| **Σ** | $100\%$ | | | **1.36** | **0.04** |

Expected value for a "perfect" session ($s = 1.0$, 26 spawns):
$$E[\text{gold} \mid s = 1] = 26 \cdot 1.36 = 35.4$$
$$E[\text{gems} \mid s = 1] = 26 \cdot 0.04 = 1.04$$

Cap applied: gold $\to 31$, gems $\to 1$ (hard).

---

## 4. Skill Curve — Lazy to Tryhard

Let $s \in [0, 1]$ be the fraction of spawned drops the player catches. Then:
$$\text{bonus\_gold}(s) = \min(c,\ s \cdot 35.4) = \min(31,\ 35.4 s)$$
$$\text{bonus\_gems}(s) = \min(1,\ \lfloor s \cdot 1.04 \rfloor)$$

| $s$ | Player profile | Bonus gold | $\%$ of $G_p$ | Bonus gems |
|---|---|---|---|---|
| 0.00 | Skips, no taps | 0 | $0\%$ | 0 |
| 0.25 | Half-asleep | $8.9 \to $ **8** | $4.2\%$ | 0 |
| 0.50 | Average | $17.7 \to $ **17** | $8.4\%$ | 0–1 |
| 0.75 | Attentive | $26.6 \to $ **26** | $12.6\%$ | 1 |
| 0.88 | Top — hits gold cap | $31.1 \to $ **31 (cap)** | $14.8\%$ | 1 |
| 1.00 | Machine | 31 (cap) | $14.8\%$ | 1 |

**Observations:**
- Cap is only reached at $s \approx 0.88$ — an honest skill cliff.
- Delta lazy ($s = 0.25$) vs top ($s = 0.88$) $= 23$ gold/session.
- Gems are near-guaranteed at $s \geq 0.75$ — rewarding attention, not luck.

---

## 5. Daily Upside — All Scenarios

Assuming 6 Collect Alls per day (full optimization, every 4 h). Fewer than $5\%$ of active users actually play this way.

| Profile | Base (no minigame) | Minigame gold | Minigame gems | Total gold | Total gems | Gold delta | Gem delta |
|---|---|---|---|---|---|---|---|
| **Lazy** (1 collect/day, skip) | 210 | 0 | 0 | 210 | 0.6 | — | — |
| **Casual** (3 collects/day, $s = 0.5$) | 630 | 51 | 3 | 681 | 4.8 | $+8.1\%$ | $+78\%$ |
| **Active** (6 collects/day, $s = 0.5$) | 1 260 | 102 | 6 | 1 362 | 9.6 | $+8.1\%$ | $+167\%$ |
| **Top** (6 collects/day, $s = 0.88$) | 1 260 | 186 | 6 | 1 446 | 9.6 | $+14.8\%$ | $+167\%$ |
| **Perfect** (6 collects/day, $s = 1.0$) | 1 260 | 186 | 6 | 1 446 | 9.6 | $+14.8\%$ | $+167\%$ |

### 5.1 Gold — completely safe

Top delta $+186$ gold/day $\approx 1.2$ PvP wins. PvP delivers $\sim 2700$ gold/day at the same time-on-target. Even with the full bonus, Gold Mine does not become a dominant source. **Zero risk to the gold economy.**

### 5.2 Gems — requires monitoring

Active/top players receive $+6$ gems/day vs baseline 3.6 — that is a **doubling of gem velocity**.

Reference gem sinks (BALANCE_CONSTANTS v2):
- Stamina Refill = 30 gems
- Extra PvP = 50 gems
- Mine Boost = 10 gems
- Mine Slot = 50 gems
- BP Premium = 500 gems
- Respec = 50 gems

Delta $+6$ gems/day $\to +2\%$ BP Premium/month, $+1$ Stamina Refill every 5 days vs every 10. Noticeable acceleration, not breaking (BP Premium stays gated for payers, Refill was already accessible to active players).

**Protective mechanisms:**
1. Hard session cap: max 1 gem per mini-game session.
2. Optional daily cap: max 4 gems/day bonus (instead of 6) — backend toggle if Ledger sees accumulation.
3. Drop weight $4\%$ can be lowered to $3\%$ (avg $\sim 0.75$ gem/session) via a live-ops change.

**Recommendation:** ship $4\%$ in Phase 1 with `minigame_gems_awarded` event logging, review after 7 days. If the daily gem flow grows $> 30\%$ in the medium cohort, downtune weight to $2\%$.

---

## 6. Expedition Meta-Loop (Variant D) — No EV Change

The expedition loop is a commitment-and-closure layer on top of the core mini-game. It does **not** modify any per-session expected value. Formally, let:

- $N = 5$ = extractions required to clear a shaft
- $q$ = accuracy per session (fraction caught), assumed i.i.d. across sessions in a cycle

Then per-cycle expected values simply scale by $N$:
$$E[\text{cycle gold bonus}] = N \cdot E[\text{bonus\_gold}(s)] = 5 \cdot \min(c,\ 35.4 \cdot q)$$
$$E[\text{cycle gem bonus}] = N \cdot E[\text{bonus\_gems}(s)] = 5 \cdot \min(1,\ \lfloor q \cdot 1.04 \rfloor)$$

For a top player ($q = 0.88$): $5 \cdot 31 = 155$ bonus gold per cycle, $5 \cdot 1 = 5$ bonus gems per cycle. A cycle takes $\sim 20$ hours at 6 CA/day (hardcore) or $\sim 40$ hours at 3 CA/day (casual).

**The daily-upside table in Section 5 is unchanged.** The meta-loop reshapes the player's mental model of the reward, not the reward itself.

### 6.1 Why add it

1. **Visible progression:** a filling bar on the Gold Mine screen gives a clear "progress I am making" signal, which the plain collector lacks.
2. **Committed variety:** forcing a $\geq 5$-session commitment prevents "flip-between-shafts every session" behavior and protects the variety of the experience.
3. **Natural picker cadence:** opening the picker once per day (for a hardcore player) feels like a small ritual — "which vein am I digging today?" — and creates a scheduled engagement hook without adding rewards.
4. **Zero expansion cost for Phase 2:** the same loop trivially supports Phase 2 per-shaft drop-table tilts (gold-tilt, gem-tilt) without any structural change.

### 6.2 Anti-abuse: shaft progress advances only on real plays

To prevent "skip-to-clear-faster" behavior, shaft progress increments **only** when the mini-game is played with `caught > 0` and `skipped == false`. Skipping the mini-game still awards the passive gold (no penalty), but does not advance the expedition. This keeps the closure loop tied to actual engagement rather than button-mashing through it.

### 6.3 D1 vs D2 — deferred to Phase 2

Phase 1 locks **D1** (free re-pick after clear). If Phase 2 telemetry shows a single shaft picked $>70\%$ of the time in the medium cohort, we migrate to **D2** (just-cleared shaft enters a 1-cycle cooldown). No client change needed — the backend picker-gate can be toggled without a new release.

### 6.4 Ascent sign-off criteria

- Cycle length at hardcore (6 CA/day): $20$ hours — **within target** (12–36 h window)
- Cycle length at casual (3 CA/day): $40$ hours — **within target** (24–72 h window)
- Cycle length at lazy (1 CA/day): $120$ hours — slightly above target ($\leq 96$ h), acceptable because lazy players would likely skip the mini-game anyway and the loop would pause organically
- Progression feel: each Collect All moves the bar by $20\%$ — large enough to feel, small enough to make 5 sessions feel meaningful

---

## 7. Server-Authoritative Guardrails

The client **never** computes its own reward — this is a CDO veto. The exact contract:

### Request (`POST /api/gold-mine/minigame-bonus`)
```json
{
  "character_id": "...",
  "session_id": "...",
  "caught": 19,
  "spawned": 26,
  "gold_claimed_in_session": 19,
  "gems_claimed_in_session": 1,
  "duration_ms": 15000,
  "skipped": false
}
```

### Server validation rules
1. `session_id` exists in `minigame_sessions`, `status = 'pending'`, `character_id` matches, `created_at` within 60 seconds.
2. `spawned` $\in [15, 40]$ — out of range $\to$ reject.
3. `caught \leq spawned`, `caught \geq 0`.
4. `gold_claimed_in_session \leq spawned \times 3` (max if all bags).
5. `gems_claimed_in_session \leq \min(spawned, 3)` — client cannot claim 10 gems.
6. **Server reward recomputation:**
```ts
const passiveGold = session.passive_gold_amount;
const cap = Math.floor(passiveGold * 0.15);
const bonusGold = Math.min(req.gold_claimed_in_session, cap);
const bonusGems = Math.min(req.gems_claimed_in_session, 1);
```
7. **Session atomicity:** mark `status = 'claimed'` in the same transaction that increments `character.gold`. Second request with the same `session_id` $\to$ reject.
8. **Rate limit:** 1 mini-game bonus per 30 seconds per `character_id` (script protection).
9. **Shaft progress update:** only if `skipped == false && caught > 0`, in the same transaction. On reaching $N$, `activeShaftKey` is cleared and the player is prompted for a pick on the next Collect All.

### Cheat surface

- Claim $s = 1.0$ instead of $s = 0.5$ $\to$ gains $+31$ gold instead of $+17$ (delta $14$ gold). Less than one PvP win. **Economic harm from cheat clients: negligible.**
- Claim a gem where none spawned $\to$ gains $+1$ gem. Session cap is 1 and daily cap is $6$; Stamina Refill costs 30 gems $\to$ 5 days of perfect cheating to buy one Refill. **Also negligible**, especially given the $4\%$ weight awards one almost always legitimately.
- Spam `/collect-all` every 30 s is impossible — backend cooldown is 4 hours.
- Spam `minigame-bonus` to clear a shaft without playing is blocked by the "progress only on real plays" rule ($caught > 0$ required).

**Verdict (Fortress + Signal):** guardrails are sufficient; no additional anti-cheat needed. Monitoring lives in Ledger (daily gems awarded per cohort, shaft clear rate, skip rate).

---

## 8. Comparison — Mini-game vs No-op (Current)

Today, tapping "Collect All" gives you 210 gold, a coins animation, and $+0.6$ gem (in expectation). The mini-game is **inserted into that same moment**, not replacing it.

| Metric | Without mini-game | With mini-game (Phase 1, avg $s = 0.5$) |
|---|---|---|
| Time per collect | $\sim 2$ s (tap + feedback) | $\sim 17$ s (tap $\to 15$ s game $\to$ result) |
| Attention cost | Low | Medium (skip available) |
| Gold/collect | 210 | 227 ($+17$ avg, $+31$ top) |
| Gem/collect expected | 0.6 | $0.6 + 0.5 = 1.1$ |
| Emotional peak | Flat | Two peaks: pool arrival + game finale |
| Retention hook | None | Accuracy PB + shaft cycle closure |
| Progression visibility | Slot bar only | Slot bar + expedition bar |

### Skip-as-Design

If the player taps Skip or closes the mini-game, they still receive **the full passive reward** (210 gold, no gem bonus). This is not a penalty; it is the default. Skip must be an explicit button on the intro overlay labelled "Collect without playing" or equivalent.

After 5 consecutive skips (tracked in `UserDefaults`), the intro overlay is suppressed and the game auto-collects with $s = 0$ (passive only). A single one-session toast `Tap to play for +15% bonus` is shown and then the pattern is left alone. This is anti-burnout for casuals.

**Important interaction with expedition loop:** skipping does not advance shaft progress. A casual player who skips 5 times in a row stays locked on their current shaft indefinitely until they choose to engage. This is acceptable because:
1. They are not being denied gold — they get the full passive reward.
2. The shaft picker is a reward for engagement, not a chore for disengagement.
3. If they re-engage later, the loop resumes where they left it.

---

## 9. Risk Matrix

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Gem velocity breaks BP/shop pacing | Medium | Medium | Optional daily cap on bonus gems; weight downtune $4\% \to 2\%$ |
| Players feel obligated | High | High | Auto-skip after 5; explicit Skip always |
| Client cheat script | Low | Low | Server-authoritative reward, rate limit |
| Retention split (lovers vs haters) | Low | Medium | Skip is first-class; no public skip stats |
| Bug in cap math | Low | High | Unit test `computeMinigameBonus(passiveGold, caughtGold, caughtGems)` |
| iPhone SE lag at 26 drop nodes | Medium | Low | Test on SE 2nd; node reuse pool if FPS $< 50$ |
| Shaft progress griefing (stuck on unwanted shaft) | Low | Low | D1 re-pick on clear; no forced rotation in Phase 1 |
| One shaft dominates | Medium | Low | Monitor in Ledger; if $> 70\%$, migrate to D2 in Phase 2 |

---

## 10. Phase Gates

**Phase 1 (ship now):**
- Drops: coin + bag + gem ($4\%$)
- Gem cap: 1/session
- Duration: 15 s
- Trigger: $1\times$ per Collect All
- Expedition loop: $N = 5$, D1, Z1, no completion reward
- Shafts shipped: stone + ice
- Skip button: first-class
- Server endpoint + DB session table + Character shaft state columns

**Phase 2 (live-ops, after 2 weeks of metrics):**
- Gem drop weight tune ($3\%$–$5\%$ range)
- Add `lava` and `crystal` shafts
- Cosmetic completion titles
- Per-shaft drop-table tilts (gold-tilt / gem-tilt / rare-tilt)
- D1 $\to$ D2 migration if telemetry flags dominance
- Possible daily cap on bonus gems
- Sparks as third currency experiment

**Phase 3 (future):**
- Class bonuses: Mage pulls drops magnetically, Rogue sees drops longer, Warrior cap $17\%$, Tank fewer drops with $+50\%$ gold
- Weekly Accuracy Rank leaderboard per shaft
- Rare-item chance on clear (requires Vault + Ledger re-audit)

---

## 11. Final Math Table

$$G_p = 210,\quad c = \lfloor 0.15 \cdot G_p \rfloor = 31$$
$$E[\text{gold} \mid s = 1.0] = 35.4 \to c = 31$$
$$E[\text{gold} \mid s = 0.5] = 17.7$$
$$E[\text{gems} \mid s = 1.0] = 1.04 \to \text{cap} = 1$$

**Daily top upside (6 sessions, $s = 0.88$):**
$$\Delta\text{gold} = 6 \cdot 31 = 186\text{ gold/day}$$
$$\Delta\text{gems} = 6 \cdot 1 = 6\text{ gems/day}$$

**As a share of daily income:**
$$\frac{186}{1260} = 14.8\%\text{ of Gold Mine daily}$$
$$\frac{186}{2700} = 6.9\%\text{ of PvP maximum}$$

**Per-cycle expected cycle reward (hardcore $s = 0.88$, $N = 5$):**
$$E[\text{cycle gold}] = 5 \cdot 31 = 155\text{ gold}$$
$$E[\text{cycle gems}] = 5 \cdot 1 = 5\text{ gems}$$
$$\text{Cycle time} \approx 20\text{ hours}$$

---

## 12. Sign-offs Required Before Merge

- [ ] **Vault** (Economy Designer) — approve drop table + cap
- [ ] **Ledger** (Economy QA) — approve gem velocity + daily cap strategy
- [ ] **Heartbeat** (Core Loop) — approve mini-game insertion into Collect All
- [ ] **Psyche** (Motivation) — approve skip-as-design, anti-burnout, commitment loop
- [ ] **Ascent** (Progression) — approve $N = 5$ expedition pacing
- [ ] **Fortress + Signal** — approve server contract + rate limit
- [ ] **Canvas + Ember** — approve shaft art direction + thematic cohesion
- [ ] **Architect** — final check against vision pillars

After approvals: `hexbound-studio:screen` implements the SwiftUI, `hexbound-studio:server` writes the endpoint, `hexbound-studio:fortress` runs the Prisma migration.
