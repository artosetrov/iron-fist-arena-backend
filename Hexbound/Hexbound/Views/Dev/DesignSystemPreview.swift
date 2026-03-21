#if DEBUG
import SwiftUI

// MARK: - Design System Preview

/// Visual catalog of all design tokens, components, and styles.
/// Access via Screen Catalog → "Design System" section.
struct DesignSystemPreview: View {
    @State private var expandedSection: String?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutConstants.spaceLG) {
                    colorPaletteSection
                    backdropColorsSection
                    borderColorsSection
                    feedbackColorsSection
                    textColorsSection
                    rarityColorsSection
                    statColorsSection
                    toastColorsSection
                    typographySection
                    spacingSection
                    buttonStylesSection
                    damageTypeBadgesSection
                    statusEffectBadgesSection
                }
                .padding(.horizontal, LayoutConstants.screenPadding)
                .padding(.vertical, LayoutConstants.spaceMD)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DESIGN SYSTEM")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }

    // MARK: - Color Palette

    private var colorPaletteSection: some View {
        dsSection("Background & Surface") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                colorSwatch("bgAbyss", DarkFantasyTheme.bgAbyss)
                colorSwatch("bgPrimary", DarkFantasyTheme.bgPrimary)
                colorSwatch("bgSecondary", DarkFantasyTheme.bgSecondary)
                colorSwatch("bgTertiary", DarkFantasyTheme.bgTertiary)
                colorSwatch("bgElevated", DarkFantasyTheme.bgElevated)
                colorSwatch("bgDarkPanel", DarkFantasyTheme.bgDarkPanel)
            }
        }
    }

    private var backdropColorsSection: some View {
        dsSection("Backdrop & Overlay") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                colorSwatch("bgModal", DarkFantasyTheme.bgModal)
                colorSwatch("bgBackdrop", DarkFantasyTheme.bgBackdrop)
                colorSwatch("bgBackdropLight", DarkFantasyTheme.bgBackdropLight)
                colorSwatch("bgScrim", DarkFantasyTheme.bgScrim)
                colorSwatch("bgDarkPanel", DarkFantasyTheme.bgDarkPanel)
            }
        }
    }

    private var borderColorsSection: some View {
        dsSection("Border & Frame") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                colorSwatch("borderSubtle", DarkFantasyTheme.borderSubtle)
                colorSwatch("borderMedium", DarkFantasyTheme.borderMedium)
                colorSwatch("borderStrong", DarkFantasyTheme.borderStrong)
                colorSwatch("borderGold", DarkFantasyTheme.borderGold)
                colorSwatch("borderOrnament", DarkFantasyTheme.borderOrnament)
            }
        }
    }

    private var feedbackColorsSection: some View {
        dsSection("Feedback & Accent") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                colorSwatch("gold", DarkFantasyTheme.gold)
                colorSwatch("goldBright", DarkFantasyTheme.goldBright)
                colorSwatch("goldDim", DarkFantasyTheme.goldDim)
                colorSwatch("danger", DarkFantasyTheme.danger)
                colorSwatch("success", DarkFantasyTheme.success)
                colorSwatch("info", DarkFantasyTheme.info)
                colorSwatch("cyan", DarkFantasyTheme.cyan)
                colorSwatch("purple", DarkFantasyTheme.purple)
                colorSwatch("stamina", DarkFantasyTheme.stamina)
            }
        }
    }

    private var textColorsSection: some View {
        dsSection("Text Colors") {
            VStack(alignment: .leading, spacing: 6) {
                textSample("textPrimary — Main body text", DarkFantasyTheme.textPrimary)
                textSample("textSecondary — Labels, subtitles", DarkFantasyTheme.textSecondary)
                textSample("textTertiary — Hints, placeholders", DarkFantasyTheme.textTertiary)
                textSample("textDisabled — Disabled states", DarkFantasyTheme.textDisabled)
                textSample("textGold — Currency values", DarkFantasyTheme.textGold)
                textSample("textDanger — Error messages", DarkFantasyTheme.textDanger)
                textSample("textSuccess — Positive changes", DarkFantasyTheme.textSuccess)
            }
        }
    }

    private var rarityColorsSection: some View {
        dsSection("Rarity Colors") {
            HStack(spacing: 8) {
                ForEach([ItemRarity.common, .uncommon, .rare, .epic, .legendary], id: \.self) { rarity in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(DarkFantasyTheme.rarityColor(for: rarity), lineWidth: 2)
                            )
                            .shadow(color: DarkFantasyTheme.rarityGlow(for: rarity), radius: 6)
                        Text(rarity.rawValue.capitalized)
                            .font(DarkFantasyTheme.body(size: 9))
                            .foregroundStyle(DarkFantasyTheme.rarityColor(for: rarity))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var statColorsSection: some View {
        dsSection("Stat Colors") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                colorSwatch("STR", DarkFantasyTheme.statSTR)
                colorSwatch("AGI", DarkFantasyTheme.statAGI)
                colorSwatch("VIT", DarkFantasyTheme.statVIT)
                colorSwatch("END", DarkFantasyTheme.statEND)
                colorSwatch("INT", DarkFantasyTheme.statINT)
                colorSwatch("WIS", DarkFantasyTheme.statWIS)
                colorSwatch("LUK", DarkFantasyTheme.statLUK)
                colorSwatch("CHA", DarkFantasyTheme.statCHA)
            }
        }
    }

    private var toastColorsSection: some View {
        dsSection("Toast Indicator Colors") {
            HStack(spacing: 8) {
                toastDot("Achievement", DarkFantasyTheme.toastAchievement)
                toastDot("Level Up", DarkFantasyTheme.toastLevelUp)
                toastDot("Rank Up", DarkFantasyTheme.toastRankUp)
                toastDot("Quest", DarkFantasyTheme.toastQuest)
                toastDot("Reward", DarkFantasyTheme.toastReward)
                toastDot("Info", DarkFantasyTheme.toastInfo)
                toastDot("Error", DarkFantasyTheme.toastError)
            }
        }
    }

    // MARK: - Typography

    private var typographySection: some View {
        dsSection("Typography") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cinematic Title (Oswald 40)")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text("Title (Oswald 28)")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Section (Oswald 22)")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Card Title (Oswald 18)")
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Body — The quick brown fox jumps over the lazy dog")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                Text("Caption — Secondary information")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
        }
    }

    // MARK: - Spacing

    private var spacingSection: some View {
        dsSection("Spacing Scale") {
            VStack(alignment: .leading, spacing: 4) {
                spacingBar("2XS = 2", LayoutConstants.space2XS)
                spacingBar("XS = 4", LayoutConstants.spaceXS)
                spacingBar("SM = 8", LayoutConstants.spaceSM)
                spacingBar("MS = 12", LayoutConstants.spaceMS)
                spacingBar("MD = 16", LayoutConstants.spaceMD)
                spacingBar("LG = 24", LayoutConstants.spaceLG)
                spacingBar("XL = 32", LayoutConstants.spaceXL)
                spacingBar("2XL = 48", LayoutConstants.space2XL)
            }
        }
    }

    // MARK: - Button Styles

    private var buttonStylesSection: some View {
        dsSection("Button Styles") {
            VStack(spacing: 12) {
                Button("PRIMARY — Gold CTA") {}
                    .buttonStyle(.primary)

                Button("SECONDARY — Outlined") {}
                    .buttonStyle(.secondary)

                Button("DANGER — Destructive") {}
                    .buttonStyle(.danger)

                Button("Ghost — Text Only") {}
                    .buttonStyle(.ghost)

                Button("NAV GRID — Hub Tile") {}
                    .buttonStyle(.navGrid)

                Button("FIGHT — Combat CTA") {}
                    .buttonStyle(.fight)

                HStack(spacing: 8) {
                    Button("1X") {}
                        .buttonStyle(.combatToggle(isActive: true))
                    Button("2X") {}
                        .buttonStyle(.combatToggle(isActive: false))
                    Button("SKIP") {}
                        .buttonStyle(.combatControl)
                    Button {
                    } label: {
                        Image(systemName: "flag.fill").font(.system(size: 14))
                    }
                    .buttonStyle(.combatForfeit)
                }

                HStack(spacing: 12) {
                    Button { } label: { Image(systemName: "xmark") }
                        .buttonStyle(.closeButton)
                    Text("closeButton").font(DarkFantasyTheme.body(size: 10)).foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Button("G") {}
                        .buttonStyle(.socialAuth)
                        .frame(width: 80)
                    Text("socialAuth").font(DarkFantasyTheme.body(size: 10)).foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                HStack(spacing: 8) {
                    Button("$4.99") {}
                        .buttonStyle(.compactPrimary)
                        .frame(width: 72, height: 40)
                    Text("compactPrimary").font(DarkFantasyTheme.body(size: 10)).foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Button("REVENGE") {}
                        .buttonStyle(.dangerCompact)
                    Text("dangerCompact").font(DarkFantasyTheme.body(size: 10)).foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                HStack(spacing: 8) {
                    Button("50") {}
                        .buttonStyle(.colorToggle(isActive: true))
                    Button("100") {}
                        .buttonStyle(.colorToggle(isActive: false))
                    Text("colorToggle").font(DarkFantasyTheme.body(size: 10)).foregroundStyle(DarkFantasyTheme.textTertiary)
                }

                Button("ScalePress — Card tap") {}
                    .buttonStyle(.scalePress(0.96))
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(LayoutConstants.cardPadding)
                    .background(DarkFantasyTheme.bgTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            }
        }
    }

    // MARK: - Damage Type Badges

    private var damageTypeBadgesSection: some View {
        dsSection("Damage Type Badges") {
            HStack(spacing: 8) {
                ForEach([DamageTypeStyle.physical, .magical, .poison, .trueDamage, .unknown], id: \.label) { style in
                    HStack(spacing: 2) {
                        Image(systemName: style.icon)
                            .font(.system(size: 7))
                        Text(style.label)
                            .font(DarkFantasyTheme.body(size: 8).bold())
                    }
                    .foregroundStyle(.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(style.color.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
        }
    }

    // MARK: - Status Effect Badges

    private var statusEffectBadgesSection: some View {
        dsSection("Status Effect Badges") {
            HStack(spacing: 8) {
                ForEach(["Bleed", "Burn", "Stun", "Poison", "Freeze"], id: \.self) { name in
                    let effect = StatusEffect(name: name)
                    HStack(spacing: 3) {
                        Image(systemName: effect.icon)
                            .font(.system(size: 8))
                        Text(effect.abbreviation)
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                    }
                    .foregroundStyle(.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(effect.color.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    // MARK: - Helpers

    private func dsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            Text(title.uppercased())
                .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.gold)

            content()
        }
        .padding(LayoutConstants.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
    }

    private func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                )
            Text(name)
                .font(DarkFantasyTheme.body(size: 9))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
        }
    }

    private func textSample(_ label: String, _ color: Color) -> some View {
        Text(label)
            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
            .foregroundStyle(color)
    }

    private func toastDot(_ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(DarkFantasyTheme.body(size: 8))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
        }
    }

    private func spacingBar(_ label: String, _ width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(DarkFantasyTheme.body(size: 10))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .frame(width: 80, alignment: .leading)
            RoundedRectangle(cornerRadius: 2)
                .fill(DarkFantasyTheme.gold.opacity(0.6))
                .frame(width: width * 3, height: 8)
        }
    }
}
#endif
