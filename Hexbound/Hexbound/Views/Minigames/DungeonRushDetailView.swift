import SwiftUI

struct DungeonRushDetailView: View {
    @Environment(AppState.self) var appState
    @State var vm: DungeonRushViewModel?
    @State var portalGlow: Bool = false
    @State var dustPhase: CGFloat = 0

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                Group {
                    if vm.errorMessage != nil {
                        ErrorStateView.loadFailed {
                            Task { await vm.checkActiveRush() }
                        }
                    } else if vm.isGameOver {
                        gameOverView(vm: vm)
                    } else if vm.isActive {
                        rushView(vm: vm)
                    } else {
                        startView(vm: vm)
                    }

                    if vm.showShop        { shopOverlay(vm: vm) }
                    if vm.showEventResult { eventOverlay(vm: vm) }
                    if vm.showTreasureResult { treasureOverlay(vm: vm) }
                    if vm.showAbandonConfirm { abandonConfirmOverlay(vm: vm) }
                }
                .transaction { $0.animation = nil }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DUNGEON RUSH")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if vm == nil {
                let newVM = DungeonRushViewModel(appState: appState)
                vm = newVM
                Task { await newVM.checkActiveRush() }
            } else {
                vm?.applyPendingResult()
            }
        }
    }
}
