import SwiftUI

// MARK: - Skeleton Rect (base building block)

struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = LayoutConstants.radiusSM

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DarkFantasyTheme.bgTertiary)
            .frame(width: width, height: height)
            .overlay(
                // Radial tint for depth
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [DarkFantasyTheme.borderSubtle.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
            )
            .overlay(
                // Shimmer sweep
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    DarkFantasyTheme.textSecondary.opacity(0.06),
                                    DarkFantasyTheme.goldDim.opacity(0.04),
                                    DarkFantasyTheme.textSecondary.opacity(0.06),
                                    .clear,
                                ],
                                startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                                endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                            )
                        )
                }
            )
            .overlay(
                // Subtle border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DarkFantasyTheme.borderSubtle.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 2
                }
            }
            .onDisappear {
                shimmerOffset = -1
            }
    }
}

// MARK: - Skeleton Opponent Card

struct SkeletonOpponentCard: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            // Avatar placeholder
            SkeletonRect(width: 52, height: 52, cornerRadius: 26) // circle: half of width

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                SkeletonRect(width: 120, height: 14)
                SkeletonRect(width: 80, height: 12)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: LayoutConstants.spaceXS) {
                SkeletonRect(width: 50, height: 14)
                SkeletonRect(width: 60, height: 12)
            }
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - Skeleton Inventory Item

struct SkeletonInventoryItem: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            SkeletonRect(height: 56, cornerRadius: LayoutConstants.radiusMD)
            SkeletonRect(width: 50, height: 10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Quest Card

struct SkeletonQuestCard: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 36, height: 36, cornerRadius: LayoutConstants.radiusMD)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                SkeletonRect(width: 100, height: 14)
                SkeletonRect(height: 10)
            }

            Spacer()

            SkeletonRect(width: 44, height: 20, cornerRadius: LayoutConstants.spaceMS) // pill-like half-height
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
    }
}

// MARK: - Skeleton Leaderboard Row

struct SkeletonLeaderboardRow: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 28, height: 14) // rank
            SkeletonRect(width: 36, height: 36, cornerRadius: 18) // circle: half of width // avatar
            VStack(alignment: .leading, spacing: 4) {
                SkeletonRect(width: 110, height: 14)
                SkeletonRect(width: 70, height: 10)
            }
            Spacer()
            SkeletonRect(width: 50, height: 16)
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
    }
}

// MARK: - Skeleton Shop Item Card

struct SkeletonShopItemCard: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            SkeletonRect(height: 64, cornerRadius: LayoutConstants.radiusMD)
            SkeletonRect(width: 60, height: 10)
            SkeletonRect(width: 40, height: 10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Achievement Card

struct SkeletonAchievementCard: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 44, height: 44, cornerRadius: LayoutConstants.radiusMD)

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                SkeletonRect(width: 140, height: 14)
                SkeletonRect(height: 10)
                SkeletonRect(height: 6) // progress bar
            }

            Spacer()

            SkeletonRect(width: 50, height: 24, cornerRadius: LayoutConstants.radiusLG)
        }
        .padding(LayoutConstants.bannerPadding)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
    }
}

// MARK: - Skeleton Battle Pass Node

struct SkeletonBPNode: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            SkeletonRect(width: 60, height: 60, cornerRadius: LayoutConstants.radiusLG)
            SkeletonRect(width: 40, height: 10)
        }
    }
}

// MARK: - Skeleton Dungeon Card

struct SkeletonDungeonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonRect(height: 140, cornerRadius: 0)
            VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
                SkeletonRect(width: 180, height: 16)
                SkeletonRect(height: 10)
                SkeletonRect(height: 10)
            }
            .padding(LayoutConstants.bannerPadding)
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }
}

// MARK: - Skeleton Gold Mine Slot

struct SkeletonMineSlot: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 56, height: 56, cornerRadius: LayoutConstants.radiusMD)
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                SkeletonRect(width: 60, height: 14)
                SkeletonRect(width: 80, height: 10)
            }
            Spacer()
            SkeletonRect(width: 64, height: 32, cornerRadius: LayoutConstants.radiusMD)
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
    }
}

// MARK: - Skeleton Conversation Card

struct SkeletonConversationCard: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Avatar circle placeholder (matches 40pt AvatarImageView)
            SkeletonRect(width: 40, height: 40, cornerRadius: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    // Sender name
                    SkeletonRect(width: 110, height: 14)
                    Spacer()
                    // Timestamp placeholder
                    SkeletonRect(width: 36, height: 10)
                }
                // Message preview line
                SkeletonRect(height: 12)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius)
        .innerBorder(cornerRadius: LayoutConstants.cardRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.borderMedium.opacity(0.3), length: 10, thickness: 1)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
    }
}

// MARK: - Skeleton Revenge Card

struct SkeletonRevengeCard: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 40, height: 40, cornerRadius: LayoutConstants.radiusMD)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonRect(width: 100, height: 14)
                SkeletonRect(width: 130, height: 10)
            }
            Spacer()
            SkeletonRect(width: 76, height: 28, cornerRadius: LayoutConstants.radiusMD)
        }
        .panelCard()
    }
}

// MARK: - Skeleton History Row

struct SkeletonHistoryRow: View {
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            SkeletonRect(width: 24, height: 24, cornerRadius: LayoutConstants.radiusXS)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonRect(width: 100, height: 14)
                SkeletonRect(width: 80, height: 10)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                SkeletonRect(width: 40, height: 14)
                SkeletonRect(width: 50, height: 10)
            }
        }
        .padding(LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
    }
}
