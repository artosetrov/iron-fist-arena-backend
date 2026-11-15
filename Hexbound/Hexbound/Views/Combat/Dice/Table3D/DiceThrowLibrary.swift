//
//  DiceThrowLibrary.swift
//  Hexbound
//
//  Baked dice throws for the 3D table. The physics ran once, offline
//  (scripts/dice-throws/generate.mjs); on device a throw is only played back,
//  so it looks the same on every iPhone and never decides a face — the
//  server does (DiceCube.correction turns the cube to show it).
//  Data: Assets.xcassets/dice-throws.dataset. Format in generate.mjs.
//

import Foundation
import UIKit
import simd

struct DiceThrowClip {
    struct Impact {
        enum Kind: UInt8 { case felt = 0, rim = 1, die = 2 }
        let t: Float
        let die: Int
        let kind: Kind
        /// Impact speed, table units / s.
        let strength: Float
    }

    let dieCount: Int
    let fps: Float
    let angle: Float
    let speed: Float
    /// When each die leaves the table / hand, seconds.
    let launch: [Float]
    /// First impact after launch, seconds — the cube correction finishes before it.
    let firstImpact: [Float]
    let impacts: [Impact]
    /// `positions[frame * dieCount + die]`
    let positions: [SIMD3<Float>]
    let rotations: [simd_quatf]

    var frameCount: Int { positions.count / max(1, dieCount) }
    var duration: Float { Float(max(0, frameCount - 1)) / fps }

    func pose(die: Int, at t: Float) -> (position: SIMD3<Float>, rotation: simd_quatf) {
        let f = max(0, min(Float(frameCount - 1), t * fps))
        let i0 = Int(f)
        let i1 = min(i0 + 1, frameCount - 1)
        let a = f - Float(i0)
        let p = simd_mix(positions[i0 * dieCount + die], positions[i1 * dieCount + die], SIMD3<Float>(repeating: a))
        let q = simd_slerp(rotations[i0 * dieCount + die], rotations[i1 * dieCount + die], a)
        return (p, q)
    }

    func finalRotation(die: Int) -> simd_quatf { rotations[(frameCount - 1) * dieCount + die] }

    /// The same throw reflected across the table's long axis. Your attack and
    /// guard swap tracks (and so do the enemy's), so every die stays on its side.
    func mirrored() -> DiceThrowClip {
        let swap: (Int) -> Int = { d in dieCount == 4 ? d ^ 1 : d }
        var pos = positions, rot = rotations
        for f in 0..<frameCount {
            for d in 0..<dieCount {
                let src = f * dieCount + swap(d)
                let p = positions[src]
                pos[f * dieCount + d] = SIMD3(-p.x, p.y, p.z)
                rot[f * dieCount + d] = DiceCube.mirrored(rotations[src])
            }
        }
        return DiceThrowClip(
            dieCount: dieCount, fps: fps, angle: -angle, speed: speed,
            launch: (0..<dieCount).map { launch[swap($0)] },
            firstImpact: (0..<dieCount).map { firstImpact[swap($0)] },
            impacts: impacts.map { Impact(t: $0.t, die: swap($0.die), kind: $0.kind, strength: $0.strength) },
            positions: pos, rotations: rot
        )
    }

    /// The same clip moved on the table (hops are baked at the origin).
    func translated(by offset: SIMD3<Float>) -> DiceThrowClip {
        DiceThrowClip(dieCount: dieCount, fps: fps, angle: angle, speed: speed,
                      launch: launch, firstImpact: firstImpact, impacts: impacts,
                      positions: positions.map { $0 + offset }, rotations: rotations)
    }
}

@MainActor
final class DiceThrowLibrary {
    static let shared = DiceThrowLibrary()

    private(set) var throwClips: [DiceThrowClip] = []
    private(set) var hopClips: [DiceThrowClip] = []
    private var loaded = false

    /// Angles / speeds the round throws were baked at (generate.mjs).
    static let maxAngle: Float = 35
    static let speedRange: ClosedRange<Float> = 5...12.5

    private init() {}

    var isAvailable: Bool { load(); return !throwClips.isEmpty && !hopClips.isEmpty }

    /// Parse the dataset now (≈1 MB) instead of on the first throw.
    func warmUp() { load() }

    /// The baked throw closest to a flick. `angle` in degrees from straight
    /// up the table (−Z) toward the right (+X); negative angles mirror a clip.
    func pickThrow(angle: Float, speed: Float) -> DiceThrowClip? {
        load()
        guard !throwClips.isEmpty else { return nil }
        let a = min(Self.maxAngle, abs(angle))
        let s = min(Self.speedRange.upperBound, max(Self.speedRange.lowerBound, speed))
        let scored = throwClips.map { clip -> (DiceThrowClip, Float) in
            let da = (clip.angle - a) / 7, ds = (clip.speed - s) / 1.5
            return (clip, da * da + ds * ds)
        }
        let best = scored.map { $0.1 }.min() ?? 0
        let near = scored.filter { $0.1 <= best + 0.01 }.map { $0.0 }
        guard let clip = near.randomElement() else { return nil }
        return angle < 0 ? clip.mirrored() : clip
    }

