import {
  getEconomySummary,
  getGoldByLevel,
  getTopGoldHolders,
  getTopGemHolders,
  getIapByProduct,
  getRecentTransactions,
  getOfferPurchasesByOffer,
  getWealthDistribution,
  getEconomyByClass,
} from '@/actions/economy'
import { EconomyClient } from './economy-client'

export default async function EconomyPage() {
  const [
    summary,
    goldByLevel,
    topGold,
    topGems,
    iapByProduct,
    recentTxns,
    offerPurchases,
    wealthDist,
    byClass,
  ] = await Promise.all([
    getEconomySummary(),
    getGoldByLevel(),
    getTopGoldHolders(),
    getTopGemHolders(),
    getIapByProduct(),
    getRecentTransactions(),
    getOfferPurchasesByOffer(),
    getWealthDistribution(),
    getEconomyByClass(),
  ])

  return (
    <EconomyClient
      summary={summary}
      goldByLevel={goldByLevel}
      topGold={JSON.parse(JSON.stringify(topGold))}
      topGems={JSON.parse(JSON.stringify(topGems))}
      iapByProduct={iapByProduct}
      recentTransactions={JSON.parse(JSON.stringify(recentTxns))}
      offerPurchases={offerPurchases}
      wealthDistribution={wealthDist}
      byClass={byClass}
    />
  )
}
