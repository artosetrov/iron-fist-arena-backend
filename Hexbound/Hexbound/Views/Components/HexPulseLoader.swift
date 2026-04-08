import SwiftUI

// MARK: - HexPulseLoader
/// Unified loading indicator for the entire app.
/// Replaces ProgressView(), LoadingOverlay diamonds, and SplashView spinner.
///
/// Usage:
///   HexPulseLoader()                       // .standard (50px) — section loading
///   HexPulseLoader(.micro)                 // 18px — inside buttons
///   HexPulseLoader(.compact)               // 32px — inline placeholders
///   HexPulseLoader(.large)                 // 100px — full-screen overlay
///   HexPulseLoader(.large, message: "LOADING")  // with text + ornamental dots

struct HexPulseLoader: View {
    let size: Size
    let message: String?
    let tintColor: Color

    @State private var drawPhase: CGFloat = 0
    @State private var diamondPulse = false
    @State private var dotPulse = false

    enum Size {
        case micro      // 18px — button inline
        case compact    // 32px — small placeholders
        case standard   // 50px — section loading
        case large      // 100px — overlay / splash

        var dimension: CGFloat {
            switch self {
            case .micro: return 18
            case .compact: return 32
            case .standard: return 50
            case .large: return 100
            }
        }

        var strokeWidth: CGFloat {
            switch self {
            case .micro: return 2.5
            case .compact: return 2
            case .standard: return 1.8
            case .large: return 1.5
            }
        }

        var outerStrokeWidth: CGFloat {
            switch self {
            case .micro: return 0
            case .compact: return 1
            case .standard: return 1.2
            case .large: return 1
            }
        }

        var diamondSize: CGFloat {
            switch self {
            case .micro: return 0
            case .compact: return 5
            case .standard: return 8
            case .large: return 14
            }
        }

        var glowRadius: CGFloat {
            switch self {
            case .micro: return 0
            case .compact: return 12
            case .standard: return 24
            case .large: return 50
            }
        }

        var showDiamond: Bool { self != .micro }
        var showGlow: Bool { self != .micro }
        var showOrnamentalDots: Bool { self == .large }
    }

    init(_ size: Size = .standard, message: String? = nil, tintColor: Color = DarkFantasyTheme.gold) {
        self.size = size
        self.message = message
        self.tintColor = tintColor
    }

    // MARK: - Hex polygon points (viewBox 0 0 120 120)
    private static let hexPoints: [CGPoint] = [
        CGPoint(x: 60, y: 8),
        CGPoint(x: 108, y: 32),
        CGPoint(x: 108, y: 88),
        CGPoint(x: 60, y: 112),
        CGPoint(x: 12, y: 88),
        CGPoint(x: 12, y: 32)
    ]

    private var hexPath: Path {
        var path = Path()
        guard let first = Self.hexPoints.first else { return path }
        path.move(to: first)
        for point in Self.hexPoints.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    // Approximate perimeter of the hex at viewBox scale
    private var hexPerimeter: CGFloat { 360 }

    var body: some View {
        VStack(spacing: size == .large ? LayoutConstants.spaceLG : LayoutConstants.spaceMS) {
            // Main hex spinner
            ZStack {
                // Radial glow
                if size.showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    tintColor.opacity(0.2),
                                    tintColor.opacity(0.05),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: size.dimension * 0.7
                            )
                        )
                        .frame(width: size.dimension * 1.6, height: size.dimension * 1.6)
                        .opacity(diamondPulse ? 0.8 : 0.3)
                        .animation(MotionConstants.pulse, value: diamondPulse)
                }

                // Outer static hex outline
                if size.outerStrokeWidth > 0 {
                    hexShape
                        .stroke(
                            DarkFantasyTheme.goldDim.opacity(0.3),
                            lineWidth: size.outerStrokeWidth
                        )
                        .frame(width: size.dimension, height: size.dimension)
                }

                // Animated drawing hex stroke
                hexShape
                    .trim(from: 0, to: drawPhase)
                    .stroke(
                        LinearGradient(
                            colors: [DarkFantasyTheme.goldDim, tintColor, DarkFantasyTheme.goldBright, tintColor, DarkFantasyTheme.goldDim],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: size.strokeWidth, lineCap: .round)
                    )
                    .frame(width: size.dimension, height: size.dimension)
                    .shadow(color: tintColor.opacity(0.4), radius: diamondPulse ? 6 : 2)
                    .animation(MotionConstants.pulse, value: diamondPulse)

                // Center diamond
                if size.showDiamond {
                    Rectangle()
                        .fill(tintColor)
                        .frame(width: size.diamondSize, height: size.diamondSize)
                        .rotationEffect(.degrees(45))
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: diamondPulse ? 8 : 2)
                        .opacity(diamondPulse ? 1 : 0.4)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: diamondPulse
                        )
                }
            }
            .frame(width: size.dimension * (size.showGlow ? 1.6 : 1),
                   height: size.dimension * (size.showGlow ? 1.6 : 1))

            // Message text
            if let message {
                Text(message)
                    .font(size == .large ? DarkFantasyTheme.section : DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(size == .large ? 4 : 2)
                    .textCase(.uppercase)
                    .shadow(color: DarkFantasyTheme.goldBright.opacity(0.3), radius: 12)
            }

            // Ornamental diamond dots (large only)
            if size.showOrnamentalDots {
                ornamentalDots
            }
        }
        .onAppear {
            diamondPulse = true
            dotPulse = true
            startDrawAnimation()
        }
        .onDisappear {
            diamondPulse = false
            dotPulse = false
        }
    }

    // MARK: - Hex Shape
    private var hexShape: some Shape {
        HexagonShape()
    }

    // MARK: - Draw animation (continuous loop)
    private func startDrawAnimation() {
        // Use a repeating timer-like pattern via withAnimation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
            drawPhase = 1.0
        }
    }

    // MARK: - Ornamental dots
    private var ornamentalDots: some View {
        HStack(spacing: 0) {
            // Left line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.goldDim],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 1)

            // Diamond dots
            HStack(spacing: LayoutConstants.spaceMS) {
                ForEach(0..<3, id: \.self) { i in
                    Rectangle()
                        .fill(tintColor)
                        .frame(width: 6, height: 6)
                        .rotationEffect(.degrees(45))
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: dotPulse ? 4 : 0)
                        .opacity(dotPulse ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: MotionConstants.tickUpDuration)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: dotPulse
                        )
                }
            }

            // Right line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldDim, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 1)
        }
    }
}

// MARK: - Hexagon Shape

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        // Flat-top hexagon proportions matching viewBox 0 0 120 120
        // Points: (60,8) (108,32) (108,88) (60,112) (12,88) (12,32)
        let points: [(CGFloat, CGFloat)] = [
            (0.500, 0.067),  // top center
            (0.900, 0.267),  // top right
            (0.900, 0.733),  // bottom right
            (0.500, 0.933),  // bottom center
            (0.100, 0.733),  // bottom left
            (0.100, 0.267)   // top left
        ]

        var path = Path()
        if let first = points.first {
            path.move(to: CGPoint(x: first.0 * w, y: first.1 * h))
        }
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: point.0 * w, y: point.1 * h))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Convenience for button-tinted version

extension HexPulseLoader {
    /// Dark-tinted version for use inside gold/colored buttons
    static func onGold() -> HexPulseLoader {
        HexPulseLoader(.micro, tintColor: DarkFantasyTheme.textOnGold)
    }
}
