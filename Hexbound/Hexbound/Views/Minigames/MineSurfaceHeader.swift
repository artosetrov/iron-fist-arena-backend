import SwiftUI

/// Top of the Gold Mine screen: the head-frame on the surface, the Mine
/// Foreman and what he has to say, and the hero's gold and gems.
///
/// The foreman's first line is about right now (full carts, an empty
/// tunnel, the next cart's time); tapping him cycles through how the mine
/// works, with every number taken from the server's `economy`.
struct MineSurfaceHeader: View {
    @Bindable var vm: GoldMineViewModel
    @State private var lineIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            balances
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let lines = vm.foremanLines(now: context.date)
                scene(line: lines[lineIndex % max(lines.count, 1)])
            }
        }
    }

    // MARK: Balances

    private var balances: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            balance(icon: "icon-gold", value: vm.gold, color: DarkFantasyTheme.goldBright)
            balance(icon: "icon-gems", value: vm.gems, color: DarkFantasyTheme.cyan)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.gold) gold, \(vm.gems) gems")
    }

    /// Cross-fades to the new total (opacity only — digits don't roll).
    private func balance(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: LayoutConstants.spaceXS) {
            MineIcon(name: icon, size: 26)
            Text(value.formatted())
                .font(DarkFantasyTheme.section)
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.opacity)
                .animation(MotionConstants.smooth, value: value)
        }
    }

    // MARK: Surface scene

    private func scene(line: String) -> some View {
        ZStack(alignment: .topLeading) {
            Image("building-gold-mine")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 184, height: 176)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .accessibilityHidden(true)

            foreman
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            bubble(line: line)
                .padding(.leading, 100)
                .padding(.top, LayoutConstants.spaceXS)
        }
        .frame(height: 184)
    }

    @ViewBuilder
    private var foreman: some View {
        let portrait = NPCSpeaker.mine.portrait
        Button {
            HapticManager.light()
            lineIndex += 1
        } label: {
            Group {
                if UIImage(named: portrait) != nil {
                    Image(portrait)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Color.clear
                }
            }
            .frame(width: 104, height: 108)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mine Foreman")
        .accessibilityHint("Tells you the next tip about the mine")
    }

    private func bubble(line: String) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
            Text("MINE FOREMAN")
                .font(DarkFantasyTheme.buttonLabelCompact)
                .tracking(1.5)
                .foregroundStyle(DarkFantasyTheme.gold)
            Text(line)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, LayoutConstants.spaceMS)
        .padding(.vertical, LayoutConstants.spaceSM)
        .frame(maxWidth: 230, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.borderSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

/// Timber beam between the surface and the shaft.
struct MineGroundBeam: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DarkFantasyTheme.goldDim.opacity(0.7))
                .frame(height: 2)
            Rectangle()
                .fill(DarkFantasyTheme.goldDim.opacity(0.35))
                .frame(height: 6)
        }
        .accessibilityHidden(true)
    }
}
