import SwiftUI

/// What there is to read and pick in the room the hero is standing in: the top
/// of the room's panel (`DescentPanel`). Its buttons are `DescentRunActions`,
/// pinned under it.
struct DescentRunPanel: View {
    @Bindable var vm: DescentViewModel
    let snapshot: DescentSnapshot

    var body: some View {
        let s = snapshot
        switch s.screenKind {
        case .depthCard:
            tale(s, centered: true)
        case .depthClear:
            depthClearPanel(s)
        case .fork:
            forkPanel(s)
        case .combat:
            combatPanel(s)
        case .spoils:
            tale(s)
            DescentLootSummary(loot: s.spoils?.loot ?? [], bag: s.bag.gold)
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
        case .result, .unknown:
            EmptyView()
        }
    }

    // MARK: Shared pieces

    /// Under a title on the scene (a depth's gate, the way down) the tale is centred.
    @ViewBuilder
    private func tale(_ s: DescentSnapshot, centered: Bool = false) -> some View {
        if let text = s.tale, !text.isEmpty {
            DescentTale(text: text, centered: centered)
        }
    }

    // MARK: Fork

    @ViewBuilder
    private func forkPanel(_ s: DescentSnapshot) -> some View {
        if let fork = s.fork {
            tale(s)
            if fork.options.count == 2 {
                forkCards(fork, torches: s.hero.torches)
            } else {
                forkRows(fork, torches: s.hero.torches)
            }
        }
    }

    /// Two passages: two cards, in the order they lie (left, right).
    private func forkCards(_ fork: DescentFork, torches: Int) -> some View {
        DescentChoiceCards {
            ForEach(fork.options.sorted { $0.lane < $1.lane }) { option in
                DescentChoiceCard(
                    title: option.known ? (option.typeName ?? "Passage") : "Darkness",
                    subtitle: option.cue,
                    selected: vm.selectedNodeId == option.id,
                    accent: option.known ? DescentStyle.glow(option.roomType) : DarkFantasyTheme.vfxStormFog,
                    direction: DescentDirection(side: option.side),
                    bottomInset: option.known ? 0 : Self.cardTorchHeight + LayoutConstants.spaceSM,
                    action: { vm.select(option) }
                ) {
                    if option.known, let type = option.roomType {
                        DescentRowIcon(asset: type.iconAsset, size: 50)
                    } else {
                        DescentDarkGlyph()
                    }
                }
                .overlay(alignment: .bottom) {
                    if !option.known {
                        cardTorchButton(option, torches: torches)
                            .padding(.horizontal, LayoutConstants.spaceMS)
                            .padding(.bottom, LayoutConstants.spaceMS)
                    }
                }
            }
        }
    }

    private static let cardTorchHeight: CGFloat = 44

