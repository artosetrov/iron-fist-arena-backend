import SwiftUI

// MARK: - Active Shaft Banner
//
// Shown at the top of the Gold Mine screen once the player has picked a
// shaft. Displays the shaft thumb, name, progress label (e.g. "3 / 5"),
// and a thin gold progress bar. Locked look — no change button here
// (Variant D rule: you can't change shafts mid-cycle).

struct ActiveShaftBanner: View {
    let shaft: ActiveShaft
    /// Optional tap handler. When set, the whole banner becomes tappable —
    /// used in Gold Mine to trigger Collect All + mini-game from the shaft
    /// banner. `nil` = purely decorative banner.
    var onTap: (() -> Void)? = nil
    var isDisabled: Bool = false

    var body: some View {
        Button {
            guard !isDisabled, let onTap else { return }
            HapticManager.medium()
            onTap()
        } label: {
            bannerContent
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil || isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }

    private var bannerContent: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Thumb
            Image(shaft.key.thumbAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: LayoutConstants.mineShaftThumbSM, height: LayoutConstants.mineShaftThumbSM)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                        .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                HStack {
                    Text("ACTIVE SHAFT")
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(1.2)
                    Spacer()
                    Text(shaft.progressLabel)
                        .font(DarkFantasyTheme.badge)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .contentTransition(.numericText())
                        .animation(MotionConstants.smooth, value: shaft.progress)
                }
                Text(shaft.key.displayName.uppercased())
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(1)
                progressBar
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.vertical, LayoutConstants.spaceSM)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    private var progressBar: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                .fill(DarkFantasyTheme.bgTertiary)
                .frame(height: LayoutConstants.mineProgressHeight)
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(DarkFantasyTheme.goldGradient)
                    .frame(width: proxy.size.width * CGFloat(shaft.fraction), height: 5)
                    .animation(MotionConstants.smooth, value: shaft.fraction)
            }
            .frame(height: LayoutConstants.mineProgressHeight)
        }
        .frame(height: LayoutConstants.mineProgressHeight)
    }
}

// MARK: - Shaft Picker Sheet
//
// Presented as a sheet when the backend responds with
// `needs_shaft_pick: true` from /collect-all. The player picks one
// unlocked shaft; only unlocked shafts are tappable. The sheet calls
// back with the chosen shaft key and the parent view re-fires
// /collect-all with `picked_shaft_key`.

struct ShaftPickerSheet: View {
    let unlockedShafts: [ShaftKey]
    let currentSlotLevel: Int
    let onPick: (ShaftKey) -> Void
    let onCancel: () -> Void

    @State private var showCard = false

    private let accentColor = DarkFantasyTheme.goldBright

    var body: some View {
        ZStack {
            // Dimmed backdrop — taps cancel the picker
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            // Radial glow accent
            RadialGradient(
                colors: [
                    accentColor.opacity(0.18),
                    accentColor.opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()
            .opacity(showCard ? 1 : 0)
            .allowsHitTesting(false)

            // Main card — full DS chrome (matches ClaimRewardModalView pattern)
            ScrollView(.vertical, showsIndicators: false) {
                cardContent
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.modalRadius))
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgPrimary,
                    glowColor: DarkFantasyTheme.bgSecondary,
                    glowIntensity: 0.4,
                    cornerRadius: LayoutConstants.modalRadius
                )
            )
            .surfaceLighting(cornerRadius: LayoutConstants.modalRadius, topHighlight: 0.10, bottomShadow: 0.16)
            .innerBorder(cornerRadius: LayoutConstants.modalRadius - 3, inset: 3, color: accentColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                    .stroke(accentColor.opacity(0.5), lineWidth: 2)
            )
            .cornerBrackets(color: accentColor.opacity(0.4), length: 18, thickness: 2.0)
            .cornerDiamonds(color: accentColor.opacity(0.5), size: 6)
            .shadow(color: accentColor.opacity(0.3), radius: 20, y: 4)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 12, y: 6)
            .padding(.horizontal, LayoutConstants.screenPadding)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.78)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            withAnimation(MotionConstants.dramatic) {
                showCard = true
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            header
                .padding(.top, LayoutConstants.spaceLG)

            GoldDivider()
                .padding(.horizontal, LayoutConstants.spaceMD)

            shaftList

            Button {
                HapticManager.light()
                onCancel()
            } label: {
                Text("CANCEL")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compactOutline(color: DarkFantasyTheme.borderMedium, fillOpacity: 0.15))
            .padding(.horizontal, LayoutConstants.cardPadding)

            Spacer().frame(height: LayoutConstants.spaceMD)
        }
    }

    private var header: some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            Text("CHOOSE YOUR SHAFT")
                .font(DarkFantasyTheme.section)
                .foregroundStyle(accentColor)
                .tracking(1.5)
                .shadow(color: accentColor.opacity(0.3), radius: 8)
            Text("Commit to one shaft for the full expedition cycle.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceLG)
        }
    }

    private var shaftList: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(ShaftKey.allCases) { key in
                let isUnlocked = unlockedShafts.contains(key)
                ShaftPickerRow(
                    shaft: key,
                    isUnlocked: isUnlocked,
                    currentSlotLevel: currentSlotLevel
                ) {
                    guard isUnlocked else { return }
                    HapticManager.medium()
                    onPick(key)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.cardPadding)
    }
}

