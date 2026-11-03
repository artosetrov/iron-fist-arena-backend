import SwiftUI

/// Top band of the Descent.
///
/// One row to find your way: back, the depth — its name and the rooms walked,
/// which is also the map button — and the bag. Under it, out of a fight, the
/// hero's health, buffs and flask; in a fight, the duel strip (your health
/// against the foe's, face to face, and what the foe does), so nothing is drawn
/// over the foe's art. Torches show on the fork's LIGHT button and in the bag,
/// relics in the bag; in a fight the flask is in the action row.
struct DescentHUD: View {
    let snapshot: DescentSnapshot
    let canDrink: Bool
    let onMap: () -> Void
    let onBag: () -> Void
    let onDrink: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navRow
                .padding(.horizontal, LayoutConstants.spaceSM)
            if snapshot.screenKind == .combat, let combat = snapshot.combat {
                DescentDuelStrip(hero: snapshot.hero, combat: combat)
                    .padding(.top, LayoutConstants.spaceXS)
            } else {
                vitalsRow
                    .padding(.horizontal, LayoutConstants.spaceMS)
                    .padding(.top, LayoutConstants.spaceXS)
                    .padding(.bottom, LayoutConstants.spaceSM)
            }
        }
        .background(
            LinearGradient(colors: [DarkFantasyTheme.bgDungeonDeep, DarkFantasyTheme.bgAbyss], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(DarkFantasyTheme.borderSubtle).frame(height: 1)
        }
    }

    // MARK: Way-finding

    private var navRow: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            HubLogoButton()
            Button(action: onMap) {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image("rush2-map-parchment")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 19)
                        Text(snapshot.depthRoman)
                            .foregroundStyle(DarkFantasyTheme.gold)
                        Text(snapshot.depthName.uppercased())
                            .foregroundStyle(DarkFantasyTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.5)
                    DescentDepthTrack(progress: snapshot.progress)
                }
                .frame(maxWidth: .infinity, minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
            }
            .buttonStyle(DescentHUDPressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Depth \(snapshot.depthRoman), \(snapshot.depthName). Room \(max(1, snapshot.progress.current + 1)) of \(snapshot.progress.total).")
            .accessibilityHint("Opens the map")
            .accessibilityAddTraits(.isButton)
            bagButton
        }
        .frame(minHeight: LayoutConstants.touchMin)
    }

    private var bagButton: some View {
        Button(action: onBag) {
            HStack(spacing: 6) {
                Image("rush2-icon-goldpouch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 24)
                Text("\(snapshot.bag.gold)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textGold)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: MotionConstants.fast), value: snapshot.bag.gold)
                Circle()
                    .fill(snapshot.bag.isEmpty ? DarkFantasyTheme.borderMedium : DarkFantasyTheme.danger)
                    .frame(width: 8, height: 8)
                    .shadow(color: snapshot.bag.isEmpty ? .clear : DarkFantasyTheme.dangerGlow, radius: 4)
            }
            .padding(.horizontal, LayoutConstants.spaceMS)
            .frame(minHeight: LayoutConstants.touchMin - 4)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
            )
        }
        .buttonStyle(DescentHUDPressStyle())
        .accessibilityLabel("Your bag: \(snapshot.bag.gold) gold at risk, \(snapshot.bag.items.count) items")
    }

    // MARK: Out of a fight

    private var vitalsRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            DescentHPBar(
                value: snapshot.hero.hp,
                maxValue: snapshot.hero.maxHp,
                fill: DarkFantasyTheme.canonicalHpGradient(percentage: snapshot.hero.hpFraction),
                label: "HP \(snapshot.hero.hp) / \(snapshot.hero.maxHp)",
                isLow: snapshot.hero.isLow,
                labelAlignment: .center
            )
            .frame(height: 28)
            .accessibilityLabel("Health \(snapshot.hero.hp) of \(snapshot.hero.maxHp)")
            DescentHeroStatus(hero: snapshot.hero)
            flaskButton
        }
        .frame(height: 40)
    }

    private var flaskButton: some View {
        Button(action: onDrink) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("rush2-icon-potion")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 25)
                Text("\(snapshot.hero.potions)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
            }
            .frame(width: 56, height: 40)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(canDrink ? DarkFantasyTheme.btnDangerFill.opacity(0.55) : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(canDrink ? DarkFantasyTheme.danger.opacity(0.6) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .opacity(canDrink ? 1 : 0.6)
            .frame(minWidth: LayoutConstants.touchMin, minHeight: LayoutConstants.touchMin)
            .contentShape(Rectangle())
        }
        .buttonStyle(DescentHUDPressStyle())
        .disabled(!canDrink)
        .accessibilityLabel("Drink a potion, \(snapshot.hero.potions) left, heals \(snapshot.hero.potionHeal)")
    }
}

