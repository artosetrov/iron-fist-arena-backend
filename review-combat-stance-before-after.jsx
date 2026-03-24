import { useState } from "react";

// Combat Stance — Before / After UX Comparison
// Kuzya UI/UX Audit — 2026-03-23

const ZONES = ["HEAD", "CHEST", "LEGS"];
const ZONE_COLORS = { HEAD: "#E85D5D", CHEST: "#D4A537", LEGS: "#5B9BD5" };
const ZONE_ICONS = { HEAD: "🪖", CHEST: "🛡️", LEGS: "🦵" };

const ATTACK_BONUSES = {
  HEAD: { offense: "+10%", crit: "+5%" },
  CHEST: { offense: "+5%", crit: "0%" },
  LEGS: { offense: "0%", crit: "-3%" },
};
const DEFENSE_BONUSES = {
  HEAD: { defense: "0%", dodge: "+8%" },
  CHEST: { defense: "+10%", dodge: "0%" },
  LEGS: { defense: "+5%", dodge: "+3%" },
};

// Shared phone frame
const PhoneFrame = ({ label, children, labelColor }) => (
  <div className="flex flex-col items-center gap-3">
    <span
      className="text-sm font-bold tracking-widest"
      style={{ color: labelColor || "#888" }}
    >
      {label}
    </span>
    <div
      className="relative rounded-3xl border-2 overflow-hidden"
      style={{
        width: 320,
        height: 693,
        borderColor: "#333",
        background: "#0D0B14",
      }}
    >
      {/* Status bar */}
      <div
        className="flex items-center justify-between px-6 pt-3 pb-1"
        style={{ height: 44, background: "#0D0B14" }}
      >
        <span className="text-xs" style={{ color: "#666" }}>
          9:41
        </span>
        <div className="flex gap-1">
          <div
            className="w-4 h-2 rounded-sm"
            style={{ background: "#444" }}
          />
          <div
            className="w-4 h-2 rounded-sm"
            style={{ background: "#444" }}
          />
        </div>
      </div>
      {/* Nav bar */}
      <div
        className="flex items-center justify-center px-4"
        style={{ height: 44, borderBottom: "1px solid #1a1a2e" }}
      >
        <span className="text-xs" style={{ color: "#666" }}>
          ‹
        </span>
        <span
          className="flex-1 text-center text-xs font-bold tracking-widest"
          style={{ color: "#D4A537" }}
        >
          COMBAT STANCE
        </span>
      </div>
      {/* Content */}
      <div className="flex flex-col" style={{ height: 605 }}>
        {children}
      </div>
    </div>
  </div>
);

// Annotation badge
const Fix = ({ children, color = "#4ADE80" }) => (
  <span
    className="inline-block text-xs font-bold px-2 py-0.5 rounded-full ml-2"
    style={{ background: color + "22", color, fontSize: 9, whiteSpace: "nowrap" }}
  >
    ✓ {children}
  </span>
);

// ─── BEFORE ─────────────────────────────────────────────

