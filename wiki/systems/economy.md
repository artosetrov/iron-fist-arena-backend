---
title: Economy
category: systems
tags: [economy, gold, gems, monetization, sinks]
sources: [docs/02_product_and_features/ECONOMY.md, docs/06_game_systems/BALANCE_CONSTANTS.md]
updated: 2026-04-14
---

# Economy

Two currencies: Gold (soft, earned) and Gems (premium, mostly IAP).

## Gold

**Earning:**
- PvP win: 150g (× 1.04/level), loss: 50g
- Level scaling: +4% per level (doubled from 2% in Economy v3)
- Win streak: 3-win +20%, 5-win +50% (capped, was +100% pre-W3.D3)
- CHA bonus: 0–30 CHA +2.5%/pt (cap +75%), 31–60 +1%/pt (+30%), 61+ +0.5%/pt (hard cap +80%, was +125%)
- Starting gold: 300

**Sinks:**
- Equipment purchase: 100–8,000g
- Upgrades: exponential 150 × 1.4^N (+1 to +10) — **dominant whale sink**
- Repairs: 120 + level × 20 + rarity multiplier
- Potions: live-configurable via `GameConfig` (`consumable.price.*`). Code fallback baseline currently matches the seeded catalog: stamina `100/250/500`, health `150/350/700`.
- Skills: learn 200g, upgrade 500 + 500 × rank
- Inventory expansion: 5,000g/slot (28 base → 58 max)

## Gems

**F2P sources:** Daily login Day 7 (25), achievements (5–50), battle pass (~50–100 free tier)

**Sinks:** Stamina refill (50g base, diminishing: 80/140/240), protection scroll (40g, was 50), battle pass premium (700g, was 500)

**No gem → gold conversion.** See [[why-no-gem-to-gold]].

## Monetization

| Product | Price | Value |
|---------|-------|-------|
| Gem packs | $0.99–$49.99 | 100–6,500 gems |
| Monthly Gem Card | $4.99 | 50 instant + 10/day = 350 total |
| Starter Bundle | $2.99 | 200g + 3,000g (one-time) |
| Adventurer's Bundles | varies | 600–3,200 gems + 3k–20k gold |
| Premium Forever | $9.99 | **Disabled for new sales** |

Premium perks: +10% gold multiplier, +25 gems/day, "Chosen" title. No stat boosts = F2P friendly.

## Economy Health

Sink ratio targets by archetype:
- Casual: 55–65% (measured: 57.9%)
- Active: 60–70% (measured: 62.3%)
- Whale: 70–80% (measured: 74.3%)

Verified via 1000-player Monte Carlo simulator. CI gate prevents drift.

### W3.D3 Rebalance (2026-04-10)

Win streak capped +50% (was +100%). CHA gold bonus capped 80% (was 125%). Repair costs raised. Consumable price increase is documented as intended policy, but the repo-visible code fallback still stays on seeded potion prices unless `GameConfig` overrides are present. See [[rebalance-w3d3]].

## See Also

- [[combat]] (gold from PvP)
- [[progression]] (level scaling)
- [[gold-mine]] (passive income)
- [[why-no-gem-to-gold]]
- [[why-exponential-upgrades]]
