import SwiftUI

/// Segmented progress bar where each segment represents one unit of progress.
///
/// States:
/// - Empty segments: subtle bg, unfilled
/// - Filled (in progress): cyan gradient + BarFillHighlight shine
/// - Complete (all filled): gold gradient + BarFillHighlight shine
///
/// Usage:
/// ```
/// SegmentedProgressBar(progress: 2, target: 4)                     // cyan in-progress
/// SegmentedProgressBar(progress: 4, target: 4)                     // gold complete
/// SegmentedProgressBar(progress: 3, target: 5, isBonus: true)      // bonus panel style
/// ```
struct SegmentedProgressBar: View {
    let progress: Int
    let target: Int
    var isBonus: Bool = false

    /// Whether all segments are filled
    private var isComplete: Bool { progress >= target }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(target, 1), id: \.self) { index in
                segment(filled: index < progress)
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
