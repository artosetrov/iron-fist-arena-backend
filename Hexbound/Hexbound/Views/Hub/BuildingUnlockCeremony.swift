import SwiftUI

/// W2.D4 — Ceremonial overlay that plays when a new building unlocks.
///
/// Drives the "a new door has opened" moment — the single biggest retention
/// hook in the first week. Triggered from two places:
///
///   1. Hub first mount when `appState.pendingBuildingUnlocks` is non-empty
///      (populated by the tutorial-victory → hub transition).
///   2. Any mid-game level-up that crosses a threshold in
///      `BuildingUnlockConfig.levels` (wired via level-up modal observer).
///
/// Ceremonies queue: if two buildings unlock at the same level (e.g. dungeon
/// + gold-mine at Lv6) the ceremonies play back-to-back with a short gap.
///
/// Animation: opacity-only staggered reveal per user preference (no scale).
/// Duration: ~3.2s total per ceremony (fade-in 0.4s → hold 2.4s → fade-out 0.4s).
///
/// See: docs/07_ui_ux/W2_D4_UNLOCK_CEREMONY.md
struct BuildingUnlockCeremony: View {
    let entry: BuildingUnlockCatalog.Entry
    let onDismiss: () -> Void

    @State private var backdropOpacity: Double = 0
    @State private var iconOpacity: Double = 0
    @State private var headlineOpacity: Double = 0
    @State private var barkOpacity: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var didDismiss = false

    var body: some View {
        ZStack {
            // Dim backdrop — taps dismiss early
            Color.black
                .opacity(0.75 * backdropOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissEarly() }

            // Radial accent glow behind the icon
            RadialGradient(
                colors: [entry.accent.opacity(0.35), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .opacity(ringOpacity)
            .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceLG) {
                Spacer()

                // Icon badge — no scale, opacity-only
                ZStack {
                    Circle()
                        .stroke(entry.accent.opacity(0.7), lineWidth: 2)
                        .frame(width: 112, height: 112)
                        .opacity(ringOpacity)

                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Circle()
                                .stroke(entry.accent.opacity(0.9), lineWidth: 1),
                        )

                    Image(systemName: entry.icon)
                        .font(DarkFantasyTheme.cinematicTitle)
                        .foregroundStyle(entry.accent)
                        .shadow(color: entry.accent.opacity(0.6), radius: 10)
                }
                .opacity(iconOpacity)

                // Headline
                Text(entry.headline)
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .shadow(color: DarkFantasyTheme.gold.opacity(0.4), radius: 10)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .opacity(headlineOpacity)

                // Snarky NPC line
                Text(entry.barkline)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .opacity(barkOpacity)

                Spacer()

                Text("Tap to continue")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary.opacity(0.7))
                    .padding(.bottom, LayoutConstants.spaceLG)
                    .opacity(barkOpacity)
            }
        }
        .onAppear(perform: playCeremony)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.headline). \(entry.barkline). Tap to continue.")
    }

    // MARK: - Animation

    private func playCeremony() {
        HapticManager.rankUp()
        SFXManager.shared.play(.uiConfirm)

        withAnimation(.easeOut(duration: 0.4)) {
            backdropOpacity = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.4)) { ringOpacity = 1; iconOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.4)) { headlineOpacity = 1 }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeOut(duration: 0.4)) { barkOpacity = 1 }

            // Auto-dismiss after hold
            try? await Task.sleep(for: .milliseconds(2400))
            await MainActor.run { dismissEarly() }
        }
    }

    private func dismissEarly() {
        guard !didDismiss else { return }
        didDismiss = true
        HapticManager.light()
        withAnimation(.easeIn(duration: 0.35)) {
            backdropOpacity = 0
            iconOpacity = 0
            headlineOpacity = 0
            barkOpacity = 0
            ringOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            onDismiss()
        }
    }
}

// MARK: - Ceremony Queue Host

/// Host view that consumes `appState.pendingBuildingUnlocks` one at a time
/// and plays a BuildingUnlockCeremony for each. Attach as an overlay on
/// HubView so the ceremonies appear above the map.
struct BuildingUnlockCeremonyHost: View {
    @Environment(AppState.self) private var appState
    @State private var currentBuildingId: String?

    var body: some View {
        ZStack {
            if let id = currentBuildingId {
                let label = defaultCityBuildings.first { $0.id == id }?.label ?? id
                BuildingUnlockCeremony(
                    entry: BuildingUnlockCatalog.entry(for: id, fallbackLabel: label),
                    onDismiss: advance,
                )
                .transition(.opacity)
                .id(id) // force re-mount per building
            }
        }
        .onAppear(perform: primeIfNeeded)
        .onChange(of: appState.pendingBuildingUnlocks) { _, new in
            // If something else pushed new unlocks while idle, pick them up.
            if currentBuildingId == nil && !new.isEmpty {
                primeIfNeeded()
            }
        }
    }

    private func primeIfNeeded() {
        guard currentBuildingId == nil else { return }
        guard !appState.pendingBuildingUnlocks.isEmpty else { return }
        let next = appState.pendingBuildingUnlocks.removeFirst()
        withAnimation(.easeOut(duration: 0.35)) {
            currentBuildingId = next
        }
    }

    private func advance() {
        withAnimation(.easeIn(duration: 0.3)) {
            currentBuildingId = nil
        }
        // Short gap before the next ceremony feels less jarring
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            primeIfNeeded()
        }
    }
}
