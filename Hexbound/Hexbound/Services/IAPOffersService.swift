import Foundation
import Observation

// MARK: - IAP Offers

/// This account's state for the shop's special offers (GET /api/iap/offers):
/// whether the one-time Starter Bundle is still on sale, and the Monthly Gem
/// Card's terms and status. The terms come from backend balance.ts
/// (MONTHLY_GEM_CARD), so the client does not own economy numbers.
struct IAPOffers: Decodable, Equatable, Sendable {
    var starterBundleAvailable: Bool
    var gemCard: GemCard

    struct GemCard: Decodable, Equatable, Sendable {
        var instantGems: Int
        var dailyGems: Int
        var days: Int
        var active: Bool
        /// Daily payouts still ahead on an active card.
        var daysRemaining: Int
        var expiresAt: String?

        /// The most one card pays: the instant gems plus every daily payout.
        var maxGems: Int { instantGems + dailyGems * days }
    }
}

// MARK: - IAP Offers Service

@MainActor
@Observable
final class IAPOffersService {
    static let shared = IAPOffersService()

    /// Last answer from the server; nil until the first one arrives.
    private(set) var offers: IAPOffers?

    /// Shown until the server answers (or while it can't be reached). Mirrors
    /// MONTHLY_GEM_CARD in backend/src/lib/game/balance.ts.
    static let fallbackGemCard = IAPOffers.GemCard(
        instantGems: 150, dailyGems: 50, days: 30,
        active: false, daysRemaining: 0, expiresAt: nil
    )

    private init() {}

    var gemCard: IAPOffers.GemCard { offers?.gemCard ?? Self.fallbackGemCard }

    /// Before the server has answered, the Starter Bundle is hidden only if
    /// this device has already seen the account buy it — so a returning buyer
    /// never sees it flash up and vanish.
    func isStarterBundleAvailable(for userId: String?) -> Bool {
        if let offers { return offers.starterBundleAvailable }
        guard let userId else { return true }
        return !UserDefaults.standard.bool(forKey: Self.starterBoughtKey(userId))
    }

    func refresh(userId: String?) async {
        do {
            let fresh: IAPOffers = try await APIClient.shared.get(APIEndpoints.iapOffers)
            offers = fresh
            if !fresh.starterBundleAvailable, let userId {
                UserDefaults.standard.set(true, forKey: Self.starterBoughtKey(userId))
            }
        } catch {
            // Keep the last answer; the shop falls back to the defaults above.
            #if DEBUG
            print("[IAPOffers] refresh failed: \(error)")
            #endif
        }
    }

    // MARK: Optimistic updates — the next refresh() confirms them

    func starterBundleBought(userId: String?) {
        if let userId {
            UserDefaults.standard.set(true, forKey: Self.starterBoughtKey(userId))
        }
        offers?.starterBundleAvailable = false
    }

    /// A purchase starts a card, or adds `days` to the active one (verify-receipt).
    func gemCardBought() {
        guard var card = offers?.gemCard else { return }
        card.daysRemaining = (card.active ? card.daysRemaining : 0) + card.days
        card.active = true
        offers?.gemCard = card
    }

    private static func starterBoughtKey(_ userId: String) -> String {
        "iap.starterBundleBought.\(userId)"
    }
}