/// HUD buttons dim while pressed; their own actions play their sounds.
struct DescentHUDPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}

// MARK: - Duel strip

/// In a fight: your health against the foe's, face to face, and one line of
/// what the foe does. It sits above the scene, so the foe's art stays clear.
/// What the foe is about to do (a crushing blow) is in the action panel, by Brace.
struct DescentDuelStrip: View {
    let hero: DescentHero
    let combat: DescentCombat

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: LayoutConstants.spaceSM) {
                Text("YOU")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(2)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                DescentHeroStatus(hero: hero)
                Spacer(minLength: LayoutConstants.spaceSM)
                foeName
            }
            .frame(height: 22)

            HStack(spacing: 6) {
                DescentHPBar(
                    value: hero.hp,
                    maxValue: hero.maxHp,
                    fill: DarkFantasyTheme.canonicalHpGradient(percentage: hero.hpFraction),
                    label: "\(hero.hp) / \(hero.maxHp)",
                    isLow: hero.isLow
                )
                Rectangle()
                    .fill(DarkFantasyTheme.gold)
                    .frame(width: 9, height: 9)
                    .rotationEffect(.degrees(45))
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 4)
                    .accessibilityHidden(true)
                DescentHPBar(
                    value: combat.hp,
                    maxValue: combat.maxHp,
                    fill: DarkFantasyTheme.hpCriticalGradient,
                    label: "\(combat.hp.formatted()) / \(combat.maxHp.formatted())",
                    fromTrailing: true
                )
            }
            .frame(height: 28)

            if hasTraits {
                traitsText
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.top, 7)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(
            LinearGradient(colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgDarkPanel], startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(DarkFantasyTheme.borderSubtle).frame(height: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    private var nameColor: Color {
        combat.isBoss ? DarkFantasyTheme.textDanger : combat.isElite ? DarkFantasyTheme.btnOrangeBright : DarkFantasyTheme.textPrimary
    }

    private var kindLabel: String {
        combat.isBoss ? "GUARDIAN" : combat.isElite ? "ELITE" : "LV \(combat.level)"
    }

    /// The kind and the name when both fit, else the name alone.
    private var foeName: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                Text(kindLabel)
                    .tracking(1.5)
                    .foregroundStyle(DarkFantasyTheme.textTertiaryAA)
                Text(combat.name.uppercased())
                    .tracking(1)
                    .foregroundStyle(nameColor)
            }
            Text(combat.name.uppercased())
                .tracking(1)
                .foregroundStyle(nameColor)
                .minimumScaleFactor(0.7)
        }
        .font(DarkFantasyTheme.buttonLabelCompact)
        .lineLimit(1)
    }

    private var hasTraits: Bool {
        !combat.traits.isEmpty || !combat.canFlee || combat.enraged
    }

    /// "Frenzy below 35% · Crush every 3rd · No escape"; the frenzy turns
    /// into FRENZIED, in orange, once it has set in.
    private var traitsText: Text {
        let muted = DarkFantasyTheme.textTertiaryAA
        var parts: [Text] = combat.traits.map { trait in
            if trait.key == "enrage", combat.enraged {
                return Text("FRENZIED").foregroundStyle(DarkFantasyTheme.btnOrangeBright)
            }
            return Text(trait.shortLabel).foregroundStyle(muted)
        }
        if combat.enraged, !combat.traits.contains(where: { $0.key == "enrage" }) {
            parts.append(Text("FRENZIED").foregroundStyle(DarkFantasyTheme.btnOrangeBright))
        }
        if !combat.canFlee {
            parts.append(Text("No escape").foregroundStyle(muted))
        }
        guard let first = parts.first else { return Text(verbatim: "") }
        return parts.dropFirst().reduce(first) { line, part in
            line + Text("  ·  ").foregroundStyle(muted) + part
        }
    }

    private var spokenSummary: String {
        var traits = combat.traits.map(\.shortLabel)
        if combat.enraged { traits.append("frenzied") }
        if !combat.canFlee { traits.append("no escape") }
        let kind = combat.isBoss ? "guardian" : combat.isElite ? "elite" : "level \(combat.level)"
        let what = traits.isEmpty ? "" : " " + traits.joined(separator: ", ") + "."
        return "You: \(hero.hp) of \(hero.maxHp) health. \(combat.name), \(kind): \(combat.hp) of \(combat.maxHp) health.\(what)"
    }
}

