import { useState } from "react";

// Hexbound Dark Fantasy Theme Colors
const theme = {
  bgAbyss: "#08080C",
  bgPrimary: "#0D0D12",
  bgSecondary: "#1A1A2E",
  bgTertiary: "#16213E",
  bgElevated: "#1E2240",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  borderSubtle: "#2A2A3E",
  borderMedium: "#3A3A50",
  borderStrong: "#4A4A60",
  borderOrnament: "#B8860B",
  textPrimary: "#F5F5F5",
  textSecondary: "#A0A0B0",
  textTertiary: "#6B6B80",
  danger: "#E63946",
};

// SVG Arrow Icon (matching ui-arrow-left style)
const ArrowLeft = ({ size = 20, color = theme.textPrimary }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
    <path d="M15 18l-6-6 6-6" />
  </svg>
);

// Corner Bracket (L-shaped)
const CornerBrackets = ({ color = theme.borderMedium, length = 10, thickness = 1.5 }) => (
  <svg style={{ position: "absolute", inset: 0, pointerEvents: "none" }} width="100%" height="100%">
    {/* Top-left */}
    <path d={`M0,${length} L0,0 L${length},0`} fill="none" stroke={color} strokeWidth={thickness} />
    {/* Top-right */}
    <path d={`M100%,0`} fill="none" stroke={color} strokeWidth={thickness} />
  </svg>
);

// Reusable button wrapper with press effect
const PressButton = ({ children, style, onClick }) => {
  const [pressed, setPressed] = useState(false);
  return (
    <button
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      onClick={onClick}
      style={{
        ...style,
        filter: pressed ? "brightness(0.94)" : "brightness(1)",
        cursor: "pointer",
        border: "none",
        background: "none",
        padding: 0,
        transition: "filter 0.1s ease",
      }}
    >
      {children}
    </button>
  );
};