const BeforeScreen = () => {
  const [atkZone] = useState("HEAD");
  const [defZone] = useState("CHEST");

  return (
    <div
      className="flex-1 overflow-y-auto px-3 py-3 flex flex-col gap-3"
      style={{ fontSize: 11 }}
    >
      {/* Summary */}
      <div
        className="flex items-center rounded-lg p-2"
        style={{ background: "#161422", border: "1px solid #2a2640" }}
      >
        <div className="flex-1 text-center">
          <div className="text-xs" style={{ color: "#E85D5D" }}>
            ⚔ ATTACK
          </div>
          <div className="font-bold" style={{ color: "#E85D5D" }}>
            {ZONE_ICONS.HEAD} HEAD
          </div>
        </div>
        <div style={{ width: 1, height: 32, background: "#2a2640" }} />
        <div className="flex-1 text-center">
          <div className="text-xs" style={{ color: "#5B9BD5" }}>
            🛡 DEFENSE
          </div>
          <div className="font-bold" style={{ color: "#D4A537" }}>
            {ZONE_ICONS.CHEST} CHEST
          </div>
        </div>
      </div>

      {/* Attack Zone Title */}
      <div className="flex items-center gap-1 px-1">
        <span>{ZONE_ICONS.HEAD}</span>
        <span style={{ color: "#888", fontSize: 10 }}>ATTACK ZONE</span>
      </div>

      {/* Attack Zone Buttons — tall 80pt */}
      <div className="flex gap-2">
        {ZONES.map((z) => (
          <div
            key={z}
            className="flex-1 flex flex-col items-center justify-center rounded-lg"
            style={{
              height: 68,
              background: z === atkZone ? ZONE_COLORS[z] : "#161422",
              border: `1.5px solid ${z === atkZone ? ZONE_COLORS[z] : "#2a2640"}`,
              color: z === atkZone ? "#fff" : "#666",
              opacity: z === atkZone ? 1 : 0.6,
            }}
          >
            <span style={{ fontSize: 20 }}>{ZONE_ICONS[z]}</span>
            <span className="text-xs font-bold mt-1">{z}</span>
          </div>
        ))}
      </div>

      {/* Attack Bonus Card */}
      <div
        className="rounded-lg p-3"
        style={{ background: "#161422", border: "1px solid #2a2640" }}
      >
        <div className="flex gap-3">
          <div
            className="px-2 py-1 rounded"
            style={{ background: "#E85D5D18" }}
          >
            <div style={{ color: "#888", fontSize: 9 }}>OFFENSE</div>
            <div style={{ color: "#E85D5D", fontWeight: 700 }}>+10%</div>
          </div>
          <div
            className="px-2 py-1 rounded"
            style={{ background: "#D4A53718" }}
          >
            <div style={{ color: "#888", fontSize: 9 }}>CRIT</div>
            <div style={{ color: "#D4A537", fontWeight: 700 }}>+5%</div>
          </div>
        </div>
        <div className="mt-2" style={{ color: "#555", fontSize: 10 }}>
          High risk, high reward. Maximum damage and crit chance.
        </div>
      </div>

      {/* Gold Divider */}
      <div
        className="mx-2"
        style={{ height: 1, background: "#D4A53740" }}
      />

      {/* Defense Zone Title */}
      <div className="flex items-center gap-1 px-1">
        <span>{ZONE_ICONS.CHEST}</span>
        <span style={{ color: "#888", fontSize: 10 }}>DEFENSE ZONE</span>
      </div>

      {/* Defense Zone Buttons */}
      <div className="flex gap-2">
        {ZONES.map((z) => (
          <div
            key={z}
            className="flex-1 flex flex-col items-center justify-center rounded-lg"
            style={{
              height: 68,
              background: z === defZone ? ZONE_COLORS[z] : "#161422",
              border: `1.5px solid ${z === defZone ? ZONE_COLORS[z] : "#2a2640"}`,
              color: z === defZone ? "#fff" : "#666",
              opacity: z === defZone ? 1 : 0.6,
            }}
          >
            <span style={{ fontSize: 20 }}>{ZONE_ICONS[z]}</span>
            <span className="text-xs font-bold mt-1">{z}</span>
          </div>
        ))}
      </div>

      {/* Defense Bonus Card */}
      <div
        className="rounded-lg p-3"
        style={{ background: "#161422", border: "1px solid #2a2640" }}
      >
        <div className="flex gap-3">
          <div
            className="px-2 py-1 rounded"
            style={{ background: "#5B9BD518" }}
          >
            <div style={{ color: "#888", fontSize: 9 }}>DEFENSE</div>
            <div style={{ color: "#5B9BD5", fontWeight: 700 }}>+10%</div>
          </div>
          <div
            className="px-2 py-1 rounded"
            style={{ background: "#4ADE8018" }}
          >
            <div style={{ color: "#888", fontSize: 9 }}>DODGE</div>
            <div style={{ color: "#4ADE80", fontWeight: 700 }}>0%</div>
          </div>
        </div>
        <div className="mt-2" style={{ color: "#555", fontSize: 10 }}>
          Tanky. Maximum damage reduction.
        </div>
      </div>

      {/* Gold Divider */}
      <div
        className="mx-2"
        style={{ height: 1, background: "#D4A53740" }}
      />

      {/* Zone Matching Card */}
      <div
        className="rounded-lg p-3"
        style={{ background: "#161422", border: "1px solid #2a2640" }}
      >
        <div className="flex items-center gap-1 mb-2">
          <span style={{ color: "#D4A537", fontSize: 12 }}>◎</span>
          <span
            style={{ color: "#D4A537", fontSize: 10, fontWeight: 700 }}
          >
            ZONE MATCHING
          </span>
        </div>
        <div className="flex items-center gap-2 mb-1">
          <span style={{ color: "#4ADE80" }}>🛡</span>
          <div>
            <div style={{ color: "#ccc", fontSize: 10 }}>
              Correct Prediction
            </div>
            <div style={{ color: "#555", fontSize: 9 }}>
              Your defense zone matches opponent's attack
            </div>
          </div>
          <div className="ml-auto text-right">
            <div style={{ color: "#4ADE80", fontWeight: 700 }}>+15%</div>
            <div style={{ color: "#555", fontSize: 8 }}>DEFENSE</div>
          </div>
        </div>
        <div style={{ height: 1, background: "#2a2640" }} />
        <div className="flex items-center gap-2 mt-1">
          <span style={{ color: "#E85D5D" }}>🔥</span>
          <div>
            <div style={{ color: "#ccc", fontSize: 10 }}>
              Wrong Prediction
            </div>
            <div style={{ color: "#555", fontSize: 9 }}>
              Opponent defends a different zone
            </div>
          </div>
          <div className="ml-auto text-right">
            <div style={{ color: "#E85D5D", fontWeight: 700 }}>+5%</div>
            <div style={{ color: "#555", fontSize: 8 }}>OFFENSE</div>
          </div>
        </div>
      </div>

      {/* Save button — OFF SCREEN! */}
      <div
        className="rounded-lg py-3 text-center font-bold"
        style={{
          background: "#D4A537",
          color: "#0D0B14",
          fontSize: 12,
          marginTop: 4,
        }}
      >
        SAVE STANCE
      </div>
      <div style={{ height: 16 }} />

      {/* Overflow indicator */}
      <div
        className="absolute bottom-0 left-0 right-0 text-center py-1"
        style={{
          background: "linear-gradient(transparent, #0D0B14)",
          color: "#E85D5D",
          fontSize: 9,
          fontWeight: 700,
        }}
      >
        ⚠ BUTTON OFF-SCREEN — REQUIRES SCROLL ⚠
      </div>
    </div>
  );
};

