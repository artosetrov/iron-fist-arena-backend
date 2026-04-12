import SwiftUI

/// "The Scavenger" — timed contraband loot drops in the shop.
///
/// Two visual states:
/// - **Cooldown**: Dark card with progress bar + countdown timer + lore text
/// - **Available**: Contraband offer card with loot preview + CLAIM/BUY CTA
///
/// Replaces the Special Offers widget position when active.
struct ContrabandWidget: View {
    let state: ContrabandUIState
    let canAfford: Bool
    let isClaiming: Bool
    let onClaim: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Section header
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "eye.slash")
                    .font(DarkFantasyTheme.body)
                Text("THE SCAVENGER")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.contrabandAccent)
                Spacer()
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            switch state {
            case .loading:
                loadingState
                    .padding(.horizontal, LayoutConstants.screenPadding)
            case .cooldown(let nextAt, _, let totalSeconds, _):
                CooldownCard(
                    nextAt: nextAt,
                    totalSeconds: totalSeconds,
                    onReady: onRefresh
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
            case .available(let offer):
                AvailableCard(
                    offer: offer,
                    canAfford: canAfford,
                    isClaiming: isClaiming,
                    onClaim: onClaim
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
            case .error:
                errorState
                    .padding(.horizontal, LayoutConstants.screenPadding)
            }
        }
    }

    // MARK: - Loading

    private var loadingState: some View {
        HStack {
            Spacer()
            HexPulseLoader(.compact)
            Spacer()
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }

    // MARK: - Error

    private var errorState: some View {
        HStack {
            Spacer()
            VStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "exclamationmark.triangle")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                Text("The Scavenger couldn't be reached...")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            Spacer()
        }
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }
}

// MARK: - Cooldown Card

/// Shows progress bar + countdown timer while the Scavenger is "searching".
private struct CooldownCard: View {
    let nextAt: Date
    let totalSeconds: Int
    let onReady: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let remaining = max(0, nextAt.timeIntervalSince(now))
            let progress = 1.0 - (remaining / Double(totalSeconds))

            VStack(spacing: LayoutConstants.spaceMS) {
                // Lore text
                // Title + timer in one row
                HStack {
                    Image(systemName: "figure.walk")
                        .font(DarkFantasyTheme.cardTitle)
                        .foregroundStyle(DarkFantasyTheme.contrabandAccent.opacity(0.7))

                    Text("SCOURING...")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .tracking(1)

                    Spacer(minLength: 0)

                    Text(formatCountdown(remaining))
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.contrabandAccent)
                        .monospacedDigit()
                        .shadow(color: DarkFantasyTheme.contrabandAccent.opacity(0.4), radius: 6)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(DarkFantasyTheme.bgAbyss)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DarkFantasyTheme.contrabandAccent.opacity(0.6),
                                        DarkFantasyTheme.contrabandAccent,
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(1.0, progress), height: 8)
                            .animation(.linear(duration: 1), value: progress)

                        if progress > 0.05 && progress < 1.0 {
                            Circle()
                                .fill(DarkFantasyTheme.contrabandAccent)
                                .frame(width: 6, height: 6)
                                .shadow(color: DarkFantasyTheme.contrabandAccent.opacity(0.8), radius: 4)
                                .offset(x: geo.size.width * min(1.0, progress) - 3)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, LayoutConstants.spaceMD)
            .padding(.vertical, LayoutConstants.spaceMS)
            .background(
                RadialGlowBackground(
                    baseColor: DarkFantasyTheme.bgSecondary,
                    glowColor: DarkFantasyTheme.contrabandAccent.opacity(0.05),
                    glowIntensity: 0.3,
                    cornerRadius: LayoutConstants.cardRadius
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
            .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.06, bottomShadow: 0.10)
            .innerBorder(
                cornerRadius: LayoutConstants.cardRadius - 2,
                inset: 2,
                color: DarkFantasyTheme.contrabandAccent.opacity(0.06)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .stroke(DarkFantasyTheme.contrabandAccent.opacity(0.3), lineWidth: 1)
            )
            .cornerBrackets(
                color: DarkFantasyTheme.contrabandAccent.opacity(0.25),
                length: 14,
                thickness: 1.5
            )
            .cardShadow()
            .onChange(of: remaining <= 0) { _, isReady in
                if isReady { onReady() }
            }
        }
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Available Card

/// Shows the contraband offer with loot preview and CLAIM/BUY button.
private struct AvailableCard: View {
    let offer: ContrabandOffer
    let canAfford: Bool
    let isClaiming: Bool
    let onClaim: () -> Void

