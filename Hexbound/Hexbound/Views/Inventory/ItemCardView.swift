import SwiftUI

// MARK: - Item Card Context

/// Defines what additional overlays/behavior ItemCardView shows per screen.
enum ItemCardContext {
    /// Inventory grid — comparison arrows, equipped badge, quantity, durability
    case inventory(equippedItem: Item?)
    /// Shop grid — price bar at bottom, affordability/level dimming, buying spinner
    /// originalPrice + discountPct are optional (nil = no sale)
    case shop(price: Int, isGem: Bool, canAfford: Bool, meetsLevel: Bool, isBuying: Bool, originalPrice: Int? = nil, discountPct: Int? = nil)
    /// Hero equipment grid — empty slot placeholder, broken indicator
    case equipment(slotAsset: String?)
    /// Loot reveal in battle result — minimal (no functional overlays)
    case loot
    /// Preview in detail sheets — minimal, no button wrapping
    case preview
}

// MARK: - Unified Item Card View

/// **Single source of truth** for item cell rendering across the entire game.
///
/// Usage:
/// ```
/// ItemCardView(item: myItem, context: .inventory(equippedItem: equipped)) { handleTap() }
/// ItemCardView(shopItem: shopItem, context: .shop(...)) { handleBuy() }
/// ItemCardView(rarity: .epic, imageKey: "sword-01", fallbackIcon: "⚔️", context: .loot) { }
/// ```
struct ItemCardView: View {

    // MARK: - Core visual data (always required)

    let rarity: ItemRarity
    let imageKey: String?
    let imageUrl: String?
    let fallbackIcon: String
    var systemIcon: String? = nil
    var systemIconColor: Color? = nil

    // MARK: - Optional item metadata

    var upgradeLevel: Int? = nil
    var quantity: Int? = nil
    var durability: Int? = nil
    var maxDurability: Int? = nil
    var totalPower: Int = 0
    var isEquipped: Bool = false
    var isBroken: Bool = false
    var itemType: ItemType? = nil

    // MARK: - Context & action

    let context: ItemCardContext
    let onTap: () -> Void

    // MARK: - Convenience initializers

    /// Initialize from an `Item` model (inventory, equipment, loot)
    init(item: Item, context: ItemCardContext, onTap: @escaping () -> Void) {
        self.rarity = item.rarity
        self.imageKey = item.imageKey
        self.imageUrl = item.imageUrl
        self.fallbackIcon = item.itemType.icon
        self.systemIcon = item.consumableIcon
        self.systemIconColor = item.consumableIconColor
        self.upgradeLevel = item.upgradeLevel
        self.quantity = item.quantity
        self.durability = item.durability
        self.maxDurability = item.maxDurability
        self.totalPower = item.totalPower
        self.isEquipped = item.isEquipped == true
        self.isBroken = (item.durability ?? 1) <= 0
        self.itemType = item.itemType
        self.context = context
        self.onTap = onTap
    }

    /// Initialize from a `ShopItem` model
    init(shopItem: ShopItem, context: ItemCardContext, onTap: @escaping () -> Void) {
        self.rarity = shopItem.rarity
        self.imageKey = shopItem.imageKey
        self.imageUrl = shopItem.imageUrl
        self.fallbackIcon = shopItem.typeIcon
        self.systemIcon = shopItem.consumableIcon
        self.systemIconColor = shopItem.consumableIconColor
        self.context = context
        self.onTap = onTap
    }

    /// Initialize from a `LootPreview` model
    init(loot: LootPreview, context: ItemCardContext = .preview, onTap: @escaping () -> Void) {
        self.rarity = loot.rarity
        self.imageKey = loot.imageKey
        self.imageUrl = loot.imageUrl
        self.fallbackIcon = loot.icon
        self.context = context
        self.onTap = onTap
    }

