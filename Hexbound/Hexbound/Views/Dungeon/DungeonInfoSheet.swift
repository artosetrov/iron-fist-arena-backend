import SwiftUI

/// Redesigned dungeon detail sheet: portrait header, boss progress, rewards,
/// dungeon stats, lore, and full boss list with gold-checkmark states.
struct DungeonInfoSheet: View {

    let dungeon: DungeonInfo
    var defeatedCount: Int = 0
    /// Optional enter callback. When non-nil the sticky "ENTER DUNGEON" CTA is shown.
    var onEnter: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    // MARK: - Derived

    private var currentStamina: Int { appState.currentCharacter?.currentStamina ?? 0 }
    private var themeColor: Color { dungeon.themeColor }
    private var totalBosses: Int { dungeon.totalBosses }
    private var progressFraction: Double {
        totalBosses > 0 ? Double(defeatedCount) / Double(totalBosses) : 0
    }
    /// Loot previews shared by all bosses in this dungeon.
    private var dungeonLoot: [LootPreview] { dungeon.bosses.first?.loot ?? [] }

    // MARK: - Body

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgDungeonGradient
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Portrait ──────────────────────────────────
                    portraitSection

                    VStack(alignment: .leading, spacing: 0) {

                        // ── Boss progress ─────────────────────────
                        progressSection
                            .padding(.top, LayoutConstants.spaceMD)

                        // ── Rewards ───────────────────────────────
                        GoldDivider()
                            .padding(.vertical, LayoutConstants.spaceMD)
                        rewardsSection

                        // ── Dungeon stats ─────────────────────────
                        GoldDivider()
                            .padding(.vertical, LayoutConstants.spaceMD)
                        statsSection

                        // ── Lore ──────────────────────────────────
                        GoldDivider()
                            .padding(.vertical, LayoutConstants.spaceMD)
                        loreSection

                        // Boss list removed — already shown on main dungeon page (FIX #6)

                        Spacer(minLength: onEnter != nil ? 120 : 40)
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .safeAreaInset(edge: .bottom) {
            if onEnter != nil { enterCTA }
        }
        // Boss detail sheet removed — boss list is on main dungeon page (FIX #6)
    }

    // MARK: - Portrait Header

