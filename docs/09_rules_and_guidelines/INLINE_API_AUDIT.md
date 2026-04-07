# Inline API Calls Audit — SwiftUI Views

**Date:** 2026-04-06
**Scope:** All 181 `.swift` files in `Hexbound/Hexbound/Views/`
**Finding:** 8 files with direct API/service calls in Views; 7 contain duplicated code

---

## Executive Summary

Most user-triggered async operations correctly delegate to ViewModels. However, **7 critical problem areas** contain direct API/service calls that should be extracted into ViewModels for consistency and testability.

**Primary Issue:** CharacterProfileView + LeaderboardPlayerDetailSheet share identical friend/challenge logic with direct service calls. This code duplication should be consolidated into a shared OpponentProfileViewModel.

---

## Critical Issues (User-Triggered, Blocking Calls)

### 1. CurrencyPurchaseView.swift — Lines 340, 347, 376, 384

**Pattern:** Direct `APIClient.shared.post()` for IAP verification

```swift
private func buyPackage(_ pkg: CurrencyPackage) {
    Task {
        do {
            let transaction = try await StoreKitService.shared.purchase(productId: pkg.productId)
            let _: IAPVerifyResponse = try await APIClient.shared.post("/api/iap/verify", body: body)
            //                           ↑ DIRECT API CALL
        }
    }
}
```

| Aspect | Status |
|--------|--------|
| User Action | Tap "BUY PACKAGE" button |
| Blocking | YES — waits for StoreKit + server verification |
| Optimistic Feedback | YES — `.purchasing` state shown before API |
| Error Handling | Reverts on failure with toast |
| Should Delegate | YES — wrap in ShopViewModel |

**Impact:** User sees loading state immediately but must wait for full transaction. Acceptable but inconsistent with VM pattern used elsewhere.

---

### 2. PremiumPurchaseView.swift — Lines 345, 352

**Pattern:** Identical to CurrencyPurchaseView

```swift
let transaction = try await StoreKitService.shared.purchase(productId: productId)
let _: IAPVerifyResponse = try await APIClient.shared.post("/api/iap/verify", body: body)
```

**Status:** Same as #1 — should move to ShopViewModel.

---

### 3. InboxRowView.swift — Line 578

**Pattern:** Direct `ChallengeService.shared.declineChallenge()`

```swift
private func declineInvite(_ invite: BattleInviteData) {
    Task {
        do {
            try await ChallengeService.shared.declineChallenge(
                characterId: characterId,
                challengeId: invite.challengeId
            )
            //  ↑ DIRECT SERVICE CALL — NOT IN VIEWMODEL
        }
    }
}
```

| Aspect | Status |
|--------|--------|
| User Action | Tap "DECLINE" button on battle invite |
| Blocking | YES — waits for decline to process |
| Optimistic Feedback | Minimal — only haptic on tap |
| Should Delegate | YES — should use InboxViewModel |

---

### 4. CharacterProfileView.swift — Lines 411, 454, 477, 499, 524, 536

**Pattern:** Multiple direct service/API calls scattered across 5 methods

```swift
private func sendFriendRequest() {
    Task {
        let errorMsg = await SocialService.shared.sendFriendRequest(...)  // Line 411
    }
}

private func acceptFriendRequest() {
    Task {
        let success = await SocialService.shared.acceptFriendRequest(...)  // Line 454
    }
}

private func removeFriend() {
    Task {
        let success = await SocialService.shared.removeFriend(...)  // Line 477
    }
}

private func sendChallenge() {
    Task {
        _ = try await ChallengeService.shared.sendChallenge(...)  // Line 499
    }
}

private func loadProfile() async {
    let response: OpponentProfileResponse = try await APIClient.shared.get(...)  // Line 524
    let state = await SocialService.shared.getFriendshipStatus(...)  // Line 536
}
```

**Issue:** All six API/service calls are direct; should be in a CharacterProfileViewModel.

**User Actions:**
- Tap "Add Ally" → sendFriendRequest()
- Tap "Accept" → acceptFriendRequest()
- Tap "···" → Remove → removeFriend()
- Tap "Challenge" → sendChallenge()
- Screen load → loadProfile()

**All blocking with optimistic feedback for friend actions, but scattered across View.**

---

### 5. LeaderboardPlayerDetailSheet.swift — Lines 409, 448, 472, 505, 517

**Pattern:** CODE DUPLICATE of CharacterProfileView

```swift
// IDENTICAL to CharacterProfileView methods:
private func sendFriendRequest() { ... }      // Line 409
private func acceptFriendRequest() { ... }    // Line 448
private func sendChallenge() { ... }          // Line 472
private func loadProfile() { ... }            // Line 505, 517
```

**Critical Issue:** Same logic exists in both CharacterProfileView and LeaderboardPlayerDetailSheet. Both make direct service calls.

---

