// =============================================================================
// generate-balance-docs.ts — W1.D4 SSoT doc auto-generator
// =============================================================================
//
// Reads backend/src/lib/game/balance.ts via runtime import (not AST parsing)
// and emits docs/06_game_systems/BALANCE_CONSTANTS_AUTO.md as a pure mechanical
// reference derived 1:1 from code. Humans edit balance.ts; this script brings
// the docs back in sync.
//
// Usage:
//   cd backend
//   npm run docs:balance          # regenerate
//   npm run docs:balance -- --check   # verify file is fresh (CI / preflight)
//
// Design notes:
//   - Runtime import avoids the fragility of AST walks. balance.ts is
//     side-effect-free — importing it just evaluates `as const` literals.
//   - The curated narrative file (BALANCE_CONSTANTS.md) is NOT overwritten;
//     it now carries a banner pointing to this auto file as SSoT for numbers.
//   - Output is deterministic (stable key order, no timestamps in body).
//
// =============================================================================

import {
  STAMINA,
  HP_REGEN,
  xpForLevel,
  GOLD_REWARDS,
  XP_REWARDS,
  FIRST_WIN_BONUS,
  UPGRADE_CHANCES,
  DAILY_LOGIN_REWARDS,
  IAP_PRODUCTS,
  BATTLE_PASS,
  bpXpForLevel,
  ELO,
  PVP_RANKS,
  COMBAT,
  BATTLE_FATIGUE,
  STANCE_ZONES,
  PRESTIGE,
  DROP_CHANCES,
  LOSS_STREAK_BONUSES,
  WIN_STREAK_BONUSES,
  REPAIR_COSTS,
  UPGRADE_COSTS,
  upgradeCost,
  SKILLS,
  PASSIVES,
  GEM_COSTS,
  STAT_PURCHASE,
  INVENTORY,
  EXTRA_PVP,
  RARITY_DISTRIBUTION,
} from '../src/lib/game/balance';

import * as fs from 'node:fs';
import * as path from 'node:path';

// -----------------------------------------------------------------------------
// Output helpers
// -----------------------------------------------------------------------------

const out: string[] = [];
const push = (line: string = '') => out.push(line);

function section(title: string, depth = 2) {
  push();
  push(`${'#'.repeat(depth)} ${title}`);
  push();
}

function kvTable(title: string, obj: Record<string, unknown>) {
  section(title, 3);
  push('| Key | Value |');
  push('|-----|-------|');
  for (const [k, v] of Object.entries(obj)) {
    push(`| \`${k}\` | \`${formatValue(v)}\` |`);
  }
}

