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
///
/// Client events (`ClientAnalyticsEvent`) are buffered and POSTed in batches to
/// `/api/analytics/events`, where they land in `analytics_events` next to the
/// server-side funnel events (since 2026-10-13 — before that, `track()` had
/// zero call sites and nothing was persisted).
enum AnalyticsAuthProvider: String, Sendable {
    case email
    case guest
    case google
    case apple
}

enum AnalyticsEvent {
    case signup(userId: String, authProvider: AnalyticsAuthProvider, hasUsername: Bool)
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
            return ["userId": userId, "authProvider": authProvider.rawValue, "hasUsername": hasUsername]
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

// MARK: - Client events (iOS → POST /api/analytics/events)

/// JSON-safe property value for client events.
enum AnalyticsValue: Encodable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    case string(String), int(Int), double(Double), bool(Bool)

    init(stringLiteral value: String) { self = .string(value) }
    init(integerLiteral value: Int) { self = .int(value) }
    init(booleanLiteral value: Bool) { self = .bool(value) }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        }
    }
}

/// Client-originated funnel events. Allowlisted on the server
/// (`CLIENT_EVENT_NAMES` in backend/src/lib/analytics.ts) — add there first.
enum ClientAnalyticsEvent: String {
    case sessionStart = "session_start"
    case screenView = "screen_view"
    case onboardingStep = "onboarding_step"
    case tutorialComplete = "tutorial_complete"
    case iapStarted = "iap_started"
    case iapFailed = "iap_failed"
    case dungeonRunStart = "dungeon_run_start"
    case dungeonRunEnd = "dungeon_run_end"
    case shopPurchase = "shop_purchase"
    case pvpFightStart = "pvp_fight_start"
}

private struct ClientEventPayload: Encodable {
    let name: String
    let characterId: String?
    let props: [String: AnalyticsValue]
    let ts: Int
}

private struct ClientEventBatch: Encodable {
    let events: [ClientEventPayload]
}

private struct ClientEventAck: Decodable {
    let accepted: Int
}

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var backend: any AnalyticsBackend = NoopAnalyticsBackend()

    // Client-event buffer. Flushed every `flushInterval`, when it reaches
    // `flushThreshold`, or explicitly via `flush()` (app background).
    private var buffer: [ClientEventPayload] = []
    private var flushTask: Task<Void, Never>?
    private let flushThreshold = 20
    private let flushInterval: Duration = .seconds(15)
    /// Set by GameInitService once a character is active.
    var currentCharacterId: String?

    private init() {}

    /// Queue a client event. Never throws, never blocks the caller.
    /// Props must not contain PII — ids, enums and numbers only.
    func track(_ event: ClientAnalyticsEvent, _ props: [String: AnalyticsValue] = [:]) {
        buffer.append(ClientEventPayload(
            name: event.rawValue,
            characterId: currentCharacterId,
            props: props,
            ts: Int(Date().timeIntervalSince1970 * 1000)
        ))
        #if DEBUG
        print("[analytics] \(event.rawValue) \(props)")
        #endif
        if buffer.count >= flushThreshold {
            flush()
        } else if flushTask == nil {
            flushTask = Task { [weak self] in
                try? await Task.sleep(for: self?.flushInterval ?? .seconds(15))
                await MainActor.run { self?.flush() }
            }
        }
    }

    /// Send whatever is buffered. Safe to call any time (e.g. on background).
    func flush() {
        flushTask?.cancel()
        flushTask = nil
        guard !buffer.isEmpty else { return }
        let batch = ClientEventBatch(events: buffer)
        buffer.removeAll()
        Task.detached(priority: .utility) {
            // Fire-and-forget: a lost batch is acceptable, a visible error is not.
            guard await APIClient.shared.getAuthToken() != nil else { return }
            let _: ClientEventAck? = try? await APIClient.shared.post(APIEndpoints.analyticsEvents, body: batch)
        }
    }

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
