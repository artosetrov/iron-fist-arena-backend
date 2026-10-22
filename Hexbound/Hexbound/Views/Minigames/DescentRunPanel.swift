import SwiftUI

/// The action panel for whatever room the hero is standing in.
struct DescentRunPanel: View {
    @Bindable var vm: DescentViewModel
    let snapshot: DescentSnapshot
    let onLeave: () -> Void

    var body: some View {
        let s = snapshot
        switch s.screenKind {
        case .depthCard:
            tale(s)
            Button(s.depth == 0 ? "Light your torch" : "Descend") { vm.perform(.beginDepth) }
                .buttonStyle(.primary)
                .disabled(vm.isBusy)
        case .fork:
            forkPanel(s)
        case .combat:
            combatPanel(s)
        case .spoils:
            tale(s)
            lootList(s.spoils?.loot ?? [])
            Button("Take it all") { vm.perform(.takeLoot) }
                .buttonStyle(.primary)
                .disabled(vm.isBusy)
        case .chest:
            chestPanel(s)
        case .event:
            eventPanel(s)
        case .camp:
            campPanel(s)
        case .merchant:
            merchantPanel(s)
        case .relic:
            relicPanel(s)
        case .depthClear:
            tale(s)
            Button("Descend to depth \(DescentText.roman(s.depth + 2))") { vm.perform(.descend) }
                .buttonStyle(.primary)
                .disabled(vm.isBusy)
            Button("Climb out · keep it all") { vm.perform(.escape) }
                .buttonStyle(.secondary)
                .disabled(vm.isBusy)
        case .result:
            // The run's end is `DescentResultCard`, over this screen; this way out
            // shows for the beat before it fades in, and if a result screen ever
            // arrives without its result.
            Button("Return to town", action: onLeave)
                .buttonStyle(.secondary)
        case .unknown:
            Button("Refresh") { Task { await vm.load() } }
                .buttonStyle(.secondary)
        }
    }

    // MARK: Shared pieces

    @ViewBuilder
    private func tale(_ s: DescentSnapshot) -> some View {
        if let text = s.tale, !text.isEmpty {
            DescentTale(text: text)
        }
    }

