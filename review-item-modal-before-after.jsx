import { useState } from "react";

const colors = {
  bgPrimary: "#0D0F14",
  bgSecondary: "#161A22",
  bgTertiary: "#1E232D",
  bgModal: "rgba(0,0,0,0.75)",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  textPrimary: "#E8E0D0",
  textSecondary: "#9C9484",
  textTertiary: "#6B6358",
  borderSubtle: "#2A2E38",
  borderOrnament: "#8B7732",
  rarityRare: "#4D80FF",
  rarityUncommon: "#4DCC4D",
  danger: "#E84040",
  success: "#4DCC4D",
  cyan: "#4DE8E8",
};

// Reusable components
const Badge = ({ text, color, small }) => (
  <span
    style={{
      display: "inline-block",
      padding: small ? "1px 6px" : "2px 8px",
      borderRadius: 99,
      fontSize: small ? 9 : 10,
      fontWeight: 700,
      letterSpacing: 1,
      color: color,
      background: `${color}22`,
      border: `1px solid ${color}55`,
    }}
  >
    {text}
  </span>
);

const Divider = ({ ornamental }) =>
  ornamental ? (
    <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "0 16px" }}>
      <div style={{ flex: 1, height: 1, background: `linear-gradient(to right, transparent, ${colors.goldDim}44, transparent)` }} />
      <div style={{ width: 5, height: 5, background: colors.goldDim, transform: "rotate(45deg)", opacity: 0.5 }} />
      <div style={{ flex: 1, height: 1, background: `linear-gradient(to right, transparent, ${colors.goldDim}44, transparent)` }} />
    </div>
  ) : (
    <div style={{ height: 1, background: colors.borderSubtle }} />
  );

const GoldIcon = ({ size = 14 }) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: "50%",
      background: `linear-gradient(135deg, ${colors.goldBright}, ${colors.gold})`,
      border: `1px solid ${colors.goldDim}`,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontSize: size * 0.55,
      fontWeight: 900,
      color: colors.bgPrimary,
    }}
  >
    G
  </div>
);

const GemIcon = ({ size = 14 }) => (
  <div
    style={{
      width: size,
      height: size,
      background: colors.cyan,
      transform: "rotate(45deg)",
      borderRadius: 2,
      opacity: 0.9,
    }}
  />
);

const CurrencyInline = ({ amount, type = "gold", size = 14 }) => (
  <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
    <span style={{ fontWeight: 700, fontSize: size, color: type === "gold" ? colors.goldBright : colors.cyan }}>
      {amount}
    </span>
    {type === "gold" ? <GoldIcon size={size} /> : <GemIcon size={size - 2} />}
  </span>
);

// Annotation badge
const Fix = ({ label, color = "#4DCC4D" }) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 4,
      padding: "2px 8px",
      borderRadius: 4,
      background: `${color}20`,
      border: `1px solid ${color}55`,
      fontSize: 9,
      fontWeight: 700,
      color: color,
      letterSpacing: 0.5,
      whiteSpace: "nowrap",
    }}
  >
    FIX: {label}
  </div>
);

// Phone frame
const PhoneFrame = ({ label, children }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
    <div
      style={{
        fontSize: 13,
        fontWeight: 800,
        letterSpacing: 3,
        color: label === "BEFORE" ? colors.danger : colors.success,
        textTransform: "uppercase",
      }}
    >
      {label}
    </div>
    <div
      style={{
        width: 320,
        minHeight: 560,
        borderRadius: 24,
        border: `2px solid ${colors.borderSubtle}`,
        background: colors.bgModal,
        overflow: "hidden",
        position: "relative",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 20,
      }}
    >
      {children}
    </div>
  </div>
);

