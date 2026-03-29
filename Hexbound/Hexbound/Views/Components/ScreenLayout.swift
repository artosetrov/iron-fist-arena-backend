import SwiftUI

// MARK: - Hub Logo Button (Unified back navigation)

struct HubLogoButton: View {
    @Environment(AppState.self) private var appState
    /// Optional custom action. When nil, pops `mainPath` by default.
    var action: (() -> Void)?

    var body: some View {
        Button {
            SFXManager.shared.play(.uiBack)
            if let action {
                action()
            } else if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast(1)
            }
        } label: {
            Image("ui-arrow-left")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: LayoutConstants.touchMin, minHeight: LayoutConstants.touchMin)
        .accessibilityLabel("Go back")
    }
}

// MARK: - Screen Layout (uses HubLogoButton)

struct ScreenLayout<Content: View>: View {
    let title: String
    let content: Content
    @Environment(AppState.self) private var appState

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()
            content
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
    }
}
