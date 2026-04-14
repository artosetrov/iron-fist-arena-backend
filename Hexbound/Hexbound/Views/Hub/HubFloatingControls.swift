import SwiftUI

// MARK: - Floating Action Icon

struct FloatingActionIcon: View {
    let systemIcon: String?
    let customIcon: String?
    let badgeActive: Bool
    let accentColor: Color
    var size: CGFloat = 56
    let action: () -> Void

    init(systemIcon: String, badgeActive: Bool, accentColor: Color, size: CGFloat = 56, action: @escaping () -> Void) {
        self.systemIcon = systemIcon
        self.customIcon = nil
        self.badgeActive = badgeActive
        self.accentColor = accentColor
        self.size = size
        self.action = action
    }

    init(customIcon: String, badgeActive: Bool, accentColor: Color, size: CGFloat = 56, action: @escaping () -> Void) {
        self.systemIcon = nil
        self.customIcon = customIcon
        self.badgeActive = badgeActive
        self.accentColor = accentColor
        self.size = size
        self.action = action
    }

    @State private var badgePulse = false

    private var iconSize: CGFloat { size * 0.39 }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let customIcon {
                        Image(customIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                    } else if let systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: iconSize, weight: .semibold)) // dynamic — based on component size param
                            .foregroundStyle(accentColor)
                            .frame(width: size, height: size)
                    }
                }
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 2)

                // Notification badge — gold pulsing dot
                if badgeActive {
                    Circle()
                        .fill(DarkFantasyTheme.goldBright)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(DarkFantasyTheme.bgPrimary, lineWidth: 2)
                        )
                        .shadow(color: DarkFantasyTheme.gold.opacity(badgePulse ? 0.8 : 0.2), radius: badgePulse ? 6 : 2)
                        .offset(x: 2, y: -2)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.scalePress(0.9))
        .contentShape(Circle())
        .onAppear {
            if badgeActive {
                withAnimation(MotionConstants.pulse) {
                    badgePulse = true
                }
            }
        }
        .onDisappear {
            badgePulse = false
        }
    }
}

// MARK: - Floating Sound Toggle (matches FloatingActionIcon style)

struct FloatingSoundToggle: View {
    var size: CGFloat = 56
    private let settings = SettingsManager.shared
    @State private var isMuted: Bool = SettingsManager.shared.isMuted

    // Tap feedback
    @State private var tapScale: CGFloat = 1.0

    // Sound wave rings (expand + fade on tap)
    @State private var waveScales: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var waveOpacities: [Double] = [0.0, 0.0, 0.0]

    // Idle animation (sound on)
    @State private var idleGlow = false
    @State private var eq1: CGFloat = 0.35
    @State private var eq2: CGFloat = 0.5
    @State private var eq3: CGFloat = 0.25

    private var accentColor: Color {
        isMuted ? DarkFantasyTheme.textDisabled : DarkFantasyTheme.gold
    }

    private var glowOpacity: Double {
        if isMuted { return 0.15 }
        return idleGlow ? 0.5 : 0.25
    }

    private var glowRadius: CGFloat {
        if isMuted { return 4 }
        return idleGlow ? 14 : 8
    }

    var body: some View {
        Button {
            performToggle()
        } label: {
            ZStack {
                // Expanding wave rings (tap only)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            DarkFantasyTheme.gold,
                            lineWidth: 1.5 - CGFloat(i) * 0.3
                        )
                        .frame(width: size, height: size)
                        .scaleEffect(waveScales[i])
                        .opacity(waveOpacities[i])
                }

                // Main icon + chrome
                soundButtonContent

                // Equalizer bars below icon (idle indicator)
                if !isMuted {
                    equalizerBars
                        .transition(.opacity.animation(.easeInOut(duration: MotionConstants.normal)))
                }
            }
        }
        .buttonStyle(.scalePress(0.9))
        .contentShape(Circle())
        .onAppear {
            if !isMuted { startIdleLoop() }
        }
        .onDisappear {
            stopIdleLoop()
        }
    }

    // MARK: - Main Button Content

    private var soundButtonContent: some View {
        Image(isMuted ? "hud-sound-off" : "hud-sound-on")
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.75, height: size * 0.75)
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.bgSecondary)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(isMuted ? 0.04 : 0.12), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: size / 2
                            )
                        )
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DarkFantasyTheme.textPrimary.opacity(0.08),
                                    Color.clear,
                                    DarkFantasyTheme.bgAbyss.opacity(0.12)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .overlay(
                Circle()
                    .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [DarkFantasyTheme.textPrimary.opacity(0.08), Color.clear, DarkFantasyTheme.bgAbyss.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(LayoutConstants.spaceXS)
            )
            .shadow(color: accentColor.opacity(glowOpacity), radius: glowRadius, y: 2)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)
            .scaleEffect(tapScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.45), value: tapScale)
            .animation(.easeInOut(duration: 2.5), value: idleGlow)
            .animation(MotionConstants.smooth, value: isMuted)
    }

    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            equalizerBar(height: eq1, maxHeight: 8)
            equalizerBar(height: eq2, maxHeight: 8)
            equalizerBar(height: eq3, maxHeight: 8)
        }
        .offset(y: size * 0.52)
    }

    private func equalizerBar(height: CGFloat, maxHeight: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1) // keep — sub-pixel decorative equalizer bar
            .fill(
                LinearGradient(
                    colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2.5, height: max(2.5, height * maxHeight))
            .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 2)
    }

    // MARK: - Actions

    private func performToggle() {
        isMuted.toggle()
        settings.isMuted = isMuted

        if isMuted {
            AudioManager.shared.stopBGM()
            AmbientManager.shared.stopAll()
            stopIdleLoop()
        } else {
            AudioManager.shared.syncVolume()
            AmbientManager.shared.syncVolume()
            AudioManager.shared.playBGM("stray-city.mp3")
            triggerTapBounce()
            triggerWaves()
            startIdleLoop()
        }
    }

    private func triggerTapBounce() {
        tapScale = 1.15
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            tapScale = 1.0
        }
    }

    private func triggerWaves() {
        let delays: [Int] = [0, 100, 200]
        let maxScales: [CGFloat] = [1.7, 2.0, 2.3]

        for i in 0..<3 {
            Task { @MainActor in
                if delays[i] > 0 {
                    try? await Task.sleep(for: .milliseconds(delays[i]))
                }
                waveScales[i] = 1.0
                waveOpacities[i] = 0.4 - Double(i) * 0.06
                withAnimation(.easeOut(duration: 0.65)) {
                    waveScales[i] = maxScales[i]
                    waveOpacities[i] = 0.0
                }
            }
        }
    }

    private func startIdleLoop() {
        withAnimation(MotionConstants.breathing) {
            idleGlow = true
        }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            eq1 = 0.9
        }
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(0.15)) {
            eq2 = 0.85
        }
        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.3)) {
            eq3 = 1.0
        }
    }

    private func stopIdleLoop() {
        idleGlow = false
        eq1 = 0.35
        eq2 = 0.5
        eq3 = 0.25
    }
}
