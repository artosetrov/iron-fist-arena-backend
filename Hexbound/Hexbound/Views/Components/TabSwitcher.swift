import SwiftUI

struct TabSwitcher: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    HapticManager.selection()
                    SFXManager.shared.play(.uiTap)
                    withAnimation(MotionConstants.tabIndicatorSlide) {
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
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.scalePress)
                .accessibilityLabel(tabs[index])
            }
        }
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    // Only trigger if horizontal swipe is dominant
                    guard abs(horizontal) > vertical else { return }
                    if horizontal < 0 && selectedIndex < tabs.count - 1 {
                        HapticManager.selection()
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.tabIndicatorSlide) {
                            selectedIndex += 1
                        }
                    } else if horizontal > 0 && selectedIndex > 0 {
                        HapticManager.selection()
                        SFXManager.shared.play(.uiTap)
                        withAnimation(MotionConstants.tabIndicatorSlide) {
                            selectedIndex -= 1
                        }
                    }
                }
        )
    }
}
