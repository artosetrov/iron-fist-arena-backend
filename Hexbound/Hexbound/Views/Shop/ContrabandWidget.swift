import SwiftUI

/// "The Scavenger's crate" — the black market's timed contraband drop.
///
/// Redesigned 2026-10-16 with the Black Market header (design canvas,
/// concept A): one crimson crate card in both states, so the screen keeps its
/// shape while the timer runs.
/// - **Cooldown**: "SCOURING THE DOCKS…", countdown + progress, three sealed slots.
/// - **Available**: "TONIGHT'S CRATE", the real rewards in the slots,
///   flavour line, and a full-width PRY IT OPEN button with the price on it.
///
/// The keeper himself lives in `ShopkeeperHeader`, so the card no longer
/// repeats "THE SCAVENGER".
struct ContrabandWidget: View {
    let state: ContrabandUIState
    let canAfford: Bool
    let isClaiming: Bool
    let onClaim: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        Group {
            switch state {
            case .loading:
                CrateCard {
                    HStack {
                        Spacer()
                        HexPulseLoader(.compact)
                        Spacer()
                    }
                    .frame(height: 140)
                }
            case .cooldown(let nextAt, _, let totalSeconds, let claimNumber):
                CooldownCrate(
                    nextAt: nextAt,
                    totalSeconds: totalSeconds,
                    claimNumber: claimNumber,
                    onReady: onRefresh
                )
            case .available(let offer):
                AvailableCrate(
                    offer: offer,
                    canAfford: canAfford,
                    isClaiming: isClaiming,
                    onClaim: onClaim
                )
            case .error:
                CrateCard {
                    VStack(spacing: LayoutConstants.spaceSM) {
                        Text("The Scavenger is lying low tonight.")
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.contrabandMuted)
                            .multilineTextAlignment(.center)
                        Button("TRY AGAIN", action: onRefresh)
                            .buttonStyle(.secondary)
                            .frame(maxWidth: 200)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LayoutConstants.spaceMD)
                }
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }
}

// MARK: - Card chrome

/// Crimson crate frame shared by every state.
private struct CrateCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceMS) {
            content
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                .fill(
                    LinearGradient(
                        colors: [DarkFantasyTheme.bmCounterTop, DarkFantasyTheme.bmCounterBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusXL)
                .stroke(DarkFantasyTheme.contrabandAccent.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.contrabandAccent.opacity(0.18), radius: 14)
        .cornerBrackets(
            color: DarkFantasyTheme.contrabandAccent.opacity(0.35),
            length: 14,
            thickness: 1.5
        )
    }
}

private struct CrateTitle: View {
    let title: String
    let trailing: String
    var trailingColor: Color = DarkFantasyTheme.contrabandMuted

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DarkFantasyTheme.cardTitle)
                .tracking(3)
                .foregroundStyle(DarkFantasyTheme.contrabandBright)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: LayoutConstants.spaceSM)
            Text(trailing)
                .font(DarkFantasyTheme.uiLabel.weight(.semibold))
                .foregroundStyle(trailingColor)
                .monospacedDigit()
        }
    }
}

/// Dashed slot that holds one reward (or a sealed "?").
private struct CrateSlot<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .fill(DarkFantasyTheme.bgAbyss.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                    .strokeBorder(
                        DarkFantasyTheme.bmCounterEdge,
                        style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                    )
            )
    }
}

