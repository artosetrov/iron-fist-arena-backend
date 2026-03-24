import SwiftUI

// MARK: - Merchant Tip Model

/// A single merchant tip with styled text segments.
@MainActor
struct MerchantTip: Equatable, Hashable {
    let segments: [Segment]

    enum Segment: Equatable, Hashable {
        case plain(String)
        case gold(String)    // Rendered in goldBright, semibold
        case gem(String)     // Rendered in cyan, semibold
    }

    /// Build an AttributedString for display.
    var attributedText: AttributedString {
        var result = AttributedString()
        for segment in segments {
            var part: AttributedString
            switch segment {
            case .plain(let text):
                part = AttributedString(text)
                part.foregroundColor = DarkFantasyTheme.textSecondary
            case .gold(let text):
                part = AttributedString(text)
                part.foregroundColor = DarkFantasyTheme.goldBright
                part.font = DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold()
            case .gem(let text):
                part = AttributedString(text)
                part.foregroundColor = DarkFantasyTheme.cyan
                part.font = DarkFantasyTheme.body(size: LayoutConstants.textCaption).bold()
            }
            result.append(part)
        }
        return result
    }
}

// MARK: - Merchant Tip Provider

/// Provides contextual merchant tips based on the current shop tab.
/// Tips are client-side only — no backend model exists for merchant content.
@MainActor @Observable
final class MerchantTipProvider {
    private(set) var currentTip: MerchantTip
    private var currentTabIndex: Int = 0
    private var currentTipIndex: Int = 0

    init() {
        currentTip = Self.tipsByTab[0]?.first ?? MerchantTip(segments: [.plain("Welcome, adventurer!")])
    }

    // MARK: - Tab Change

    func updateTab(_ tabIndex: Int) {
        currentTabIndex = tabIndex
        currentTipIndex = 0
        updateCurrentTip(animated: true)
    }

    // MARK: - Cycle to Next Tip

    func nextTip() {
        currentTipIndex += 1
        updateCurrentTip(animated: true)
    }

    // MARK: - Insufficient Funds Override

    func showInsufficientFunds(isGems: Bool) {
        if isGems {
            currentTip = MerchantTip(segments: [
                .plain("Not enough "),
                .gem("gems"),
                .plain("? Tap "),
                .gold("GET MORE"),
                .plain(" above — I'll hold your items!")
            ])
        } else {
            currentTip = MerchantTip(segments: [
                .plain("Not enough "),
                .gold("gold"),
                .plain("? Tap "),
                .gold("GET MORE"),
                .plain(" above — I'll hold your items!")
            ])
        }
    }

    // MARK: - Private

    private func updateCurrentTip(animated: Bool) {
        let tips = Self.tipsByTab[currentTabIndex] ?? Self.tipsByTab[0] ?? []
        guard !tips.isEmpty else { return }
        let index = currentTipIndex % tips.count
        if animated {
            withAnimation(.easeOut(duration: 0.15)) {
                currentTip = tips[index]
            }
        } else {
            currentTip = tips[index]
        }
    }

    // MARK: - Tips Content

    /// Tab index → tips. Matches ShopViewModel.tabs: [All, Weapons, Equipment, Potions]
    /// Content is flavor text + navigation nudges only — no balance data or formulas.
    private static let tipsByTab: [Int: [MerchantTip]] = [
        // All tab
        0: [
            MerchantTip(segments: [
                .plain("Looking for a "),
                .gold("new weapon"),
                .plain("? The swords in row two are popular with warriors.")
            ]),
            MerchantTip(segments: [
                .plain("Short on "),
                .gem("gems"),
                .plain("? Tap "),
                .gold("GET MORE"),
                .plain(" above!")
            ]),
            MerchantTip(segments: [
                .plain("The "),
                .gold("legendary gear"),
                .plain(" at the bottom is worth saving up for.")
            ]),
            MerchantTip(segments: [
                .plain("Don't forget "),
                .gold("potions"),
                .plain(" before heading into the arena!")
            ]),
        ],
        // Weapons tab
        1: [
            MerchantTip(segments: [
                .plain("A fine warrior needs a "),
                .gold("fine blade"),
                .plain(". These are my sharpest.")
            ]),
            MerchantTip(segments: [
                .plain("The "),
                .gem("purple wand"),
                .plain(" there? Best for mage class. Very popular.")
            ]),
            MerchantTip(segments: [
                .plain("Legendary weapons deal "),
                .gold("massive damage"),
                .plain(" — worth the investment.")
            ]),
        ],
        // Equipment tab
        2: [
            MerchantTip(segments: [
                .plain("Good armor saves lives. "),
                .gold("Chest pieces"),
                .plain(" give the most defense.")
            ]),
            MerchantTip(segments: [
                .plain("Don't overlook "),
                .gold("boots"),
                .plain(" — speed wins fights in the arena.")
            ]),
            MerchantTip(segments: [
                .plain("Match your armor to your "),
                .gold("class"),
                .plain(" for hidden bonuses!")
            ]),
        ],
        // Potions tab
        3: [
            MerchantTip(segments: [
                .plain("Stock up on "),
                .gold("health potions"),
                .plain(" before dungeon runs!")
            ]),
            MerchantTip(segments: [
                .plain("The "),
                .gem("XP boost"),
                .plain(" potion? 30 minutes of double experience.")
            ]),
            MerchantTip(segments: [
                .gold("Gold boost"),
                .plain(" potions pay for themselves in 2–3 battles.")
            ]),
        ],
    ]
}
