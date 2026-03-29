import { useState, useEffect, useRef } from "react";

// ─── Цвета из DarkFantasyTheme ───────────────────────────────────────────────
const T = {
  bgPrimary:   "#0D1117",
  bgSecondary: "#141B26",
  bgTertiary:  "#1C2738",
  bgAbyss:     "#060A0F",
  gold:        "#D4A537",
  goldBright:  "#FFD700",
  goldDim:     "#8B6914",
  borderMedium:"#2E3D52",
  textPrimary: "#E8DCC8",
  textSecondary:"#A89880",
  danger:      "#C0392B",
  info:        "#3498DB",
  statSTR:     "#E74C3C",
  statAGI:     "#2ECC71",
  statVIT:     "#E91E63",
  statWIS:     "#9B59B6",
};

// ─── Иконки статов (emoji как плейсхолдер, в проде — Image assets) ───────────
const STAT_ICONS = { STR: "💪", AGI: "🪶", VIT: "❤️", WIS: "📖" };
const STAT_COLORS= { STR: T.statSTR, AGI: T.statAGI, VIT: T.statVIT, WIS: T.statWIS };

const STATS = [
  { key: "STR", label: "Strength", bonus: 3, max: 10 },
  { key: "AGI", label: "Agility",  bonus: 2, max: 10 },
  { key: "VIT", label: "Vitality", bonus: 2, max: 10 },
  { key: "WIS", label: "Wisdom",   bonus: 1, max: 10 },
];

// ─── Частицы-эмберы ────────────────────────────────────────────────────────
function useParticles(count = 18) {
  const [particles, setParticles] = useState(() =>
    Array.from({ length: count }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100 + 50,
      size: Math.random() * 3 + 1,
      speed: Math.random() * 0.3 + 0.1,
      opacity: Math.random() * 0.6 + 0.2,
      drift: (Math.random() - 0.5) * 0.4,
      delay: Math.random() * 4,
    }))
  );

  useEffect(() => {
    let raf;
    const tick = () => {
      setParticles(prev =>
        prev.map(p => {
          let ny = p.y - p.speed;
          let nx = p.x + p.drift;
          if (ny < -5) { ny = 105; nx = Math.random() * 100; }
          if (nx < 0)  nx = 100;
          if (nx > 100) nx = 0;
          return { ...p, x: nx, y: ny };
        })
      );
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);

  return particles;
}

// ─── Угловые скобки (SVG) ──────────────────────────────────────────────────
function CornerBrackets({ color = T.gold, size = 16, thickness = 1.5 }) {
  const s = { position: "absolute", width: size, height: size };
  const path = `M0,${size} L0,0 L${size},0`;
  const svg = (rot) => (
    <svg width={size} height={size} style={{ ...s, transform: `rotate(${rot}deg)` }}>
      <path d={path} fill="none" stroke={color} strokeWidth={thickness} opacity={0.7} />
    </svg>
  );
  return (
    <>
      <div style={{ ...s, top: 6, left: 6 }}>{svg(0)}</div>
      <div style={{ ...s, top: 6, right: 6 }}>{svg(90)}</div>
      <div style={{ ...s, bottom: 6, right: 6 }}>{svg(180)}</div>
      <div style={{ ...s, bottom: 6, left: 6 }}>{svg(270)}</div>
    </>
  );
}

// ─── Угловые ромбы ─────────────────────────────────────────────────────────
function CornerDiamond({ x, y, color = T.gold, size = 5 }) {
  return (
    <div style={{
      position: "absolute",
      [y]: -size / 2,
      [x]: -size / 2,
      width: size,
      height: size,
      background: color,
      transform: "rotate(45deg)",
      opacity: 0.8,
    }} />
  );
}

// ─── Горизонтальный разделитель ◆◇◆ ──────────────────────────────────────
function GoldDivider() {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 6, margin: "10px 0" }}>
      <div style={{ flex: 1, height: 1, background: `linear-gradient(to right, transparent, ${T.goldDim})` }} />
      <span style={{ color: T.gold, fontSize: 9, letterSpacing: 4, opacity: 0.9 }}>◆◇◆</span>
      <div style={{ flex: 1, height: 1, background: `linear-gradient(to left, transparent, ${T.goldDim})` }} />
    </div>
  );
}

