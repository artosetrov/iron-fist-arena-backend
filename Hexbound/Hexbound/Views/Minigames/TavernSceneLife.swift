import SwiftUI

// MARK: - Living Tavern (v2)
//
// Everything that moves in the tavern scene. The art is one illustration
// (`bg-tavern`) with the hosts painted in; this file drives the layers on top:
//   • candle light: an additive light pass split into five zones, each with its own flicker
//   • blinks for the four hosts with faces (opacity swap of a closed-eyes patch)
//   • the Trickster's coin, the game's own Wheel of Fortune behind Fortuna,
//     the crystal ball's swirl, candle flames and gold glints
//   • hands cut from the painting: the Trickster throws the coin, the Veteran beats
//     his fist over the map, Fortuna weaves over the ball, the barkeep polishes a tankard
//   • a draught now and then: the hanging props swing, the flames bend, smoke lifts
//   • a spider that drops from the cobweb (tap it and it runs back up)
//   • a reaction per host when the player taps them
// Coordinates are background pixels (1536 × 2752). Art pipeline, job ids and the
// web prototype: project doc TAVERN_LIVING_SCENE_2026-11-15.
//
// Motion rules (Hexbound/CLAUDE.md): no scaleEffect animation — parts move by
// offset, rotation and opacity; the coin flip is a rotation3DEffect. The scene
// clock is paused while the view is off screen, and Reduce Motion freezes idle life.

// MARK: - Art placement

enum TavernLightZoneID: String, CaseIterable {
    case chandelier, wallCandle, table, ball, floor
}

enum TavernBlinker: String, CaseIterable {
    case trickster, veteran, miner, fortuna
}

enum TavernGlintGroup: CaseIterable {
    case ore, shield, helmet, tankard, coins, tokens
}

/// Who a tap belongs to. The keeper behind the bar has no section of his own.
enum TavernTapTarget: Equatable {
    case chest, shell, wheel, rush, mine, keeper
}

/// A piece cut out of the painting that turns about a pivot. The painting under each
/// piece is a clean plate, so a turned piece never shows a double.
enum TavernPart: String, CaseIterable {
    // hanging props, swung by the draught (drawn first: they hang behind everyone)
    case medal, pennant, hookChain, chandelier, morningStar
    // hands
    case trickHand, veteranHand, fortunaLeftHand, fortunaRightHand, keeperHand

    static let props: [TavernPart] = [.medal, .pennant, .hookChain, .chandelier, .morningStar]
    static let hands: [TavernPart] = [.trickHand, .veteranHand, .fortunaLeftHand, .fortunaRightHand, .keeperHand]
}

struct TavernPartArt {
    let asset: String
    /// Where the piece sits at rest, in background pixels.
    let frame: CGRect
    /// Wrist, elbow or hanging point, in background pixels.
    let pivot: CGPoint

    /// The pivot as an anchor inside `frame`, for `rotationEffect(_:anchor:)`.
    var anchor: UnitPoint {
        UnitPoint(x: (pivot.x - frame.minX) / frame.width, y: (pivot.y - frame.minY) / frame.height)
    }
}

/// Turn and nudge for one part in one frame (radians, background pixels).
struct TavernPose {
    var angle: Double = 0
    var dx: CGFloat = 0
    var dy: CGFloat = 0

    static let rest = TavernPose()

    /// Where a point that rides on the part (the coin on the Trickster's fist) ends up.
    func carry(_ p: CGPoint, about pivot: CGPoint) -> CGPoint {
        let c = CGFloat(cos(angle)), s = CGFloat(sin(angle))
        let vx = p.x - pivot.x, vy = p.y - pivot.y
        return CGPoint(x: pivot.x + vx * c - vy * s + dx, y: pivot.y + vx * s + vy * c + dy)
    }
}

struct TavernSprite: Identifiable {
    let id: String
    let asset: String
    let frame: CGRect
}

enum TavernSceneArt {
    static let size = CGSize(width: 1536, height: 2752)

    /// Additive candle light (`max(lit − base, 0)`), stored at half resolution: it is soft enough
    /// that nobody can tell, and it keeps the five layers at ~8 MB decoded instead of ~33 MB.
    static let lightZones: [TavernLightZoneID: CGRect] = [
        .chandelier: CGRect(x: 71, y: 0, width: 1395, height: 1256),
        .wallCandle: CGRect(x: 70, y: 0, width: 1068, height: 1579),
        .table: CGRect(x: 71, y: 591, width: 1394, height: 2115),
        .ball: CGRect(x: 864, y: 1020, width: 529, height: 594),
        .floor: CGRect(x: 71, y: 1680, width: 1394, height: 1072),
    ]

    static func lightAsset(_ zone: TavernLightZoneID) -> String {
        switch zone {
        case .chandelier: return "tavern-light-chandelier"
        case .wallCandle: return "tavern-light-wallcandle"
        case .table: return "tavern-light-table"
        case .ball: return "tavern-light-ball"
        case .floor: return "tavern-light-floor"
        }
    }

    static let blinks: [TavernBlinker: CGRect] = [
        .trickster: CGRect(x: 384, y: 1625, width: 89, height: 59),
        .veteran: CGRect(x: 810, y: 1618, width: 59, height: 49),
        .miner: CGRect(x: 1120, y: 1630, width: 105, height: 57),
        .fortuna: CGRect(x: 1100, y: 1076, width: 93, height: 53),
    ]

    static func blinkAsset(_ host: TavernBlinker) -> String { "tavern-blink-\(host.rawValue)" }

    /// The wall behind Fortuna is painted empty; the minigame's own wheel hangs there in code.
    static let wheelCenter = CGPoint(x: 1232, y: 935)
    static let wheelRadius: CGFloat = 150
    static let pointerSize = CGSize(width: 23, height: 62)
    /// Fortuna's head and shoulders, cut from the same painting, drawn in front of the wheel.
    static let fortunaFront = CGRect(x: 1040, y: 880, width: 420, height: 295)

