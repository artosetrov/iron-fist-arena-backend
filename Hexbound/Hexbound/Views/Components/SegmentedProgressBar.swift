import SwiftUI

/// Segmented progress bar where each segment represents one unit of progress.
///
/// States:
/// - Empty segments: subtle bg, unfilled
/// - Filled (in progress): cyan gradient + BarFillHighlight shine
/// - Complete (all filled): gold gradient + BarFillHighlight shine
///
/// Auto-fallback: when `target > maxSegments` (e.g. scalar goals like
/// "Spend 1674 gold"), renders a continuous filled bar with the same
/// visual styling instead of 1674 individual segments. This prevents
/// horizontal overflow — an HStack of 1674 rects with 3pt spacing has
/// a minimum width of ~5000pt, which pushes the parent off-screen.
///
/// Usage:
/// ```
/// SegmentedProgressBar(progress: 2, target: 4)                     // cyan in-progress (segmented)
/// SegmentedProgressBar(progress: 4, target: 4)                     // gold complete (segmented)
/// SegmentedProgressBar(progress: 3, target: 5, isBonus: true)      // bonus panel style (segmented)
/// SegmentedProgressBar(progress: 820, target: 1674)                // auto-fallback to continuous
/// ```
struct SegmentedProgressBar: View {
    let progress: Int
    let target: Int
    var isBonus: Bool = false

    /// Max segment count before falling back to a continuous bar.
    /// Chosen so that at a typical card width ~300pt each segment stays
    /// readable (>20pt wide including spacing).
    private let maxSegments: Int = 10

    /// Whether all segments are filled
    private var isComplete: Bool { progress >= target }

    /// Use continuous bar when target exceeds the segment cap.
    private var useContinuous: Bool { target > maxSegments }

    /// Normalized fill ratio 0...1 for the continuous bar.
    private var fillRatio: CGFloat {
        guard target > 0 else { return 0 }
        return min(max(CGFloat(progress) / CGFloat(target), 0), 1)
    }

    var body: some View {
        Group {
            if useContinuous {
                continuousBar
            } else {
                segmentedBar
            }
        }
        .padding(2)
        .frame(height: 10)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .fill(DarkFantasyTheme.bgTertiary)
                .shadow(color: Color.black.opacity(0.45), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
        .accessibilityLabel("Progress")
        .accessibilityValue("\(min(progress, target)) of \(target)")
    }

    // MARK: - Segmented (discrete targets, ≤ maxSegments)

    @ViewBuilder
    private var segmentedBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(target, 1), id: \.self) { index in
                segment(filled: index < progress)
            }
        }
    }

    // MARK: - Continuous (scalar targets, > maxSegments)

    @ViewBuilder
    private var continuousBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Empty track (matches unfilled segment look)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(Color.white.opacity(0.03))

                // Filled portion — same gradient as filled segment
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(segmentFill(filled: true))
                    .overlay {
                        // Top-shine highlight mirroring the segmented version
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.35), Color.clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .frame(height: 4)
                            Spacer(minLength: 0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
                    }
                    .frame(width: max(geo.size.width * fillRatio, fillRatio > 0 ? 2 : 0))
                    .shadow(color: fillRatio > 0 ? segmentGlow : .clear, radius: 3)
            }
        }
    }

    @ViewBuilder
    private func segment(filled: Bool) -> some View {
        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
            .fill(segmentFill(filled: filled))
            .overlay {
                if filled {
                    // Top-shine highlight (mini BarFillHighlight)
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 4)
                        Spacer(minLength: 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
                }
            }
            .shadow(color: filled ? segmentGlow : .clear, radius: 3)
    }

    private func segmentFill(filled: Bool) -> some ShapeStyle {
        if filled {
            if isComplete {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.goldBright, DarkFantasyTheme.goldDim],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [DarkFantasyTheme.cyan, DarkFantasyTheme.cyan.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        } else {
            return AnyShapeStyle(Color.white.opacity(0.03))
        }
    }

    private var segmentGlow: Color {
        isComplete
            ? DarkFantasyTheme.gold.opacity(0.3)
            : DarkFantasyTheme.cyan.opacity(0.25)
    }
}
