import SwiftUI

// MARK: - Redesigned Hub Character Card

struct HubCharacterCard: View {
    let character: Character
    var showCurrencies: Bool = true
    var showChevron: Bool = true
    var onUsePotion: (() -> Void)? = nil

    @Environment(AppState.self) private var appState

    // Animation state
    @State private var healFlash = false

    private var hpPercent: Double { character.hpPercentage }
    private var isFullHP: Bool { character.currentHp >= character.maxHp }
    private var isCriticalHP: Bool { hpPercent < 0.25 }

    // Count health potions from cached inventory
    private var healthPotionCount: Int {
        guard let items = appState.cachedInventory else { return 0 }
        return items
            .filter { $0.consumableType?.contains("health_potion") == true }
            .reduce(0) { $0 + ($1.quantity ?? 0) }
    }

    private func formatGold(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    var body: some View {
        HStack(spacing: LayoutConstants.classGridGap) {
            // MARK: Avatar with XP Ring
            avatarWithXPRing

            // MARK: Info Block
            VStack(alignment: .leading, spacing: 6) {
                // Name + Status
                nameAndStatusRow

                // HP Bar + Potion Button
                hpBarRow

                // Currencies
                if showCurrencies {
                    currencyRow
                }
            }

            // MARK: Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textDisabled)
                    .padding(.leading, LayoutConstants.space2XS)
            }
        }
        .padding(LayoutConstants.classGridGap)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                .fill(DarkFantasyTheme.bgCardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                .stroke(DarkFantasyTheme.bgCardBorder, lineWidth: 1)
        )
        // Heal flash overlay
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.modalRadius)
                .fill(DarkFantasyTheme.healFlash.opacity(healFlash ? 0.25 : 0))
                .allowsHitTesting(false)
        )
        .animation(.easeInOut(duration: 0.3), value: isFullHP)
    }

    // MARK: - Avatar with XP Ring

    private var avatarWithXPRing: some View {
        ZStack {
            // XP ring background
            Circle()
                .stroke(DarkFantasyTheme.xpRingTrack, lineWidth: 4)
                .frame(width: LayoutConstants.avatarRingSize, height: LayoutConstants.avatarRingSize)

            // XP ring fill
            Circle()
                .trim(from: 0, to: character.xpPercentage)
                .stroke(
                    DarkFantasyTheme.xpRing,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: LayoutConstants.avatarRingSize, height: LayoutConstants.avatarRingSize)
                .shadow(color: DarkFantasyTheme.xpRing.opacity(0.4), radius: 4)
                .animation(.easeInOut(duration: 1.0), value: character.xpPercentage)

            // Avatar image (circular)
            AvatarImageView(
                skinKey: character.avatar,
                characterClass: character.characterClass,
                size: LayoutConstants.avatarInnerSize
            )
            .clipShape(Circle())
            .frame(width: LayoutConstants.avatarInnerSize, height: LayoutConstants.avatarInnerSize)

            // Level badge (bottom center)
            VStack {
                Spacer()
                Text("Lv. \(character.level)")
                    .font(DarkFantasyTheme.body(size: 10).bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, LayoutConstants.space2XS)
                    .background(
                        Capsule()
                            .fill(DarkFantasyTheme.bgCardGradientVertical)
                    )
                    .overlay(
                        Capsule()
                            .stroke(DarkFantasyTheme.xpRing, lineWidth: 1)
                    )
                    .offset(y: 6)
            }
            .frame(width: LayoutConstants.avatarRingSize, height: LayoutConstants.avatarRingSize)
        }
        .frame(width: LayoutConstants.avatarRingSize, height: LayoutConstants.avatarRingOverflow)
    }

    // MARK: - Name + Status Row

    private var nameAndStatusRow: some View {
        HStack {
            Text(character.characterName)
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody).bold())
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text(statusText)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge).bold())
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .modifier(PulseModifier(active: isCriticalHP))
        }
    }

    private var statusText: String {
        if hpPercent >= 1.0 { return "Battle Ready" }
        if hpPercent >= 0.75 { return "Almost Ready" }
        if hpPercent >= 0.25 { return "Needs Healing" }
        return "Critical HP!"
    }

    private var statusColor: Color {
        if hpPercent >= 0.75 { return DarkFantasyTheme.textStatusGood }
        if hpPercent >= 0.25 { return DarkFantasyTheme.textWarning }
        return DarkFantasyTheme.textDanger
    }

    // MARK: - HP Bar Row

    private var hpBarRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // HP Bar with numbers inside
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 7)
                        .fill(DarkFantasyTheme.bgTertiary)

                    // Fill — uses canonical HP gradient (green → amber → red)
                    RoundedRectangle(cornerRadius: 7)
                        .fill(DarkFantasyTheme.canonicalHpGradient(percentage: hpPercent))
                        .frame(width: geo.size.width * max(0.02, min(1, hpPercent)))
                        .modifier(PulseModifier(active: isCriticalHP))

                    // HP text inside bar (hidden when full)
                    if !isFullHP {
                        Text("\(character.currentHp) / \(character.maxHp)")
                            .font(DarkFantasyTheme.body(size: 10).bold())
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .frame(maxWidth: .infinity)
                            .transition(.opacity)
                    }
                }
            }
            .frame(height: LayoutConstants.spaceMD)
            .animation(.easeInOut(duration: 0.8), value: hpPercent)

            // Potion button (only when HP < 100%)
            if !isFullHP {
                potionButton
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Potion Button

    private var potionButton: some View {
        Button {
            onUsePotion?()
            triggerHealFlash()
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(Color.clear)
                    .frame(width: LayoutConstants.buttonHeightSM, height: LayoutConstants.buttonHeightSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                            .stroke(
                                isCriticalHP ? DarkFantasyTheme.textDanger : DarkFantasyTheme.success,
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        Image(systemName: "cross.vial.fill")
                            .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                            .foregroundStyle(
                                healthPotionCount > 0
                                    ? (isCriticalHP ? DarkFantasyTheme.textDanger : DarkFantasyTheme.success)
                                    : DarkFantasyTheme.textDisabled
                            )
                    )
                    .modifier(PulseScaleModifier(active: isCriticalHP && healthPotionCount > 0))

                // Potion count badge
                if healthPotionCount > 0 {
                    Text("\(healthPotionCount)")
                        .font(DarkFantasyTheme.body(size: 9).bold())
                        .foregroundStyle(.white)
                        .frame(width: LayoutConstants.spaceMD, height: LayoutConstants.spaceMD)
                        .background(Circle().fill(DarkFantasyTheme.success))
                        .offset(x: LayoutConstants.spaceXS, y: -LayoutConstants.spaceXS)
                }
            }
        }
        .buttonStyle(.scalePress(0.9))
        .disabled(healthPotionCount == 0)
        .opacity(healthPotionCount == 0 ? 0.5 : 1.0)
    }

    // MARK: - Currency Row

    private var currencyRow: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            // Gold
            HStack(spacing: 5) {
                Image("icon-gold")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(formatGold(character.gold))
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .monospacedDigit()
            }

            // Gems
            HStack(spacing: 5) {
                Image("icon-gems")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("\(character.gems ?? 0)")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.cyan)
                    .monospacedDigit()
            }

            Spacer()
        }
    }

    // MARK: - Animations

    private func triggerHealFlash() {
        withAnimation(.easeIn(duration: 0.15)) { healFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) { healFlash = false }
        }
    }
}

// MARK: - Animation Modifiers

/// Pulsating opacity effect for critical HP text/bar
private struct PulseModifier: ViewModifier {
    let active: Bool
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .opacity(active ? (pulse ? 0.6 : 1.0) : 1.0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onChange(of: active) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                } else {
                    withAnimation { pulse = false }
                }
            }
    }
}

/// Pulsating scale effect for critical HP potion button
private struct PulseScaleModifier: ViewModifier {
    let active: Bool
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? (pulse ? 1.08 : 1.0) : 1.0)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onChange(of: active) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                } else {
                    withAnimation { pulse = false }
                }
            }
    }
}
