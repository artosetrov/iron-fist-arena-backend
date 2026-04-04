#if DEBUG
import SwiftUI

// MARK: - Modals Catalog

/// Showcases modal, sheet, and gate components in static (non-animated) preview form.
struct ModalsCatalogView: View {

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    guestGateSection
                    npcGuideSection
                    sessionExpiredSection
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
                Text("MODALS & GATES")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Guest Gate

    private var guestGateSection: some View {
        catalogSection("Guest Gate") {
            GuestGateView(
                feature: "Arena PvP",
                onRegister: { },
                onDismiss: { }
            )
        }
    }

    // MARK: - NPC Guide Widget

    private var npcGuideSection: some View {
        catalogSection("NPC Guide Widget") {
            VStack(spacing: LayoutConstants.spaceMD) {
                NPCGuideWidget(
                    npcTitle: "Merchant Zara",
                    onDismiss: { },
                    plainMessage: "Welcome, adventurer! Browse my finest wares."
                )

                NPCGuideWidget(
                    npcTitle: "Arena Master",
                    onDismiss: { },
                    plainMessage: "Ready to prove your worth in combat?",
                    ctaLabel: "FIGHT NOW"
                ) { }
            }
        }
    }

    // MARK: - Session Expired

    private var sessionExpiredSection: some View {
        catalogSection("Session Expired (Static Preview)") {
            VStack(spacing: LayoutConstants.spaceMD) {
                Text("SessionExpiredModalView renders as a full-screen overlay. Use Screen Catalog → Modals to test it live.")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                // Static representation
                VStack(spacing: LayoutConstants.spaceMD) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.danger)

                    Text("SESSION EXPIRED")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)

                    Text("Your session has expired. Please log in again.")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button("LOG IN") { }
                        .buttonStyle(.primary)
                }
                .padding(LayoutConstants.spaceLG)
                .background(DarkFantasyTheme.bgTertiary)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.modalRadius))
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
}

#Preview("Modals & Gates") {
    NavigationStack {
        ModalsCatalogView()
    }
}
#endif
