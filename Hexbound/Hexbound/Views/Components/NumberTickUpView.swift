import SwiftUI

// MARK: - Animated Number Counter (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.9)
// Smoothly interpolates between old and new values.
// Usage: NumberTickUpView(value: viewModel.gold, style: .gold)

struct NumberTickUpView: View {
    let value: Int
    let style: TickUpStyle
    var prefix: String = ""
    var suffix: String = ""
    var duration: Double = MotionConstants.tickUpDuration
    var showSign: Bool = false

    @State private var displayValue: Double = 0
    @State private var previousValue: Int = 0
    @State private var flashColor: Color? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            if !prefix.isEmpty {
                Text(prefix)
                    .font(style.font)
                    .foregroundStyle(style.labelColor)
            }

            Text(formattedNumber)
                .font(style.font)
                .foregroundStyle(flashColor ?? style.valueColor)
                .contentTransition(.numericText(value: displayValue))
                .monospacedDigit()

            if !suffix.isEmpty {
                Text(suffix)
                    .font(style.font)
                    .foregroundStyle(style.labelColor)
            }
        }
        .onAppear {
            displayValue = Double(value)
            previousValue = value
        }
        .onChange(of: value) { oldVal, newVal in
            previousValue = oldVal
            animateToValue(newVal, from: oldVal)
        }
    }

    // MARK: - Animation

    private func animateToValue(_ newVal: Int, from oldVal: Int) {
        let delta = newVal - oldVal

        // Flash color on change
        if delta > 0 {
            flashColor = style.gainFlash
        } else if delta < 0 {
            flashColor = style.lossFlash
        }

        // Animate number
        withAnimation(.easeOut(duration: duration)) {
            displayValue = Double(newVal)
        }

        // Clear flash after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashColor = nil
            }
        }
    }

    // MARK: - Formatting

    private var formattedNumber: String {
        let intDisplay = Int(displayValue)
        let sign = showSign && intDisplay > 0 ? "+" : (showSign && intDisplay < 0 ? "" : "")

        if abs(intDisplay) >= 1_000_000 {
            let millions = Double(intDisplay) / 1_000_000
            return "\(sign)\(String(format: "%.1f", millions))M"
        } else if abs(intDisplay) >= 10_000 {
            let thousands = Double(intDisplay) / 1_000
            return "\(sign)\(String(format: "%.1f", thousands))K"
        } else {
            return "\(sign)\(intDisplay.formatted())"
        }
    }
}

// MARK: - Tick Up Styles

enum TickUpStyle {
    case gold
    case gems
    case xp
    case rating
    case stat
    case plain

    var font: Font {
        switch self {
        case .gold, .gems:
            return DarkFantasyTheme.section(size: LayoutConstants.textCard)
        case .xp, .rating:
            return DarkFantasyTheme.section(size: LayoutConstants.textBody)
        case .stat:
            return DarkFantasyTheme.body(size: LayoutConstants.textBody)
        case .plain:
            return DarkFantasyTheme.body(size: LayoutConstants.textBody)
        }
    }

    var valueColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.textGold
        case .gems: return DarkFantasyTheme.cyan
        case .xp: return DarkFantasyTheme.purple
        case .rating: return DarkFantasyTheme.textPrimary
        case .stat: return DarkFantasyTheme.textPrimary
        case .plain: return DarkFantasyTheme.textPrimary
        }
    }

    var labelColor: Color {
        switch self {
        case .gold: return DarkFantasyTheme.gold
        case .gems: return DarkFantasyTheme.cyan
        default: return DarkFantasyTheme.textSecondary
        }
    }

    var gainFlash: Color {
        switch self {
        case .gold: return DarkFantasyTheme.goldBright
        case .gems: return DarkFantasyTheme.cyan
        case .xp: return DarkFantasyTheme.purple
        case .rating: return DarkFantasyTheme.success
        case .stat: return DarkFantasyTheme.success
        case .plain: return DarkFantasyTheme.success
        }
    }

    var lossFlash: Color {
        DarkFantasyTheme.danger
    }
}

// MARK: - Compact Variant for Inline Use

/// Small inline counter for currency displays, HP text, etc.
struct NumberTickUpText: View {
    let value: Int
    var color: Color = DarkFantasyTheme.textPrimary
    var font: Font = DarkFantasyTheme.body(size: LayoutConstants.textBody)
    var duration: Double = MotionConstants.tickUpShort

    @State private var displayValue: Double = 0

    var body: some View {
        Text("\(Int(displayValue).formatted())")
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: displayValue))
            .onAppear { displayValue = Double(value) }
            .onChange(of: value) { _, newVal in
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = Double(newVal)
                }
            }
    }
}
