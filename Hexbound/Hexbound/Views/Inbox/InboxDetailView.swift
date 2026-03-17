import SwiftUI

struct InboxDetailView: View {
    @State private var viewModel = InboxViewModel()
    @Environment(\.dismiss) var dismiss
    
    let characterId: String
    
    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Inbox")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DarkFantasyTheme.textPrimary)
                    
                    Spacer()
                    
                    if viewModel.unreadCount > 0 {
                        Badge(count: viewModel.unreadCount)
                    }
                }
                .padding(.horizontal, LayoutConstants.padding)
                .padding(.vertical, LayoutConstants.paddingMedium)
                
                Divider()
                    .foregroundColor(DarkFantasyTheme.surfaceLight)
                
                // Content
                if viewModel.isLoading && viewModel.messages.isEmpty {
                    VStack(spacing: LayoutConstants.paddingMedium) {
                        ProgressView()
                            .tint(DarkFantasyTheme.accent)
                        
                        Text("Loading mail...")
                            .foregroundColor(DarkFantasyTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DarkFantasyTheme.background)
                } else if viewModel.messages.isEmpty {
                    EmptyMailState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DarkFantasyTheme.background)
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
                    .background(DarkFantasyTheme.background)
                    .refreshable {
                        await viewModel.fetchInbox(characterId: characterId)
                    }
                }
                
                if let error = viewModel.error {
                    ErrorBanner(message: error)
                        .padding(LayoutConstants.padding)
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
        VStack(spacing: LayoutConstants.paddingLarge) {
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
                .padding(.horizontal, LayoutConstants.paddingLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DarkFantasyTheme.background)
    }
}

// MARK: - Badge
private struct Badge: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(DarkFantasyTheme.accent)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DarkFantasyTheme.background)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Error Banner
private struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: LayoutConstants.padding) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(DarkFantasyTheme.gold)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(DarkFantasyTheme.textPrimary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(LayoutConstants.paddingMedium)
        .background(DarkFantasyTheme.surface)
        .cornerRadius(8)
    }
}

#Preview {
    InboxDetailView(characterId: "char-123")
}
