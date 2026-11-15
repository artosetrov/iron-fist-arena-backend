import SwiftUI

// MARK: - Framed portrait

/// A hero's portrait inside the hero-card frame of their level — the gate
/// deck's frames (`HeroCardTier`, `card-frame-N`): oak and iron below 10,
/// bronze, runed silver, ruby gold, obsidian at 40+. The level sits on the
/// frame's socket; an optional status light burns in the window's corner.
struct HeroFramedPortrait: View {
    let level: Int
    let avatar: String?
    let characterClass: CharacterClass
    var showsLevel: Bool = true
    var statusColor: Color? = nil

    /// Width / height of the frame art (300 × 402 pt).
    static let aspect: CGFloat = 300.0 / 402.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let tier = HeroCardTier(level: level)
            let g = tier.geometry
            let win = CGRect(
                x: g.windowL * w,
                y: g.windowT * h,
                width: (g.windowR - g.windowL) * w,
                height: (g.windowB - g.windowT) * h
            )
            let classColor = DarkFantasyTheme.classColor(for: characterClass)
            let socket = max(24, g.socketR * 2 * w + 6)

            ZStack(alignment: .topLeading) {
                // Card body under the window, a little larger so no seam shows.
                Rectangle()
                    .fill(DarkFantasyTheme.bgSecondary)
                    .frame(width: win.width + w * 0.04, height: win.height + w * 0.04)
                    .offset(x: win.minX - w * 0.02, y: win.minY - w * 0.02)

                AvatarImageView(skinKey: avatar, characterClass: characterClass, size: win.height)
                    .frame(width: win.width, height: win.height)
                    .clipped()
                    .background(
                        RadialGradient(
                            colors: [classColor.opacity(0.45), DarkFantasyTheme.bgAbyss],
                            center: .center,
                            startRadius: 0,
                            endRadius: win.height * 0.7
                        )
                    )
                    .offset(x: win.minX, y: win.minY)

                Image(tier.asset)
                    .resizable()
                    .frame(width: w, height: h)

                if showsLevel {
                    Text("\(level)")
                        .font(DarkFantasyTheme.buttonLabelCompact)
                        .monospacedDigit()
                        .foregroundStyle(tier.levelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: socket, height: socket)
                        .background(Circle().fill(DarkFantasyTheme.bgAbyss))
                        .overlay(Circle().stroke(DarkFantasyTheme.goldDim, lineWidth: 1.5))
                        .offset(x: g.socketX * w - socket / 2, y: g.socketY * h - socket / 2)
                }

                if let statusColor {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(DarkFantasyTheme.bgAbyss, lineWidth: 2))
                        .shadow(color: statusColor.opacity(0.8), radius: 5)
                        .offset(x: win.maxX - 12 - LayoutConstants.spaceXS, y: win.minY + LayoutConstants.spaceXS)
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// MARK: - Ally card

/// An ally as a small hero card: framed portrait, status light, class crest
/// at the foot, name and when they were last seen.
struct AllyHeroCard: View {
    let friend: FriendEntry

    private var statusColor: Color {
        switch friend.onlineStatus {
        case .online: DarkFantasyTheme.success
        case .away: DarkFantasyTheme.stamina
        case .offline: DarkFantasyTheme.textTertiary
        }
    }

    private var statusText: String {
        switch friend.onlineStatus {
        case .online: "Online"
        case .away: "Away"
        case .offline: friend.lastSeenText ?? "Offline"
        }
    }

    var body: some View {
        VStack(spacing: LayoutConstants.space2XS) {
            HeroFramedPortrait(
                level: friend.level,
                avatar: friend.avatar,
                characterClass: friend.classEnum,
                statusColor: statusColor
            )
            .overlay(alignment: .bottom) {
                Image(friend.classEnum.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 3, y: 2)
                    .offset(y: 10)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, LayoutConstants.spaceXS)

            Text(friend.characterName)
                .font(DarkFantasyTheme.buttonLabelCompact)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(statusText)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(friend.onlineStatus == .offline ? DarkFantasyTheme.textTertiaryAA : statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(friend.characterName), level \(friend.level) \(friend.classEnum.displayName), \(statusText)")
    }
}

// MARK: - Letters

/// A conversation as a letter on parchment, closed with a wax seal pressed
/// with the sender's class crest: unbroken and warm while there is something
/// unread, cracked once read.
struct GuildLetterRow: View {
    let name: String
    let characterClass: CharacterClass
    let line: String
    let when: String
    let unread: Int
    var tilt: Double = 0

    var body: some View {
        HStack(spacing: LayoutConstants.spaceMS) {
            GuildWaxSeal(crest: characterClass.iconAsset, isBroken: unread == 0, count: unread)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: LayoutConstants.spaceSM) {
                    Text(name)
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.parchmentInk)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(when)
                        .font(DarkFantasyTheme.tale)
                        .foregroundStyle(DarkFantasyTheme.parchmentInkSoft)
                        .lineLimit(1)
                }
                Text(line)
                    .font(DarkFantasyTheme.tale)
                    .foregroundStyle(unread > 0 ? DarkFantasyTheme.parchmentInk : DarkFantasyTheme.parchmentInkSoft)
                    .lineLimit(1)
            }
        }
        .padding(.leading, LayoutConstants.spaceSM)
        .padding(.trailing, LayoutConstants.spaceMD)
        .frame(maxWidth: .infinity, minHeight: 82)
        .background {
            Image("rush2-map-parchment")
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                .stroke(DarkFantasyTheme.parchmentInkSoft.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: unread > 0 ? DarkFantasyTheme.goldGlow.opacity(0.35) : .clear, radius: 8)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 6, y: 4)
        .rotationEffect(.degrees(tilt))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(unread > 0
            ? "Unopened scroll from \(name), \(when): \(line)"
            : "Scroll from \(name), \(when): \(line)")
    }
}

/// `rush2-map-seal` with a class crest pressed into the wax.
struct GuildWaxSeal: View {
    let crest: String
    let isBroken: Bool
    var count: Int = 0

    var body: some View {
        ZStack {
            Image("rush2-map-seal")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .grayscale(isBroken ? 0.55 : 0)
                .shadow(color: isBroken ? .clear : DarkFantasyTheme.goldGlow.opacity(0.7), radius: 6)

            Image(crest)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .grayscale(1)
                .colorMultiply(DarkFantasyTheme.btnDangerStroke)
                .opacity(0.75)

            if isBroken {
                GuildSealCrack()
                    .stroke(
                        DarkFantasyTheme.parchmentPaper,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .frame(width: 56, height: 56)
        .overlay(alignment: .topTrailing) {
            if count > 0 {
                Text("\(count)")
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .monospacedDigit()
                    .foregroundStyle(DarkFantasyTheme.textOnGold)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Capsule().fill(DarkFantasyTheme.goldBright))
                    .overlay(Capsule().stroke(DarkFantasyTheme.parchmentInk, lineWidth: 1.5))
                    .offset(x: 6, y: -6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The crack across a broken seal.
struct GuildSealCrack: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: p(0.52, 0.11))
        path.addLine(to: p(0.43, 0.38))
        path.addLine(to: p(0.57, 0.50))
        path.addLine(to: p(0.45, 0.71))
        path.addLine(to: p(0.54, 0.91))
        return path
    }
}
