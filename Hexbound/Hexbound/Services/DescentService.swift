import Foundation

/// Network layer for Dungeon Rush v2 "The Descent" (`/api/dungeon-rush/v2/*`).
/// Every call returns a `Result` so the view model can branch on the server's
/// typed codes (NO_STAMINA, STALE, RUN_NOT_ACTIVE) instead of string matching.
@MainActor
final class DescentService {
    enum Failure: Error {
        case noCharacter
        case noStamina(String)
        /// Another device (or a retried request) already advanced the run;
        /// the server returns its current snapshot so we can resync.
        case stale(DescentSnapshot?)
        case runOver(String)
        case rejected(String)
        case network(String)

        var message: String {
            switch self {
            case .noCharacter: "No hero selected."
            case .noStamina(let m), .runOver(let m), .rejected(let m), .network(let m): m
            case .stale: "The descent moved on. Showing the latest state."
            }
        }
    }

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    private var characterId: String? { appState.currentCharacter?.id }

    func state() async -> Result<DescentStateResponse, Failure> {
        guard let characterId else { return .failure(.noCharacter) }
        do {
            let res: DescentStateResponse = try await APIClient.shared.get(
                APIEndpoints.descentState,
                params: ["character_id": characterId]
            )
            return .success(res)
        } catch {
            return .failure(Self.failure(from: error))
        }
    }

    func start() async -> Result<DescentStartResponse, Failure> {
        guard let characterId else { return .failure(.noCharacter) }
        do {
            let res: DescentStartResponse = try await APIClient.shared.post(
                APIEndpoints.descentStart,
                body: DescentStartRequest(characterId: characterId)
            )
            return .success(res)
        } catch {
            return .failure(Self.failure(from: error))
        }
    }

    func act(runId: String, seq: Int, action: DescentAction) async -> Result<DescentActResponse, Failure> {
        guard let characterId else { return .failure(.noCharacter) }
        do {
            let res: DescentActResponse = try await APIClient.shared.post(
                APIEndpoints.descentAct,
                body: action.request(characterId: characterId, runId: runId, seq: seq)
            )
            return .success(res)
        } catch {
            return .failure(Self.failure(from: error))
        }
    }

    // MARK: - Error mapping

    private static func failure(from error: Error) -> Failure {
        guard let api = error as? APIError else {
            return .network("Check your connection and try again.")
        }
        switch api {
        case .clientError(let status, let message, let body):
            let code = body?["code"] as? String
            if code == "NO_STAMINA" { return .noStamina(message) }
            if code == "STALE" || status == 409 { return .stale(decodeSnapshot(body?["view"])) }
            if code == "RUN_NOT_ACTIVE" || status == 404 { return .runOver(message) }
            return .rejected(message)
        case .rateLimited(let message):
            return .rejected(message)
        default:
            return .network(api.userMessage)
        }
    }

    /// The 409 body carries the current `view`; re-encode the parsed JSON and decode it.
    private static func decodeSnapshot(_ raw: Any?) -> DescentSnapshot? {
        guard let raw, JSONSerialization.isValidJSONObject(raw),
              let data = try? JSONSerialization.data(withJSONObject: raw) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(DescentSnapshot.self, from: data)
    }
}