    func randomHop() -> DiceThrowClip? {
        load()
        return hopClips.randomElement()
    }

    // MARK: - Parsing

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let asset = NSDataAsset(name: "dice-throws") else {
            #if DEBUG
            print("[DiceThrowLibrary] dice-throws dataset missing")
            #endif
            return
        }
        do {
            var r = ByteReader(bytes: [UInt8](asset.data))
            guard try r.ascii(4) == "HXDT", try r.u16() == 1 else { throw ByteReader.Failure.badHeader }
            let fps = try Float(r.u16())
            let sets = try Int(r.u16())
            var parsed: [[DiceThrowClip]] = []
            for _ in 0..<sets {
                let dieCount = try Int(r.u8())
                let count = try Int(r.u16())
                var clips: [DiceThrowClip] = []
                clips.reserveCapacity(count)
                for _ in 0..<count { clips.append(try Self.clip(&r, dieCount: dieCount, fps: fps)) }
                parsed.append(clips)
            }
            throwClips = parsed.first ?? []
            hopClips = parsed.count > 1 ? parsed[1] : []
        } catch {
            #if DEBUG
            print("[DiceThrowLibrary] failed to parse: \(error)")
            #endif
            throwClips = []
            hopClips = []
        }
    }

    private static func clip(_ r: inout ByteReader, dieCount: Int, fps: Float) throws -> DiceThrowClip {
        let angle = try r.f32()
        let speed = try r.f32()
        let frames = try Int(r.u16())
        var launch: [Float] = [], first: [Float] = []
        for _ in 0..<dieCount {
            launch.append(try Float(r.u16()) / 1000)
            first.append(try Float(r.u16()) / 1000)
        }
        let impactCount = try Int(r.u16())
        var impacts: [DiceThrowClip.Impact] = []
        for _ in 0..<impactCount {
            let t = try Float(r.u16()) / 1000
            let die = try Int(r.u8())
            let kind = try DiceThrowClip.Impact.Kind(rawValue: r.u8()) ?? .felt
            let strength = try Float(r.u8()) / 10
            _ = try r.u8()
            impacts.append(.init(t: t, die: min(die, dieCount - 1), kind: kind, strength: strength))
        }
        var positions: [SIMD3<Float>] = []
        var rotations: [simd_quatf] = []
        positions.reserveCapacity(frames * dieCount)
        rotations.reserveCapacity(frames * dieCount)
        for _ in 0..<(frames * dieCount) {
            let x = try Float(r.i16()) / 1000
            let y = try Float(r.i16()) / 1000
            let z = try Float(r.i16()) / 1000
            let qx = try Float(r.i16()) / 32767
            let qy = try Float(r.i16()) / 32767
            let qz = try Float(r.i16()) / 32767
            let qw = try Float(r.i16()) / 32767
            positions.append(SIMD3(x, y, z))
            rotations.append(simd_quatf(ix: qx, iy: qy, iz: qz, r: qw).normalized)
        }
        return DiceThrowClip(dieCount: dieCount, fps: fps, angle: angle, speed: speed,
                             launch: launch, firstImpact: first, impacts: impacts,
                             positions: positions, rotations: rotations)
    }
}

/// Little-endian reader over the dataset bytes.
private struct ByteReader {
    enum Failure: Error { case truncated, badHeader }
    let bytes: [UInt8]
    var offset = 0

    private mutating func take(_ n: Int) throws -> Int {
        guard offset + n <= bytes.count else { throw Failure.truncated }
        defer { offset += n }
        return offset
    }

    mutating func u8() throws -> UInt8 {
        let o = try take(1)
        return bytes[o]
    }

    mutating func u16() throws -> UInt16 {
        let o = try take(2)
        return UInt16(bytes[o]) | UInt16(bytes[o + 1]) << 8
    }

    mutating func i16() throws -> Int16 { try Int16(bitPattern: u16()) }

    mutating func f32() throws -> Float {
        let o = try take(4)
        let bits = UInt32(bytes[o]) | UInt32(bytes[o + 1]) << 8 | UInt32(bytes[o + 2]) << 16 | UInt32(bytes[o + 3]) << 24
        return Float(bitPattern: bits)
    }

    mutating func ascii(_ n: Int) throws -> String {
        let o = try take(n)
        return String(decoding: bytes[o..<(o + n)], as: UTF8.self)
    }
}