    /// Where the coin rests on the Trickster's fist when the hand is at rest.
    static let coinRest = CGPoint(x: 540, y: 1686)
    static let coinSize: CGFloat = 32

    static func part(_ part: TavernPart) -> TavernPartArt {
        switch part {
        case .medal:
            return TavernPartArt(asset: "tavern-part-medal", frame: CGRect(x: 172, y: 936, width: 74, height: 146), pivot: CGPoint(x: 208, y: 938))
        case .pennant:
            return TavernPartArt(asset: "tavern-part-pennant", frame: CGRect(x: 260, y: 895, width: 97, height: 206), pivot: CGPoint(x: 316, y: 900))
        case .hookChain:
            return TavernPartArt(asset: "tavern-part-hook-chain", frame: CGRect(x: 484, y: 247, width: 52, height: 326), pivot: CGPoint(x: 510, y: 252))
        case .chandelier:
            return TavernPartArt(asset: "tavern-part-chandelier", frame: CGRect(x: 595, y: 295, width: 380, height: 280), pivot: CGPoint(x: 791, y: 300))
        case .morningStar:
            return TavernPartArt(asset: "tavern-part-morning-star", frame: CGRect(x: 1020, y: 247, width: 165, height: 406), pivot: CGPoint(x: 1100, y: 256))
        case .trickHand:
            return TavernPartArt(asset: "tavern-part-hand-trickster", frame: CGRect(x: 502, y: 1676, width: 88, height: 183), pivot: CGPoint(x: 527, y: 1840))
        case .veteranHand:
            return TavernPartArt(asset: "tavern-part-hand-veteran", frame: CGRect(x: 870, y: 1704, width: 85, height: 130), pivot: CGPoint(x: 887, y: 1820))
        case .fortunaLeftHand:
            return TavernPartArt(asset: "tavern-part-hand-fortuna-left", frame: CGRect(x: 993, y: 1221, width: 100, height: 74), pivot: CGPoint(x: 1077, y: 1275))
        case .fortunaRightHand:
            return TavernPartArt(asset: "tavern-part-hand-fortuna-right", frame: CGRect(x: 1116, y: 1256, width: 138, height: 64), pivot: CGPoint(x: 1240, y: 1280))
        case .keeperHand:
            return TavernPartArt(asset: "tavern-part-hand-keeper", frame: CGRect(x: 492, y: 921, width: 109, height: 114), pivot: CGPoint(x: 502, y: 967))
        }
    }

    /// The spider hangs from the top-left cobweb, along the thread painted there.
    static let spiderAnchor = CGPoint(x: 391, y: 336)
    static let spiderSize = CGSize(width: 56, height: 63)
    /// Its thread meets the sprite this far below the sprite's top edge.
    static let spiderThreadInset: CGFloat = 4

    static let ballCenter = CGPoint(x: 1112, y: 1347)
    static let ballRadius: CGFloat = 27

    /// Painted flames on the chandelier and the wall candle; code adds a living wobble on top.
    /// The first `chandelierFlameCount` sit on the chandelier and swing with it.
    static let chandelierFlameCount = 7
    static let flames: [CGPoint] = [
        CGPoint(x: 620, y: 452), CGPoint(x: 683, y: 428), CGPoint(x: 789, y: 431), CGPoint(x: 894, y: 431),
        CGPoint(x: 959, y: 452), CGPoint(x: 717, y: 476), CGPoint(x: 858, y: 476), CGPoint(x: 377, y: 728),
    ]

    static let glintPoints: [TavernGlintGroup: [CGPoint]] = [
        .ore: [CGPoint(x: 1060, y: 2030), CGPoint(x: 1120, y: 2008), CGPoint(x: 1190, y: 2042), CGPoint(x: 1150, y: 2050)],
        .shield: [CGPoint(x: 226, y: 780), CGPoint(x: 190, y: 830)],
        .helmet: [CGPoint(x: 329, y: 1421)],
        .tankard: [CGPoint(x: 600, y: 962)],
        .coins: [CGPoint(x: 495, y: 1995), CGPoint(x: 470, y: 2010)],
        .tokens: [CGPoint(x: 601, y: 2037), CGPoint(x: 696, y: 2048)],
    ]

    /// Centre of the warm press-glow for each target.
    static let pressGlow: [TavernTapTarget: (center: CGPoint, radius: CGFloat)] = [
        .chest: (CGPoint(x: 260, y: 1150), 300),
        .shell: (CGPoint(x: 390, y: 1800), 260),
        .wheel: (CGPoint(x: 1200, y: 1100), 300),
        .rush: (CGPoint(x: 790, y: 1780), 230),
        .mine: (CGPoint(x: 1210, y: 1800), 260),
        .keeper: (CGPoint(x: 590, y: 880), 170),
    ]
}

// MARK: - Timing

/// Effect parameters for the scene clock (seconds and background pixels).
/// These are scene-simulation values, not UI transitions, so they live here
/// rather than in MotionConstants.
enum TavernLifeTiming {
    static let frameInterval: Double = 1.0 / 30.0

    static let blinkRamp: Double = 0.045
    static let blinkHold: Double = 0.13
    static let winkHold: Double = 0.45
    static let blinkGap: ClosedRange<Double> = 3.5...8
    static let doubleBlinkChance: Double = 0.15
    static let doubleBlinkGap: Double = 0.32

    static let coinGap: ClosedRange<Double> = 4...8
    static let coinFlip: (duration: Double, height: CGFloat, turns: Double) = (0.78, 85, 3)
    static let coinToss: (duration: Double, height: CGFloat, turns: Double) = (1.05, 150, 4)
    /// A toss: the fist cocks back, flicks (the coin leaves), and dips when it catches the coin.
    static let tossWindUp: Double = 0.2
    static let tossFlick: Double = 0.12
    static let tossCatch: Double = 0.3

