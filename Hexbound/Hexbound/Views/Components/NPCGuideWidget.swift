import SwiftUI

// MARK: - Unified NPC Guide Widget

/// Single reusable NPC guide widget for ALL screens: shop, arena, tutorials, dungeon, etc.
/// Replaces both `MerchantStripView` and `TutorialTooltipView` with one consistent component.
///
/// Layout (ZStack):
/// ┌─────────────────────────────────────────────┐
/// │ [NPC Image]  TITLE              [X]         │
/// │              Message text here...            │
/// │              [Skip all]     [Continue]       │
/// └─────────────────────────────────────────────┘
///   NPC image peeks out from bottom-left behind card.
///
/// Avatar modes:
/// - Static asset: pass `npcImageName` (e.g. "shopkeeper")
/// - Player character: pass `avatarSkinKey` + `avatarClass` to use `AvatarImageView`
@MainActor
struct NPCGuideWidget: View {
    // MARK: - Required
    let npcTitle: String
    let onDismiss: () -> Void

    // MARK: - Avatar (provide ONE mode)
    /// Static NPC image asset name (e.g. "shopkeeper", "npc-arena-master")
    var npcImageName: String? = nil
    /// Player character avatar — skinKey + class for AvatarImageView
    var avatarSkinKey: String? = nil
    var avatarClass: CharacterClass? = nil

    // MARK: - Content (provide ONE)
    /// Attributed text (for shop tips with colored segments)
    var attributedMessage: AttributedString? = nil
    /// Plain text (for tutorials / simple messages)
    var plainMessage: String? = nil

    // MARK: - Optional Actions
    /// Tap the card body (e.g. cycle to next tip)
    var onTapCard: (() -> Void)? = nil
    /// "Skip all tips" button (tutorial mode)
    var onSkipAll: (() -> Void)? = nil
    /// "Continue" button (tutorial mode)
    var onContinue: (() -> Void)? = nil

    // MARK: - Optional CTA Button
    /// Custom CTA button text (e.g. "Go to Shop")
    var ctaLabel: String? = nil
    /// Custom CTA action
    var onCTA: (() -> Void)? = nil

    // MARK: - Customization
    /// SF Symbol fallback when NPC image asset is missing
    var npcFallbackIcon: String = "person.crop.circle.fill"
    /// Unique ID for message transition animation
    var messageId: AnyHashable? = nil
    /// Enable typewriter text animation (characters appear one by one)
    var typewriterEnabled: Bool = false
    /// Speed of typewriter animation (seconds per character)
    var typewriterSpeed: Double = 0.03

    // MARK: - State
    @State private var avatarBounce = false
    @State private var typewriterText: String = ""
    @State private var typewriterTimer: Timer?
    @State private var typewriterDone = false

