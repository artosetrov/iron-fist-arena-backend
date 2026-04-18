//
//  TalentsTabView.swift
//  Hexbound
//
//  Third tab on HeroDetailView. Hosts the passive-tree canvas, SP banner,
//  and respec action. Purely additive — does not modify existing Inventory or Status tabs.
//

import SwiftUI

struct TalentsTabView: View {
    @Bindable var vm: PassiveTreeViewModel

    // Respec cost is surfaced server-side; we echo the canonical value here for UI clarity.
    private let respecGemCost: Int = 50

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: LayoutConstants.spaceMD) {
                header

                ActiveSlotsBar(vm: vm)

                if vm.isLoading && vm.nodes.isEmpty {
                    loadingView
                } else if vm.nodes.isEmpty {
                    emptyView
                } else {
                    canvasContainer
                }

                respecRow
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            // Reserve room so respec row stays above the sticky bar when it appears.
            .padding(.bottom, vm.hasPendingChanges ? 96 : LayoutConstants.spaceMD)

            // Sticky confirm bar (Stats-tab pattern).
            if vm.hasPendingChanges {
                stickyConfirmBar
            }
        }
        .animation(.easeOut(duration: 0.25), value: vm.hasPendingChanges)
        .sheet(item: sheetBinding()) { node in
            TalentDetailSheet(
                node: node,
                isUnlocked: vm.isUnlocked(node),
                isPending: vm.isPending(node),
                isUnlockable: vm.isUnlockable(node),
                pointsAvailable: vm.pointsAvailableAfterPending,
                isMutating: vm.isMutating,
                onStage: {
                    vm.stageUnlock(node)
                    vm.selectedNode = nil
                },
                onUnstage: {
                    vm.unstageUnlock(node)
                    vm.selectedNode = nil
                },
                onClose: { vm.selectedNode = nil },
                equippedSlotIndex: vm.equippedSlotIndex(for: node.id),
                onEquip: {
                    vm.beginEquipActive(node: node)
                    vm.selectedNode = nil
                },
                onUnequip: {
                    if let idx = vm.equippedSlotIndex(for: node.id) {
                        vm.clearActive(slotIndex: idx)
                    }
                    vm.selectedNode = nil
                }
            )
            .presentationDetents([.medium])
            .presentationBackground(DarkFantasyTheme.bgSecondary)
        }
        .sheet(isPresented: $vm.showActiveSkillPicker) {
            ActiveSkillPickerSheet(vm: vm)
                .presentationDetents([.large])
                .presentationBackground(DarkFantasyTheme.bgSecondary)
                .presentationDragIndicator(.visible)
        }
        .alert("Reset all talents?", isPresented: $vm.showRespecConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset — \(respecGemCost) gems", role: .destructive) {
                vm.respec()
            }
        } message: {
            Text("All unlocked talents will be refunded as skill points. Costs \(respecGemCost) gems.")
        }
        .task {
            await vm.load()
        }
    }

    // MARK: - Header (SP banner)

    private var header: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text("SKILL POINTS")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(2)
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceXS) {
                    Text("\(vm.pointsAvailableAfterPending) available")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.gold)
                    if vm.hasPendingChanges {
                        Text("(−\(vm.pendingCost) pending)")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                }
            }
            Spacer()
            unlockedCountPill
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var unlockedCountPill: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.gold)
                .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
            Text("\(vm.unlockedNodes.count)/\(vm.nodes.count)")
                .font(DarkFantasyTheme.uiLabel.bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .fill(DarkFantasyTheme.bgTertiary)
        )
    }

    // MARK: - Canvas container

    private var canvasContainer: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            TalentTreeCanvas(
                nodes: vm.nodes,
                connections: vm.connections,
                isUnlocked: vm.isUnlocked,
                isPending: vm.isPending,
                isUnlockable: vm.isUnlockable,
                onTap: { node in
                    vm.selectedNode = node
                }
            )
            .padding(LayoutConstants.spaceMD)
        }
        .frame(maxWidth: .infinity)
        // Bigger nodes need a taller viewport to feel comfortable; user can still pan/zoom.
        .frame(height: 560)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(DarkFantasyTheme.gold)
            Text("Loading talents…")
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .padding(.top, LayoutConstants.spaceSM)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 560)
    }

    private var emptyView: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .foregroundStyle(DarkFantasyTheme.textDisabled)
                .frame(width: LayoutConstants.icon2XL, height: LayoutConstants.icon2XL)
            Text("No talents available")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 560)
    }

    // MARK: - Respec row

    private var respecRow: some View {
        Button {
            vm.showRespecConfirm = true
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                Text("RESET TALENTS")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .tracking(2)
                Spacer()
                Text("\(respecGemCost) gems")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                    .stroke(DarkFantasyTheme.danger.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.unlockedNodes.isEmpty || vm.isMutating)
        .opacity(vm.unlockedNodes.isEmpty ? 0.5 : 1)
    }

    // MARK: - Sticky Confirm Bar (mirrors Stats tab `statsStickyBar`)

    private var stickyConfirmBar: some View {
        VStack(spacing: 0) {
            // Top edge gradient to lift the bar off content
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, DarkFantasyTheme.bgPrimary.opacity(0.95)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(height: LayoutConstants.iconMD)

            HStack(spacing: LayoutConstants.spaceSM) {
                Button("RESET") { vm.resetPending() }
                    .buttonStyle(.ghost)
                    .frame(maxWidth: .infinity)
                    .disabled(vm.isMutating)

                Button {
                    vm.commitPending()
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        if vm.isMutating {
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                        }
                        Text("CONFIRM \(vm.pendingCost) SP")
                    }
                }
                .buttonStyle(.primary)
                .disabled(vm.isMutating)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.top, LayoutConstants.spaceSM)
            .padding(.bottom, LayoutConstants.spaceMD)
            .background(DarkFantasyTheme.bgPrimary.opacity(0.95))
            .overlay(alignment: .top) {
                FiligreeLine(
                    color: DarkFantasyTheme.gold.opacity(0.3),
                    notchColor: DarkFantasyTheme.gold.opacity(0.5),
                    notchCount: 5,
                    notchSize: 3
                )
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Sheet binding

    private func sheetBinding() -> Binding<PassiveNode?> {
        Binding(
            get: { vm.selectedNode },
            set: { vm.selectedNode = $0 }
        )
    }
}
