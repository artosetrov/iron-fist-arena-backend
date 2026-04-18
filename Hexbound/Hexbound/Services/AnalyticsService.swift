import Foundation

/// Provider-agnostic analytics event tracking for the iOS client.
///
/// Mirrors `backend/src/lib/analytics.ts` — the 7 critical-funnel events are
/// strongly typed so swapping in a concrete SDK (Firebase, Mixpanel, Segment,
/// Amplitude) happens in exactly one place: `AnalyticsService.shared.setBackend(_:)`.
///
/// Defaults to `NoopAnalyticsBackend`, which prints to stdout in DEBUG builds
/// and is silent in release. Ships the event contract to production before the
/// SDK decision lands.
///
/// Most events are emitted server-side (authoritative). The client emits only
/// UI-layer events where the server doesn't see the action directly — e.g.
/// signup flow (before the user creates a character) and IAP purchase started
/// (before StoreKit verification).
enum AnalyticsEvent {
    case signup(userId: String, authProvider: String, hasUsername: Bool)
    case firstPvP(userId: String, characterId: String, won: Bool, totalTurns: Int, ratingAfter: Int)
    case iapPurchase(userId: String, productId: String, transactionId: String, gemsAwarded: Int, goldAwarded: Int)
    case bpClaim(userId: String, characterId: String, seasonId: String, level: Int, isPremium: Bool)
    case dailyLogin(userId: String, characterId: String, day: Int, streak: Int, resetStreak: Bool)
    case levelUp(userId: String, characterId: String, fromLevel: Int, toLevel: Int)
    case shopUpgrade(userId: String, characterId: String, itemId: String, catalogId: String, fromLevel: Int, toLevel: Int, success: Bool)

    var name: String {
        switch self {
        case .signup: return "signup"
        case .firstPvP: return "first_pvp"
        case .iapPurchase: return "iap_purchase"
        case .bpClaim: return "bp_claim"
        case .dailyLogin: return "daily_login"
        case .levelUp: return "level_up"
        case .shopUpgrade: return "shop_upgrade"
        }
    }

    var properties: [String: Any] {
        switch self {
        case let .signup(userId, authProvider, hasUsername):
            return ["userId": userId, "authProvider": authProvider, "hasUsername": hasUsername]
        case let .firstPvP(userId, characterId, won, totalTurns, ratingAfter):
            return [
                "userId": userId, "characterId": characterId, "won": won,
                "totalTurns": totalTurns, "ratingAfter": ratingAfter,
            ]
        case let .iapPurchase(userId, productId, transactionId, gemsAwarded, goldAwarded):
            return [
                "userId": userId, "productId": productId, "transactionId": transactionId,
                "gemsAwarded": gemsAwarded, "goldAwarded": goldAwarded,
            ]
        case let .bpClaim(userId, characterId, seasonId, level, isPremium):
            return [
                "userId": userId, "characterId": characterId, "seasonId": seasonId,
                "level": level, "isPremium": isPremium,
            ]
        case let .dailyLogin(userId, characterId, day, streak, resetStreak):
            return [
                "userId": userId, "characterId": characterId, "day": day,
                "streak": streak, "resetStreak": resetStreak,
            ]
        case let .levelUp(userId, characterId, fromLevel, toLevel):
            return [
                "userId": userId, "characterId": characterId,
                "fromLevel": fromLevel, "toLevel": toLevel,
            ]
        case let .shopUpgrade(userId, characterId, itemId, catalogId, fromLevel, toLevel, success):
            return [
                "userId": userId, "characterId": characterId, "itemId": itemId,
                "catalogId": catalogId, "fromLevel": fromLevel, "toLevel": toLevel, "success": success,
            ]
        }
    }
}

protocol AnalyticsBackend: Sendable {
    func track(_ event: AnalyticsEvent) async
}

struct NoopAnalyticsBackend: AnalyticsBackend {
    func track(_ event: AnalyticsEvent) async {
        #if DEBUG
        print("[analytics] \(event.name) \(event.properties)")
        #endif
    }
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var backend: any AnalyticsBackend = NoopAnalyticsBackend()

    private init() {}

    /// Swap in a real SDK backend at app startup. Typically called once from
    /// `HexboundApp` after auth is wired (so we can attach userId to session).
    func setBackend(_ backend: any AnalyticsBackend) {
        self.backend = backend
    }

    /// Fire-and-forget. Never awaits, never throws into callers. Safe to call
    /// from ViewModels, Services, onAppear, onChange handlers, etc.
    func track(_ event: AnalyticsEvent) {
        let b = backend
        Task.detached { await b.track(event) }
    }
}
