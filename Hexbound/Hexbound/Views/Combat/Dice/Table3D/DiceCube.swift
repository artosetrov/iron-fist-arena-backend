//
//  DiceCube.swift
//  Hexbound
//
//  Cube math for the 3D dice table: where each server face sits on the cube,
//  the 24 rotations that map a cube onto itself, and the "server face lands
//  on top" correction. Pure simd — no RealityKit, no UI.
//  Spec: docs/06_game_systems/DICE_3D_THROW.md §2.
//

import simd

enum DiceCube {

    /// Die edge in table units (the felt is 4.1 × 6.1).
    static let edge: Float = 0.8
    static let half: Float = edge / 2

    /// Outward normal of each geometry face, die-local.
    static let normals: [SIMD3<Float>] = [
        [1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1],
    ]

    /// Where the face art's "up" points on each geometry face, die-local.
    static let ups: [SIMD3<Float>] = [
        [0, 1, 0], [0, 1, 0], [0, 0, -1], [0, 0, 1], [0, 1, 0], [0, 1, 0],
    ]

    /// Server face 0…5 (head, head, chest, chest, legs, legs) → geometry face.
    /// Each zone sits on two faces that are never opposite each other.
    static let geoFace: [Int] = [0, 5, 1, 2, 3, 4]

    /// Geometry face → server face (inverse of `geoFace`).
    static let serverFace: [Int] = [0, 2, 3, 4, 5, 1]

    /// The 24 rotations that map the cube onto itself (signed permutation
    /// matrices with determinant +1).
    static let rotations: [simd_quatf] = {
        var out: [simd_quatf] = []
        let perms = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
        for p in perms {
            for s in 0..<8 {
                var rows = [SIMD3<Float>](repeating: .zero, count: 3)
                for r in 0..<3 { rows[r][p[r]] = (s >> r) & 1 == 1 ? -1 : 1 }
                let m = simd_float3x3(rows[0], rows[1], rows[2]).transpose
                if m.determinant > 0 { out.append(simd_quatf(m).normalized) }
            }
        }
        return out
    }()

    /// Geometry face pointing up for a die with this orientation.
    static func landedFace(_ q: simd_quatf) -> Int {
        var best: Float = -2
        var face = 0
        for i in 0..<6 {
            let y = q.act(normals[i]).y
            if y > best { best = y; face = i }
        }
        return face
    }

    /// The cube symmetry `C` to apply inside the physics box
    /// (`q_visual = q_body · C`) so that `targetGeo` is the face on top when
    /// the body rests at `final`. Of the four that work, picks the one whose
    /// art reads most upright for a player looking down the table (−Z).
    static func correction(final: simd_quatf, targetGeo: Int) -> simd_quatf {
        let landed = normals[landedFace(final)]
        var best = simd_quatf(angle: 0, axis: [0, 1, 0])
        var bestScore: Float = -9
        for r in rotations {
            guard simd_dot(r.act(normals[targetGeo]), landed) > 0.99 else { continue }
            let up = final.act(r.act(ups[targetGeo]))
            if -up.z > bestScore { bestScore = -up.z; best = r }
        }
        return best
    }

    /// Orientation of a die lying with `geo` on top and its art upright for
    /// the player, optionally turned by `yaw` around the vertical.
    static func upright(geo: Int, yaw: Float = 0) -> simd_quatf {
        let n = normals[geo], u = ups[geo], r = simd_cross(u, n)
        let local = simd_float3x3(r, u, n)                         // columns
        let world = simd_float3x3([1, 0, 0], [0, 0, -1], [0, 1, 0]) // right, art-up, normal
        var q = simd_quatf(world * local.transpose)
        if yaw != 0 { q = simd_quatf(angle: yaw, axis: [0, 1, 0]) * q }
        return q.normalized
    }

    /// Orientation of the art plane on a geometry face (plane faces +Z, art up +Y).
    static func decalRotation(geo: Int) -> simd_quatf {
        let n = normals[geo], u = ups[geo]
        return simd_quatf(simd_float3x3(simd_cross(u, n), u, n)).normalized
    }

    /// Mirror of a rotation across the table's long axis (x → −x).
    static func mirrored(_ q: simd_quatf) -> simd_quatf {
        simd_quatf(ix: q.imag.x, iy: -q.imag.y, iz: -q.imag.z, r: q.real)
    }

    static func smoothstep(_ x: Float) -> Float {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }
}