// BEFORE — current shop item modal
const BeforeModal = () => (
  <div
    style={{
      width: "100%",
      borderRadius: 16,
      background: colors.bgSecondary,
      border: `2px solid ${colors.rarityRare}77`,
      boxShadow: `0 0 20px ${colors.rarityRare}30, 0 8px 32px ${colors.bgPrimary}cc`,
      overflow: "hidden",
    }}
  >
    {/* Header */}
    <div style={{ padding: 16, display: "flex", gap: 12, alignItems: "flex-start" }}>
      <div
        style={{
          width: 72,
          height: 72,
          borderRadius: 10,
          background: colors.bgTertiary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 28,
        }}
      >
        🪢
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: colors.rarityRare, fontWeight: 700, fontSize: 16 }}>Enchanted Girdle</div>
        <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
          <Badge text="Belt" color={colors.textSecondary} />
          <Badge text="RARE" color={colors.rarityRare} />
        </div>
        <div style={{ color: colors.textTertiary, fontSize: 12, marginTop: 4 }}>Level 1</div>
      </div>
      <button
        style={{
          background: "none",
          border: `1px solid ${colors.borderSubtle}`,
          borderRadius: 6,
          width: 28,
          height: 28,
          color: colors.textTertiary,
          cursor: "pointer",
          fontSize: 14,
        }}
      >
        ✕
      </button>
    </div>

    <Divider />

    {/* Stats */}
    <div style={{ padding: "12px 16px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
        <span style={{ fontSize: 11, color: colors.textTertiary, letterSpacing: 1.2 }}>● STATS</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between" }}>
        <div>
          <span style={{ color: colors.textSecondary, fontSize: 13 }}>Endurance</span>
          <span style={{ color: colors.gold, fontWeight: 700, marginLeft: 8, fontSize: 13 }}>+3</span>
        </div>
        <div>
          <span style={{ color: colors.textSecondary, fontSize: 13 }}>Vitality</span>
          <span style={{ color: colors.gold, fontWeight: 700, marginLeft: 8, fontSize: 13 }}>+1</span>
        </div>
      </div>
    </div>

    <Divider />

    {/* Description */}
    <div style={{ padding: "12px 16px" }}>
      <div style={{ color: colors.textTertiary, fontSize: 12, fontStyle: "italic", lineHeight: 1.5 }}>
        Enchanted Girdle — a rare belt touched by lingering magic...
      </div>
      {/* catalogId visible */}
      <div
        style={{
          color: `${colors.textTertiary}88`,
          fontSize: 10,
          fontFamily: "monospace",
          marginTop: 8,
        }}
      >
        loot_fe5a17b0-b001-4f88-ac96-999446f0a069
      </div>
    </div>

    <Divider />

    {/* Price — emoji */}
    <div style={{ padding: "12px 16px", textAlign: "center" }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: colors.goldBright }}>240 💎</div>
    </div>

    {/* BUY button — emoji in label */}
    <div style={{ padding: "0 16px 16px" }}>
      <button
        style={{
          width: "100%",
          height: 56,
          borderRadius: 8,
          background: `linear-gradient(180deg, ${colors.goldBright}, ${colors.gold})`,
          border: `2px solid ${colors.borderOrnament}`,
          color: colors.bgPrimary,
          fontWeight: 800,
          fontSize: 14,
          letterSpacing: 2,
          cursor: "pointer",
        }}
      >
        BUY 240 💎
      </button>
    </div>
  </div>
);

