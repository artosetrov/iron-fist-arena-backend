import SwiftUI

/// The black market — a back-alley screen whose only tenant is "The Scavenger".
///
/// Until 2026-10-14 this building existed on the hub map with `route: nil`,
/// which meant `resolvedCityBuildings` filtered it out of the map entirely
/// (it only appeared in the hub editor), and it carried an unlock level of 99
/// so the lock overlay would read "SOON". Meanwhile its actual content — the
/// Scavenger's timed contraband drop — was a widget stacked on top of the
/// shop's gear list. One building with no screen, one screen with two
/// merchants. This separates them.
struct BlackMarketDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var vm: BlackMarketViewModel?

    var body: some View {
        ZStack {
            // No dedicated art yet — the shop plate under a heavier scrim
            // reads as the alley behind it. Swap in `bg-black-market` when
            // the asset lands (prompt: docs/08_prompts).
            GeometryReader { geo in
                Image("bg-shop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .saturation(0.5)
            }
            .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            if let vm {
                content(vm)
                    .transaction { $0.animation = nil }

                // Claim reward ceremony
                if let rewardConfig = vm.claimRewardConfig {
                    ClaimRewardModalView(config: rewardConfig) {
                        rewardConfig.onDismiss?()
                        vm.claimRewardConfig = nil
                    }
                    .transition(.opacity)
                    .zIndex(200)
                }
            } else {
                HexPulseLoader(.compact)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
        }
        .task {
            if vm == nil {
                vm = BlackMarketViewModel(appState: appState, cache: cache)
            }
            await vm?.load()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(_ vm: BlackMarketViewModel) -> some View {
        VStack(spacing: 0) {
            OrnamentalTitle("BLACK MARKET", accentColor: DarkFantasyTheme.contrabandAccent)
                .padding(.top, LayoutConstants.spaceSM)

            currencyBar(vm)

            ScrollView {
                VStack(spacing: LayoutConstants.spaceMD) {
                    ContrabandWidget(
                        state: vm.contrabandState,
                        canAfford: vm.canAfford,
                        isClaiming: vm.isClaiming,
                        onClaim: { Task { await vm.claim() } },
                        onRefresh: { Task { await vm.load() } }
                    )

                    lore
                }
                .padding(.vertical, LayoutConstants.spaceMD)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Lore

    private var lore: some View {
        Text("One crate a day, no questions, no refunds. Come back when the lamp is lit.")
            .font(DarkFantasyTheme.caption)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Currency Bar

    @ViewBuilder
    private func currencyBar(_ vm: BlackMarketViewModel) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            CurrencyDisplay(gold: vm.gold, gems: vm.gems)

            Spacer()

            Button {
                appState.mainPath.append(AppRoute.currencyPurchase())
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "plus")
                        .font(DarkFantasyTheme.body.bold())
                    Text("GET MORE")
                }
            }
            .buttonStyle(.getMore)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceMD)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
    }
}
