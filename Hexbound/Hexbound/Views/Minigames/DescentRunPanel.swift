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
            Button("Return to the surface · keep everything") { vm.perform(.escape) }
                .buttonStyle(.secondary)
                .disabled(vm.isBusy)
        case .result:
            resultPanel(s)
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
                        title: "\(option.side) · \(option.known ? (option.typeName ?? "Passage") : "Darkness")",
                        subtitle: option.cue,
                        selected: vm.selectedNodeId == option.id,
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
                Text("LIGHT")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1)
                    .foregroundStyle(torches > 0 ? DarkFantasyTheme.gold : DarkFantasyTheme.textDisabled)
            }
            .frame(width: LayoutConstants.touchComfortable + 8, height: LayoutConstants.touchComfortable + 8)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(torches > 0 ? DarkFantasyTheme.goldDim : DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
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
            DescentDiceTray(round: c.lastRound)
            DescentVerdict(
                lines: c.verdict,
                hint: s.hero.isLow && s.hero.potions > 0 ? "Low health — drink a potion" : nil,
                notice: vm.autoNotice
            )
            HStack(spacing: LayoutConstants.spaceSM) {
                Button("Strike") { vm.perform(.strike) }
                    .buttonStyle(.primary)
                    .disabled(vm.isBusy || vm.autoFight)
                Button("Brace") { vm.perform(.brace) }
                    .buttonStyle(.neutral)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.buttonRadius)
                            .stroke(DarkFantasyTheme.danger, lineWidth: c.windup ? 2 : 0)
                    )
                    .disabled(vm.isBusy || vm.autoFight)
                Button("Potion \(s.hero.potions)") { vm.perform(.potion) }
                    .buttonStyle(.neutral)
                    .disabled(vm.isBusy || vm.autoFight || s.hero.potions == 0 || s.hero.hp >= s.hero.maxHp)
            }
            HStack(spacing: LayoutConstants.spaceSM) {
                Toggle(isOn: Binding(get: { vm.autoFight }, set: { _ in vm.toggleAuto() })) {
                    Text("AUTO-FIGHT")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(1.5)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .toggleStyle(.switch)
                .tint(DarkFantasyTheme.gold)
                .fixedSize()
                Spacer(minLength: LayoutConstants.spaceSM)
                if c.canFlee {
                    Button {
                        vm.perform(.flee)
                    } label: {
                        Text("Flee to the fork (−8% HP)")
                            .font(DarkFantasyTheme.buttonLabelCompact)
                            .underline()
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: LayoutConstants.touchMin)
                    .disabled(vm.isBusy)
                } else {
                    Text("No escape from a guardian")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                        .multilineTextAlignment(.trailing)
                }
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
                    action: { vm.perform(.openChest) }
                ) {
                    DescentRowIcon(asset: "rush2-chest-\(chest.tier)-closed")
                }
                if !chest.inspected {
                    DescentChoiceRow(
                        title: "Inspect it · 1 torch",
                        subtitle: s.hero.torches > 0 ? "Hold the light close and look for teeth." : "{-You have no torches.-}",
                        disabled: vm.isBusy || s.hero.torches == 0,
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
                    action: { vm.perform(.camp("rest")) }
                ) {
                    DescentRowIcon(asset: "rush2-node-camp")
                }
                DescentChoiceRow(
                    title: "Sharpen your blade",
                    subtitle: "{++12% damage+} for the rest of the run.",
                    disabled: vm.isBusy,
                    action: { vm.perform(.camp("sharpen")) }
                ) {
                    DescentRowIcon(asset: "rush2-relic-shadowblade")
                }
                DescentChoiceRow(
                    title: "Stash your loot",
                    subtitle: stashText(camp),
                    disabled: vm.isBusy || !camp.canStash,
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
                        tone: DarkFantasyTheme.rarityEpic,
                        action: { vm.perform(.takeRelic(relic.key)) }
                    ) {
                        DescentRowIcon(asset: relic.icon, size: 36)
                    }
                }
            }
        }
    }

    // MARK: Result

    @ViewBuilder
    private func resultPanel(_ s: DescentSnapshot) -> some View {
        if let r = s.result {
            DescentSummaryBox(title: "You keep") {
                DescentValueLine(label: "Gold", value: "\(r.keptGold)", color: DarkFantasyTheme.textGold)
                DescentValueLine(label: "Experience", value: "\(r.xp) XP")
                DescentItemsList(items: r.keptItems, empty: "No items this time")
            }
            if r.outcome == "dead" || r.outcome == "abandoned" {
                DescentSummaryBox(title: "Lost in the dark", note: "Half your bag", danger: true) {
                    DescentValueLine(label: "Gold from your bag", value: "−\(r.lostGold)", color: DarkFantasyTheme.textDanger)
                    if !r.lostItems.isEmpty {
                        DescentItemsList(items: r.lostItems)
                    }
                    Text("The other half made it out with you. Stashed loot and experience are never lost.")
                        .font(DarkFantasyTheme.tale)
                        .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                }
            }
            Button {
                Task { await vm.start() }
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("Descend again")
                    Image("icon-stamina")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("\(vm.staminaCost)")
                }
            }
            .buttonStyle(.primary)
            .disabled(vm.isStarting)
            .accessibilityLabel("Descend again, costs \(vm.staminaCost) stamina")
            Button("Return to town", action: onLeave)
                .buttonStyle(.secondary)
        }
    }
}