// ─── AFTER ──────────────────────────────────────────────

const AfterScreen = () => {
  const [atkZone, setAtkZone] = useState("HEAD");
  const [defZone, setDefZone] = useState("CHEST");

  const atk = ATTACK_BONUSES[atkZone];
  const def = DEFENSE_BONUSES[defZone];

  return (
    <div className="flex-1 flex flex-col" style={{ fontSize: 11 }}>
      {/* Scrollable content area */}
      <div className="flex-1 overflow-y-auto px-3 py-3 flex flex-col gap-2.5">
        {/* ── ATTACK ZONE ── inline label + compact buttons */}
        <div>
          <div className="flex items-center gap-1 px-1 mb-1.5">
            <span style={{ color: "#E85D5D", fontSize: 11 }}>⚔</span>
            <span
              style={{ color: "#888", fontSize: 10, fontWeight: 600 }}
            >
              ATTACK ZONE
            </span>
            <Fix>compact 48pt buttons</Fix>
          </div>
          <div className="flex gap-1.5">
            {ZONES.map((z) => (
              <button
                key={z}
                onClick={() => setAtkZone(z)}
                className="flex-1 flex items-center justify-center gap-1.5 rounded-lg cursor-pointer"
                style={{
                  height: 44,
                  background:
                    z === atkZone ? ZONE_COLORS[z] : "#161422",
                  border: `1.5px solid ${z === atkZone ? ZONE_COLORS[z] : "#2a2640"}`,
                  color: z === atkZone ? "#fff" : "#666",
                  opacity: z === atkZone ? 1 : 0.6,
                }}
              >
                <span style={{ fontSize: 14 }}>{ZONE_ICONS[z]}</span>
                <span className="font-bold" style={{ fontSize: 11 }}>
                  {z}
                </span>
              </button>
            ))}
          </div>
          {/* Inline bonus pills — merged into zone section */}
          <div className="flex gap-2 mt-1.5">
            <div
              className="flex items-center gap-1 px-2 py-1 rounded"
              style={{ background: "#E85D5D12" }}
            >
              <span style={{ color: "#E85D5D", fontSize: 10 }}>🔥</span>
              <span style={{ color: "#888", fontSize: 9 }}>OFF</span>
              <span
                style={{
                  color:
                    atk.offense !== "0%"
                      ? "#E85D5D"
                      : "#555",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                {atk.offense}
              </span>
            </div>
            <div
              className="flex items-center gap-1 px-2 py-1 rounded"
              style={{ background: "#D4A53712" }}
            >
              <span style={{ color: "#D4A537", fontSize: 10 }}>⚡</span>
              <span style={{ color: "#888", fontSize: 9 }}>CRIT</span>
              <span
                style={{
                  color:
                    atk.crit !== "0%"
                      ? "#D4A537"
                      : "#555",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                {atk.crit}
              </span>
            </div>
            <Fix color="#D4A537">bonus inline</Fix>
          </div>
        </div>

        {/* Subtle divider */}
        <div style={{ height: 1, background: "#D4A53720", margin: "0 8px" }} />

        {/* ── DEFENSE ZONE ── */}
        <div>
          <div className="flex items-center gap-1 px-1 mb-1.5">
            <span style={{ color: "#5B9BD5", fontSize: 11 }}>🛡</span>
            <span
              style={{ color: "#888", fontSize: 10, fontWeight: 600 }}
            >
              DEFENSE ZONE
            </span>
          </div>
          <div className="flex gap-1.5">
            {ZONES.map((z) => (
              <button
                key={z}
                onClick={() => setDefZone(z)}
                className="flex-1 flex items-center justify-center gap-1.5 rounded-lg cursor-pointer"
                style={{
                  height: 44,
                  background:
                    z === defZone ? ZONE_COLORS[z] : "#161422",
                  border: `1.5px solid ${z === defZone ? ZONE_COLORS[z] : "#2a2640"}`,
                  color: z === defZone ? "#fff" : "#666",
                  opacity: z === defZone ? 1 : 0.6,
                }}
              >
                <span style={{ fontSize: 14 }}>{ZONE_ICONS[z]}</span>
                <span className="font-bold" style={{ fontSize: 11 }}>
                  {z}
                </span>
              </button>
            ))}
          </div>
          <div className="flex gap-2 mt-1.5">
            <div
              className="flex items-center gap-1 px-2 py-1 rounded"
              style={{ background: "#5B9BD512" }}
            >
              <span style={{ color: "#5B9BD5", fontSize: 10 }}>🛡</span>
              <span style={{ color: "#888", fontSize: 9 }}>DEF</span>
              <span
                style={{
                  color:
                    def.defense !== "0%"
                      ? "#5B9BD5"
                      : "#555",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                {def.defense}
              </span>
            </div>
            <div
              className="flex items-center gap-1 px-2 py-1 rounded"
              style={{ background: "#4ADE8012" }}
            >
              <span style={{ color: "#4ADE80", fontSize: 10 }}>💨</span>
              <span style={{ color: "#888", fontSize: 9 }}>DODGE</span>
              <span
                style={{
                  color:
                    def.dodge !== "0%"
                      ? "#4ADE80"
                      : "#555",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                {def.dodge}
              </span>
            </div>
          </div>
        </div>

        {/* Subtle divider */}
        <div style={{ height: 1, background: "#D4A53720", margin: "0 8px" }} />

        {/* ── ZONE MATCHING — collapsed single row ── */}
        <div
          className="rounded-lg px-3 py-2"
          style={{ background: "#161422", border: "1px solid #2a2640" }}
        >
          <div className="flex items-center gap-1 mb-1">
            <span style={{ color: "#D4A537", fontSize: 10 }}>◎</span>
            <span
              style={{ color: "#D4A537", fontSize: 9, fontWeight: 700 }}
            >
              ZONE MATCHING
            </span>
            <Fix color="#60A5FA">compact card</Fix>
          </div>
          <div className="flex gap-3">
            <div className="flex items-center gap-1">
              <span style={{ color: "#4ADE80", fontSize: 10 }}>✓</span>
              <span style={{ color: "#888", fontSize: 9 }}>Match:</span>
              <span
                style={{
                  color: "#4ADE80",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                +15% DEF
              </span>
            </div>
            <div className="flex items-center gap-1">
              <span style={{ color: "#E85D5D", fontSize: 10 }}>✗</span>
              <span style={{ color: "#888", fontSize: 9 }}>Miss:</span>
              <span
                style={{
                  color: "#E85D5D",
                  fontWeight: 700,
                  fontSize: 11,
                }}
              >
                +5% OFF
              </span>
            </div>
          </div>
        </div>

        {/* Summary — moved below selectors as confirmation of choice */}
        <div
          className="flex items-center rounded-lg"
          style={{
            background: "#161422",
            border: "1px solid #2a2640",
            padding: "6px 10px",
          }}
        >
          <div className="flex-1 text-center">
            <div className="flex items-center justify-center gap-1">
              <span style={{ color: "#E85D5D", fontSize: 9 }}>⚔</span>
              <span
                style={{
                  color: ZONE_COLORS[atkZone],
                  fontWeight: 700,
                  fontSize: 12,
                }}
              >
                {ZONE_ICONS[atkZone]} {atkZone}
              </span>
            </div>
          </div>
          <div
            style={{
              width: 1,
              height: 20,
              background: "#D4A53740",
            }}
          />
          <div className="flex-1 text-center">
            <div className="flex items-center justify-center gap-1">
              <span style={{ color: "#5B9BD5", fontSize: 9 }}>🛡</span>
              <span
                style={{
                  color: ZONE_COLORS[defZone],
                  fontWeight: 700,
                  fontSize: 12,
                }}
              >
                {ZONE_ICONS[defZone]} {defZone}
              </span>
            </div>
          </div>
        </div>

        <Fix color="#60A5FA">summary → confirmation below selectors</Fix>
      </div>

      {/* ── STICKY SAVE BUTTON ── pinned to bottom */}
      <div
        className="px-3 pb-4 pt-2"
        style={{
          borderTop: "1px solid #1a1a2e",
          background:
            "linear-gradient(to top, #0D0B14 60%, transparent)",
        }}
      >
        <div
          className="rounded-lg py-3 text-center font-bold"
          style={{
            background: "#D4A537",
            color: "#0D0B14",
            fontSize: 13,
          }}
        >
          SAVE STANCE
        </div>
        <Fix>sticky button — always visible</Fix>
      </div>
    </div>
  );
};

// ─── LEGEND ─────────────────────────────────────────────

const Legend = () => (
  <div
    className="flex flex-col gap-2 mt-6 px-4 py-3 rounded-xl mx-auto"
    style={{
      background: "#161422",
      border: "1px solid #2a2640",
      maxWidth: 700,
      fontSize: 11,
    }}
  >
    <div className="font-bold" style={{ color: "#D4A537", fontSize: 12 }}>
      Changes Applied (Priority Actions)
    </div>
    <div className="flex flex-col gap-1.5" style={{ color: "#999" }}>
      <div>
        <span style={{ color: "#4ADE80" }}>1.</span>{" "}
        <b style={{ color: "#ccc" }}>Sticky Save button</b> — pinned to
        bottom via safeAreaInset, always visible without scrolling
      </div>
      <div>
        <span style={{ color: "#4ADE80" }}>2.</span>{" "}
        <b style={{ color: "#ccc" }}>Zone buttons 80→44pt</b> — horizontal
        icon+label layout, saves ~72pt total
      </div>
      <div>
        <span style={{ color: "#4ADE80" }}>3.</span>{" "}
        <b style={{ color: "#ccc" }}>Bonus cards → inline pills</b> —
        merged into zone section, eliminated 2 separate cards (~120pt saved)
      </div>
      <div>
        <span style={{ color: "#4ADE80" }}>4.</span>{" "}
        <b style={{ color: "#ccc" }}>Zone Matching → compact 1-row</b> —
        condensed from ~130pt to ~50pt
      </div>
      <div>
        <span style={{ color: "#4ADE80" }}>5.</span>{" "}
        <b style={{ color: "#ccc" }}>Summary → confirmation card</b> —
        moved below selectors, serves as "your choice" confirmation
      </div>
    </div>
    <div style={{ color: "#666", fontSize: 10 }}>
      Total vertical savings: ~300pt — entire screen fits without scrolling
      on iPhone SE and up
    </div>
  </div>
);

// ─── MAIN ───────────────────────────────────────────────

export default function CombatStanceReview() {
  return (
    <div
      className="min-h-screen p-6 flex flex-col items-center"
      style={{ background: "#08070E" }}
    >
      <h1
        className="text-lg font-bold tracking-widest mb-1"
        style={{ color: "#D4A537" }}
      >
        COMBAT STANCE — UX AUDIT
      </h1>
      <p className="text-xs mb-6" style={{ color: "#666" }}>
        Kuzya UI/UX Review · 2026-03-23
      </p>

      <div className="flex flex-wrap justify-center gap-8">
        <PhoneFrame label="BEFORE" labelColor="#E85D5D">
          <BeforeScreen />
        </PhoneFrame>
        <PhoneFrame label="AFTER" labelColor="#4ADE80">
          <AfterScreen />
        </PhoneFrame>
      </div>

      <Legend />
    </div>
  );
}