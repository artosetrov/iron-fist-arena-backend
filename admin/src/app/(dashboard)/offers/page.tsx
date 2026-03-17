import { listShopOffers, getOfferStats } from '@/actions/shop-offers'
import { OffersClient } from './offers-client'

export default async function OffersPage() {
  const [offers, stats] = await Promise.all([
    listShopOffers(),
    getOfferStats(),
  ])
  return <OffersClient initialOffers={JSON.parse(JSON.stringify(offers))} stats={stats} />
}