    /// Initialize from raw visual data (for LootItemDisplay, generic use)
    init(
        rarity: ItemRarity,
        imageKey: String?,
        imageUrl: String?,
        fallbackIcon: String,
        systemIcon: String? = nil,
        systemIconColor: Color? = nil,
        upgradeLevel: Int? = nil,
        context: ItemCardContext = .loot,
        onTap: @escaping () -> Void
    ) {
        self.rarity = rarity
        self.imageKey = imageKey
        self.imageUrl = imageUrl
        self.fallbackIcon = fallbackIcon
        self.systemIcon = systemIcon
        self.systemIconColor = systemIconColor
        self.upgradeLevel = upgradeLevel
        self.context = context
        self.onTap = onTap
    }

    // MARK: - Computed properties

    private var rarityColor: Color {
        DarkFantasyTheme.rarityColor(for: rarity)
    }

    private var starCount: Int {
        rarity.tier + 1
    }

    private var isHighRarity: Bool {
        rarity == .epic || rarity == .legendary
    }

    private var hasDurability: Bool {
        maxDurability != nil && (maxDurability ?? 0) > 0
    }

    private var durabilityFraction: Double {
        guard let max = maxDurability, max > 0 else { return 1.0 }
        return Double(durability ?? 0) / Double(max)
    }

    /// Comparison delta (inventory context only)
    private var comparisonDelta: Int? {
        guard case .inventory(let equippedItem) = context,
              !isEquipped,
              itemType != .consumable,
              let equipped = equippedItem else { return nil }
        let diff = totalPower - equipped.totalPower
        return diff != 0 ? diff : nil
    }

    /// Whether this is an empty equipment slot
    private var isEmptySlot: Bool {
        if case .equipment = context, imageKey == nil, imageUrl == nil, systemIcon == nil {
            return true
        }
        return false
    }

    /// Shop-specific: whether item is affordable & meets level
    private var shopCanInteract: Bool {
        if case .shop(_, _, let canAfford, let meetsLevel, _) = context {
            return canAfford && meetsLevel
        }
        return true
    }

