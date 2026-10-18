import SwiftUI

// MARK: - Palette per room type
//
// Light in the Descent is code, never painted into the art (ART_STYLE_GUIDE §1):
// each room type owns one hue that its doorway, aura and loot glow share.

enum DescentStyle {
    /// Main glow of a room type (unknown passages: a cold grey draft).
    static func glow(_ type: DescentRoomType?) -> Color {
        switch type {
        case .combat: DarkFantasyTheme.danger
        case .elite: DarkFantasyTheme.rankGrandmaster
        case .treasure: DarkFantasyTheme.glowTreasure
        case .event: DarkFantasyTheme.rankMaster
        case .camp: DarkFantasyTheme.glowEmber
        case .merchant: DarkFantasyTheme.rankPlatinum
        case .boss: DarkFantasyTheme.glowBlood
        case nil: DarkFantasyTheme.vfxStormFog
        }
    }

    /// Light the doorway throws on the stone around it — warmer than `glow`
    /// so red rooms read as fire, not as pink.
    static func aura(_ type: DescentRoomType?) -> Color {
        switch type {
        case .combat: DarkFantasyTheme.btnOrangeGlow
        case .boss: DarkFantasyTheme.danger
        default: glow(type)
        }
    }

    /// The hot centre of a light source.
    static let core = DarkFantasyTheme.vfxStunGlow

    static func rarityColor(_ rarity: String) -> Color {
        DarkFantasyTheme.rarityColor(for: ItemRarity(rawValue: rarity) ?? .common)
    }

    /// The die face that shows `zone` on the arena dice (`DiceDieView`):
    /// faces 0…5 are head, head, chest, chest, legs, legs on both sides.
    static func zoneFace(_ zone: String) -> Int {
        switch zone {
        case "head": 0
        case "legs": 4
        default: 2
        }
    }

    /// How far a fight's painting is dimmed. Every room is brought down to about
    /// the same depth (`combatLuma`), so the foe is the brightest thing on screen —
    /// as on the arena's dark stage. The pale parchment rooms (the Ossuary, the
    /// treasure vault) need about twice the dim of the dark Warrens.
    static func combatDim(_ asset: String) -> Double {
        guard let luma = DescentGeometry.backdropLuma[asset], luma > 0 else { return 0.55 }
        return min(0.72, max(0.36, 1 - combatLuma / luma))
    }

    static let combatLuma = 0.17
}

// MARK: - Fork geometry
//
// Doorway voids measured on each fork painting (`art/arches.py`), normalised to
// the image (0...1). The imagesets keep the exact crop the measurements were
// taken on, so these stay valid at every scale.

struct DescentArch: Equatable {
    let x0: CGFloat
    let x1: CGFloat
    let y0: CGFloat
    let y1: CGFloat
}

enum DescentGeometry {
    /// Aspect (width / height) of the scene paintings.
    static let sceneAspect: CGFloat = 1290.0 / 1747.0
    static let runeDoorAspect: CGFloat = 1290.0 / 1669.0

    /// Mean luminance (0…1) of each room a fight can happen in, measured on the
    /// @3x JPEG. Re-measure when a painting is regenerated.
    static let backdropLuma: [String: Double] = [
        "rush2-bg-ossuary-hall": 0.467,
        "rush2-bg-ossuary-elite": 0.464,
        "rush2-bg-ossuary-arena": 0.465,
        "rush2-bg-warrens-hall": 0.258,
        "rush2-bg-warrens-elite": 0.308,
        "rush2-bg-warrens-arena": 0.414,
        "rush2-bg-molten-hall": 0.259,
        "rush2-bg-molten-elite": 0.325,
        "rush2-bg-molten-arena": 0.335,
        "rush2-bg-treasure": 0.5,
    ]

