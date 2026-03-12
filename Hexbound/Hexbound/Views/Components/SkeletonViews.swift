import SwiftUI

// MARK: - Skeleton Rect (base building block)

struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DarkFantasyTheme.bgTertiary)
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    DarkFantasyTheme.textSecondary.opacity(0.08),
                                    .clear,
                                ],
                                startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                                endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
                            )
                        )
                }
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
        HStack(spacing: 12) {
            // Avatar placeholder
            SkeletonRect(width: 52, height: 52, cornerRadius: 26)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(width: 120, height: 14)
                SkeletonRect(width: 80, height: 12)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                SkeletonRect(width: 50, height: 14)
                SkeletonRect(width: 60, height: 12)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Skeleton Inventory Item

struct SkeletonInventoryItem: View {
    var body: some View {
        VStack(spacing: 6) {
            SkeletonRect(height: 56, cornerRadius: 8)
            SkeletonRect(width: 50, height: 10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Quest Card

struct SkeletonQuestCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 36, height: 36, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(width: 100, height: 14)
                SkeletonRect(height: 10)
            }

            Spacer()

            SkeletonRect(width: 44, height: 20, cornerRadius: 10)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Skeleton Leaderboard Row

struct SkeletonLeaderboardRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 28, height: 14) // rank
            SkeletonRect(width: 36, height: 36, cornerRadius: 18) // avatar
            VStack(alignment: .leading, spacing: 4) {
                SkeletonRect(width: 110, height: 14)
                SkeletonRect(width: 70, height: 10)
            }
            Spacer()
            SkeletonRect(width: 50, height: 16)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Skeleton Shop Item Card

struct SkeletonShopItemCard: View {
    var body: some View {
        VStack(spacing: 6) {
            SkeletonRect(height: 64, cornerRadius: 8)
            SkeletonRect(width: 60, height: 10)
            SkeletonRect(width: 40, height: 10)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton Achievement Card

struct SkeletonAchievementCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 44, height: 44, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(width: 140, height: 14)
                SkeletonRect(height: 10)
                SkeletonRect(height: 6) // progress bar
            }

            Spacer()

            SkeletonRect(width: 50, height: 24, cornerRadius: 12)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Skeleton Battle Pass Node

struct SkeletonBPNode: View {
    var body: some View {
        VStack(spacing: 8) {
            SkeletonRect(width: 60, height: 60, cornerRadius: 12)
            SkeletonRect(width: 40, height: 10)
        }
    }
}

// MARK: - Skeleton Dungeon Card

struct SkeletonDungeonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonRect(height: 140, cornerRadius: 0)
            VStack(alignment: .leading, spacing: 10) {
                SkeletonRect(width: 180, height: 16)
                SkeletonRect(height: 10)
                SkeletonRect(height: 10)
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }
}

// MARK: - Skeleton Gold Mine Slot

struct SkeletonMineSlot: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 56, height: 56, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonRect(width: 60, height: 14)
                SkeletonRect(width: 80, height: 10)
            }
            Spacer()
            SkeletonRect(width: 64, height: 32, cornerRadius: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Skeleton Revenge Card

struct SkeletonRevengeCard: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 40, height: 40, cornerRadius: 8)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonRect(width: 100, height: 14)
                SkeletonRect(width: 130, height: 10)
            }
            Spacer()
            SkeletonRect(width: 76, height: 28, cornerRadius: 8)
        }
        .panelCard()
    }
}

// MARK: - Skeleton History Row

struct SkeletonHistoryRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRect(width: 24, height: 24, cornerRadius: 4)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}
