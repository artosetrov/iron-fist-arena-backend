import SwiftUI

/// Accent colours for a minigame outcome. Non-generic so call sites can read
/// `MinigameResultAccent.color(isWin:)` without naming a specialization.
enum MinigameResultAccent {
    static let win = DarkFantasyTheme.gold
    static let lose = DarkFantasyTheme.danger

    static func color(isWin: Bool) -> Color { isWin ? win : lose }
}

/// Win/lose result shared by the shell game, the fortune wheel and Fortune's Table.
///
/// Since 2026-10-22 it is a fortune reward card (`RewardCard`): a win shows the
/// winnings as gold in the fortune-teller's tent and the card's metal follows the
/// prize (the wheel's jackpot is mythic); a loss is the same card drained of
/// colour, with a red title and the stake gone (an overturned, empty purse). The
/// game's own picture — the ball, the cup, the wheel's sector, the prize — sits
/// on the result line under the title.
///
/// The view is full-screen and owns its backdrop: present it directly (not
/// inside `GameModal`). A tap on the backdrop or a swipe down continues, as
/// `GameModal` did.
struct MinigameResultModal<Illustration: View>: View {
    let isWin: Bool
    let title: String
    let amountText: String
    /// Two lines on the wheel (sector names run long), one in the shell game.
    var amountLineLimit: Int = 1
    /// Gold won. Sizes the pile in the card's illustration and, unless `tier`
    /// says more, the card's metal. 0 on a loss.
    var winnings: Int = 0
    /// The card's metal when the game knows better than the amount — the
    /// wheel's multiplier, the item in Fortune's Table's chest.
    var tier: RewardCardTier? = nil
    let onContinue: () -> Void
    @ViewBuilder var illustration: () -> Illustration

    @State private var dragOffset: CGFloat = 0

    /// Gold for a win, danger for a loss — also the illustration's glow.
    var accent: Color { MinigameResultAccent.color(isWin: isWin) }

    /// Past this many points a swipe down continues (as in `GameModal`).
    private static var dismissThreshold: CGFloat { 110 }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onContinue)
                // VoiceOver reaches the card directly; the backdrop is a
                // pointer affordance, not content.
                .accessibilityHidden(true)

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .fortune,
                    tier: cardTier,
                    dimmed: !isWin,
                    art: cardArt,
                    width: width,
                    artRatio: artRatio,
                    title: title,
                    titleColor: isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.danger,
                    content: { resultLine },
                    actions: { continueButton }
                )
            }
            .offset(y: dragOffset)
            .gesture(dragGesture)
        }
        // Opacity only — the project does not scale modals in.
        .transition(.opacity)
    }

    // MARK: - Card

    private var cardTier: RewardCardTier {
        guard isWin else { return .iron }
        return RewardCardTier.best([tier, RewardCardTier(gold: winnings)])
    }

    /// A win: the gold, sized by the winnings. A loss: the purse, tipped over and empty.
    private var cardArt: RewardCardArt {
        guard isWin else { return .object("reward-art-fortune-loss", fill: 0.6) }
        guard winnings > 0 else { return RewardCardArt(subject: .none) }
        return .headline(gold: winnings, gems: 0, xp: 0, items: [], hasConsumables: false)
    }

    /// The game's picture and what it paid (or cost).
    private var resultLine: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            illustration()
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
                .shadow(color: accent.opacity(DarkFantasyTheme.opacityStrong), radius: 8)
                .accessibilityHidden(true)

            Text(amountText)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(isWin ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                .lineLimit(amountLineLimit)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceXS)
        // The title is the card's header; the result line reads as one element
        // after it, and the button below stays its own.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(amountText)
        .accessibilityAddTraits(.isStaticText)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("CONTINUE")
                .font(DarkFantasyTheme.cardTitle)
                .tracking(2)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeightMD)
        }
        .buttonStyle(isWin ? AnyButtonStyle(PrimaryButtonStyle()) : AnyButtonStyle(DangerButtonStyle()))
        .accessibilityLabel("Continue")
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Downward only: an upward drag should not lift the card off
                // the backdrop.
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if value.translation.height > Self.dismissThreshold {
                    onContinue()
                }
                withAnimation(MotionConstants.spring) { dragOffset = 0 }
            }
    }
}
