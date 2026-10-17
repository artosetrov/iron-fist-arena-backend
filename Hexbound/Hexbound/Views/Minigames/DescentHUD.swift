import SwiftUI

/// Top band of the Descent: back, map, depth, bag; health with the potion
/// flask beside it; torches, the depth's progress and the relics carried.
struct DescentHUD: View {
    let snapshot: DescentSnapshot
    let canDrink: Bool
    let onMap: () -> Void
    let onBag: () -> Void
    let onDrink: () -> Void

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            HStack(spacing: LayoutConstants.spaceSM) {
                HubLogoButton()
                iconButton(label: "Map of this depth", action: onMap) {
                    Image("rush2-map-parchment")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 28)
                }
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    Text("DEPTH \(snapshot.depthRoman)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .tracking(3)
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text(snapshot.depthName)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                bagButton
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                DescentHeroHPBar(hero: snapshot.hero)
                flaskButton
            }

            HStack(spacing: LayoutConstants.spaceMS) {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image("rush2-icon-torch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 20)
                    Text("\(snapshot.hero.torches)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(snapshot.hero.torches) torches")

                DescentProgressDots(progress: snapshot.progress)

                if snapshot.hero.dmgBonusPct > 0 {
                    Text("+\(snapshot.hero.dmgBonusPct)% DMG")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textSuccess)
                        .lineLimit(1)
                }
                if snapshot.hero.cursedFights > 0 {
                    Text("CURSED \(snapshot.hero.cursedFights)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .foregroundStyle(DarkFantasyTheme.textDanger)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                HStack(spacing: LayoutConstants.space2XS) {
                    ForEach(snapshot.relics.prefix(6)) { relic in
                        Image(relic.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .accessibilityLabel(relic.name)
                    }
                }
            }
            .frame(minHeight: 22)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.top, LayoutConstants.spaceXS)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(
            LinearGradient(colors: [DarkFantasyTheme.bgDungeonDeep, DarkFantasyTheme.bgAbyss], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(DarkFantasyTheme.borderSubtle).frame(height: 1)
        }
    }

    private var bagButton: some View {
        Button(action: onBag) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("rush2-icon-goldpouch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 26)
                Text("\(snapshot.bag.gold)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textGold)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: MotionConstants.fast), value: snapshot.bag.gold)
                Circle()
                    .fill(snapshot.bag.isEmpty ? DarkFantasyTheme.borderMedium : DarkFantasyTheme.danger)
                    .frame(width: 8, height: 8)
                    .shadow(color: snapshot.bag.isEmpty ? .clear : DarkFantasyTheme.dangerGlow, radius: 4)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(minHeight: LayoutConstants.touchMin)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your bag: \(snapshot.bag.gold) gold at risk, \(snapshot.bag.items.count) items")
    }

    private var flaskButton: some View {
        Button(action: onDrink) {
            HStack(spacing: LayoutConstants.spaceXS) {
                Image("rush2-icon-potion")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 26)
                Text("×\(snapshot.hero.potions)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                Text("DRINK")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.5)
                    .foregroundStyle(canDrink ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textTertiaryAA)
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .frame(minHeight: 40)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(canDrink ? DarkFantasyTheme.btnDangerFill.opacity(0.55) : DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .stroke(canDrink ? DarkFantasyTheme.danger.opacity(0.6) : DarkFantasyTheme.borderSubtle, lineWidth: 1)
            )
            .opacity(canDrink ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .disabled(!canDrink)
        .accessibilityLabel("Drink a potion, \(snapshot.hero.potions) left, heals \(snapshot.hero.potionHeal)")
    }

    private func iconButton<Label: View>(label: String, action: @escaping () -> Void, @ViewBuilder content: () -> Label) -> some View {
        Button(action: action) {
            content()
                .frame(width: LayoutConstants.touchMin - 8, height: LayoutConstants.touchMin - 8)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                        .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
                )
                .frame(minWidth: LayoutConstants.touchMin, minHeight: LayoutConstants.touchMin)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// The hero's health, with the number inside the bar.
struct DescentHeroHPBar: View {
    let hero: DescentHero

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.bgAbyss)
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(DarkFantasyTheme.canonicalHpGradient(percentage: hero.hpFraction))
                    .frame(width: geo.size.width * max(0, min(1, hero.hpFraction)))
                    .overlay(BarFillHighlight(cornerRadius: LayoutConstants.radiusSM))
                    .animation(.easeOut(duration: MotionConstants.normal), value: hero.hp)
                Text("HP \(hero.hp) / \(hero.maxHp)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .monospacedDigit()
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 2, y: 1)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 28)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(hero.isLow ? DarkFantasyTheme.danger.opacity(0.8) : DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Health \(hero.hp) of \(hero.maxHp)")
    }
}

/// One dot per room row of the depth, then the guardian's diamond.
struct DescentProgressDots: View {
    let progress: DescentProgress

    var body: some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            ForEach(0..<max(0, progress.total - 1), id: \.self) { i in
                Circle()
                    .fill(color(i))
                    .frame(width: 8, height: 8)
                    .shadow(color: i == progress.current && !progress.currentCleared ? DarkFantasyTheme.goldGlow : .clear, radius: 4)
            }
            Rectangle()
                .fill(progress.current >= progress.total - 1 ? DarkFantasyTheme.danger : DarkFantasyTheme.btnDangerStroke)
                .frame(width: 9, height: 9)
                .overlay(Rectangle().stroke(DarkFantasyTheme.danger, lineWidth: 1))
                .rotationEffect(.degrees(45))
                .padding(.leading, LayoutConstants.space2XS)
        }
        .accessibilityElement()
        .accessibilityLabel("Room \(max(0, progress.current + 1)) of \(progress.total)")
    }

    private func color(_ i: Int) -> Color {
        if i < progress.current || (i == progress.current && progress.currentCleared) { return DarkFantasyTheme.gold }
        if i == progress.current { return DarkFantasyTheme.goldBright }
        return DarkFantasyTheme.borderMedium
    }
}
