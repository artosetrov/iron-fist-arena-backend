//
//  DiceTableScene.swift
//  Hexbound
//
//  The 3D dice table (RealityKit, ARView in non-AR mode — the app targets
//  iOS 17, RealityView needs 18). Owns the felt, the dice, the camera and
//  every animation; DiceBattleViewModel drives it through a handful of async
//  calls and stays the only place that talks to the server.
//
//  The face that lands always comes from the server. A throw is a baked clip
//  (DiceThrowLibrary); while the die spins in the air the visual cube turns
//  inside its physics box by one of the 24 cube symmetries so the server's
//  face is the one on top when it settles (DiceCube.correction).
//  Spec: docs/06_game_systems/DICE_3D_THROW.md.
//

import Combine
import RealityKit
import SwiftUI
import UIKit
import simd

/// What SwiftUI draws over the 3D table, in the ARView's coordinates.
@MainActor
@Observable
final class DiceTableOverlay {
    /// Top-face centre of each die resting in its slot.
    var slotPoints: [DiceBattleViewModel.Slot: CGPoint] = [:]
    var labelPoints: [DiceTableLabel: CGPoint] = [:]
    /// On-screen edge of a die in its slot, points.
    var dieSize: CGFloat = 56
    /// Dice rest in their slots — labels, chips and status tags may show.
    var labelsVisible = false
    /// Waiting for the player to grab and throw.
    var awaitingThrow = false
    var holding = false
    /// Where the "flick" cue sits (above your dice in the tray).
    var cuePoint: CGPoint = .zero
    /// The camera has framed the table — fade the view in.
    var ready = false
}

enum DiceTableLabel: Hashable {
    case theirGuard, yourStrike, enemyStrike, yourGuard, chipMine, chipTheirs, bossNext
}

@MainActor
final class DiceTableScene {
    typealias Slot = DiceBattleViewModel.Slot

    // MARK: Layout (table units — must match scripts/dice-throws/generate.mjs)

    static let tableHalf = SIMD2<Float>(2.05, 3.05)
    static let rim: Float = 0.3
    static let handHeight: Float = 1.35
    private static let tilt: Float = 0.38
    private static let half = DiceCube.half
    private static let oa2Scale: Float = 0.72

    static func slotPosition(_ slot: Slot) -> SIMD3<Float> {
        switch slot {
        case .pa: return [-0.95, half, 1.08]
        case .od: return [-0.95, half, -1.08]
        case .oa: return [0.95, half, -1.08]
        case .pd: return [0.95, half, 1.08]
        case .oa2: return [1.62, half * oa2Scale, -1.62]
        }
    }

    static func trayPosition(_ slot: Slot) -> SIMD3<Float> {
        switch slot {
        case .pa: return [-0.52, half, 2.4]
        case .pd: return [0.52, half, 2.4]
        case .oa: return [0.52, half, -2.4]
        case .od: return [-0.52, half, -2.4]
        case .oa2: return [1.3, half * oa2Scale, -2.5]
        }
    }

    /// Clip die index → slot (generate.mjs: your attack, your guard, enemy attack, enemy guard).
    private static let clipSlots: [Slot] = [.pa, .pd, .oa, .od]

    // MARK: State

    let overlay = DiceTableOverlay()
    /// Tap on a die resting in its slot.
    var onTapDie: ((Slot) -> Void)?

    private var arView: ARView?
    private let root = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
    private let camera = PerspectiveCamera()
    private var felt: ModelEntity?
    private var dice: [Slot: DieEntity] = [:]
    private var updateSub: Cancellable?
    private var clock: Double = 0
    private var tweens: [Tween] = []
    private var playbacks: [Playback] = []
    private var hold: Hold?
    private var touchStart: (point: CGPoint, time: Double)?
    private var mat: DiceTableMat?

    private var camDistance: Float = 12
    private var camTarget = SIMD3<Float>(0, 0, 0.1)
    private var fitBudget = 60
    private var fittedBounds: CGSize = .zero

    private var roundWaiter: CheckedContinuation<Void, Never>?
    private var pendingRound: PendingRound?
    private var autoThrowAt: Double?
    private var hopWaiters: [Slot: CheckedContinuation<Void, Never>] = [:]
    private var lastImpactSound: Double = -1
    private var lastImpactHaptic: Double = -1
    private var inSlots = false

    private struct PendingRound {
        let roll: DiceRollView
    }

    // MARK: - View

