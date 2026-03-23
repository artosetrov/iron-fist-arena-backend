import SwiftUI

struct InboxDetailView: View {
    @State private var viewModel = InboxViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) private var appState

    private var characterId: String {
        appState.currentCharacter?.id ?? ""
    }
    
    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Content
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    VStack(spacing: LayoutConstants.spaceMD) {
                        ProgressView()
                            .tint(DarkFantasyTheme.gold)
                        
                        Text("Loading mail...")
                            .foregroundColor(DarkFantasyTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DarkFantasyTheme.bgPrimary)
                } else if viewModel.messages.isEmpty {
                    EmptyMailState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DarkFantasyTheme.bgPrimary)
                } else {
                    List {
                        ForEach(viewModel.messages) { message in
                            InboxRowView(message: message, viewModel: viewModel, characterId: characterId)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(DarkFantasyTheme.bgPrimary)
                    .refreshable {
                        await viewModel.fetchInbox(characterId: characterId)
                    }
                }
                
                if let error = viewModel.error {
                    ErrorBanner(message: error)
                        .padding(LayoutConstants.spaceMD)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("INBOX")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    if viewModel.unreadCount > 0 {
                        Badge(count: viewModel.unreadCount)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchInbox(characterId: characterId)
        }
    }
}

// MARK: - Empty State
private struct EmptyMailState: View {
    var body: some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundColor(DarkFantasyTheme.textSecondary)
            
            Text("No Messages")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DarkFantasyTheme.textPrimary)
            
            Text("Your inbox is empty. Check back later for messages, rewards, and notifications.")
                .font(.system(size: 14))
                .foregroundColor(DarkFantasyTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.spaceLG)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DarkFantasyTheme.bgPrimary)
    }
}

// MARK: - Badge
private struct Badge: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.gold)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DarkFantasyTheme.bgPrimary)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Error Banner
private struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(DarkFantasyTheme.gold)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(DarkFantasyTheme.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(LayoutConstants.spaceMD)
        .background(DarkFantasyTheme.bgSecondary)
        .cornerRadius(LayoutConstants.radiusMD)
    }
}

#Preview {
    InboxDetailView()
}
