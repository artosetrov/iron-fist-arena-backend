import SwiftUI

/// Persistent banner shown when the device has no network connection.
/// Place at the top of the main app overlay (similar to ToastOverlayView).
struct OfflineBannerView: View {
    @State private var isVisible = false

    var body: some View {
        if !NetworkMonitor.shared.isConnected {
            HStack(spacing: LayoutConstants.spaceSM) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)

                Text("NO CONNECTION")
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textOnGold)

                Spacer()

                Text("Some features may not work")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textOnGold.opacity(0.8))
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
            .padding(.vertical, LayoutConstants.spaceSM)
            .background(DarkFantasyTheme.danger)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = true
                }
            }
        }
    }
}
