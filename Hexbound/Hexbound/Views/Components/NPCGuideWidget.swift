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

    // MARK: - Customization
    /// SF Symbol fallback when NPC image asset is missing
    var npcFallbackIcon: String = "person.crop.circle.fill"
    /// Unique ID for message transition animation
    var messageId: AnyHashable? = nil

    // MARK: - State
    @State private var avatarBounce = false

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
        HStack(spacing: LayoutConstants.spaceSM) {
            VStack(alignment: .leading, spacing: 4) {
                // NPC title (gold)
                Text(npcTitle.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.goldBright)

                // Message text
                Group {
                    if let attributed = attributedMessage {
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

                // Optional action row (tutorial mode)
                if onSkipAll != nil || onContinue != nil {
                    actionRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Dismiss X button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.closeButton)
        }
        .padding(.horizontal, LayoutConstants.npcBarPaddingH)
        .padding(.vertical, LayoutConstants.npcBarPaddingV)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius)
                .fill(DarkFantasyTheme.bgElevated.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius)
                .stroke(DarkFantasyTheme.borderOrnament, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: LayoutConstants.npcBarRadius))
        .onTapGesture {
            onTapCard?()
        }
    }

    // MARK: - Action Row (Skip all + Continue)

    @ViewBuilder
    private var actionRow: some View {
        HStack {
            if let skipAll = onSkipAll {
                Button {
                    skipAll()
                } label: {
                    Text("Skip all tips")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .buttonStyle(.ghost)
            }

            Spacer()

            if let continueAction = onContinue {
                Button {
                    HapticManager.light()
                    continueAction()
                } label: {
                    Text("Continue")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.vertical, LayoutConstants.spaceXS + 2)
                        .background(
                            Capsule().fill(DarkFantasyTheme.gold)
                        )
                }
                .buttonStyle(.scalePress(0.9))
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
                    // Dynamic player character avatar
                    AvatarImageView(
                        skinKey: avatarSkinKey,
                        characterClass: avatarClass!,
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
                        characterClass: avatarClass!,
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
