// Bakes the 3D dice throw library for the iOS dice table.
//
//   cd scripts/dice-throws && npm install && npm run generate
//
// Writes Hexbound/Hexbound/Resources/Assets.xcassets/dice-throws.dataset/dice-throws.bin
// (read on device through NSDataAsset("dice-throws") by DiceThrowLibrary.swift).
//
// Why baked: the face that lands is decided by the server. The client plays a
// recorded throw and turns the visual cube inside its physics box by one of
// the 24 cube symmetries, so the server's face ends up on top
// (docs/06_game_systems/DICE_3D_THROW.md §2). RealityKit can't run a
// simulation ahead of time, so the simulation runs here, once.
//
// Units match DiceTableScene.swift: table half extents 2.05 × 3.05, die edge
// 0.8, +Z = the player's side (bottom of the screen), +Y up.
//
// Format (little endian):
//   "HXDT" u16 version=1 u16 fps u16 setCount
//   per set:  u8 dieCount u16 clipCount
//   per clip: f32 angleDeg f32 speed u16 frameCount
//             dieCount × (u16 launchMs u16 firstImpactMs)
//             u16 impactCount, impactCount × (u16 tMs u8 die u8 kind u8 strength u8 pad)
//               kind: 0 felt, 1 rim, 2 die · strength = impact speed × 10
//             frameCount × dieCount × 7 × i16  (x y z in mm, then qx qy qz qw × 32767)
//   set 0 = round throws (die 0 your attack, 1 your guard, 2 enemy attack, 3 enemy guard)
//   set 1 = reroll hops (one die, starting at rest at the origin)

