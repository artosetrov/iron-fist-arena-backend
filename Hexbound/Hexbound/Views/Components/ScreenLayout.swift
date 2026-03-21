import SwiftUI

// MARK: - Hub Logo Button (Unified back navigation)

struct HubLogoButton: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            if !appState.mainPath.isEmpty {
                appState.mainPath.removeLast()
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
