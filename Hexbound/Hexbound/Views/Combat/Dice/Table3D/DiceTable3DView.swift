//
//  DiceTable3DView.swift
//  Hexbound
//
//  The 3D dice table in the battle screen: the RealityKit view, the touch
//  layer (hold · shake · flick, tap a die) and the SwiftUI pieces drawn over
//  it — slot labels, result chips, status tags, the throw cue. Replaces the
//  2D lanes (DiceTableView) unless Reduce Motion is on.
//

import RealityKit
import SwiftUI

struct DiceTable3DView: View {
    @Bindable var vm: DiceBattleViewModel
    /// The boss kill overlay takes over the victory beat in dungeon fights.
    var hideEndCard: Bool = false

    @State private var scene = DiceTableScene()
    @State private var touching = false
    @State private var cuePhase = false

    // Explicit init — the `@State private` vars would make the memberwise one private.
    init(vm: DiceBattleViewModel, hideEndCard: Bool = false) {
        _vm = Bindable(wrappedValue: vm)
        self.hideEndCard = hideEndCard
    }

    var body: some View {
        let overlay = scene.overlay
        ZStack {
            DiceARViewContainer(scene: scene)
                .accessibilityHidden(true)

            // Covers the table while the camera frames it (ARView keeps rendering underneath).
            DarkFantasyTheme.bgPrimary
                .opacity(overlay.ready ? 0 : 1)
                .animation(.easeOut(duration: 0.35), value: overlay.ready)
                .allowsHitTesting(false)

            Color.clear
                .contentShape(Rectangle())
                .gesture(touchGesture)

            labels(overlay)
                .allowsHitTesting(false)

            if overlay.awaitingThrow && !overlay.holding {
                throwCue
                    .position(overlay.cuePoint)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if !hideEndCard {
                switch vm.phase {
                case .ending, .completing: DiceEndCard(vm: vm)
                default: EmptyView()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .animation(.easeOut(duration: 0.2), value: overlay.awaitingThrow)
        .animation(.easeOut(duration: 0.2), value: overlay.holding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilitySummary))
        .accessibilityAction(named: Text("Throw the dice")) { scene.throwNow() }
        .accessibilityAction(named: Text("Change the attack die")) { vm.tapDie(.attack) }
        .accessibilityAction(named: Text("Change the guard die")) { vm.tapDie(.guardDie) }
        .onAppear {
            DiceThrowLibrary.shared.warmUp()
            scene.resume()
            let model = vm
            scene.onTapDie = { [weak model] slot in model?.tapTableDie(slot) }
            scene.setMat(vm.tableMat)
            scene.refreshFaces { vm.faceRunes($0) }
            vm.attachTable(scene)
        }
        .onDisappear {
            vm.detachTable(scene)
            scene.teardown()
        }
        .onChange(of: vm.tableMat) { _, mat in scene.setMat(mat) }
    }

    // MARK: - Touch

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if !touching {
                    touching = true
                    scene.touchBegan(value.startLocation)
                }
                scene.touchMoved(value.location)
            }
            .onEnded { value in
                touching = false
                scene.touchEnded(value.location)
            }
    }

    // MARK: - Overlay

    @ViewBuilder
    private func labels(_ overlay: DiceTableOverlay) -> some View {
        let visible = overlay.labelsVisible && overlay.ready
        let m = vm.match
        ZStack {
            slotLabel("THEIR GUARD", at: overlay.labelPoints[.theirGuard])
            slotLabel("YOUR STRIKE", first: m != nil && vm.playerStrikesFirst, at: overlay.labelPoints[.yourStrike])
            slotLabel("ENEMY STRIKE", first: m != nil && !vm.playerStrikesFirst, at: overlay.labelPoints[.enemyStrike])
            slotLabel("YOUR GUARD", at: overlay.labelPoints[.yourGuard])

            if let p = overlay.labelPoints[.chipMine] { DiceChipView(chip: vm.chipP).position(p) }
            if let p = overlay.labelPoints[.chipTheirs] { DiceChipView(chip: vm.chipO).position(p) }

            if let next = m?.bossNext, let p = overlay.labelPoints[.bossNext] {
                Text("NEXT: \(DiceZone.of(face: next).label.uppercased())")
                    .font(DarkFantasyTheme.badge)
                    .tracking(1)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.8)))
                    .position(p)
            }

