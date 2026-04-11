import SwiftUI

// MARK: - Referral Section (Settings)

/// Displays referral code, share button, and "enter friend's code" input.
/// Fetches referral data from TutorialManager on appear.
struct ReferralSectionView: View {
    @Environment(AppState.self) private var appState

    @State private var referralCode: String?
    @State private var referralCount: Int = 0
    @State private var qualifiedCount: Int = 0
    @State private var maxReferrals: Int = 20
    @State private var alreadyReferred: Bool = false
    @State private var loadFailed: Bool = false

    @State private var friendCode: String = ""
    @State private var isApplying: Bool = false
    @State private var applyResult: ApplyResult?

    enum ApplyResult {
        case success(bonusGold: Int)
        case alreadyReferred
        case invalidCode
        case error(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            // Section header
            Text("Invite Friends")
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.gold)

            // My referral code + share
            if let code = referralCode {
                myCodeRow(code)
            } else if loadFailed {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Text("Could not load referral code")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                    Spacer()
                    Button("Retry") {
                        loadFailed = false
                        Task { await loadReferralData() }
                    }
                    .buttonStyle(.ghost)
                }
            } else {
                HStack {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                    Text("Loading...")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }

            // Stats
            if referralCount > 0 {
                statsRow
            }

            // Divider
            DarkFantasyTheme.borderSubtle.opacity(0.3)
                .frame(height: 1)
                .padding(.vertical, LayoutConstants.spaceXS)

            // Enter friend's code
            if !alreadyReferred {
                friendCodeInput
            } else {
                HStack(spacing: LayoutConstants.spaceXS) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DarkFantasyTheme.success)
                    Text("Referred by a friend")
                        .font(DarkFantasyTheme.body)
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
            }
        }
        .task { await loadReferralData() }
    }

    // MARK: - My Code Row

    @ViewBuilder
    private func myCodeRow(_ code: String) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text("Your invite code:")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            HStack(spacing: LayoutConstants.spaceSM) {
                // Code display
                Text(code)
                    .font(DarkFantasyTheme.cardTitle)
                    .foregroundStyle(DarkFantasyTheme.goldBright)
                    .tracking(3)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                    .stroke(DarkFantasyTheme.gold.opacity(0.3), lineWidth: 1)
                            )
                    )

                Spacer()

                // Share button
                Button {
                    HapticManager.selection()
                    SFXManager.shared.play(.uiTap)
                    shareReferralCode(code)
                } label: {
                    HStack(spacing: LayoutConstants.spaceXS) {
                        Image(systemName: "square.and.arrow.up")
                        Text("SHARE")
                    }
                }
                .buttonStyle(.compactPrimary)
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: LayoutConstants.spaceMD) {
            statPill(
                label: "Invited",
                value: "\(referralCount)/\(maxReferrals)",
                color: DarkFantasyTheme.gold
            )
            statPill(
                label: "Lv5+",
                value: "\(qualifiedCount)",
                color: DarkFantasyTheme.success
            )
        }
    }

    @ViewBuilder
    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: LayoutConstants.space2XS) {
            Text(value)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(color)
            Text(label)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        }
    }

    // MARK: - Friend Code Input

    private var friendCodeInput: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
            Text("Have a friend's code?")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            HStack(spacing: LayoutConstants.spaceSM) {
                TextField("Enter code", text: $friendCode)
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textPrimary)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.vertical, LayoutConstants.spaceSM)
                    .background(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .fill(DarkFantasyTheme.bgTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                                    .stroke(
                                        applyResult.isError ? DarkFantasyTheme.danger.opacity(0.6) : DarkFantasyTheme.borderSubtle.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    )

                Button {
                    Task { await applyFriendCode() }
                } label: {
                    Text("APPLY")
                }
                .buttonStyle(.compactPrimary)
                .disabled(friendCode.count < 4 || isApplying)
            }

            // Result message
            if let result = applyResult {
                resultMessage(result)
            }
        }
    }

    @ViewBuilder
    private func resultMessage(_ result: ApplyResult) -> some View {
        switch result {
        case .success(let gold):
            HStack(spacing: LayoutConstants.spaceXS) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DarkFantasyTheme.success)
                Text("Bonus applied! +\(gold) gold")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.success)
            }
        case .alreadyReferred:
            Text("You already used a referral code")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textTertiary)
        case .invalidCode:
            Text("Invalid code — check and try again")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.danger)
        case .error(let msg):
            Text(msg)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.danger)
        }
    }

    // MARK: - Actions

    private func loadReferralData() async {
        guard let charId = appState.currentCharacter?.id else { return }
        do {
            let response = try await APIClient.shared.getRaw(
                "/tutorial/referral",
                params: ["character_id": charId]
            )
            await MainActor.run {
                self.referralCode = response["referralCode"] as? String
                self.referralCount = response["referralCount"] as? Int ?? 0
                self.qualifiedCount = response["qualifiedCount"] as? Int ?? 0
                self.maxReferrals = response["maxReferrals"] as? Int ?? 20
                self.alreadyReferred = (response["referredBy"] as? String) != nil
            }
        } catch {
            print("Referral data load failed:", error)
            await MainActor.run {
                self.loadFailed = true
            }
        }
    }

    private func applyFriendCode() async {
        guard let charId = appState.currentCharacter?.id else { return }
        let code = friendCode.uppercased().trimmingCharacters(in: .whitespaces)
        guard code.count >= 4 else { return }

        isApplying = true
        defer { isApplying = false }

        do {
            let response = try await APIClient.shared.postRaw(
                "/tutorial/referral",
                body: ["character_id": charId, "referral_code": code]
            )
            if let gold = response["bonusGold"] as? Int {
                applyResult = .success(bonusGold: gold)
                alreadyReferred = true
                appState.showToast("+\(gold) gold from referral!", type: .success)
                await appState.reloadCharacter()
            }
        } catch let error as APIError {
            switch error {
            case .clientError(_, let message, _):
                if message.lowercased().contains("already referred") {
                    applyResult = .alreadyReferred
                    alreadyReferred = true
                } else if message.lowercased().contains("invalid") || message.lowercased().contains("not found") {
                    applyResult = .invalidCode
                } else if message.lowercased().contains("own referral") {
                    applyResult = .error("Can't use your own code")
                } else {
                    applyResult = .error(message)
                }
            default:
                applyResult = .error(error.userMessage)
            }
        } catch {
            applyResult = .error("Connection error")
        }
    }

    private func shareReferralCode(_ code: String) {
        let message = "Join me in Hexbound! Use my invite code \(code) for bonus gold. Download: https://hexboundapp.com"
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - ApplyResult helpers

extension Optional where Wrapped == ReferralSectionView.ApplyResult {
    var isError: Bool {
        switch self {
        case .some(.invalidCode), .some(.error):
            return true
        default:
            return false
        }
    }
}
