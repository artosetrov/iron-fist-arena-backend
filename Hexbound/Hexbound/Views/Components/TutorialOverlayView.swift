import SwiftUI

/// Full-screen tutorial overlay with dimmed background, spotlight cutout, and NPC dialog.
/// Used for the hard guided tutorial (first 3-5 minutes of gameplay).
struct TutorialOverlayView: View {
    let npcMessage: String
    let ctaLabel: String?
    let secondaryLabel: String?
    let spotlightRect: CGRect?
    let onCTA: (() -> Void)?
    let onSecondary: (() -> Void)?
    let onTapAnywhere: (() -> Void)?

    @State private var showContent = false
    @State private var typewriterText = ""
    @State private var typewriterTask: Task<Void, Never>?

    init(
        npcMessage: String,
        ctaLabel: String? = nil,
        secondaryLabel: String? = nil,
        spotlightRect: CGRect? = nil,
        onCTA: (() -> Void)? = nil,
        onSecondary: (() -> Void)? = nil,
        onTapAnywhere: (() -> Void)? = nil
    ) {
        self.npcMessage = npcMessage
        self.ctaLabel = ctaLabel
        self.secondaryLabel = secondaryLabel
        self.spotlightRect = spotlightRect
        self.onCTA = onCTA
        self.onSecondary = onSecondary
        self.onTapAnywhere = onTapAnywhere
    }

    var body: some View {
        ZStack {
            // Dimmed background with optional spotlight cutout
            spotlightBackground
                .ignoresSafeArea()
                .onTapGesture {
                    onTapAnywhere?()
                }

            // NPC dialog at bottom
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()

                npcDialogCard
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 40)

                // Buttons
                if ctaLabel != nil || secondaryLabel != nil {
                    buttonRow
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .opacity(showContent ? 1 : 0)
                }

                Spacer()
                    .frame(height: LayoutConstants.space2XL)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showContent = true
            }
            startTypewriter()
        }
        .onDisappear {
            typewriterTask?.cancel()
        }
    }

    // MARK: - Spotlight Background

    @ViewBuilder
    private var spotlightBackground: some View {
        if let rect = spotlightRect {
            Canvas { context, size in
                // Fill entire area with dark overlay
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(Color.black.opacity(0.75))
                )
                // Cut out spotlight area with rounded rect
                let spotlightPath = Path(roundedRect: rect.insetBy(dx: -8, dy: -8),
                                         cornerRadius: LayoutConstants.radiusMD)
                context.blendMode = .destinationOut
                context.fill(spotlightPath, with: .color(.white))
            }
            .compositingGroup()
        } else {
            Color.black.opacity(0.75)
        }
    }

    // MARK: - NPC Dialog

    private var npcDialogCard: some View {
        HStack(alignment: .top, spacing: LayoutConstants.spaceSM) {
            // NPC avatar
            Image("shopkeeper")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DarkFantasyTheme.gold, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("КАЭЛЬ")
                    .font(DarkFantasyTheme.uiLabel)
                    .foregroundStyle(DarkFantasyTheme.gold)

                Text(typewriterText)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(LayoutConstants.spaceMD)
        .background(DarkFantasyTheme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.radiusLG)
                .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Buttons

    private var buttonRow: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            if let label = ctaLabel, let action = onCTA {
                Button(action: action) {
                    Text(label)
                        .font(DarkFantasyTheme.buttonLabel)
                        .textCase(.uppercase)
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            if let label = secondaryLabel, let action = onSecondary {
                Button(action: action) {
                    Text(label)
                        .font(DarkFantasyTheme.caption)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Typewriter

    private func startTypewriter() {
        typewriterText = ""
        typewriterTask?.cancel()
        typewriterTask = Task { @MainActor in
            for char in npcMessage {
                if Task.isCancelled { break }
                typewriterText.append(char)
                try? await Task.sleep(nanoseconds: 25_000_000) // 25ms per char
            }
        }
    }
}
