import SwiftUI

/// Root-level ceremonial overlay announcing a new boss. Fires twice:
///
/// 1. **Dungeons** — once-per-boss on first unlock (locked → current).
///    Full ~2.2s choreography, CTA `CHALLENGE` dismisses the overlay
///    and returns the player to `BossDetailSheet`.
///
/// 2. **Dungeon Rush** — every miniboss reveal. Compact ~1.2s version,
///    CTA `CHALLENGE` fires the fight immediately.
///
/// Owned by `AppState.isBossRevealing` and mounted at root in
/// `HexboundApp.swift` so the overlay survives `currentScreen` and
/// NavigationStack transitions (see CLAUDE.md "Root-Level Overlays").
struct BossRevealOverlayView: View {
    let data: BossRevealData

    @Environment(AppState.self) private var appState

    // Choreography phases — progressed by DispatchQueue.main.asyncAfter.
    // Each phase toggles a bool that drives a `.animation(_, value:)` on
    // the relevant subview. Skip tap jumps straight to `.ready`.
    @State private var phase: Phase = .rising

    private enum Phase: Int, Comparable {
        case rising       // silhouette slides up from bottom
        case impact       // flash + shake + reveal
        case named        // letter-drop name + subtitle
        case ready        // stats chips + CTA

        static func < (l: Self, r: Self) -> Bool { l.rawValue < r.rawValue }
    }

    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0

    // Compact variant trims the choreography in half (Rush tempo).
    private var isCompact: Bool { data.kind == .rushMiniboss }

    var body: some View {
        ZStack {
            atmosphere
            bossLayer
                .offset(x: shakeOffset)
            flashLayer
            contentOverlay
            topBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.black.opacity(0.01)) // catch taps
        .contentShape(Rectangle())
        .onTapGesture { skipToReady() }
        .task { await runChoreography() }
    }

    // MARK: - Atmosphere (background + god ray + dust)

