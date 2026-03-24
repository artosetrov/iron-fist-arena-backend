import SwiftUI

struct ToastOverlayView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Show only 1 toast at a time (queue managed by AppState)
            ForEach(appState.toasts.prefix(1)) { toast in
                ToastView(toast: toast, onDismiss: {
                    appState.dismissToast(toast.id)
                })
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.top, LayoutConstants.spaceSM)
        .animation(.easeOut(duration: 0.3), value: appState.toasts.count)
    }
}

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            // Type icon in tinted container (replaces 8px dot — a11y: color + icon + text)
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(toast.type.color.opacity(0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: toast.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(toast.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .lineLimit(2)

                if !toast.subtitle.isEmpty {
                    Text(toast.subtitle)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let label = toast.actionLabel, let action = toast.action {
                Button {
                    action()
                    onDismiss()
                } label: {
                    Text(label)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge).bold())
                        .foregroundStyle(toast.type.color)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .frame(minHeight: 32) // Touch target compliance
                        .background(
                            Capsule()
                                .fill(toast.type.color.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
                // Subtle radial tint from toast type color
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(
                        RadialGradient(
                            colors: [toast.type.color.opacity(0.06), .clear],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
            }
        )
        .innerBorder(
            cornerRadius: LayoutConstants.panelRadius - 2,
            inset: 2,
            color: toast.type.color.opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(toast.type.color.opacity(0.5), lineWidth: 1)
        )
        // Swipe handle hint
        .overlay(alignment: .top) {
            Capsule()
                .fill(DarkFantasyTheme.textTertiary.opacity(0.3))
                .frame(width: 24, height: 3)
                .padding(.top, 4)
        }
        .shadow(color: toast.type.color.opacity(0.15), radius: 6, y: 0)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 8, y: 4)
        // Swipe up to dismiss
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow upward drag
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -30 {
                        // Dismiss
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = -100
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .accessibilityLabel("\(toast.title): \(toast.subtitle)")
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityHint("Swipe up to dismiss")
    }
}
