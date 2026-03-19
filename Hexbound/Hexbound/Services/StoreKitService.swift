import Foundation
import StoreKit

// MARK: - IAP Product IDs

enum IAPProduct: String, CaseIterable {
    // Gold packs
    case gold500 = "com.hexbound.gold500"
    case gold1200 = "com.hexbound.gold1200"
    case gold3500 = "com.hexbound.gold3500"
    case gold8000 = "com.hexbound.gold8000"
    case gold20000 = "com.hexbound.gold20000"

    // Gem packs (aligned with docs/02_product_and_features/ECONOMY.md)
    case gemsSmall = "com.hexbound.gems_small"        // 100 gems — $0.99
    case gemsMedium = "com.hexbound.gems_medium"       // 550 gems — $4.99
    case gemsLarge = "com.hexbound.gems_large"         // 1200 gems — $9.99
    case gemsMega = "com.hexbound.gems_mega"           // 6500 gems — $49.99

    // Special
    case monthlyGemCard = "com.hexbound.monthly_gem_card"  // 50 + 10/day x30 — $4.99
    case premiumForever = "com.hexbound.premium_forever"    // One-time premium — $9.99
}

// MARK: - StoreKit Error

enum StoreKitError: LocalizedError {
    case productNotFound
    case purchaseFailed
    case purchaseCancelled
    case verificationFailed
    case pending

    var errorDescription: String? {
        switch self {
        case .productNotFound: "Product not found in the App Store."
        case .purchaseFailed: "Purchase failed. Please try again."
        case .purchaseCancelled: "Purchase was cancelled."
        case .verificationFailed: "Purchase verification failed."
        case .pending: "Purchase is pending approval."
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
        Task { [weak self] in await self?.loadProducts() }
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
            await transaction.finish()
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

    func restorePurchases() async {
        // Sync with App Store
        try? await AppStore.sync()

        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    // MARK: - Check if Premium

    var isPremium: Bool {
        purchasedProductIDs.contains(IAPProduct.premiumForever.rawValue)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await MainActor.run {
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
