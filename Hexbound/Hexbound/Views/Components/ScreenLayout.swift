import SwiftUI

// MARK: - Hub Logo Button (Unified back-to-hub navigation)

struct HubLogoButton: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.mainPath = NavigationPath()
        } label: {
            Image("hexbound-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(minWidth: LayoutConstants.touchMin, minHeight: LayoutConstants.touchMin)
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
