/**
 * active-handlers.ts — Pure-function math for `TalentSlotAction` handlers.
 *
 * Extracted from `app/api/pvp/strike/route.ts` (Talents v2, 2026-04-29) so
 * the round-resolution arithmetic is testable in isolation. The route file
 * still owns request shape, state mutation, persistence, and AI selection;
 * the helpers below are stateless and depend only on their parameters.
 *
 * Spec source-of-truth:
 *   docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §8 (action-type semantics)
 *
 * Audit trail:
 *   wiki/audit/block-262-talents-v2-ult-action-types-and-class-trees.md
 *
 * Each helper returns a number / boolean — no side effects, no I/O. Bounds:
 *   • All output damage / heal values clamped to >= 0.
 *   • All magnitude inputs treated as fractions (0.5 == 50 %), and a negative
 *     magnitude is treated as 0 to prevent stat-flip exploits if a balance
 *     mistake ever ships a signed value through the seeds.
 */

/**
 * `burst_damage` and its 1v1 alias `aoe_damage` (D-3 of SKILL_TREE_DESIGN_V2 §8):
 * multiply the base strike's damage by `(1 + magnitude)`. magnitude=0.6 means
 * a 60 % bonus on top of the existing roll.
 */
export function applyBurstDamage(baseDamage: number, magnitude: number): number {
  return Math.round(baseDamage * (1 + Math.max(0, magnitude)))
}

/**
 * `shield_self` (and the Tank Fortress ult, which proxies through it):
 * reduce a single incoming damage value by `magnitude` fraction. magnitude=0.7
 * cuts the hit to 30 % of its raw value. Output is rounded and floored at 0
 * so a tiny incoming hit can never become a heal.
 *
 * Negative `magnitude` is clamped at 0 (identity — no reduction). Without
 * this clamp, a stray signed value in a seed would amplify damage above raw
 * (e.g. magnitude=-0.5 → 1.5×). This guard mirrors `applyBurstDamage` and
 * the docstring promise at the top of the module. Caught by unit-test
 * regression in `tests/lib/active-handlers.test.ts` 2026-04-29.
 */
export function applyShield(incomingDamage: number, magnitude: number): number {
  const safeMag = Math.max(0, magnitude)
  const reduced = Math.round(incomingDamage * Math.max(0, 1 - safeMag))
  return Math.max(0, reduced)
}

/**
 * `heal_self`: convert a max-HP fraction into an absolute heal amount.
 * magnitude=0.25 → restore 25 % of the fighter's max HP. Caller is responsible
 * for clamping the post-heal HP at maxHp; this helper only returns the
 * unsigned amount to add.
 */
export function healAmountFromActive(maxHp: number, magnitude: number): number {
  return Math.max(0, Math.round(maxHp * Math.max(0, magnitude)))
}

/**
 * `execute`: returns true when the defender's HP fraction is at or below the
 * configured magnitude threshold (and strictly above 0 — already-dead targets
 * don't trigger a finishing-blow animation). magnitude=0.2 means execute when
 * the target is at 20 % HP or less.
 *
 * `maxHp <= 0` returns false to keep test-doubles and degenerate match states
 * from short-circuiting into a guaranteed kill.
 */
export function shouldExecute(currentHp: number, maxHp: number, magnitude: number): boolean {
  if (maxHp <= 0) return false
  const pct = currentHp / maxHp
  return pct > 0 && pct <= Math.max(0, magnitude)
}
