import SwiftUI

// MARK: - Hero Forge Overlay (BUG-08)
//
// Root-level cover shown while the destination screen (`.loreIntro` /
// `.characterSelect`) mounts its first frame after "Enter the city". Owned by
// `HexboundApp` via `appState.isForgingHero`; it persists across the
// `currentScreen` cross-fade, covering the moment when the new root view is
// synchronously decoding `onboarding-city-panorama` and `bg-shop`.
//
// Since the Forge Stage redesign (2026-10-16) the forging itself happens in
// `ForgeCeremonyView`, so this cover only says the gates are opening.
struct HeroForgeOverlayView: View {
    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                HexPulseLoader(.standard)

                Text("The gates open...")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Entering the city")
    }
}

// MARK: - Forge Ceremony (forging → reveal)

/// Full-screen ceremony after FORGE HERO: the portrait heats up on the anvil
/// while the server creates the hero, then the reveal shows the hero's real
/// starting stats and Grothmund's greeting.
struct ForgeCeremonyView: View {
    @Bindable var vm: OnboardingViewModel
    let onEnterCity: () -> Void

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.6).ignoresSafeArea()

            if vm.phase == .revealed, let hero = vm.createdCharacter {
                ForgeRevealView(vm: vm, hero: hero, onEnterCity: onEnterCity)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                ForgingView(vm: vm)
                    .transition(.opacity)
            }
        }
    }
}

private struct ForgingView: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false
    @State private var heated = false
    @State private var hammer: Task<Void, Never>?

    private let ring: CGFloat = 260
    private let portrait: CGFloat = 220

    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(
                        DarkFantasyTheme.goldBright.opacity(0.8),
                        style: StrokeStyle(lineWidth: 3, dash: [40, 30])
                    )
                    .frame(width: ring, height: ring)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 1.6).repeatForever(autoreverses: false), value: spin)

                ForgePortrait(skin: vm.selectedSkin, accent: DarkFantasyTheme.goldBright, size: portrait)
                    .brightness(heated ? 0 : -0.9)
                    .saturation(heated ? 1 : 3)
                    .colorMultiply(heated ? .white : DarkFantasyTheme.goldBright)
                    .animation(.easeOut(duration: 2.4), value: heated)

                if !reduceMotion {
                    ForgeSparks()
                        .frame(width: ring, height: ring + 80)
                }
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text("FORGING")
                    .font(DarkFantasyTheme.title)
                    .tracking(8)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("The anvil rings for \(vm.displayName)…")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forging \(vm.displayName)")
        .onAppear {
            spin = true
            heated = true
            hammer = Task {
                // Three anvil strikes while the hero takes shape.
                for _ in 0..<3 {
                    SFXManager.shared.play(.uiTapHeavy)
                    try? await Task.sleep(for: .milliseconds(700))
                    if Task.isCancelled { return }
                }
            }
        }
        .onDisappear { hammer?.cancel() }
    }
}