    static let archTable: [String: [DescentArch]] = [
        "ossuary-1": [DescentArch(x0: 0.3822, x1: 0.6167, y0: 0.3208, y1: 0.7039)],
        "ossuary-2": [DescentArch(x0: 0.2011, x1: 0.4022, y0: 0.3161, y1: 0.7085), DescentArch(x0: 0.6067, x1: 0.8078, y0: 0.3161, y1: 0.7069)],
        "ossuary-3": [DescentArch(x0: 0.1644, x1: 0.2611, y0: 0.3339, y1: 0.6907), DescentArch(x0: 0.4400, x1: 0.5989, y0: 0.3585, y1: 0.6678), DescentArch(x0: 0.7811, x1: 0.8611, y0: 0.3339, y1: 0.6907)],
        "warrens-1": [DescentArch(x0: 0.3889, x1: 0.6100, y0: 0.4299, y1: 0.7162)],
        "warrens-2": [DescentArch(x0: 0.1922, x1: 0.4089, y0: 0.3084, y1: 0.7170), DescentArch(x0: 0.6067, x1: 0.8156, y0: 0.3084, y1: 0.7203)],
        "warrens-3": [DescentArch(x0: 0.1956, x1: 0.4000, y0: 0.3983, y1: 0.7157), DescentArch(x0: 0.5222, x1: 0.6411, y0: 0.4223, y1: 0.6917), DescentArch(x0: 0.7722, x1: 0.9233, y0: 0.3876, y1: 0.7198)],
        "molten-1": [DescentArch(x0: 0.3744, x1: 0.6244, y0: 0.2947, y1: 0.6897)],
        "molten-2": [DescentArch(x0: 0.2000, x1: 0.4022, y0: 0.3142, y1: 0.7121), DescentArch(x0: 0.6067, x1: 0.8089, y0: 0.3126, y1: 0.7096)],
        "molten-3": [DescentArch(x0: 0.1633, x1: 0.2811, y0: 0.3270, y1: 0.7016), DescentArch(x0: 0.4322, x1: 0.6056, y0: 0.3533, y1: 0.6721), DescentArch(x0: 0.7700, x1: 0.8733, y0: 0.3279, y1: 0.6951)],
    ]

    /// Arch boxes for `count` passages at a depth, falling back to evenly spaced doors.
    static func arches(depthKey: String, count: Int) -> [DescentArch] {
        let n = max(1, min(3, count))
        if let boxes = archTable["\(depthKey)-\(n)"], boxes.count == n { return boxes }
        return (0..<n).map { i in
            let cx = (CGFloat(i) + 0.5) / CGFloat(n)
            return DescentArch(x0: cx - 0.1, x1: cx + 0.1, y0: 0.33, y1: 0.71)
        }
    }

    /// The three rune discs painted on the vault door (`rush2-ev-runedoor`).
    static let runes: [CGPoint] = [CGPoint(x: 0.3056, y: 0.5369), CGPoint(x: 0.5, y: 0.5369), CGPoint(x: 0.6944, y: 0.5369)]
    static let runeRadius: CGFloat = 0.0956

    /// The fire in `rush2-bg-campfire`.
    static let campfire = CGPoint(x: 0.69, y: 0.767)

    /// The intro key art (`rush2-bg-descent-key`): the three depths in one cross-section.
    static let keyArtAspect: CGFloat = 3072.0 / 5504.0
    /// The hero's torch on the key art, normalised.
    static let keyArtTorch = CGPoint(x: 391.0 / 900, y: 145.0 / 1612)
    /// The top of each depth's tier on the key art (normalised height), for its label.
    static let keyArtTiers: [(roman: String, name: String, y: CGFloat)] = [
        ("I", "The Ossuary", 0.195),
        ("II", "Shadow Warrens", 0.44),
        ("III", "Molten Heart", 0.655),
    ]
}

/// Maps normalised painting coordinates into a view that shows the painting
/// aspect-filled (cropped, never letterboxed), anchored on a focus height.
struct DescentSceneMapper {
    let size: CGSize
    let imageRect: CGRect

    init(size: CGSize, aspect: CGFloat = DescentGeometry.sceneAspect, focusY: CGFloat = 0.52) {
        self.size = size
        var w = size.width
        var h = w / aspect
        if h < size.height {
            h = size.height
            w = h * aspect
        }
        let x = (size.width - w) / 2
        // Keep `focusY` of the painting at the centre of the view when cropping vertically.
        let y = min(0, max(size.height - h, size.height / 2 - focusY * h))
        imageRect = CGRect(x: x, y: y, width: w, height: h)
    }

    /// Painting pixels at 900 px width → points. Sizes in the prototype were authored at 900 px.
    var k: CGFloat { imageRect.width / 900 }