// ─── Анимированная полоска стата ───────────────────────────────────────────
function StatBar({ stat, animated, delay }) {
  const [width, setWidth] = useState(0);
  const baseWidth = 40; // базовый % (из 10 очков)
  const bonusWidth = stat.bonus * 8; // каждый бонус +8%

  useEffect(() => {
    if (!animated) return;
    const t = setTimeout(() => setWidth(baseWidth + bonusWidth), delay);
    return () => clearTimeout(t);
  }, [animated]);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 5 }}>
          <span style={{ fontSize: 13 }}>{STAT_ICONS[stat.key]}</span>
          <span style={{ fontFamily: "'Oswald', sans-serif", fontSize: 13, color: T.textSecondary, letterSpacing: 1 }}>
            {stat.label.toUpperCase()}
          </span>
        </div>
        <span style={{
          fontFamily: "'Oswald', sans-serif",
          fontSize: 15,
          color: STAT_COLORS[stat.key],
          fontWeight: 700,
        }}>
          +{stat.bonus}
        </span>
      </div>
      {/* Полоска */}
      <div style={{
        height: 4,
        borderRadius: 2,
        background: `${T.borderMedium}88`,
        overflow: "hidden",
        position: "relative",
      }}>
        {/* Базовый fill */}
        <div style={{
          position: "absolute",
          left: 0, top: 0, bottom: 0,
          width: animated ? `${width}%` : `${baseWidth}%`,
          background: `${T.goldDim}`,
          borderRadius: 2,
          transition: "width 0.8s cubic-bezier(0.34, 1.56, 0.64, 1)",
        }} />
        {/* Бонусный fill поверх */}
        <div style={{
          position: "absolute",
          left: `${baseWidth}%`,
          top: 0, bottom: 0,
          width: animated ? `${bonusWidth}%` : "0%",
          background: STAT_COLORS[stat.key],
          borderRadius: "0 2px 2px 0",
          transition: `width 0.8s cubic-bezier(0.34, 1.56, 0.64, 1) ${delay + 200}ms`,
          boxShadow: `0 0 6px ${STAT_COLORS[stat.key]}`,
        }} />
        {/* Shine overlay */}
        <div style={{
          position: "absolute",
          inset: 0,
          background: "linear-gradient(to bottom, rgba(255,255,255,0.15), transparent)",
          borderRadius: 2,
        }} />
      </div>
    </div>
  );
}