    /// Shop-specific: currently buying
    private var shopIsBuying: Bool {
        if case .shop(_, _, _, _, let isBuying) = context {
            return isBuying
        }
        return false
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            cellContent
        }
        .buttonStyle(.scalePress(0.95))
        .disabled(isEmptySlot)
    }

    @ViewBuilder
    private var cellContent: some View {
        ZStack {
            // MARK: - Layer 1: Gradient background
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(
                    isEmptySlot
                        ? AnyShapeStyle(DarkFantasyTheme.bgTertiary.opacity(0.4))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                rarityColor.opacity(0.10),
                                DarkFantasyTheme.bgAbyss.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                )

            // MARK: - Layer 2: Radial glow for epic/legendary
            if isHighRarity && !isEmptySlot {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                rarityColor.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
            }

            // MARK: - Layer 3: Item image / empty slot / buying spinner
            if shopIsBuying {
                ProgressView()
                    .tint(DarkFantasyTheme.gold)
            } else if isEmptySlot {
                emptySlotPlaceholder
            } else {
                ItemImageView(
                    imageKey: imageKey,
                    imageUrl: imageUrl,
                    systemIcon: systemIcon,
                    systemIconColor: systemIconColor,
                    fallbackIcon: fallbackIcon
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }

            // MARK: - Layer 4: Bottom vignette
            if !isEmptySlot {
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color.clear,
                            DarkFantasyTheme.bgAbyss.opacity(0.85)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 28)
                }
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            }

            // MARK: - Layer 5: Corner accents
            if !isEmptySlot {
                CornerAccentsOverlay(
                    cornerRadius: LayoutConstants.cardRadius,
                    color: DarkFantasyTheme.borderMedium.opacity(0.6),
                    length: 10,
                    lineWidth: 1.5
                )
            }
        }
        // MARK: - Context-specific overlays
        .overlay(alignment: .topLeading) { topLeadingOverlay }
        .overlay(alignment: .topTrailing) { topTrailingOverlay }
        .overlay(alignment: .bottom) { bottomOverlay }
        .overlay(alignment: .bottomTrailing) { bottomTrailingOverlay }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        // MARK: - Inner bevel border (ornamental gradient)
        .if(!isEmptySlot) { view in
            view.innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 2,
                inset: 2,
                color: rarityColor.opacity(0.15)
            )
        }
        // MARK: - Inner bevel stroke (subtle)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: isEmptySlot ? 1 : 2)
                .padding(isEmptySlot ? 0 : 1)
        )
        // MARK: - Outer rarity border
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(
                    isEmptySlot
                        ? DarkFantasyTheme.borderSubtle
                        : (isBroken
                            ? DarkFantasyTheme.danger
                            : rarityColor.opacity(isEquipped ? 1.0 : 0.7)),
                    lineWidth: isEmptySlot ? 1 : (isEquipped ? 3 : 2.5)
                )
        )
        // MARK: - Corner diamonds (non-empty slots)
        .if(!isEmptySlot) { view in
            view.cornerDiamonds(color: rarityColor.opacity(0.5), size: 4)
        }
        // MARK: - Durability ring
        .overlay {
            if hasDurability && durabilityFraction < 1.0 {
                DurabilityRingOverlay(
                    fraction: durabilityFraction,
                    cornerRadius: LayoutConstants.cardRadius
                )
            }
        }
        // MARK: - Enhanced glow shadows
        .shadow(
            color: isEmptySlot ? Color.clear : DarkFantasyTheme.rarityGlow(for: rarity),
            radius: isHighRarity ? 14 : 6
        )
        .shadow(
            color: isHighRarity && !isEmptySlot ? rarityColor.opacity(0.25) : Color.clear,
            radius: 4
        )
        // MARK: - Shop affordability dimming
        .opacity(shopCanInteract ? 1.0 : 0.5)
    }

    // MARK: - Empty Slot Placeholder

    @ViewBuilder
    private var emptySlotPlaceholder: some View {
        if case .equipment(let slotAsset) = context, let assetName = slotAsset {
            Image(assetName)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
                .foregroundStyle(DarkFantasyTheme.textTertiary.opacity(0.25))
                .saturation(0)
        }
    }

    // MARK: - Top-Leading Overlay

    @ViewBuilder
    private var topLeadingOverlay: some View {
        switch context {
        case .inventory:
            if let delta = comparisonDelta {
                Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(delta > 0 ? DarkFantasyTheme.success : DarkFantasyTheme.danger)
                    .padding(3)
                    .background(
                        Circle()
                            .fill(DarkFantasyTheme.bgSecondary.opacity(0.9))
                    )
                    .padding(3)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Top-Trailing Overlay

    @ViewBuilder
    private var topTrailingOverlay: some View {
        if isEquipped {
            // Equipped badge — shown in any context
            Text("E")
                .font(DarkFantasyTheme.body(size: 11).bold())
                .foregroundStyle(DarkFantasyTheme.textOnGold)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(DarkFantasyTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
                .padding(LayoutConstants.spaceXS)
        } else if isBroken {
            // Broken indicator — equipment context
            Text("!")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .frame(width: 16, height: 16)
                .background(Circle().fill(DarkFantasyTheme.danger))
                .padding(LayoutConstants.spaceXS)
        }
    }

    // MARK: - Bottom Overlay

    @ViewBuilder
    private var bottomOverlay: some View {
        if isEmptySlot {
            EmptyView()
        } else if case .shop(let price, let isGem, _, _, _, let originalPrice, let discountPct) = context {
            // Shop price bar with optional discount
            shopPriceBar(price: price, isGem: isGem, originalPrice: originalPrice, discountPct: discountPct)
        } else {
            // Rarity stars + upgrade level
            HStack(spacing: 2) {
                ForEach(0..<starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(DarkFantasyTheme.gold)
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 2)
                }
                if let upg = upgradeLevel, upg > 0 {
                    Text("+\(upg)")
                        .font(DarkFantasyTheme.body(size: 9).bold())
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .shadow(color: DarkFantasyTheme.goldGlow, radius: 2)
                }
            }
            .padding(.bottom, 4)
        }
    }

    // MARK: - Bottom-Trailing Overlay

    @ViewBuilder
    private var bottomTrailingOverlay: some View {
        if let qty = quantity, qty > 1 {
            Text("x\(qty)")
                .font(DarkFantasyTheme.body(size: 11).bold())
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(DarkFantasyTheme.bgElevated.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
                .padding(LayoutConstants.spaceXS)
        }
    }

    // MARK: - Shop Price Bar

    @ViewBuilder
    private func shopPriceBar(price: Int, isGem: Bool, originalPrice: Int? = nil, discountPct: Int? = nil) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Strikethrough original price (if discounted)
                if let original = originalPrice, let _ = discountPct, original > price {
                    CurrencyDisplay(
                        gold: isGem ? 0 : original,
                        gems: isGem ? original : nil,
                        size: .mini,
                        currencyType: isGem ? .gems : .gold,
                        animated: false
                    )
                    .strikethrough(color: DarkFantasyTheme.danger.opacity(0.8))
                    .opacity(0.5)
                }

                // Current (sale) price
                CurrencyDisplay(
                    gold: isGem ? 0 : price,
                    gems: isGem ? price : nil,
                    size: .mini,
                    currencyType: isGem ? .gems : .gold,
                    animated: false
                )
            }
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .frame(maxWidth: .infinity)
            .background(DarkFantasyTheme.bgAbyss.opacity(0.65))
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: LayoutConstants.cardRadius,
                    bottomTrailingRadius: LayoutConstants.cardRadius,
                    topTrailingRadius: 0
                )
            )

            // Discount badge (top-right corner of price bar)
            if let pct = discountPct, pct > 0 {
                Text("-\(pct)%")
                    .font(DarkFantasyTheme.body(size: 10).bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.danger)
                    )
                    .offset(x: 4, y: -8)
            }
        }
    }
}

