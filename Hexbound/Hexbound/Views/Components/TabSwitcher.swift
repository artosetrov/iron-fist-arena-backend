import SwiftUI

struct TabSwitcher: View {
    let tabs: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(
                            selectedIndex == index ? DarkFantasyTheme.goldBright : DarkFantasyTheme.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            selectedIndex == index ? DarkFantasyTheme.bgElevated : Color.clear
                        )
                        .overlay(alignment: .bottom) {
                            if selectedIndex == index {
                                Rectangle()
                                    .fill(DarkFantasyTheme.gold)
                                    .frame(height: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
