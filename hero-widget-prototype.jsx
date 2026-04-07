import { useState } from "react";

// === Design Tokens (from DarkFantasyTheme) ===
const T = {
  bgAbyss: "#08080C",
  bgPrimary: "#0D0D12",
  bgSecondary: "#1A1A2E",
  bgTertiary: "#16213E",
  bgElevated: "#1E2240",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  danger: "#E63946",
  success: "#2ECC71",
  stamina: "#E67E22",
  staminaDark: "#D35400",
  purple: "#9B59B6",
  cyan: "#00D4FF",
  textPrimary: "#F5F5F5",
  textSecondary: "#A0A0B0",
  textGold: "#FFD700",
  textOnGold: "#1A1A2E",
  xpRing: "#5DADE2",
  xpRingTrack: "#2A2A4A",
  borderSubtle: "#2A2A3E",
  borderMedium: "#3A3A50",
  borderOrnament: "#B8860B",
  hpFull1: "#2ECC71",
  hpFull2: "#55EFC4",
  hpMed1: "#E67E22",
  hpMed2: "#F1C40F",
};

// === Shared sub-components ===

function Avatar({ size = 72 }) {
  const xpPercent = 0.65;
  const r = size / 2 - 3;
  const circ = 2 * Math.PI * r;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      {/* XP Ring */}
      <svg width={size} height={size} style={{ position: "absolute", top: 0, left: 0 }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={T.xpRingTrack} strokeWidth={3} />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={T.xpRing} strokeWidth={3}
          strokeDasharray={circ} strokeDashoffset={circ * (1 - xpPercent)}
          strokeLinecap="round" transform={`rotate(-90 ${size/2} ${size/2})`} />
      </svg>
      {/* Avatar placeholder */}
      <div style={{
        position: "absolute", top: 5, left: 5, right: 5, bottom: 5,
        borderRadius: 8, background: `linear-gradient(135deg, ${T.bgTertiary}, ${T.bgElevated})`,
        border: `1px dashed ${T.xpRing}`,
      }} />
      {/* Corner diamonds */}
      {[{t:-2,l:-2},{t:-2,r:-2},{b:-2,l:-2},{b:-2,r:-2}].map((pos, i) => (
        <div key={i} style={{
          position:"absolute", ...pos, width:5, height:5,
          background: T.gold, transform:"rotate(45deg)", opacity:0.5,
        }}/>
      ))}
      {/* Level badge */}
      <div style={{
        position: "absolute", bottom: -4, left: "50%", transform: "translateX(-50%)",
        background: T.bgSecondary, border: `1px solid ${T.xpRing}`,
        borderRadius: 8, padding: "1px 8px",
        fontFamily: "Inter, sans-serif", fontSize: 11, fontWeight: 700,
        color: T.textPrimary, whiteSpace: "nowrap",
      }}>Lv. 16</div>
    </div>
  );
}

function HPBar({ current = 245, max = 320 }) {
  const pct = current / max;
  return (
    <div style={{
      width: "100%", height: 22, borderRadius: 6,
      background: T.bgSecondary, position: "relative", overflow: "hidden",
    }}>
      <div style={{
        width: `${pct * 100}%`, height: "100%", borderRadius: 6,
        background: `linear-gradient(90deg, ${T.hpFull1}, ${T.hpFull2})`,
      }} />
      <span style={{
        position: "absolute", top: "50%", left: "50%",
        transform: "translate(-50%,-50%)",
        fontFamily: "Inter, sans-serif", fontSize: 13, fontWeight: 700,
        color: T.textPrimary, textShadow: "0 1px 3px rgba(0,0,0,0.7)",
      }}>{current} / {max}</span>
    </div>
  );
}

function StaminaBar({ current = 85, max = 120 }) {
  const pct = current / max;
  return (
    <div style={{
      width: "100%", height: 22, borderRadius: 6,
      background: T.bgSecondary, position: "relative", overflow: "hidden",
    }}>
      <div style={{
        width: `${pct * 100}%`, height: "100%", borderRadius: 6,
        background: `linear-gradient(90deg, ${T.stamina}, ${T.staminaDark})`,
      }} />
      <span style={{
        position: "absolute", top: "50%", left: "50%",
        transform: "translate(-50%,-50%)",
        fontFamily: "Inter, sans-serif", fontSize: 13, fontWeight: 700,
        color: T.textPrimary, textShadow: "0 1px 3px rgba(0,0,0,0.7)",
      }}>{current} / {max}</span>
    </div>
  );
}

function CurrencyRow({ children }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
      {children}
    </div>
  );
}

function CurrencyItem({ icon, value, color }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
      <span style={{ fontSize: 16 }}>{icon}</span>
      <span style={{
        fontFamily: "Inter, sans-serif", fontSize: 16, fontWeight: 800,
        color, fontStyle: "italic",
      }}>{value}</span>
    </div>
  );
}

