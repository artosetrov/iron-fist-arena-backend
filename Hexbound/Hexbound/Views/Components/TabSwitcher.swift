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
                                    .fill(
                                        LinearGradient(
                                            colors: [DarkFantasyTheme.goldDim, DarkFantasyTheme.gold, DarkFantasyTheme.goldDim],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 2)
                                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 4, y: 0)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.scalePress)
                .accessibilityLabel(tabs[index])
            }
        }
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.panelRadius
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        .surfaceLighting(cornerRadius: LayoutConstants.panelRadius, topHighlight: 0.06, bottomShadow: 0.10)
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 3,
            inset: 3,
            color: DarkFantasyTheme.borderMedium.opacity(0.2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .cornerBrackets(color: DarkFantasyTheme.borderMedium, length: 10, thickness: 1)
        .cornerDiamonds(color: DarkFantasyTheme.borderStrong, size: 4)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
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
