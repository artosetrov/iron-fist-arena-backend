//
//  CombatVerdictFlash.swift
//  Hexbound
//
//  Screen-level radial flash keyed off the resolved-round verdict. Opacity
//  only — no scale. Project motion rule: screen emphasis should pulse or
//  fade, not scale-grow. Fires once at the start of `.reveal` and fades out
//  within ~700 ms so the log card + HP drain still read cleanly inside the
//  1.4 s reveal window.
//

import SwiftUI

struct CombatVerdictFlash: View {
    let verdict: RoundVerdict?
    let triggerId: UUID?

    @State private var opacity: Double = 0

    private var flashColor: Color {
        guard let verdict else { return .clear }
        switch verdict {
        case .outplayed: return DarkFantasyTheme.gold
        case .held:      return DarkFantasyTheme.success
        case .struck:    return DarkFantasyTheme.success.opacity(0.7)
        case .outread:   return DarkFantasyTheme.danger
        }
    }

    private var peakOpacity: Double {
        guard let verdict else { return 0 }
        return verdict.isPeak ? 0.22 : 0.14
    }

    var body: some View {
        RadialGradient(
            colors: [flashColor.opacity(peakOpacity), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 520
        )
        .opacity(opacity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .task(id: triggerId) {
            guard triggerId != nil, verdict != nil else {
                opacity = 0
                return
            }
            opacity = 0
            withAnimation(.easeOut(duration: 0.22)) { opacity = 1 }
            try? await Task.sleep(for: .milliseconds(220))
            withAnimation(.easeOut(duration: 0.48)) { opacity = 0 }
        }
    }
}