    /// Lighting a dark passage, inside its card.
    private func cardTorchButton(_ option: DescentForkOption, torches: Int) -> some View {
        Button {
            vm.perform(.torch(nodeId: option.id))
        } label: {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("rush2-icon-torch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 18)
                    .shadow(color: torches > 0 ? DarkFantasyTheme.glowEmber.opacity(0.6) : .clear, radius: 5)
                Text("LIGHT")
                    .tracking(1.5)
                    .foregroundStyle(torches > 0 ? DarkFantasyTheme.rankChallenger : DarkFantasyTheme.textDisabled)
                Text("· \(torches)")
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .monospacedDigit()
            }
            .font(DarkFantasyTheme.buttonLabelCompact)
            .frame(maxWidth: .infinity, minHeight: Self.cardTorchHeight)
            .background {
                let shape = DescentChamferShape(chamfer: 8)
                ZStack {
                    shape.fill(LinearGradient(colors: [DarkFantasyTheme.bgCardGradientEnd, DarkFantasyTheme.bgDungeonDeep], startPoint: .top, endPoint: .bottom))
                    shape.strokeBorder(torches > 0 ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.borderSubtle, lineWidth: 1.5)
                }
                .compositingGroup()
                .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 4, y: 3)
            }
            .opacity(torches > 0 ? 1 : 0.55)
        }
        .buttonStyle(DescentRowPressStyle())
        .disabled(torches == 0 || vm.isBusy)
        .accessibilityLabel(torches > 0 ? "Light the dark passage, \(torches) torches left" : "No torches left")
    }

    @ViewBuilder
    private func forkRows(_ fork: DescentFork, torches: Int) -> some View {
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
                    torchButton(option, torches: torches)
                }
            }
        }
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
                Text("×\(torches)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                    .monospacedDigit()
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
                notice: vm.autoNotice,
                warning: c.windup ? "Crushing blow next round · Brace" : nil
            )
        }
    }

    // MARK: Chest

    @ViewBuilder
    private func chestPanel(_ s: DescentSnapshot) -> some View {
        if let chest = s.chest {
            tale(s)
            if chest.opened {
                if !chest.loot.isEmpty {
                    // The lid swings open on the scene first.
                    DescentLootSummary(loot: chest.loot, bag: s.bag.gold, countDelay: 0.3)
                }
            } else if chest.inspected {
                DescentChoiceRow(
                    title: "Open the chest",
                    subtitle: "{+It is a real chest.+}",
                    disabled: vm.isBusy,
                    accent: DarkFantasyTheme.glowTreasure,
                    action: { vm.perform(.openChest) }
                ) {
                    DescentRowIcon(asset: "rush2-chest-\(chest.tier)-closed")
                }
            } else {
                DescentChoiceCards {
                    DescentChoiceCard(
                        title: "Open it",
                        subtitle: "What could go wrong?",
                        disabled: vm.isBusy,
                        accent: DarkFantasyTheme.glowTreasure,
                        action: { vm.perform(.openChest) }
                    ) {
                        DescentRowIcon(asset: "rush2-chest-\(chest.tier)-closed", size: 50)
                    }
                    DescentChoiceCard(
                        title: "Inspect · 1 torch",
                        subtitle: s.hero.torches > 0 ? "Hold the light close and look for teeth." : "{-You have no torches.-}",
                        disabled: vm.isBusy || s.hero.torches == 0,
                        accent: DarkFantasyTheme.glowWarm,
                        action: { vm.perform(.inspect) }
                    ) {
                        DescentRowIcon(asset: "rush2-icon-torch", size: 50)
                    }
                }
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
                    DescentLootSummary(loot: event.loot, bag: s.bag.gold, countDelay: 0.15)
                }
            } else if event.choices.count == 2 {
                DescentChoiceCards {
                    ForEach(event.choices) { choice in
                        DescentChoiceCard(
                            title: choice.label,
                            subtitle: choice.disabledReason.map { "{-\($0)-}" } ?? choice.hint,
                            disabled: vm.isBusy || choice.disabledReason != nil,
                            accent: DarkFantasyTheme.rankMaster,
                            action: { vm.perform(.choose(choice.i)) }
                        ) {
                            DescentRowIcon(asset: choice.icon, size: 50)
                        }
                    }
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
            if !camp.done {
                DescentChoiceCards {
                    DescentChoiceCard(
                        title: "Rest",
                        subtitle: "{++30% HP+} by the fire.",
                        disabled: vm.isBusy,
                        accent: DarkFantasyTheme.glowEmber,
                        compact: true,
                        action: { vm.perform(.camp("rest")) }
                    ) {
                        DescentRowIcon(asset: "rush2-node-camp")
                    }
                    DescentChoiceCard(
                        title: "Sharpen",
                        subtitle: "{++12% damage+} for the run.",
                        disabled: vm.isBusy,
                        accent: DarkFantasyTheme.glowEmber,
                        compact: true,
                        action: { vm.perform(.camp("sharpen")) }
                    ) {
                        DescentRowIcon(asset: "rush2-relic-shadowblade")
                    }
                    DescentChoiceCard(
                        title: "Stash",
                        subtitle: stashText(camp),
                        disabled: vm.isBusy || !camp.canStash,
                        accent: DarkFantasyTheme.glowEmber,
                        compact: true,
                        action: { vm.perform(.camp("stash")) }
                    ) {
                        DescentRowIcon(asset: "rush2-chest-wood-closed")
                    }
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
        return "Keep **\(camp.stashGold)** gold\(items) safe."
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
    }

    // MARK: Depth cleared

    /// Deeper or out, as two cards — they are the room's buttons. The way down
    /// shows the next guardian's face and how much richer the gold is; the way
    /// out, the bag that comes home whole. The card tapped stays lit while the
    /// server answers; the other one greys.
    @ViewBuilder
    private func depthClearPanel(_ s: DescentSnapshot) -> some View {
        tale(s, centered: true)
        DescentChoiceCards {
            DescentChoiceCard(
                title: "Descend",
                subtitle: Self.descendText(s.depthClear),
                selected: vm.pendingAction == .descend,
                disabled: vm.isBusy && vm.pendingAction != .descend,
                accent: DarkFantasyTheme.glowEmber,
                action: { vm.perform(.descend) }
            ) {
                DescentRowIcon(asset: s.depthClear?.nextGuardianFace ?? "rush2-node-guardian", size: Self.faceSize)
            }
            DescentChoiceCard(
                title: "Climb out",
                subtitle: Self.climbOutText(s.bag),
                selected: vm.pendingAction == .escape,
                disabled: vm.isBusy && vm.pendingAction != .escape,
                accent: DarkFantasyTheme.gold,
                action: { vm.perform(.escape) }
            ) {
                DescentRowIcon(asset: "rush2-icon-goldpouch", size: 50)
            }
        }
        DescentRiskLine(text: "Fall below and half the bag is lost.")
    }

    /// The next guardian's face fills the medallion's well (`rush2-face-*` are discs).
    private static let faceSize: CGFloat = 62

    static func descendText(_ clear: DescentDepthClear?) -> String {
        guard let clear else { return "Deeper, richer, deadlier." }
        guard let mult = clear.goldMult, mult > 1 else { return "\(clear.nextDepthName)." }
        let x = mult == mult.rounded() ? "\(Int(mult))" : String(format: "%.1f", mult)
        return "\(clear.nextDepthName).\n**Gold ×\(x)**"
    }

    static func climbOutText(_ bag: DescentBag) -> String {
        let n = bag.items.count
        let items = n == 0 ? nil : "\(n) item\(n == 1 ? "" : "s")"
        switch (bag.gold > 0, items) {
        case (true, let items?): return "Keep all of it.\n**\(bag.gold) gold** + \(items)"
        case (true, nil): return "Keep all of it.\n**\(bag.gold) gold**"
        case (false, let items?): return "Keep all of it.\n**\(items)**"
        case (false, nil): return "Walk out alive."
        }
    }

    // MARK: Relic

    @ViewBuilder
    private func relicPanel(_ s: DescentSnapshot) -> some View {
        if let pick = s.relicChoice {
            tale(s)
            if !pick.loot.isEmpty {
                DescentLootSummary(loot: pick.loot, bag: s.bag.gold)
            }
            if !pick.choices.isEmpty {
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

// MARK: - Buttons

/// The room's buttons, pinned under its panel (`DescentPanel`): they stay on
/// screen when what is above them has to scroll.
struct DescentRunActions: View {
    @Bindable var vm: DescentViewModel
    let snapshot: DescentSnapshot
    let onLeave: () -> Void

    var body: some View {
        let s = snapshot
        switch s.screenKind {
        case .depthCard:
            primary(s.depth == 0 ? "Light your torch" : "Descend", .beginDepth)
        case .fork:
            if s.fork != nil {
                Button(enterTitle) { vm.enterSelected() }
                    .buttonStyle(.primary)
                    .disabled(vm.selectedOption == nil || vm.isBusy)
            }
        case .combat:
            if let c = s.combat {
                combatActions(s, combat: c)
            }
        case .spoils:
            primary("Take it all", .takeLoot)
        case .chest:
            if let chest = s.chest {
                if chest.opened {
                    primary("Take it all", .takeLoot)
                } else {
                    secondary("Leave it be", .leave)
                }
            }
        case .event:
            if let event = s.event, event.done {
                switch event.then ?? "continue" {
                case "take_loot":
                    primary("Take it", .takeLoot)
                case "fight_now":
                    primary("Fight!", .fightNow)
                default:
                    primary("Continue", .proceed)
                }
            }
        case .camp:
            if s.camp?.done == true {
                primary("Push on", .proceed)
                secondary("Climb out with your loot", .escape)
            }
        case .merchant:
            secondary("Move on", .proceed)
        case .relic:
            if let pick = s.relicChoice, pick.choices.isEmpty {
                primary("Take the spoils", .takeRelic(nil))
            }
        case .depthClear:
            // Deeper or out are the panel's two cards (`DescentRunPanel`).
            EmptyView()
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

    /// A button keeps its colour while its own action is on the way (`perform`
    /// ignores taps meanwhile): a slow answer must not read as a dead, grey
    /// button. Only the other ways on grey out.
    private func primary(_ title: LocalizedStringKey, _ action: DescentAction) -> some View {
        Button(title) { vm.perform(action) }
            .buttonStyle(.primary)
            .disabled(vm.isBusy && vm.pendingAction != action)
    }

    private func secondary(_ title: LocalizedStringKey, _ action: DescentAction) -> some View {
        Button(title) { vm.perform(action) }
            .buttonStyle(.secondary)
            .disabled(vm.isBusy && vm.pendingAction != action)
    }

    private var enterTitle: String {
        guard let option = vm.selectedOption else { return "Choose a path" }
        return option.roomType == .boss ? "Face the guardian" : "Take this path"
    }

    /// One row, as on the arena: AUTO beside the gold FIGHT button, then Brace
    /// and the flask. Fleeing sits on the scene (`DescentCombatStage`).
    /// Nothing greys out while a round is in flight (`perform` ignores taps
    /// then) — the tumbling dice show the wait instead of a flickering button.
    private func combatActions(_ s: DescentSnapshot, combat c: DescentCombat) -> some View {
        let potionOff = s.hero.potions == 0 || s.hero.hp >= s.hero.maxHp
        return HStack(spacing: LayoutConstants.spaceSM) {
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

// MARK: - Loot

/// Loot as every reward window shows it (docs/07_ui_ux/REWARD_CARDS.md, "Reward
/// cells"): the gold and the XP in cells, the rest of the loot in rows under
/// them — after a fight, under the guardian, in an opened chest, from an event.
/// The gold goes into the bag when it is taken — at risk until the run ends, so
/// its cell reads "Bag 340 → 520" with the risk dot; the XP is already the hero's
/// (the server grants it on the kill), so its cell fills the level bar.
struct DescentLootSummary: View {
    let loot: [DescentLoot]
    /// The bag now, before this loot goes into it.
    let bag: Int
    /// The beat before the cells count, for what lands on the scene first: a kill
    /// stamp (`DescentBanner`), a chest's lid.
    var countDelay: Double = 0.45

    @Environment(AppState.self) private var appState
    /// Read once, when the loot appears: later updates must not move the cells.
    @State private var bagBefore: Int?
    @State private var xpLevel: RewardCellLevel?
    @State private var counting = false

    private var gold: Int { loot.filter { $0.kind == "gold" }.reduce(0) { $0 + $1.amount } }
    private var xp: Int { loot.filter { $0.kind == "xp" }.reduce(0) { $0 + $1.amount } }
    private var others: [DescentLoot] { loot.filter { $0.kind != "gold" && $0.kind != "xp" } }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if gold > 0 || xp > 0 {
                RewardCells(items: cells, isActive: counting)
                if gold > 0 {
                    DescentRiskLine(text: xp > 0 ? "Half the bag is lost if you fall. XP is kept." : "Half the bag is lost if you fall.")
                }
            }
            ForEach(Array(others.enumerated()), id: \.offset) { _, entry in
                DescentLootRow(loot: entry)
            }
        }
        .onAppear(perform: capture)
    }

    private var cells: [RewardCell.Item] {
        var items: [RewardCell.Item] = []
        if gold > 0 {
            items.append(RewardCell.Item(kind: .gold, amount: gold, bagBefore: bagBefore ?? bag))
        }
        if xp > 0 {
            items.append(RewardCell.Item(kind: .xp, amount: xp, level: xpLevel))
        }
        return items
    }

    /// The bag before the gold, the level bar after the XP; then the cells count.
    private func capture() {
        guard bagBefore == nil else { return }
        bagBefore = bag
        if let char = appState.currentCharacter, xp > 0 {
            xpLevel = RewardCellLevel.after(level: char.level, xp: char.experience ?? 0, gained: xp)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + countDelay) {
            counting = true
        }
    }
}

/// What the bag risks, under loot and at the way down: a red dot and one plain line.
struct DescentRiskLine: View {
    let text: LocalizedStringKey

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            Circle()
                .fill(DarkFantasyTheme.danger)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(text)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
