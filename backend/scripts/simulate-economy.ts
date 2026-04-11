// =============================================================================
// simulate-economy.ts — CLI wrapper around the pure economy-simulator
// =============================================================================
//
// Usage:
//   cd backend && tsx scripts/simulate-economy.ts
//   cd backend && tsx scripts/simulate-economy.ts --players 5000 --days 60 --seed 777
//
// Prints a per-archetype sink-ratio report plus the headline overall number.
// This is the interactive sibling of backend/tests/economy/sink-ratio.test.ts —
// use it during balance tuning to feel-check a change before committing.
//
// It is intentionally thin: all modelling lives in
// src/lib/game/economy-simulator.ts so the test and the CLI agree byte-for-byte.

import {
  runEconomySimulation,
  DEFAULT_ARCHETYPES,
} from '../src/lib/game/economy-simulator'

interface Argv {
  players: number
  days: number
  seed: number
}

function parseArgv(argv: string[]): Argv {
  const out: Argv = { players: 1000, days: 30, seed: 20260410 }
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i]
    const v = argv[i + 1]
    if (k === '--players') out.players = Number(v)
    if (k === '--days') out.days = Number(v)
    if (k === '--seed') out.seed = Number(v)
  }
  return out
}

function fmtPct(x: number): string {
  return (x * 100).toFixed(1) + '%'
}

function fmtGold(x: number): string {
  return Math.round(x).toLocaleString('en-US')
}

function main() {
  const { players, days, seed } = parseArgv(process.argv.slice(2))

  console.log('='.repeat(72))
  console.log(`Hexbound economy simulation — W3.D3 tuning`)
  console.log(
    `players/archetype=${players}  days=${days}  seed=${seed}  archetypes=${DEFAULT_ARCHETYPES.length}`,
  )
  console.log('='.repeat(72))

  const result = runEconomySimulation(DEFAULT_ARCHETYPES, {
    playersPerArchetype: players,
    days,
    seed,
  })

  const header =
    'archetype  avg_in/day  avg_out/day  sink_ratio  cumulative_net'
  console.log(header)
  console.log('-'.repeat(header.length))
  for (const r of result.archetypes) {
    console.log(
      [
        r.name.padEnd(10),
        fmtGold(r.avg_gold_in_per_day).padStart(10),
        fmtGold(r.avg_gold_out_per_day).padStart(12),
        fmtPct(r.sink_ratio).padStart(11),
        fmtGold(r.cumulative_net).padStart(16),
      ].join('  '),
    )
  }
  console.log('-'.repeat(header.length))
  console.log(
    `OVERALL    in=${fmtGold(result.total_gold_in)}  out=${fmtGold(
      result.total_gold_out,
    )}  sink_ratio=${fmtPct(result.overall_sink_ratio)}`,
  )
  console.log('='.repeat(72))

  // Exit non-zero if the sink ratio is below 50% — matches the QA bar.
  const ok = result.overall_sink_ratio >= 0.5
  if (!ok) {
    console.error(
      `FAIL: overall sink_ratio ${fmtPct(
        result.overall_sink_ratio,
      )} is below the 50% floor.`,
    )
    process.exit(1)
  }
  console.log(`PASS: overall sink_ratio meets the 50% floor.`)
}

main()