// MARK: - Corner Accents Overlay (metallic L-bracket decorations)

struct CornerAccentsOverlay: View {
    let cornerRadius: CGFloat
    let color: Color
    var length: CGFloat = 10
    var lineWidth: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let inset: CGFloat = 3

            Canvas { context, _ in
                var path = Path()

                // Top-left
                path.move(to: CGPoint(x: inset, y: inset + length))
                path.addLine(to: CGPoint(x: inset, y: inset))
                path.addLine(to: CGPoint(x: inset + length, y: inset))

                // Top-right
                path.move(to: CGPoint(x: w - inset - length, y: inset))
                path.addLine(to: CGPoint(x: w - inset, y: inset))
                path.addLine(to: CGPoint(x: w - inset, y: inset + length))

                // Bottom-left
                path.move(to: CGPoint(x: inset, y: h - inset - length))
                path.addLine(to: CGPoint(x: inset, y: h - inset))
                path.addLine(to: CGPoint(x: inset + length, y: h - inset))

                // Bottom-right
                path.move(to: CGPoint(x: w - inset - length, y: h - inset))
                path.addLine(to: CGPoint(x: w - inset, y: h - inset))
                path.addLine(to: CGPoint(x: w - inset, y: h - inset - length))

                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Durability Ring Overlay (contour around icon)

struct DurabilityRingOverlay: View {
    let fraction: Double
    var cornerRadius: CGFloat = 12
    var lineWidth: CGFloat = 2.5

    private var durabilityColor: Color {
        DarkFantasyTheme.durabilityColor(fraction: fraction)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(durabilityColor.opacity(0.15), lineWidth: lineWidth)

            RoundedRectangle(cornerRadius: cornerRadius)
                .trim(from: 0, to: fraction)
                .stroke(
                    durabilityColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .shadow(color: durabilityColor.opacity(0.5), radius: 3)
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
    }
}
