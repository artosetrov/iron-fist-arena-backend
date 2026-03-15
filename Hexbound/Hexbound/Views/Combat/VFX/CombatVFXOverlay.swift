import SwiftUI

/// Canvas-based particle VFX overlay rendered via TimelineView for 60fps animation.
/// Placed between the main combat UI and the damage popup layer.
struct CombatVFXOverlay: View {
    let vfxManager: CombatVFXManager
    let speedMultiplier: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                vfxManager.update(now: timeline.date, speed: max(0.1, speedMultiplier))
                vfxManager.render(in: &context, size: size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