### 6. LeaderboardPlayerDetailSheet 2.swift — Lines 518, 557, 581, 614, 626

**Pattern:** DUPLICATE of LeaderboardPlayerDetailSheet.swift

This appears to be a backup file. Same code duplication issue.

**Recommendation:** DELETE this file; consolidate into single LeaderboardPlayerDetailSheet.swift, then extract to shared ViewModel.

---

### 7. HubEditorDetailView.swift — Line 295

**Pattern:** Direct `APIClient.shared.postRaw()` in map save

```swift
private func saveToServer(terrainSize: Int) async {
    let _ = try await APIClient.shared.postRaw(
        "/api/editor/save-terrain",
        body: saveBody
    )  // ↑ DIRECT API
}
```

Called from Button: `Task { await saveToServer(...) }`

| Aspect | Status |
|--------|--------|
| User Action | Tap "SAVE" button on map editor |
| Blocking | YES — waits for save to complete |
| Optimistic Feedback | Minimal — haptic on button tap only |
| Should Delegate | YES — wrap in EditorViewModel |

---

### 8. DungeonMapEditorView.swift — Line 253

**Pattern:** Identical to HubEditorDetailView

```swift
private func saveToServer(terrainSize: Int) async {
    let _ = try await APIClient.shared.postRaw(...)  // Line 253
}
```

---

## Good Patterns (Correctly Delegated)

### Majority of Views follow VM pattern correctly:

```swift
// CORRECT — from DailyQuestsDetailView.swift
Button { Task { await vm.claimQuest(quest) } } label: { ... }
//      Delegates to ViewModel ✓

// CORRECT — from GoldMineDetailView.swift
Task { await vm.startMining(slotIndex: index) }
//    Delegates to ViewModel ✓

// CORRECT — from ArenaDetailView.swift
Task { await vm.fight(opponentId: opponent.id) }
//    Delegates to ViewModel ✓

// CORRECT — from HeroDetailView.swift
onEquip: { let _ = Task { await vm.equip(item) } }
onUnequip: { let _ = Task { await vm.unequip(item) } }
onSell: { let _ = Task { await vm.sell(item) } }
//       All delegate to ViewModel ✓
```

---

## Remediation Checklist

### Phase 1: Eliminate Code Duplication

- [ ] Create shared `OpponentProfileViewModel`
  - Consolidate friend/challenge/load logic from CharacterProfileView and LeaderboardPlayerDetailSheet
  - Both Views should use this single ViewModel
- [ ] Delete LeaderboardPlayerDetailSheet 2.swift (backup/duplicate)

### Phase 2: Extract Service Calls

- [ ] **CharacterProfileView.swift:** Remove direct service calls, delegate to OpponentProfileViewModel
  - Lines: 411, 454, 477, 499, 524, 536
- [ ] **LeaderboardPlayerDetailSheet.swift:** Same extraction (auto-fixed when using shared ViewModel)
  - Lines: 409, 448, 472, 505, 517
- [ ] **InboxRowView.swift:** Move `declineChallenge()` to InboxViewModel
  - Line: 578
- [ ] **CurrencyPurchaseView.swift:** Wrap IAP verification in ShopViewModel
  - Lines: 340, 347, 376, 384
- [ ] **PremiumPurchaseView.swift:** Wrap IAP verification in ShopViewModel
  - Lines: 345, 352
- [ ] **HubEditorDetailView.swift:** Wrap `saveToServer()` in EditorViewModel
  - Line: 295
- [ ] **DungeonMapEditorView.swift:** Wrap `saveToServer()` in EditorViewModel
  - Line: 253

### Phase 3: Validation

- [ ] All user-triggered async operations follow: `Button { vm.action() }` pattern
- [ ] Zero direct APIClient.shared calls in Views
- [ ] Zero direct Service.shared calls in Views
- [ ] All .task/.onAppear data loading remains in proper lifecycle methods

---

## Architecture Pattern (REQUIRED)

All user-triggered async operations in Views **MUST** follow this pattern:

```swift
// CORRECT
Button { vm.performAction() } label: { ... }

// INCORRECT
Button { Task { await APIClient.shared.post(...) } } label: { ... }

// INCORRECT
Button { Task { await Service.shared.method(...) } } label: { ... }
```

**Rationale:**
1. Testability — ViewModel methods can be mocked; direct API calls cannot
2. Consistency — all Views follow same pattern across codebase
3. Maintainability — service calls in one place (ViewModel)
4. Error handling — centralized in ViewModel
5. Optimistic UI — easier to manage in ViewModel

---

## Related Documentation

- `docs/09_rules_and_guidelines/DEVELOPMENT_RULES.md` — Architecture requirements
- `CLAUDE.md` — State management: `@MainActor @Observable` classes, Views use `@Bindable var vm`
- `Hexbound/CLAUDE.md` — Swift/iOS specific patterns

