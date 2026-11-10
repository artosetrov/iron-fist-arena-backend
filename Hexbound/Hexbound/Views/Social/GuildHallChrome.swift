import SwiftUI

// MARK: - Header

/// Inside the hall behind the title (`bg-guild-hall`, 2026-11-04): beams,
/// banners, the notice board on the left, the Chronicler's ledger on the right,
/// the cold hearth at the back. Dimmed under the title, fading into the
/// screen. Scrolls away; the banner tabs stay.
struct GuildHallHeader: View {
    var body: some View {
        OrnamentalTitle("GUILD HALL", subtitle: "Bonds forged in battle", accentColor: DarkFantasyTheme.gold)
            .padding(.top, LayoutConstants.spaceSM)
            .frame(maxWidth: .infinity)
            .frame(height: 196, alignment: .top)
            .background {
                Color.clear
                    .overlay {
                        Image("bg-guild-hall")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                            .brightness(-0.1)
                    }
                    .overlay {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [DarkFantasyTheme.bgPrimary.opacity(0.92), DarkFantasyTheme.bgPrimary.opacity(0.25)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 96)
                            Spacer(minLength: 0)
                            LinearGradient(
                                colors: [DarkFantasyTheme.bgPrimary.opacity(0), DarkFantasyTheme.bgPrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 72)
                        }
                    }
                    .overlay { DescentVignette(strength: 0.45) }
                    .clipped()
                    .accessibilityHidden(true)
            }
    }
}

// MARK: - Banner tabs

/// The three tabs as hanging pennants with their emblems — crimson and gold
/// when raised. Plays the same tap sound and haptic as `TabSwitcher`.
struct GuildBannerTabs: View {
    struct Item: Identifiable {
        let id: Int
        let title: String
        let emblem: String
        let badge: Int
    }

    let items: [Item]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            ForEach(items) { item in
                let isOn = item.id == selectedIndex
                Button {
                    guard selectedIndex != item.id else { return }
                    selectedIndex = item.id
                    SFXManager.shared.play(.uiTap)
                    HapticManager.selection()
                } label: {
                    GuildPennant(title: item.title, emblem: item.emblem, isRaised: isOn)
                        .overlay(alignment: .topTrailing) {
                            if item.badge > 0 {
                                Text("\(item.badge)")
                                    .font(DarkFantasyTheme.buttonLabelCompact)
                                    .monospacedDigit()
                                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                                    .padding(.horizontal, LayoutConstants.spaceXS)
                                    .frame(minWidth: 22, minHeight: 22)
                                    .background(Capsule().fill(DarkFantasyTheme.goldBright))
                                    .overlay(Capsule().stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5))
                                    .offset(x: 4, y: -6)
                            }
                        }
                }
                .buttonStyle(GuildPressStyle())
                .accessibilityLabel(item.badge > 0 ? "\(item.title.capitalized), \(item.badge) new" : item.title.capitalized)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct GuildPennant: View {
    let title: String
    let emblem: String
    let isRaised: Bool

    var body: some View {
        let shape = GuildPennantShape()
        HStack(spacing: LayoutConstants.spaceXS) {
            Image(emblem)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 30, height: 26)
                .saturation(isRaised ? 1 : 0.6)
                .accessibilityHidden(true)
            Text(title)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.5)
                .foregroundStyle(isRaised ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, LayoutConstants.spaceXS)
        .padding(.bottom, LayoutConstants.spaceSM)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            shape.fill(
                LinearGradient(
                    colors: isRaised
                        ? [DarkFantasyTheme.btnDangerFill, DarkFantasyTheme.btnDangerStroke]
                        : [DarkFantasyTheme.bgElevated, DarkFantasyTheme.bgSecondary],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(
            shape.stroke(isRaised ? DarkFantasyTheme.gold : DarkFantasyTheme.borderMedium, lineWidth: isRaised ? 2 : 1)
        )
        .shadow(color: isRaised ? DarkFantasyTheme.dangerGlow.opacity(0.35) : .clear, radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 4, y: 3)
        .contentShape(shape)
    }
}

/// A banner cut into a swallow point at the bottom.
struct GuildPennantShape: Shape {
    /// How deep the point is, as a share of the height.
    var point: CGFloat = 0.2

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * point))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * point))
        path.closeSubpath()
        return path
    }
}

/// Press = a touch darker (the project's press rule), no scale.
struct GuildPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}

// MARK: - Section label

/// "YOUR ALLIES ··········· 3 / 50" — a quiet label over a block.
struct GuildSectionLabel: View {
    let title: String
    var trailing: String? = nil
    var trailingColor: Color = DarkFantasyTheme.goldBright

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(2)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: LayoutConstants.spaceSM)
            if let trailing {
                Text(trailing)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .foregroundStyle(trailingColor)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
