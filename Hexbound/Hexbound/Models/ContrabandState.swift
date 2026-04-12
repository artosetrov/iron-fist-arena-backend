import Foundation

// MARK: - Contraband State

/// Server response for GET /api/shop/contraband.
/// Two states: cooldown (timer visible) or available (offer visible).
struct ContrabandResponse: Codable {
    let status: String // "available" | "cooldown"

    // Cooldown fields
    let nextAvailableAt: String?
    let cooldownSeconds: Int?
    let totalCooldownSeconds: Int?

    // Available fields
    let offer: ContrabandOffer?

    // Common
    let claimNumber: Int?
    let totalClaims: Int?
}

/// The generated contraband offer when status == "available".
struct ContrabandOffer: Codable {
    let contents: [OfferContent] // reuses existing OfferContent model
    let price: Int
    let currency: String
    let isFree: Bool
    let flavorText: String
    let claimNumber: Int
}

/// Response after claiming contraband (POST).
struct ContrabandClaimResponse: Codable {
    let success: Bool
    let gold: Int
    let gems: Int
    let xp: Int
    let contents: [OfferContent]
    let claimNumber: Int
}

// MARK: - Parsed Contraband UI State

/// Convenience enum for the view layer — parsed from ContrabandResponse.
enum ContrabandUIState {
    case loading
    case cooldown(nextAt: Date, cooldownSeconds: Int, totalSeconds: Int, claimNumber: Int)
    case available(offer: ContrabandOffer)
    case error

    /// Parse from server response.
    static func from(_ response: ContrabandResponse) -> ContrabandUIState {
        if response.status == "available", let offer = response.offer {
            return .available(offer: offer)
        }
        if response.status == "cooldown",
           let nextAtString = response.nextAvailableAt,
           let cooldown = response.cooldownSeconds,
           let total = response.totalCooldownSeconds {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let nextAt = formatter.date(from: nextAtString) {
                return .cooldown(
                    nextAt: nextAt,
                    cooldownSeconds: cooldown,
                    totalSeconds: total,
                    claimNumber: response.claimNumber ?? 1
                )
            }
        }
        return .error
    }
}
