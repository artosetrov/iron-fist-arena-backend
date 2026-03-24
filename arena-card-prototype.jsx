import { useState } from "react";

// Design tokens from DarkFantasyTheme
const T = {
  bgAbyss: "#08080C",
  bgPrimary: "#0D0D12",
  bgSecondary: "#1A1A2E",
  bgTertiary: "#16213E",
  bgElevated: "#1E2240",
  gold: "#D4A537",
  goldBright: "#FFD700",
  danger: "#E63946",
  success: "#2ECC71",
  info: "#3498DB",
  purple: "#9B59B6",
  cyan: "#00D4FF",
  textPrimary: "#F5F5F5",
  textSecondary: "#A0A0B0",
  textTertiary: "#6B6B80",
  borderSubtle: "#2A2A3E",
  borderMedium: "#3A3A50",
  classWarrior: "#E68C33",
  classRogue: "#4DD958",
  classMage: "#6680FF",
  classTank: "#9999B2",
  diffEasy: "#2ECC71",
  diffMedium: "#F39C12",
  diffHard: "#E74C3C",
  rankBronze: "#B38040",
  rankSilver: "#BFBFCC",
  rankGold: "#FFD600",
  rankPlatinum: "#66CCCC",
};

const classColors = {
  WARRIOR: T.classWarrior,
  ROGUE: T.classRogue,
  MAGE: T.classMage,
  TANK: T.classTank,
};

const diffColors = {
  EASY: T.diffEasy,
  MEDIUM: T.diffMedium,
  HARD: T.diffHard,
};

const opponents = [
  {
    name: "Pipka6000",
    class: "WARRIOR",
    level: 4,
    rating: 1185,
    attack: 12,
    defense: 8,
    winRate: 83,
    difficulty: "EASY",
    avatar: "https://i.imgur.com/placeholder1.jpg",
  },
  {
    name: "Kuzya",
    class: "MAGE",
    level: 4,
    rating: 1225,
    attack: 6,
    defense: 14,
    winRate: 80,
    difficulty: "EASY",
    avatar: "https://i.imgur.com/placeholder2.jpg",
  },
  {
    name: "DarkLord99",
    class: "ROGUE",
    level: 7,
    rating: 1580,
    attack: 22,
    defense: 11,
    winRate: 71,
    difficulty: "HARD",
    avatar: "https://i.imgur.com/placeholder3.jpg",
  },
];