    func point(_ p: CGPoint) -> CGPoint {
        CGPoint(x: imageRect.minX + p.x * imageRect.width, y: imageRect.minY + p.y * imageRect.height)
    }

    func rect(_ a: DescentArch) -> CGRect {
        CGRect(
            x: imageRect.minX + a.x0 * imageRect.width,
            y: imageRect.minY + a.y0 * imageRect.height,
            width: (a.x1 - a.x0) * imageRect.width,
            height: (a.y1 - a.y0) * imageRect.height
        )
    }
}

// MARK: - Shapes

/// A round-topped doorway filling its rect (the semicircle spans the full width).
struct DescentArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addRelativeArc(center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r, startAngle: .degrees(180), delta: .degrees(180))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The arch outline without the floor edge — for light that runs along the stone.
struct DescentArchOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addRelativeArc(center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r, startAngle: .degrees(180), delta: .degrees(180))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

/// One side of the arch, from the floor up to the keystone — the rune thread's comets run along it.
/// `side` is -1 (left) or 1 (right).
struct DescentArchHalf: Shape {
    var side: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = rect.width / 2
        let x = side < 0 ? rect.minX : rect.maxX
        p.move(to: CGPoint(x: x, y: rect.maxY))
        p.addLine(to: CGPoint(x: x, y: rect.minY + r))
        p.addRelativeArc(
            center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r,
            startAngle: .degrees(side < 0 ? 180 : 0), delta: .degrees(side < 0 ? 90 : -90)
        )
        return p
    }
}

/// A ray of light: narrow where it enters at the top, wide where it lands.
struct DescentShaftShape: Shape {
    var topHalf: CGFloat
    var bottomHalf: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - topHalf, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + topHalf, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + bottomHalf, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - bottomHalf, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A plate with cut corners: the Descent's choice rows and the torch button.
struct DescentChamferShape: InsettableShape {
    var chamfer: CGFloat = 12
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        // Keep the cut at 45° while shrinking: an inset of d moves a corner cut in by d·(√2 − 1).
        let c = max(0, min(chamfer - insetAmount * 0.414, min(r.width, r.height) / 2))
        var p = Path()
        p.move(to: CGPoint(x: r.minX + c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + c))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + c, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - c))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> DescentChamferShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

/// A banner tag with a pointed right end (depth labels on the key art).
struct DescentPennantShape: Shape {
    func path(in rect: CGRect) -> Path {
        let point = min(9, rect.height / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - point, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - point, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A small solid triangle pointing right; rotate it for other directions.
struct DescentTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Everything except the doorway: masks auras so they light the stone, never the void.
struct DescentOutsideArch: Shape {
    let arch: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path(rect.insetBy(dx: -400, dy: -400))
        p.addPath(DescentArchShape().path(in: arch))
        return p
    }
}

/// An angry almond eye, drawn around the pair's centre. `side` is -1 (left) or 1 (right);
/// `open` 0...1 closes it into a slit for the blink.
struct DescentEyeShape: Shape {
    var side: CGFloat
    var sep: CGFloat
    var width: CGFloat
    var height: CGFloat
    var open: CGFloat

    var animatableData: CGFloat {
        get { open }
        set { open = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let eh = height * max(0.06, open)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + side * x, y: c.y + y) }
        var p = Path()
        p.move(to: pt(sep + width, -eh * 0.2))
        p.addQuadCurve(to: pt(sep - width * 0.6, eh * 0.9), control: pt(sep + width * 0.35, -eh * 1.6))
        p.addQuadCurve(to: pt(sep + width, -eh * 0.2), control: pt(sep + width * 0.3, eh * 1.1))
        p.closeSubpath()
        return p
    }
}

/// A four-point glint.
struct DescentStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let a = r * 0.22
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x + a, y: c.y - a))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x + a, y: c.y + a))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r))
        p.addLine(to: CGPoint(x: c.x - a, y: c.y + a))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        p.addLine(to: CGPoint(x: c.x - a, y: c.y - a))
        p.closeSubpath()
        return p
    }
}

/// Deterministic pseudo-random numbers so particles keep their places between frames.
struct DescentRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15 &+ 0xD1B5_4A32_D192_ED03
    }

    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat((state >> 33) & 0xFFFFFF) / CGFloat(0x1000000)
    }
}