    func makeView() -> ARView {
        if let arView { return arView }
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(UIColor(DarkFantasyTheme.bgPrimary))
        view.renderOptions.insert(.disableMotionBlur)
        view.renderOptions.insert(.disableDepthOfField)
        view.renderOptions.insert(.disableCameraGrain)
        view.renderOptions.insert(.disablePersonOcclusion)
        view.scene.addAnchor(root)
        build()
        updateSub = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            let dt = event.deltaTime
            MainActor.assumeIsolated { self?.tick(dt) }
        }
        arView = view
        return view
    }

    /// Re-subscribe to frame updates if the screen comes back after `teardown`.
    func resume() {
        guard let view = arView, updateSub == nil else { return }
        updateSub = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            let dt = event.deltaTime
            MainActor.assumeIsolated { self?.tick(dt) }
        }
    }

    /// Releases anything still waiting on an animation (screen left mid-throw).
    func teardown() {
        updateSub?.cancel()
        updateSub = nil
        let pending = tweens
        tweens.removeAll()
        pending.forEach { $0.done?() }
        playbacks.forEach { $0.finish() }
        playbacks.removeAll()
        roundWaiter?.resume()
        roundWaiter = nil
        hopWaiters.values.forEach { $0.resume() }
        hopWaiters.removeAll()
        pendingRound = nil
        hold = nil
    }

    // MARK: - Scene setup

    private func build() {
        camera.camera.fieldOfViewInDegrees = 34
        root.addChild(camera)

        let key = DirectionalLight()
        key.light.color = UIColor(red: 1, green: 0.88, blue: 0.72, alpha: 1)
        key.light.intensity = 3200
        key.shadow = DirectionalLightComponent.Shadow(maximumDistance: 14, depthBias: 1.6)
        key.look(at: .zero, from: [-3.2, 9, 3.5], relativeTo: nil)
        root.addChild(key)

        let fill = DirectionalLight()
        fill.light.color = UIColor(red: 0.55, green: 0.62, blue: 0.85, alpha: 1)
        fill.light.intensity = 700
        fill.look(at: .zero, from: [3, 4, -6], relativeTo: nil)
        root.addChild(fill)

        let rimLight = PointLight()
        rimLight.light.color = UIColor(red: 0.37, green: 0.49, blue: 1, alpha: 1)
        rimLight.light.intensity = 24000
        rimLight.light.attenuationRadius = 12
        rimLight.position = [3, 3.2, -4.5]
        root.addChild(rimLight)

        let candle = PointLight()
        candle.light.color = UIColor(red: 1, green: 0.6, blue: 0.29, alpha: 1)
        candle.light.intensity = 16000
        candle.light.attenuationRadius = 9
        candle.position = [-2.6, 2.2, 3.4]
        root.addChild(candle)

        // Felt — the mat texture arrives with setMat.
        let half = Self.tableHalf
        let felt = ModelEntity(mesh: .generatePlane(width: half.x * 2, depth: half.y * 2),
                               materials: [SimpleMaterial(color: UIColor(DarkFantasyTheme.bgSecondary), roughness: 0.95, isMetallic: false)])
        root.addChild(felt)
        self.felt = felt

        let under = ModelEntity(mesh: .generatePlane(width: 30, depth: 30),
                                materials: [UnlitMaterial(color: UIColor(DarkFantasyTheme.bgPrimary))])
        under.position = [0, -0.02, 0]
        root.addChild(under)

        // Rims: dark wood with a thin gold strip on top.
        let wood = SimpleMaterial(color: UIColor(red: 0.17, green: 0.11, blue: 0.07, alpha: 1), roughness: 0.7, isMetallic: false)
        let trim = SimpleMaterial(color: UIColor(red: 0.79, green: 0.64, blue: 0.29, alpha: 1), roughness: 0.35, isMetallic: true)
        let r = Self.rim, h: Float = 0.3, t: Float = 0.035
        func box(_ size: SIMD3<Float>, _ pos: SIMD3<Float>, _ material: SimpleMaterial) {
            let e = ModelEntity(mesh: .generateBox(size: size), materials: [material])
            e.position = pos
            root.addChild(e)
        }
        box([r, h, half.y * 2 + r * 2], [half.x + r / 2, h / 2, 0], wood)
        box([r, h, half.y * 2 + r * 2], [-half.x - r / 2, h / 2, 0], wood)
        box([half.x * 2, h, r], [0, h / 2, half.y + r / 2], wood)
        box([half.x * 2, h, r], [0, h / 2, -half.y - r / 2], wood)
        box([t, t, half.y * 2], [half.x + t / 2, h + t / 2, 0], trim)
        box([t, t, half.y * 2], [-half.x - t / 2, h + t / 2, 0], trim)
        box([half.x * 2, t, t], [0, h + t / 2, half.y + t / 2], trim)
        box([half.x * 2, t, t], [0, h + t / 2, -half.y - t / 2], trim)

        // Dice
        for slot in [Slot.pa, .pd, .oa, .od, .oa2] {
            let kind: DiceKind = (slot == .pd || slot == .od) ? .guardDie : .attack
            let die = DieEntity(kind: kind)
            if slot == .oa2 {
                die.entity.scale = SIMD3(repeating: Self.oa2Scale)
                die.entity.isEnabled = false
            }
            root.addChild(die.entity)
            dice[slot] = die
        }
        placeInTrays()
        placeCamera()
    }

    private func placeInTrays() {
        for (slot, die) in dice {
            die.entity.position = Self.trayPosition(slot)
            die.entity.orientation = DiceCube.upright(geo: Int.random(in: 0..<6), yaw: Float.random(in: -0.5...0.5))
        }
        dice[.oa2]?.entity.isEnabled = false
        inSlots = false
    }

    // MARK: - Content

    func setMat(_ newMat: DiceTableMat) {
        guard newMat != mat, let felt else { return }
        mat = newMat
        guard let image = Self.feltImage(newMat).cgImage,
              let texture = try? TextureResource.generate(from: image, options: .init(semantic: .color)) else { return }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(white: newMat.tint, alpha: 1), texture: .init(texture))
        material.roughness = .init(floatLiteral: 0.92)
        material.metallic = .init(floatLiteral: 0)
        felt.model?.materials = [material]
    }

    /// Face art for every die; `runeAssets(slot)` lists the rune asset per server face.
    func refreshFaces(_ runeAssets: (Slot) -> [String?]) {
        for (slot, die) in dice {
            let runes = runeAssets(slot)
            die.setFaces { serverFace in runes.indices.contains(serverFace) ? runes[serverFace] : nil }
        }
    }

    /// The mat with the four slot marks and a soft vignette baked in.
    private static func feltImage(_ mat: DiceTableMat) -> UIImage {
        let w: CGFloat = 1024
        let h = (w * CGFloat(tableHalf.y / tableHalf.x)).rounded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format).image { ctx in
            let rect = CGRect(x: 0, y: 0, width: w, height: h)
            UIColor(DarkFantasyTheme.bgSecondary).setFill()
            ctx.fill(rect)
            UIImage(named: mat.asset)?.draw(in: rect)
            let cg = ctx.cgContext
            let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.35).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                cg.drawRadialGradient(gradient, startCenter: CGPoint(x: w / 2, y: h / 2), startRadius: h * 0.2,
                                      endCenter: CGPoint(x: w / 2, y: h / 2), endRadius: h * 0.7, options: .drawsAfterEndLocation)
            }
            let side = CGFloat(DiceCube.edge * 1.22 / (tableHalf.x * 2)) * w
            for slot in [Slot.pa, .pd, .oa, .od] {
                let p = slotPosition(slot)
                let cx = CGFloat((p.x + tableHalf.x) / (tableHalf.x * 2)) * w
                let cy = CGFloat((p.z + tableHalf.y) / (tableHalf.y * 2)) * h
                let mark = UIBezierPath(roundedRect: CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side),
                                        cornerRadius: side * 0.14)
                UIColor.black.withAlphaComponent(0.28).setFill()
                mark.fill()
                let mine = slot == .pa || slot == .pd
                (mine ? UIColor(red: 0.95, green: 0.82, blue: 0.48, alpha: 0.55)
                      : UIColor(red: 0.9, green: 0.55, blue: 0.47, alpha: 0.45)).setStroke()
                mark.lineWidth = w / 260
                mark.stroke()
            }
        }
    }

    // MARK: - Round throw

    /// Round start: dice back to the trays, wait for the player's throw (or
    /// throw for them on `auto` / after a few idle seconds), play it, slide
    /// the dice into their slots. Returns when they rest there.
    func throwRound(roll: DiceRollView, auto: Bool) async {
        if inSlots || dice.values.contains(where: { $0.entity.isEnabled && $0.entity.position.y > Self.half + 0.05 }) {
            await collect()
        }
        overlay.labelsVisible = false
        overlay.awaitingThrow = true
        pendingRound = PendingRound(roll: roll)
        autoThrowAt = clock + (auto ? 0.45 : 7)
        publishOverlay(force: true)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            roundWaiter = cont
        }
    }

    /// AUTO pressed while the dice wait in the tray.
    func throwNow() {
        guard overlay.awaitingThrow, hold == nil else { return }
        autoThrowAt = clock
    }

    private func autoThrow() {
        performThrow(angle: Float.random(in: -18...18), speed: Float.random(in: 8...11))
    }

    private func performThrow(angle: Float, speed: Float) {
        guard let round = pendingRound else { return }
        pendingRound = nil
        autoThrowAt = nil
        overlay.awaitingThrow = false
        overlay.holding = false
        hold = nil
        SFXManager.shared.play(.diceShake)

        let roll = round.roll
        let targets: [Slot: Int] = [.pa: roll.p.a, .pd: roll.p.d, .oa: roll.o.a, .od: roll.o.d]
        guard let clip = DiceThrowLibrary.shared.pickThrow(angle: angle, speed: speed) else {
            // No baked data — drop the dice straight into their slots.
            Task { [weak self] in
                await self?.dropIn(targets: targets)
                await self?.finishRound(roll: roll)
            }
            return
        }
        let movers = Self.clipSlots.compactMap { dice[$0] }
        let geoTargets = Self.clipSlots.map { DiceCube.geoFace[clamp(targets[$0] ?? 0)] }
        let playback = Playback(clip: clip, dice: movers, targets: geoTargets)
        playback.onDone = { [weak self] in
            Task { await self?.finishRound(roll: roll) }
        }
        playbacks.append(playback)
    }

    private func finishRound(roll: DiceRollView) async {
        await arrange(roll: roll)
        if let a2 = roll.o.a2 { await dropSecondAttack(face: a2) }
        inSlots = true
        overlay.labelsVisible = true
        publishOverlay(force: true)
        roundWaiter?.resume()
        roundWaiter = nil
    }

    private func arrange(roll: DiceRollView) async {
        let jobs: [(Slot, Int)] = [(.pa, roll.p.a), (.od, roll.o.d), (.oa, roll.o.a), (.pd, roll.p.d)]
        await withTaskGroup(of: Void.self) { group in
            for (i, job) in jobs.enumerated() {
                group.addTask { @MainActor [weak self] in
                    guard let self, let die = self.dice[job.0] else { return }
                    await self.wait(Double(i) * 0.07)
                    await self.glide(die, to: Self.slotPosition(job.0),
                                     rotation: DiceCube.upright(geo: DiceCube.geoFace[self.clamp(job.1)]),
                                     duration: 0.43, arc: 0.5)
                }
            }
        }
    }

    /// Fallback with no throw data: each die drops from above onto its face.
    private func dropIn(targets: [Slot: Int]) async {
        await withTaskGroup(of: Void.self) { group in
            for (i, slot) in Self.clipSlots.enumerated() {
                group.addTask { @MainActor [weak self] in
                    guard let self, let die = self.dice[slot] else { return }
                    let end = Self.slotPosition(slot)
                    die.entity.position = end + [0, 2.4, 0]
                    die.entity.orientation = simd_quatf(angle: Float.random(in: 0...6), axis: simd_normalize(SIMD3<Float>.random(in: -1...1) + [0, 0.01, 0]))
                    let q0 = die.entity.orientation
                    let q1 = DiceCube.upright(geo: DiceCube.geoFace[self.clamp(targets[slot] ?? 0)])
                    await self.wait(Double(i) * 0.08)
                    await self.tween(0.42, ease: Ease.inQuad) { k in
                        die.entity.position = end + [0, 2.4 * (1 - k), 0]
                        die.entity.orientation = simd_slerp(q0, q1, k)
                    }
                    self.impactFeedback(4.5, kind: .felt)
                }
            }
        }
    }

    /// Boss phase 2: the second attack die drops in beside the first.
    private func dropSecondAttack(face: Int) async {
        guard let die = dice[.oa2] else { return }
        let end = Self.slotPosition(.oa2)
        die.entity.isEnabled = true
        die.entity.position = end + [0, 2.2, 0]
        let q0 = simd_quatf(angle: 2.4, axis: simd_normalize(SIMD3<Float>(0.4, 1, 0.7)))
        let q1 = DiceCube.upright(geo: DiceCube.geoFace[clamp(face)])
        await tween(0.4, ease: Ease.inQuad) { k in
            die.entity.position = end + [0, 2.2 * (1 - k), 0]
            die.entity.orientation = simd_slerp(q0, q1, k)
        }
        impactFeedback(5, kind: .felt)
        await tween(0.16) { k in die.entity.position = end + [0, 0.12 * sin(Float.pi * k), 0] }
    }

    /// Everything back to the trays (round end).
    func collect() async {
        overlay.labelsVisible = false
        inSlots = false
        await withTaskGroup(of: Void.self) { group in
            for (i, slot) in [Slot.pa, .pd, .oa, .od].enumerated() {
                group.addTask { @MainActor [weak self] in
                    guard let self, let die = self.dice[slot] else { return }
                    die.glow(face: nil, amount: 0)
                    await self.wait(Double(i) * 0.06)
                    await self.glide(die, to: Self.trayPosition(slot),
                                     rotation: DiceCube.upright(geo: Int.random(in: 0..<6), yaw: Float.random(in: -0.4...0.4)),
                                     duration: 0.42, arc: 0.7)
                }
            }
            group.addTask { @MainActor [weak self] in
                guard let self, let die = self.dice[.oa2], die.entity.isEnabled else { return }
                let p0 = die.entity.position
                await self.tween(0.3) { k in die.entity.position = p0 + [0, 1.5 * k, -1.2 * k] }
                die.entity.isEnabled = false
            }
        }
    }

    // MARK: - Focus actions

    /// Reroll starts before the server answers: the die jumps at once and the
    /// face is fixed in the air by `landHop`.
    func beginHop(_ slot: Slot) {
        guard let die = dice[slot], let hop = DiceThrowLibrary.shared.randomHop() else { return }
        let base = die.entity.position
        let clip = hop.translated(by: [base.x, base.y - Self.half * die.entity.scale.x, base.z])
        let playback = Playback(clip: clip, dice: [die], targets: [nil], slot: slot)
        playbacks.removeAll { $0.slot == slot }
        playbacks.append(playback)
        SFXManager.shared.play(.diceShake)
    }

    /// The server's face for a hop started with `beginHop`. Returns once the
    /// die is back in its slot showing it.
    func landHop(_ slot: Slot, face: Int) async {
        let geo = DiceCube.geoFace[clamp(face)]
        guard let die = dice[slot], let playback = playbacks.first(where: { $0.slot == slot }) else {
            if let die = dice[slot] { await settle(die, slot: slot, geo: geo) }
            return
        }
        playback.setTarget(0, geo: geo)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            if playback.isFinished { cont.resume() } else { hopWaiters[slot] = cont }
        }
        await settle(die, slot: slot, geo: geo)
    }

    func reroll(_ slot: Slot, face: Int) async {
        beginHop(slot)
        await landHop(slot, face: face)
    }

    /// Set a face: the die lifts, turns over in the air and drops back.
    func setFace(_ slot: Slot, face: Int) async {
        guard let die = dice[slot] else { return }
        let p0 = die.entity.position, q0 = die.entity.orientation
        let q1 = DiceCube.upright(geo: DiceCube.geoFace[clamp(face)])
        SFXManager.shared.play(.diceShake)
        await tween(0.2) { k in die.entity.position = p0 + [0, 0.95 * k, 0] }
        await tween(0.46) { k in
            let spin = simd_quatf(angle: (1 - k) * Float.pi * 2, axis: [0, 1, 0])
            die.entity.orientation = spin * simd_slerp(q0, q1, k)
        }
        await tween(0.17, ease: Ease.inQuad) { k in die.entity.position = p0 + [0, 0.95 * (1 - k), 0] }
        impactFeedback(4, kind: .felt)
    }

    private func settle(_ die: DieEntity, slot: Slot, geo: Int) async {
        await glide(die, to: Self.slotPosition(slot), rotation: DiceCube.upright(geo: geo), duration: 0.34, arc: 0.35)
    }

    // MARK: - Clash

    /// The attack die lunges at the defender's guard die and comes back.
    /// `outcome`: crit | hit | pierce | blocked | miss (server strike result).
    func lunge(from slot: Slot, outcome: String) async {
        guard let attacker = dice[slot] else { return }
        let guardSlot: Slot = slot == .pa ? .od : .pd
        guard let guardDie = dice[guardSlot] else { return }
        let start = attacker.entity.position
        let target = guardDie.entity.position
        var dir = target - start
        dir.y = 0
        dir = simd_length(dir) > 0.001 ? simd_normalize(dir) : [0, 0, slot == .pa ? -1 : 1]
        let tiltAxis = simd_normalize(simd_cross([0, 1, 0], dir))
        let q0 = attacker.entity.orientation
        let lifted = start + [0, 0.6, 0] - dir * 0.18
        let contact = target - dir * (DiceCube.edge * 1.02) + [0, 0.18, 0]

        // Contact lands with the VM's strike VFX (~0.18 s after the lunge starts).
        await tween(0.1) { k in
            attacker.entity.position = simd_mix(start, lifted, SIMD3(repeating: k))
            attacker.entity.orientation = simd_quatf(angle: -0.35 * k, axis: tiltAxis) * q0
        }
        await tween(0.09, ease: Ease.inQuad) { k in
            attacker.entity.position = simd_mix(lifted, contact, SIMD3(repeating: k))
            attacker.entity.orientation = simd_quatf(angle: -0.35 + 0.75 * k, axis: tiltAxis) * q0
        }
        let blocked = outcome == "blocked"
        if outcome != "miss" {
            impactFeedback(blocked ? 7 : 5, kind: .die)
            let g0 = guardDie.entity.orientation
            let amount: Float = blocked ? 0.12 : 0.32
            Task { [weak self] in
                await self?.tween(0.38, ease: Ease.linear) { k in
                    guardDie.entity.orientation = simd_quatf(angle: sin(k * Float.pi * 3) * (1 - k) * amount, axis: tiltAxis) * g0
                }
            }
        }
        let back = attacker.entity.position, qBack = attacker.entity.orientation
        await tween(0.33) { k in
            attacker.entity.position = simd_mix(back, start, SIMD3(repeating: k)) + [0, sin(Float.pi * k) * 0.25, 0]
            attacker.entity.orientation = simd_slerp(qBack, q0, k)
        }
        impactFeedback(2.5, kind: .felt)
    }

    /// Rune fired — the face on top flashes.
    func pulse(_ slot: Slot) {
        guard let die = dice[slot], die.entity.isEnabled else { return }
        let geo = DiceCube.landedFace(die.entity.orientation)
        Task { [weak self] in
            await self?.tween(0.7, ease: Ease.linear) { k in
                die.glow(face: geo, amount: k < 0.3 ? k / 0.3 * 1.6 : 1.6 - (k - 0.3) / 0.7 * 1.3)
            }
        }
    }

    // MARK: - Touch (from SwiftUI, in the ARView's coordinates)

    func touchBegan(_ point: CGPoint) {
        touchStart = (point, clock)
        guard overlay.awaitingThrow, hold == nil, let p = handPoint(point) else { return }
        autoThrowAt = nil
        hold = Hold(point: p, samples: [(clock, p)], axes: [randomAxis(), randomAxis()], previous: p)
        overlay.holding = true
        HapticManager.light()
    }

    func touchMoved(_ point: CGPoint) {
        guard var h = hold, let p = handPoint(point) else { return }
        h.point = p
        h.samples.append((clock, p))
        h.samples.removeAll { clock - $0.0 > 0.14 }
        hold = h
    }

    func touchEnded(_ point: CGPoint) {
        defer { touchStart = nil }
        if let h = hold {
            let recent = h.samples.filter { clock - $0.0 < 0.11 }
            var v = SIMD3<Float>.zero
            if let a = recent.first, let b = recent.last, b.0 > a.0 {
                v = (b.1 - a.1) / Float(max(0.016, b.0 - a.0))
            }
            let flat = SIMD2<Float>(v.x, v.z)
            let speed = simd_length(flat)
            if speed < 1.2 || flat.y > -0.3 {
                // A drop or a pull back — toss forward instead.
                performThrow(angle: Float.random(in: -10...10), speed: max(6, min(9, speed)))
            } else {
                let angle = atan2(flat.x, -flat.y) * 180 / .pi
                performThrow(angle: angle, speed: speed * 0.9)
            }
            return
        }
        // A tap on a die resting in its slot.
        guard overlay.labelsVisible, let start = touchStart,
              hypot(point.x - start.point.x, point.y - start.point.y) < 12,
              clock - start.time < 0.4 else { return }
        let hit = overlay.slotPoints
            .filter { dice[$0.key]?.entity.isEnabled == true }
            .min { hypot($0.value.x - point.x, $0.value.y - point.y) < hypot($1.value.x - point.x, $1.value.y - point.y) }
        if let hit, hypot(hit.value.x - point.x, hit.value.y - point.y) < overlay.dieSize * 0.9 {
            onTapDie?(hit.key)
        }
    }

    private func handPoint(_ point: CGPoint) -> SIMD3<Float>? {
        guard let ray = arView?.ray(through: point), abs(ray.direction.y) > 0.0001 else { return nil }
        let t = (Self.handHeight - ray.origin.y) / ray.direction.y
        guard t > 0 else { return nil }
        var p = ray.origin + ray.direction * t
        p.x = max(-Self.tableHalf.x + 0.6, min(Self.tableHalf.x - 0.6, p.x))
        p.z = max(-0.4, min(Self.tableHalf.y - 0.55, p.z))
        return p
    }

    private func randomAxis() -> SIMD3<Float> {
        simd_normalize(SIMD3<Float>.random(in: -1...1) + [0.001, 0.001, 0.001])
    }

    // MARK: - Frame

    private func tick(_ dt: TimeInterval) {
        let dt = min(dt, 1.0 / 20)
        clock += dt
        fitCameraIfNeeded()
        updateHold(Float(dt))
        if let at = autoThrowAt, clock >= at, hold == nil, pendingRound != nil { autoThrow() }
        for playback in playbacks { advance(playback, dt: Float(dt)) }
        playbacks.removeAll { $0.isFinished }
        runTweens()
    }

    private func updateHold(_ dt: Float) {
        guard var h = hold else { return }
        let moved = simd_length(h.point - h.previous) / max(dt, 0.001)
        h.shake = h.shake * 0.9 + moved * 0.1
        h.previous = h.point
        for (i, slot) in [Slot.pa, .pd].enumerated() {
            guard let die = dice[slot] else { continue }
            let t = Float(clock)
            let target = h.point + [i == 0 ? -0.42 : 0.42, sin(t * 23 + Float(i) * 2) * 0.05, cos(t * 19 + Float(i)) * 0.04]
            let k = 1 - exp(-dt * 22)
            die.entity.position = simd_mix(die.entity.position, target, SIMD3(repeating: k))
            die.entity.orientation = (simd_quatf(angle: dt * (7 + h.shake * 0.8), axis: h.axes[i]) * die.entity.orientation).normalized
        }
        h.rattleIn -= Double(dt)
        if h.rattleIn <= 0, h.shake > 0.6 {
            SFXManager.shared.play(.diceShake)
            h.rattleIn = Double.random(in: 0.12...0.22) / Double(1 + min(h.shake, 20) * 0.04)
        }
        hold = h
    }

    private func advance(_ pb: Playback, dt: Float) {
        guard !pb.isFinished else { return }
        var limit = pb.clip.duration
        for (k, target) in pb.targets.enumerated() where target == nil {
            limit = min(limit, pb.holdTime(k))
        }
        pb.time = min(pb.time + dt, max(pb.time, limit))
        for (k, die) in pb.dice.enumerated() {
            let pose = pb.clip.pose(die: k, at: pb.time)
            let w = 1 - DiceCube.smoothstep(pb.time / 0.2)
            die.entity.position = pose.position + pb.startOffset[k] * w
            die.entity.orientation = (pose.rotation * pb.correction(k)).normalized
        }
        while pb.impactCursor < pb.clip.impacts.count, pb.clip.impacts[pb.impactCursor].t <= pb.time {
            let impact = pb.clip.impacts[pb.impactCursor]
            impactFeedback(impact.strength, kind: impact.kind)
            pb.impactCursor += 1
        }
        if pb.time >= pb.clip.duration, pb.targets.allSatisfy({ $0 != nil }) {
            pb.finish()
            if let slot = pb.slot, let waiter = hopWaiters.removeValue(forKey: slot) { waiter.resume() }
        }
    }

    private func impactFeedback(_ strength: Float, kind: DiceThrowClip.Impact.Kind) {
        if strength > 1.2, clock - lastImpactSound > 0.045 {
            lastImpactSound = clock
            SFXManager.shared.play(.diceHit)
        }
        if strength > 3.5, clock - lastImpactHaptic > 0.08 {
            lastImpactHaptic = clock
            if strength > 6.5 { HapticManager.medium() } else { HapticManager.light() }
        }
    }

    // MARK: - Camera fit

    /// Frames the table (rims included) inside the view. ARView.project uses
    /// the rendered camera, so this converges over a few frames; the view
    /// stays transparent until it has.
    private func fitCameraIfNeeded() {
        guard let view = arView else { return }
        let bounds = view.bounds.size
        guard bounds.width > 20, bounds.height > 20 else { return }
        if bounds != fittedBounds {
            fittedBounds = bounds
            fitBudget = 60
            overlay.ready = false
        }
        guard fitBudget > 0 else { return }
        fitBudget -= 1
        defer {
            // Out of attempts: show the table as it is rather than never.
            if fitBudget == 0, !overlay.ready {
                overlay.ready = true
                publishOverlay(force: true)
            }
        }
        let hx = Self.tableHalf.x + Self.rim, hz = Self.tableHalf.y + Self.rim
        let corners: [SIMD3<Float>] = [[-hx, 0.3, -hz], [hx, 0.3, -hz], [-hx, 0.3, hz], [hx, 0.3, hz]]
        let points = corners.compactMap { view.project($0) }
        guard points.count == 4 else { placeCamera(); return }
        let minX = points.map(\.x).min() ?? 0, maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0, maxY = points.map(\.y).max() ?? 0
        let inset: CGFloat = 4
        let scale = max((maxX - minX) / (bounds.width - inset * 2), (maxY - minY) / (bounds.height - inset * 2))
        let dy = (minY + maxY) / 2 - bounds.height / 2
        if abs(scale - 1) < 0.008, abs(dy) < 1.5 {
            fitBudget = 0
            overlay.ready = true
            publishOverlay(force: true)
            return
        }
        camDistance *= Float(min(1.5, max(0.67, scale)))
        let worldPerPoint = Float(hz * 2) / Float(max(1, maxY - minY))
        camTarget.z += Float(dy) * worldPerPoint * 0.7
        placeCamera()
    }

    private func placeCamera() {
        let from = camTarget + SIMD3(0, camDistance * cos(Self.tilt), camDistance * sin(Self.tilt))
        camera.look(at: camTarget, from: from, relativeTo: nil)
    }

    /// Screen positions of the slots, labels and cue — they only move with
    /// the camera, so this runs on fit and on demand, not every frame.
    private func publishOverlay(force: Bool = false) {
        guard let view = arView, overlay.ready || force else { return }
        var points: [Slot: CGPoint] = [:]
        for slot in [Slot.pa, .pd, .oa, .od, .oa2] {
            let p = Self.slotPosition(slot)
            let height = slot == .oa2 ? DiceCube.edge * Self.oa2Scale : DiceCube.edge
            if let s = view.project([p.x, height, p.z]) { points[slot] = s }
        }
        let pa = Self.slotPosition(.pa), od = Self.slotPosition(.od)
        let oa = Self.slotPosition(.oa), pd = Self.slotPosition(.pd)
        let h = Self.half
        var labels: [DiceTableLabel: CGPoint] = [:]
        func put(_ key: DiceTableLabel, _ w: SIMD3<Float>) { if let s = view.project(w) { labels[key] = s } }
        put(.theirGuard, [od.x, DiceCube.edge + 0.05, od.z - h - 0.16])
        put(.enemyStrike, [oa.x, DiceCube.edge + 0.05, oa.z - h - 0.16])
        put(.yourStrike, [pa.x, 0, pa.z + h + 0.2])
        put(.yourGuard, [pd.x, 0, pd.z + h + 0.2])
        put(.chipMine, [pa.x, 0.02, 0])
        put(.chipTheirs, [oa.x, 0.02, 0])
        put(.bossNext, [oa.x + 0.55, DiceCube.edge + 0.05, oa.z - h - 0.62])
        if let a = view.project([pa.x - h, DiceCube.edge, pa.z]), let b = view.project([pa.x + h, DiceCube.edge, pa.z]) {
            overlay.dieSize = abs(b.x - a.x)
        }
        let tray = Self.trayPosition(.pa)
        if let cue = view.project([0, DiceCube.edge + 0.1, tray.z - 0.55]) { overlay.cuePoint = cue }
        overlay.slotPoints = points
        overlay.labelPoints = labels
    }

    // MARK: - Tweens

    private struct Tween {
        let start: Double
        let duration: Double
        let ease: (Float) -> Float
        let step: (Float) -> Void
        let done: (() -> Void)?
    }

    private func tween(_ seconds: Double, ease: @escaping (Float) -> Float = Ease.inOut, _ step: @escaping (Float) -> Void) async {
        guard arView != nil, updateSub != nil else { step(1); return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            tweens.append(Tween(start: clock, duration: max(0.001, seconds), ease: ease, step: step, done: { cont.resume() }))
        }
    }

    private func wait(_ seconds: Double) async {
        guard seconds > 0 else { return }
        await tween(seconds, ease: Ease.linear) { _ in }
    }

    private func glide(_ die: DieEntity, to end: SIMD3<Float>, rotation: simd_quatf, duration: Double, arc: Float) async {
        let p0 = die.entity.position, q0 = die.entity.orientation
        await tween(duration) { k in
            die.entity.position = simd_mix(p0, end, SIMD3(repeating: k)) + [0, sin(Float.pi * k) * arc, 0]
            die.entity.orientation = simd_slerp(q0, rotation, k)
        }
        impactFeedback(1.6, kind: .felt)
    }

    private func runTweens() {
        guard !tweens.isEmpty else { return }
        var finished: [Tween] = []
        var keep: [Tween] = []
        for tw in tweens {
            let k = Float(max(0, min(1, (clock - tw.start) / tw.duration)))
            tw.step(tw.ease(k))
            if k >= 1 { finished.append(tw) } else { keep.append(tw) }
        }
        tweens = keep
        finished.forEach { $0.done?() }
    }

    private func clamp(_ face: Int) -> Int { max(0, min(5, face)) }
}

