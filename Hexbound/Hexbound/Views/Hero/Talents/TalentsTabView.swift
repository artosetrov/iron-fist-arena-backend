//
//  TalentsTabView.swift
//  Hexbound
//
//  Third tab on HeroDetailView. Hosts the passive-tree canvas, SP summary,
//  active-skill loadout, and respec action. Fits the prototype Talents screen:
//  SummaryCard (SP + slots) → tree canvas → reset row → sticky Reset/Confirm.
//

import SwiftUI

struct TalentsTabView: View {
    @Bindable var vm: PassiveTreeViewModel

    /// Respec cost mirrors backend balance constant `PASSIVES.RESPEC_GEM_COST`.
    private let respecGemCost: Int = 50
    /// Gems to unlock the 4th active slot. Mirrors backend
    /// `PASSIVES.PREMIUM_ACTIVE_SLOT_GEM_COST`.
    private let premiumSlotGemCost: Int = 100

    @State private var showPremiumSlotConfirm: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: LayoutConstants.spaceMD) {
                TalentsSummaryCard(
                    vm: vm,
                    premiumSlotGemCost: premiumSlotGemCost,
                    onTapPremiumSlot: { showPremiumSlotConfirm = true }
                )

                if vm.isLoading && vm.nodes.isEmpty {
                    loadingView
                } else if vm.nodes.isEmpty {
                    emptyView
                } else {
                    canvasContainer
                }

                resetRow
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            // Reserve room so respec row stays above the sticky bar when it appears.
            .padding(.bottom, vm.hasPendingChanges ? 96 : LayoutConstants.spaceMD)

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
                // Talents v2 — `onStage` advances the staged target rank by one
                // (stageNextRank supports both locked→1 first unlocks and
                // already-unlocked rank-ups). Keeps the sheet closed on the
                // first tap for flat nodes; stays open for ranked nodes so
                // the player can chain rank-ups.
                onStage: {
                    vm.stageNextRank(node)
                    if node.maxRankResolved <= 1 { vm.selectedNode = nil }
                },
                onUnstage: {
                    // For ranked nodes, peel a single staged rank. For flat
                    // nodes this is equivalent to the old "clear pending".
                    vm.unstageRankStep(node)
                    if !vm.isPending(node) { vm.selectedNode = nil }
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
                },
                currentRank: vm.committedRank(for: node.id),
                maxRank: node.maxRankResolved,
                pendingTargetRank: vm.pendingTargetRank(node),
                nextRankCost: vm.nextRankCost(for: node)
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
        .alert("Unlock 4th active slot?", isPresented: $showPremiumSlotConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Unlock — \(premiumSlotGemCost) gems") {
                vm.unlockPremiumSlot()
            }
        } message: {
            Text("Permanently adds a fourth active-skill slot. Costs \(premiumSlotGemCost) gems.")
        }
        .task {
            await vm.load()
        }
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
                currentRank: { vm.committedRank(for: $0.id) },
                stagedRank: { vm.pendingTargetRank($0) ?? 0 },
                onTap: { node in
                    vm.selectedNode = node
                }
            )
            .padding(LayoutConstants.spaceMD)
        }
        .frame(maxWidth: .infinity)
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

    // MARK: - Reset talents — inline rust-tinted row (prototype parity)

    private var resetRow: some View {
        Button {
            vm.showRespecConfirm = true
            HapticManager.light()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .frame(width: LayoutConstants.iconXS, height: LayoutConstants.iconXS)
                Text("RESET TALENTS")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .tracking(2)
                Spacer()
                HStack(spacing: LayoutConstants.spaceXS) {
                    gemDiamond
                    Text("\(respecGemCost) gems")
                        .font(DarkFantasyTheme.uiLabel)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(DarkFantasyTheme.danger.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(DarkFantasyTheme.danger.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(vm.unlockedNodes.isEmpty || vm.isMutating)
        .opacity(vm.unlockedNodes.isEmpty ? 0.45 : 1)
    }

    /// Small purple diamond — gem glyph for inline cost labels.
    private var gemDiamond: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.71, green: 0.49, blue: 0.84),
                        Color(red: 0.48, green: 0.29, blue: 0.66)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(45))
    }

    // MARK: - Sticky Confirm Bar (appears only when there's a pending stage)

    private var stickyConfirmBar: some View {
        VStack(spacing: 0) {
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