    // Hands (degrees, background pixels, seconds)
    static let veteranBeatFirst: ClosedRange<Double> = 3...6
    static let veteranBeatGap: ClosedRange<Double> = 5...9
    static let veteranBeat: Double = 0.4
    static let fortunaWeaveSpeed: Double = 2.25
    static let keeperWipeFirst: ClosedRange<Double> = 1.5...4
    static let keeperWipeGap: ClosedRange<Double> = 3.5...7
    static let keeperWipe: Double = 1.8
    static let keeperWipeRate: Double = 2.6

    // Draught
    static let gustFirst: ClosedRange<Double> = 5...9
    static let gustGap: ClosedRange<Double> = 12...22
    /// How long the flames duck and lean while the gust passes.
    static let gustBreath: Double = 1.2
    static let gustFlameLean: CGFloat = 7
    static let smokeDelay: Double = 0.35
    static let smokeLife: Double = 2.4

    /// Per prop: idle sway (amplitude °, period s) and the gust's push
    /// (delay s, amplitude °, period s, decay s). Negative = the bottom swings right, with the wind.
    static func swing(_ part: TavernPart) -> (idle: (amp: Double, period: Double), gust: (delay: Double, amp: Double, period: Double, decay: Double)) {
        switch part {
        case .medal: return ((0.5, 2.3), (0.00, -6.0, 1.0, 1.3))
        case .pennant: return ((0.6, 2.7), (0.08, -5.0, 1.3, 1.6))
        case .hookChain: return ((0.4, 3.3), (0.25, -3.5, 1.9, 2.5))
        case .chandelier: return ((0.25, 5.3), (0.35, -1.8, 2.8, 3.2))
        case .morningStar: return ((0.5, 3.9), (0.55, -3.5, 2.3, 2.8))
        default: return ((0, 1), (0, 0, 1, 1))
        }
    }

    // Spider
    static let spiderFirst: ClosedRange<Double> = 6...11
    static let spiderGap: ClosedRange<Double> = 15...30
    static let spiderDrop: Double = 1.8
    static let spiderDepth: ClosedRange<CGFloat> = 105...150
    static let spiderHang: ClosedRange<Double> = 2.2...3.6
    static let spiderClimb: Double = 2.2
    static let spiderFlee: Double = 0.55
    /// Taps within this radius of the spider's body scare it off.
    static let spiderTouchRadius: CGFloat = 60

    static let wheelNudgeGap: ClosedRange<Double> = 6...11
    static let wheelNudge: Double = 1.4
    static let wheelSpin: Double = 3.2

    static let glintGap: ClosedRange<Double> = 2.2...4.5
    static let glintLife: ClosedRange<Double> = 0.5...0.8
    static let ballFlare: Double = 1.6

    /// A tap shows the host's reaction for this long before the section opens.
    static let reactionLead: Double = 0.4

    static let steadyLight: Double = 0.85
}

// MARK: - Frame snapshot

struct TavernGlint {
    let point: CGPoint
    let size: CGFloat
    let alpha: Double
}

struct TavernSmokePuff {
    let center: CGPoint
    let radius: CGFloat
    let alpha: Double
}

struct TavernSpiderState {
    /// Where the thread meets the spider, in background pixels.
    let hang: CGPoint
    let angle: Double
    let alpha: Double
}

/// Everything the view needs for one frame, computed by `TavernLife` from the scene clock.
struct TavernLifeFrame {
    var time: Double = 0
    var light: [TavernLightZoneID: Double] = [:]
    var blink: [TavernBlinker: Double] = [:]
    var parts: [TavernPart: TavernPose] = [:]
    /// The coin's centre, riding on the Trickster's fist while it rests.
    var coinCenter: CGPoint = TavernSceneArt.coinRest
    var coinTurnDegrees: Double = 0
    /// Downwind lean of the flames while a gust passes, chandelier and wall candle.
    var chandelierLean: CGFloat = 0
    var wallCandleLean: CGFloat = 0
    var smoke: [TavernSmokePuff] = []
    var spider: TavernSpiderState?
    var wheelAngle: Double = 0
    var pointerTilt: Double = 0
    var ballFlare: Double = 0
    var ballSwirl: Double = 0
    var flamesLit: Bool = true
    var flamesMove: Bool = true
    var glints: [TavernGlint] = []
}

// MARK: - Scene clock

/// Plain reference type, not observable: TimelineView drives redraws, and the
/// schedules below are advanced while a frame is computed (no view invalidation).
/// Owned by the view's @State and only touched from the view, so it is not actor-isolated.
final class TavernLife {
    let epoch = Date.timeIntervalSinceReferenceDate

    func now() -> Double { Date.timeIntervalSinceReferenceDate - epoch }

    // Blinks
    private struct Blink { var next: Double; var start: Double = -1; var hold: Double = TavernLifeTiming.blinkHold; var wink = false }
    private var blinks: [TavernBlinker: Blink] = Dictionary(uniqueKeysWithValues: TavernBlinker.allCases.map {
        ($0, Blink(next: Double.random(in: 1...5)))
    })

    // Coin
    private var coinNext = Double.random(in: 2.5...5)
    private var coinStart: Double = -1
    private var coinMove = TavernLifeTiming.coinFlip

    // Wheel
    private let sector = Double.pi * 2 / 12
    private var wheelAngle = Double.random(in: 0..<(Double.pi * 2))
    private var wheelFrom = 0.0
    private var wheelTo = 0.0
    private var wheelStart: Double = -1
    private var wheelDuration = TavernLifeTiming.wheelNudge
    private var wheelNext = Double.random(in: 4...8)

