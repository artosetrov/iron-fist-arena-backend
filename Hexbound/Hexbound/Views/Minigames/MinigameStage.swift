import SwiftUI

// MARK: - Minigame stage (variant A, 2026-11-04)
//
// The game fills the screen; one dock at the bottom carries the bet and the
// action. No scroll, no info plates: the payout is said where you decide
// ("Find the ball — win 200"), the rules and odds sit behind one link, the
// balance lives in the toolbar. Used by the Fortune Wheel and the Shell Game.

/// Gold balance for the toolbar's trailing slot.
struct MinigameGoldPill: View {
    let gold: Int

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image("icon-gold")
                .resizable()
                .interpolation(.high)
                .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
            NumberTickUpText(value: gold, color: DarkFantasyTheme.goldBright, font: DarkFantasyTheme.cardTitle)
        }
        .padding(.leading, LayoutConstants.spaceXS)
        .padding(.trailing, LayoutConstants.spaceMS)
        .frame(height: 36)
        .background(Capsule().fill(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityDense)))
        .overlay(Capsule().stroke(DarkFantasyTheme.borderMedium, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(gold) gold")
    }
}

/// The host's line, in a plate by their head.
struct MinigameSpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.textPrimary)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, LayoutConstants.spaceMS)
            .padding(.vertical, LayoutConstants.spaceSM + LayoutConstants.space2XS)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgPrimary.opacity(DarkFantasyTheme.opacityOpaque))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 1)
            )
            .depthShadow(.elevated)
            .animation(MotionConstants.smooth, value: text)
            .accessibilityAddTraits(.isStaticText)
    }
}

/// A capsule on the stage (Fortune's Table entry, the Treasury, the payout line).
struct MinigameStagePill<Content: View>: View {
    var accent: Color = DarkFantasyTheme.gold
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            content()
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .frame(minHeight: 44)
        .background(Capsule().fill(DarkFantasyTheme.bgPrimary.opacity(DarkFantasyTheme.opacityOpaque)))
        .overlay(Capsule().stroke(accent.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 1))
        .depthShadow(.card)
    }
}

/// The outcome, said on the stage instead of a modal: the multiplier in a
/// gold coin and the gold won, or the stake gone.
struct MinigameResultPlaque: View {
    let isWin: Bool
    /// "×2", "×1.5" — shown in the coin on a win.
    let badge: String
    let amount: Int
    let caption: String

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            Text(isWin ? badge : "×0")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(isWin ? DarkFantasyTheme.textOnGold : DarkFantasyTheme.textPrimary)
                .frame(width: 52, height: 52)
                .background(Circle().fill(isWin ? DarkFantasyTheme.gold : DarkFantasyTheme.danger.opacity(DarkFantasyTheme.opacityHeavy)))
            VStack(alignment: .leading, spacing: 0) {
                Text(isWin ? "+\(amount.formatted())" : "−\(amount.formatted())")
                    .font(DarkFantasyTheme.title)
                    .monospacedDigit()
                    .foregroundStyle(isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger)
                Text(caption)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.leading, LayoutConstants.spaceSM)
        .padding(.trailing, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(Capsule().fill(DarkFantasyTheme.bgPrimary.opacity(DarkFantasyTheme.opacityOpaque)))
        .overlay(Capsule().stroke(isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger, lineWidth: 2))
        .depthShadow(.elevated)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isWin ? "Won \(amount) gold, \(badge)" : "Lost \(amount) gold")
    }
}

/// The bottom dock: bet stepper + main action on one row, then what's left
/// today and the rules/odds link.
struct MinigameBetDock: View {
    let bets: [Int]
    @Binding var selectedBet: Int
    let gold: Int
    /// No bet changes while a round is running.
    let isLocked: Bool
    let ctaTitle: String
    let ctaEnabled: Bool
    var ctaIsDanger: Bool = false
    let remainingText: String
    let remainingIsEmpty: Bool
    let infoTitle: String
    let onInfo: () -> Void
    let onCTA: () -> Void

