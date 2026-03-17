import SwiftUI

/// Animated particle effect overlay for battle results.
/// - Victory: gold confetti falling + rising sparkles
/// - Defeat: slow red embers / ash drifting down
struct VictoryParticlesView: View {
    let isVictory: Bool
    let particleCount: Int

    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    init(isVictory: Bool, particleCount: Int = 30) {
        self.isVictory = isVictory
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    particle.shape
                        .frame(width: particle.size, height: particle.size)
                        .foregroundStyle(particle.color)
                        .rotationEffect(.degrees(isAnimating ? particle.rotationEnd : particle.rotationStart))
                        .position(
                            x: isAnimating ? particle.endX : particle.startX,
                            y: isAnimating ? particle.endY : particle.startY
                        )
                        .opacity(isAnimating ? 0 : particle.opacity)
                }
            }
            .onAppear {
                particles = generateParticles(in: geo.size)
                // Stagger start
                withAnimation(.easeOut(duration: 3.0).delay(0.2)) {
                    isAnimating = true
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle Generation

    private func generateParticles(in size: CGSize) -> [Particle] {
        (0..<particleCount).map { _ in
            if isVictory {
                return victoryParticle(in: size)
            } else {
                return defeatParticle(in: size)
            }
        }
    }

    private func victoryParticle(in size: CGSize) -> Particle {
        let startX = CGFloat.random(in: 0...size.width)
        let startY = CGFloat.random(in: -40...size.height * 0.3)
        let drift = CGFloat.random(in: -60...60)
        let colors: [Color] = [
            DarkFantasyTheme.goldBright,
            DarkFantasyTheme.gold,
            DarkFantasyTheme.goldDim,
            .white.opacity(0.8),
            DarkFantasyTheme.success.opacity(0.6)
        ]
        let shapes: [AnyView] = [
            AnyView(Rectangle()),
            AnyView(Circle()),
            AnyView(RoundedRectangle(cornerRadius: 2))
        ]
        return Particle(
            startX: startX,
            startY: startY,
            endX: startX + drift,
            endY: startY + size.height * CGFloat.random(in: 0.6...1.2),
            size: CGFloat.random(in: 3...8),
            color: colors.randomElement()!,
            opacity: Double.random(in: 0.6...1.0),
            rotationStart: Double.random(in: 0...180),
            rotationEnd: Double.random(in: 360...720),
            shape: shapes.randomElement()!
        )
    }

    private func defeatParticle(in size: CGSize) -> Particle {
        let startX = CGFloat.random(in: 0...size.width)
        let startY = CGFloat.random(in: -20...size.height * 0.2)
        let drift = CGFloat.random(in: -30...30)
        let colors: [Color] = [
            DarkFantasyTheme.danger.opacity(0.4),
            DarkFantasyTheme.danger.opacity(0.2),
            Color.gray.opacity(0.3),
            Color.white.opacity(0.1)
        ]
        return Particle(
            startX: startX,
            startY: startY,
            endX: startX + drift,
            endY: startY + size.height * CGFloat.random(in: 0.5...0.9),
            size: CGFloat.random(in: 2...5),
            color: colors.randomElement()!,
            opacity: Double.random(in: 0.3...0.6),
            rotationStart: Double.random(in: 0...90),
            rotationEnd: Double.random(in: 180...360),
            shape: AnyView(Circle())
        )
    }
}

// MARK: - Particle Model

private struct Particle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let color: Color
    let opacity: Double
    let rotationStart: Double
    let rotationEnd: Double
    let shape: AnyView
}