// ─── Основной компонент ────────────────────────────────────────────────────
export default function HeroCard() {
  const particles = useParticles(20);
  const [mounted, setMounted]   = useState(false);
  const [shimmer, setShimmer]   = useState(false);
  const [name, setName]         = useState("");
  const [hovered, setHovered]   = useState(false);
  const [tiltX, setTiltX]       = useState(0);
  const [tiltY, setTiltY]       = useState(0);
  const cardRef = useRef(null);

  useEffect(() => {
    setTimeout(() => setMounted(true), 100);
    // Переодический shimmer
    const iv = setInterval(() => {
      setShimmer(true);
      setTimeout(() => setShimmer(false), 900);
    }, 5000);
    return () => clearInterval(iv);
  }, []);

  // 3D tilt on mouse/touch
  const handleMouseMove = (e) => {
    if (!cardRef.current) return;
    const rect = cardRef.current.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = (e.clientX - cx) / (rect.width / 2);
    const dy = (e.clientY - cy) / (rect.height / 2);
    setTiltX(dy * -8);
    setTiltY(dx * 8);
  };
  const handleMouseLeave = () => { setTiltX(0); setTiltY(0); setHovered(false); };

  // Floating animation (keyframes via style tag)
  const floatKF = `
    @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;600;700&family=Inter:wght@400;600&display=swap');
    @keyframes float {
      0%,100% { transform: translateY(0px); }
      50%      { transform: translateY(-6px); }
    }
    @keyframes pulseGlow {
      0%,100% { opacity: 0.5; }
      50%      { opacity: 1; }
    }
    @keyframes scanline {
      0%   { transform: translateY(-100%); }
      100% { transform: translateY(200%); }
    }
    @keyframes borderSpin {
      0%   { background-position: 0% 50%; }
      100% { background-position: 200% 50%; }
    }
    @keyframes entrySlide {
      from { opacity: 0; transform: translateY(32px) scale(0.94); }
      to   { opacity: 1; transform: translateY(0) scale(1); }
    }
    @keyframes shimmerSlide {
      from { transform: translateX(-100%) skewX(-20deg); }
      to   { transform: translateX(300%) skewX(-20deg); }
    }
    @keyframes levelPulse {
      0%,100% { box-shadow: 0 0 8px ${T.goldBright}88; }
      50%      { box-shadow: 0 0 20px ${T.goldBright}, 0 0 40px ${T.goldBright}44; }
    }
  `;

  const cardStyle = {
    position: "relative",
    width: 320,
    borderRadius: 18,
    background: `radial-gradient(ellipse at 50% 0%, ${T.bgTertiary} 0%, ${T.bgSecondary} 55%, ${T.bgAbyss} 100%)`,
    border: `1.5px solid ${T.goldDim}55`,
    boxShadow: hovered
      ? `0 0 40px ${T.gold}55, 0 20px 60px ${T.bgAbyss}, inset 0 1px 0 ${T.gold}30`
      : `0 0 20px ${T.gold}22, 0 12px 40px ${T.bgAbyss}CC, inset 0 1px 0 ${T.gold}18`,
    transform: `perspective(800px) rotateX(${tiltX}deg) rotateY(${tiltY}deg)`,
    transition: "box-shadow 0.3s ease, transform 0.15s ease",
    animation: mounted ? "float 4s ease-in-out infinite, entrySlide 0.5s ease-out forwards" : "none",
    overflow: "hidden",
    cursor: "default",
    userSelect: "none",
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: `radial-gradient(ellipse at 50% 30%, #1a1025 0%, ${T.bgAbyss} 70%)`,
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      padding: "32px 16px",
      fontFamily: "'Inter', sans-serif",
      position: "relative",
      overflow: "hidden",
    }}>
      <style>{floatKF}</style>

      {/* ── Фоновые частицы-эмберы ── */}
      <div style={{ position: "fixed", inset: 0, pointerEvents: "none" }}>
        {particles.map(p => (
          <div key={p.id} style={{
            position: "absolute",
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.size,
            height: p.size,
            borderRadius: "50%",
            background: p.size > 3 ? T.gold : T.goldDim,
            opacity: p.opacity,
            boxShadow: p.size > 2.5 ? `0 0 ${p.size * 3}px ${T.gold}` : "none",
            transition: "none",
          }} />
        ))}
      </div>

      {/* ── Заголовок ── */}
      <div style={{
        marginBottom: 24,
        opacity: mounted ? 1 : 0,
        transform: mounted ? "translateY(0)" : "translateY(-12px)",
        transition: "all 0.5s ease 0.1s",
        textAlign: "center",
      }}>
        <div style={{ color: T.textSecondary, fontSize: 12, letterSpacing: 3, marginBottom: 4 }}>
          CHOOSE YOUR HERO
        </div>
        <div style={{
          fontFamily: "'Oswald', sans-serif",
          color: T.gold,
          fontSize: 11,
          letterSpacing: 6,
          textTransform: "uppercase",
          opacity: 0.6,
        }}>
          ◆ Character Creation ◆
        </div>
      </div>

      {/* ── Карточка героя ── */}
      <div
        ref={cardRef}
        style={cardStyle}
        onMouseMove={handleMouseMove}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={handleMouseLeave}
      >
        {/* Угловые ромбы */}
        <CornerDiamond x="left" y="top" color={T.gold} size={8} />
        <CornerDiamond x="right" y="top" color={T.gold} size={8} />
        <CornerDiamond x="left" y="bottom" color={T.gold} size={8} />
        <CornerDiamond x="right" y="bottom" color={T.gold} size={8} />

        {/* Угловые скобки */}
        <CornerBrackets color={T.gold} size={20} thickness={1.5} />

        {/* Внутренняя рамка (inner border) */}
        <div style={{
          position: "absolute",
          inset: 6,
          borderRadius: 14,
          border: `1px solid ${T.gold}15`,
          pointerEvents: "none",
        }} />

        {/* Surface lighting — верх светлее */}
        <div style={{
          position: "absolute",
          top: 0, left: 0, right: 0,
          height: "50%",
          borderRadius: "18px 18px 0 0",
          background: "linear-gradient(to bottom, rgba(255,255,255,0.06), transparent)",
          pointerEvents: "none",
        }} />

        {/* Shimmer sweep */}
        {shimmer && (
          <div style={{
            position: "absolute",
            inset: 0,
            background: "linear-gradient(105deg, transparent 40%, rgba(255,215,0,0.12) 50%, transparent 60%)",
            animation: "shimmerSlide 0.9s ease-in-out forwards",
            pointerEvents: "none",
            zIndex: 20,
          }} />
        )}

        {/* ── Портрет ── */}
        <div style={{ padding: "20px 20px 0", display: "flex", justifyContent: "center", position: "relative" }}>

          {/* Аура за портретом */}
          <div style={{
            position: "absolute",
            top: "50%",
            left: "50%",
            transform: "translate(-50%, -50%)",
            width: 200,
            height: 200,
            borderRadius: "50%",
            background: `radial-gradient(circle, ${T.gold}18 0%, transparent 70%)`,
            animation: "pulseGlow 3s ease-in-out infinite",
            pointerEvents: "none",
          }} />

          {/* Рамка портрета */}
          <div style={{
            position: "relative",
            width: 160,
            height: 160,
            borderRadius: 14,
            border: `2px solid ${T.gold}`,
            background: `linear-gradient(135deg, ${T.bgAbyss}, ${T.bgTertiary})`,
            overflow: "hidden",
            boxShadow: `0 0 20px ${T.gold}44, inset 0 0 20px ${T.bgAbyss}88`,
          }}>
            {/* Заглушка — аватар */}
            <div style={{
              width: "100%",
              height: "100%",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 80,
              background: `radial-gradient(ellipse at 50% 30%, ${T.bgTertiary}, ${T.bgAbyss})`,
            }}>
              🐺
            </div>

            {/* Нижний градиент на портрете */}
            <div style={{
              position: "absolute",
              bottom: 0, left: 0, right: 0,
              height: 50,
              background: `linear-gradient(to top, ${T.bgAbyss}CC, transparent)`,
            }} />
          </div>

          {/* Бейдж уровня */}
          <div style={{
            position: "absolute",
            top: 16,
            right: "calc(50% - 95px)",
            width: 28,
            height: 28,
            borderRadius: "50%",
            background: `radial-gradient(circle, ${T.goldBright}, ${T.goldDim})`,
            border: `1.5px solid ${T.bgAbyss}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: "'Oswald', sans-serif",
            fontSize: 13,
            fontWeight: 700,
            color: T.bgAbyss,
            animation: "levelPulse 2.5s ease-in-out infinite",
            zIndex: 5,
          }}>1</div>
        </div>

        {/* ── Раса / Класс ── */}
        <div style={{ padding: "14px 20px 0", textAlign: "center" }}>
          <div style={{ display: "flex", justifyContent: "center", alignItems: "center", gap: 10 }}>
            <span style={{ fontSize: 13 }}>⚙️</span>
            <span style={{
              fontFamily: "'Oswald', sans-serif",
              fontSize: 18,
              color: T.textPrimary,
              letterSpacing: 1,
            }}>Dogfolk</span>
            <span style={{ fontSize: 13 }}>⚔️</span>
            <span style={{
              fontFamily: "'Oswald', sans-serif",
              fontSize: 18,
              color: T.gold,
              letterSpacing: 1,
            }}>Warrior</span>
          </div>

          <div style={{
            marginTop: 4,
            fontSize: 12,
            color: T.textSecondary,
            letterSpacing: 2,
          }}>MALE</div>
        </div>

        {/* ── Разделитель ── */}
        <div style={{ padding: "0 20px" }}>
          <GoldDivider />
        </div>

        {/* ── Название класса ── */}
        <div style={{ textAlign: "center", marginBottom: 12 }}>
          <span style={{
            fontFamily: "'Oswald', sans-serif",
            fontSize: 14,
            color: T.gold,
            opacity: 0.8,
            letterSpacing: 3,
            textTransform: "uppercase",
          }}>Male Dogfolk Warrior</span>
        </div>

        {/* ── Статы ── */}
        <div style={{ padding: "0 20px 20px", display: "flex", flexDirection: "column", gap: 10 }}>
          {STATS.map((stat, i) => (
            <StatBar key={stat.key} stat={stat} animated={mounted} delay={300 + i * 120} />
          ))}
        </div>

        {/* ── Нижняя полоска (рейтинг класса) ── */}
        <div style={{
          borderTop: `1px solid ${T.gold}18`,
          padding: "10px 20px",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}>
          <span style={{ fontSize: 11, color: T.textSecondary, letterSpacing: 1 }}>CLASS BONUS</span>
          <div style={{ display: "flex", gap: 6 }}>
            {["STR", "STR", "AGI", "VIT", "WIS"].map((k, i) => (
              <div key={i} style={{
                width: 8,
                height: 8,
                borderRadius: "50%",
                background: i < 2 ? STAT_COLORS[k] : STAT_COLORS[k],
                opacity: 0.8,
                boxShadow: `0 0 4px ${STAT_COLORS[k]}`,
              }} />
            ))}
          </div>
        </div>
      </div>

      {/* ── Поле имени ── */}
      <div style={{
        marginTop: 24,
        width: 320,
        opacity: mounted ? 1 : 0,
        transform: mounted ? "translateY(0)" : "translateY(16px)",
        transition: "all 0.5s ease 0.4s",
      }}>
        <div style={{
          fontSize: 12,
          color: T.textSecondary,
          letterSpacing: 2,
          marginBottom: 8,
          textTransform: "uppercase",
        }}>Your Name</div>

        <div style={{ display: "flex", gap: 8 }}>
          {/* Поле ввода */}
          <div style={{
            flex: 1,
            borderRadius: 10,
            border: `1.5px solid ${name ? T.gold + "88" : T.borderMedium}`,
            background: `${T.bgSecondary}CC`,
            padding: "0 14px",
            display: "flex",
            alignItems: "center",
            transition: "border-color 0.2s",
            boxShadow: name ? `0 0 12px ${T.gold}22` : "none",
          }}>
            <input
              value={name}
              onChange={e => setName(e.target.value.slice(0, 16))}
              placeholder="Enter hero name..."
              maxLength={16}
              style={{
                background: "transparent",
                border: "none",
                outline: "none",
                color: T.textPrimary,
                fontFamily: "'Inter', sans-serif",
                fontSize: 15,
                width: "100%",
                padding: "14px 0",
              }}
            />
            <span style={{ fontSize: 11, color: T.textSecondary, whiteSpace: "nowrap" }}>
              {name.length}/16
            </span>
          </div>

          {/* Кнопка Random */}
          <div style={{
            width: 52,
            height: 52,
            borderRadius: 10,
            border: `1.5px solid ${T.gold}55`,
            background: `radial-gradient(circle, ${T.bgTertiary}, ${T.bgSecondary})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            fontSize: 22,
            boxShadow: `0 0 10px ${T.gold}22`,
          }}>
            🎲
          </div>
        </div>
      </div>

      {/* ── Кнопка Begin ── */}
      <div style={{
        marginTop: 16,
        width: 320,
        opacity: mounted ? 1 : 0,
        transform: mounted ? "translateY(0)" : "translateY(16px)",
        transition: "all 0.5s ease 0.6s",
      }}>
        <button style={{
          width: "100%",
          padding: "16px",
          borderRadius: 12,
          border: `1.5px solid ${T.gold}`,
          background: `linear-gradient(135deg, ${T.goldDim}CC, ${T.gold}CC, ${T.goldBright}88)`,
          color: T.bgAbyss,
          fontFamily: "'Oswald', sans-serif",
          fontSize: 18,
          letterSpacing: 4,
          fontWeight: 700,
          cursor: name ? "pointer" : "not-allowed",
          opacity: name ? 1 : 0.5,
          boxShadow: name ? `0 4px 20px ${T.gold}44` : "none",
          transition: "all 0.2s",
        }}>
          BEGIN JOURNEY
        </button>
      </div>
    </div>
  );
}
