import SwiftUI

// MARK: - Combat FX Image Overlay
// Renders PNG combat effect images as animated overlays.
// Placed BETWEEN the main UI layer and the Canvas VFX particle layer.
//
// Layer order (bottom → top):
//   1. Background (bgAbyss)
//   2. Main UI (fighters, HP, log)
//   3. ★ THIS LAYER — PNG FX images
//   4. Canvas VFX particles (CombatVFXOverlay)
//   5. Damage popups
//   6. Crit flash / Victory tint

@MainActor @Observable
final class CombatFXImageManager {

    // Active FX instances currently animating
    var activeFX: [ActiveImageFX] = []

    /// Maximum concurrent FX to prevent GPU overload
    private let maxConcurrent = 4

    /// Spawn an FX image at the specified position.
    /// - Parameters:
    ///   - descriptor: The FX descriptor from CombatFXAssetMap
    ///   - defenderPosition: Normalized (0-1) position of the defender
    ///   - attackerPosition: Normalized (0-1) position of the attacker
    ///   - speed: Speed multiplier (0.5 for 2x, 1.0 for 1x)
    func trigger(
        _ descriptor: CombatFXDescriptor,
        defenderPos: CGPoint,
        attackerPos: CGPoint,
        speed: Double
    ) {
        // Cap concurrent FX
        if activeFX.count >= maxConcurrent {
            activeFX.removeFirst()
        }

        // Main FX
        let mainFX = ActiveImageFX(
            asset: descriptor.asset,
            mode: descriptor.mode,
            normalizedPosition: positionForMode(descriptor.mode, defenderPos: defenderPos, attackerPos: attackerPos),
            duration: durationForMode(descriptor.mode) * speed,
            rotation: Double.random(in: -8...8)
        )
        activeFX.append(mainFX)
        scheduleRemoval(id: mainFX.id, after: durationForMode(descriptor.mode) * speed + 0.05)

        // Crit overlay (fullscreen text on top of damage FX)
        if let critAsset = descriptor.critOverlay {
            let critFX = ActiveImageFX(
                asset: critAsset,
                mode: .fullscreen,
                normalizedPosition: CGPoint(x: 0.5, y: 0.38),
                duration: 0.6 * speed,
                rotation: 0
            )
            // Slight delay so crit text appears just after hit
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.08 * speed))
                if activeFX.count >= maxConcurrent { activeFX.removeFirst() }
                activeFX.append(critFX)
                scheduleRemoval(id: critFX.id, after: 0.6 * speed + 0.05)
            }
        }
    }

    /// Clear all active FX (called on skip)
    func clearAll() {
        activeFX.removeAll()
    }

    // MARK: - Helpers

    private func positionForMode(
        _ mode: CombatFXMode,
        defenderPos: CGPoint,
        attackerPos: CGPoint
    ) -> CGPoint {
        switch mode {
        case .onDefender:
            return defenderPos
        case .onAttacker:
            return attackerPos
        case .fullscreen:
            return CGPoint(x: 0.5, y: 0.38)
        }
    }

    private func durationForMode(_ mode: CombatFXMode) -> Double {
        switch mode {
        case .onDefender: return 0.45
        case .onAttacker: return 0.45
        case .fullscreen: return 0.6
        }
    }

    private func scheduleRemoval(id: UUID, after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            activeFX.removeAll { $0.id == id }
        }
    }
}

// MARK: - Active Image FX Instance

struct ActiveImageFX: Identifiable {
    let id = UUID()
    let asset: String
    let mode: CombatFXMode
    let normalizedPosition: CGPoint
    let duration: Double
    let rotation: Double
}

// MARK: - CombatFXImageOverlay View

struct CombatFXImageOverlay: View {
    let fxManager: CombatFXImageManager

    var body: some View {
        GeometryReader { geo in
            ForEach(fxManager.activeFX) { fx in
                FXImageAnimator(
                    fx: fx,
                    containerSize: geo.size
                )
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Individual FX Image Animator

private struct FXImageAnimator: View {
    let fx: ActiveImageFX
    let containerSize: CGSize

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var rotationAngle: Double = 0

    private var fxSize: CGFloat {
        switch fx.mode {
        case .onDefender: return 160
        case .onAttacker: return 150
        case .fullscreen: return 240
        }
    }

    var body: some View {
        Image(fx.asset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: fxSize, height: fxSize)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotationAngle))
            .position(
                x: fx.normalizedPosition.x * containerSize.width,
                y: fx.normalizedPosition.y * containerSize.height
            )
            .shadow(
                color: fxShadowColor.opacity(0.4),
                radius: 12
            )
            .onAppear {
                animateIn()
            }
    }

    private var fxShadowColor: Color {
        // Tint shadow based on asset name for extra glow
        let name = fx.asset.lowercased()
        if name.contains("physical") || name.contains("crit") {
            return DarkFantasyTheme.gold
        } else if name.contains("magical") {
            return DarkFantasyTheme.classMage
        } else if name.contains("poison") {
            return DarkFantasyTheme.success
        } else if name.contains("fire") {
            return DarkFantasyTheme.danger
        } else if name.contains("true") || name.contains("lightning") || name.contains("block") {
            return DarkFantasyTheme.info
        } else if name.contains("heal") {
            return DarkFantasyTheme.success
        }
        return DarkFantasyTheme.gold
    }

    private func animateIn() {
        let duration = fx.duration

        // Phase 1: Pop in (0→30% of duration)
        let popDuration = duration * 0.30
        withAnimation(.easeOut(duration: popDuration)) {
            opacity = 1.0
            scale = fx.mode == .fullscreen ? 1.1 : 1.15
            rotationAngle = fx.rotation
        }

        // Phase 2: Settle (30→55% of duration)
        let settleDuration = duration * 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + popDuration) {
            withAnimation(.easeInOut(duration: settleDuration)) {
                scale = 1.0
            }
        }

        // Phase 3: Fade out (55→100% of duration)
        let fadeDelay = duration * 0.55
        let fadeDuration = duration * 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay) {
            withAnimation(.easeIn(duration: fadeDuration)) {
                opacity = 0
                scale = 1.08
            }
        }
    }
}
