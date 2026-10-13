/**
 * Fortune Wheel sectors — server-authoritative. Shared by /spin (roll) and
 * /status (odds disclosure for the client — App Store 3.1.1).
 */
export const WHEEL_SECTORS = [
  { index: 0, multiplier: 0,   label: 'LOSE',  weight: 40 },
  { index: 1, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 2, multiplier: 0,   label: 'LOSE',  weight: 40 },
  { index: 3, multiplier: 2,   label: 'x2',    weight: 20 },
  { index: 4, multiplier: 0,   label: 'LOSE',  weight: 40 },
  { index: 5, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 6, multiplier: 0,   label: 'LOSE',  weight: 40 },
  { index: 7, multiplier: 3,   label: 'x3',    weight: 10 },
  { index: 8, multiplier: 0,   label: 'LOSE',  weight: 40 },
  { index: 9, multiplier: 1.5, label: 'x1.5',  weight: 25 },
  { index: 10, multiplier: 0,  label: 'LOSE',  weight: 40 },
  { index: 11, multiplier: 5,  label: 'x5',    weight: 5  }, // JACKPOT
] as const
// Total weight 350. EV ≈ 0.593 → 59.3% RTP (house edge ~40%).

export type WheelOdd = { label: string; multiplier: number; percent: number }

/** Per-outcome probabilities, merged by multiplier, sorted by multiplier. */
export function wheelOdds(): WheelOdd[] {
  const total = WHEEL_SECTORS.reduce((s, x) => s + x.weight, 0)
  const byMult = new Map<number, { label: string; weight: number }>()
  for (const s of WHEEL_SECTORS) {
    const cur = byMult.get(s.multiplier)
    byMult.set(s.multiplier, { label: s.label, weight: (cur?.weight ?? 0) + s.weight })
  }
  return Array.from(byMult.entries())
    .map(([multiplier, { label, weight }]) => ({
      label,
      multiplier,
      percent: Math.round((1000 * weight) / total) / 10,
    }))
    .sort((a, b) => a.multiplier - b.multiplier)
}
