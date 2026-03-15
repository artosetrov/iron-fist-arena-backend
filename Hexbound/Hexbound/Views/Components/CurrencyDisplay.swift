import SwiftUI

struct CurrencyDisplay: View {
    let gold: Int
    var gems: Int? = nil
    var showAddButton: Bool = false
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 5) {
                    Text("\u{1FA99}")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    Text(formatGold(gold))
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                if let gems = gems, gems > 0 {
                    HStack(spacing: 5) {
                        Text("\u{1F48E}")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        Text("\(gems)")
                            .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                            .foregroundStyle(DarkFantasyTheme.cyan)
                    }
                }
            }

            if showAddButton {
                Button {
                    onAdd?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.gold)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
        }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
