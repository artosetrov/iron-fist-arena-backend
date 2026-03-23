import SwiftUI

// MARK: - Ornamental Design System
// Reusable visual primitives for the dark fantasy UI: corner brackets, diamond accents,
// inner bevel borders, surface lighting overlays, and radial glow backgrounds.
// All effects are pure SwiftUI — no image assets required.

// MARK: - Corner L-Bracket Overlay
/// Draws L-shaped bracket accents at each corner of the view.
/// Inspired by medieval manuscript frames and dark fantasy UI kits.
struct CornerBracketOverlay: View {
    var color: Color = DarkFantasyTheme.borderMedium
    var length: CGFloat = 18
    var thickness: CGFloat = 2.0
    var inset: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Top-left
            Path { p in
                p.move(to: CGPoint(x: inset, y: inset + length))
                p.addLine(to: CGPoint(x: inset, y: inset))
                p.addLine(to: CGPoint(x: inset + length, y: inset))
            }
            .stroke(color, lineWidth: thickness)

            // Top-right
            Path { p in
                p.move(to: CGPoint(x: w - inset - length, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset))
                p.addLine(to: CGPoint(x: w - inset, y: inset + length))
            }
            .stroke(color, lineWidth: thickness)

            // Bottom-left
            Path { p in
                p.move(to: CGPoint(x: inset, y: h - inset - length))
                p.addLine(to: CGPoint(x: inset, y: h - inset))
                p.addLine(to: CGPoint(x: inset + length, y: h - inset))
            }
            .stroke(color, lineWidth: thickness)

            // Bottom-right
            Path { p in
                p.move(to: CGPoint(x: w - inset - length, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset))
                p.addLine(to: CGPoint(x: w - inset, y: h - inset - length))
            }
            .stroke(color, lineWidth: thickness)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Corner Diamond Overlay
/// Places small rotated-square diamond accents at each corner.
struct CornerDiamondOverlay: View {
    var color: Color = DarkFantasyTheme.borderStrong
    var size: CGFloat = 6
    var offset: CGFloat = 3.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let positions = [
                CGPoint(x: -offset, y: -offset),
                CGPoint(x: w + offset, y: -offset),
                CGPoint(x: -offset, y: h + offset),
                CGPoint(x: w + offset, y: h + offset)
            ]

            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(45))
                    .position(positions[i])
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Side Diamond Overlay
/// Places diamond accents at the left and right center edges of the view.
struct SideDiamondOverlay: View {
    var color: Color = DarkFantasyTheme.borderStrong
    var size: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height / 2

            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
                .position(x: -(size / 2 + 1), y: h)

            Rectangle()
                .fill(color)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(45))
                .position(x: geo.size.width + size / 2 + 1, y: h)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Inner Border Overlay
/// A secondary inset border that creates a bevel/frame-within-frame effect.
/// Top edge is brighter (highlight), bottom edge is darker (shadow) for 3D convexity.
struct InnerBorderOverlay: View {
    var cornerRadius: CGFloat = 9
    var inset: CGFloat = 3
    var highlightColor: Color = Color.white.opacity(0.10)
    var shadowColor: Color = Color.black.opacity(0.20)
    var baseColor: Color = DarkFantasyTheme.borderMedium.opacity(0.35)

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [highlightColor, baseColor, shadowColor],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
            .padding(inset)
            .allowsHitTesting(false)
    }
}

// MARK: - Surface Lighting Overlay
/// Simulates top-down lighting on a convex surface: bright top edge, dark bottom edge.
/// Apply as `.overlay()` on any filled shape.
struct SurfaceLightingOverlay: View {
    var cornerRadius: CGFloat = 12
    var topHighlight: Double = 0.12
    var bottomShadow: Double = 0.18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(topHighlight),
                        Color.clear,
                        Color.black.opacity(bottomShadow)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Radial Glow Background
/// Subtle radial gradient that makes the center of a panel slightly brighter.
/// Creates depth on dark backgrounds.
struct RadialGlowBackground: View {
    var baseColor: Color = DarkFantasyTheme.bgSecondary
    var glowColor: Color = DarkFantasyTheme.bgTertiary
    var glowIntensity: Double = 0.6
    var cornerRadius: CGFloat = 12
    /// Glow radius scales to view size when nil; set manually to override
    var glowRadius: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let radius = glowRadius ?? max(geo.size.width, geo.size.height) * 0.6
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(baseColor)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [glowColor.opacity(glowIntensity), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
            }
        }
    }
}

