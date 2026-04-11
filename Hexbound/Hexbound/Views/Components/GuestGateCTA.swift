import SwiftUI

/// Unified guest gating banner — single source of truth for prompting
/// guest users to create an account. Replaces ad-hoc inline banners.
///
/// **Dynamic CTA copy (loss-aversion psychology):**
/// - `hasProgress == false` → "Playing as Guest" / **CREATE ACCOUNT**
/// - `hasProgress == true`  → "Save Your Progress!" / **SAVE MY PROGRESS**
///
/// **Variants:**
/// - `.prominent` — full card with vertical layout and full-width CTA.
///   Used on the character selection / onboarding screen where guest
///   gating is the primary conversion moment.
/// - `.soft` — compact inline nudge with inline pill CTA and dismiss
///   button. Used in-hub as a gentle reminder after level 3+.
///
/// Does NOT compete with a bottom gold primary CTA — uses a tonal
/// background with inner border rather than a full gold fill, so the
/// screen's primary action remains visually dominant.
struct GuestGateCTA: View {
    enum Variant {
        case prominent
        case soft
    }

    let variant: Variant
    let hasProgress: Bool
    let onSignUp: () -> Void
    var onDismiss: (() -> Void)? = nil

    @State private var dismissed = false

    // MARK: - Dynamic Copy

    private var title: String {
        hasProgress ? "Save Your Progress!" : "Playing as Guest"
    }

    private var subtitle: String {
        hasProgress
            ? "Don't lose your heroes. Create an account to keep them forever."
            : "Sign up to save heroes, unlock shop, and keep progress across devices."
    }

    private var ctaLabel: String {
        hasProgress ? "SAVE MY PROGRESS" : "CREATE ACCOUNT"
    }

    // MARK: - Body

    var body: some View {
        if variant == .soft && dismissed {
            EmptyView()
        } else {
            Group {
                switch variant {
                case .prominent:
                    prominentBody
                case .soft:
                    softBody
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Prominent Variant

    private var prominentBody: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
                iconBadge

                VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                    Text(title)
                        .font(DarkFantasyTheme.body.weight(.semibold))
                        .foregroundStyle(DarkFantasyTheme.goldBright)

                    Text(subtitle)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                HapticManager.medium()
                SFXManager.shared.play(.uiTap)
                onSignUp()
            } label: {
                Text(ctaLabel)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.compactPrimary)
        }
        .padding(LayoutConstants.spaceMD)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.gold.opacity(0.08),
                glowIntensity: 0.5,
                cornerRadius: LayoutConstants.cardRadius
            )
        )
        .innerBorder(
            cornerRadius: LayoutConstants.cardRadius - 2,
            inset: 2,
            color: DarkFantasyTheme.gold.opacity(0.12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Soft Variant

    private var softBody: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            iconBadge

            VStack(alignment: .leading, spacing: LayoutConstants.space2XS) {
                Text(title)
                    .font(DarkFantasyTheme.body.weight(.semibold))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                Text(subtitle)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: LayoutConstants.spaceXS)

            Button {
                HapticManager.medium()
                SFXManager.shared.play(.uiTap)
                onSignUp()
            } label: {
                Text(ctaLabel)
                    .font(DarkFantasyTheme.buttonLabelCompact)
                    .tracking(0.8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.compactPrimary)

            if onDismiss != nil {
                Button {
                    withAnimation { dismissed = true }
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .frame(width: LayoutConstants.iconLG, height: LayoutConstants.iconLG)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Icon Badge

    private var iconBadge: some View {
        Image("icon-padlock")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: LayoutConstants.iconXL, height: LayoutConstants.iconXL)
    }
}

// MARK: - Previews

#Preview("Prominent · No progress") {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        GuestGateCTA(
            variant: .prominent,
            hasProgress: false,
            onSignUp: {}
        )
        .padding(LayoutConstants.spaceMD)
    }
}

#Preview("Prominent · Has progress") {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        GuestGateCTA(
            variant: .prominent,
            hasProgress: true,
            onSignUp: {}
        )
        .padding(LayoutConstants.spaceMD)
    }
}

#Preview("Soft · Dismissible") {
    ZStack {
        DarkFantasyTheme.bgPrimary.ignoresSafeArea()
        GuestGateCTA(
            variant: .soft,
            hasProgress: true,
            onSignUp: {},
            onDismiss: {}
        )
        .padding(LayoutConstants.spaceMD)
    }
}