// === OPTION A: Minimal (Current + fix) ===
const OptionA = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.goldBright, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      A — МИНИМАЛЬНЫЙ (ЧИСТАЯ СТРЕЛКА)
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Голая стрелка без фона. Текущий стиль, но с единым размером 28×28 на всех экранах. Самый чистый, не отвлекает от контента.
    </div>
    {/* Simulated navbar */}
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary, borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
    }}>
      <PressButton style={{ width: 44, height: 44, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <ArrowLeft size={28} color={theme.textPrimary} />
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === OPTION B: Gold Circle Badge ===
const OptionB = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.goldBright, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      B — ЗОЛОТОЕ КОЛЬЦО
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Тонкое золотое кольцо вокруг стрелки. Выглядит как средневековая монета/печать. Элегантно, но заметно.
    </div>
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary, borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
    }}>
      <PressButton>
        <div style={{
          width: 38, height: 38,
          borderRadius: "50%",
          border: `1.5px solid ${theme.gold}`,
          display: "flex", alignItems: "center", justifyContent: "center",
          background: "transparent",
          boxShadow: `0 0 8px ${theme.gold}22, inset 0 1px 0 rgba(255,255,255,0.06)`,
        }}>
          <ArrowLeft size={20} color={theme.gold} />
        </div>
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === OPTION C: Ornamental Diamond Panel ===
const OptionC = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.goldBright, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      C — ОРНАМЕНТАЛЬНАЯ ПАНЕЛЬ
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Мини-панель с RadialGlow фоном, innerBorder и угловыми скобками. Полностью в стиле дизайн-системы. Самый «тяжёлый» вариант — максимум fantasy-хром.
    </div>
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary, borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
    }}>
      <PressButton>
        <div style={{
          width: 42, height: 42, borderRadius: 8, position: "relative",
          background: `radial-gradient(circle at 50% 40%, ${theme.bgTertiary}, ${theme.bgSecondary})`,
          border: `1px solid ${theme.borderMedium}40`,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: `0 2px 6px ${theme.bgAbyss}88, 0 0 12px ${theme.gold}10`,
        }}>
          {/* Surface lighting overlay */}
          <div style={{
            position: "absolute", inset: 0, borderRadius: 7,
            background: "linear-gradient(180deg, rgba(255,255,255,0.07) 0%, transparent 50%, rgba(0,0,0,0.10) 100%)",
            pointerEvents: "none",
          }} />
          {/* Inner border */}
          <div style={{
            position: "absolute", inset: 2, borderRadius: 6,
            border: `1px solid ${theme.borderMedium}20`,
            pointerEvents: "none",
          }} />
          {/* Corner brackets (simplified CSS) */}
          <div style={{ position: "absolute", top: 1, left: 1, width: 8, height: 8, borderTop: `1.5px solid ${theme.borderMedium}50`, borderLeft: `1.5px solid ${theme.borderMedium}50`, pointerEvents: "none" }} />
          <div style={{ position: "absolute", top: 1, right: 1, width: 8, height: 8, borderTop: `1.5px solid ${theme.borderMedium}50`, borderRight: `1.5px solid ${theme.borderMedium}50`, pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: 1, left: 1, width: 8, height: 8, borderBottom: `1.5px solid ${theme.borderMedium}50`, borderLeft: `1.5px solid ${theme.borderMedium}50`, pointerEvents: "none" }} />
          <div style={{ position: "absolute", bottom: 1, right: 1, width: 8, height: 8, borderBottom: `1.5px solid ${theme.borderMedium}50`, borderRight: `1.5px solid ${theme.borderMedium}50`, pointerEvents: "none" }} />
          <ArrowLeft size={22} color={theme.textPrimary} />
        </div>
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === OPTION D: Etched Shield (Recommended) ===
const OptionD = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.goldBright, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      D — ГРАВИРОВАННЫЙ ЩИТ ⭐ РЕКОМЕНДАЦИЯ
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Закруглённый квадрат с едва заметным bgSecondary фоном и тонкой золотой обводкой. SurfaceLighting сверху. Баланс между минимализмом и fantasy-стилем. Не перегружает, но даёт «металлическую» тактильность.
    </div>
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary, borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
    }}>
      <PressButton>
        <div style={{
          width: 40, height: 40, borderRadius: 10, position: "relative",
          background: `${theme.bgSecondary}`,
          border: `1px solid ${theme.goldDim}55`,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: `0 2px 4px ${theme.bgAbyss}66`,
        }}>
          {/* Surface lighting */}
          <div style={{
            position: "absolute", inset: 0, borderRadius: 9,
            background: "linear-gradient(180deg, rgba(255,255,255,0.06) 0%, transparent 40%, rgba(0,0,0,0.08) 100%)",
            pointerEvents: "none",
          }} />
          <ArrowLeft size={22} color={theme.textPrimary} />
        </div>
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === OPTION E: Ghost Pill ===
const OptionE = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.goldBright, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      E — ПРИЗРАЧНАЯ ПИЛЮЛЯ
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Округлая капсула с полупрозрачным фоном. Появляется только при наведении/нажатии (ghost). Минимальное присутствие — стрелка как бы «парит» над контентом, фон видно только при интеракции.
    </div>
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary, borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
    }}>
      <PressButton>
        <div style={{
          width: 42, height: 36, borderRadius: 18, position: "relative",
          background: `${theme.bgSecondary}60`,
          border: `1px solid ${theme.borderSubtle}80`,
          display: "flex", alignItems: "center", justifyContent: "center",
          backdropFilter: "blur(4px)",
        }}>
          <ArrowLeft size={20} color={theme.textPrimary} />
        </div>
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === CURRENT (what it looks like now - the "problem") ===
const CurrentVersion = () => (
  <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
    <div style={{ color: theme.danger, fontFamily: "Oswald, sans-serif", fontSize: 14, fontWeight: 600, letterSpacing: 1 }}>
      ТЕКУЩИЙ ВАРИАНТ (ЧТО СЕЙЧАС)
    </div>
    <div style={{ color: theme.textSecondary, fontFamily: "Inter, sans-serif", fontSize: 12, marginBottom: 8 }}>
      Стрелка 28×28 без фона. На некоторых экранах iOS toolbar добавляет свою системную «плашку» (material background), которая выглядит как чужеродный серый блок.
    </div>
    <div style={{
      display: "flex", alignItems: "center", height: 56, padding: "0 16px",
      background: theme.bgPrimary,
      borderBottom: `1px solid ${theme.borderSubtle}`,
      borderRadius: 12,
      position: "relative",
    }}>
      {/* iOS-style material background simulation */}
      <div style={{
        position: "absolute", left: 8, top: 8, bottom: 8, width: 46,
        background: "rgba(60, 60, 67, 0.18)",
        borderRadius: 10,
        display: "flex", alignItems: "center", justifyContent: "center",
      }} />
      <PressButton style={{ position: "relative", zIndex: 1, width: 44, height: 44, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <ArrowLeft size={28} color={theme.textPrimary} />
      </PressButton>
      <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 18, color: theme.goldBright, letterSpacing: 1 }}>
        ARENA
      </div>
      <div style={{ width: 44 }} />
    </div>
  </div>
);