// MARK: - Easing

enum Ease {
    static let linear: (Float) -> Float = { $0 }
    static let inQuad: (Float) -> Float = { $0 * $0 }
    static let out: (Float) -> Float = { 1 - pow(1 - $0, 3) }
    static let inOut: (Float) -> Float = { k in k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2 }
}

// MARK: - Hold (dice in the player's hand)

private struct Hold {
    var point: SIMD3<Float>
    var samples: [(Double, SIMD3<Float>)]
    var axes: [SIMD3<Float>]
    var previous: SIMD3<Float>
    var shake: Float = 0
    var rattleIn: Double = 0
}

// MARK: - Playback of a baked clip

@MainActor
private final class Playback {
    let clip: DiceThrowClip
    let dice: [DieEntity]
    let slot: DiceBattleViewModel.Slot?
    /// Geometry face each die must show; nil until the server answers (hops).
    private(set) var targets: [Int?]
    var time: Float = 0
    var impactCursor = 0
    var onDone: (() -> Void)?
    private(set) var isFinished = false
    /// Hand / slot position minus the clip's first frame, blended out over 0.2 s.
    let startOffset: [SIMD3<Float>]
    private var cFrom: [simd_quatf]
    private var cTo: [simd_quatf?]
    private var cT0: [Float]
    private var cT1: [Float]