    private var atmosphere: some View {
        ZStack {
            DarkFantasyTheme.bgDungeonGradient
                .ignoresSafeArea()
                .opacity(phase >= .rising ? 1 : 0)

            // God ray — radial glow from top center, tinted by accent
            GeometryReader { geo in
                RadialGradient(
                    colors: [
                        data.accent.opacity(0.18),
                        data.accent.opacity(0.06),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.1),
                    startRadius: 40,
                    endRadius: geo.size.height * 0.8
                )
            }
            .ignoresSafeArea()
            .opacity(phase >= .impact ? 1 : 0)
            .animation(.easeOut(duration: MotionConstants.reward), value: phase)

            // Bottom vignette so content reads against boss artwork
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.75), DarkFantasyTheme.bgAbyss],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(phase >= .rising ? 1 : 0)
        }
        .animation(.easeOut(duration: MotionConstants.overlayFade), value: phase)
    }

    // MARK: - Boss artwork

    private var bossLayer: some View {
        GeometryReader { geo in
            let size = min(geo.size.width * 0.72, 320)
            VStack {
                Spacer(minLength: 0)
                bossImage
                    .frame(width: size, height: size)
                    // DS rule: no scale on reveal — use y-offset + opacity
                    .offset(y: phase >= .impact ? 0 : 60)
                    .opacity(phase >= .rising ? 1 : 0)
                    // silhouette → full brightness on impact
                    .brightness(phase >= .impact ? 0 : -1)
                    .scaleEffect(x: -1, y: 1) // mirror enemy (DS rule)
                    .animation(.easeOut(duration: isCompact ? 0.3 : 0.5), value: phase)
                Spacer(minLength: geo.size.height * 0.32)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var bossImage: some View {
        if UIImage(named: data.imageKey) != nil {
            Image(data.imageKey)
                .resizable()
                .scaledToFit()
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.85), radius: 20, y: 10)
                .shadow(color: data.accent.opacity(phase >= .impact ? 0.35 : 0), radius: 30)
        } else {
            ZStack {
                Circle()
                    .fill(DarkFantasyTheme.bgSecondary)
                Image(systemName: "flame.fill")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(data.accent)
            }
        }
    }

    // MARK: - Flash on impact

    private var flashLayer: some View {
        Rectangle()
            .fill(Color.white)
            .opacity(flashOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Content (ribbon / name / subtitle / chips / CTA)

    private var contentOverlay: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Spacer(minLength: 0)

            newChallengerRibbon
                .opacity(phase >= .impact ? 1 : 0)
                .offset(y: phase >= .impact ? 0 : -12)
                .animation(.easeOut(duration: MotionConstants.reward).delay(0.05), value: phase)

            nameAndSubtitle
                .padding(.top, LayoutConstants.spaceXS)

            Spacer(minLength: LayoutConstants.spaceMD)

            statsChips
                .opacity(phase >= .ready ? 1 : 0)
                .offset(y: phase >= .ready ? 0 : 12)
                .animation(.easeOut(duration: MotionConstants.reward).delay(0.05), value: phase)
                .padding(.horizontal, LayoutConstants.screenPadding)

            ctaButton
                .opacity(phase >= .ready ? 1 : 0)
                .offset(y: phase >= .ready ? 0 : 24)
                .animation(.easeOut(duration: MotionConstants.reward).delay(0.15), value: phase)
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.bottom, LayoutConstants.spaceLG + LayoutConstants.safeAreaBottom)
        }
    }

    private var newChallengerRibbon: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            FiligreeLine(
                color: data.accent.opacity(0.5),
                notchColor: data.accent,
                notchCount: 2,
                notchSize: 3
            )
            .frame(width: 48)

            Text(ribbonCopy)
                .font(DarkFantasyTheme.body.weight(.bold))
                .tracking(4)
                .foregroundStyle(data.accent)

            FiligreeLine(
                color: data.accent.opacity(0.5),
                notchColor: data.accent,
                notchCount: 2,
                notchSize: 3
            )
            .frame(width: 48)
        }
        .shadow(color: data.accent.opacity(0.5), radius: 12)
    }

    private var nameAndSubtitle: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            LetterDropText(
                text: data.name.uppercased(),
                accent: data.accent,
                isVisible: phase >= .named,
                isCompact: isCompact
            )

            if !data.subtitle.isEmpty {
                Text(data.subtitle)
                    .font(DarkFantasyTheme.body.italic())
                    .foregroundStyle(DarkFantasyTheme.textBossDesc)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, LayoutConstants.spaceLG)
                    .opacity(phase >= .ready ? 1 : 0)
                    .animation(.easeOut(duration: MotionConstants.reward), value: phase)
            }
        }
    }

    private var statsChips: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            statChip(label: "LV.", value: "\(data.level)", color: DarkFantasyTheme.gold)
            if data.hp > 0 {
                statChip(label: "HP", value: formatNumber(data.hp), color: DarkFantasyTheme.danger)
            }
            if data.dropCount > 0 {
                statChip(label: "DROPS", value: "\(data.dropCount)", color: DarkFantasyTheme.lootGold)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func statChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
            Text(value)
                .font(DarkFantasyTheme.cardTitle.weight(.bold))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(minWidth: 80)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary.opacity(0.85),
                glowColor: color.opacity(0.15),
                glowIntensity: 0.35,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 1,
            inset: 1,
            color: color.opacity(0.25)
        )
        .cornerDiamonds(color: color.opacity(0.4), size: 4)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 4, y: 2)
    }

    private var ctaButton: some View {
        Button {
            HapticManager.heavy()
            SFXManager.shared.play(.battleStart)
            data.onChallenge()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "bolt.shield.fill")
                    .font(DarkFantasyTheme.cardTitle.bold())
                Text("CHALLENGE")
                    .tracking(3)
            }
        }
        .buttonStyle(.fight(accent: data.accent))
    }

    // MARK: - Top bar (close + skip hint)

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    skipAndDismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.closeButton)

                Spacer()

                Text("TAP TO SKIP")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .opacity(phase < .ready ? 1 : 0)
                    .animation(.easeOut(duration: MotionConstants.fast), value: phase)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.safeAreaTop)

            Spacer()
        }
        .opacity(phase >= .rising ? 1 : 0)
        .animation(.easeIn(duration: MotionConstants.fast).delay(MotionConstants.ceremonyPhase1), value: phase)
    }

    // MARK: - Choreography

    private var ribbonCopy: String {
        data.kind == .rushMiniboss ? "MINIBOSS" : "NEW CHALLENGER"
    }

    private func runChoreography() async {
        // Phase 1 — silhouette rises from below
        try? await Task.sleep(for: .milliseconds(100))
        phase = .rising

        // Phase 2 — impact: flash + shake + growl + reveal
        let riseDuration: UInt64 = isCompact ? 250 : 500
        try? await Task.sleep(for: .milliseconds(Int(riseDuration)))
        guard phase < .impact else { return }  // respect skip
        phase = .impact
        triggerImpact()

        // Phase 3 — letter-drop name
        let afterImpact: UInt64 = isCompact ? 250 : 450
        try? await Task.sleep(for: .milliseconds(Int(afterImpact)))
        guard phase < .named else { return }
        phase = .named

        // Phase 4 — stats chips + subtitle + CTA
        let afterName: UInt64 = isCompact ? 350 : 600
        try? await Task.sleep(for: .milliseconds(Int(afterName)))
        guard phase < .ready else { return }
        phase = .ready
    }

    private func triggerImpact() {
        HapticManager.heavy()
        SFXManager.shared.play(.dungeonBossAppear)

        // White flash (150ms)
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.45 }
        Task {
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.easeOut(duration: 0.25)) { flashOpacity = 0 }
        }

        // Screen shake — four oscillations
        Task {
            for offset in [-8.0, 6.0, -4.0, 2.0, 0.0] {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = CGFloat(offset)
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func skipToReady() {
        guard phase < .ready else {
            // Already ready — tapping outside CTA/close should not dismiss.
            // The user can press CHALLENGE or X to leave.
            return
        }
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            phase = .ready
        }
        HapticManager.selection()
    }

    private func skipAndDismiss() {
        HapticManager.light()
        SFXManager.shared.play(.uiClose)
        data.onSkip()
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Letter-drop text

/// Each character fades in + slides down with a short stagger. No
/// scale (DS rule forbids scale on reveal). Compact variant halves
/// the per-letter stagger for Rush tempo.
private struct LetterDropText: View {
    let text: String
    let accent: Color
    let isVisible: Bool
    let isCompact: Bool

    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(text.enumerated()), id: \.offset) { idx, ch in
                Text(String(ch))
                    .font(.system(size: LayoutConstants.textCinematic, weight: .black, design: .serif))
                    .foregroundStyle(accent)
                    .tracking(2)
                    .shadow(color: accent.opacity(0.6), radius: 16)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 3, y: 2)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -18)
                    .animation(
                        .easeOut(duration: MotionConstants.fast)
                            .delay(Double(idx) * (isCompact ? 0.02 : 0.04)),
                        value: isVisible
                    )
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
}
