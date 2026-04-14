import SwiftUI

struct TabSwitcher: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    /// Optional per-tab "+N" badges. If provided, `badges.count` must equal `tabs.count`.
    /// A `nil` entry or a value `<= 0` renders no badge; positive values render a gold
    /// "+N" capsule anchored at the top-trailing corner of the matching tab cell.
    /// Using per-tab positioning (vs a single `.trailing` overlay on the whole switcher)
    /// keeps badges correctly anchored when tabs are added or reordered.
    var badges: [Int?]? = nil
    @Namespace private var tabNamespace
    @State private var badgePulse = false

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
                        .font(DarkFantasyTheme.body)
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
                                    .frame(height: LayoutConstants.space2XS)
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
        .overlay(alignment: .top) { badgeOverlay }
        .onAppear {
            guard hasAnyBadge else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                badgePulse = true
            }
        }
        .onDisappear { badgePulse = false }
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

    // MARK: - Badges

    private var hasAnyBadge: Bool {
        guard let badges else { return false }
        return badges.contains(where: { ($0 ?? 0) > 0 })
    }

    @ViewBuilder
    private var badgeOverlay: some View {
        if let badges, badges.count == tabs.count, hasAnyBadge {
            GeometryReader { geo in
                let tabWidth = geo.size.width / CGFloat(tabs.count)
                ForEach(tabs.indices, id: \.self) { index in
                    if let count = badges[index], count > 0 {
                        pointsBadge(count)
                            // Top-trailing corner of the tab cell, nudged inward
                            // so the capsule sits over the cell — not between cells.
                            .position(
                                x: tabWidth * CGFloat(index) + tabWidth - LayoutConstants.spaceMD,
                                y: -LayoutConstants.space2XS
                            )
                            .accessibilityLabel("\(count) \(tabs[index].lowercased()) points available")
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func pointsBadge(_ count: Int) -> some View {
        Text("+\(count)")
            .font(DarkFantasyTheme.body.weight(.semibold))
            .foregroundStyle(DarkFantasyTheme.textOnGold)
            .padding(.horizontal, LayoutConstants.spaceXS)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(Capsule().fill(DarkFantasyTheme.goldBright))
            .overlay(
                Capsule().stroke(DarkFantasyTheme.bgAbyss, lineWidth: 1.5)
            )
            .shadow(
                color: DarkFantasyTheme.goldBright.opacity(badgePulse ? 0.8 : 0.2),
                radius: badgePulse ? 10 : 4
            )
    }
}