// === COMPARISON IN CONTEXT ===
const ContextDemo = ({ label, children }) => (
  <div style={{
    background: theme.bgPrimary,
    borderRadius: 16,
    overflow: "hidden",
    border: `1px solid ${theme.borderSubtle}`,
  }}>
    {/* Navbar */}
    {children}
    {/* Fake screen content */}
    <div style={{ padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      {/* UnifiedHeroWidget placeholder */}
      <div style={{
        background: `radial-gradient(circle at 50% 40%, ${theme.bgTertiary}, ${theme.bgSecondary})`,
        borderRadius: 12, padding: 16, height: 80,
        border: `1px solid ${theme.borderSubtle}`,
        display: "flex", alignItems: "center", gap: 12,
      }}>
        <div style={{ width: 52, height: 52, borderRadius: 26, background: theme.bgElevated, border: `2px solid ${theme.gold}` }} />
        <div style={{ flex: 1 }}>
          <div style={{ height: 14, background: theme.bgElevated, borderRadius: 4, width: "60%", marginBottom: 6 }} />
          <div style={{ height: 6, background: theme.danger + "60", borderRadius: 3, width: "80%" }} />
          <div style={{ height: 6, background: theme.gold + "40", borderRadius: 3, width: "45%", marginTop: 4 }} />
        </div>
      </div>
      {/* Cards placeholder */}
      <div style={{ display: "flex", gap: 8 }}>
        {[1, 2, 3].map(i => (
          <div key={i} style={{
            flex: 1, height: 100, borderRadius: 12,
            background: `radial-gradient(circle at 50% 30%, ${theme.bgTertiary}, ${theme.bgSecondary})`,
            border: `1px solid ${theme.borderSubtle}`,
          }} />
        ))}
      </div>
    </div>
  </div>
);

// Main App
export default function BackButtonConcepts() {
  const [selected, setSelected] = useState(null);

  return (
    <div style={{
      minHeight: "100vh",
      background: theme.bgAbyss,
      padding: 24,
      fontFamily: "Inter, system-ui, sans-serif",
      color: theme.textPrimary,
    }}>
      {/* Title */}
      <div style={{ textAlign: "center", marginBottom: 32 }}>
        <h1 style={{
          fontFamily: "Oswald, sans-serif",
          fontSize: 28,
          color: theme.goldBright,
          margin: 0,
          letterSpacing: 2,
        }}>
          HEXBOUND — BACK BUTTON
        </h1>
        <div style={{ width: 200, height: 1, background: `linear-gradient(90deg, transparent, ${theme.gold}, transparent)`, margin: "12px auto" }} />
        <p style={{ color: theme.textSecondary, fontSize: 14, margin: 0 }}>
          Варианты дизайна кнопки «назад» в стиле dark fantasy
        </p>
      </div>

      {/* Current Problem */}
      <div style={{
        background: `${theme.danger}10`,
        border: `1px solid ${theme.danger}30`,
        borderRadius: 12,
        padding: 20,
        marginBottom: 32,
      }}>
        <CurrentVersion />
      </div>

      {/* Options Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 32, maxWidth: 900, margin: "0 auto 32px" }}>
        {/* Option A */}
        <div style={{
          background: theme.bgSecondary,
          borderRadius: 16,
          padding: 20,
          border: `1px solid ${selected === "A" ? theme.gold : theme.borderSubtle}`,
          cursor: "pointer",
          transition: "border-color 0.2s",
        }} onClick={() => setSelected("A")}>
          <OptionA />
        </div>

        {/* Option B */}
        <div style={{
          background: theme.bgSecondary,
          borderRadius: 16,
          padding: 20,
          border: `1px solid ${selected === "B" ? theme.gold : theme.borderSubtle}`,
          cursor: "pointer",
          transition: "border-color 0.2s",
        }} onClick={() => setSelected("B")}>
          <OptionB />
        </div>

        {/* Option C */}
        <div style={{
          background: theme.bgSecondary,
          borderRadius: 16,
          padding: 20,
          border: `1px solid ${selected === "C" ? theme.gold : theme.borderSubtle}`,
          cursor: "pointer",
          transition: "border-color 0.2s",
        }} onClick={() => setSelected("C")}>
          <OptionC />
        </div>

        {/* Option D */}
        <div style={{
          background: theme.bgSecondary,
          borderRadius: 16,
          padding: 20,
          border: `1px solid ${selected === "D" ? theme.gold : theme.borderSubtle}`,
          cursor: "pointer",
          transition: "border-color 0.2s",
          boxShadow: `0 0 16px ${theme.gold}15`,
        }} onClick={() => setSelected("D")}>
          <OptionD />
        </div>

        {/* Option E - full width */}
        <div style={{
          gridColumn: "1 / -1",
          background: theme.bgSecondary,
          borderRadius: 16,
          padding: 20,
          border: `1px solid ${selected === "E" ? theme.gold : theme.borderSubtle}`,
          cursor: "pointer",
          transition: "border-color 0.2s",
        }} onClick={() => setSelected("E")}>
          <OptionE />
        </div>
      </div>

      {/* Context Comparison */}
      <div style={{ maxWidth: 900, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 20 }}>
          <h2 style={{
            fontFamily: "Oswald, sans-serif",
            fontSize: 20,
            color: theme.gold,
            margin: 0,
            letterSpacing: 1,
          }}>
            В КОНТЕКСТЕ ЭКРАНА
          </h2>
          <div style={{ width: 140, height: 1, background: `linear-gradient(90deg, transparent, ${theme.goldDim}, transparent)`, margin: "8px auto" }} />
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          {/* Context A */}
          <ContextDemo label="A">
            <div style={{
              display: "flex", alignItems: "center", height: 52, padding: "0 16px",
              borderBottom: `1px solid ${theme.borderSubtle}`,
            }}>
              <div style={{ width: 44, height: 44, display: "flex", alignItems: "center", justifyContent: "center" }}>
                <ArrowLeft size={28} color={theme.textPrimary} />
              </div>
              <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 16, color: theme.goldBright, letterSpacing: 1 }}>
                A — ЧИСТАЯ
              </div>
              <div style={{ width: 44 }} />
            </div>
          </ContextDemo>

          {/* Context B */}
          <ContextDemo label="B">
            <div style={{
              display: "flex", alignItems: "center", height: 52, padding: "0 16px",
              borderBottom: `1px solid ${theme.borderSubtle}`,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: "50%",
                border: `1.5px solid ${theme.gold}`,
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: `0 0 6px ${theme.gold}22`,
              }}>
                <ArrowLeft size={18} color={theme.gold} />
              </div>
              <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 16, color: theme.goldBright, letterSpacing: 1 }}>
                B — КОЛЬЦО
              </div>
              <div style={{ width: 44 }} />
            </div>
          </ContextDemo>

          {/* Context D */}
          <ContextDemo label="D">
            <div style={{
              display: "flex", alignItems: "center", height: 52, padding: "0 16px",
              borderBottom: `1px solid ${theme.borderSubtle}`,
            }}>
              <div style={{
                width: 38, height: 38, borderRadius: 8, position: "relative",
                background: theme.bgSecondary,
                border: `1px solid ${theme.goldDim}55`,
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: `0 2px 4px ${theme.bgAbyss}66`,
              }}>
                <div style={{
                  position: "absolute", inset: 0, borderRadius: 7,
                  background: "linear-gradient(180deg, rgba(255,255,255,0.06) 0%, transparent 40%, rgba(0,0,0,0.08) 100%)",
                  pointerEvents: "none",
                }} />
                <ArrowLeft size={20} color={theme.textPrimary} />
              </div>
              <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 16, color: theme.goldBright, letterSpacing: 1 }}>
                D — ЩИТ ⭐
              </div>
              <div style={{ width: 44 }} />
            </div>
          </ContextDemo>

          {/* Context E */}
          <ContextDemo label="E">
            <div style={{
              display: "flex", alignItems: "center", height: 52, padding: "0 16px",
              borderBottom: `1px solid ${theme.borderSubtle}`,
            }}>
              <div style={{
                width: 40, height: 34, borderRadius: 17,
                background: `${theme.bgSecondary}60`,
                border: `1px solid ${theme.borderSubtle}80`,
                display: "flex", alignItems: "center", justifyContent: "center",
              }}>
                <ArrowLeft size={18} color={theme.textPrimary} />
              </div>
              <div style={{ flex: 1, textAlign: "center", fontFamily: "Oswald, sans-serif", fontSize: 16, color: theme.goldBright, letterSpacing: 1 }}>
                E — ПРИЗРАК
              </div>
              <div style={{ width: 44 }} />
            </div>
          </ContextDemo>
        </div>
      </div>

      {/* Stats */}
      <div style={{
        maxWidth: 900, margin: "32px auto 0",
        background: theme.bgSecondary,
        borderRadius: 12,
        padding: 20,
        border: `1px solid ${theme.borderSubtle}`,
      }}>
        <div style={{ fontFamily: "Oswald, sans-serif", fontSize: 16, color: theme.gold, marginBottom: 12, letterSpacing: 1 }}>
          ТЕКУЩАЯ СИТУАЦИЯ
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, fontSize: 13, color: theme.textSecondary, fontFamily: "Inter, sans-serif" }}>
          <div>
            <span style={{ color: theme.goldBright, fontSize: 24, fontFamily: "Oswald, sans-serif" }}>27</span>
            <br />экранов с HubLogoButton
          </div>
          <div>
            <span style={{ color: theme.danger, fontSize: 24, fontFamily: "Oswald, sans-serif" }}>2</span>
            <br />экрана с другим размером (24×24)
          </div>
          <div>
            <span style={{ color: theme.textTertiary, fontSize: 24, fontFamily: "Oswald, sans-serif" }}>3</span>
            <br />спец. кейса (профиль, карта, email)
          </div>
        </div>
      </div>
    </div>
  );
}