private struct SealedSlot: View {
    var body: some View {
        CrateSlot {
            Text("?")
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.bmCounterEdge)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Cooldown

private struct CooldownCrate: View {
    let nextAt: Date
    let totalSeconds: Int
    let claimNumber: Int
    let onReady: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = max(0, nextAt.timeIntervalSince(timeline.date))
            let progress = totalSeconds > 0 ? min(1, max(0, 1 - remaining / Double(totalSeconds))) : 1

            CrateCard {
                CrateTitle(
                    title: "SCOURING THE DOCKS…",
                    trailing: Self.format(remaining),
                    trailingColor: DarkFantasyTheme.contrabandBright
                )

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DarkFantasyTheme.bgAbyss)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [DarkFantasyTheme.bmCounterEdge, DarkFantasyTheme.contrabandBright],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress)
                            .animation(.linear(duration: 1), value: progress)
                    }
                }
                .frame(height: 8)

                HStack(spacing: LayoutConstants.spaceSM) {
                    SealedSlot()
                    SealedSlot()
                    SealedSlot()
                }

                Text("Crate #\(claimNumber) is on its way. Come back when the lamp is lit.")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.contrabandMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next crate in \(Self.spoken(remaining))")
            .onChange(of: remaining <= 0) { _, isReady in
                if isReady { onReady() }
            }
        }
    }

    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    static func spoken(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60
        return h > 0 ? "\(h) hours \(m) minutes" : "\(m) minutes"
    }
}

// MARK: - Available

private struct AvailableCrate: View {
    let offer: ContrabandOffer
    let canAfford: Bool
    let isClaiming: Bool
    let onClaim: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    private var ctaTitle: String {
        if offer.isFree { return "PRY IT OPEN · FREE" }
        if !canAfford { return "NOT ENOUGH GOLD" }
        return "PRY IT OPEN · \(offer.price.formatted()) GOLD"
    }

    var body: some View {
        CrateCard {
            CrateTitle(title: "TONIGHT'S CRATE", trailing: "Crate #\(offer.claimNumber)")

            if !offer.flavorText.isEmpty {
                Text("“\(offer.flavorText)”")
                    .font(DarkFantasyTheme.uiLabel.italic())
                    .foregroundStyle(DarkFantasyTheme.contrabandInk)
                    .lineLimit(2)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(offer.contents.prefix(3).enumerated()), id: \.offset) { _, content in
                    CrateSlot {
                        rewardCard(for: content)
                            .allowsHitTesting(false)
                            .padding(LayoutConstants.spaceXS)
                    }
                }
                ForEach(0..<max(0, 3 - offer.contents.count), id: \.self) { _ in
                    SealedSlot()
                }
            }

            Button {
                HapticManager.heavy()
                onClaim()
            } label: {
                Group {
                    if isClaiming {
                        HexPulseLoader(.compact)
                    } else {
                        Text(ctaTitle)
                            .font(DarkFantasyTheme.buttonLabel)
                            .tracking(2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .foregroundStyle(DarkFantasyTheme.contrabandInk)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.touchComfortable)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(
                            LinearGradient(
                                colors: canAfford
                                    ? [DarkFantasyTheme.contrabandBright, DarkFantasyTheme.bmCounterEdge]
                                    : [DarkFantasyTheme.bmSignTop, DarkFantasyTheme.bmSignBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .stroke(DarkFantasyTheme.contrabandBright.opacity(canAfford ? 0.9 : 0.3), lineWidth: 1)
                )
                .shadow(
                    color: DarkFantasyTheme.contrabandAccent.opacity(canAfford && breathe ? 0.6 : 0.25),
                    radius: 14
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford || isClaiming)
            .accessibilityLabel(offer.isFree ? "Open the crate for free" : "Open the crate for \(offer.price) gold")
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }

    // MARK: - Reward visuals

    @ViewBuilder
    private func rewardCard(for content: OfferContent) -> some View {
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
        case "gold": return (.legendary, "icon-gold", "shippingbox")
        case "gems": return (.epic, "icon-gems", "shippingbox")
        case "xp": return (.rare, "icon-xp", "shippingbox")
        case "consumable": return (.uncommon, content.id, "shippingbox")
        case "item": return (.rare, content.id, "shippingbox")
        default: return (.common, nil, "shippingbox")
        }
    }

    private func rewardLabel(for content: OfferContent) -> String {
        let q = content.quantity
        if q >= 1_000_000 { return "×\(q / 1_000_000)M" }
        if q >= 10_000 { return "×\(q / 1_000)K" }
        return "×\(q)"
    }
}
