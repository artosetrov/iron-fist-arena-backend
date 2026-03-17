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
            }
        }
        .padding(LayoutConstants.spaceSM)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                .stroke(toast.type.color.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}
