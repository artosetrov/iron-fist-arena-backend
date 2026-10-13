import Foundation
import StoreKit

// MARK: - IAP Product IDs

/// Every SKU the app may offer.
///
/// The raw value is the App Store Connect product identifier; `internalId` is
/// the matching key in the backend's `IAP_PRODUCTS`. Both sides must agree —
/// see `backend/src/lib/apple-iap.ts` (`APPLE_TO_INTERNAL_PRODUCT_ID`).
///
/// Economy v3: flat gold packs and `premium_forever` are retired. They are
/// deliberately NOT listed here — the backend returns 410 for them, so
/// offering them would charge the player and deliver nothing.
enum IAPProduct: String, CaseIterable {
    // Gem packs
    case gemsSmall = "com.hexbound.gems_small"        // 100 gems — $0.99
    case gemsMedium = "com.hexbound.gems_medium"       // 550 gems — $4.99
    case gemsLarge = "com.hexbound.gems_large"         // 1200 gems — $9.99
    case gemsHuge = "com.hexbound.gems_huge"           // 2500 gems — $19.99
    case gemsMega = "com.hexbound.gems_mega"           // 6500 gems — $49.99

    // Adventurer's Bundles — gems + gold + consumables
    case adventurerBundleI = "com.hexbound.adventurer_bundle_I"     // 600💎 + 3K gold — $4.99
    case adventurerBundleII = "com.hexbound.adventurer_bundle_II"   // 1400💎 + 10K gold — $9.99
    case adventurerBundleIII = "com.hexbound.adventurer_bundle_III" // 3200💎 + 20K gold — $19.99

    // Starter / recurring
    case starterBundle = "com.hexbound.starter_bundle"              // 200💎 + 3K gold — $2.99
    case monthlyGemCard = "com.hexbound.monthly_gem_card"           // 50 + 10/day ×30 — $4.99
    case premiumPassMonthly = "com.hexbound.premium_pass_monthly"   // 30-day pass — $4.99

    /// Backend `IAP_PRODUCTS` key for this SKU.
    var internalId: String {
        switch self {
        case .gemsSmall: "gems_small"
        case .gemsMedium: "gems_medium"
        case .gemsLarge: "gems_large"
        case .gemsHuge: "gems_huge"
        case .gemsMega: "gems_mega"
        case .adventurerBundleI: "adventurer_bundle_I"
        case .adventurerBundleII: "adventurer_bundle_II"
        case .adventurerBundleIII: "adventurer_bundle_III"
        case .starterBundle: "starter_bundle"
        case .monthlyGemCard: "monthly_gem_card"
        case .premiumPassMonthly: "premium_pass_monthly"
        }
    }

    static func internalId(forAppleProductId appleProductId: String) -> String? {
        IAPProduct(rawValue: appleProductId)?.internalId
    }
}

// MARK: - StoreKit Error

enum StoreKitError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case verificationFailed
    case pending
    case unknownProduct

    var errorDescription: String? {
        switch self {
        case .productNotFound: "Product not found in the App Store."
        case .purchaseFailed: "Purchase failed. Please try again."
        case .purchaseCancelled: "Purchase was cancelled."
        case .verificationFailed: "Purchase verification failed."
        case .pending: "Purchase is pending approval."
        case .unknownProduct: "This purchase could not be delivered. Your receipt is saved — please contact support."
        }
    }
}

// MARK: - StoreKit Service (StoreKit 2)