// Stamina as inline resource (variant B)
function StaminaInline({ current = 85, max = 120 }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
      <span style={{ fontSize: 16 }}>⚡</span>
      <span style={{
        fontFamily: "Inter, sans-serif", fontSize: 16, fontWeight: 800,
        color: T.stamina, fontStyle: "italic",
      }}>{current}/{max}</span>
    </div>
  );
}

// Stamina as mini-bar + text (variant C)
function StaminaMini({ current = 85, max = 120 }) {
  const pct = current / max;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
      <span style={{ fontSize: 16 }}>⚡</span>
      <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        <span style={{
          fontFamily: "Inter, sans-serif", fontSize: 14, fontWeight: 700,
          color: T.stamina, lineHeight: 1,
        }}>{current}/{max}</span>
        <div style={{
          width: 60, height: 3, borderRadius: 2, background: T.bgSecondary,
          overflow: "hidden",
        }}>
          <div style={{
            width: `${pct*100}%`, height: "100%", borderRadius: 2,
            background: `linear-gradient(90deg, ${T.stamina}, ${T.staminaDark})`,
          }}/>
        </div>
      </div>
    </div>
  );
}

// === Card wrapper ===
function WidgetCard({ children, label, isActive, onClick }) {
  return (
    <div onClick={onClick} style={{
      position: "relative", cursor: "pointer",
      background: `linear-gradient(135deg, #1C1C30, #2A2A40)`,
      borderRadius: 12, padding: 12,
      border: `1px solid ${isActive ? T.gold : T.borderMedium}`,
      boxShadow: isActive
        ? `0 0 20px ${T.gold}33, inset 0 1px 0 rgba(255,255,255,0.06)`
        : `0 4px 12px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.06)`,
      transition: "all 0.3s ease",
    }}>
      {/* Surface lighting */}
      <div style={{
        position: "absolute", inset: 0, borderRadius: 12, pointerEvents: "none",
        background: "linear-gradient(180deg, rgba(255,255,255,0.06) 0%, rgba(0,0,0,0.08) 100%)",
      }}/>
      {/* Label */}
      <div style={{
        position: "absolute", top: -10, left: 12,
        background: isActive ? T.gold : T.bgElevated,
        color: isActive ? T.textOnGold : T.textSecondary,
        fontSize: 11, fontWeight: 700, fontFamily: "Inter, sans-serif",
        padding: "2px 10px", borderRadius: 6,
        border: `1px solid ${isActive ? T.gold : T.borderMedium}`,
        textTransform: "uppercase", letterSpacing: 1,
      }}>{label}</div>
      <div style={{ position: "relative", zIndex: 1 }}>{children}</div>
    </div>
  );
}

// === Widget Variants ===

function VariantA() {
  return (
    <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
      <Avatar />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <div style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 20, fontWeight: 600,
          color: T.textPrimary, textTransform: "uppercase", letterSpacing: 1.5,
          lineHeight: 1,
        }}>Shadowblade</div>
        <HPBar />
        <StaminaBar />
        <CurrencyRow>
          <CurrencyItem icon="🪙" value="12,450" color={T.textGold} />
          <CurrencyItem icon="💎" value="385" color="#C882FF" />
        </CurrencyRow>
      </div>
    </div>
  );
}

function VariantB() {
  return (
    <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
      <Avatar />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <div style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 20, fontWeight: 600,
          color: T.textPrimary, textTransform: "uppercase", letterSpacing: 1.5,
          lineHeight: 1,
        }}>Shadowblade</div>
        <HPBar />
        <CurrencyRow>
          <CurrencyItem icon="🪙" value="12,450" color={T.textGold} />
          <CurrencyItem icon="💎" value="385" color="#C882FF" />
          <StaminaInline />
        </CurrencyRow>
      </div>
    </div>
  );
}

function VariantC() {
  return (
    <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
      <Avatar />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <div style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 20, fontWeight: 600,
          color: T.textPrimary, textTransform: "uppercase", letterSpacing: 1.5,
          lineHeight: 1,
        }}>Shadowblade</div>
        <HPBar />
        <CurrencyRow>
          <CurrencyItem icon="🪙" value="12,450" color={T.textGold} />
          <CurrencyItem icon="💎" value="385" color="#C882FF" />
          <StaminaMini />
        </CurrencyRow>
      </div>
    </div>
  );
}

// Variant D: stamina as segmented pips
function StaminaPips({ current = 85, max = 120 }) {
  const segments = 6;
  const perSeg = max / segments;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
      <span style={{ fontSize: 14 }}>⚡</span>
      <div style={{ display: "flex", gap: 2, alignItems: "center" }}>
        {Array.from({ length: segments }).map((_, i) => {
          const segStart = i * perSeg;
          const fill = Math.min(1, Math.max(0, (current - segStart) / perSeg));
          return (
            <div key={i} style={{
              width: 16, height: 8, borderRadius: 2,
              background: T.bgSecondary, overflow: "hidden", position: "relative",
            }}>
              <div style={{
                width: `${fill * 100}%`, height: "100%",
                background: fill > 0.5 ? T.stamina : T.staminaDark,
                borderRadius: 2,
              }}/>
            </div>
          );
        })}
      </div>
      <span style={{
        fontFamily: "Inter, sans-serif", fontSize: 12, fontWeight: 600,
        color: T.stamina, marginLeft: 2,
      }}>{current}</span>
    </div>
  );
}

