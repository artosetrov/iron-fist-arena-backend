import SwiftUI

/// Hero Integrated Card: equipment-first layout with arena-style portrait,
/// HP bar below, action pills — mirrors the premium ArenaOpponentCard feel.
@MainActor
struct HeroIntegratedCard: View {
    let character: Character
    let equippedItems: [Item]

    var onTapPortrait: (() -> Void)? = nil
    var onTapSlot: ((Item) -> Void)? = nil
    var onUseHealthPotion: (() -> Void)? = nil
    var onRefillStamina: (() -> Void)? = nil

    @Environment(AppState.self) private var appState

    // Portrait animation state
    @State private var glowPhase: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -1.2

    // MARK: - Computed

    private var healthPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items.filter { $0.consumableType?.contains("health_potion") == true }.reduce(0) { $0 + ($1.quantity ?? 0) }
    }


    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // ═══ EQUIPMENT GRID ═══
            equipmentGrid
                .padding(.horizontal, LayoutConstants.spaceMS)
                .padding(.top, LayoutConstants.heroCardPadding)
                .padding(.bottom, LayoutConstants.spaceLG)

            // ═══ DIVIDER ═══
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.borderSubtle, .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, LayoutConstants.heroCardPadding)

            // ═══ DATA BELOW ═══
            dataSection
                .padding(LayoutConstants.heroCardPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius)
                .fill(DarkFantasyTheme.bgCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius)
                .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroCardRadius))
    }

    // MARK: - Equipment Grid (GeometryReader for precise layout)

    /// Aspect ratio for the equipment grid (width / height)
    private var aspectRatioForGrid: CGFloat {
        let refW: CGFloat = 400
        let slotGap = LayoutConstants.heroSlotGap
        let cw = (refW - 3 * slotGap) / 4
        let height = 3 * cw + 2 * slotGap + slotGap + cw
        return refW / height
    }

    private func gridCellWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - 3 * LayoutConstants.heroSlotGap) / 4
    }

    private var equipmentGrid: some View {
        GeometryReader { geo in
            let containerW = geo.size.width
            let slotGap = LayoutConstants.heroSlotGap
            let cw = gridCellWidth(in: containerW)
            // Portrait = exactly 2 cells + 1 gap (centered in grid)
            let portraitW = 2 * cw + slotGap
            let portraitH = 3 * cw + 2 * slotGap

            VStack(spacing: slotGap) {
                // Top: 3 left | portrait (2-col) | 3 right
                HStack(alignment: .top, spacing: slotGap) {
                    VStack(spacing: slotGap) {
                        equipSlot("helmet", size: cw)
                        equipSlot("chest", size: cw)
                        equipSlot("legs", size: cw)
                    }
                    .frame(width: cw)

                    heroPortrait()
                        .frame(width: portraitW, height: portraitH)

                    VStack(spacing: slotGap) {
                        equipSlot("amulet", size: cw)
                        equipSlot("gloves", size: cw)
                        equipSlot("boots", size: cw)
                    }
                    .frame(width: cw)
                }

                // Bottom: Ring, Weapon, Relic, Belt
                HStack(spacing: slotGap) {
                    equipSlot("ring", size: cw, index: 0)
                    equipSlot("weapon", size: cw)
                    equipSlot("relic", size: cw)
                    equipSlot("belt", size: cw)
                }
            }
        }
        .aspectRatio(aspectRatioForGrid, contentMode: .fit)
    }

    // MARK: - Data Section (below divider)

    private var dataSection: some View {
        HPBarView(
            currentHp: character.currentHp,
            maxHp: character.maxHp,
            size: .large,
            label: "HP"
        )
    }

    // MARK: - Hero Portrait (Arena-style full-bleed)

    @ViewBuilder
    private func heroPortrait() -> some View {
        ZStack {
            // 1. Full-bleed avatar background
            AvatarImageView(
                skinKey: character.avatar,
                characterClass: character.characterClass,
                size: 200
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            // 2. Vignette: top tint + radial + bottom fade
            portraitVignette

            // 3. Overlaid info content
            VStack(spacing: 0) {
                // Top row: class icon badge (left) + level badge (right)
                HStack(alignment: .top) {
                    Image(character.characterClass.iconAsset)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: LayoutConstants.iconSM, height: LayoutConstants.iconSM)
                        .padding(LayoutConstants.spaceXS)
                        .background(Circle().fill(DarkFantasyTheme.bgAbyss.opacity(0.65)))
                        .overlay(
                            Circle().stroke(DarkFantasyTheme.gold.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 2, y: 1)

                    Spacer()

                    CardLevelBadge(level: character.level, accentColor: DarkFantasyTheme.gold)
                }

                Spacer()

                // Bottom: name + class tag + XP bar
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(character.characterName)
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .lineLimit(1)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 6, y: 2)

                    ClassTagView(characterClass: character.characterClass)

                    // XP label
                    Text("XP \(character.experience ?? 0)/\(character.xpNeeded)")
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.xpRing)
                        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.8), radius: 3)

                    // XP thin progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(DarkFantasyTheme.xpRingTrack)
                                .frame(height: 3)
                            Capsule()
                                .fill(DarkFantasyTheme.xpRing)
                                .frame(width: geo.size.width * character.xpPercentage, height: 3)
                                .shadow(color: DarkFantasyTheme.xpRing.opacity(0.5), radius: 3)
                                .animation(.easeInOut(duration: 1.0), value: character.xpPercentage)
                        }
                    }
                    .frame(height: 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(LayoutConstants.spaceSM)

            // 4. Animated angular glow border + corner ornaments
            portraitGlowBorder

            // 5. Shimmer sweep
            RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                .fill(
                    LinearGradient(
                        colors: [.clear, DarkFantasyTheme.arenaShimmerColor, .clear],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0.3),
                        endPoint: UnitPoint(x: shimmerOffset + 0.4, y: 0.7)
                    )
                )
                .allowsHitTesting(false)

            // 6. Low HP danger pulse ring
            RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
                .stroke(DarkFantasyTheme.danger, lineWidth: 2)
                .opacity(character.hpPercentage < 0.25 ? 0.8 : 0)
                .glowPulse(color: DarkFantasyTheme.danger, intensity: 0.5, isActive: character.hpPercentage < 0.25)
        }
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius))
        .contentShape(Rectangle())
        .onAppear { startPortraitAnimations() }
        .onDisappear { stopPortraitAnimations() }
        .onTapGesture { onTapPortrait?() }
    }

    // MARK: - Portrait Vignette

    private var portraitVignette: some View {
        ZStack {
            // Top dark tint (softens avatar top)
            LinearGradient(
                colors: [DarkFantasyTheme.bgAbyss.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.35)
            )

            // Radial edge darkening
            RadialGradient(
                gradient: Gradient(colors: [.clear, DarkFantasyTheme.bgAbyss.opacity(0.45)]),
                center: .init(x: 0.5, y: 0.3),
                startRadius: 40,
                endRadius: 130
            )

            // Bottom strong fade for text readability
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        .clear,
                        DarkFantasyTheme.bgAbyss.opacity(0.5),
                        DarkFantasyTheme.bgAbyss.opacity(0.85),
                        DarkFantasyTheme.bgAbyss
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
        }
    }

    // MARK: - Animated Glow Border

    private var portraitGlowBorder: some View {
        RoundedRectangle(cornerRadius: LayoutConstants.heroSlotRadius)
            .stroke(
                AngularGradient(
                    colors: [
                        DarkFantasyTheme.gold.opacity(0.55),
                        DarkFantasyTheme.xpRing.opacity(0.2),
                        DarkFantasyTheme.gold.opacity(0.35),
                        DarkFantasyTheme.xpRing.opacity(0.15),
                        DarkFantasyTheme.gold.opacity(0.55)
                    ],
                    center: .center,
                    startAngle: .degrees(glowPhase),
                    endAngle: .degrees(glowPhase + 360)
                ),
                lineWidth: 1.5
            )
            .overlay(
                CornerBracketOverlay(
                    color: DarkFantasyTheme.gold.opacity(0.5),
                    length: 14,
                    thickness: 1.5
                )
            )
            .overlay(
                CornerDiamondOverlay(
                    color: DarkFantasyTheme.gold.opacity(0.4),
                    size: 5
                )
            )
    }

    // MARK: - Portrait Animations

    private func startPortraitAnimations() {
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            glowPhase = 360
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            shimmerOffset = 1.5
        }
    }

    private func stopPortraitAnimations() {
        glowPhase = 0
        shimmerOffset = -1.2
    }

    // MARK: - Equipment Slot

    private func findEquippedItem(slot: String, index: Int = 0) -> Item? {
        let accepted = EquipmentViewModel.slotAccepts[slot] ?? [slot]
        switch slot {
        case "ring":
            let rings = equippedItems.filter { $0.equippedSlot == "ring" || $0.equippedSlot == "ring2" || ($0.equippedSlot == nil && $0.itemType == .ring) }
            return index < rings.count ? rings[index] : nil
        default:
            return equippedItems.first { item in
                if item.equippedSlot == slot { return true }
                return accepted.contains(item.itemType.rawValue) && (item.equippedSlot == slot || item.equippedSlot == nil)
            }
        }
    }

    @ViewBuilder
    private func equipSlot(_ slot: String, size: CGFloat, index: Int = 0) -> some View {
        let item = findEquippedItem(slot: slot, index: index)
        let slotAsset = EquipmentViewModel.slotAssets[slot]

        if let item {
            ItemCardView(
                item: item,
                context: .equipment(slotAsset: slotAsset)
            ) {
                onTapSlot?(item)
            }
            .frame(width: size, height: size)
        } else {
            ItemCardView(
                rarity: .common,
                imageKey: nil,
                imageUrl: nil,
                fallbackIcon: "",
                context: .equipment(slotAsset: slotAsset)
            ) { }
            .frame(width: size, height: size)
        }
    }
}
