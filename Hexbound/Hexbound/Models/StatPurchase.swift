import Foundation

struct BuyStatPointsResult: Codable {
    let purchased: Int
    let price: Int
    let nextPrice: Int?
    let dailyRemaining: Int
    let totalPurchased: Int
    let globalCap: Int
}

struct StatPurchaseStatus: Codable {
    let purchasesToday: Int
    let dailyLimit: Int
    let dailyRemaining: Int
    let totalPurchased: Int
    let globalCap: Int
    let prices: [Int]
    let nextPrice: Int?
    let statPointsAvailable: Int
}