            ForEach(statusTags(m), id: \.slot) { tag in
                if let p = overlay.slotPoints[tag.slot] {
                    Text(tag.text)
                        .font(DarkFantasyTheme.badge)
                        .tracking(1.2)
                        .foregroundStyle(DarkFantasyTheme.bgAbyss)
                        .padding(.horizontal, LayoutConstants.spaceXS)
                        .padding(.vertical, LayoutConstants.space2XS)
                        .background(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS).fill(tag.color))
                        .position(x: p.x, y: p.y - overlay.dieSize * 0.7)
                }
            }

            ForEach([DiceBattleViewModel.Slot.pa, .pd], id: \.self) { slot in
                if let p = overlay.slotPoints[slot], vm.canAct || vm.changed.contains(slot) {
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .stroke(DarkFantasyTheme.goldBright.opacity(vm.changed.contains(slot) ? 1 : 0.65), lineWidth: 2)
                        .frame(width: overlay.dieSize * 1.3, height: overlay.dieSize * 1.3)
                        .position(p)
                }
            }
        }
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: visible)
    }

    private func slotLabel(_ text: String, first: Bool = false, at point: CGPoint?) -> some View {
        Group {
            if let point {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(text)
                        .font(DarkFantasyTheme.badge)
                        .tracking(1.5)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                    if first {
                        Text("1ST")
                            .font(DarkFantasyTheme.badge)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                            .badgeCapsule(color: DarkFantasyTheme.gold)
                    }
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.75)))
                .fixedSize()
                .position(point)
            }
        }
    }

    private struct StatusTag {
        let slot: DiceBattleViewModel.Slot
        let text: String
        let color: Color
    }

    private func statusTags(_ m: DiceMatchView?) -> [StatusTag] {
        guard let m else { return [] }
        var tags: [StatusTag] = []
        if m.p.frozen { tags.append(StatusTag(slot: .pa, text: "FROZEN", color: DarkFantasyTheme.cyan)) }
        else if m.p.stunned { tags.append(StatusTag(slot: .pa, text: "STUNNED", color: DarkFantasyTheme.gold)) }
        if m.o.frozen { tags.append(StatusTag(slot: .oa, text: "FROZEN", color: DarkFantasyTheme.cyan)) }
        else if m.o.stunned { tags.append(StatusTag(slot: .oa, text: "STUNNED", color: DarkFantasyTheme.gold)) }
        if m.p.opened { tags.append(StatusTag(slot: .pd, text: "OPEN", color: DarkFantasyTheme.danger)) }
        if m.o.opened { tags.append(StatusTag(slot: .od, text: "OPEN", color: DarkFantasyTheme.danger)) }
        return tags
    }

    private var throwCue: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                Image("ui-arrow-up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .opacity(cuePhase ? (i == 0 ? 1 : 0.35) : (i == 2 ? 1 : 0.35))
                    .accessibilityHidden(true)
            }
            Text("HOLD · SHAKE · FLICK")
                .font(DarkFantasyTheme.badge)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .padding(.top, LayoutConstants.space2XS)
        }
        .padding(.horizontal, LayoutConstants.spaceSM)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(0.6)))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { cuePhase.toggle() }
        }
    }

    private var accessibilitySummary: String {
        guard let s = vm.shown, scene.overlay.labelsVisible else {
            return scene.overlay.awaitingThrow ? "Dice table. Your dice are ready to throw." : "Dice table."
        }
        return "Your strike \(DiceZone.of(face: s.p.a).label) against their guard \(DiceZone.of(face: s.o.d).label). "
            + "Their strike \(DiceZone.of(face: s.o.a).label) against your guard \(DiceZone.of(face: s.p.d).label)."
    }
}

/// Hosts the scene's ARView.
private struct DiceARViewContainer: UIViewRepresentable {
    let scene: DiceTableScene

    func makeUIView(context: Context) -> ARView { scene.makeView() }
    func updateUIView(_ uiView: ARView, context: Context) {}
}
