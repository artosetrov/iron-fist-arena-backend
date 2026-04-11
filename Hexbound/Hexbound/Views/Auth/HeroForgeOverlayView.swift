import SwiftUI

// MARK: - Hero Forge Overlay (BUG-08)
//
// Root-level loading overlay shown while a new character is being forged and
// the destination screen (`.loreIntro` / `.characterSelect`) is mounting its
// first frame. Previously lived inline inside `OnboardingDetailView`, which
// caused a 2–3s black gap between SAVE and OnboardingCinematicView appearing
// because the overlay was torn down with its parent view before the cinematic
// view finished decoding its large backdrop assets.
//
// Now owned by `HexboundApp` via `appState.isForgingHero`. The overlay
// persists across the `currentScreen` cross-fade, covering the moment when
// the new root view is synchronously decoding `onboarding-city-panorama`
// and `bg-shop`.
//
// Visual: identical to the old inline version — HexPulseLoader, golden title
// line, subtitle, gold CTA-style chrome (RadialGlow + surfaceLighting +
// corner brackets + corner diamonds + dual shadow).
struct HeroForgeOverlayView: View {
    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: LayoutConstants.spaceMD) {
                HexPulseLoader(.standard)

                Text("Forging Your Hero...")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                Text("Sharpening swords, polishing armor...")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(LayoutConstants.spaceLG)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.gold.opacity(0.15),
                    glowIntensity: 0.5,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(
                cornerRadius: LayoutConstants.modalRadius,
                topHighlight: 0.10,
                bottomShadow: 0.16
            )
            .innerBorder(
                cornerRadius: LayoutConstants.modalRadius - 3,
                inset: 3,
                color: DarkFantasyTheme.gold.opacity(0.1)
            )
            .cornerBrackets(
                color: DarkFantasyTheme.gold.opacity(0.5),
                length: 18,
                thickness: 2.0
            )
            .cornerDiamonds(
                color: DarkFantasyTheme.gold.opacity(0.4),
                size: 6
            )
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.gold.opacity(0.18), radius: 10)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 32, y: 8)
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forging your hero")
        .accessibilityHint("Please wait while your character is being created.")
        .onAppear {
            SFXManager.shared.play(.uiUpgradeSuccess)
        }
    }
}