@MainActor
final class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        _ = Task { [weak self] in await self?.loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        let productIDs = IAPProduct.allCases.map(\.rawValue)
        do {
            products = try await Product.products(for: Set(productIDs))
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase a product by ID. Returns the transaction for server-side verification.
    func purchase(productId: String) async throws -> Transaction {
        guard let product = products.first(where: { $0.id == productId }) else {
            // Attempt to fetch single product
            let fetched = try await Product.products(for: [productId])
            guard let product = fetched.first else {
                throw StoreKitError.productNotFound
            }
            return try await executePurchase(product)
        }
        return try await executePurchase(product)
    }

    private func executePurchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerification(verification)

            // Redeem on the server BEFORE finishing. `finish()` tells StoreKit
            // the goods were delivered and drops the transaction from
            // `Transaction.updates` forever — doing it first means a failed
            // server call leaves the player charged with nothing to show and
            // no way to recover. A throw here leaves the transaction unfinished
            // so the listener below retries on the next launch.
            let outcome = try await redeem(transaction)

            // Both remaining outcomes are terminal, so stop the redelivery loop
            // either way — but only one of them is worth celebrating.
            await transaction.finish()

            // A refused receipt must not mark the product as owned — that is
            // what drives `isPremium` and the Restore copy.
            if case .undeliverable = outcome {
                throw StoreKitError.unknownProduct
            }

            purchasedProductIDs.insert(product.id)
            return transaction

        case .userCancelled:
            throw StoreKitError.purchaseCancelled

        case .pending:
            throw StoreKitError.pending

        @unknown default:
            throw StoreKitError.purchaseFailed
        }
    }

    // MARK: - Server Redemption

    /// Outcome of handing a transaction to the backend.
    enum RedeemOutcome {
        /// The account was credited by this call.
        case granted(IAPVerifyResponse)
        /// A previous attempt already credited this transaction (HTTP 409).
        /// The player has what they paid for; nothing more to do.
        case alreadyCredited
        /// The server will never grant for this receipt — retired SKU, refunded
        /// transaction, product mismatch. Retrying cannot help, so the
        /// transaction must be finished and the player told plainly.
        case undeliverable(reason: String)
    }

    /// Legacy App Store SKUs that are no longer offered but may still arrive as
    /// an undelivered transaction. They are deliberately absent from
    /// `IAPProduct` so nothing can sell them, yet they must still reach the
    /// server: the backend recognises them and answers 410, which is the
    /// correct, logged resolution. Dropping them client-side would silently
    /// destroy a real receipt.
    private static let legacyProductIds: [String: String] = [
        "com.hexbound.gold500": "gold_500",
        "com.hexbound.gold1200": "gold_1200",
        "com.hexbound.gold3500": "gold_3500",
        "com.hexbound.gold8000": "gold_8000",
        "com.hexbound.gold20000": "gold_20000",
        "com.hexbound.premium_forever": "premium_forever",
    ]

    /// Hand a verified StoreKit transaction to the backend, which validates it
    /// with Apple and credits the account.
    ///
    /// Throws only for failures worth retrying — offline, 5xx, expired session,
    /// or a transient verification outage. A permanent answer comes back as
    /// `.alreadyCredited` / `.undeliverable` so the caller can finish the
    /// transaction instead of replaying it on every launch forever.
    func redeem(_ transaction: Transaction) async throws -> RedeemOutcome {
        let productID = transaction.productID
        guard let internalId = IAPProduct.internalId(forAppleProductId: productID)
            ?? Self.legacyProductIds[productID]
        else {
            return .undeliverable(reason: "unknown product \(productID)")
        }

        let body = IAPVerifyRequest(
            productId: internalId,
            transactionId: String(transaction.id),
            receiptData: String(transaction.id)
        )

        do {
            let response: IAPVerifyResponse = try await APIClient.shared.post(
                APIEndpoints.iapVerify,
                body: body
            )
            return .granted(response)
        } catch let error as APIError {
            guard let status = error.statusCode else { throw error }

            // Already credited on a previous attempt — a success, not a failure.
            if status == 409 { return .alreadyCredited }

            // The server marks permanently-rejected receipts explicitly, because
            // the status alone cannot separate "this will never work" from
            // "verification is down right now" — both are 403.
            let code = error.responsePayload?["code"] as? String
            if code == "RECEIPT_REJECTED" {
                return .undeliverable(reason: "server rejected receipt (\(status))")
            }
            if code == "VERIFICATION_UNAVAILABLE" { throw error }

            // No code (older server build): fall back to the status. 410 is
            // always terminal; 400 means the request itself will never be valid.
            if status == 410 || status == 400 {
                return .undeliverable(reason: "server returned \(status)")
            }
            throw error
        }
    }


    // MARK: - Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    // MARK: - Restore Purchases

    @discardableResult
    func restorePurchases() async -> RestoreResult {
        // Sync with App Store
        try? await AppStore.sync()

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }

        // Re-send anything StoreKit still considers undelivered. This is what
        // makes "Restore Purchases" actually recover a purchase whose server
        // grant failed, instead of only repopulating a local set.
        var recovered = 0
        var stillPending = 0
        var undeliverable = 0
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            do {
                let outcome = try await redeem(transaction)
                await transaction.finish()

                switch outcome {
                case .granted:
                    recovered += 1
                    purchasedProductIDs.insert(transaction.productID)
                case .alreadyCredited:
                    purchasedProductIDs.insert(transaction.productID)
                case .undeliverable(let reason):
                    // Finished so it stops replaying, but the player did not
                    // get it — say so rather than reporting a clean restore.
                    undeliverable += 1
                    logUndeliverable(transaction.productID, reason)
                }
            } catch {
                stillPending += 1
                #if DEBUG
                print("[StoreKit] Restore could not redeem \(transaction.productID): \(error)")
                #endif
            }
        }
        return RestoreResult(
            recoveredPurchases: recovered,
            unresolvedPurchases: stillPending,
            undeliverablePurchases: undeliverable
        )
    }

    /// Permanent-delivery failures are rare and worth a line in the log, but
    /// the message itself only exists in debug builds. Keeping the binding out
    /// here means no unused-variable warning when archiving.
    private nonisolated func logUndeliverable(_ productID: String, _ reason: String) {
        #if DEBUG
        print("[StoreKit] \(productID) undeliverable: \(reason)")
        #endif
    }

    /// What `restorePurchases()` actually managed to do, so the UI can say
    /// something true instead of always claiming success.
    struct RestoreResult {
        /// Credited by this restore.
        let recoveredPurchases: Int
        /// Failed for a retryable reason — worth telling the player to retry.
        let unresolvedPurchases: Int
        /// Permanently refused by the server — retrying will not help.
        let undeliverablePurchases: Int

        var hasUnresolved: Bool { unresolvedPurchases > 0 }
        var hasUndeliverable: Bool { undeliverablePurchases > 0 }
    }

    // MARK: - Check if Premium

    /// Local hint only — the server's `premiumUntil` is authoritative.
    /// `premium_forever` is retired for new purchases but still entitles the
    /// players who bought it, so Restore must keep recognising it.
    static let legacyPremiumForeverProductID = "com.hexbound.premium_forever"

    var isPremium: Bool {
        purchasedProductIDs.contains(IAPProduct.premiumPassMonthly.rawValue)
            || purchasedProductIDs.contains(Self.legacyPremiumForeverProductID)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // This is the recovery path for a purchase whose server
                    // redemption failed earlier (offline, server error, app
                    // killed mid-flow). Only finish once the grant succeeded —
                    // otherwise keep the transaction alive for the next try.
                    do {
                        let outcome = try await self.redeem(transaction)
                        if case .undeliverable(let reason) = outcome {
                            self.logUndeliverable(transaction.productID, reason)
                            await transaction.finish()
                            continue
                        }
                    } catch {
                        // Retryable failure — leave it unfinished so StoreKit
                        // delivers it again next launch.
                        #if DEBUG
                        print("[StoreKit] Deferred redemption failed for \(transaction.productID): \(error). Will retry.")
                        #endif
                        continue
                    }

                    _ = await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Product Helpers

    func product(for id: IAPProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func formattedPrice(for id: IAPProduct) -> String {
        product(for: id)?.displayPrice ?? "—"
    }
}

// MARK: - API Models for Receipt Verification

struct IAPVerifyRequest: Encodable {
    let productId: String
    let transactionId: String
    let receiptData: String
}

struct IAPVerifyResponse: Decodable {
    let success: Bool
    let gemsAwarded: Int?
    let goldAwarded: Int?
    let premiumUntil: String?
    let transactionId: String?
}