// AFTER — fixed shop item modal
const AfterModal = () => (
  <div
    style={{
      width: "100%",
      borderRadius: 16,
      background: colors.bgSecondary,
      border: `2px solid ${colors.rarityRare}77`,
      boxShadow: `0 0 20px ${colors.rarityRare}30, 0 8px 32px ${colors.bgPrimary}cc`,
      overflow: "hidden",
      position: "relative",
    }}
  >
    {/* Header */}
    <div style={{ padding: 16, display: "flex", gap: 12, alignItems: "flex-start" }}>
      <div
        style={{
          width: 72,
          height: 72,
          borderRadius: 10,
          background: colors.bgTertiary,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 28,
        }}
      >
        🪢
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: colors.rarityRare, fontWeight: 700, fontSize: 16 }}>Enchanted Girdle</div>
        <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
          <Badge text="Belt" color={colors.textSecondary} />
          <Badge text="RARE" color={colors.rarityRare} />
        </div>
        <div style={{ color: colors.textTertiary, fontSize: 12, marginTop: 4 }}>Level 1</div>
      </div>
      <button
        style={{
          background: "none",
          border: `1px solid ${colors.borderSubtle}`,
          borderRadius: 6,
          width: 28,
          height: 28,
          color: colors.textTertiary,
          cursor: "pointer",
          fontSize: 14,
        }}
      >
        ✕
      </button>
    </div>

    <Divider ornamental />

    {/* Stats */}
    <div style={{ padding: "12px 16px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
        <span style={{ fontSize: 11, color: colors.textTertiary, letterSpacing: 1.2 }}>● STATS</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between" }}>
        <div>
          <span style={{ color: colors.textSecondary, fontSize: 13 }}>Endurance</span>
          <span style={{ color: colors.gold, fontWeight: 700, marginLeft: 8, fontSize: 13 }}>+3</span>
        </div>
        <div>
          <span style={{ color: colors.textSecondary, fontSize: 13 }}>Vitality</span>
          <span style={{ color: colors.gold, fontWeight: 700, marginLeft: 8, fontSize: 13 }}>+1</span>
        </div>
      </div>
    </div>

    <Divider ornamental />

    {/* Description — NO catalogId */}
    <div style={{ padding: "12px 16px" }}>
      <div style={{ color: colors.textTertiary, fontSize: 12, fontStyle: "italic", lineHeight: 1.5 }}>
        Enchanted Girdle — a rare belt touched by lingering magic...
      </div>
      {/* catalogId REMOVED */}
    </div>

    <Divider ornamental />

    {/* Price — proper CurrencyDisplay */}
    <div style={{ padding: "12px 16px", textAlign: "center" }}>
      <CurrencyInline amount={240} type="gem" size={16} />
    </div>

    {/* BUY button — asset icon instead of emoji */}
    <div style={{ padding: "0 16px 16px" }}>
      <button
        style={{
          width: "100%",
          height: 56,
          borderRadius: 8,
          background: `linear-gradient(180deg, ${colors.goldBright}, ${colors.gold})`,
          border: `2px solid ${colors.borderOrnament}`,
          color: colors.bgPrimary,
          fontWeight: 800,
          fontSize: 14,
          letterSpacing: 2,
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 8,
        }}
      >
        BUY <CurrencyInline amount={240} type="gem" size={14} />
      </button>
    </div>

    {/* Fix annotations */}
    <div style={{ position: "absolute", top: -4, right: -4 }}>
      {/* Annotations positioned outside */}
    </div>
  </div>
);

// Inventory BEFORE — with emoji REPAIR button + no sell confirm
const BeforeInventory = () => (
  <div
    style={{
      width: "100%",
      borderRadius: 16,
      background: colors.bgSecondary,
      border: `2px solid ${colors.rarityUncommon}77`,
      boxShadow: `0 0 20px ${colors.rarityUncommon}30`,
      overflow: "hidden",
    }}
  >
    <div style={{ padding: 16, display: "flex", gap: 12, alignItems: "flex-start" }}>
      <div
        style={{ width: 56, height: 56, borderRadius: 10, background: colors.bgTertiary, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22 }}
      >
        ⚔
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: colors.rarityUncommon, fontWeight: 700, fontSize: 15 }}>Iron Blade +2</div>
        <div style={{ display: "flex", gap: 4, marginTop: 4 }}>
          <Badge text="Weapon" color={colors.textSecondary} small />
          <Badge text="UNCOMMON" color={colors.rarityUncommon} small />
        </div>
      </div>
    </div>

    <Divider />

    {/* Actions — emoji in buttons */}
    <div style={{ padding: "12px 16px", display: "flex", gap: 8 }}>
      <button
        style={{
          flex: 1,
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.gold}66`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
        }}
      >
        EQUIP
      </button>
      <button
        style={{
          flex: 1,
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.gold}66`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
        }}
      >
        SELL
      </button>
    </div>
    <div style={{ padding: "0 16px 12px" }}>
      <button
        style={{
          width: "100%",
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.gold}66`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
        }}
      >
        REPAIR · 12 💰
      </button>
    </div>
  </div>
);

// Inventory AFTER — asset currency + sell has confirm icon
const AfterInventory = () => (
  <div
    style={{
      width: "100%",
      borderRadius: 16,
      background: colors.bgSecondary,
      border: `2px solid ${colors.rarityUncommon}77`,
      boxShadow: `0 0 20px ${colors.rarityUncommon}30`,
      overflow: "hidden",
    }}
  >
    <div style={{ padding: 16, display: "flex", gap: 12, alignItems: "flex-start" }}>
      <div
        style={{ width: 56, height: 56, borderRadius: 10, background: colors.bgTertiary, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22 }}
      >
        ⚔
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: colors.rarityUncommon, fontWeight: 700, fontSize: 15 }}>Iron Blade +2</div>
        <div style={{ display: "flex", gap: 4, marginTop: 4 }}>
          <Badge text="Weapon" color={colors.textSecondary} small />
          <Badge text="UNCOMMON" color={colors.rarityUncommon} small />
        </div>
      </div>
    </div>

    <Divider ornamental />

    {/* Actions — asset currency + sell with ⚠ hint */}
    <div style={{ padding: "12px 16px", display: "flex", gap: 8 }}>
      <button
        style={{
          flex: 1,
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.gold}66`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
        }}
      >
        EQUIP
      </button>
      <button
        style={{
          flex: 1,
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.danger}44`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
          position: "relative",
        }}
      >
        SELL
      </button>
    </div>
    <div style={{ padding: "0 16px 12px" }}>
      <button
        style={{
          width: "100%",
          height: 44,
          borderRadius: 8,
          background: "transparent",
          border: `1.5px solid ${colors.gold}66`,
          color: colors.gold,
          fontWeight: 700,
          fontSize: 12,
          letterSpacing: 1.5,
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          gap: 6,
        }}
      >
        REPAIR · <CurrencyInline amount={12} type="gold" size={12} />
      </button>
    </div>
  </div>
);

// Main component
export default function ItemModalBeforeAfter() {
  const [view, setView] = useState("shop");

  return (
    <div
      style={{
        minHeight: "100vh",
        background: "#080A0E",
        fontFamily: "'Segoe UI', system-ui, sans-serif",
        padding: "32px 16px",
      }}
    >
      {/* Title */}
      <div style={{ textAlign: "center", marginBottom: 24 }}>
        <h1 style={{ color: colors.goldBright, fontSize: 20, fontWeight: 800, letterSpacing: 3, margin: 0 }}>
          ITEM MODAL AUDIT
        </h1>
        <p style={{ color: colors.textTertiary, fontSize: 12, marginTop: 6 }}>
          Before / After — Major & Critical fixes
        </p>
      </div>

      {/* Tab switcher */}
      <div
        style={{
          display: "flex",
          justifyContent: "center",
          gap: 8,
          marginBottom: 24,
        }}
      >
        {["shop", "inventory"].map((tab) => (
          <button
            key={tab}
            onClick={() => setView(tab)}
            style={{
              padding: "8px 20px",
              borderRadius: 8,
              background: view === tab ? `${colors.gold}22` : "transparent",
              border: `1px solid ${view === tab ? colors.gold : colors.borderSubtle}`,
              color: view === tab ? colors.gold : colors.textTertiary,
              fontWeight: 700,
              fontSize: 12,
              letterSpacing: 1.5,
              cursor: "pointer",
              textTransform: "uppercase",
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Side by side */}
      <div
        style={{
          display: "flex",
          gap: 24,
          justifyContent: "center",
          flexWrap: "wrap",
        }}
      >
        <PhoneFrame label="BEFORE">
          {view === "shop" ? <BeforeModal /> : <BeforeInventory />}
        </PhoneFrame>
        <PhoneFrame label="AFTER">
          {view === "shop" ? <AfterModal /> : <AfterInventory />}
        </PhoneFrame>
      </div>

      {/* Legend */}
      <div
        style={{
          maxWidth: 700,
          margin: "32px auto 0",
          padding: 20,
          borderRadius: 12,
          background: colors.bgSecondary,
          border: `1px solid ${colors.borderSubtle}`,
        }}
      >
        <div style={{ color: colors.goldBright, fontWeight: 700, fontSize: 13, letterSpacing: 1.5, marginBottom: 12 }}>
          CHANGES APPLIED
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <Fix label="CurrencyDisplay" />
            <span style={{ color: colors.textSecondary, fontSize: 12, lineHeight: 1.5 }}>
              Replaced all 💰💎 emoji with game asset icons (CurrencyDisplay component). Applies to price display, BUY button, REPAIR/UPGRADE buttons.
            </span>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <Fix label="catalogId hidden" />
            <span style={{ color: colors.textSecondary, fontSize: 12, lineHeight: 1.5 }}>
              Removed technical ID string from description section. Only shown in DEBUG builds.
            </span>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <Fix label="Ornamental dividers" />
            <span style={{ color: colors.textSecondary, fontSize: 12, lineHeight: 1.5 }}>
              Replaced flat 1px lines with EtchedGroove diamond-motif dividers matching premium chrome.
            </span>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <Fix label="Sell confirm" color={colors.danger} />
            <span style={{ color: colors.textSecondary, fontSize: 12, lineHeight: 1.5 }}>
              Added confirmationDialog for sell action (especially rare+ items) to prevent accidental loss.
            </span>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
            <Fix label="Sound timing" color="#E8A030" />
            <span style={{ color: colors.textSecondary, fontSize: 12, lineHeight: 1.5 }}>
              Moved upgrade success sound from button tap to after server response confirms result.
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