    // Light
    private struct Draught { var next: Double; var until: Double = 0; var depth: Double = 0 }
    private var chandelierDraught = Draught(next: Double.random(in: 3...8))
    private var wallDraught = Draught(next: Double.random(in: 2...6))
    private var ballFlareStart: Double = -10

    // Glints
    private struct Glint { let point: CGPoint; let start: Double; let life: Double; let size: CGFloat }
    private var glints: [Glint] = []
    private var glintNext = Double.random(in: 2...4)

    // Hands
    private var veteranBeatStart: Double = -1
    private var veteranBeats = 3
    private var veteranBeatNext = Double.random(in: TavernLifeTiming.veteranBeatFirst)
    private var fortunaPhase = Double.random(in: 0...6)
    private var fortunaLast: Double = 0
    private var wipeStart: Double = -1
    private var wipeNext = Double.random(in: TavernLifeTiming.keeperWipeFirst)

    // Draught
    private var gustStart: Double = -100
    private var gustNext = Double.random(in: TavernLifeTiming.gustFirst)
    private struct Smoke { let flame: Int; let start: Double }
    private var smokes: [Smoke] = []

    // Spider
    private var spiderStart: Double = -1
    private var spiderNext = Double.random(in: TavernLifeTiming.spiderFirst)
    private var spiderDepth: CGFloat = 130
    private var spiderHangTime: Double = 3
    private var spiderClimbTime = TavernLifeTiming.spiderClimb
    private var spiderFleeing = false
    private var lastSpider: TavernSpiderState?

    // MARK: Frame

    func frame(at t: Double, reduceMotion: Bool, lightOn: Bool = true) -> TavernLifeFrame {
        var f = TavernLifeFrame()
        f.time = t
        gustTick(t, reduceMotion: reduceMotion)
        f.light = lightLevels(t, reduceMotion: reduceMotion)
        for host in TavernBlinker.allCases { f.blink[host] = blinkAlpha(host, t, reduceMotion: reduceMotion) }

        let wheel = wheelState(t, reduceMotion: reduceMotion)
        f.wheelAngle = wheel.angle; f.pointerTilt = wheel.tilt

        f.ballFlare = max(0, 1 - (t - ballFlareStart) / TavernLifeTiming.ballFlare)
        f.ballSwirl = reduceMotion ? 0 : t * (0.6 + f.ballFlare * 4)
        f.flamesLit = lightOn
        f.flamesMove = !reduceMotion

        for part in TavernPart.props { f.parts[part] = TavernPose(angle: propAngle(part, t, reduceMotion: reduceMotion)) }
        f.chandelierLean = TavernLifeTiming.gustFlameLean * CGFloat(gustBreath(t, delay: 0.3))
        f.wallCandleLean = TavernLifeTiming.gustFlameLean * CGFloat(gustBreath(t, delay: 0))
        f.smoke = smokePuffs(t, chandelier: f.parts[.chandelier] ?? .rest)

        if !reduceMotion && coinStart < 0 && t >= coinNext { toss(at: t, move: TavernLifeTiming.coinFlip) }
        let trick = trickPose(t, reduceMotion: reduceMotion)
        f.parts[.trickHand] = trick
        let coin = coinState(t, hand: trick)
        f.coinCenter = coin.center; f.coinTurnDegrees = coin.turn
        f.parts[.veteranHand] = veteranPose(t, reduceMotion: reduceMotion)
        let fortuna = fortunaPoses(t, flare: f.ballFlare, reduceMotion: reduceMotion)
        f.parts[.fortunaLeftHand] = fortuna.left
        f.parts[.fortunaRightHand] = fortuna.right
        f.parts[.keeperHand] = keeperPose(t, reduceMotion: reduceMotion)

        f.spider = spiderState(t, reduceMotion: reduceMotion)
        lastSpider = f.spider

        if !reduceMotion && t >= glintNext { idleGlint(t) }
        f.glints = liveGlints(t)
        return f
    }

    // MARK: Reactions

    /// What the host does when tapped. The view handles sound and navigation.
    func react(to target: TavernTapTarget, at t: Double) {
        switch target {
        case .shell:
            wink(.trickster, at: t)
            toss(at: t, move: TavernLifeTiming.coinToss)
            glint(.coins, at: t, stagger: 0.12)
        case .rush:
            wink(.veteran, at: t)
            veteranBeatStart = t
            veteranBeats = 3
            glint(.tokens, at: t, stagger: 0.15)
        case .mine:
            blinks[.miner]?.next = t
            glint(.ore, at: t, stagger: 0.1)
        case .wheel:
            blinks[.fortuna]?.next = t
            ballFlareStart = t
            spinWheel(at: t, full: true)
        case .chest:
            glint(.shield, at: t, stagger: 0.12)
            glint(.helmet, at: t + 0.2, stagger: 0)
        case .keeper:
            wipeStart = t
            glint(.tankard, at: t, stagger: 0)
        }
    }

    /// Sends the spider back up the thread if the tap (background pixels) landed on it.
    /// Returns whether it did, so the tap goes no further.
    func scareSpider(at p: CGPoint, time t: Double) -> Bool {
        guard spiderStart >= 0, !spiderFleeing, let s = lastSpider else { return false }
        let body = CGPoint(x: s.hang.x, y: s.hang.y + TavernSceneArt.spiderSize.height / 2)
        guard hypot(p.x - body.x, p.y - body.y) < TavernLifeTiming.spiderTouchRadius else { return false }
        spiderFleeing = true
        spiderDepth = max(0, s.hang.y - TavernSceneArt.spiderAnchor.y)
        spiderHangTime = 0
        spiderClimbTime = TavernLifeTiming.spiderFlee
        spiderStart = t - TavernLifeTiming.spiderDrop     // straight to the climb, from where it hangs now
        return true
    }

