-- 2026-10-13: Premium Pass renewals now credit monthlyGems from the Apple
-- webhook (DID_RENEW). Column records the renewal transaction that was paid
-- so Apple's retries cannot double-credit.
ALTER TABLE "premium_subscriptions"
  ADD COLUMN IF NOT EXISTS "renewal_gems_tx_id" TEXT;
