import SwiftUI

@MainActor @Observable
final class InventoryViewModel {
    private let appState: AppState
    private let service: InventoryService
    private let shopService: ShopService

    var items: [Item] = []
    var isLoading = false
    var selectedItem: Item?
    var showItemDetail = false
    var totalSlots: Int = 28
    var errorMessage: String? = nil

    /// True only when the last refresh failed AND there is nothing to show.
    ///
    /// A failed background refresh over warm cache must not replace a readable
    /// list with a full-screen error — the stale list is more useful. The error
    /// page is for the case where the screen would otherwise be blank.
    var showsErrorState: Bool { errorMessage != nil && items.isEmpty }

    // Search & Sort
    var searchText = ""
    var sortMode: InventorySortMode = .rarity

    init(appState: AppState) {
        self.appState = appState
        self.service = InventoryService(appState: appState)
        self.shopService = ShopService(appState: appState)
        self.totalSlots = appState.currentCharacter?.inventorySlots ?? 28
    }

    var gold: Int { appState.currentCharacter?.gold ?? 0 }
    var canExpand: Bool { totalSlots < 58 } // 28 + 3*10
    let expandCost = 5000

    var sortedItems: [Item] {
        var result = items.filter { $0.isEquipped != true }

        // Filter by search text
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.displayName.lowercased().contains(q) ||
                $0.rarity.rawValue.lowercased().contains(q) ||
                $0.itemType.rawValue.lowercased().contains(q)
            }
        }

        // Sort
        return result.sorted { a, b in
            switch sortMode {
            case .rarity:
                let aR = Item.rarityOrder[a.rarity] ?? 0
                let bR = Item.rarityOrder[b.rarity] ?? 0
                if aR != bR { return aR > bR }
                return a.itemLevel > b.itemLevel
            case .level:
                if a.itemLevel != b.itemLevel { return a.itemLevel > b.itemLevel }
                return (Item.rarityOrder[a.rarity] ?? 0) > (Item.rarityOrder[b.rarity] ?? 0)
            case .type:
                if a.itemType != b.itemType { return a.itemType.rawValue < b.itemType.rawValue }
                return (Item.rarityOrder[a.rarity] ?? 0) > (Item.rarityOrder[b.rarity] ?? 0)
            case .newest:
                return a.id > b.id  // IDs are chronological UUIDs
            }
        }
    }

    /// Currently equipped item per slot — used for comparison indicators
    var equippedBySlot: [String: Item] {
        var map: [String: Item] = [:]
        for item in items where item.isEquipped == true {
            map[item.equipSlot] = item
        }
        return map
    }

    // BUG-63: mirror of the server's equip validation
    // (backend/src/app/api/inventory/equip/route.ts) so the inventory grid
    // can pre-dim items that this character can't wear yet (level too low
    // or wrong class). The detail sheet has its own copy of this logic so
    // both layers stay consistent without a shared dependency.

    /// Whether the currently-viewed character can equip this item right now.
    /// Returns `true` for consumables, already-equipped items, and any item
    /// inside shop/view flows — those contexts have their own gating.
    func canEquip(_ item: Item) -> Bool {
        guard item.itemType != .consumable else { return true }
        guard item.isEquipped != true else { return true }
        guard let char = appState.currentCharacter else { return true }

        // Level check — prestige-aware, mirrors backend /inventory/equip
        if char.gearLevel < item.itemLevel { return false }

        // Class restriction check — same matrix as the server (warrior ↔ tank share)
        return Character.canWear(characterClass: char.characterClass.rawValue, restriction: item.classRestriction)
    }

    /// Grid slots: items + empty placeholders up to totalSlots
    var gridSlots: [InventorySlot] {
        let sorted = sortedItems
        var slots = sorted.enumerated().map { InventorySlot(index: $0.offset, item: $0.element) }
        let emptyCount = max(0, totalSlots - sorted.count)
        for i in 0..<emptyCount {
            slots.append(InventorySlot(index: sorted.count + i, item: nil))
        }
        return slots
    }

    // MARK: - Load

    func loadInventory() async {
        // Serve cached inventory instantly if available
        if let cached = appState.cachedInventory, items.isEmpty {
            items = cached
        } else if items.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        let seqAtStart = mutationSeq
        let outcome = await service.loadInventory()
        // An equip/unequip went out while this was loading: this snapshot
        // may predate it and would undo the optimistic change on screen.
        // Still in flight → reload once they settle; already settled → the
        // mutation's own snapshot is newer than this one, keep it.
        if inFlightMutations > 0 {
            needsResyncAfterMutations = true
            // The service already wrote this (older) snapshot to the shared
            // cache — put the on-screen optimistic state back.
            appState.cachedInventory = items
            isLoading = false
            return
        }
        if mutationSeq != seqAtStart {
            appState.cachedInventory = items
            isLoading = false
            return
        }
        outcome.apply(
            assign: { self.items = $0 },
            cache: { self.appState.cachedInventory = $0 },
            setError: { self.errorMessage = $0 }
        )
        totalSlots = appState.currentCharacter?.inventorySlots ?? 28
        isLoading = false
    }

    // MARK: - Actions

    func selectItem(_ item: Item) {
        selectedItem = item
        showItemDetail = true
    }

    // MARK: - Deposit to Stash

    func depositToStash(_ item: Item) async {
        // Optimistic UI — remove instantly, API in background with rollback
        let previousItems = items
        items.removeAll { $0.id == item.id }
        appState.cachedInventory = items
        showItemDetail = false
        appState.showToast("Stored in chest", type: .success)

        let stashService = StashService(appState: appState)
        let success = await stashService.deposit(equipmentId: item.id)
        if !success {
            // Rollback on failure
            items = previousItems
            appState.cachedInventory = previousItems
            appState.showToast("Failed to deposit item", type: .error)
        }
    }

    // MARK: - Equip / Unequip (optimistic, sequenced)
    //
    // Latency pass (2026-10-15). The optimistic step used to unequip EVERY
    // item of the same type — a second ring took the first one off, a
    // necklace left the amulet on, an off-hand weapon dropped the main
    // hand — and then the server snapshot put them back a round trip
    // later. That snap-back was the "equip isn't instant" bug. The local
    // step now mirrors the server's slot rules exactly
    // (backend/src/app/api/inventory/equip/route.ts), so the snapshot
    // normally changes nothing on screen.
    //
    // Rapid taps: every mutation gets a sequence number. A server snapshot
    // is applied only if no newer optimistic change is on screen (the newer
    // request's response will carry the newer truth). A failure of an
    // older request triggers one authoritative reload once everything in
    // flight has settled, instead of rolling back over newer changes.

    private var mutationSeq = 0
    private var inFlightMutations = 0
    private var needsResyncAfterMutations = false
    private var characterNeedsRefresh = false
    /// Two requests were in flight at once. Their DB transactions may have
    /// committed in a different order than the taps, so the newest snapshot
    /// isn't guaranteed to contain the older change — reload once at the end.
    private var mutationsOverlapped = false

    func equip(_ item: Item) async {
        // Optimistic UI: update immediately
        let previousItems = items
        let seq = beginMutation()
        applyOptimisticEquip(item)
        appState.cachedInventory = items
        showItemDetail = false
        appState.showToast("Equipped \(item.displayName)", type: .reward)

        // Failure toast comes from the service (it has the server's reason).
        let updated = await service.equip(inventoryId: item.id)
        endMutation(seq: seq, snapshot: updated, rollback: previousItems)
    }

    func unequip(_ item: Item) async {
        // Optimistic UI: update immediately
        let previousItems = items
        let seq = beginMutation()
        applyOptimisticUnequip(item)
        appState.cachedInventory = items
        showItemDetail = false
        appState.showToast("Unequipped \(item.displayName)", type: .info)

        let updated = await service.unequip(inventoryId: item.id)
        endMutation(seq: seq, snapshot: updated, rollback: previousItems)
    }

    private func beginMutation() -> Int {
        if inFlightMutations > 0 { mutationsOverlapped = true }
        mutationSeq += 1
        inFlightMutations += 1
        return mutationSeq
    }

    /// Reconcile one equip/unequip response. `snapshot == nil` means failure.
    private func endMutation(seq: Int, snapshot: [Item]?, rollback: [Item]) {
        inFlightMutations = max(0, inFlightMutations - 1)
        let isLatest = seq == mutationSeq

        if let snapshot {
            characterNeedsRefresh = true
            if isLatest {
                items = snapshot
                appState.cachedInventory = snapshot
            }
        } else if isLatest {
            items = rollback
            appState.cachedInventory = rollback
        } else {
            needsResyncAfterMutations = true
        }

        guard inFlightMutations == 0 else { return }
        if mutationsOverlapped {
            mutationsOverlapped = false
            needsResyncAfterMutations = true
        }
        if needsResyncAfterMutations {
            needsResyncAfterMutations = false
            Task { [weak self] in await self?.loadInventory() }
        }
        if characterNeedsRefresh {
            characterNeedsRefresh = false
            // Equip recomputes derived stats (max HP, damage…) server-side;
            // the inventory snapshot doesn't carry them. One silent refresh
            // after the burst of taps settles, never blocking the UI.
            let characterService = CharacterService(appState: appState)
            Task { await characterService.refreshCharacterSilently() }
        }
    }

    func sell(_ item: Item) async {
        // Optimistic UI: remove item + add gold immediately
        let previousItems = items
        let previousGold = appState.currentCharacter?.gold ?? 0
        let sellPrice = item.sellPrice ?? 0
        items.removeAll { $0.id == item.id }
        appState.currentCharacter?.gold = previousGold + sellPrice
        showItemDetail = false
        appState.showToast("Sold for \(sellPrice) gold", type: .reward)

        if let result = await service.sell(inventoryId: item.id) {
            // Server confirmed — sync authoritative gold
            appState.currentCharacter?.gold = result.gold
            appState.cachedInventory = items
        } else {
            // Rollback on failure
            items = previousItems
            appState.currentCharacter?.gold = previousGold
            appState.cachedInventory = previousItems
            appState.showToast("Failed to sell", subtitle: "Unequip the item first", type: .error)
        }
    }

    func useItem(_ item: Item) async {
        showItemDetail = false

        // Optimistic UI — update inventory instantly
        let previousItems = items
        if let qty = item.quantity, qty > 1 {
            items = items.map { existing in
                guard existing.id == item.id else { return existing }
                var updated = existing
                updated.quantity = qty - 1
                return updated
            }
        } else {
            items.removeAll { $0.id == item.id }
        }
        appState.cachedInventory = items

        // Optimistic stat update — estimate HP/stamina change immediately
        let previousHp = appState.currentCharacter?.currentHp ?? 0
        let previousStamina = appState.currentCharacter?.currentStamina ?? 0
        let isHealthPotion = item.consumableType?.contains("health_potion") == true
        let isStaminaPotion = item.consumableType?.contains("stamina_potion") == true

        if isHealthPotion, var char = appState.currentCharacter {
            let estimatedHeal = InventoryService.estimatedHpRestore(consumableType: item.consumableType, maxHp: char.maxHp)
            char.currentHp = min(char.currentHp + estimatedHeal, char.maxHp)
            appState.currentCharacter = char
        } else if isStaminaPotion, var char = appState.currentCharacter {
            let estimatedRestore = InventoryService.estimatedStaminaRestore(consumableType: item.consumableType, maxStamina: char.maxStamina)
            char.currentStamina = min(char.currentStamina + estimatedRestore, char.maxStamina)
            appState.currentCharacter = char
        }

        HapticManager.success()
        appState.showToast("Used \(item.displayName)", type: .reward)

        // Fire API in background — capture service + appState directly so the call
        // survives even if the InventoryViewModel is deallocated (user navigated away).
        // Previously used [weak self] which could nil-out mid-flight, causing the API
        // call to never reach the server while the optimistic UI already removed the potion.
        let capturedService = service
        let capturedAppState = appState
        let capturedItems = items
        let itemId = item.id
        let consumableType = item.consumableType
        Task { @MainActor [weak self] in
            let success = await capturedService.useItem(inventoryId: itemId, consumableType: consumableType)
            if !success {
                // Revert optimistic changes — use self if still alive, otherwise revert via appState
                if let self {
                    self.items = previousItems
                    self.appState.cachedInventory = previousItems
                } else {
                    capturedAppState.cachedInventory = previousItems
                }
                // Revert optimistic stat changes
                if isHealthPotion {
                    capturedAppState.currentCharacter?.currentHp = previousHp
                } else if isStaminaPotion {
                    capturedAppState.currentCharacter?.currentStamina = previousStamina
                }
            } else {
                // Server confirmed — sync the optimistic cache state
                if let self {
                    capturedAppState.cachedInventory = self.items
                } else {
                    capturedAppState.cachedInventory = capturedItems
                }
                capturedAppState.invalidateCache("quests")
            }
        }
    }

    func upgrade(_ item: Item, useProtection: Bool) async {
        showItemDetail = false
        HapticManager.medium()

        // Upgrade must wait for server result (success/fail/level-change is server-authoritative)
        // But we dismiss UI instantly and show result as toast
        guard let result = await shopService.upgrade(inventoryId: item.id, useProtection: useProtection) else { return }
        items = items.map { existing in
            guard existing.id == item.id else { return existing }
            var updated = existing
            updated.upgradeLevel = result.newLevel
            return updated
        }
        appState.cachedInventory = items
        appState.invalidateCache("quests")
        if result.success {
            SFXManager.shared.play(.anvilStrike)
            SFXManager.shared.play(.enchantGlow)
            HapticManager.success()
            appState.showToast("⬆ \(item.itemName) +\(result.newLevel)!", type: .reward)
        } else if result.protectionUsed {
            appState.showToast("Protected — level kept at +\(result.newLevel)", type: .info)
        } else if result.levelLost {
            HapticManager.error()
            appState.showToast("Failed! Dropped to +\(result.newLevel)", type: .error)
        } else {
            HapticManager.error()
            appState.showToast("Upgrade failed", subtitle: "Level unchanged", type: .error)
        }
    }

    private var repairingItemId: String?

    func repair(_ item: Item) {
        guard repairingItemId == nil else { return } // prevent double-tap
        repairingItemId = item.id
        showItemDetail = false

        // Optimistic: restore durability + deduct gold instantly
        let previousItems = items
        let previousGold = appState.currentCharacter?.gold ?? 0
        let repairCost = item.repairCost ?? 0

        items = items.map { existing in
            guard existing.id == item.id else { return existing }
            var updated = existing
            updated.durability = existing.maxDurability
            return updated
        }
        appState.cachedInventory = items
        if repairCost > 0 {
            appState.currentCharacter?.gold = max(0, previousGold - repairCost)
        }
        HapticManager.success()
        appState.showToast("Repaired!", type: .reward)

        // Fire API in background
        let itemId = item.id
        Task { [weak self] in
            guard let self else { return }
            defer { repairingItemId = nil }
            guard let result = await shopService.repair(inventoryId: itemId) else {
                // Revert on failure
                items = previousItems
                appState.cachedInventory = previousItems
                appState.currentCharacter?.gold = previousGold
                appState.showToast("Repair failed", type: .error)
                return
            }
            // Sync with server values
            items = items.map { existing in
                guard existing.id == itemId else { return existing }
                var updated = existing
                updated.durability = result.newDurability
                updated.maxDurability = result.maxDurability
                return updated
            }
            appState.cachedInventory = items
        }
    }

    // MARK: - Expand Inventory

    private var isExpanding = false

    func expandInventory() {
        guard !isExpanding else { return } // prevent double-tap
        guard canExpand else { return }
        guard gold >= expandCost else {
            appState.showToast("Not enough gold", subtitle: "Earn gold in arena or dungeons", type: .error)
            return
        }

        // Optimistic: increase slots + deduct gold instantly
        let previousSlots = totalSlots
        let previousGold = appState.currentCharacter?.gold ?? 0
        isExpanding = true
        totalSlots += 10
        appState.currentCharacter?.gold = max(0, previousGold - expandCost)
        HapticManager.success()
        appState.showToast("+10 inventory slots! Now: \(totalSlots)", type: .reward)

        // Fire API in background
        Task { [weak self] in
            guard let self else { return }
            defer { isExpanding = false }
            if let newSlots = await service.expandInventory() {
                totalSlots = newSlots
            } else {
                // Revert on failure
                totalSlots = previousSlots
                appState.currentCharacter?.gold = previousGold
                appState.showToast("Failed to expand", type: .error)
            }
        }
    }

    // MARK: - Comparison

    func equippedItemInSlot(for item: Item) -> Item? {
        guard item.isEquipped != true else { return nil }
        // Compare against what the server would actually replace. For a
        // second ring with one ring slot free that is nothing — fall back to
        // a same-type item so the sheet still shows a useful comparison.
        if let slot = Self.predictedSlot(for: item, in: items),
           let occupant = items.first(where: { $0.isEquipped == true && $0.equippedSlot == slot }) {
            return occupant
        }
        return items.first { $0.isEquipped == true && $0.itemType == item.itemType }
    }

    // MARK: - Optimistic Helpers

    /// Item type → candidate equipment slots, in server priority order.
    /// Mirror of `ITEM_TYPE_TO_SLOTS` in backend/src/app/api/inventory/equip/route.ts.
    static let serverSlotsByType: [String: [String]] = [
        "weapon": ["weapon", "relic"],   // main hand, then off-hand (dual wield)
        "helmet": ["helmet"],
        "chest": ["chest"],
        "gloves": ["gloves"],
        "legs": ["legs"],
        "boots": ["boots"],
        "accessory": ["relic"],
        "amulet": ["amulet"],
        "necklace": ["amulet"],          // shares the amulet slot
        "belt": ["belt"],
        "relic": ["relic"],
        "ring": ["ring", "ring2"],       // dual ring slots
    ]

    /// The slot the server will put `item` in, given what is equipped now:
    /// the first free candidate slot, else the first candidate.
    static func predictedSlot(for item: Item, in items: [Item]) -> String? {
        let candidates = serverSlotsByType[item.itemType.rawValue]
            ?? canonicalPrimarySlot(for: item.itemType.rawValue).map { [$0] }
            ?? []
        guard let first = candidates.first else { return nil }
        let occupied = Set(items.compactMap { other -> String? in
            guard other.id != item.id, other.isEquipped == true else { return nil }
            return other.equippedSlot
        })
        return candidates.first { !occupied.contains($0) } ?? first
    }

    private func applyOptimisticEquip(_ item: Item) {
        // Mirror the server: pick the slot (first free candidate, else the
        // primary), unequip ONLY what occupies that slot, plus the two-handed
        // rules. BUG-59 still holds — the equipped item always gets an
        // explicit `equippedSlot` so the card never matches it twice.
        guard let slot = Self.predictedSlot(for: item, in: items) else { return }

        let isTwoHanded = item.itemType == .weapon && item.isTwoHanded == true
        let mainHandIsTwoHanded = slot == "relic"
            && item.itemType == .weapon
            && items.contains { $0.isEquipped == true && $0.equippedSlot == "weapon" && $0.itemType == .weapon && $0.isTwoHanded == true }

        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = true
                updated.equippedSlot = slot
            } else if existing.isEquipped == true, let occupiedSlot = existing.equippedSlot {
                let displaced = occupiedSlot == slot
                    || (isTwoHanded && occupiedSlot == "relic")
                    || (mainHandIsTwoHanded && occupiedSlot == "weapon")
                if displaced {
                    updated.isEquipped = false
                    updated.equippedSlot = nil
                }
            }
            return updated
        }
    }

    private func applyOptimisticUnequip(_ item: Item) {
        items = items.map { existing in
            var updated = existing
            if existing.id == item.id {
                updated.isEquipped = false
                updated.equippedSlot = nil
            }
            return updated
        }
    }

    /// Mirror of `IntegratedCharacterCard.canonicalPrimarySlot` — picks
    /// the first slot in `EquipmentViewModel.slotOrder` that accepts the
    /// given item type. Kept local so the view model doesn't depend on
    /// the view layer.
    private static func canonicalPrimarySlot(for itemType: String) -> String? {
        for candidate in EquipmentViewModel.slotOrder {
            let accepted = EquipmentViewModel.slotAccepts[candidate] ?? [candidate]
            if accepted.contains(itemType) {
                return candidate
            }
        }
        return nil
    }
}

// MARK: - Inventory Slot

struct InventorySlot: Identifiable {
    let index: Int
    let item: Item?
    var id: String { item?.id ?? "empty_\(index)" }
}

// MARK: - Sort Mode

enum InventorySortMode: String, CaseIterable {
    case rarity = "Rarity"
    case level = "Level"
    case type = "Type"
    case newest = "Newest"

    var icon: String {
        switch self {
        case .rarity: "star.fill"
        case .level: "arrow.up.right"
        case .type: "square.grid.2x2"
        case .newest: "clock"
        }
    }
}
