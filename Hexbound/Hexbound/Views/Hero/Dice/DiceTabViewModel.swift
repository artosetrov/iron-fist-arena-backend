//
//  DiceTabViewModel.swift
//  Hexbound
//
//  Hero → Dice tab: both dice, their sockets and the class's nine runes.
//  GET /api/dice, POST /api/dice/socket (DICE_RUNES_DESIGN.md §5).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class DiceTabViewModel {
    var data: DiceLoadoutResponse?
    var isLoading = false
    var errorMessage: String?
    /// Face the player tapped — drives the rune picker sheet.
    var picking: (kind: DiceKind, face: Int)?
    var savingFace: (kind: DiceKind, face: Int)?

    private let appState: AppState
    let characterId: String

    init(appState: AppState, characterId: String) {
        self.appState = appState
        self.characterId = characterId
    }

    func load() async {
        if data == nil { isLoading = true }
        defer { isLoading = false }
        do {
            data = try await APIClient.shared.get(APIEndpoints.dice, params: ["character_id": characterId])
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't load your dice"
        }
    }

    // MARK: - Derived

    func runes(for kind: DiceKind) -> [DiceRuneEntry] {
        (data?.runes ?? []).filter { $0.die == kind.profileKey }
    }

    func runeKey(_ kind: DiceKind, face: Int) -> String? {
        guard let die = data?.loadout(kind), die.runes.indices.contains(face) else { return nil }
        return die.runes[face]
    }

    /// Owned runes for this die that aren't socketed anywhere yet.
    func idleRunes(_ kind: DiceKind) -> Int {
        runes(for: kind).filter { $0.owned && $0.socketed == nil }.count
    }

    var hasFreeSocketAndRune: Bool {
        guard let d = data else { return false }
        return (d.dice.atk.used < d.dice.atk.sockets && idleRunes(.attack) > 0)
            || (d.dice.grd.used < d.dice.grd.sockets && idleRunes(.guardDie) > 0)
    }

    // MARK: - Actions

    func tapFace(_ kind: DiceKind, face: Int) {
        guard data != nil else { return }
        HapticManager.selection()
        picking = (kind, face)
    }

    func socket(_ rune: DiceRuneEntry?, kind: DiceKind, face: Int) {
        picking = nil
        guard let current = data else { return }
        if current.inMatch {
            appState.showToast("Finish your fight first", subtitle: "Runes can't change mid-match", type: .info)
            return
        }
        savingFace = (kind, face)
        Task { [weak self] in
            guard let self else { return }
            defer { self.savingFace = nil }
            do {
                let updated: DiceLoadoutResponse = try await APIClient.shared.post(
                    APIEndpoints.diceSocket,
                    body: DiceSocketRequest(characterId: self.characterId, die: kind.profileKey,
                                            faceIndex: face, runeKey: rune?.key)
                )
                self.data = updated
                HapticManager.success()
                SFXManager.shared.play(rune == nil ? .uiUnequip : .uiEquip)
                if let rune {
                    self.appState.showToast("\(rune.name) socketed", subtitle: "\(kind.title) · \(DiceZone.of(face: face).label)", type: .success)
                }
            } catch {
                HapticManager.error()
                let msg = (error as? APIError)?.errorDescription ?? "Couldn't change the rune"
                self.appState.showToast("Rune not socketed", subtitle: msg, type: .error,
                                        actionLabel: "Retry", action: { [weak self] in self?.socket(rune, kind: kind, face: face) })
            }
        }
    }
}
