/**
 * Milestone payouts are per account — 2026-10-14 balance audit.
 *
 * Rewards are gold and gems on `User`; the claim was keyed on `Character`.
 * Five characters each crossing a milestone paid the same wallet five times.
 */
import { describe, expect, it, vi } from 'vitest'
import { checkAndAwardMilestones, getMilestoneStatus, MILESTONES } from '../../src/lib/game/milestones'

type Claim = { userId: string; characterId: string | null; milestoneLevel: number }

function fakePrisma(claims: Claim[], characters: Record<string, { userId: string }>) {
  const userUpdates: unknown[] = []
  const tx = {
    milestoneClaim: {
      create: vi.fn(async ({ data }: { data: Claim }) => {
        claims.push(data)
        return data
      }),
    },
    user: { update: vi.fn(async (args: unknown) => { userUpdates.push(args); return {} }) },
  }
  const prisma = {
    character: {
      findUnique: vi.fn(async ({ where }: { where: { id: string } }) => characters[where.id] ?? null),
    },
    milestoneClaim: {
      findMany: vi.fn(async ({ where }: { where: { userId: string } }) =>
        claims.filter((c) => c.userId === where.userId).map((c) => ({ milestoneLevel: c.milestoneLevel })),
      ),
    },
    $transaction: vi.fn(async (fn: (t: typeof tx) => Promise<void>) => fn(tx)),
  }
  return { prisma, claims, userUpdates }
}

const first = MILESTONES[0]

describe('checkAndAwardMilestones', () => {
  it('pays a milestone once per account, not once per character', async () => {
    const { prisma, claims, userUpdates } = fakePrisma([], {
      'char-a': { userId: 'u1' },
      'char-b': { userId: 'u1' },
    })

    const a = await checkAndAwardMilestones(prisma as never, 'char-a', first.level)
    expect(a.map((m) => m.level)).toEqual([first.level])
    expect(userUpdates).toHaveLength(1)

    // Second character on the same account crosses the same level.
    const b = await checkAndAwardMilestones(prisma as never, 'char-b', first.level)
    expect(b).toEqual([])
    expect(userUpdates).toHaveLength(1)
    expect(claims).toHaveLength(1)
    expect(claims[0]).toMatchObject({ userId: 'u1', characterId: 'char-a' })
  })

  it('still pays a different account', async () => {
    const { prisma, userUpdates } = fakePrisma(
      [{ userId: 'u1', characterId: 'char-a', milestoneLevel: first.level }],
      { 'char-x': { userId: 'u2' } },
    )
    const x = await checkAndAwardMilestones(prisma as never, 'char-x', first.level)
    expect(x.map((m) => m.level)).toEqual([first.level])
    expect(userUpdates).toHaveLength(1)
  })

  it('shows a milestone as claimed on every character of the account', async () => {
    const { prisma } = fakePrisma(
      [{ userId: 'u1', characterId: null, milestoneLevel: first.level }],
      { 'char-b': { userId: 'u1' } },
    )
    const status = await getMilestoneStatus(prisma as never, 'char-b', first.level)
    const row = status.milestones.find((m) => m.level === first.level)!
    expect(row.claimed).toBe(true)
    expect(row.available).toBe(false)
  })
})