    @ViewBuilder
    private var portraitSection: some View {
        ZStack(alignment: .bottomLeading) {

            // Art: gradient + radial glow + big emoji
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeColor.opacity(0.28),
                                DarkFantasyTheme.bgAbyss.opacity(0.92),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Radial glow (uses circle path, not RadialGlowBackground)
                RadialGradient(
                    gradient: Gradient(colors: [themeColor.opacity(0.20), .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )

                AssetPlaceholderView(systemIcon: "map.fill")
                    .frame(width: 88, height: 88)
                    .opacity(0.30)
                    .offset(y: -8)
            }
            .frame(height: 200)
            .clipped()
            // Bottom scrim for title overlay
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 90)
            }
            // Ornamental frame
            .cornerBrackets(color: themeColor.opacity(0.45), length: 18, thickness: 1.5)
            .cornerDiamonds(color: themeColor.opacity(0.40), size: 6)
            // Close button
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.caption.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(DarkFantasyTheme.bgAbyss.opacity(0.72))
                                .overlay(Circle().stroke(DarkFantasyTheme.borderMedium, lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .padding(LayoutConstants.spaceMS)
            }

            // Title + meta chips
            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text(dungeon.name.uppercased())
                    .font(DarkFantasyTheme.title(size: 28))
                    .foregroundStyle(themeColor)
                    .tracking(2)
                    .shadow(color: themeColor.opacity(0.45), radius: 10)
                    .shadow(color: DarkFantasyTheme.bgAbyss, radius: 3)

                HStack(spacing: LayoutConstants.spaceSM) {
                    metaChip(icon: "arrow.up.right",
                             text: "Lv. \(dungeon.minLevel)–\(dungeon.maxLevel)",
                             color: themeColor)
                    metaChip(icon: "bolt.fill",
                             text: "\(dungeon.energyCost) Energy",
                             color: DarkFantasyTheme.stamina)
                    metaChip(icon: "person.3.fill",
                             text: "\(dungeon.totalBosses) Bosses",
                             color: DarkFantasyTheme.textSecondary)
                }
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.bottom, LayoutConstants.spaceMS)
        }
    }

    private func metaChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.badge.weight(.semibold))
            Text(text)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceXS)
        .background(
            Capsule()
                .fill(DarkFantasyTheme.bgAbyss.opacity(0.68))
                .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 1))
        )
    }

    // MARK: - Progress

    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            HStack {
                Text("PROGRESS")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .tracking(1.5)
                Spacer()
                Text("\(defeatedCount) / \(totalBosses) Bosses")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.gold)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
                        )

                    // Fill
                    if progressFraction > 0 {
                        RoundedRectangle(cornerRadius: LayoutConstants.heroBarRadius)
                            .fill(
                                progressFraction >= 1.0
                                    ? LinearGradient(
                                        colors: [DarkFantasyTheme.goldDim, DarkFantasyTheme.gold, DarkFantasyTheme.goldBright],
                                        startPoint: .leading, endPoint: .trailing)
                                    : DarkFantasyTheme.progressGradient
                            )
                            .frame(width: geo.size.width * progressFraction)
                            .overlay(BarFillHighlight(cornerRadius: LayoutConstants.heroBarRadius))
                            .animation(.easeOut(duration: 0.5), value: defeatedCount)
                    }
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Rewards

    @ViewBuilder
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            sectionHeader(label: "REWARDS")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    ForEach(dungeonLoot.prefix(6)) { loot in
                        rewardTile(loot)
                    }
                }
                .padding(.horizontal, 2) // prevent shadow clipping
            }
        }
    }

    @ViewBuilder
    private func rewardTile(_ loot: LootPreview) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            ZStack {
                // Rarity-tinted background
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(
                        LinearGradient(
                            colors: [
                                loot.rarity.color.opacity(0.18),
                                DarkFantasyTheme.bgSecondary,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Asset or emoji
                if let key = loot.resolvedImageKey, UIImage(named: key) != nil {
                    Image(key)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                } else {
                    AssetPlaceholderView(systemIcon: "cube.fill")
                        .frame(width: 26, height: 26)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(loot.rarity.color.opacity(0.55), lineWidth: 1.5)
            )
            .shadow(color: loot.rarity.color.opacity(0.22), radius: 6)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 3, y: 2)

            Text(loot.name)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 56)
        }
    }

    // MARK: - Stats Grid

    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            sectionHeader(label: "DUNGEON INFO")

            HStack(spacing: LayoutConstants.spaceSM) {
                statTile(
                    value: "Lv. \(dungeon.minLevel)–\(dungeon.maxLevel)",
                    label: "Level",
                    icon: "arrow.up.right",
                    color: themeColor
                )
                statTile(
                    value: "\(dungeon.energyCost)",
                    label: "Energy",
                    icon: "bolt.fill",
                    color: DarkFantasyTheme.stamina
                )
                statTile(
                    value: "\(dungeon.totalBosses)",
                    label: "Bosses",
                    icon: "person.3.fill",
                    color: DarkFantasyTheme.textSecondary
                )
            }
        }
    }

    @ViewBuilder
    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Image(systemName: icon)
                .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                .foregroundStyle(color)

            Text(value)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LayoutConstants.spaceMS)
        .padding(.horizontal, LayoutConstants.spaceXS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.3,
                cornerRadius: LayoutConstants.radiusMD
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.radiusMD, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.radiusMD - 2,
            inset: 2,
            color: color.opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
        .cornerBrackets(color: color.opacity(0.25), length: 8, thickness: 1)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Lore

    @ViewBuilder
    private var loreSection: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            sectionHeader(label: "LORE")

            VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
                Text(dungeon.description)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption).italic())
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineSpacing(4)

                Text(extendedLore)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .lineSpacing(4)
            }
            .padding(LayoutConstants.cardPadding)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: themeColor.opacity(0.07),
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.radiusMD
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.radiusMD, topHighlight: 0.05, bottomShadow: 0.08)
            .innerBorder(
                cornerRadius: LayoutConstants.radiusMD - 2,
                inset: 2,
                color: themeColor.opacity(0.07)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(themeColor.opacity(0.14), lineWidth: 1)
            )
            .cornerBrackets(color: themeColor.opacity(0.22), length: 10, thickness: 1)
            .compositingGroup()
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
        }
    }

    // Boss list removed — FIX #6: bosses are shown on the main dungeon page, not here

    // MARK: - Enter CTA (sticky bottom)

    @ViewBuilder
    private var enterCTA: some View {
        HStack(spacing: LayoutConstants.spaceSM) {

            // Energy badge
            VStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "bolt.fill")
                    .font(DarkFantasyTheme.body.bold())
                    .foregroundStyle(DarkFantasyTheme.stamina)
                Text("\(dungeon.energyCost)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.stamina)
                Text("Energy")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                    .foregroundStyle(DarkFantasyTheme.stamina.opacity(0.60))
            }
            .frame(width: 64)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.stamina.opacity(0.08),
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.radiusMD
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.radiusMD, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(
                cornerRadius: LayoutConstants.radiusMD - 2,
                inset: 2,
                color: DarkFantasyTheme.stamina.opacity(0.08)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .stroke(DarkFantasyTheme.stamina.opacity(0.30), lineWidth: 1)
            )
            .cornerBrackets(color: DarkFantasyTheme.stamina.opacity(0.25), length: 8, thickness: 1)
            .compositingGroup()

            // Primary CTA
            Button {
                HapticManager.medium()
                dismiss()
                onEnter?()
            } label: {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "figure.fencing")
                        .font(DarkFantasyTheme.body.weight(.semibold))
                    Text("ENTER DUNGEON")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                }
            }
            .buttonStyle(.primary)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceSM)
        .background(
            LinearGradient(
                colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Section Header (theme-coloured diamond motif)

    private func sectionHeader(label: String) -> some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, themeColor.opacity(0.35)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: LayoutConstants.spaceXS) {
                diamondMotif
                Text(label)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                    .foregroundStyle(themeColor)
                    .tracking(2)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                diamondMotif
            }
            .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.35), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    private var diamondMotif: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(themeColor)
                .frame(width: 5, height: 5)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(themeColor.opacity(0.40))
                .frame(width: 3, height: 3)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(themeColor)
                .frame(width: 5, height: 5)
                .rotationEffect(.degrees(45))
        }
    }

    // MARK: - Extended Lore

    private var extendedLore: String {
        switch dungeon.id {
        case "training_camp":
            return "Generations of warriors have trained here, their sweat and blood seeping into the very stones. The arena's current master, the Arena Warden, tests all who seek to prove themselves worthy of entering the deeper dungeons. Only those who conquer all ten trials may advance to face the true horrors that await below."
        case "desecrated_catacombs":
            return "The catacombs were once a sacred burial ground for the noble houses of the old kingdom. When the Lich King Verath rose from death, he corrupted the sacred wards and turned the dead against the living. Now the tunnels writhe with restless spirits and undead horrors, all serving the will of their skeletal overlord."
        case "volcanic_forge":
            return "Long ago, the dwarven smiths of the Molten Clan built their greatest forge within the heart of an active volcano. When the mountain erupted, the forge absorbed the primal fire, creating a self-sustaining inferno. The creatures within have been tempered by millennia of heat, making them nearly indestructible. At its core, Pyrox the Eternal burns with the fury of creation itself."
        default:
            return "A dangerous place filled with powerful enemies and valuable treasure."
        }
    }
}