    /// Whether to use the player's dynamic avatar (AvatarImageView) instead of a static NPC image
    private var usesPlayerAvatar: Bool {
        avatarSkinKey != nil && avatarClass != nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Layer 0: dark-to-transparent fade behind the whole widget
            LinearGradient(
                colors: [
                    Color.clear,
                    DarkFantasyTheme.bgAbyss.opacity(0.6),
                    DarkFantasyTheme.bgAbyss.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Layer 1 (back): NPC/player image, bottom-left, peeks out behind card
            HStack(alignment: .bottom) {
                npcAvatar
                    .offset(y: LayoutConstants.npcAvatarOffset)
                Spacer()
            }

            // Layer 2 (front): speech card widget
            speechCard
        }
    }

    // MARK: - Speech Card

    @ViewBuilder
    private var speechCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                // NPC title (gold)
                Text(npcTitle.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .padding(.trailing, 32) // space for X button

                // Message text (with optional typewriter animation)
                Group {
                    if typewriterEnabled {
                        Text(typewriterText)
                    } else if let attributed = attributedMessage {
                        Text(attributed)
                    } else if let plain = plainMessage {
                        Text(plain)
                    }
                }
                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .lineLimit(3)
                .id(messageId)
                .transition(.opacity)
                .onAppear {
                    if typewriterEnabled {
                        startTypewriter()
                    }
                }
                .onDisappear {
                    typewriterTimer?.invalidate()
                    typewriterTimer = nil
                }

                // Optional CTA button (e.g. "Go to Shop")
                if let label = ctaLabel, let action = onCTA, (!typewriterEnabled || typewriterDone) {
                    Button {
                        HapticManager.light()
                        action()
                    } label: {
                        HStack(spacing: LayoutConstants.spaceXS) {
                            Text(label)
                                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textOnGold)
                        }
                        .padding(.horizontal, LayoutConstants.spaceLG)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(Capsule().fill(DarkFantasyTheme.gold))
                    }
                    .buttonStyle(.scalePress(0.9))
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                // Optional action row (tutorial mode)
                if onSkipAll != nil || onContinue != nil {
                    actionRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Dismiss X button — top-right corner
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(DarkFantasyTheme.bgTertiary.opacity(0.6))
                    )
                    .overlay(
                        Circle()
                            .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LayoutConstants.npcBarPaddingH)
        .padding(.vertical, LayoutConstants.npcBarPaddingV)
        .frame(maxWidth: .infinity)
        .background(
            RadialGlowBackground(
                baseColor: DarkFantasyTheme.bgSecondary,
                glowColor: DarkFantasyTheme.bgTertiary,
                glowIntensity: 0.4,
                cornerRadius: LayoutConstants.npcBarRadius
            )
        )
        .surfaceLighting(cornerRadius: LayoutConstants.npcBarRadius, topHighlight: 0.08, bottomShadow: 0.12)
        .innerBorder(cornerRadius: LayoutConstants.npcBarRadius - 2, inset: 2, color: DarkFantasyTheme.borderMedium.opacity(0.15))
        .cornerBrackets(color: DarkFantasyTheme.gold.opacity(0.3), length: 14, thickness: 1.5)
        .compositingGroup()
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 6, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius))
        .onTapGesture {
            onTapCard?()
        }
    }

    // MARK: - Action Row (Skip all + Continue)

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Spacer()

            if let skipAll = onSkipAll {
                Button {
                    skipAll()
                } label: {
                    Text("Skip all")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            if let continueAction = onContinue {
                Button {
                    HapticManager.light()
                    continueAction()
                } label: {
                    Text("Continue")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceLG)
                        .padding(.vertical, LayoutConstants.spaceSM)
                        .background(
                            Capsule().fill(DarkFantasyTheme.gold)
                        )
                }
                .buttonStyle(.scalePress(0.9))
            }
        }
    }

    // MARK: - Typewriter Animation

    private func startTypewriter() {
        let fullText = plainMessage ?? ""
        guard !fullText.isEmpty else { return }
        typewriterText = ""
        typewriterDone = false
        var charIndex = 0
        let chars = Array(fullText)
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: typewriterSpeed, repeats: true) { timer in
            guard charIndex < chars.count else {
                timer.invalidate()
                typewriterTimer = nil
                withAnimation(.easeInOut(duration: 0.3)) {
                    typewriterDone = true
                }
                return
            }
            typewriterText.append(chars[charIndex])
            charIndex += 1
        }
    }

    // MARK: - NPC Avatar

    @ViewBuilder
    private var npcAvatar: some View {
        Button {
            avatarBounce = true
            onTapCard?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                avatarBounce = false
            }
        } label: {
            Group {
                if usesPlayerAvatar {
                    // Dynamic player character avatar
                    AvatarImageView(
                        skinKey: avatarSkinKey,
                        characterClass: avatarClass ?? .warrior,
                        size: LayoutConstants.npcAvatarSize
                    )
                    .clipShape(Circle())
                } else if let imageName = npcImageName, UIImage(named: imageName) != nil {
                    // Static NPC asset image
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                } else {
                    // Fallback: themed circle with icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [DarkFantasyTheme.bgTertiary, DarkFantasyTheme.bgSecondary],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(DarkFantasyTheme.gold.opacity(0.5), lineWidth: 2)
                            )
                        Image(systemName: npcFallbackIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .frame(width: 60, height: 60)
                }
            }
            .frame(
                width: LayoutConstants.npcAvatarSize,
                height: LayoutConstants.npcAvatarSize
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.5), radius: 8, y: 2)
        }
        .buttonStyle(.scalePress)
    }
}

// MARK: - NPC Mini Button (Collapsed State)

/// Floating circular NPC avatar button shown when the guide widget is collapsed.
/// Supports both static NPC image and dynamic player avatar.
struct NPCMiniButton: View {
    /// Static NPC image name (e.g. "shopkeeper")
    var npcImageName: String? = nil
    /// Player character avatar — skinKey + class for AvatarImageView
    var avatarSkinKey: String? = nil
    var avatarClass: CharacterClass? = nil

    let onTap: () -> Void

    @State private var bouncing = false

    private var usesPlayerAvatar: Bool {
        avatarSkinKey != nil && avatarClass != nil
    }

    var body: some View {
        Button(action: onTap) {
            Group {
                if usesPlayerAvatar {
                    AvatarImageView(
                        skinKey: avatarSkinKey,
                        characterClass: avatarClass ?? .warrior,
                        size: LayoutConstants.merchantMiniSize
                    )
                } else if let imageName = npcImageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(
                width: LayoutConstants.merchantMiniSize,
                height: LayoutConstants.merchantMiniSize
            )
            .clipShape(Circle())
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DarkFantasyTheme.bgCardGradientStart, DarkFantasyTheme.bgTertiary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 3)
            )
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.6), radius: 8, y: 2)
            .shadow(color: DarkFantasyTheme.goldGlow.opacity(0.5), radius: 10)
        }
        .buttonStyle(.plain)
        .offset(y: bouncing ? -3 : 0)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                bouncing = true
            }
        }
    }
}
