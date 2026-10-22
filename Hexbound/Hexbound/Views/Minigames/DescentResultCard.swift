import SwiftUI

/// The end of a descent (Dungeon Rush v2) as a dungeon reward card
/// (`RewardCard.swift`, 2026-10-22): what the hero carried out of the dark — or,
/// after a fall, what the dark kept — and the way back in. Replaces the whole run
/// screen once the server's snapshot says the run is over; the view model has
/// already played the outcome's sound and haptic.
struct DescentResultCard: View {
    @Environment(AppState.self) private var appState
    let result: DescentResult
    /// The depth the run ended on (`DescentSnapshot.depthKey` / `.depthRoman`).
    let depthKey: String
    let depthRoman: String
    let staminaCost: Int
    let isStarting: Bool
    let onAgain: () -> Void
    let onLeave: () -> Void

    @State private var revealed = false
    @State private var burst = false

    /// A fall or a retreat: half the bag stays below.
    private var fell: Bool { result.outcome == "dead" || result.outcome == "abandoned" }

    var body: some View {
        ZStack {
            DescentBackdrop(asset: sceneAsset, dim: 0.62)
                .ignoresSafeArea()
            DescentVignette()
                .ignoresSafeArea()

            RewardCardStage { width, artRatio in
                RewardCard(
                    family: .dungeon,
                    tier: tier,
                    dimmed: fell,
                    art: art,
                    width: width,
                    artRatio: artRatio,
                    header: {
                        RewardCardTitle(
                            title: title,
                            subtitle: subtitle,
                            color: fell ? DarkFantasyTheme.danger : DarkFantasyTheme.goldBright
                        )
                        .rewardBurst(isActive: $burst, style: .gold)
                    },
                    content: { rewards },
                    actions: { buttons }
                )
            }
            .opacity(revealed ? 1 : 0)
            // The run screen sits under `.transaction { animation = nil }`, so the
            // reveal carries its own animation.
            .animation(.easeOut(duration: MotionConstants.reward), value: revealed)
        }
        .onAppear {
            revealed = true
            if !fell {
                DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) { burst = true }
            }
        }
    }

    // MARK: - Reading

    private var title: String {
        switch result.outcome {
        case "victory": "VICTORY!"
        case "escaped": "ESCAPED"
        case "abandoned": "ABANDONED"
        default: "DEFEAT"
        }
    }

    private var subtitle: String {
        switch result.outcome {
        case "victory": "The deep is conquered"
        case "escaped": "Back in the daylight"
        case "abandoned": "You turned back"
        default: "You fell in the dark"
        }
    }

    /// What came out decides the metal (shards are pieces, not items, and do not
    /// count); conquering all three depths is at least gold.
    private var tier: RewardCardTier {
        let items: [RewardCardTier?] = result.keptItems.filter { !$0.isShard }.map { RewardCardTier(rarity: $0.itemRarity) }
        let floor: RewardCardTier? = result.outcome == "victory" ? .gold : nil
        return RewardCardTier.best([RewardCardTier(gold: result.keptGold, xp: result.xp), floor] + items)
    }

    /// The room behind the card: the treasure vault, the daylight at the entrance,
    /// or the hall of the depth where the run ended.
    private var sceneAsset: String {
        switch result.outcome {
        case "victory": "rush2-bg-treasure"
        case "escaped": "rush2-bg-entrance"
        default: "rush2-bg-\(depthKey)-hall"
        }
    }

    /// A chest that fits the haul in the room it was carried to; after a fall, the
    /// hero in the hall where it happened, greyed like every lost card.
    private var art: RewardCardArt {
        if fell, let hero = appState.currentCharacter {
            var art = RewardCardArt.hero(skinKey: hero.avatar, characterClass: hero.characterClass)
            art.backdrop = sceneAsset
            return art
        }
        if fell { return RewardCardArt(subject: .none, backdrop: sceneAsset) }
        var art = RewardCardArt.object(chestAsset, fill: 0.78)
        art.backdrop = sceneAsset
        return art
    }

    private var chestAsset: String {
        switch tier {
        case .iron, .bronze: "rush2-chest-wood-open"
        case .silver: "rush2-chest-iron-open"
        case .gold, .mythic: "rush2-chest-gold-open"
        }
    }

    // MARK: - Content

    private var rewards: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("Depth \(depthRoman) · \(result.rooms) rooms · \(result.kills) foes slain")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            VStack(spacing: LayoutConstants.spaceXS) {
                RewardCardRow(icon: "icon-gold", value: "+\(result.keptGold)", label: "Gold")
                if result.xp > 0 {
                    RewardCardRow(icon: "reward-xp", value: "+\(result.xp)", label: "XP", color: DarkFantasyTheme.xpRing)
                }
            }

            if !result.keptItems.isEmpty {
                DescentItemsList(items: result.keptItems)
            }

            if fell {
                DescentSummaryBox(title: "Lost in the dark", note: "Half your bag", danger: true) {
                    DescentValueLine(label: "Gold from your bag", value: "−\(result.lostGold)", color: DarkFantasyTheme.textDanger)
                    if !result.lostItems.isEmpty {
                        DescentItemsList(items: result.lostItems)
                    }
                    Text("The other half made it out with you. Stashed loot and experience are never lost.")
                        .font(DarkFantasyTheme.tale)
                        .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, LayoutConstants.spaceXS)
    }

    private var buttons: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Button(action: onAgain) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("Descend again")
                    Image("icon-stamina")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("\(staminaCost)")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(isStarting)
            .accessibilityLabel("Descend again, costs \(staminaCost) stamina")

            Button(action: onLeave) {
                Text("Return to town")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
        }
    }
}
