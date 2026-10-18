import CryptoKit
import Foundation

// MARK: - Fortune's Table (jackpot wheel, 4–6 seats) — 2026-10-17
//
// Mirrors `backend/src/app/api/minigames/fortune-table/*`. The APIClient
// decodes snake_case into these camelCase names.

struct FortuneTableTier: Codable, Identifiable, Equatable {
    let key: String
    let minStake: Int
    let maxStake: Int
    let minLevel: Int
    let unlocked: Bool

    var id: String { key }
    var title: String { key.uppercased() }

    /// Stakes offered when sitting down: the minimum, ×2, ×4 and the cap.
    var stakePresets: [Int] {
        Array(Set([minStake, minStake * 2, minStake * 4, maxStake].filter { $0 <= maxStake })).sorted()
    }

    /// Top-up chips while the lobby is open: 1×, 2× and 5× the table minimum.
    var topUpSteps: [Int] { [minStake, minStake * 2, minStake * 5] }
}

struct FortuneTableSeat: Codable, Identifiable, Equatable {
    let seat: Int
    let isYou: Bool
    let name: String
    /// Bundled `hero_portrait_XX`; nil for the player (their own avatar is drawn).
    let portrait: String?
    let style: String
    let stake: Int
    let joinedMs: Int

    /// Names are unique at a table; the player keeps one id whatever their name.
    var id: String { isYou ? "you" : name }
}

struct FortuneChestShard: Codable, Equatable {
    let tier: String
    let amount: Int
}

struct FortuneChestItem: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let rarity: String
    let itemType: String?
    let imageKey: String?
    let imageUrl: String?
    let shard: FortuneChestShard?
}

struct FortuneTableResult: Codable, Equatable {
    let won: Bool
    let winnerSeat: Int
    /// Where the pointer stops, 0…1 clockwise from 12 o'clock.
    let ticket: Double
    let payout: Int
    let chest: [FortuneChestItem]
}

struct FortuneTableRound: Codable, Equatable {
    let id: String
    let tier: String
    /// `lobby` → `drawing` → `settled`
    let status: String
    /// SHA-256 of the round's seed, shown before the draw.
    let commitment: String
    /// The seed itself, revealed once the round is settled.
    let seed: String?
    let lobbyMs: Int
    let msToLock: Int
    let topUpCloseMs: Int
    let rake: Double
    let pot: Int
    let payoutIfWin: Int
    let chestItemChance: Double
    let yourStake: Int
    let yourChance: Double
    let seats: [FortuneTableSeat]
    let result: FortuneTableResult?

    var isSettled: Bool { status == "settled" }
    var winner: FortuneTableSeat? {
        guard let result, seats.indices.contains(result.winnerSeat) else { return nil }
        return seats[result.winnerSeat]
    }
}

struct FortuneTableHistoryEntry: Codable, Identifiable, Equatable {
    let id: String
    let at: String
    let tier: String
    let pot: Int
    let won: Bool
    let payout: Int
    let yourStake: Int
    let winnerName: String?
}

struct FortuneTableStatusResponse: Codable {
    let tiers: [FortuneTableTier]
    let rake: Double
    let lobbyMs: Int
    let roundsToday: Int
    let roundsLimit: Int
    let gold: Int
    let activeRound: FortuneTableRound?
    let history: [FortuneTableHistoryEntry]
}

struct FortuneTableJoinRequest: Encodable {
    let characterId: String
    let tier: String
    let stake: Int
}

struct FortuneTableJoinResponse: Codable {
    let round: FortuneTableRound?
    let gold: Int
    let roundsToday: Int
    let roundsLimit: Int
    let resumed: Bool
}

struct FortuneTableTopUpRequest: Encodable {
    let characterId: String
    let roundId: String
    let amount: Int
}

struct FortuneTableRoundResponse: Codable {
    let round: FortuneTableRound?
    let gold: Int
}

// MARK: - Fairness check

/// Re-does the server's maths on the device: the revealed seed must hash to
/// the seal shown before the draw, and the ticket must come from the seed.
enum FortuneTableFairness {
    static func sha256Hex(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// HMAC-SHA256(seed, "ticket") → top 52 bits / 2^52, as on the server.
    static func ticket(forSeed seed: String) -> Double {
        let key = SymmetricKey(data: Data(seed.utf8))
        let mac = Array(HMAC<SHA256>.authenticationCode(for: Data("ticket".utf8), using: key))
        guard mac.count >= 8 else { return -1 }
        let word0 = mac[0..<4].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let word1 = mac[4..<8].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let hi = word0 >> 12 // 20 bits
        return Double(hi * 4_294_967_296 + word1) / 4_503_599_627_370_496 // 2^52
    }

    /// True when the seed matches the seal, yields the stored ticket, and the
    /// ticket falls in the winner's slice (seat order, clockwise from 12).
    /// The regulars' entries come from the same seed, so the seal covers them
    /// too — the client just doesn't re-deal them.
    static func verify(_ round: FortuneTableRound) -> Bool {
        guard let seed = round.seed, let result = round.result else { return false }
        guard sha256Hex(seed) == round.commitment else { return false }
        guard abs(ticket(forSeed: seed) - result.ticket) < 1e-12 else { return false }
        let pot = round.seats.reduce(0) { $0 + $1.stake }
        guard pot > 0, round.seats.indices.contains(result.winnerSeat) else { return false }
        var cumulative = 0
        for seat in round.seats {
            let start = Double(cumulative) / Double(pot)
            cumulative += seat.stake
            let end = Double(cumulative) / Double(pot)
            if result.ticket >= start && result.ticket < end { return seat.seat == result.winnerSeat }
        }
        return result.winnerSeat == round.seats.count - 1
    }
}
