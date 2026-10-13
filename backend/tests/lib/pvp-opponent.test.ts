/**
 * Self-farm guards.
 *
 * Regression cover for the hole found in the 2026-09-10 audit: gold and gems
 * live on `users`, a user may hold 5 characters, and every PvP route checked
 * only `character_id !== opponent_id`. A main could farm its own alt and both
 * the attacker and the defender payout incremented the SAME wallet row.
 *
 * See: docs/10_operations/HEXBOUND_FULL_AUDIT_2026-09-10.md (P0-8)
 */
import { describe, it, expect } from 'vitest';
import { sameOwner, excludeOwnCharacters } from '../../src/lib/game/pvp-opponent';

describe('sameOwner', () => {
  it('flags two characters on the same account', () => {
    expect(sameOwner({ userId: 'user-1' }, { userId: 'user-1' })).toBe(true);
  });

  it('allows characters on different accounts', () => {
    expect(sameOwner({ userId: 'user-1' }, { userId: 'user-2' })).toBe(false);
  });

  it('does not treat distinct character ids as sufficient', () => {
    // The exact bug: different characters, same wallet.
    const main = { id: 'char-main', userId: 'user-1' };
    const alt = { id: 'char-alt', userId: 'user-1' };
    expect(main.id).not.toBe(alt.id);
    expect(sameOwner(main, alt)).toBe(true);
  });
});

describe('excludeOwnCharacters', () => {
  it('excludes both the character itself and every sibling on the account', () => {
    expect(excludeOwnCharacters('char-1', 'user-1')).toEqual({
      id: { not: 'char-1' },
      userId: { not: 'user-1' },
    });
  });

  it('produces a fragment that is spreadable into a Prisma where clause', () => {
    const where = {
      ...excludeOwnCharacters('char-1', 'user-1'),
      level: { gte: 5, lte: 15 },
    };
    expect(where).toEqual({
      id: { not: 'char-1' },
      userId: { not: 'user-1' },
      level: { gte: 5, lte: 15 },
    });
  });
});