/// Single row in the shaft picker. Tappable when unlocked; dimmed +
/// "Requires slot level X" label when locked. No scale animation — per
/// project rule, opacity is the only press feedback.
private struct ShaftPickerRow: View {
    let shaft: ShaftKey
    let isUnlocked: Bool
    let currentSlotLevel: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LayoutConstants.spaceMD) {
                Image(shaft.thumbAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: LayoutConstants.mineShaftThumbMD, height: LayoutConstants.mineShaftThumbMD)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                            .stroke(DarkFantasyTheme.gold.opacity(isUnlocked ? 0.5 : 0.15), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(shaft.displayName.uppercased())
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(isUnlocked ? DarkFantasyTheme.textPrimary : DarkFantasyTheme.textDisabled)
                        .lineLimit(1)
                    if isUnlocked {
                        Text("Commit for \(5) extractions")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    } else {
                        Text("Requires slot level \(shaft.unlockSlotLevel)")
                            .font(DarkFantasyTheme.caption)
                            .foregroundStyle(DarkFantasyTheme.danger)
                    }
                }
                Spacer()
                if isUnlocked {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DarkFantasyTheme.gold)
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(DarkFantasyTheme.textDisabled)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(DarkFantasyTheme.bgSecondary.opacity(isUnlocked ? 0.85 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(
                        isUnlocked ? DarkFantasyTheme.gold.opacity(0.3) : DarkFantasyTheme.borderSubtle,
                        lineWidth: 1
                    )
            )
            .opacity(isUnlocked ? 1.0 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - Shaft Cleared Overlay
//
// Shown for ~2.5s when /minigame-bonus returns `shaft_completed: true`.
// Celebration moment after clearing the full shaft cycle. Dismisses on
// tap or timer, then the parent view re-shows the picker on next
// /collect-all.

struct ShaftClearedOverlay: View {
    let clearedShaftKey: ShaftKey
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: LayoutConstants.spaceLG) {
                Text("SHAFT CLEARED")
                    .font(DarkFantasyTheme.cinematicTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(2)
                    .opacity(appeared ? 1 : 0)
                    .animation(MotionConstants.smooth.delay(0.1), value: appeared)

                Image(clearedShaftKey.thumbAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: LayoutConstants.mineShaftThumbLG, height: LayoutConstants.mineShaftThumbLG)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                            .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                    )
                    .shadow(color: DarkFantasyTheme.goldGlow, radius: 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(MotionConstants.smooth.delay(0.2), value: appeared)

                Text(clearedShaftKey.displayName.uppercased())
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .animation(MotionConstants.smooth.delay(0.3), value: appeared)

                Text("You may pick a new shaft on your next collect.")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LayoutConstants.spaceXL)
                    .opacity(appeared ? 1 : 0)
                    .animation(MotionConstants.smooth.delay(0.4), value: appeared)

                Button {
                    onDismiss()
                } label: {
                    Text("CONTINUE")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.compactPrimary)
                .padding(.horizontal, LayoutConstants.spaceXL)
                .opacity(appeared ? 1 : 0)
                .animation(MotionConstants.smooth.delay(0.5), value: appeared)
            }
        }
        .onAppear {
            HapticManager.success()
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onDismiss()
            }
        }
    }
}
