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
    /// "Don't show again" button (contextual hint mode — dismisses only this hint, not all)
    var onDontShowAgain: (() -> Void)? = nil

    // MARK: - Optional CTA Button
    /// Custom CTA button text (e.g. "Go to Shop")
    var ctaLabel: String? = nil
    /// Custom CTA action
    var onCTA: (() -> Void)? = nil

    // MARK: - Wheel Mode (Fortune Wheel custom content)
    /// Custom content builder replacing message + actions (e.g. wager section)
    /// When provided, plainMessage/attributedMessage/actions are ignored.
    var wheelContent: AnyView? = nil

    // MARK: - Customization
    /// SF Symbol fallback when NPC image asset is missing
    var npcFallbackIcon: String = "person.crop.circle.fill"
    /// Custom avatar size override (default: LayoutConstants.npcAvatarSize)
    var customAvatarSize: CGFloat? = nil
    /// Custom avatar vertical offset override (default: LayoutConstants.npcAvatarOffset)
    var customAvatarOffset: CGFloat? = nil
    /// Unique ID for message transition animation
    var messageId: AnyHashable? = nil
    /// Enable typewriter text animation (characters appear one by one)
    var typewriterEnabled: Bool = false
    /// Speed of typewriter animation (seconds per character)
    var typewriterSpeed: Double = 0.03
    /// Inline mode: compact layout with inline avatar (40×40), no gradient overlay, no peek-behind.
    /// Used by ContextualHintOverlay for first-visit hints. Full mode remains for onboarding/fortune wheel.
    var inlineMode: Bool = false

    // MARK: - State
    @State private var avatarBounce = false
    @State private var typewriterText: String = ""
    @State private var typewriterTask: Task<Void, Never>?
    @State private var typewriterDone = false

    /// Whether to use the player's dynamic avatar (AvatarImageView) instead of a static NPC image
    private var usesPlayerAvatar: Bool {
        avatarSkinKey != nil && avatarClass != nil
    }

    var body: some View {
        if inlineMode {
            // Inline mode: compact card with inline avatar, no gradient, no peek-behind
            inlineSpeechCard
        } else {
            // Full mode: gradient overlay + peek-behind NPC avatar (onboarding, fortune wheel)
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

                // Layer 1 (back): NPC/player image, bottom-left, peeks above card
                HStack(alignment: .bottom) {
                    npcAvatar
                        .offset(y: customAvatarOffset ?? LayoutConstants.npcAvatarOffset)
                    Spacer()
                }

                // Layer 2 (front): speech card widget
                speechCard
            }
        }
    }

    // MARK: - Speech Card

    @ViewBuilder
    private var speechCard: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Header row: NPC title + dismiss button
            // Figma: Header Row (HORIZONTAL, SPACE_BETWEEN)
            HStack {
                Text(npcTitle.uppercased())
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(2)

                Spacer()

                // Dismiss ✕ — Figma: Inter Bold 12, textTertiary
                // Hidden in Wheel state (per Figma State=Wheel has no dismiss)
                if wheelContent == nil {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(DarkFantasyTheme.body.bold())
                            .foregroundStyle(DarkFantasyTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let wheel = wheelContent {
                // Wheel mode: custom content replaces message + actions
                // Figma: State=Wheel → Wager Section
                wheel
            } else {
                // Standard mode: message + optional CTA + optional actions
                // Figma: State=Full → Message + Actions

                // Message text (with optional typewriter animation)
                // Full text is always rendered (hidden when typewriter active) to reserve layout height,
                // preventing the widget from growing as characters appear.
                ZStack(alignment: .topLeading) {
                    // Hidden full text — reserves the final height
                    Group {
                        if let attributed = attributedMessage {
                            Text(attributed)
                        } else if let plain = plainMessage {
                            Text(plain)
                        }
                    }
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .lineLimit(3)
                    .opacity(typewriterEnabled ? 0 : 1)

                    // Visible typewriter text — overlaid on top
                    if typewriterEnabled {
                        Text(typewriterText)
                            .font(DarkFantasyTheme.body)
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                            .lineLimit(3)
                    }
                }
                .id(messageId)
                .transition(.opacity)
                .onAppear {
                    if typewriterEnabled {
                        startTypewriter()
                    }
                }
                .onDisappear {
                    typewriterTask?.cancel()
                    typewriterTask = nil
                }

                // Optional CTA button (e.g. "Go to Shop")
                if let label = ctaLabel, let action = onCTA, (!typewriterEnabled || typewriterDone) {
                    Button {
                        action()
                    } label: {
                        Text(label)
                    }
                    .buttonStyle(.compactOutline(color: DarkFantasyTheme.gold))
                    .transition(.opacity)
                }

                // Optional action row (tutorial mode)
                // Figma: Actions → "Skip all" (textTertiary) + Continue (Wager Button/Selected)
                if onSkipAll != nil || onContinue != nil {
                    actionRow
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Figma: Speech Card — padding 12-16, cornerRadius 8, bgSecondary fill, borderMedium stroke w:1
        .padding(.horizontal, LayoutConstants.npcBarPaddingH)
        .padding(.vertical, LayoutConstants.npcBarPaddingV)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.panelRadius))
        // Prevent card height from animating when content changes (CTA appears, text loads)
        .transaction { t in t.animation = nil }
        .onTapGesture {
            onTapCard?()
        }
    }

    // MARK: - Action Row (Skip all + Continue / Don't show again)

    @ViewBuilder
    private var actionRow: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Spacer()

            if let skipAll = onSkipAll {
                Button {
                    skipAll()
                } label: {
                    Text("Skip all")
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.textSecondary))
            }

            if let dontShow = onDontShowAgain {
                Button {
                    dontShow()
                } label: {
                    Text("Don't show again")
                }
                .buttonStyle(.compactOutline(color: DarkFantasyTheme.textSecondary))
            }

            if let continueAction = onContinue {
                Button {
                    continueAction()
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.compactPrimary)
            }
        }
    }

    // MARK: - Inline Speech Card (compact, no gradient/peek)

    /// Compact version: inline avatar + speech card in one row, no gradient overlay.
    @ViewBuilder
    private var inlineSpeechCard: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Header: inline avatar + NPC name + dismiss
            HStack(spacing: LayoutConstants.spaceSM) {
                // Inline NPC avatar (40×40)
                inlineAvatar

                Text(npcTitle.uppercased())
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(2)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("✕")
                        .font(DarkFantasyTheme.body.bold())
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }

            // Message (no typewriter — shown immediately)
            Group {
                if let attributed = attributedMessage {
                    Text(attributed)
                } else if let plain = plainMessage {
                    Text(plain)
                }
            }
            .font(DarkFantasyTheme.body)
            .foregroundStyle(DarkFantasyTheme.textSecondary)
            .lineLimit(3)

            // Actions row: CTA + "Don't show again"
            HStack(spacing: LayoutConstants.spaceSM) {
                Spacer()

                if let dontShow = onDontShowAgain {
                    Button {
                        dontShow()
                    } label: {
                        Text("Don't show again")
                    }
                    .buttonStyle(.compactOutline(color: DarkFantasyTheme.textSecondary))
                }

                if let label = ctaLabel, let action = onCTA {
                    Button {
                        action()
                    } label: {
                        Text(label)
                    }
                    .buttonStyle(.compactPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutConstants.npcBarPaddingH)
        .padding(.vertical, LayoutConstants.npcBarPaddingV)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(DarkFantasyTheme.borderMedium, lineWidth: 1)
        )
    }

    // MARK: - Inline Avatar (40×40, for inline mode)

    @ViewBuilder
    private var inlineAvatar: some View {
        Group {
            if usesPlayerAvatar {
                AvatarImageView(
                    skinKey: avatarSkinKey,
                    characterClass: avatarClass ?? .warrior,
                    size: 40
                )
            } else if let imageName = npcImageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.bgTertiary)
                        .overlay(
                            Circle()
                                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: npcFallbackIcon)
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Typewriter Animation

    private func startTypewriter() {
        let fullText = plainMessage ?? ""
        guard !fullText.isEmpty else { return }
        typewriterText = ""
        typewriterDone = false
        let chars = Array(fullText)
        let speed = typewriterSpeed
        typewriterTask?.cancel()
        typewriterTask = Task { @MainActor in
            for char in chars {
                try? await Task.sleep(for: .seconds(speed))
                guard !Task.isCancelled else { return }
                typewriterText.append(char)
            }
            withAnimation(MotionConstants.smooth) {
                typewriterDone = true
            }
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
                    // Dynamic player character avatar — no circle clip, peeks out like static NPCs
                    AvatarImageView(
                        skinKey: avatarSkinKey,
                        characterClass: avatarClass ?? .warrior,
                        size: customAvatarSize ?? LayoutConstants.npcAvatarSize
                    )
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
                            .font(DarkFantasyTheme.title)
                            .foregroundStyle(DarkFantasyTheme.goldBright)
                    }
                    .frame(width: 60, height: 60)
                }
            }
            .frame(
                width: customAvatarSize ?? LayoutConstants.npcAvatarSize,
                height: customAvatarSize ?? LayoutConstants.npcAvatarSize
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
                        size: LayoutConstants.touchComfortable
                    )
                } else if let imageName = npcImageName, UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(DarkFantasyTheme.title)
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }
            }
            .frame(
                width: LayoutConstants.touchComfortable,
                height: LayoutConstants.touchComfortable
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