    init(clip: DiceThrowClip, dice: [DieEntity], targets: [Int?], slot: DiceBattleViewModel.Slot? = nil) {
        self.clip = clip
        self.dice = dice
        self.slot = slot
        self.targets = targets
        var offsets: [SIMD3<Float>] = []
        var c0: [simd_quatf] = []
        for (k, die) in dice.enumerated() {
            let start = clip.pose(die: k, at: 0)
            offsets.append(die.entity.position - start.position)
            // Keeps the die exactly as it looks right now at t = 0.
            c0.append((start.rotation.inverse * die.entity.orientation).normalized)
        }
        startOffset = offsets
        cFrom = c0
        cTo = Array(repeating: nil, count: dice.count)
        cT0 = Array(repeating: 0, count: dice.count)
        cT1 = Array(repeating: 0, count: dice.count)
        for (k, target) in targets.enumerated() {
            if let target { setTarget(k, geo: target) }
        }
    }

    /// Fix the face die `k` lands on; the turn happens in the air before its first impact.
    func setTarget(_ k: Int, geo: Int) {
        guard k < dice.count else { return }
        let launch = clip.launch[k], first = clip.firstImpact[k]
        cFrom[k] = correction(k)
        cTo[k] = DiceCube.correction(final: clip.finalRotation(die: k), targetGeo: geo)
        cT0[k] = max(time, launch)
        let window = max(0.1, min(0.45, (first - launch) * 0.85))
        cT1[k] = max(cT0[k] + 0.12, min(launch + window, first - 0.02))
        targets[k] = geo
    }