    // MARK: Light

    private func candle(_ t: Double, seed: Double, speed: Double) -> Double {
        sin(t * 1.7 * speed + seed) * 0.09
            + sin(t * 4.3 * speed + seed * 2.1) * 0.06
            + sin(t * 9.1 * speed + seed * 3.7) * 0.035
            + sin(t * 17.3 * speed + seed * 1.3) * 0.015
    }

    /// A rare draught: the flame ducks for a fraction of a second.
    private func draught(_ d: inout Draught, _ t: Double) -> Double {
        if t > d.next {
            d.until = t + Double.random(in: 0.12...0.35)
            d.depth = Double.random(in: 0.08...0.2)
            d.next = t + Double.random(in: 3...9)
        }
        guard t < d.until else { return 0 }
        let k = 1 - abs((d.until - t) / 0.35 - 0.5) * 2
        return d.depth * max(0, k)
    }

    private func lightLevels(_ t: Double, reduceMotion: Bool) -> [TavernLightZoneID: Double] {
        let flare = max(0, 1 - (t - ballFlareStart) / TavernLifeTiming.ballFlare)
        if reduceMotion {
            let s = TavernLifeTiming.steadyLight
            return [.chandelier: s, .wallCandle: s, .table: s, .ball: max(s, flare), .floor: s]
        }
        let duck = draught(&chandelierDraught, t)
        let chandelier = 0.84 + candle(t, seed: 0.7, speed: 1) - duck - 0.22 * gustBreath(t, delay: 0.3)
        let table = 0.84 + candle(t - 0.06, seed: 0.7, speed: 1) * 0.8 - duck * 0.8 - 0.18 * gustBreath(t, delay: 0.34)
        let floor = 0.82 + candle(t - 0.1, seed: 0.7, speed: 1) * 0.7 - duck * 0.6 - 0.12 * gustBreath(t, delay: 0.38)
        let wall = 0.82 + candle(t, seed: 4.1, speed: 1.35) * 1.3 - draught(&wallDraught, t) - 0.2 * gustBreath(t, delay: 0)
        let ball = 0.62 + 0.28 * (0.5 + 0.5 * sin(t * 1.25)) + 0.04 * sin(t * 6.1)
        return [
            .chandelier: clamp(chandelier), .wallCandle: clamp(wall), .table: clamp(table),
            .ball: clamp(max(ball, flare)), .floor: clamp(floor),
        ]
    }

    private func clamp(_ v: Double) -> Double { min(1, max(0, v)) }

    // MARK: Blinks

    private func wink(_ host: TavernBlinker, at t: Double) {
        blinks[host]?.wink = true
        blinks[host]?.start = -1
        blinks[host]?.next = t
    }

    private func blinkAlpha(_ host: TavernBlinker, _ t: Double, reduceMotion: Bool) -> Double {
        guard var b = blinks[host] else { return 0 }
        defer { blinks[host] = b }
        if reduceMotion && !b.wink { return 0 }
        if b.start < 0 && t >= b.next {
            b.start = t
            b.hold = b.wink ? TavernLifeTiming.winkHold : TavernLifeTiming.blinkHold
        }
        guard b.start >= 0 else { return 0 }
        let ramp = TavernLifeTiming.blinkRamp
        let e = t - b.start
        if e > ramp * 2 + b.hold {
            b.start = -1
            b.wink = false
            b.next = t + (Double.random(in: 0...1) < TavernLifeTiming.doubleBlinkChance
                ? TavernLifeTiming.doubleBlinkGap
                : Double.random(in: TavernLifeTiming.blinkGap))
            return 0
        }
        if e < ramp { return e / ramp }
        if e > ramp + b.hold { return 1 - (e - ramp - b.hold) / ramp }
        return 1
    }

    // MARK: Coin

    private func toss(at t: Double, move: (duration: Double, height: CGFloat, turns: Double)) {
        coinStart = t
        coinMove = move
    }

    /// The coin rests on the fist and leaves it at the end of the wind-up.
    private func coinState(_ t: Double, hand: TavernPose) -> (center: CGPoint, turn: Double) {
        let rest = hand.carry(TavernSceneArt.coinRest, about: TavernSceneArt.part(.trickHand).pivot)
        guard coinStart >= 0 else { return (rest, 0) }
        let e = t - coinStart, windUp = TavernLifeTiming.tossWindUp
        if e >= windUp + coinMove.duration + TavernLifeTiming.tossCatch {
            coinStart = -1
            coinNext = t + Double.random(in: TavernLifeTiming.coinGap)
            return (rest, 0)
        }
        let p = (e - windUp) / coinMove.duration
        guard p > 0, p < 1 else { return (rest, 0) }
        let lift = CGFloat(4 * p * (1 - p)) * coinMove.height
        let drift = CGFloat(sin(p * .pi)) * 6
        return (CGPoint(x: rest.x + drift, y: rest.y - lift), p * coinMove.turns * 360)
    }

    // MARK: Hands

