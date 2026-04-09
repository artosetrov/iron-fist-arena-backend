import SwiftUI

/// Equipped indicator badge — gold "E" shown on item cards and equipment slots.
/// Figma DS: Components / Badges & Pills → Equipped Badge
struct EquippedBadge: View {
    var body: some View {
        Text("E")
            .font(DarkFantasyTheme.body.bold())
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(DarkFantasyTheme.gold)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusXS))
    }
}

#Preview {
    ZStack {
        DarkFantasyTheme.bgAbyss
        EquippedBadge()
    }
}
