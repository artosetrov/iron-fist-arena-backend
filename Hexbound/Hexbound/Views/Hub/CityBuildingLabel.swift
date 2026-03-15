import SwiftUI

// MARK: - City Building Label (Banner above building on tap)

struct CityBuildingLabel: View {
    let text: String
    let visible: Bool

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(DarkFantasyTheme.gold.opacity(0.7), lineWidth: 1)
            )
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 6)
            .animation(.easeOut(duration: 0.25), value: visible)
    }
}