// MARK: - Bar Fill Highlight
/// Top-edge shine on progress bar fills for a glossy/3D look.
struct BarFillHighlight: View {
    var cornerRadius: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .frame(height: 14)
            Spacer(minLength: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
    }
}

// MARK: - Ornamental Diamond Divider Center Motif
/// A small ◆◇◆ diamond motif used at the center of ornamental dividers.
struct DiamondDividerMotif: View {
    var accentColor: Color = DarkFantasyTheme.goldDim
    var dotColor: Color = DarkFantasyTheme.borderMedium
    var accentSize: CGFloat = 7
    var dotSize: CGFloat = 5

    var body: some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(accentColor)
                .frame(width: accentSize, height: accentSize)
                .rotationEffect(.degrees(45))
                .shadow(color: accentColor.opacity(0.3), radius: 4)
            Rectangle()
                .fill(dotColor)
                .frame(width: dotSize, height: dotSize)
                .rotationEffect(.degrees(45))
        }
    }
}

// MARK: - Double Border Frame
/// Two concentric rounded-rect strokes with a gap between them.
/// Creates the "frame within frame" depth typical of dark fantasy UI kits.
struct DoubleBorderOverlay: View {
    var outerColor: Color = DarkFantasyTheme.borderMedium
    var innerColor: Color = DarkFantasyTheme.borderSubtle
    var cornerRadius: CGFloat = 12
    var gap: CGFloat = 4
    var outerWidth: CGFloat = 1.5
    var innerWidth: CGFloat = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(outerColor, lineWidth: outerWidth)
            RoundedRectangle(cornerRadius: cornerRadius - gap)
                .stroke(innerColor, lineWidth: innerWidth)
                .padding(gap)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Scrollwork Divider
/// A more elaborate divider with curving end-caps and a center diamond motif.
/// The ends taper from the center outward using a gradient stroke + small "S" curves.
struct ScrollworkDivider: View {
    var color: Color = DarkFantasyTheme.borderMedium
    var accentColor: Color = DarkFantasyTheme.goldDim
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let midY = height / 2

            // Left scroll curl
            Path { p in
                p.move(to: CGPoint(x: 0, y: midY))
                p.addQuadCurve(
                    to: CGPoint(x: 24, y: midY - 4),
                    control: CGPoint(x: 12, y: midY + 6)
                )
                p.addLine(to: CGPoint(x: w * 0.38, y: midY - 1))
            }
            .stroke(
                LinearGradient(
                    colors: [color.opacity(0.0), color.opacity(0.6), color],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1.5
            )

            // Right scroll curl (mirrored)
            Path { p in
                p.move(to: CGPoint(x: w, y: midY))
                p.addQuadCurve(
                    to: CGPoint(x: w - 24, y: midY - 4),
                    control: CGPoint(x: w - 12, y: midY + 6)
                )
                p.addLine(to: CGPoint(x: w * 0.62, y: midY - 1))
            }
            .stroke(
                LinearGradient(
                    colors: [color.opacity(0.0), color.opacity(0.6), color],
                    startPoint: .trailing,
                    endPoint: .leading
                ),
                lineWidth: 1.5
            )

            // Center motif
            DiamondDividerMotif(
                accentColor: accentColor,
                dotColor: color,
                accentSize: 6,
                dotSize: 4
            )
            .position(x: w / 2, y: midY)
        }
        .frame(height: height)
    }
}

// MARK: - Filigree Edge Line
/// A subtle decorative line with tiny diamond notches at intervals.
/// Use along long edges (top/bottom of headers, section separators).
struct FiligreeLine: View {
    var color: Color = DarkFantasyTheme.borderMedium
    var notchColor: Color = DarkFantasyTheme.borderStrong
    var notchCount: Int = 3
    var notchSize: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            // Base line
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0.5))
                p.addLine(to: CGPoint(x: w, y: 0.5))
            }
            .stroke(color, lineWidth: 1)

            // Diamond notches evenly spaced
            let spacing = w / CGFloat(notchCount + 1)
            ForEach(0..<notchCount, id: \.self) { i in
                Rectangle()
                    .fill(notchColor)
                    .frame(width: notchSize, height: notchSize)
                    .rotationEffect(.degrees(45))
                    .position(x: spacing * CGFloat(i + 1), y: 0.5)
            }
        }
        .frame(height: notchSize + 2)
        .allowsHitTesting(false)
    }
}

