import SwiftUI

// MARK: - CharacterPortraitXPInfo
//
// Slot content shown below the class tag in the portrait area of
// `IntegratedCharacterCard` when the character has XP data (own hero).
// Mirrors the layout that was previously inlined in `HeroIntegratedCard`.
//
// Reusability: extracted so both hero cards and any future portrait-style
// surface can share one XP progress presentation.

@MainActor
struct CharacterPortraitXPInfo: View {
    let experience: Int
    let xpNeeded: Int
    let xpPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text("XP \(experience)/\(xpNeeded)")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.xpRing)
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 3)

            // Thin XP progress bar (3pt tall, capsule shape)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DarkFantasyTheme.xpRingTrack)
                        .frame(height: 3)
                    Capsule()
                        .fill(DarkFantasyTheme.xpRing)
                        .frame(width: geo.size.width * xpPercentage, height: 3)
                        .shadow(color: DarkFantasyTheme.xpRing.opacity(0.5), radius: 3)
                        .animation(.easeInOut(duration: 1.0), value: xpPercentage)
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Experience \(experience) of \(xpNeeded)")
    }
}

// MARK: - CharacterPortraitRankInfo
//
// Slot content shown below the class tag in the portrait area of
// `IntegratedCharacterCard` when the character has PvP rank+rating data (opponent).
// Occupies the same vertical slot as XP info, so Hero and Opponent cards remain
// structurally identical.
//
// Built from semantic DS tokens only — no inline hex values, no inline capsules
// with manual fill + stroke. Uses `DarkFantasyTheme.caption` / `.body` text styles
// so it stays in lockstep with the design system.

@MainActor
struct CharacterPortraitRankInfo: View {
    let rank: PvPRank
    let rating: Int

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            rankPill
            ratingPill
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rank.rawValue) rank, \(rating) rating")
    }

    private var rankPill: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: rank.icon)
                .font(DarkFantasyTheme.caption.weight(.semibold))
                .foregroundStyle(rank.color)
            Text(rank.rawValue)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(rank.color)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            Capsule()
                .fill(rank.color.opacity(0.15))
                .overlay(
                    Capsule().stroke(rank.color.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)
    }

    private var ratingPill: some View {
        HStack(spacing: LayoutConstants.space2XS) {
            Image(systemName: "trophy.fill")
                .font(DarkFantasyTheme.caption.weight(.semibold))
                .foregroundStyle(DarkFantasyTheme.gold)
            Text("\(rating)")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.gold)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.vertical, LayoutConstants.space2XS)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.gold.opacity(0.15))
                .overlay(
                    Capsule().stroke(DarkFantasyTheme.gold.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 2, y: 1)
    }
}

// MARK: - EmptyPortraitInfo
//
// Placeholder for call sites that want no extra info under the class tag.
// Keeps the portrait layout balanced (same bottom padding as XP/Rank variants).

@MainActor
struct EmptyPortraitInfo: View {
    var body: some View {
        Color.clear
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
