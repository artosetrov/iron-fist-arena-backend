import SwiftUI

struct ToastOverlayView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            ForEach(appState.toasts.prefix(3)) { toast in
                ToastView(toast: toast)
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

    var body: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Circle()
                .fill(toast.type.color)
                .frame(width: 8, height: 8)
                .shadow(color: toast.type.color.opacity(0.6), radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                if !toast.subtitle.isEmpty {
                    Text(toast.subtitle)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }

            Spacer()

            if let label = toast.actionLabel, let action = toast.action {
                Button {
                    action()
                } label: {
                    Text(label)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textOnGold)
                        .padding(.horizontal, LayoutConstants.spaceSM)
                        .padding(.vertical, LayoutConstants.spaceXS)
                        .background(
                            Capsule().fill(toast.type.color)
                        )
                }
                .buttonStyle(.scalePress(0.9))
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
        .shadow(color: toast.type.color.opacity(0.15), radius: 6, y: 0)
        .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.4), radius: 8, y: 4)
        .accessibilityLabel("\(toast.title): \(toast.subtitle)")
        .accessibilityElement(children: .combine)
    }
}