import * as CANNON from 'cannon-es'
import { mkdirSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const OUT_DIR = resolve(HERE, '../../Hexbound/Hexbound/Resources/Assets.xcassets/dice-throws.dataset')

const DIE = 0.8
const H = DIE / 2
const TABLE = { hx: 2.05, hz: 3.05 }
const DT = 1 / 120
const FPS = 60
const HAND = { y: 1.35, z: 2.25, dx: 0.42 }
const TRAY_E = { atk: [0.52, -2.4], grd: [-0.52, -2.4] }
const ANGLES = [0, 7, 14, 21, 28, 35]
const SPEEDS = [5, 6.5, 8, 9.5, 11, 12.5]
const VARIANTS = 3
const HOPS = 24

// ---------- deterministic randomness
let seed = 0x5eed1e
function rnd() {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
const rand = (a, b) => a + rnd() * (b - a)
const randUnit = () => {
  for (;;) {
    const v = [rand(-1, 1), rand(-1, 1), rand(-1, 1)]
    const l = Math.hypot(...v)
    if (l > 0.1 && l <= 1) return v.map((c) => c / l)
  }
}
const randQuat = () => {
  // uniform random rotation (Shoemake)
  const u1 = rnd(), u2 = rnd() * Math.PI * 2, u3 = rnd() * Math.PI * 2
  const a = Math.sqrt(1 - u1), b = Math.sqrt(u1)
  return new CANNON.Quaternion(a * Math.sin(u2), a * Math.cos(u2), b * Math.sin(u3), b * Math.cos(u3))
}
const restingQuat = () => {
  // a die lying flat on some face with a random yaw
  const faces = [
    [0, 0, 0, 1], [1, 0, 0, 0], [Math.SQRT1_2, 0, 0, Math.SQRT1_2], [-Math.SQRT1_2, 0, 0, Math.SQRT1_2],
    [0, 0, Math.SQRT1_2, Math.SQRT1_2], [0, 0, -Math.SQRT1_2, Math.SQRT1_2],
  ]
  const f = faces[Math.floor(rnd() * 6)]
  const q = new CANNON.Quaternion(f[0], f[1], f[2], f[3])
  const yaw = new CANNON.Quaternion().setFromAxisAngle(new CANNON.Vec3(0, 1, 0), rand(0, Math.PI * 2))
  return yaw.mult(q)
}

// ---------- one simulation
function simulate(movers) {
  const world = new CANNON.World({ gravity: new CANNON.Vec3(0, -30, 0) })
  world.allowSleep = true
  world.solver.iterations = 14
  const mDie = new CANNON.Material(), mFloor = new CANNON.Material(), mWall = new CANNON.Material()
  world.addContactMaterial(new CANNON.ContactMaterial(mDie, mFloor, { friction: 0.32, restitution: 0.3 }))
  world.addContactMaterial(new CANNON.ContactMaterial(mDie, mDie, { friction: 0.18, restitution: 0.42 }))
  world.addContactMaterial(new CANNON.ContactMaterial(mDie, mWall, { friction: 0.08, restitution: 0.55 }))
  const floor = new CANNON.Body({ mass: 0, material: mFloor, shape: new CANNON.Plane() })
  floor.quaternion.setFromEuler(-Math.PI / 2, 0, 0)
  floor.kind = 0
  world.addBody(floor)
  const wall = (x, y, z, hx, hy, hz) => {
    const b = new CANNON.Body({ mass: 0, material: mWall, shape: new CANNON.Box(new CANNON.Vec3(hx, hy, hz)) })
    b.position.set(x, y, z); b.kind = 1; world.addBody(b)
  }
  const T = 0.5
  wall(TABLE.hx + T, 3, 0, T, 3, TABLE.hz + 1); wall(-TABLE.hx - T, 3, 0, T, 3, TABLE.hz + 1)
  wall(0, 3, TABLE.hz + T, TABLE.hx + 1, 3, T); wall(0, 3, -TABLE.hz - T, TABLE.hx + 1, 3, T)
  wall(0, 6 + T, 0, TABLE.hx + 1, T, TABLE.hz + 1)

  const shape = new CANNON.Box(new CANNON.Vec3(H, H, H))
  const bodies = movers.map((m, i) => {
    const delayed = m.launch > 0
    const b = new CANNON.Body({
      mass: delayed ? 0 : 1, material: mDie, shape, linearDamping: 0.1, angularDamping: 0.1,
      allowSleep: true, sleepSpeedLimit: 0.15, sleepTimeLimit: 0.3,
    })
    b.type = delayed ? CANNON.Body.STATIC : CANNON.Body.DYNAMIC
    b.position.set(...m.pos)
    b.quaternion.copy(m.quat)
    if (!delayed) { b.velocity.set(...m.vel); b.angularVelocity.set(...m.ang) }
    b.kind = 2; b.idx = i
    world.addBody(b)
    return b
  })

  let step = 0
  const impacts = []
  const lastImpact = movers.map(() => -1)
  bodies.forEach((b, i) => b.addEventListener('collide', (e) => {
    if (e.body.idx !== undefined && e.body.idx < i) return
    const v = Math.abs(e.contact.getImpactVelocityAlongNormal())
    const t = step * DT
    if (v < 0.5 || t - lastImpact[i] < 0.035) return
    lastImpact[i] = t
    impacts.push({ t, v, die: i, kind: e.body.kind ?? 2 })
  }))

  const frames = []
  const record = () => frames.push(bodies.map((b) => [
    b.position.x, b.position.y, b.position.z, b.quaternion.x, b.quaternion.y, b.quaternion.z, b.quaternion.w,
  ]))
  record()
  let settled = 0
  while (step < 120 * 8) {
    for (let i = 0; i < bodies.length; i++) {
      const m = movers[i], b = bodies[i]
      if (b.type === CANNON.Body.STATIC && step * DT >= m.launch) {
        b.type = CANNON.Body.DYNAMIC; b.mass = 1; b.updateMassProperties()
        b.velocity.set(...m.vel); b.angularVelocity.set(...m.ang); b.wakeUp()
      }
    }
    world.step(DT); step++
    if (step % (120 / FPS) === 0) record()
    const launched = movers.every((m) => step * DT >= m.launch)
    const still = launched && bodies.every((b) =>
      b.sleepState === CANNON.Body.SLEEPING || (b.velocity.lengthSquared() < 0.002 && b.angularVelocity.lengthSquared() < 0.002))
    if (still) { if (++settled > 10) break } else settled = 0
  }
  if (step % (120 / FPS) !== 0) record()

  const launch = movers.map((m) => m.launch)
  const firstImpact = movers.map((m, i) => {
    const hit = impacts.find((x) => x.die === i && x.t > m.launch + 0.06)
    return hit ? hit.t : m.launch + 0.5
  })
  return { frames, impacts, launch, firstImpact, bodies }
}

function upDot(q) {
  // largest |up| component among the six face normals = how flat the die lies
  const axes = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
  let best = 0
  for (const a of axes) {
    const v = q.vmult(new CANNON.Vec3(...a))
    best = Math.max(best, Math.abs(v.y))
  }
  return best
}

function isClean(sim, { maxDrift } = {}) {
  return sim.bodies.every((b, i) => {
    const p = b.position
    if (upDot(b.quaternion) < 0.995) return false
    if (Math.abs(p.x) > TABLE.hx - H * 0.9 || Math.abs(p.z) > TABLE.hz - H * 0.9) return false
    if (p.y > H + 0.05) return false // resting on another die
    if (maxDrift && Math.hypot(p.x, p.z) > maxDrift) return false
    return true
  })
}

// ---------- the two sets
function roundThrow(angleDeg, speed) {
  const a = (angleDeg * Math.PI) / 180
  const dir = [Math.sin(a), 0, -Math.cos(a)]
  const roll = [-dir[2], 0, dir[0]] // up × dir
  for (let attempt = 0; attempt < 120; attempt++) {
    const player = [-HAND.dx, HAND.dx].map((x) => {
      const spin = randUnit(), s = rand(5, 11)
      return {
        pos: [x, HAND.y, HAND.z], quat: randQuat(), launch: 0,
        vel: [dir[0] * speed + rand(-0.6, 0.6), 2.2 + speed * 0.16, dir[2] * speed + rand(-0.6, 0.6)],
        ang: [0, 1, 2].map((k) => roll[k] * speed * 1.7 + spin[k] * s),
      }
    })
    const enemy = [TRAY_E.atk, TRAY_E.grd].map(([x, z], i) => {
      const spin = randUnit(), s = rand(5, 10), r = rand(9, 14)
      return {
        pos: [x, H, z], quat: restingQuat(), launch: 0.24 + i * 0.05,
        vel: [rand(-1.4, 1.4), rand(5, 6.2), rand(5, 7)],
        ang: [r + spin[0] * s, spin[1] * s, spin[2] * s],
      }
    })
    const sim = simulate([...player, ...enemy])
    // PvP pacing: the whole throw (both sides) settles within 3 s
    if (isClean(sim) && (sim.frames.length - 1) / FPS <= 3.0) return sim
  }
  throw new Error(`no clean throw at ${angleDeg}° × ${speed}`)
}

function hop() {
  for (let attempt = 0; attempt < 60; attempt++) {
    const spin = randUnit(), s = rand(14, 20)
    const sim = simulate([{
      pos: [0, H, 0], quat: restingQuat(), launch: 0,
      vel: [rand(-0.45, 0.45), rand(7, 8.5), rand(-0.45, 0.45)],
      ang: spin.map((c) => c * s),
    }])
    if (isClean(sim, { maxDrift: 0.6 })) return sim
  }
  throw new Error('no clean hop')
}

// ---------- encoding
class Writer {
  constructor() { this.buf = Buffer.alloc(1 << 22); this.o = 0 }
  ensure(n) { if (this.o + n > this.buf.length) { const b = Buffer.alloc(this.buf.length * 2); this.buf.copy(b); this.buf = b } }
  u8(v) { this.ensure(1); this.buf.writeUInt8(v, this.o); this.o += 1 }
  u16(v) { this.ensure(2); this.buf.writeUInt16LE(v, this.o); this.o += 2 }
  i16(v) { this.ensure(2); this.buf.writeInt16LE(v, this.o); this.o += 2 }
  f32(v) { this.ensure(4); this.buf.writeFloatLE(v, this.o); this.o += 4 }
  str(s) { for (const c of s) this.u8(c.charCodeAt(0)) }
  done() { return this.buf.subarray(0, this.o) }
}
const clampI16 = (v) => Math.max(-32767, Math.min(32767, Math.round(v)))
const ms = (t) => Math.max(0, Math.min(65535, Math.round(t * 1000)))

function writeClip(w, sim, angle, speed) {
  const dieCount = sim.launch.length
  w.f32(angle); w.f32(speed); w.u16(sim.frames.length)
  for (let i = 0; i < dieCount; i++) { w.u16(ms(sim.launch[i])); w.u16(ms(sim.firstImpact[i])) }
  w.u16(sim.impacts.length)
  for (const im of sim.impacts) {
    w.u16(ms(im.t)); w.u8(im.die); w.u8(im.kind); w.u8(Math.max(0, Math.min(255, Math.round(im.v * 10)))); w.u8(0)
  }
  for (const frame of sim.frames) {
    for (const [x, y, z, qx, qy, qz, qw] of frame) {
      w.i16(clampI16(x * 1000)); w.i16(clampI16(y * 1000)); w.i16(clampI16(z * 1000))
      const l = Math.hypot(qx, qy, qz, qw) || 1
      w.i16(clampI16((qx / l) * 32767)); w.i16(clampI16((qy / l) * 32767))
      w.i16(clampI16((qz / l) * 32767)); w.i16(clampI16((qw / l) * 32767))
    }
  }
}

const w = new Writer()
w.str('HXDT'); w.u16(1); w.u16(FPS); w.u16(2)

const throws = []
for (const angle of ANGLES) for (const speed of SPEEDS) for (let v = 0; v < VARIANTS; v++) {
  throws.push({ angle, speed, sim: roundThrow(angle, speed) })
}
w.u8(4); w.u16(throws.length)
for (const t of throws) writeClip(w, t.sim, t.angle, t.speed)

const hops = Array.from({ length: HOPS }, () => hop())
w.u8(1); w.u16(hops.length)
for (const h of hops) writeClip(w, h, 0, 0)

const bytes = w.done()
mkdirSync(OUT_DIR, { recursive: true })
writeFileSync(resolve(OUT_DIR, 'dice-throws.bin'), bytes)
writeFileSync(resolve(OUT_DIR, 'Contents.json'), JSON.stringify({
  data: [{ filename: 'dice-throws.bin', idiom: 'universal', 'universal-type-identifier': 'public.data' }],
  info: { author: 'xcode', version: 1 },
}, null, 2) + '\n')

const durations = throws.map((t) => (t.sim.frames.length - 1) / FPS)
console.log(JSON.stringify({
  throws: throws.length,
  hops: hops.length,
  bytes: bytes.length,
  throwSeconds: { min: Math.min(...durations).toFixed(2), max: Math.max(...durations).toFixed(2) },
  out: OUT_DIR,
}, null, 2))
