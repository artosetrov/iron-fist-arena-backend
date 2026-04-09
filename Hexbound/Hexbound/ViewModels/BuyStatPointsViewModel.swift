import SwiftUI

@MainActor
@Observable
final class BuyStatPointsViewModel {
    private let service: CharacterService

    // State
    var status: StatPurchaseStatus?
    var isLoading = false
    var isPurchasing = false
    var showConfirmation = false
    var lastPurchaseResult: BuyStatPointsResult?
    var errorMessage: String?

    // Computed
    var prices: [Int] { status?.prices ?? [15, 20, 30, 45, 65] }
    var purchasesToday: Int { status?.purchasesToday ?? 0 }
    var dailyLimit: Int { status?.dailyLimit ?? 5 }
    var dailyRemaining: Int { status?.dailyRemaining ?? 5 }
    var totalPurchased: Int { status?.totalPurchased ?? 0 }
    var globalCap: Int { status?.globalCap ?? 50 }
    var nextPrice: Int? { status?.nextPrice }
    var isGlobalCapReached: Bool { totalPurchased >= globalCap }
    var isDailyLimitReached: Bool { dailyRemaining <= 0 }

    init(service: CharacterService) {
        self.service = service
    }

    func loadStatus() async {
        isLoading = true
        status = await service.getStatPurchaseStatus()
        isLoading = false
    }

    func purchase() {
        guard !isPurchasing, !isDailyLimitReached, !isGlobalCapReached else { return }
        isPurchasing = true

        Task { [weak self] in
            guard let self else { return }
            let result = await service.buyStatPoints()
            isPurchasing = false
            showConfirmation = false

            if let result {
                lastPurchaseResult = result
                HapticManager.success()
                SFXManager.shared.play(.uiConfirm)
                // Reload status to get fresh data
                await loadStatus()
            } else {
                HapticManager.light()
                errorMessage = "Purchase failed"
            }
        }
    }
}
