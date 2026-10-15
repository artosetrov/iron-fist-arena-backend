//
//  DiceDieView.swift
//  Hexbound
//
//  One die face as players see it in combat and in Hero → Dice:
//  generated face tile (attack red / guard blue) + zone emblem + the socketed
//  rune stone in the corner. Glow, cracks and tags are code, not art
//  (ART_STYLE_GUIDE: "AI paints, code rules").
//

import SwiftUI

struct DiceDieView: View {
    let kind: DiceKind
    /// Face 0…5, nil = not rolled yet (blank die).
    let face: Int?
    /// Asset of the rune on this face, nil = bare face.
    let runeAsset: String?
    var size: CGFloat = 96
    /// While true the face flickers through random faces with a wobble.
    var tumbling: Bool = false
    /// Changes whenever the rune fires — drives a short highlight on the stone.
    var runePulse: Int = 0
    var opened: Bool = false
    var frozen: Bool = false
    var stunned: Bool = false
    var highlighted: Bool = false
    /// Runes on every face of this die — so a tumbling die flashes real runes.
    var faceRunes: [String?] = []

    // Explicit init — the `@State private` vars below would otherwise make the
    // synthesized memberwise init private (see TalentNodeView).
    init(kind: DiceKind,
         face: Int?,
         runeAsset: String?,
         size: CGFloat = 96,
         tumbling: Bool = false,
         runePulse: Int = 0,
         opened: Bool = false,
         frozen: Bool = false,
         stunned: Bool = false,
         highlighted: Bool = false,
         faceRunes: [String?] = []) {
        self.kind = kind
        self.face = face
        self.runeAsset = runeAsset
        self.size = size
        self.tumbling = tumbling
        self.runePulse = runePulse
        self.opened = opened
        self.frozen = frozen
        self.stunned = stunned
        self.highlighted = highlighted
        self.faceRunes = faceRunes
    }

    @State private var flickerFace: Int = 0
    @State private var wobble: Bool = false
    @State private var pulseOn: Bool = false

    private var shownFace: Int? { tumbling ? flickerFace : face }
    private var shownRune: String? {
        if tumbling {
            return faceRunes.indices.contains(flickerFace) ? faceRunes[flickerFace] : nil
        }
        return runeAsset
    }

    var body: some View {
        ZStack {
            Image(kind.tileAsset)
                .resizable()
                .interpolation(.high)
                .scaledToFit()

            if let f = shownFace {
                Image(DiceZone.of(face: f).emblemAsset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.7), radius: 2, y: 2)
            } else {
                Image(DiceZone.head.emblemAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.56, height: size * 0.56)
                    .opacity(0.15)
            }

            if shownFace != nil, let rune = shownRune {
                Image(rune)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size * 0.38, height: size * 0.42)
                    .shadow(color: pulseOn ? DarkFantasyTheme.goldBright.opacity(0.95) : DarkFantasyTheme.bgAbyss.opacity(0.85),
                            radius: pulseOn ? 10 : 3, y: pulseOn ? 0 : 2)
                    .rotationEffect(.degrees(pulseOn ? -10 : 0))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(size * 0.01)
            }

            if opened { statusTag("OPEN", color: DarkFantasyTheme.danger) }
            else if frozen { statusTag("FROZEN", color: DarkFantasyTheme.cyan) }
            else if stunned { statusTag("STUNNED", color: DarkFantasyTheme.gold) }
        }
        .frame(width: size, height: size)
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.goldBright.opacity(0.65), lineWidth: 2)
                    .padding(-3)
            }
            if frozen {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.cyan.opacity(0.12))
                    .allowsHitTesting(false)
            }
        }
        .rotationEffect(.degrees(tumbling ? (wobble ? 9 : -9) : 0))
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.55), radius: 8, y: 6)
        .task(id: tumbling) {
            guard tumbling else { wobble = false; return }
            while !Task.isCancelled {
                flickerFace = Int.random(in: 0...5)
                withAnimation(.linear(duration: 0.07)) { wobble.toggle() }
                try? await Task.sleep(for: .milliseconds(70))
            }
        }
        .onChange(of: runePulse) { _, _ in
            withAnimation(.easeOut(duration: 0.18)) { pulseOn = true }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(520))
                withAnimation(.easeIn(duration: 0.25)) { pulseOn = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
    }

    private func statusTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DarkFantasyTheme.badge)
            .tracking(1.2)
            .foregroundStyle(DarkFantasyTheme.bgAbyss)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS).fill(color))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: -LayoutConstants.spaceSM)
    }

    private var accessibilityText: String {
        guard let f = face else { return "\(kind.title), not rolled" }
        var s = "\(kind.title): \(DiceZone.of(face: f).label)"
        if runeAsset != nil { s += ", rune" }
        if opened { s += ", guard broken" }
        if frozen { s += ", frozen" }
        return s
    }
}