// Skeleton avatar with class icon
function SkeletonAvatar({ charClass, style }) {
  const icons = { WARRIOR: "⚔️", ROGUE: "🗡️", MAGE: "🔮", TANK: "🛡️" };
  return (
    <div
      style={{
        ...style,
        background: `linear-gradient(180deg, ${T.bgTertiary} 0%, ${T.bgAbyss} 100%)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: style.width ? Math.min(style.width, style.height || 200) * 0.35 : 48,
      }}
    >
      {icons[charClass] || "?"}
    </div>
  );
}

// ─── ORNAMENTAL PRIMITIVES ───

function CornerBrackets({ color = T.borderMedium, size = 16, thickness = 2 }) {
  const s = { position: "absolute", width: size, height: size };
  const border = `${thickness}px solid ${color}`;
  return (
    <>
      <div style={{ ...s, top: -1, left: -1, borderTop: border, borderLeft: border }} />
      <div style={{ ...s, top: -1, right: -1, borderTop: border, borderRight: border }} />
      <div style={{ ...s, bottom: -1, left: -1, borderBottom: border, borderLeft: border }} />
      <div style={{ ...s, bottom: -1, right: -1, borderBottom: border, borderRight: border }} />
    </>
  );
}

function CornerDiamonds({ color = T.borderMedium, size = 6 }) {
  const d = {
    position: "absolute",
    width: size,
    height: size,
    background: color,
    transform: "rotate(45deg)",
  };
  return (
    <>
      <div style={{ ...d, top: -size / 2, left: -size / 2 }} />
      <div style={{ ...d, top: -size / 2, right: -size / 2 }} />
      <div style={{ ...d, bottom: -size / 2, left: -size / 2 }} />
      <div style={{ ...d, bottom: -size / 2, right: -size / 2 }} />
    </>
  );
}

function AnimatedBorder({ color, radius = 16 }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: radius,
        overflow: "hidden",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: -2,
          borderRadius: radius,
          background: `conic-gradient(from var(--angle), ${color}88, ${color}22, ${color}55, ${color}11, ${color}88)`,
          animation: "rotateBorder 4s linear infinite",
          mask: `radial-gradient(farthest-side, transparent calc(100% - 3px), black calc(100% - 2px))`,
          WebkitMask: `radial-gradient(farthest-side, transparent calc(100% - 3px), black calc(100% - 2px))`,
        }}
      />
    </div>
  );
}

// Shimmer effect
function Shimmer({ radius = 16 }) {
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        borderRadius: radius,
        overflow: "hidden",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.06) 50%, transparent 60%)",
          animation: "shimmerMove 3s ease-in-out infinite",
        }}
      />
    </div>
  );
}

// ─── VARIANT A: Full-bleed avatar card (аватар на всю карту) ───

function CardVariantA({ opp, pressed, onPress }) {
  const dc = diffColors[opp.difficulty];
  const cc = classColors[opp.class];

  return (
    <div
      onClick={onPress}
      style={{
        position: "relative",
        width: 172,
        borderRadius: 16,
        overflow: "hidden",
        cursor: "pointer",
        transform: pressed ? "translateY(-4px)" : "translateY(0)",
        filter: pressed ? "brightness(0.94)" : "brightness(1)",
        transition: "all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)",
        boxShadow: `0 4px 20px ${dc}40, 0 2px 6px ${T.bgAbyss}cc`,
      }}
    >
      {/* Full-height avatar background */}
      <SkeletonAvatar
        charClass={opp.class}
        style={{
          width: "100%",
          height: 280,
          position: "absolute",
          top: 0,
          left: 0,
        }}
      />

      {/* Content overlay with gradient fade */}
      <div style={{ position: "relative", height: 280 }}>
        {/* Top: difficulty badge */}
        <div style={{ position: "absolute", top: 10, right: 10, zIndex: 3 }}>
          <div
            style={{
              padding: "3px 10px",
              borderRadius: 6,
              background: `${dc}20`,
              border: `1px solid ${dc}40`,
              fontSize: 11,
              fontWeight: 700,
              color: dc,
              fontFamily: "'Oswald', sans-serif",
              letterSpacing: 1,
            }}
          >
            {opp.difficulty}
          </div>
        </div>

        {/* Bottom fade: name + class + rating + stats */}
        <div
          style={{
            position: "absolute",
            bottom: 0,
            left: 0,
            right: 0,
            background: `linear-gradient(to bottom, transparent 0%, ${T.bgAbyss}44 25%, ${T.bgAbyss}cc 50%, ${T.bgAbyss}f5 75%, ${T.bgAbyss} 100%)`,
            padding: "60px 14px 14px",
            display: "flex",
            flexDirection: "column",
            gap: 4,
          }}
        >
          {/* Name */}
          <div
            style={{
              fontSize: 16,
              fontWeight: 700,
              color: T.textPrimary,
              fontFamily: "'Oswald', sans-serif",
              textShadow: `0 2px 8px ${T.bgAbyss}`,
              lineHeight: 1.1,
            }}
          >
            {opp.name}
          </div>

          {/* Class + Level */}
          <div
            style={{
              fontSize: 12,
              fontWeight: 600,
              color: cc,
              fontFamily: "'Oswald', sans-serif",
              textShadow: `0 1px 4px ${T.bgAbyss}`,
            }}
          >
            Lv.{opp.level} {opp.class}
          </div>

          {/* Rating — big */}
          <div
            style={{
              fontSize: 28,
              fontWeight: 800,
              color: T.textPrimary,
              fontFamily: "'Oswald', sans-serif",
              textShadow: `0 0 12px ${dc}50, 0 2px 4px ${T.bgAbyss}`,
              lineHeight: 1,
              marginTop: 2,
            }}
          >
            {opp.rating.toLocaleString()}
          </div>

          {/* Mini stats row */}
          <div
            style={{
              display: "flex",
              gap: 8,
              marginTop: 4,
              fontSize: 11,
              fontFamily: "'Inter', sans-serif",
            }}
          >
            <StatPill label="ATK" value={opp.attack} color={T.danger} />
            <StatPill label="DEF" value={opp.defense} color={T.info} />
            <StatPill label="WIN" value={`${opp.winRate}%`} color={T.success} />
          </div>
        </div>
      </div>

      {/* Animated glow border */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 16,
          border: `1.5px solid ${dc}55`,
          pointerEvents: "none",
          boxShadow: `inset 0 1px 0 ${dc}15, inset 0 -1px 0 ${T.bgAbyss}40`,
        }}
      />

      {/* Corner brackets */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <CornerBrackets color={`${dc}66`} size={14} thickness={1.5} />
        <CornerDiamonds color={`${dc}55`} size={5} />
      </div>

      <Shimmer />
    </div>
  );
}

// ─── VARIANT B: Cinematic wide card (горизонтальная кинематографичная) ───

function CardVariantB({ opp, pressed, onPress }) {
  const dc = diffColors[opp.difficulty];
  const cc = classColors[opp.class];

  return (
    <div
      onClick={onPress}
      style={{
        position: "relative",
        width: "100%",
        borderRadius: 14,
        overflow: "hidden",
        cursor: "pointer",
        transform: pressed ? "translateY(-3px)" : "translateY(0)",
        filter: pressed ? "brightness(0.94)" : "brightness(1)",
        transition: "all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)",
        boxShadow: `0 4px 16px ${dc}35, 0 2px 6px ${T.bgAbyss}cc`,
        display: "flex",
        height: 120,
        background: `linear-gradient(135deg, ${T.bgSecondary}, ${T.bgAbyss})`,
      }}
    >
      {/* Left: Avatar */}
      <div style={{ width: 100, height: "100%", flexShrink: 0, position: "relative" }}>
        <SkeletonAvatar
          charClass={opp.class}
          style={{ width: "100%", height: "100%" }}
        />
        {/* Right fade into card */}
        <div
          style={{
            position: "absolute",
            top: 0,
            right: 0,
            width: 40,
            height: "100%",
            background: `linear-gradient(to right, transparent, ${T.bgSecondary})`,
          }}
        />
      </div>

      {/* Right: Info */}
      <div
        style={{
          flex: 1,
          padding: "12px 14px 12px 4px",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          position: "relative",
        }}
      >
        {/* Top row: name + difficulty */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div
              style={{
                fontSize: 15,
                fontWeight: 700,
                color: T.textPrimary,
                fontFamily: "'Oswald', sans-serif",
                lineHeight: 1.1,
              }}
            >
              {opp.name}
            </div>
            <div
              style={{
                fontSize: 11,
                fontWeight: 600,
                color: cc,
                fontFamily: "'Oswald', sans-serif",
                marginTop: 2,
              }}
            >
              Lv.{opp.level} {opp.class}
            </div>
          </div>
          <div
            style={{
              padding: "2px 8px",
              borderRadius: 5,
              background: `${dc}18`,
              border: `1px solid ${dc}35`,
              fontSize: 10,
              fontWeight: 700,
              color: dc,
              fontFamily: "'Oswald', sans-serif",
              letterSpacing: 0.5,
            }}
          >
            {opp.difficulty}
          </div>
        </div>

        {/* Middle: Rating */}
        <div
          style={{
            fontSize: 26,
            fontWeight: 800,
            color: T.textPrimary,
            fontFamily: "'Oswald', sans-serif",
            textShadow: `0 0 10px ${dc}40`,
            lineHeight: 1,
          }}
        >
          {opp.rating.toLocaleString()}
        </div>

        {/* Bottom: stats */}
        <div style={{ display: "flex", gap: 6, fontSize: 11 }}>
          <StatPill label="ATK" value={opp.attack} color={T.danger} />
          <StatPill label="DEF" value={opp.defense} color={T.info} />
          <StatPill label="WIN" value={`${opp.winRate}%`} color={T.success} />
        </div>
      </div>

      {/* Border */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 14,
          border: `1.5px solid ${dc}44`,
          pointerEvents: "none",
        }}
      />
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <CornerBrackets color={`${dc}55`} size={12} thickness={1.5} />
      </div>
      <Shimmer radius={14} />
    </div>
  );
}

// ─── VARIANT C: Ultra-immersive (аватар на всю карту, статы = полупрозрачные пиллы) ───

function CardVariantC({ opp, pressed, onPress }) {
  const dc = diffColors[opp.difficulty];
  const cc = classColors[opp.class];

  return (
    <div
      onClick={onPress}
      style={{
        position: "relative",
        width: 172,
        height: 240,
        borderRadius: 16,
        overflow: "hidden",
        cursor: "pointer",
        transform: pressed ? "translateY(-4px)" : "translateY(0)",
        filter: pressed ? "brightness(0.94)" : "brightness(1)",
        transition: "all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)",
        boxShadow: `0 4px 20px ${dc}40, 0 2px 6px ${T.bgAbyss}cc`,
      }}
    >
      {/* Full avatar */}
      <SkeletonAvatar
        charClass={opp.class}
        style={{
          width: "100%",
          height: "100%",
          position: "absolute",
          top: 0,
          left: 0,
        }}
      />

      {/* Vignette overlay */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `
            radial-gradient(ellipse at center top, transparent 30%, ${T.bgAbyss}99 100%),
            linear-gradient(to bottom, transparent 40%, ${T.bgAbyss}ee 75%, ${T.bgAbyss} 100%)
          `,
        }}
      />

      {/* Content */}
      <div
        style={{
          position: "relative",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 12,
        }}
      >
        {/* Top row: level badge + difficulty */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          {/* Level circle */}
          <div
            style={{
              width: 28,
              height: 28,
              borderRadius: 14,
              background: `${T.bgAbyss}cc`,
              border: `1.5px solid ${cc}66`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 12,
              fontWeight: 700,
              color: cc,
              fontFamily: "'Oswald', sans-serif",
            }}
          >
            {opp.level}
          </div>

          <div
            style={{
              padding: "3px 8px",
              borderRadius: 6,
              background: `${dc}20`,
              border: `1px solid ${dc}40`,
              fontSize: 10,
              fontWeight: 700,
              color: dc,
              fontFamily: "'Oswald', sans-serif",
              letterSpacing: 0.8,
            }}
          >
            {opp.difficulty}
          </div>
        </div>

        {/* Bottom: all info */}
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {/* Name */}
          <div
            style={{
              fontSize: 16,
              fontWeight: 700,
              color: T.textPrimary,
              fontFamily: "'Oswald', sans-serif",
              textShadow: `0 2px 8px ${T.bgAbyss}`,
            }}
          >
            {opp.name}
          </div>

          {/* Class tag */}
          <div
            style={{
              display: "inline-flex",
              alignSelf: "flex-start",
              padding: "2px 8px",
              borderRadius: 4,
              background: `${cc}18`,
              border: `1px solid ${cc}30`,
              fontSize: 10,
              fontWeight: 600,
              color: cc,
              fontFamily: "'Oswald', sans-serif",
              letterSpacing: 0.5,
            }}
          >
            {opp.class}
          </div>

          {/* Rating */}
          <div
            style={{
              fontSize: 32,
              fontWeight: 800,
              color: T.textPrimary,
              fontFamily: "'Oswald', sans-serif",
              textShadow: `0 0 16px ${dc}60, 0 2px 4px ${T.bgAbyss}`,
              lineHeight: 1,
            }}
          >
            {opp.rating.toLocaleString()}
          </div>

          {/* Stat pills — glass morphism style */}
          <div style={{ display: "flex", gap: 4 }}>
            <GlassPill label="Attack" value={opp.attack} color={T.danger} />
            <GlassPill label="Defense" value={opp.defense} color={T.info} />
            <GlassPill label="Winrate" value={opp.winRate} color={T.success} suffix="%" />
          </div>
        </div>
      </div>

      {/* Border + ornaments */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: 16,
          border: `1.5px solid ${dc}44`,
          pointerEvents: "none",
          boxShadow: `inset 0 1px 0 rgba(255,255,255,0.06), inset 0 -2px 0 ${T.bgAbyss}60`,
        }}
      />
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
        <CornerBrackets color={`${dc}55`} size={14} thickness={1.5} />
        <CornerDiamonds color={`${dc}44`} size={5} />
      </div>
      <Shimmer />
    </div>
  );
}

// ─── Shared components ───

function StatPill({ label, value, color }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 3,
        fontFamily: "'Inter', sans-serif",
      }}
    >
      <span style={{ color: T.textTertiary, fontSize: 10, fontWeight: 500 }}>{label}</span>
      <span style={{ color, fontSize: 12, fontWeight: 700 }}>{value}</span>
    </div>
  );
}

function GlassPill({ label, value, color, suffix = "" }) {
  return (
    <div
      style={{
        flex: 1,
        padding: "4px 0",
        borderRadius: 6,
        background: `${T.bgAbyss}aa`,
        backdropFilter: "blur(8px)",
        WebkitBackdropFilter: "blur(8px)",
        border: `1px solid ${color}22`,
        textAlign: "center",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 1,
      }}
    >
      <span style={{ fontSize: 13, color, fontWeight: 700, fontFamily: "'Oswald', sans-serif" }}>
        {value}{suffix}
      </span>
      <span style={{ fontSize: 9, color: T.textTertiary, fontFamily: "'Inter', sans-serif", fontWeight: 500, letterSpacing: 0.3 }}>
        {label}
      </span>
    </div>
  );
}

// ─── MAIN APP ───

export default function ArenaCardPrototype() {
  const [pressedCard, setPressedCard] = useState(null);
  const [activeVariant, setActiveVariant] = useState("C"); // default to immersive

  return (
    <div
      style={{
        minHeight: "100vh",
        background: `linear-gradient(180deg, ${T.bgPrimary} 0%, ${T.bgAbyss} 100%)`,
        padding: 20,
        fontFamily: "'Inter', sans-serif",
      }}
    >
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Inter:wght@400;500;600;700&display=swap');

        @property --angle {
          syntax: "<angle>";
          initial-value: 0deg;
          inherits: false;
        }
        @keyframes rotateBorder {
          to { --angle: 360deg; }
        }
        @keyframes shimmerMove {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(100%); }
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
      `}</style>

      {/* Title */}
      <div style={{ textAlign: "center", marginBottom: 24 }}>
        <h1
          style={{
            fontSize: 20,
            fontWeight: 700,
            color: T.gold,
            fontFamily: "'Oswald', sans-serif",
            letterSpacing: 2,
            textTransform: "uppercase",
          }}
        >
          Arena Card Variants
        </h1>
        <p style={{ fontSize: 13, color: T.textSecondary, marginTop: 6 }}>
          Нажми на вариант чтобы сравнить
        </p>
      </div>

      {/* Variant switcher */}
      <div
        style={{
          display: "flex",
          justifyContent: "center",
          gap: 8,
          marginBottom: 24,
        }}
      >
        {["A", "B", "C"].map((v) => (
          <button
            key={v}
            onClick={() => setActiveVariant(v)}
            style={{
              padding: "8px 20px",
              borderRadius: 8,
              border: `1.5px solid ${activeVariant === v ? T.gold : T.borderSubtle}`,
              background: activeVariant === v ? `${T.gold}18` : T.bgSecondary,
              color: activeVariant === v ? T.gold : T.textSecondary,
              fontSize: 13,
              fontWeight: 600,
              fontFamily: "'Oswald', sans-serif",
              cursor: "pointer",
              letterSpacing: 1,
              transition: "all 0.2s",
            }}
          >
            {v === "A" && "Вертикальная"}
            {v === "B" && "Горизонтальная"}
            {v === "C" && "Иммерсивная"}
          </button>
        ))}
      </div>

      {/* Variant label */}
      <div
        style={{
          textAlign: "center",
          marginBottom: 16,
          padding: "8px 16px",
          background: `${T.bgSecondary}`,
          borderRadius: 8,
          border: `1px solid ${T.borderSubtle}`,
          maxWidth: 400,
          margin: "0 auto 20px",
        }}
      >
        <div style={{ fontSize: 14, fontWeight: 600, color: T.textPrimary, fontFamily: "'Oswald', sans-serif" }}>
          {activeVariant === "A" && "Вариант A: Аватар на всю карточку + фейд снизу"}
          {activeVariant === "B" && "Вариант B: Горизонтальная кинематографичная"}
          {activeVariant === "C" && "Вариант C: Полная иммерсия — всё поверх аватара"}
        </div>
        <div style={{ fontSize: 11, color: T.textTertiary, marginTop: 4 }}>
          {activeVariant === "A" && "Имя, класс и рейтинг в нижнем фейде. Статы — compact pills. Как мы уже начали делать."}
          {activeVariant === "B" && "Горизонтальная карточка — аватар слева, инфо справа. Экономит вертикальное пространство."}
          {activeVariant === "C" && "Максимальный эффект. Аватар — фон всей карточки. Все данные поверх через виньетку. Glass pills."}
        </div>
      </div>

      {/* Cards */}
      {activeVariant === "A" && (
        <div style={{ display: "flex", justifyContent: "center", gap: 16, flexWrap: "wrap" }}>
          {opponents.map((opp, i) => (
            <CardVariantA
              key={i}
              opp={opp}
              pressed={pressedCard === `A-${i}`}
              onPress={() => {
                setPressedCard(`A-${i}`);
                setTimeout(() => setPressedCard(null), 200);
              }}
            />
          ))}
        </div>
      )}

      {activeVariant === "B" && (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 12,
            maxWidth: 380,
            margin: "0 auto",
          }}
        >
          {opponents.map((opp, i) => (
            <CardVariantB
              key={i}
              opp={opp}
              pressed={pressedCard === `B-${i}`}
              onPress={() => {
                setPressedCard(`B-${i}`);
                setTimeout(() => setPressedCard(null), 200);
              }}
            />
          ))}
        </div>
      )}

      {activeVariant === "C" && (
        <div style={{ display: "flex", justifyContent: "center", gap: 16, flexWrap: "wrap" }}>
          {opponents.map((opp, i) => (
            <CardVariantC
              key={i}
              opp={opp}
              pressed={pressedCard === `C-${i}`}
              onPress={() => {
                setPressedCard(`C-${i}`);
                setTimeout(() => setPressedCard(null), 200);
              }}
            />
          ))}
        </div>
      )}

      {/* Design notes */}
      <div
        style={{
          maxWidth: 420,
          margin: "32px auto 0",
          padding: 16,
          background: T.bgSecondary,
          borderRadius: 12,
          border: `1px solid ${T.borderSubtle}`,
        }}
      >
        <div
          style={{
            fontSize: 14,
            fontWeight: 700,
            color: T.gold,
            fontFamily: "'Oswald', sans-serif",
            marginBottom: 10,
            letterSpacing: 1,
          }}
        >
          ◆ ДИЗАЙН ЗАМЕТКИ ◆
        </div>
        <div style={{ fontSize: 12, color: T.textSecondary, lineHeight: 1.6 }}>
          <p style={{ marginBottom: 8 }}>
            <strong style={{ color: T.textPrimary }}>Вариант A</strong> — то что мы уже сделали в коде.
            Аватар на ширину, фейд снизу, имя+класс в фейде. Рейтинг и статы ниже.
          </p>
          <p style={{ marginBottom: 8 }}>
            <strong style={{ color: T.textPrimary }}>Вариант B</strong> — горизонтальный лейаут.
            Хорош для списков (как лидерборд). Аватар слева с правым фейдом. Компактнее по высоте.
          </p>
          <p style={{ marginBottom: 8 }}>
            <strong style={{ color: T.textPrimary }}>Вариант C</strong> — максимальная иммерсия.
            Вся карточка = аватар. Виньетка + glass pills. Рейтинг огромный.
            Самый «геймовый» вариант — как в Genshin / AFK Arena.
          </p>
          <p style={{ color: T.gold }}>
            Все варианты используют: corner brackets, corner diamonds, shimmer,
            difficulty glow, class colors, dual shadows.
          </p>
        </div>
      </div>
    </div>
  );
}