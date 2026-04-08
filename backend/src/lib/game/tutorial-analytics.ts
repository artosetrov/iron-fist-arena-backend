/**
 * Tutorial Analytics — structured event logging for onboarding funnel.
 *
 * Events are logged as structured JSON to stdout (captured by Vercel logs).
 * Format: { event, characterId, ...payload, timestamp }
 *
 * Funnel events (in order):
 * 1. tutorial_started     — POST /tutorial called (character created, welcome gift given)
 * 2. tutorial_step        — step advanced (1=weapon_equipped, 2=first_fight, 3=completed)
 * 3. tutorial_skipped     — user chose "I'm experienced, skip"
 * 4. tutorial_quest_start — NPC quest unlocked/started
 * 5. tutorial_quest_done  — NPC quest completed (progress reached target)
 * 6. tutorial_quest_claim — quest reward claimed
 * 7. referral_applied     — user entered a referral code
 * 8. referral_qualified   — invitee reached Lv5 (referrer gets reward)
 *
 * To query: Vercel > Logs > filter by "tutorial_event"
 * Future: pipe to PostHog/Mixpanel via Vercel log drain
 */

interface TutorialEvent {
  event: string
  characterId: string
  [key: string]: unknown
}

export function logTutorialEvent(payload: TutorialEvent): void {
  const entry = {
    _tag: 'tutorial_event',
    ...payload,
    timestamp: new Date().toISOString(),
  }
  // Structured JSON log — searchable in Vercel/CloudWatch
  console.log(JSON.stringify(entry))
}
