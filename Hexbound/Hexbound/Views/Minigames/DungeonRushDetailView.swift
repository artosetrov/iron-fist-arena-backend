import SwiftUI

struct DungeonRushDetailView: View {
    @Environment(AppState.self) var appState
    @State var vm: DungeonRushViewModel?
    @State var portalGlow: Bool = false
    @State var dustPhase: CGFloat = 0
    @State private var revealedMinibossIdx: Int? = nil

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
                maybeShowMinibossReveal()
            }
        }
        .onChange(of: vm?.currentRoom?.type) { _, _ in
            maybeShowMinibossReveal()
        }
        .onChange(of: vm?.isActive ?? false) { _, active in
            if active { maybeShowMinibossReveal() }
        }
    }

    // MARK: - Miniboss Reveal

    /// Fires the root-level boss-reveal ceremony when the player enters
    /// a miniboss room. Tracked per room index so re-renders don't
    /// re-trigger. Fires every rush run — the miniboss is the run's
    /// climax, not a unique-per-player moment.
    private func maybeShowMinibossReveal() {
        guard let vm = vm,
              vm.isActive,
              !vm.isFighting,
              !vm.isGameOver,
              let room = vm.currentRoom,
              room.type == "miniboss",
              revealedMinibossIdx != vm.currentRoomIndex
        else { return }

        revealedMinibossIdx = vm.currentRoomIndex

        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.navigationDelay) {
            let imageKey = "rush-miniboss-" + vm.enemyName
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
            let data = BossRevealData.fromRushMiniboss(
                name: vm.enemyName,
                level: vm.enemyLevel,
                floor: vm.currentFloor,
                totalRooms: vm.totalRooms,
                imageKey: imageKey,
                onChallenge: {
                    appState.dismissBossReveal()
                    Task { await vm.fight() }
                },
                onSkip: { appState.dismissBossReveal() }
            )
            appState.presentBossReveal(data)
        }
    }
}