// MARK: - Etched Groove
/// Double-line groove effect: dark top line + bright bottom line, engraved look.
/// Common in dark fantasy UI for separating sections without ornamental elements.
struct EtchedGroove: View {
    var darkColor: Color = Color.black.opacity(0.25)
    var lightColor: Color = Color.white.opacity(0.06)

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(darkColor).frame(height: 1)
            Rectangle().fill(lightColor).frame(height: 1)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Convenience View Extensions

extension View {
    /// Adds ornamental corner L-brackets to the view.
    func cornerBrackets(
        color: Color = DarkFantasyTheme.borderMedium,
        length: CGFloat = 18,
        thickness: CGFloat = 2.0
    ) -> some View {
        overlay(CornerBracketOverlay(color: color, length: length, thickness: thickness))
    }

    /// Adds diamond accents at each corner.
    func cornerDiamonds(
        color: Color = DarkFantasyTheme.borderStrong,
        size: CGFloat = 6
    ) -> some View {
        overlay(CornerDiamondOverlay(color: color, size: size))
    }

    /// Adds diamond accents at left and right center edges.
    func sideDiamonds(
        color: Color = DarkFantasyTheme.borderStrong,
        size: CGFloat = 6
    ) -> some View {
        overlay(SideDiamondOverlay(color: color, size: size))
    }

    /// Adds an inner bevel border for depth.
    func innerBorder(
        cornerRadius: CGFloat = 9,
        inset: CGFloat = 3,
        color: Color = DarkFantasyTheme.borderMedium.opacity(0.35)
    ) -> some View {
        overlay(InnerBorderOverlay(cornerRadius: cornerRadius, inset: inset, baseColor: color))
    }

    /// Adds surface lighting overlay (top bright, bottom dark).
    func surfaceLighting(
        cornerRadius: CGFloat = 12,
        topHighlight: Double = 0.12,
        bottomShadow: Double = 0.18
    ) -> some View {
        overlay(SurfaceLightingOverlay(cornerRadius: cornerRadius, topHighlight: topHighlight, bottomShadow: bottomShadow))
    }

    /// Adds a double-border frame (outer + inner concentric strokes).
    func doubleBorder(
        outerColor: Color = DarkFantasyTheme.borderMedium,
        innerColor: Color = DarkFantasyTheme.borderSubtle,
        cornerRadius: CGFloat = 12,
        gap: CGFloat = 4
    ) -> some View {
        overlay(DoubleBorderOverlay(
            outerColor: outerColor,
            innerColor: innerColor,
            cornerRadius: cornerRadius,
            gap: gap
        ))
    }

    /// Adds an etched groove (dark + light hairline pair) for engraved separators.
    func etchedGroove() -> some View {
        overlay(
            VStack {
                Spacer()
                EtchedGroove()
            }
        )
    }

    /// Full ornamental frame: brackets + diamonds + inner border.
    /// Use on panels, cards, buttons, modals.
    func ornamentalFrame(
        bracketColor: Color = DarkFantasyTheme.borderMedium,
        diamondColor: Color = DarkFantasyTheme.borderStrong,
        innerBorderColor: Color = DarkFantasyTheme.borderMedium.opacity(0.35),
        cornerRadius: CGFloat = 9,
        showSideDiamonds: Bool = false
    ) -> some View {
        self
            .innerBorder(cornerRadius: cornerRadius, color: innerBorderColor)
            .cornerBrackets(color: bracketColor)
            .cornerDiamonds(color: diamondColor)
            .if(showSideDiamonds) { view in
                view.sideDiamonds(color: diamondColor)
            }
    }

    /// Premium ornamental frame: double border + brackets + diamonds + inner bevel + surface lighting.
    /// For important panels (modals, loot cards, boss rewards).
    func premiumFrame(
        borderColor: Color = DarkFantasyTheme.borderOrnament,
        accentColor: Color = DarkFantasyTheme.goldBright,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self
            .doubleBorder(outerColor: borderColor, innerColor: borderColor.opacity(0.4), cornerRadius: cornerRadius, gap: 4)
            .innerBorder(cornerRadius: cornerRadius - 6, inset: 6, color: accentColor.opacity(0.12))
            .surfaceLighting(cornerRadius: cornerRadius)
            .cornerBrackets(color: accentColor, length: 20, thickness: 2.0)
            .cornerDiamonds(color: accentColor, size: 7)
            .sideDiamonds(color: borderColor)
    }
}

// Note: `if` conditional modifier is defined in WidgetPill.swift (shared across project)
