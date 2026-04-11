import React from "react";

/**
 * Kuzya UI/UX Review — Choose Your Hero (Guest Gating)
 * Before / After wireframe comparison
 *
 * BEFORE: current screen with GET CURRENCY button visible to guest
 * AFTER:  balance-row removed, Guest banner becomes single gating point,
 *         CTA renamed to "CREATE ACCOUNT", ENTER GAME is the only
 *         dominant gold accent.
 */

export default function ChooseHeroGuestGatingReview() {
  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-200 p-8 font-sans">
      <div className="max-w-7xl mx-auto">
        <header className="mb-8">
          <h1 className="text-3xl font-bold text-yellow-400 mb-2">
            Kuzya UI/UX — Choose Your Hero (Guest Gating)
          </h1>
          <p className="text-neutral-400">
            Single-source gating, no competing gold accents, honest CTA copy.
          </p>
        </header>

        {/* Side-by-side comparison */}
        <div className="flex flex-col xl:flex-row gap-10 items-start justify-center">
          {/* BEFORE */}
          <div className="flex-1 max-w-md w-full">
            <div className="flex items-center gap-3 mb-4">
              <span className="text-xs font-bold uppercase tracking-wider text-red-400 bg-red-400/10 px-3 py-1 rounded">
                Before
              </span>
              <span className="text-sm text-neutral-500">
                current — 3 gold accents compete
              </span>
            </div>

            <PhoneFrame>
              <ScreenHeader />

              {/* balance row with GET CURRENCY */}
              <div className="relative mx-4 mb-3 flex items-center justify-between rounded-lg border border-neutral-800 bg-neutral-900/60 px-4 py-3">
                <div className="flex items-center gap-2">
                  <span className="h-5 w-5 rounded-full bg-yellow-500/80" />
                  <span className="text-sm font-semibold text-yellow-300">
                    366
                  </span>
                </div>
                <div className="relative">
                  <GoldCTA small>GET CURRENCY</GoldCTA>
                  <Annotation color="red" placement="-top-2 -right-2">
                    false promise
                  </Annotation>
                </div>
              </div>

              {/* Guest banner */}
              <div className="mx-4 mb-4 flex items-center justify-between rounded-lg border border-yellow-700/60 bg-yellow-900/10 px-3 py-2">
                <div className="flex items-center gap-2">
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-yellow-500/20 text-yellow-400 text-xs">
                    !
                  </span>
                  <div>
                    <div className="text-xs font-bold text-yellow-300">
                      Guest Account
                    </div>
                    <div className="text-[10px] text-neutral-400">
                      Create an account to save progress
                    </div>
                  </div>
                </div>
                <div className="rounded border border-yellow-600/60 px-2 py-1 text-[10px] font-bold text-yellow-300">
                  SIGN UP
                </div>
              </div>

              {/* Hero cards */}
              <div className="mx-4 mb-3 grid grid-cols-2 gap-2">
                <HeroCardStub label="Thunderhunter" sub="TANK · 1,014" highlighted />
                <HeroCardStub label="Darkmaw" sub="WARRIOR · NEW" />
              </div>
              <div className="mx-4 mb-3">
                <CreateHeroStub />
              </div>

              {/* Bottom CTA */}
              <div className="mx-4 mt-auto mb-4">
                <GoldCTA>ENTER GAME</GoldCTA>
              </div>
            </PhoneFrame>

            <ul className="mt-5 space-y-1 text-xs text-neutral-400">
              <li>× 3 gold accents compete for attention</li>
              <li>× GET CURRENCY clickable but leads to dead end</li>
              <li>× Two sign-up paths (row + banner) confuse user</li>
              <li>× Balance is noise for guest — no real ownership</li>
            </ul>
          </div>

          {/* AFTER */}
          <div className="flex-1 max-w-md w-full">
            <div className="flex items-center gap-3 mb-4">
              <span className="text-xs font-bold uppercase tracking-wider text-green-400 bg-green-400/10 px-3 py-1 rounded">
                After
              </span>
              <span className="text-sm text-neutral-500">
                single gating, one gold CTA
              </span>
            </div>

            <PhoneFrame>
              <ScreenHeader />

              {/* Enlarged, single Guest banner */}
              <div className="relative mx-4 mb-4 rounded-xl border border-yellow-600/60 bg-yellow-900/20 p-4">
                <div className="flex items-start gap-3">
                  <span className="flex h-8 w-8 items-center justify-center rounded-full bg-yellow-500/25 text-yellow-300">
                    !
                  </span>
                  <div className="flex-1">
                    <div className="text-sm font-bold text-yellow-300">
                      Playing as Guest
                    </div>
                    <div className="mt-1 text-[11px] leading-snug text-neutral-300">
                      Sign up to save heroes, unlock shop, and keep
                      progress forever.
                    </div>
                  </div>
                </div>
                <button className="mt-3 w-full rounded-md border border-yellow-500/70 bg-yellow-600/20 px-3 py-2 text-[12px] font-bold tracking-wider text-yellow-200">
                  CREATE ACCOUNT
                </button>
                <Annotation color="green" placement="-top-2 -right-2">
                  single gating point
                </Annotation>
              </div>

              {/* Hero cards */}
              <div className="mx-4 mb-3 grid grid-cols-2 gap-2">
                <HeroCardStub label="Thunderhunter" sub="TANK · 1,014" highlighted />
                <HeroCardStub label="Darkmaw" sub="WARRIOR · NEW" />
              </div>
              <div className="mx-4 mb-3">
                <CreateHeroStub />
              </div>

              {/* Bottom CTA — now the only gold */}
              <div className="relative mx-4 mt-auto mb-4">
                <GoldCTA>ENTER GAME</GoldCTA>
                <Annotation color="green" placement="-top-2 right-2">
                  only dominant focus
                </Annotation>
              </div>
            </PhoneFrame>

            <ul className="mt-5 space-y-1 text-xs text-neutral-400">
              <li>✓ Balance row hidden for guest (progressive disclosure)</li>
              <li>✓ One gating banner, one clear action</li>
              <li>✓ ENTER GAME is the only dominant gold CTA</li>
              <li>✓ CTA copy sells a concrete benefit, not a step</li>
            </ul>
          </div>
        </div>

        {/* Legend */}
        <div className="mt-12 max-w-4xl mx-auto rounded-lg border border-neutral-800 bg-neutral-900/60 p-6">
          <h2 className="text-lg font-bold text-yellow-400 mb-4">
            Changes applied (Priority Actions)
          </h2>
          <ol className="space-y-3 text-sm text-neutral-300">
            <li>
              <b className="text-yellow-300">1. Balance row removed for guests.</b>{" "}
              Valuta abstraction on onboarding is noise. Removes competing
              gold accent and eliminates the false-promise GET CURRENCY button.
            </li>
            <li>
              <b className="text-yellow-300">2. Guest banner becomes primary gate.</b>{" "}
              Larger, higher contrast, explains value (save heroes, unlock
              shop, keep progress). Single source of truth for guest → registered
              conversion.
            </li>
            <li>
              <b className="text-yellow-300">3. CTA copy: "SIGN UP" → "CREATE ACCOUNT".</b>{" "}
              More concrete for first-time users. Consider dynamic switching
              to "SAVE MY PROGRESS" once the guest has a hero 2+ lvl
              (loss aversion is stronger than abstract upside).
            </li>
            <li>
              <b className="text-yellow-300">4. ENTER GAME = only dominant gold.</b>{" "}
              One CTA at a time. Visual hierarchy restored — the primary
              action of this screen is finally unmistakable.
            </li>
            <li>
              <b className="text-yellow-300">
                5. New DS component: GuestGateCTA.
              </b>{" "}
              Add a design-system primitive for guest gating with states
              (locked / signup-prompt) so this pattern is reusable in shop,
              inventory, leaderboards — anywhere registration is required.
            </li>
          </ol>

          <div className="mt-6 pt-4 border-t border-neutral-800">
            <p className="text-xs text-neutral-500">
              <b className="text-neutral-400">Verdict on "UNLOCK SHOP":</b>{" "}
              rejected. In F2P grammar "unlock" = progression gate, not
              account gate. "CREATE ACCOUNT" or "SAVE MY PROGRESS" maps
              directly to the required user action.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------------------------------------------------------- */
/* sub-components                                             */
/* ---------------------------------------------------------- */

function PhoneFrame({ children }) {
  return (
    <div className="relative mx-auto flex h-[720px] w-[340px] flex-col overflow-hidden rounded-[40px] border-2 border-neutral-800 bg-[#0B0B15] shadow-2xl">
      <div className="flex items-center justify-between px-6 pt-3 pb-1">
        <span className="text-[10px] text-neutral-500">8:37</span>
        <span className="h-4 w-16 rounded-full bg-black" />
        <span className="text-[10px] text-neutral-500">●●●</span>
      </div>
      <div className="flex flex-1 flex-col">{children}</div>
    </div>
  );
}

function ScreenHeader() {
  return (
    <div className="px-4 pt-5 pb-4 text-center">
      <div className="text-[18px] font-bold tracking-widest text-yellow-400">
        CHOOSE YOUR HERO
      </div>
      <div className="text-[10px] text-neutral-500 mt-1">
        Select a hero to enter the world
      </div>
    </div>
  );
}

function GoldCTA({ children, small }) {
  return (
    <div
      className={
        "flex items-center justify-center rounded-md border border-yellow-500/70 bg-gradient-to-b from-yellow-500 to-yellow-700 text-neutral-900 font-bold tracking-wider shadow-lg " +
        (small ? "px-4 py-2 text-[10px]" : "px-6 py-3 text-[12px]")
      }
    >
      {children}
    </div>
  );
}

function HeroCardStub({ label, sub, highlighted }) {
  return (
    <div
      className={
        "rounded-lg border bg-neutral-900/70 p-3 " +
        (highlighted
          ? "border-yellow-500/70"
          : "border-neutral-800")
      }
    >
      <div className="flex items-center gap-2">
        <span className="h-6 w-6 rounded-full bg-neutral-700 flex items-center justify-center text-[9px] text-neutral-400">
          LVL
        </span>
        <span className="text-[11px] font-bold text-neutral-200">
          {label}
        </span>
      </div>
      <div className="mt-1 text-[9px] text-neutral-400">{sub}</div>
      <div className="mt-2 h-1 rounded bg-green-500/60" />
      <div className="mt-1 h-1 rounded bg-orange-500/60 w-2/3" />
      <div className="mt-2 flex gap-1">
        <div className="flex-1 rounded border border-red-500/40 py-1 text-center text-[9px] text-red-300">
          10 ATK
        </div>
        <div className="flex-1 rounded border border-blue-500/40 py-1 text-center text-[9px] text-blue-300">
          15 DEF
        </div>
      </div>
    </div>
  );
}

function CreateHeroStub() {
  return (
    <div className="flex h-[80px] w-[48%] items-center justify-center rounded-lg border border-dashed border-neutral-700 bg-neutral-900/40">
      <div className="text-center">
        <div className="text-lg text-neutral-400">+</div>
        <div className="text-[9px] text-neutral-500">CREATE HERO</div>
      </div>
    </div>
  );
}

function Annotation({ children, color, placement }) {
  const colorClass =
    color === "red"
      ? "bg-red-500 text-white"
      : color === "green"
      ? "bg-green-500 text-neutral-900"
      : "bg-yellow-500 text-neutral-900";
  return (
    <span
      className={
        "absolute rounded-full px-2 py-0.5 text-[9px] font-bold shadow-lg " +
        colorClass +
        " " +
        placement
      }
    >
      {children}
    </span>
  );
}
