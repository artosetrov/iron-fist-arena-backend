#if DEBUG
import SwiftUI

// MARK: - Progress Bars Catalog

/// Showcases HP, XP, and Stamina bars in all sizes and states.
struct ProgressBarsCatalogView: View {

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    hpBarsSection
                    xpBarsSection
                    staminaBarsSection
                    hpStatesSection
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceMD)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("PROGRESS BARS")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - HP Bars

    private var hpBarsSection: some View {
        catalogSection("HP Bar — Sizes") {
            VStack(spacing: LayoutConstants.spaceMD) {
                barRow("Compact") {
                    HPBarView(currentHp: 680, maxHp: 850, size: .compact)
                }
                barRow("Widget") {
                    HPBarView(currentHp: 680, maxHp: 850, size: .widget)
                }
                barRow("Large") {
                    HPBarView(currentHp: 680, maxHp: 850, size: .large)
                }
                barRow("Large + Text") {
                    HPBarView(currentHp: 680, maxHp: 850, size: .large, showTextInside: true)
                }
            }
        }
    }

    // MARK: - HP States

    private var hpStatesSection: some View {
        catalogSection("HP Bar — Health States") {
            VStack(spacing: LayoutConstants.spaceMD) {
                barRow("Full (100%)") {
                    HPBarView(currentHp: 850, maxHp: 850, size: .large, showTextInside: true)
                }
                barRow("Good (80%)") {
                    HPBarView(currentHp: 680, maxHp: 850, size: .large, showTextInside: true)
                }
                barRow("Medium (50%)") {
                    HPBarView(currentHp: 425, maxHp: 850, size: .large, showTextInside: true)
                }
                barRow("Low (25%)") {
                    HPBarView(currentHp: 212, maxHp: 850, size: .large, showTextInside: true)
                }
                barRow("Critical (10%)") {
                    HPBarView(currentHp: 85, maxHp: 850, size: .large, showTextInside: true, pulseOnCritical: true)
                }
                barRow("Dead (0%)") {
                    HPBarView(currentHp: 0, maxHp: 850, size: .large, showTextInside: true)
                }
            }
        }
    }

    // MARK: - XP Bars

    private var xpBarsSection: some View {
        catalogSection("XP Bar — Sizes & States") {
            VStack(spacing: LayoutConstants.spaceMD) {
                barRow("Compact (60%)") {
                    XPBarView(currentXp: 1800, xpNeeded: 3000, size: .compact)
                }
                barRow("Large (60%)") {
                    XPBarView(currentXp: 1800, xpNeeded: 3000, size: .large)
                }
                barRow("Nearly Full (95%)") {
                    XPBarView(currentXp: 2850, xpNeeded: 3000, size: .large)
                }
                barRow("Empty (0%)") {
                    XPBarView(currentXp: 0, xpNeeded: 3000, size: .large)
                }
            }
        }
    }

    // MARK: - Stamina Bars

    private var staminaBarsSection: some View {
        catalogSection("Stamina Bar — Sizes & States") {
            VStack(spacing: LayoutConstants.spaceMD) {
                barRow("Compact (75%)") {
                    StaminaBarView(currentStamina: 90, maxStamina: 120, size: .compact)
                }
                barRow("Large (75%)") {
                    StaminaBarView(currentStamina: 90, maxStamina: 120, size: .large)
                }
                barRow("Full") {
                    StaminaBarView(currentStamina: 120, maxStamina: 120, size: .large)
                }
                barRow("Low (10%)") {
                    StaminaBarView(currentStamina: 12, maxStamina: 120, size: .large)
                }
                barRow("Empty") {
                    StaminaBarView(currentStamina: 0, maxStamina: 120, size: .large)
                }
                barRow("With Recovery") {
                    StaminaBarView(currentStamina: 60, maxStamina: 120, size: .large, recoveryText: "Full in 8h 0m")
                }
            }
        }
    }

    // MARK: - Helpers

    private func catalogSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(title.uppercased())
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(DarkFantasyTheme.gold)

            content()
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    private func barRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text(label)
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
            content()
        }
    }
}

#Preview("Progress Bars") {
    NavigationStack {
        ProgressBarsCatalogView()
    }
}
#endif