    private func lootList(_ loot: [DescentLoot]) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(Array(loot.enumerated()), id: \.offset) { _, entry in
                DescentLootRow(loot: entry)
            }
        }
    }

    // MARK: Fork

    @ViewBuilder
    private func forkPanel(_ s: DescentSnapshot) -> some View {
        if let fork = s.fork {
            tale(s)
            ForEach(fork.options) { option in
                HStack(spacing: LayoutConstants.spaceSM) {
                    DescentChoiceRow(
                        title: option.known ? (option.typeName ?? "Passage") : "Darkness",
                        subtitle: option.cue,
                        suffix: option.side,
                        selected: vm.selectedNodeId == option.id,
                        accent: option.known ? DescentStyle.glow(option.roomType) : DarkFantasyTheme.vfxStormFog,
                        direction: DescentDirection(side: option.side),
                        action: { vm.select(option) }
                    ) {
                        if option.known, let type = option.roomType {
                            DescentRowIcon(asset: type.iconAsset)
                        } else {
                            DescentDarkGlyph()
                        }
                    }
                    if !option.known {
                        torchButton(option, torches: s.hero.torches)
                    }
                }
            }
            Button(enterTitle) { vm.enterSelected() }
                .buttonStyle(.primary)
                .disabled(vm.selectedOption == nil || vm.isBusy)
        }
    }

    private var enterTitle: String {
        guard let option = vm.selectedOption else { return "Choose a path" }
        return option.roomType == .boss ? "Face the guardian" : "Take this path"
    }

    private func torchButton(_ option: DescentForkOption, torches: Int) -> some View {
        Button {
            vm.perform(.torch(nodeId: option.id))
        } label: {
            VStack(spacing: LayoutConstants.space2XS) {
                Image("rush2-icon-torch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 24)
                    .shadow(color: torches > 0 ? DarkFantasyTheme.glowEmber.opacity(0.6) : .clear, radius: 6)
                Text("LIGHT")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.5)
                    .foregroundStyle(torches > 0 ? DarkFantasyTheme.rankChallenger : DarkFantasyTheme.textDisabled)
            }
            .frame(width: LayoutConstants.touchComfortable + 8, height: 76)
            .background {
                let shape = DescentChamferShape(chamfer: 9)
                ZStack {
                    shape.fill(LinearGradient(colors: [DarkFantasyTheme.bgCardGradientEnd, DarkFantasyTheme.bgDungeonDeep], startPoint: .top, endPoint: .bottom))
                    shape.inset(by: 5).stroke(DarkFantasyTheme.glowEmber.opacity(torches > 0 ? 0.25 : 0.08), lineWidth: 1)
                    shape.strokeBorder(torches > 0 ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
                }
                .compositingGroup()
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 3)
            }
            .opacity(torches > 0 ? 1 : 0.55)
        }
        .buttonStyle(DescentRowPressStyle())
        .disabled(torches == 0 || vm.isBusy)
        .accessibilityLabel(torches > 0 ? "Light a torch, \(torches) left" : "No torches left")
    }

    // MARK: Combat

    @ViewBuilder
    private func combatPanel(_ s: DescentSnapshot) -> some View {
        if let c = s.combat {
            DescentDiceTray(round: c.lastRound, rolling: vm.isRollingRound)
            DescentVerdict(
                lines: c.verdict,
                hint: s.hero.isLow && s.hero.potions > 0 ? "Low health — drink a potion" : nil,
                notice: vm.autoNotice
            )
            // One row, as on the arena: AUTO beside the gold FIGHT button, then Brace
            // and the flask. Fleeing sits on the scene (`DescentCombatStage`).
            // Nothing greys out while a round is in flight (`perform` ignores taps
            // then) — the tumbling dice show the wait instead of a flickering button.
            let potionOff = s.hero.potions == 0 || s.hero.hp >= s.hero.maxHp
            HStack(spacing: LayoutConstants.spaceSM) {
                Button { vm.toggleAuto() } label: {
                    Text("AUTO")
                }
                .buttonStyle(.combatToggle(isActive: vm.autoFight))
                .frame(width: 64)
                .accessibilityLabel("Auto-fight")
                .accessibilityValue(vm.autoFight ? "On" : "Off")
                Button("Strike") { vm.perform(.strike) }
                    .buttonStyle(.primary)
                    .disabled(vm.autoFight)
                Button { vm.perform(.brace) } label: {
                    Text("BRACE")
                }
                .buttonStyle(.combatControl)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                        .strokeBorder(DarkFantasyTheme.danger, lineWidth: c.windup ? 2 : 0)
                        .allowsHitTesting(false)
                )
                .frame(width: 80)
                .disabled(vm.autoFight)
                .opacity(vm.autoFight ? 0.45 : 1)
                .accessibilityLabel("Brace")
                .accessibilityHint(c.windup ? "A crushing blow is coming" : "")
                Button {
                    vm.perform(.potion)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image("rush2-icon-potion")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text("\(s.hero.potions)")
                            .monospacedDigit()
                    }
                }
                .buttonStyle(.combatControl)
                .frame(width: 64)
                .disabled(vm.autoFight || potionOff)
                .opacity(vm.autoFight || potionOff ? 0.45 : 1)
                .accessibilityLabel("Drink a potion, \(s.hero.potions) left")
            }
        }
    }

    // MARK: Chest

    @ViewBuilder
    private func chestPanel(_ s: DescentSnapshot) -> some View {
        if let chest = s.chest {
            tale(s)
            if chest.opened {
                lootList(chest.loot)
                Button("Take it all") { vm.perform(.takeLoot) }
                    .buttonStyle(.primary)
                    .disabled(vm.isBusy)
            } else {
                DescentChoiceRow(
                    title: "Open the chest",
                    subtitle: chest.inspected ? "{+It is a real chest.+}" : "What could go wrong?",
                    disabled: vm.isBusy,
                    accent: DarkFantasyTheme.glowTreasure,
                    action: { vm.perform(.openChest) }
                ) {
                    DescentRowIcon(asset: "rush2-chest-\(chest.tier)-closed")
                }
                if !chest.inspected {
                    DescentChoiceRow(
                        title: "Inspect it · 1 torch",
                        subtitle: s.hero.torches > 0 ? "Hold the light close and look for teeth." : "{-You have no torches.-}",
                        disabled: vm.isBusy || s.hero.torches == 0,
                        accent: DarkFantasyTheme.glowWarm,
                        action: { vm.perform(.inspect) }
                    ) {
                        DescentRowIcon(asset: "rush2-icon-torch")
                    }
                }
                Button("Leave it be") { vm.perform(.leave) }
                    .buttonStyle(.secondary)
                    .disabled(vm.isBusy)
            }
        }
    }

    // MARK: Event

    @ViewBuilder
    private func eventPanel(_ s: DescentSnapshot) -> some View {
        if let event = s.event {
            tale(s)
            if event.done {
                if !event.loot.isEmpty {
                    lootList(event.loot)
                }
                switch event.then ?? "continue" {
                case "take_loot":
                    Button("Take it") { vm.perform(.takeLoot) }
                        .buttonStyle(.primary)
                        .disabled(vm.isBusy)
                case "fight_now":
                    Button("Fight!") { vm.perform(.fightNow) }
                        .buttonStyle(.primary)
                        .disabled(vm.isBusy)
                default:
                    Button("Continue") { vm.perform(.proceed) }
                        .buttonStyle(.primary)
                        .disabled(vm.isBusy)
                }
            } else {
                ForEach(event.choices) { choice in
                    DescentChoiceRow(
                        title: choice.label,
                        subtitle: choice.disabledReason.map { "{-\($0)-}" } ?? choice.hint,
                        disabled: vm.isBusy || choice.disabledReason != nil,
                        accent: DarkFantasyTheme.rankMaster,
                        action: { vm.perform(.choose(choice.i)) }
                    ) {
                        DescentRowIcon(asset: choice.icon)
                    }
                }
            }
        }
    }

    // MARK: Camp

    @ViewBuilder
    private func campPanel(_ s: DescentSnapshot) -> some View {
        if let camp = s.camp {
            tale(s)
            if camp.done {
                Button("Push on") { vm.perform(.proceed) }
                    .buttonStyle(.primary)
                    .disabled(vm.isBusy)
                Button("Climb out with your loot") { vm.perform(.escape) }
                    .buttonStyle(.secondary)
                    .disabled(vm.isBusy)
            } else {
                DescentChoiceRow(
                    title: "Rest",
                    subtitle: "{++30% HP.+} Sleep by the fire.",
                    disabled: vm.isBusy,
                    accent: DarkFantasyTheme.glowEmber,
                    action: { vm.perform(.camp("rest")) }
                ) {
                    DescentRowIcon(asset: "rush2-node-camp")
                }
                DescentChoiceRow(
                    title: "Sharpen your blade",
                    subtitle: "{++12% damage+} for the rest of the run.",
                    disabled: vm.isBusy,
                    accent: DarkFantasyTheme.glowEmber,
                    action: { vm.perform(.camp("sharpen")) }
                ) {
                    DescentRowIcon(asset: "rush2-relic-shadowblade")
                }
                DescentChoiceRow(
                    title: "Stash your loot",
                    subtitle: stashText(camp),
                    disabled: vm.isBusy || !camp.canStash,
                    accent: DarkFantasyTheme.glowEmber,
                    action: { vm.perform(.camp("stash")) }
                ) {
                    DescentRowIcon(asset: "rush2-chest-wood-closed")
                }
                Text("YOU HAVE TIME FOR ONE")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
            }
        }
    }

    private func stashText(_ camp: DescentCamp) -> String {
        guard camp.canStash else { return "Your bag is empty." }
        let items = camp.stashItems > 0 ? " and \(camp.stashItems) item\(camp.stashItems > 1 ? "s" : "")" : ""
        return "Stash **\(camp.stashGold)** gold\(items) in the camp chest. Safe even if you fall."
    }

    // MARK: Merchant

    @ViewBuilder
    private func merchantPanel(_ s: DescentSnapshot) -> some View {
        tale(s)
        ForEach(s.merchant?.wares ?? []) { ware in
            DescentChoiceRow(
                title: ware.name,
                subtitle: ware.desc,
                trailing: ware.sold ? "Sold" : "\(ware.price)",
                disabled: vm.isBusy || !ware.available,
                accent: DarkFantasyTheme.rankPlatinum,
                action: { vm.perform(.buy(ware.i)) }
            ) {
                DescentRowIcon(asset: ware.icon)
            }
        }
        Button("Move on") { vm.perform(.proceed) }
            .buttonStyle(.secondary)
            .disabled(vm.isBusy)
    }

    // MARK: Relic

    @ViewBuilder
    private func relicPanel(_ s: DescentSnapshot) -> some View {
        if let pick = s.relicChoice {
            tale(s)
            lootList(pick.loot)
            if pick.choices.isEmpty {
                Button("Take the spoils") { vm.perform(.takeRelic(nil)) }
                    .buttonStyle(.primary)
                    .disabled(vm.isBusy)
            } else {
                Text("CHOOSE ONE RELIC")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(pick.choices) { relic in
                    DescentChoiceRow(
                        title: relic.name,
                        subtitle: relic.desc,
                        disabled: vm.isBusy,
                        accent: DarkFantasyTheme.rarityEpic,
                        action: { vm.perform(.takeRelic(relic.key)) }
                    ) {
                        DescentRowIcon(asset: relic.icon, size: 36)
                    }
                }
            }
        }
    }
}