// MARK: - Pieces

/// The damage bonus and the curse, as small pills; nothing when neither is on.
struct DescentHeroStatus: View {
    let hero: DescentHero

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            if hero.dmgBonusPct > 0 {
                pill(DarkFantasyTheme.textSuccess) {
                    Image("icon-strength")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("+\(hero.dmgBonusPct)%")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Plus \(hero.dmgBonusPct) percent damage")
            }
            if hero.cursedFights > 0 {
                pill(DarkFantasyTheme.textDanger) {
                    Text("CURSED \(hero.cursedFights)")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Cursed for \(hero.cursedFights) more fights")
            }
        }
    }

    private func pill<Content: View>(_ tint: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 3) {
            content()
        }
        .font(DarkFantasyTheme.buttonLabelCompact)
        .foregroundStyle(tint)
        .lineLimit(1)
        .fixedSize()
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .frame(height: 22)
        .background(Capsule().fill(tint.opacity(0.08)))
        .overlay(Capsule().stroke(tint.opacity(0.4), lineWidth: 1))
    }
}

/// A health bar with its numbers inside. The hero's grows from the left; the
/// foe's, across from it in the duel strip, from the right.
struct DescentHPBar: View {
    let value: Int
    let maxValue: Int
    let fill: LinearGradient
    let label: String
    var fromTrailing = false
    var isLow = false
    var labelAlignment: Alignment? = nil

    private var fraction: Double {
        maxValue > 0 ? Double(value) / Double(maxValue) : 0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: fromTrailing ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgAbyss)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(fill)
                    .frame(width: geo.size.width * max(0, min(1, fraction)))
                    .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusSM))
                    .animation(.easeOut(duration: MotionConstants.normal), value: value)
                Text(label)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 2, y: 1)
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .frame(maxWidth: .infinity, alignment: labelAlignment ?? (fromTrailing ? .trailing : .leading))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(isLow ? DarkFantasyTheme.danger.opacity(0.8) : DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Health \(value) of \(maxValue)")
    }
}

/// The rooms of this depth as short bars, then the guardian's mark.
struct DescentDepthTrack: View {
    let progress: DescentProgress

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<max(0, progress.total - 1), id: \.self) { i in
                Capsule()
                    .fill(color(i))
                    .frame(width: 20, height: 4)
                    .shadow(color: isCurrent(i) ? DarkFantasyTheme.goldGlow : .clear, radius: 4)
            }
            Image("rush2-node-guardian")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 16)
                .opacity(atGuardian ? 1 : 0.55)
                .shadow(color: atGuardian ? DarkFantasyTheme.danger.opacity(0.8) : .clear, radius: 5)
                .padding(.leading, LayoutConstants.space2XS)
        }
        .accessibilityHidden(true)
    }

    private var atGuardian: Bool { progress.current >= progress.total - 1 }

    private func isCurrent(_ i: Int) -> Bool { i == progress.current && !progress.currentCleared }

    private func color(_ i: Int) -> Color {
        if i < progress.current || (i == progress.current && progress.currentCleared) { return DarkFantasyTheme.gold }
        if i == progress.current { return DarkFantasyTheme.goldBright }
        return DarkFantasyTheme.borderMedium
    }
}