function formatValue(v: unknown): string {
  if (v === null || v === undefined) return String(v);
  if (typeof v === 'string') return `"${v}"`;
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  if (Array.isArray(v)) return `[${v.map(formatValue).join(', ')}]`;
  if (typeof v === 'object') return JSON.stringify(v);
  return String(v);
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

push('<!-- AUTO-GENERATED from backend/src/lib/game/balance.ts — DO NOT EDIT MANUALLY -->');
push('<!-- Regenerate with: cd backend && npm run docs:balance -->');
push();
push('# Balance Constants — Auto-Generated Reference');
push();
push('> **Source of truth:** `backend/src/lib/game/balance.ts`');
push('> **Curated narrative:** `docs/06_game_systems/BALANCE_CONSTANTS.md`');
push('>');
push('> This document is the mechanical mirror of `balance.ts`. Every number below');
push('> is read from code at generation time. If you edit this file by hand, the');
push('> pre-commit drift check will fail.');
push();
push('## Table of contents');
push();
push('- [Stamina](#stamina)');
push('- [HP regen](#hp-regen)');
push('- [XP & leveling](#xp--leveling)');
push('- [Gold rewards](#gold-rewards)');
push('- [First-win bonus](#first-win-bonus)');
push('- [Equipment upgrade](#equipment-upgrade)');
push('- [Daily login rewards](#daily-login-rewards)');
push('- [IAP products](#iap-products)');
push('- [Battle pass](#battle-pass)');
push('- [ELO & PvP ranks](#elo--pvp-ranks)');
push('- [Combat](#combat)');
push('- [Battle fatigue](#battle-fatigue)');
push('- [Stance zones](#stance-zones)');
push('- [Prestige](#prestige)');
push('- [Drop chances](#drop-chances)');
push('- [Streak bonuses](#streak-bonuses)');
push('- [Repair & upgrade costs](#repair--upgrade-costs)');
push('- [Skills & passives](#skills--passives)');
push('- [Gem costs](#gem-costs)');
push('- [Stat purchase](#stat-purchase)');
push('- [Inventory](#inventory)');
push('- [Extra PvP](#extra-pvp)');
push('- [Rarity distribution](#rarity-distribution)');

// -----------------------------------------------------------------------------
// Stamina
// -----------------------------------------------------------------------------

section('Stamina');
kvTable('STAMINA', STAMINA as Record<string, unknown>);
push();
push(`**Derived:** full 0→${STAMINA.MAX} stamina takes ` +
     `${STAMINA.MAX * STAMINA.REGEN_INTERVAL_MINUTES} minutes ` +
     `(${(STAMINA.MAX * STAMINA.REGEN_INTERVAL_MINUTES / 60).toFixed(1)} hours).`);

// -----------------------------------------------------------------------------
// HP regen
// -----------------------------------------------------------------------------

section('HP regen');
kvTable('HP_REGEN', HP_REGEN as Record<string, unknown>);
push();
push(`**Derived:** out-of-combat regen is ${HP_REGEN.REGEN_RATE}% of maxHp per ` +
     `${HP_REGEN.REGEN_INTERVAL_MINUTES} minutes → full heal in ` +
     `${(100 / HP_REGEN.REGEN_RATE) * HP_REGEN.REGEN_INTERVAL_MINUTES} minutes.`);

// -----------------------------------------------------------------------------
// XP & leveling
// -----------------------------------------------------------------------------

section('XP & leveling');
push('Formula: `xpForLevel(level) = 100 * level + 20 * level²`');
push();
push('| Level | XP required | Cumulative delta |');
push('|-------|-------------|-------------------|');
let prev = 0;
for (const lvl of [1, 2, 5, 10, 20, 30, 40, 50, 60, 75, 100]) {
  const xp = xpForLevel(lvl);
  push(`| ${lvl} | ${xp.toLocaleString()} | +${(xp - prev).toLocaleString()} |`);
  prev = xp;
}

// -----------------------------------------------------------------------------
// Gold rewards
// -----------------------------------------------------------------------------

section('Gold rewards');
kvTable('GOLD_REWARDS', GOLD_REWARDS as Record<string, unknown>);
push();
kvTable('XP_REWARDS', XP_REWARDS as Record<string, unknown>);

// -----------------------------------------------------------------------------
// First-win bonus
// -----------------------------------------------------------------------------

section('First-win bonus');
kvTable('FIRST_WIN_BONUS', FIRST_WIN_BONUS as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Equipment upgrade chances
// -----------------------------------------------------------------------------

section('Equipment upgrade');
push('### UPGRADE_CHANCES (success % per +N level)');
push();
push('| +Level | Success % |');
push('|--------|-----------|');
UPGRADE_CHANCES.forEach((pct, i) => {
  push(`| +${i + 1} | ${pct}% |`);
});
push();
push('### UPGRADE_COSTS');
push();
kvTable('UPGRADE_COSTS', UPGRADE_COSTS as Record<string, unknown>);
push();
push('**Derived cost table:**');
push();
push('| +Level | Gold cost |');
push('|--------|-----------|');
for (let i = 1; i <= 10; i++) {
  push(`| +${i} | ${upgradeCost(i).toLocaleString()} |`);
}

// -----------------------------------------------------------------------------
// Daily login rewards
// -----------------------------------------------------------------------------

section('Daily login rewards');
push('7-day cycle, ships to clients via `/api/game/init` → `config.dailyLoginRewards`.');
push();
push('| Day | Type | Amount | Display name | Display icon | Item ID |');
push('|-----|------|--------|--------------|--------------|---------|');
DAILY_LOGIN_REWARDS.forEach((r, i) => {
  push(`| ${i + 1} | ${r.type} | ${r.amount} | ${r.displayName} | \`${r.displayIcon}\` | ${r.itemId ?? '—'} |`);
});

// -----------------------------------------------------------------------------
// IAP products
// -----------------------------------------------------------------------------

section('IAP products');
push('| Product ID | Gems | Gold | Premium | Monthly gem card | Price USD |');
push('|------------|------|------|---------|------------------|-----------|');
for (const [id, p] of Object.entries(IAP_PRODUCTS)) {
  push(`| \`${id}\` | ${p.gems} | ${p.gold} | ${p.premium ? 'yes' : '—'} | ${p.monthlyGemCard ? 'yes' : '—'} | $${p.price.toFixed(2)} |`);
}

// -----------------------------------------------------------------------------
// Battle pass
// -----------------------------------------------------------------------------

section('Battle pass');
kvTable('BATTLE_PASS', BATTLE_PASS as Record<string, unknown>);
push();
push('**Formula:** `bpXpForLevel(level) = 100 + level * 50`');
push();
push('| BP Level | XP required |');
push('|----------|-------------|');
for (const lvl of [1, 5, 10, 25, 50, 100]) {
  push(`| ${lvl} | ${bpXpForLevel(lvl).toLocaleString()} |`);
}

// -----------------------------------------------------------------------------
// ELO & PvP ranks
// -----------------------------------------------------------------------------

section('ELO & PvP ranks');
kvTable('ELO', ELO as Record<string, unknown>);
push();
kvTable('PVP_RANKS (rating thresholds)', PVP_RANKS as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Combat
// -----------------------------------------------------------------------------

section('Combat');
kvTable('COMBAT', COMBAT as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Battle fatigue
// -----------------------------------------------------------------------------

section('Battle fatigue');
kvTable('BATTLE_FATIGUE', BATTLE_FATIGUE as Record<string, unknown>);
push();
push(`**Mechanic:** after turn ${BATTLE_FATIGUE.FATIGUE_START_TURN}, both fighters ` +
     `deal +${BATTLE_FATIGUE.FATIGUE_PERCENT_PER_TURN}% more damage per additional turn.`);

// -----------------------------------------------------------------------------
// Stance zones
// -----------------------------------------------------------------------------

section('Stance zones');
push('Valid zones: ' + STANCE_ZONES.VALID_ZONES.map(z => `\`${z}\``).join(', '));
push();
push('### Attack zone bonuses');
push();
push('| Zone | Offense | Crit |');
push('|------|---------|------|');
for (const [zone, bonus] of Object.entries(STANCE_ZONES.ATTACK_ZONE)) {
  push(`| ${zone} | ${bonus.offense} | ${bonus.crit} |`);
}
push();
push('### Defense zone bonuses');
push();
push('| Zone | Defense | Dodge |');
push('|------|---------|-------|');
for (const [zone, bonus] of Object.entries(STANCE_ZONES.DEFENSE_ZONE)) {
  push(`| ${zone} | ${bonus.defense} | ${bonus.dodge} |`);
}
push();
push(`**Mismatch offense bonus:** +${STANCE_ZONES.MISMATCH_OFFENSE_BONUS} (attacker)  `);
push(`**Match defense bonus:** +${STANCE_ZONES.MATCH_DEFENSE_BONUS} (defender)`);

// -----------------------------------------------------------------------------
// Prestige
// -----------------------------------------------------------------------------

section('Prestige');
kvTable('PRESTIGE', PRESTIGE as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Drop chances
// -----------------------------------------------------------------------------

section('Drop chances');
push('| Source | Drop chance |');
push('|--------|-------------|');
for (const [src, pct] of Object.entries(DROP_CHANCES)) {
  push(`| ${src} | ${(pct * 100).toFixed(0)}% |`);
}

// -----------------------------------------------------------------------------
// Streak bonuses
// -----------------------------------------------------------------------------

section('Streak bonuses');
push('### Win streak gold bonus');
push();
push('| Streak length | Bonus |');
push('|---------------|-------|');
WIN_STREAK_BONUSES.forEach((b, i) => {
  if (b > 0 || i === 0) {
    push(`| ${i} | +${(b * 100).toFixed(0)}% |`);
  }
});
push();
push('### Loss streak gold recovery (applied on next win)');
push();
push('| Loss streak | Bonus on next win |');
push('|-------------|-------------------|');
LOSS_STREAK_BONUSES.forEach((b, i) => {
  if (b > 0 || i === 0) {
    push(`| ${i} | +${(b * 100).toFixed(0)}% |`);
  }
});

// -----------------------------------------------------------------------------
// Repair & upgrade costs
// -----------------------------------------------------------------------------

section('Repair & upgrade costs');
push('### REPAIR_COSTS');
push();
push(`- **Base cost:** ${REPAIR_COSTS.BASE_COST} gold  `);
push(`- **Per level:** +${REPAIR_COSTS.PER_LEVEL} gold  `);
push();
push('**Rarity multipliers:**');
push();
push('| Rarity | Multiplier |');
push('|--------|------------|');
for (const [rarity, mult] of Object.entries(REPAIR_COSTS.RARITY_MULTIPLIERS)) {
  push(`| ${rarity} | ×${mult} |`);
}

// -----------------------------------------------------------------------------
// Skills & passives
// -----------------------------------------------------------------------------

section('Skills & passives');
kvTable('SKILLS', SKILLS as Record<string, unknown>);
push();
kvTable('PASSIVES', PASSIVES as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Gem costs
// -----------------------------------------------------------------------------

section('Gem costs');
kvTable('GEM_COSTS', GEM_COSTS as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Stat purchase
// -----------------------------------------------------------------------------

section('Stat purchase');
push(`- **Daily limit:** ${STAT_PURCHASE.DAILY_LIMIT}  `);
push(`- **Global cap:** ${STAT_PURCHASE.GLOBAL_CAP}  `);
push();
push('**Escalating daily cost (gems):**');
push();
push('| Purchase # | Gem cost |');
push('|------------|----------|');
STAT_PURCHASE.ESCALATION.forEach((cost, i) => {
  push(`| ${i + 1} | ${cost} |`);
});

// -----------------------------------------------------------------------------
// Inventory
// -----------------------------------------------------------------------------

section('Inventory');
kvTable('INVENTORY', INVENTORY as Record<string, unknown>);
push();
push(`**Derived:** max slots a character can ever reach = ` +
     `${INVENTORY.BASE_SLOTS} + ${INVENTORY.MAX_EXPANSIONS} × ${INVENTORY.EXPAND_AMOUNT} = ` +
     `${INVENTORY.MAX_SLOTS}.`);

// -----------------------------------------------------------------------------
// Extra PvP
// -----------------------------------------------------------------------------

section('Extra PvP');
kvTable('EXTRA_PVP', EXTRA_PVP as Record<string, unknown>);

// -----------------------------------------------------------------------------
// Rarity distribution
// -----------------------------------------------------------------------------

section('Rarity distribution');
push('| Rarity | Weight (%) |');
push('|--------|------------|');
let sum = 0;
for (const [rarity, weight] of Object.entries(RARITY_DISTRIBUTION)) {
  push(`| ${rarity} | ${weight} |`);
  sum += weight;
}
push();
push(`**Sum check:** ${sum} (must equal 100)`);

// -----------------------------------------------------------------------------
// Footer
// -----------------------------------------------------------------------------

push();
push('---');
push();
push('*Generated by `backend/scripts/generate-balance-docs.ts`. ' +
     'Do not edit this file directly — edit `backend/src/lib/game/balance.ts` ' +
     'and rerun `npm run docs:balance`.*');
push();

// -----------------------------------------------------------------------------
// Write / check mode
// -----------------------------------------------------------------------------

const repoRoot = path.resolve(__dirname, '..', '..');
const outPath = path.join(repoRoot, 'docs', '06_game_systems', 'BALANCE_CONSTANTS_AUTO.md');
const generated = out.join('\n');

const isCheck = process.argv.includes('--check');

if (isCheck) {
  let existing = '';
  try {
    existing = fs.readFileSync(outPath, 'utf8');
  } catch {
    console.error(`[docs:balance] FAIL: ${outPath} does not exist. Run \`npm run docs:balance\`.`);
    process.exit(1);
  }
  if (existing.trim() !== generated.trim()) {
    console.error(`[docs:balance] FAIL: ${outPath} is out of date. Run \`npm run docs:balance\` and commit the result.`);
    process.exit(1);
  }
  console.log(`[docs:balance] OK: ${path.relative(repoRoot, outPath)} is up to date.`);
  process.exit(0);
}

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, generated, 'utf8');
console.log(`[docs:balance] wrote ${path.relative(repoRoot, outPath)} (${generated.length} bytes, ${out.length} lines)`);
