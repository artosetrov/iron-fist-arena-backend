//
//  DiceTabView.swift
//  Hexbound
//
//  Hero → DICE (DICE_RUNES_DESIGN.md §5). Each die: six faces in a 3×2 grid,
//  a rune sits in the corner of its face; open sockets show as rings, closed
//  ones as a lock with the level that opens them. Tap a face → rune picker.
//  Runes are unlocked in TALENTS; socketing is free and instant out of combat.
//

import SwiftUI

struct DiceTabView: View {
    @Bindable var vm: DiceTabViewModel
    /// Jump to the TALENTS tab (to unlock a rune).
    var onOpenTalents: () -> Void = {}

    var body: some View {
        VStack(spacing: LayoutConstants.sectionGap) {
            if let data = vm.data {
                intro(data)
                diePanel(.attack, data: data)
                diePanel(.guardDie, data: data)
            } else if vm.isLoading {
                HexPulseLoader(.compact)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let err = vm.errorMessage {
                ErrorStateView.loadFailed(message: err) { Task { await vm.load() } }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .task { await vm.load() }
        .overlay {
            if let pick = vm.picking, let data = vm.data {
                RunePickerOverlay(vm: vm, data: data, kind: pick.kind, face: pick.face, onOpenTalents: {
                    vm.picking = nil
                    onOpenTalents()
                })
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: vm.picking?.face)
    }

    // MARK: - Intro

    private func intro(_ data: DiceLoadoutResponse) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            ZStack {
                Image("dice-showcase-guard")
                    .resizable().scaledToFit()
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(8))
                    .offset(x: 18, y: 6)
                Image("dice-showcase-attack")
                    .resizable().scaledToFit()
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -10)
            }
            .frame(width: 96, height: 76)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("YOUR DICE")
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("A rune fires when its face lands. Unlock runes in Talents, socket them here — free, any time out of combat.")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .cardShadow()
    }

    // MARK: - Die panel

    private func diePanel(_ kind: DiceKind, data: DiceLoadoutResponse) -> some View {
        let die = data.loadout(kind)
        let columns = Array(repeating: GridItem(.flexible(), spacing: LayoutConstants.spaceSM), count: 3)
        return VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack(alignment: .firstTextBaseline) {
                Text(kind.title.uppercased())
                    .font(DarkFantasyTheme.cardTitle)
                    .tracking(1.5)
                    .foregroundStyle(kind == .attack ? DarkFantasyTheme.danger : DarkFantasyTheme.info)
                Spacer()
                Text("\(die.used)/\(die.sockets) runes")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: LayoutConstants.spaceSM) {
                ForEach(0..<6, id: \.self) { face in
                    faceCell(kind, face: face, data: data)
                }
            }

            HStack {
                Text("Rune lands \(Int((die.landChance * 100).rounded()))% of rounds")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Spacer()
                if let next = die.nextSocketLevel {
                    Text("Next socket at Lv. \(next)")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(panelBackground)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: (kind == .attack ? DarkFantasyTheme.danger : DarkFantasyTheme.info).opacity(0.35), length: 14, thickness: 1.5)
        .compositingGroup()
        .cardShadow()
    }

    private func faceCell(_ kind: DiceKind, face: Int, data: DiceLoadoutResponse) -> some View {
        let die = data.loadout(kind)
        let key = vm.runeKey(kind, face: face)
        let rune = data.rune(key)
        let saving = vm.savingFace?.kind == kind && vm.savingFace?.face == face
        let canAddMore = die.used < die.sockets
        return Button { vm.tapFace(kind, face: face) } label: {
            VStack(spacing: LayoutConstants.space2XS) {
                ZStack(alignment: .bottomTrailing) {
                    DiceDieView(kind: kind, face: face, runeAsset: rune?.asset, size: 84)
                    if rune == nil {
                        Image(canAddMore ? "rune-socket-empty" : "rune-socket-locked")
                            .resizable().scaledToFit()
                            .frame(width: 26, height: 26)
                            .opacity(canAddMore ? 0.9 : 0.55)
                            .padding(LayoutConstants.spaceXS)
                    }
                }
                .opacity(saving ? 0.5 : 1)
                Text(rune?.name.uppercased() ?? DiceZone.of(face: face).label.uppercased())
                    .font(DarkFantasyTheme.badge)
                    .tracking(1)
                    .foregroundStyle(rune == nil ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.goldBright)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(kind.title), \(DiceZone.of(face: face).label) face\(rune.map { ", rune \($0.name)" } ?? ", empty")"))
    }

    private var panelBackground: some View {
        RadialGlowBackground(
            baseColor: DarkFantasyTheme.bgSecondary,
            glowColor: DarkFantasyTheme.bgTertiary,
            glowIntensity: 0.4,
            cornerRadius: LayoutConstants.cardRadius
        )
    }
}

// MARK: - Rune picker

struct RunePickerOverlay: View {
    @Bindable var vm: DiceTabViewModel
    let data: DiceLoadoutResponse
    let kind: DiceKind
    let face: Int
    let onOpenTalents: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            DarkFantasyTheme.bgAbyss.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { vm.picking = nil }

            VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(kind == .attack ? "ATTACK" : "GUARD") RUNES")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Text("\(DiceZone.of(face: face).label) face")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Button { vm.picking = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.closeButton)
                        .accessibilityLabel("Close")
                }

                if data.loadout(kind).sockets == 0 {
                    Text("No socket on this die yet — the first opens at Lv. \(data.loadout(kind).nextSocketLevel ?? 2).")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }

                ScrollView {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        if let current = data.rune(vm.runeKey(kind, face: face)) {
                            Button { vm.socket(nil, kind: kind, face: face) } label: {
                                row(current, trailing: "TAKE OFF", trailingColor: DarkFantasyTheme.danger, dim: false)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(vm.runes(for: kind).filter { $0.key != vm.runeKey(kind, face: face) }) { rune in
                            if rune.owned {
                                Button { vm.socket(rune, kind: kind, face: face) } label: {
                                    row(rune, trailing: rune.socketed.map { "MOVE FROM \(DiceZone.of(face: $0.face).label.uppercased())" } ?? "SOCKET",
                                        trailingColor: DarkFantasyTheme.goldBright, dim: false)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: onOpenTalents) {
                                    row(rune, trailing: "UNLOCK", trailingColor: DarkFantasyTheme.textTertiary, dim: true,
                                        footnote: "Talents · \(rune.nodeName ?? rune.name) · \(rune.nodeCost ?? 1) SP")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 420)
            }
            .padding(LayoutConstants.spaceMD)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.bgTertiary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 18, thickness: 1.5)
            .compositingGroup()
            .padding(.horizontal, LayoutConstants.spaceSM)
        }
    }

    private func row(_ rune: DiceRuneEntry, trailing: String, trailingColor: Color, dim: Bool, footnote: String? = nil) -> some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Image(rune.asset)
                .resizable().scaledToFit()
                .frame(width: 44, height: 50)
                .saturation(dim ? 0 : 1)
                .opacity(dim ? 0.5 : 1)
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Text(rune.name.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(dim ? DarkFantasyTheme.textTertiary : DarkFantasyTheme.textPrimary)
                    Text(rune.tierLabel.uppercased())
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(rune.tier == "great" ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary)
                }
                Text(rune.desc)
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let footnote {
                    Text(footnote)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            Spacer(minLength: LayoutConstants.spaceXS)
            Text(trailing)
                .font(DarkFantasyTheme.badge)
                .tracking(1)
                .foregroundStyle(trailingColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(LayoutConstants.spaceSM)
        .frame(minHeight: 56)
        .background(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG).fill(DarkFantasyTheme.bgTertiary))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG).stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1))
    }
}