function VariantD() {
  return (
    <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
      <Avatar />
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 6 }}>
        <div style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 20, fontWeight: 600,
          color: T.textPrimary, textTransform: "uppercase", letterSpacing: 1.5,
          lineHeight: 1,
        }}>Shadowblade</div>
        <HPBar />
        <CurrencyRow>
          <CurrencyItem icon="🪙" value="12,450" color={T.textGold} />
          <CurrencyItem icon="💎" value="385" color="#C882FF" />
          <StaminaPips />
        </CurrencyRow>
      </div>
    </div>
  );
}

// === Main App ===
export default function HeroWidgetPrototype() {
  const [active, setActive] = useState("B");

  const variants = [
    { id: "A", label: "A — Текущий (две шкалы)", desc: "HP + Stamina как полные бары. Классика, но занимает больше вертикали.", comp: <VariantA /> },
    { id: "B", label: "B — Стамина в ряд ресурсов", desc: "Стамина как ⚡85/120 рядом с валютами. Компактно, стамина = расходуемый ресурс.", comp: <VariantB /> },
    { id: "C", label: "C — Мини-бар + текст", desc: "Текст + тонкий бар 3px под числом. Сохраняет ощущение заполненности без громоздкости.", comp: <VariantC /> },
    { id: "D", label: "D — Сегментные пипсы", desc: "6 сегментов + число. Как пипсы stamina в Souls-like. Визуально чёткое 'сколько действий осталось'.", comp: <VariantD /> },
  ];

  return (
    <div style={{
      minHeight: "100vh", background: T.bgAbyss,
      padding: 24, display: "flex", flexDirection: "column", gap: 32,
      fontFamily: "Inter, -apple-system, sans-serif",
    }}>
      {/* Title */}
      <div>
        <h1 style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 28,
          color: T.textPrimary, margin: 0, textTransform: "uppercase",
          letterSpacing: 2,
        }}>Hero Widget — Stamina Display</h1>
        <p style={{ color: T.textSecondary, fontSize: 14, marginTop: 8 }}>
          Нажми на карточку чтобы выбрать. Золотая рамка = активный вариант.
        </p>
      </div>

      {/* Variants grid */}
      <div style={{
        display: "grid", gridTemplateColumns: "1fr 1fr",
        gap: 28, maxWidth: 800,
      }}>
        {variants.map(v => (
          <div key={v.id} style={{ paddingTop: 12 }}>
            <WidgetCard
              label={v.id}
              isActive={active === v.id}
              onClick={() => setActive(v.id)}
            >
              {v.comp}
            </WidgetCard>
            <p style={{
              color: active === v.id ? T.textPrimary : T.textSecondary,
              fontSize: 12, marginTop: 10, lineHeight: 1.5,
              transition: "color 0.3s",
            }}>{v.desc}</p>
          </div>
        ))}
      </div>

      {/* Comparison section */}
      <div style={{
        background: T.bgSecondary, borderRadius: 12, padding: 20,
        maxWidth: 800, border: `1px solid ${T.borderSubtle}`,
      }}>
        <div style={{
          fontFamily: "'Oswald', sans-serif", fontSize: 18,
          color: T.gold, textTransform: "uppercase", letterSpacing: 1,
          marginBottom: 12,
        }}>Сравнение</div>
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13, color: T.textSecondary }}>
          <thead>
            <tr style={{ borderBottom: `1px solid ${T.borderSubtle}` }}>
              <th style={{ textAlign: "left", padding: "6px 8px", color: T.textPrimary }}>Критерий</th>
              {variants.map(v => (
                <th key={v.id} style={{
                  textAlign: "center", padding: "6px 8px",
                  color: active === v.id ? T.gold : T.textPrimary,
                }}>{v.id}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {[
              ["Компактность", "−", "++", "+", "+"],
              ["Читаемость заполнения", "++", "−", "+", "+"],
              ["\"Сколько действий?\"", "+", "+", "+", "++"],
              ["Визуальный вес", "Тяжёлый", "Лёгкий", "Средний", "Средний"],
              ["Game feel (dark fantasy)", "++", "+", "+", "++"],
            ].map(([label, ...vals], i) => (
              <tr key={i} style={{ borderBottom: `1px solid ${T.borderSubtle}22` }}>
                <td style={{ padding: "6px 8px", color: T.textPrimary }}>{label}</td>
                {vals.map((v, j) => (
                  <td key={j} style={{ textAlign: "center", padding: "6px 8px" }}>{v}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}