    private var index: Int { bets.firstIndex(of: selectedBet) ?? 0 }
    private var canLower: Bool { !isLocked && index > 0 }
    private var canRaise: Bool {
        !isLocked && index < bets.count - 1 && bets[index + 1] <= max(gold, bets[0])
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            HStack(spacing: LayoutConstants.spaceSM + LayoutConstants.space2XS) {
                stepper
                cta
            }
            HStack {
                Text(remainingText)
                    .foregroundStyle(remainingIsEmpty ? DarkFantasyTheme.danger : DarkFantasyTheme.textSecondary)
                Spacer()
                Button(action: onInfo) {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "info.circle")
                        Text(infoTitle)
                    }
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .font(DarkFantasyTheme.body)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: LayoutConstants.radius2XL, topTrailingRadius: LayoutConstants.radius2XL)
                .fill(DarkFantasyTheme.bgPrimary.opacity(DarkFantasyTheme.opacityOpaque))
                .overlay(alignment: .top) {
                    UnevenRoundedRectangle(topLeadingRadius: LayoutConstants.radius2XL, topTrailingRadius: LayoutConstants.radius2XL)
                        .stroke(DarkFantasyTheme.gold.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                }
                .depthShadow(.modal)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var stepper: some View {
        HStack(spacing: 0) {
            stepButton(systemName: "minus", label: "Lower bet", enabled: canLower) {
                selectedBet = bets[index - 1]
            }
            VStack(spacing: LayoutConstants.spaceXS + LayoutConstants.space2XS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("icon-gold")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: LayoutConstants.iconMD, height: LayoutConstants.iconMD)
                    Text(selectedBet.formatted())
                        .font(DarkFantasyTheme.section)
                        .monospacedDigit()
                        .foregroundStyle(gold >= selectedBet ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.danger)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack(spacing: LayoutConstants.spaceXS) {
                    ForEach(bets.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? DarkFantasyTheme.goldBright : DarkFantasyTheme.borderMedium)
                            .frame(width: i == index ? 16 : 6, height: 6)
                    }
                }
                .animation(MotionConstants.spring, value: index)
                .accessibilityHidden(true)
            }
            .frame(minWidth: 72)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Bet \(selectedBet) gold")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: if canRaise { selectedBet = bets[index + 1] }
                case .decrement: if canLower { selectedBet = bets[index - 1] }
                @unknown default: break
                }
            }
            stepButton(systemName: "plus", label: "Raise bet", enabled: canRaise) {
                selectedBet = bets[index + 1]
            }
        }
        .frame(height: LayoutConstants.buttonHeightLG)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .fill(DarkFantasyTheme.bgTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
        .opacity(isLocked ? DarkFantasyTheme.opacityHeavy : 1)
    }

    private func stepButton(systemName: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.light()
            SFXManager.shared.play(.uiTap)
            action()
        } label: {
            Image(systemName: systemName)
                .font(DarkFantasyTheme.cardTitle.weight(.bold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(width: 44, height: LayoutConstants.buttonHeightLG)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : DarkFantasyTheme.opacityStrong)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var cta: some View {
        if ctaIsDanger {
            Button(action: onCTA) {
                Text(ctaTitle)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.danger)
            .disabled(!ctaEnabled)
        } else {
            Button(action: onCTA) {
                Text(ctaTitle)
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.primary)
            .disabled(!ctaEnabled)
        }
    }
}

/// A short rules / odds sheet behind the dock's info link.
struct MinigameInfoSheet: View {
    let title: String
    let rows: [(label: String, value: String)]
    let notes: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMD) {
            HStack {
                Text(title)
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            if !rows.isEmpty {
                VStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(rows.indices, id: \.self) { i in
                        HStack {
                            Text(rows[i].label)
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                            Spacer()
                            Text(rows[i].value)
                                .monospacedDigit()
                                .foregroundStyle(DarkFantasyTheme.goldBright)
                        }
                        .font(DarkFantasyTheme.body)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(LayoutConstants.spaceMS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
            }
            ForEach(notes.indices, id: \.self) { i in
                Text(notes[i])
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(LayoutConstants.screenPadding)
        .background(DarkFantasyTheme.bgPrimary.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