    private var ctaLabel: String {
        offer.isFree ? "CLAIM" : "BUY"
    }

    var body: some View {
        VStack(spacing: LayoutConstants.spaceMS) {
            // Header — flavor text
            HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text("CONTRABAND DROP #\(offer.claimNumber)")
                        .font(DarkFantasyTheme.buttonLabel)
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .tracking(0.5)
                        .lineLimit(1)

                    Text(offer.flavorText)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                // Free/Paid badge
                Text(offer.isFree ? "FREE" : "PAID")
                    .font(DarkFantasyTheme.badge)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .padding(.horizontal, LayoutConstants.spaceXS)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .fill(offer.isFree ? DarkFantasyTheme.success : DarkFantasyTheme.contrabandAccent)
                    )
            }

            // Rewards row — reuse OfferRewardMapper pattern
            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(offer.contents.prefix(3).enumerated()), id: \.offset) { _, content in
                    contrabandRewardCard(for: content)
                        .allowsHitTesting(false)
                }
                if offer.contents.count < 3 {
                    ForEach(0..<(3 - offer.contents.count), id: \.self) { _ in
                        Color.clear
                    }
                }
            }

            // Footer — price + CTA
            HStack(alignment: .center, spacing: LayoutConstants.spaceMS) {
                if offer.isFree {
                    Text("FREE")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .shadow(color: DarkFantasyTheme.gold.opacity(0.5), radius: 6)
                } else {
                    Text("\(offer.price) gold")
                        .font(DarkFantasyTheme.section)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                Spacer(minLength: LayoutConstants.spaceXS)

                Button {
                    HapticManager.heavy()
                    onClaim()
                } label: {
                    Group {
                        if isClaiming {
                            HexPulseLoader(.compact)
                        } else {
                            Text(ctaLabel)
                                .font(DarkFantasyTheme.buttonLabelCompact)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary)
                .frame(width: 140, height: 44)
                .disabled(!canAfford || isClaiming)
                .opacity(canAfford ? 1 : 0.5)
            }
        }
        .padding(.horizontal, LayoutConstants.spaceMD)
        .padding(.top, LayoutConstants.spaceMS)
        .padding(.bottom, LayoutConstants.spaceMS)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.contrabandAccent.opacity(0.08),
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.cardRadius))
        .surfaceLighting(cornerRadius: LayoutConstants.cardRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.contrabandAccent.opacity(0.08)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.contrabandAccent.opacity(0.55), lineWidth: 1.5)
        )
        .cornerBrackets(
            color: DarkFantasyTheme.contrabandAccent.opacity(0.4),
            length: 14,
            thickness: 1.5
        )
        .cardShadow()
    }

    // MARK: - Reward Card Builder

    @ViewBuilder
    private func contrabandRewardCard(for content: OfferContent) -> some View {
        let (rarity, imageKey, fallback) = rewardVisuals(for: content)
        ItemCardView(
            rarity: rarity,
            imageKey: imageKey,
            imageUrl: nil,
            fallbackIcon: fallback,
            context: .offerReward(label: rewardLabel(for: content)),
            onTap: {}
        )
    }

    private func rewardVisuals(for content: OfferContent) -> (ItemRarity, String?, String) {
        switch content.type {
        case "gold":
            return (.legendary, "icon-gold", "shippingbox")
        case "gems":
            return (.epic, "icon-gems", "shippingbox")
        case "xp":
            return (.rare, "icon-xp", "shippingbox")
        case "consumable":
            return (.uncommon, content.id, "shippingbox")
        case "item":
            return (.rare, content.id, "shippingbox")
        default:
            return (.common, nil, "shippingbox")
        }
    }

    private func rewardLabel(for content: OfferContent) -> String {
        let q = content.quantity
        if q >= 1_000_000 { return "×\(q / 1_000_000)M" }
        if q >= 10_000 { return "×\(q / 1_000)K" }
        return "×\(q)"
    }
}