    private func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }

    private func smooth(_ p: Double) -> Double {
        let q = min(1, max(0, p))
        return q * q * (3 - 2 * q)
    }

    /// Trickster: an idle fiddle; for a toss the fist cocks back, flicks, then dips on the catch.
    private func trickPose(_ t: Double, reduceMotion: Bool) -> TavernPose {
        let idleAmp = reduceMotion ? 0.0 : 1.0
        let idle = idleAmp * (1.1 * sin(t * 1.85) + 0.4 * sin(t * 4.7))
        guard coinStart >= 0 else {
            return TavernPose(angle: radians(idle), dy: CGFloat(idleAmp * 0.6 * sin(t * 1.85 + 1)))
        }
        let e = t - coinStart
        let windUp = TavernLifeTiming.tossWindUp, flick = TavernLifeTiming.tossFlick, catchTime = TavernLifeTiming.tossCatch
        let land = windUp + coinMove.duration
        var deg = 0.0, dy = 0.0
        if e < windUp {
            let k = smooth(e / windUp); deg = -5 * k; dy = 4 * k
        } else if e < windUp + flick {
            let k = smooth((e - windUp) / flick); deg = -5 + 9 * k; dy = 4 - 7 * k
        } else if e < land {
            let k = smooth((e - windUp - flick) / 0.35); deg = 4 * (1 - k); dy = -3 * (1 - k)
        } else if e < land + catchTime {
            let k = sin((e - land) / catchTime * .pi); deg = 3 * k; dy = 3 * k
        }
        return TavernPose(angle: radians(idle * 0.3 + deg), dy: CGFloat(dy))
    }

    /// Veteran: two or three emphatic fist beats while he tells the story over the map.
    private func veteranPose(_ t: Double, reduceMotion: Bool) -> TavernPose {
        if !reduceMotion && veteranBeatStart < 0 && t >= veteranBeatNext {
            veteranBeatStart = t
            veteranBeats = Bool.random() ? 2 : 3
        }
        var deg = reduceMotion ? 0 : 0.8 * sin(t * 1.5)
        var dy = 0.0
        if veteranBeatStart >= 0 {
            let e = t - veteranBeatStart, beat = TavernLifeTiming.veteranBeat
            if e >= Double(veteranBeats) * beat {
                veteranBeatStart = -1
                veteranBeatNext = t + Double.random(in: TavernLifeTiming.veteranBeatGap)
            } else {
                let k = sin(e.truncatingRemainder(dividingBy: beat) / beat * .pi)
                deg += -6 * k
                dy = 3 * k
            }
        }
        return TavernPose(angle: radians(deg), dy: CGFloat(dy))
    }

    /// Fortuna: both hands weave over the ball, wider and faster (and lifted) while it flares.
    private func fortunaPoses(_ t: Double, flare: Double, reduceMotion: Bool) -> (left: TavernPose, right: TavernPose) {
        guard !reduceMotion else { return (.rest, .rest) }
        let dt = min(0.1, max(0, t - fortunaLast))
        fortunaLast = t
        fortunaPhase += dt * TavernLifeTiming.fortunaWeaveSpeed * (1 + flare * 1.2)
        let a = fortunaPhase, amp = 1 + flare * 1.3, lift = -5 * sin(min(1, flare) * .pi / 2)
        let left = TavernPose(
            angle: radians(2.5 * amp * sin(a)),
            dx: CGFloat(2.2 * amp * sin(a + 1)),
            dy: CGFloat(1.6 * sin(a * 1.3) + lift)
        )
        let right = TavernPose(
            angle: radians(-2.5 * amp * sin(a + 1.9)),
            dx: CGFloat(-2.2 * amp * sin(a + 2.9)),
            dy: CGFloat(1.6 * sin(a * 1.3 + 2) + lift)
        )
        return (left, right)
    }

    /// Barkeep: polishes the tankard in short bursts.
    private func keeperPose(_ t: Double, reduceMotion: Bool) -> TavernPose {
        if !reduceMotion && wipeStart < 0 && t >= wipeNext { wipeStart = t }
        var deg = reduceMotion ? 0 : 0.5 * sin(t * 0.9)
        var dy = 0.0
        if wipeStart >= 0 {
            let e = t - wipeStart, length = TavernLifeTiming.keeperWipe
            if e >= length {
                wipeStart = -1
                wipeNext = t + Double.random(in: TavernLifeTiming.keeperWipeGap)
            } else {
                let envelope = sin(e / length * .pi), w = e * .pi * 2 * TavernLifeTiming.keeperWipeRate
                deg += 4 * envelope * sin(w)
                dy = 2.5 * envelope * cos(w)
            }
        }
        return TavernPose(angle: radians(deg), dy: CGFloat(dy))
    }

    // MARK: Draught

    /// A gust from the door: props swing left to right, flames duck and lean, two candles smoke.
    private func gustTick(_ t: Double, reduceMotion: Bool) {
        guard !reduceMotion, t >= gustNext else { return }
        gustStart = t
        gustNext = t + Double.random(in: TavernLifeTiming.gustGap)
        let candles = Array(0..<TavernSceneArt.chandelierFlameCount).shuffled().prefix(2)
        for (j, i) in candles.enumerated() {
            smokes.append(Smoke(flame: i, start: t + TavernLifeTiming.smokeDelay + Double(j) * 0.25))
        }
    }

    /// 0 → 1 → 0 while the gust passes a spot `delay` seconds downwind.
    private func gustBreath(_ t: Double, delay: Double) -> Double {
        let e = t - gustStart - delay, length = TavernLifeTiming.gustBreath
        return e < 0 || e > length ? 0 : sin(e / length * .pi)
    }

    /// Idle sway plus a damped swing after each gust.
    private func propAngle(_ part: TavernPart, _ t: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 0 }
        let s = TavernLifeTiming.swing(part)
        var deg = s.idle.amp * sin(t * .pi * 2 / s.idle.period + s.idle.period)
        let e = t - gustStart - s.gust.delay
        if e > 0 && e < s.gust.decay * 5 {
            deg += s.gust.amp * exp(-e / s.gust.decay) * sin(e * .pi * 2 / s.gust.period)
        }
        return radians(deg)
    }

    /// One-shot wisps from the candles the gust caught; they rise and drift with the wind.
    private func smokePuffs(_ t: Double, chandelier: TavernPose) -> [TavernSmokePuff] {
        smokes.removeAll { t - $0.start >= TavernLifeTiming.smokeLife }
        let pivot = TavernSceneArt.part(.chandelier).pivot
        var puffs: [TavernSmokePuff] = []
        for s in smokes {
            let p = (t - s.start) / TavernLifeTiming.smokeLife
            guard p >= 0, s.flame < TavernSceneArt.flames.count else { continue }
            let flame = TavernSceneArt.flames[s.flame]
            let origin = chandelier.carry(CGPoint(x: flame.x, y: flame.y - 10), about: pivot)
            for b in 0..<4 {
                let q = p - Double(b) * 0.07
                guard q > 0 else { continue }
                puffs.append(TavernSmokePuff(
                    center: CGPoint(x: origin.x + CGFloat(22 * q + 4 * sin(q * 9 + Double(b))), y: origin.y - CGFloat(75 * q)),
                    radius: CGFloat(4 + 15 * q),
                    alpha: 0.28 * (1 - q) * min(1, q * 8)
                ))
            }
        }
        return puffs
    }

    // MARK: Spider

    /// Drops along its thread, dangles with a little sway, climbs back into the web.
    private func spiderState(_ t: Double, reduceMotion: Bool) -> TavernSpiderState? {
        if !reduceMotion && spiderStart < 0 && t >= spiderNext {
            spiderStart = t
            spiderDepth = CGFloat.random(in: TavernLifeTiming.spiderDepth)
            spiderHangTime = Double.random(in: TavernLifeTiming.spiderHang)
            spiderClimbTime = TavernLifeTiming.spiderClimb
            spiderFleeing = false
        }
        guard spiderStart >= 0 else { return nil }
        let drop = TavernLifeTiming.spiderDrop
        let e = t - spiderStart
        if e >= drop + spiderHangTime + spiderClimbTime {
            spiderStart = -1
            spiderNext = t + Double.random(in: TavernLifeTiming.spiderGap)
            return nil
        }
        var length: CGFloat
        var sway = 0.0
        if e < drop {
            length = spiderDepth * CGFloat(1 - pow(1 - e / drop, 3))
        } else if e < drop + spiderHangTime {
            let h = e - drop
            length = spiderDepth + CGFloat(2 * sin(h * 5))
            sway = 2.5 * sin(h * 2.4) * exp(-h / 3)
        } else {
            let k = (e - drop - spiderHangTime) / spiderClimbTime
            length = spiderDepth * CGFloat(1 - k * k)
        }
        let r = radians(sway), anchor = TavernSceneArt.spiderAnchor
        return TavernSpiderState(
            hang: CGPoint(x: anchor.x + length * CGFloat(sin(r)), y: anchor.y + length * CGFloat(cos(r))),
            angle: -r,
            alpha: Double(min(1, length / 25))
        )
    }

    // MARK: Wheel

    private func spinWheel(at t: Double, full: Bool) {
        wheelFrom = wheelAngle
        wheelStart = t
        if full {
            let turns = Double(Int.random(in: 2...3))
            wheelTo = wheelAngle + .pi * 2 * turns + sector * Double(Int.random(in: 0..<12))
            wheelDuration = TavernLifeTiming.wheelSpin
        } else {
            wheelTo = wheelAngle + sector * Double(Int.random(in: 1...3))
            wheelDuration = TavernLifeTiming.wheelNudge
        }
    }

    private func wheelState(_ t: Double, reduceMotion: Bool) -> (angle: Double, tilt: Double) {
        if !reduceMotion && wheelStart < 0 && t >= wheelNext { spinWheel(at: t, full: false) }
        var speed = 0.0
        if wheelStart >= 0 {
            let p = (t - wheelStart) / wheelDuration
            if p >= 1 {
                wheelAngle = wheelTo
                wheelStart = -1
                wheelNext = t + Double.random(in: TavernLifeTiming.wheelNudgeGap)
            } else {
                let eased = 1 - pow(1 - p, 3)
                wheelAngle = wheelFrom + (wheelTo - wheelFrom) * eased
                speed = 3 * pow(1 - p, 2) * (wheelTo - wheelFrom) / wheelDuration
            }
        }
        // The pointer lifts against each peg as a sector edge passes, harder when the wheel is fast.
        let phase = (wheelAngle.truncatingRemainder(dividingBy: sector) + sector)
            .truncatingRemainder(dividingBy: sector) / sector
        let tilt = min(1, abs(speed) / 4) * max(0, sin(phase * .pi)) * 0.35
        return (wheelAngle, -tilt)
    }

    // MARK: Glints

    private func glint(_ group: TavernGlintGroup, at t: Double, stagger: Double) {
        for (i, p) in (TavernSceneArt.glintPoints[group] ?? []).enumerated() {
            glints.append(Glint(
                point: CGPoint(x: p.x + .random(in: -4...4), y: p.y + .random(in: -4...4)),
                start: t + Double(i) * stagger,
                life: .random(in: TavernLifeTiming.glintLife),
                size: .random(in: 14...22)
            ))
        }
    }

    private func idleGlint(_ t: Double) {
        let group = TavernGlintGroup.allCases.randomElement() ?? .ore
        if let p = TavernSceneArt.glintPoints[group]?.randomElement() {
            glints.append(Glint(point: p, start: t, life: .random(in: 0.55...0.8), size: .random(in: 12...18)))
        }
        glintNext = t + .random(in: TavernLifeTiming.glintGap)
    }

    private func liveGlints(_ t: Double) -> [TavernGlint] {
        glints.removeAll { t - $0.start > $0.life }
        return glints.compactMap { g in
            let p = (t - g.start) / g.life
            guard p >= 0 else { return nil }
            let k = sin(p * .pi)
            return TavernGlint(point: g.point, size: g.size * CGFloat(0.4 + 0.6 * k), alpha: k)
        }
    }
}