/// Rising embers around the anvil.
private struct ForgeSparks: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<14 {
                    let seed = Double(i) * 0.731
                    let period = 1.6 + (seed.truncatingRemainder(dividingBy: 0.9))
                    let phase = ((t / period) + seed).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.15 + 0.7 * ((seed * 7.3).truncatingRemainder(dividingBy: 1)))
                        + sin(t * 2 + seed * 10) * 6
                    let y = size.height * (0.85 - 0.8 * phase)
                    let alpha = phase < 0.15 ? phase / 0.15 : 1 - phase
                    let r = 1.5 + 1.5 * (1 - phase)
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.opacity = alpha
                    context.fill(Path(ellipseIn: rect), with: .color(DarkFantasyTheme.goldBright))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ForgeRevealView: View {
    @Bindable var vm: OnboardingViewModel
    let hero: Character
    let onEnterCity: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var slammed = false

    private var accent: Color { DarkFantasyTheme.classColor(for: hero.characterClass) }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Text("A HERO IS FORGED")
                .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                .tracking(6)
                .foregroundStyle(DarkFantasyTheme.gold)
                .padding(.top, LayoutConstants.spaceXL)

            ZStack(alignment: .bottom) {
                HexFrame()
                    .fill(DarkFantasyTheme.bgSecondary)
                    .overlay(HexFrame().stroke(DarkFantasyTheme.goldBright, lineWidth: 3))
                    .overlay(HexFrame().inset(by: 14).stroke(DarkFantasyTheme.goldDim.opacity(0.7), lineWidth: 1.5))
                    .frame(width: 250, height: 286)
                    .shadow(color: accent.opacity(0.5), radius: 30)

                ForgePortrait(skin: vm.selectedSkin, accent: accent, size: 196)
                    .padding(.bottom, 45)

                Text("LV \(hero.level)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.vertical, LayoutConstants.spaceXS)
                    .background(Capsule().fill(DarkFantasyTheme.gold))
                    .offset(y: 6)
            }

            VStack(spacing: LayoutConstants.spaceXS) {
                Text(hero.characterName.uppercased())
                    .font(DarkFantasyTheme.cinematicTitle)
                    .tracking(slammed ? 5 : 22)
                    .opacity(slammed ? 1 : 0)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .shadow(color: accent.opacity(0.75), radius: 14)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(hero.origin.iconAsset)
                        .resizable().scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                    Text("\(hero.origin.displayName) \(hero.characterClass.displayName)".uppercased())
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(2)
                        .foregroundStyle(accent)
                    Image(hero.characterClass.iconAsset)
                        .resizable().scaledToFit()
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                }
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(topStats.enumerated()), id: \.element.key) { index, stat in
                    VStack(spacing: LayoutConstants.space2XS) {
                        Text("\(stat.value)")
                            .font(DarkFantasyTheme.section)
                            .foregroundStyle(index == 0 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textPrimary)
                        Text(ForgeStat.name(stat.key))
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                            .fill(DarkFantasyTheme.bgSecondary.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                            .stroke(index == 0 ? DarkFantasyTheme.gold.opacity(0.6) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
                    )
                    .accessibilityElement(children: .combine)
                }
            }

            Spacer(minLength: LayoutConstants.spaceSM)

            VStack(spacing: LayoutConstants.spaceXS) {
                Text("“\(greeting)”")
                    .font(DarkFantasyTheme.body)
                    .italic()
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("— Grothmund")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.gold)
            }
            .accessibilityElement(children: .combine)

            Button(action: onEnterCity) {
                Text("ENTER THE CITY")
            }
            .buttonStyle(.primary)
            .padding(.bottom, LayoutConstants.spaceMD)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.8)) {
                slammed = true
            }
            NPCVoice.shared.speak(greeting)
        }
        .onDisappear { NPCVoice.shared.stop(greeting) }
    }

    /// Main stat first, then the two highest of the rest — real server values.
    private var topStats: [(key: String, value: Int)] {
        let main = vm.options.classes[hero.characterClass.rawValue]?.mainStat ?? "str"
        let all = ForgeStat.order.compactMap { key -> (key: String, value: Int)? in
            guard let value = ForgeStat.value(key, of: hero) else { return nil }
            return (key, value)
        }
        let mainEntry = all.first { $0.key == main }
        let rest = all.filter { $0.key != main }.sorted { $0.value > $1.value }
        return Array(([mainEntry].compactMap { $0 } + rest).prefix(3))
    }

    private var greeting: String {
        switch hero.characterClass {
        case .warrior: "Another blade for the Arena. Make them remember the name."
        case .rogue: "Quiet feet. Good. The Arena loves a knife it never saw coming."
        case .mage: "Mind the curtains with that fire. The Arena will not."
        case .tank: "A wall with legs. The Arena breaks most things — not you, I wager."
        }
    }
}

/// Pointy-top hexagon frame for the reveal portrait.
private struct HexFrame: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.24))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.76))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + h * 0.76))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + h * 0.24))
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> HexFrame {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