    /// Latest time die `k` may reach while its face is still unknown.
    func holdTime(_ k: Int) -> Float {
        max(clip.launch[k] + 0.05, clip.firstImpact[k] - 0.12)
    }

    func correction(_ k: Int) -> simd_quatf {
        guard let to = cTo[k] else { return cFrom[k] }
        let span = max(0.001, cT1[k] - cT0[k])
        return simd_slerp(cFrom[k], to, DiceCube.smoothstep((time - cT0[k]) / span))
    }

    func finish() {
        guard !isFinished else { return }
        isFinished = true
        let done = onDone
        onDone = nil
        done?()
    }
}

// MARK: - One die (body + six face plates)

@MainActor
private final class DieEntity {
    let kind: DiceKind
    let entity = Entity()
    private var plates: [ModelEntity] = []
    private var textures: [TextureResource?] = Array(repeating: nil, count: 6)
    private var glowing: Int?

    init(kind: DiceKind) {
        self.kind = kind
        var bodyMaterial = PhysicallyBasedMaterial()
        bodyMaterial.baseColor = .init(tint: DiceFaceArt.bodyColor(kind))
        bodyMaterial.metallic = .init(floatLiteral: 0.6)
        bodyMaterial.roughness = .init(floatLiteral: 0.38)
        let body = ModelEntity(mesh: .generateBox(size: DiceCube.edge, cornerRadius: 0.06), materials: [bodyMaterial])
        entity.addChild(body)
        let plateMesh = MeshResource.generatePlane(width: DiceCube.edge * 0.8, height: DiceCube.edge * 0.8)
        for geo in 0..<6 {
            let plate = ModelEntity(mesh: plateMesh, materials: [SimpleMaterial(color: DiceFaceArt.bodyColor(kind), isMetallic: false)])
            plate.orientation = DiceCube.decalRotation(geo: geo)
            plate.position = DiceCube.normals[geo] * (DiceCube.half + 0.003)
            entity.addChild(plate)
            plates.append(plate)
        }
        setFaces { _ in nil }
    }

    /// `rune(serverFace)` → rune asset on that face, nil for a bare face.
    func setFaces(_ rune: (Int) -> String?) {
        for geo in 0..<6 {
            let serverFace = DiceCube.serverFace[geo]
            textures[geo] = DiceFaceArt.texture(kind: kind, serverFace: serverFace, runeAsset: rune(serverFace))
            applyMaterial(geo, glow: 0)
        }
    }

    func glow(face: Int?, amount: Float) {
        if let old = glowing, old != face { applyMaterial(old, glow: 0) }
        glowing = amount > 0.01 ? face : nil
        if let face { applyMaterial(face, glow: amount) }
    }

    private func applyMaterial(_ geo: Int, glow: Float) {
        var m = PhysicallyBasedMaterial()
        if let tex = textures[geo] {
            m.baseColor = .init(tint: .white, texture: .init(tex))
            if glow > 0.01 {
                m.emissiveColor = .init(color: .white, texture: .init(tex))
                m.emissiveIntensity = glow
            }
        } else {
            m.baseColor = .init(tint: DiceFaceArt.bodyColor(kind))
        }
        m.roughness = .init(floatLiteral: 0.5)
        m.metallic = .init(floatLiteral: 0.2)
        plates[geo].model?.materials = [m]
    }
}