// MARK: - Effects canvas

/// Crystal-ball swirl, flame wobble, candle smoke, the spider's silk, gold glints and the
/// tap-only warm glow, drawn additively in background-pixel coordinates (the smoke and silk
/// read as candlelit haze and thread).
struct TavernEffectsCanvas: View {
    let frame: TavernLifeFrame
    let scale: CGFloat
    let pressed: TavernTapTarget?

    var body: some View {
        Canvas { ctx, _ in
            ctx.scaleBy(x: scale, y: scale)
            ctx.blendMode = .plusLighter
            drawBall(&ctx)
            if frame.flamesLit { drawFlames(&ctx) }
            for puff in frame.smoke { drawSmoke(&ctx, puff) }
            if let spider = frame.spider { drawSilk(&ctx, spider) }
            for g in frame.glints { drawGlint(&ctx, g) }
            if let pressed, let glow = TavernSceneArt.pressGlow[pressed] { drawPressGlow(&ctx, glow.center, glow.radius) }
        }
    }

    private func drawSmoke(_ ctx: inout GraphicsContext, _ puff: TavernSmokePuff) {
        let c = puff.center, r = puff.radius
        ctx.fill(
            Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
            with: .radialGradient(
                Gradient(colors: [DarkFantasyTheme.textSecondary.opacity(puff.alpha), DarkFantasyTheme.textSecondary.opacity(0)]),
                center: c, startRadius: 0, endRadius: r
            )
        )
    }

