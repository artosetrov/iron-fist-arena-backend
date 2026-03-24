# Game Economy Safety Review

> Trigger: "economy check", "проверь экономику", "economy safety", or when any reward/price/currency change is made.

## Purpose
Verify game economy changes don't break balance, create exploits, or cause inflation.

## Workflow

### Phase 1 — Sources & Sinks Audit
List all currency sources (where players earn) and sinks (where players spend):
- Gold sources: PvP wins, dungeon rewards, daily login, quests, gold mine, achievements, battle pass
- Gold sinks: shop purchases, equipment repair, consumables, upgrades, prestige
- Gem sources: IAP, achievements, battle pass, daily gem card
- Gem sinks: premium shop, stamina refill, cosmetics

### Phase 2 — Change Impact
For the proposed change:
- Which source/sink is affected?
- How much does daily earning/spending change?
- At scale (1000 players × 30 days), what's the aggregate impact?
- Does this create a new net-positive loop (earn more than spend)?

### Phase 3 — Exploit Vectors
Check for:
- Can players spam-farm this? (rate limits?)
- Can concurrent requests double-claim? (TOCTOU prevention?)
- Can bot accounts exploit this? (anti-automation?)
- Is the reward server-authoritative? (client can't fake it?)
- Are there atomic increments for counters?

### Phase 4 — Progression Impact
- Does this change level-up speed significantly?
- Does it affect gear progression curve?
- Does it impact PvP balance (pay-to-win risk)?
- Is it fair for F2P players?

### Phase 5 — Admin/LiveOps Readiness
- Can this be tuned via admin without deploy?
- Are the key values in `live-config.ts`?
- Can the change be reverted quickly?

## Output
```
CHANGE: [description]
RISK LEVEL: Critical / High / Medium / Low
EXPLOIT RISKS: [list]
INFLATION RISK: [assessment]
RECOMMENDATION: Approve / Approve with conditions / Reject
CONDITIONS: [if applicable]
```