    private func drawSilk(_ ctx: inout GraphicsContext, _ spider: TavernSpiderState) {
        var thread = Path()
        thread.move(to: TavernSceneArt.spiderAnchor)
        thread.addLine(to: spider.hang)
        ctx.stroke(thread, with: .color(DarkFantasyTheme.textPrimary.opacity(0.55 * spider.alpha)), lineWidth: 1.3)
    }

    private func drawBall(_ ctx: inout GraphicsContext) {
        let c = TavernSceneArt.ballCenter, r = TavernSceneArt.ballRadius
        let rect = CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        let strength = 0.22 + frame.ballFlare * 0.5
        let blobs: [(phase: Double, color: Color)] = [
            (0, DarkFantasyTheme.purple), (2.1, DarkFantasyTheme.cyan), (4.2, DarkFantasyTheme.purple),
        ]
        ctx.drawLayer { layer in
            layer.clip(to: Path(ellipseIn: rect))
            for blob in blobs {
                let a = frame.ballSwirl + blob.phase
                let center = CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.45, y: c.y + CGFloat(sin(a * 1.3)) * r * 0.35)
                layer.fill(
                    Path(rect),
                    with: .radialGradient(
                        Gradient(colors: [blob.color.opacity(strength), blob.color.opacity(0)]),
                        center: center, startRadius: 0, endRadius: r * 0.75
                    )
                )
            }
        }
    }

    private func drawFlames(_ ctx: inout GraphicsContext) {
        let t = frame.time
        let chandelier = frame.parts[.chandelier] ?? .rest
        let pivot = TavernSceneArt.part(.chandelier).pivot
        for (i, painted) in TavernSceneArt.flames.enumerated() {
            let fi = Double(i)
            let onChandelier = i < TavernSceneArt.chandelierFlameCount
            // chandelier flames swing with it; every flame leans downwind while a gust passes
            let p = onChandelier ? chandelier.carry(painted, about: pivot) : painted
            let lean = onChandelier ? frame.chandelierLean : frame.wallCandleLean
            let wobble = frame.flamesMove ? sin(t * 11 + fi * 1.7) * 1.4 + sin(t * 23 + fi) * 0.7 : 0
            let a = frame.flamesMove ? 0.45 + 0.25 * (0.5 + 0.5 * sin(t * 9 + fi * 2.3)) : 0.55
            let center = CGPoint(x: p.x + CGFloat(wobble) + lean, y: p.y - 2)
            ctx.fill(
                Path(ellipseIn: CGRect(x: center.x - 16, y: center.y - 16, width: 32, height: 32)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: DarkFantasyTheme.goldBright.opacity(a), location: 0),
                        .init(color: DarkFantasyTheme.gold.opacity(a * 0.45), location: 0.4),
                        .init(color: DarkFantasyTheme.gold.opacity(0), location: 1),
                    ]),
                    center: center, startRadius: 0, endRadius: 16
                )
            )
        }
    }

    private func drawGlint(_ ctx: inout GraphicsContext, _ g: TavernGlint) {
        let p = g.point, s = g.size
        ctx.fill(
            Path(ellipseIn: CGRect(x: p.x - s * 0.6, y: p.y - s * 0.6, width: s * 1.2, height: s * 1.2)),
            with: .radialGradient(
                Gradient(colors: [DarkFantasyTheme.goldBright.opacity(0.9 * g.alpha), DarkFantasyTheme.goldBright.opacity(0)]),
                center: p, startRadius: 0, endRadius: s * 0.6
            )
        )
        var star = Path()
        for (w, h) in [(s * 0.09, s), (s, s * 0.09)] {
            star.move(to: CGPoint(x: p.x - w, y: p.y))
            star.addLine(to: CGPoint(x: p.x, y: p.y - h))
            star.addLine(to: CGPoint(x: p.x + w, y: p.y))
            star.addLine(to: CGPoint(x: p.x, y: p.y + h))
            star.closeSubpath()
        }
        ctx.fill(star, with: .color(DarkFantasyTheme.textPrimary.opacity(g.alpha)))
    }

    private func drawPressGlow(_ ctx: inout GraphicsContext, _ center: CGPoint, _ radius: CGFloat) {
        ctx.fill(
            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
            with: .radialGradient(
                Gradient(colors: [DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityMedium), DarkFantasyTheme.goldBright.opacity(0)]),
                center: center, startRadius: 0, endRadius: radius
            )
        )
    }
}
