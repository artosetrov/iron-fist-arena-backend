import { useState, useEffect } from "react";

// Dark Fantasy Theme tokens (matching DarkFantasyTheme.swift)
const theme = {
  bgAbyss: "#0A0A0F",
  bgPrimary: "#12121A",
  bgSecondary: "#1A1A26",
  bgTertiary: "#222233",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  textPrimary: "#E8E4DC",
  textSecondary: "#A09888",
  textTertiary: "#6B6358",
  textTertiaryAA: "#7A7168",
  borderSubtle: "#2A2A3A",
  borderMedium: "#3A3A4E",
  danger: "#C94444",
  info: "#4A8EC9",
  success: "#4A9960",
  difficultyEasy: "#2ECC71",
  difficultyMedium: "#F39C12",
  difficultyHard: "#E74C3C",
};

const classData = {
  warrior: { icon: "⚔️", color: "#C94444", name: "WARRIOR", gradient: "linear-gradient(135deg, #8B2020, #C94444)" },
  rogue: { icon: "🗡️", color: "#9B59B6", name: "ROGUE", gradient: "linear-gradient(135deg, #5B2D8E, #9B59B6)" },
  mage: { icon: "✨", color: "#4A8EC9", name: "MAGE", gradient: "linear-gradient(135deg, #1E4D7B, #4A8EC9)" },
  tank: { icon: "🛡️", color: "#4A9960", name: "TANK", gradient: "linear-gradient(135deg, #1E5930, #4A9960)" },
};

// Placeholder avatar backgrounds per class
const avatarBg = {
  warrior: "linear-gradient(180deg, #3A1515 0%, #1A0A0A 100%)",
  rogue: "linear-gradient(180deg, #2A1535 0%, #120A1A 100%)",
  mage: "linear-gradient(180deg, #152535 0%, #0A101A 100%)",
  tank: "linear-gradient(180deg, #153525 0%, #0A1A10 100%)",
};

const mockCharacters = [
  {
    id: "1",
    characterName: "Грозный Кузнец",
    class: "warrior",
    origin: "orc",
    level: 24,
    pvpRating: 1450,
    avatar: "orc-warrior-male",
    currentHp: 340,
    maxHp: 420,
    strength: 42,
    vitality: 38,
    winRate: 64,
  },
  {
    id: "2",
    characterName: "Тень Ночи",
    class: "rogue",
    origin: "demon",
    level: 12,
    pvpRating: 1120,
    avatar: "demon-rogue-female",
    currentHp: 180,
    maxHp: 180,
    strength: 28,
    vitality: 18,
    winRate: 52,
  },
  {
    id: "3",
    characterName: "Элдрик",
    class: "mage",
    origin: "human",
    level: 8,
    pvpRating: 980,
    avatar: "human-mage-male",
    currentHp: 95,
    maxHp: 140,
    strength: 12,
    vitality: 15,
    winRate: 41,
  },
];

// --- Ornamental Components ---

const CornerBrackets = ({ color = theme.gold, opacity = 0.5, length = 14 }) => {
  const style = { position: "absolute", inset: 0, pointerEvents: "none" };
  const b = (top, left, right, bottom, flipX, flipY) => ({
    position: "absolute",
    width: length,
    height: length,
    borderColor: color,
    opacity,
    ...(top !== undefined && { top }),
    ...(bottom !== undefined && { bottom }),
    ...(left !== undefined && { left }),
    ...(right !== undefined && { right }),
    borderTopWidth: flipY ? 0 : 1.5,
    borderBottomWidth: flipY ? 1.5 : 0,
    borderLeftWidth: flipX ? 0 : 1.5,
    borderRightWidth: flipX ? 1.5 : 0,
    borderStyle: "solid",
  });
  return (
    <div style={style}>
      <div style={b(4, 4, undefined, undefined, false, false)} />
      <div style={b(4, undefined, 4, undefined, true, false)} />
      <div style={b(undefined, 4, undefined, 4, false, true)} />
      <div style={b(undefined, undefined, 4, 4, true, true)} />
    </div>
  );
};

const CornerDiamonds = ({ color = theme.gold, opacity = 0.4, size = 5 }) => {
  const d = (top, left, right, bottom) => ({
    position: "absolute",
    width: size,
    height: size,
    background: color,
    opacity,
    transform: "rotate(45deg)",
    ...(top !== undefined && { top }),
    ...(bottom !== undefined && { bottom }),
    ...(left !== undefined && { left }),
    ...(right !== undefined && { right }),
  });
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <div style={d(2, 2)} />
      <div style={d(2, undefined, 2)} />
      <div style={d(undefined, 2, undefined, 2)} />
      <div style={d(undefined, undefined, 2, 2)} />
    </div>
  );
};

const DiamondDivider = () => (
  <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 6, padding: "8px 0", opacity: 0.4 }}>
    <div style={{ flex: 1, height: 1, background: `linear-gradient(90deg, transparent, ${theme.gold})` }} />
    <div style={{ width: 5, height: 5, background: theme.gold, transform: "rotate(45deg)" }} />
    <div style={{ width: 7, height: 7, border: `1px solid ${theme.gold}`, transform: "rotate(45deg)" }} />
    <div style={{ width: 5, height: 5, background: theme.gold, transform: "rotate(45deg)" }} />
    <div style={{ flex: 1, height: 1, background: `linear-gradient(270deg, transparent, ${theme.gold})` }} />
  </div>
);

// --- Animated Border (CSS keyframe via style tag) ---
const AnimatedBorderStyle = () => (
  <style>{`
    @keyframes rotateBorder { from { --angle: 0deg; } to { --angle: 360deg; } }
    @keyframes shimmer { 0% { transform: translateX(-150%); } 100% { transform: translateX(250%); } }
    @keyframes selectedPulse { 0%,100% { box-shadow: 0 0 12px rgba(212,165,55,0.25), 0 4px 8px rgba(10,10,15,0.5); } 50% { box-shadow: 0 0 24px rgba(212,165,55,0.4), 0 4px 12px rgba(10,10,15,0.6); } }
    .hero-card { transition: transform 0.2s ease, filter 0.15s ease; }
    .hero-card:active { transform: scale(0.97); filter: brightness(0.94); }
    .hero-card.selected { animation: selectedPulse 2s ease-in-out infinite; }
    .shimmer-overlay { position: absolute; top: 0; left: 0; width: 40%; height: 100%; background: linear-gradient(105deg, transparent, rgba(255,255,255,0.05), transparent); animation: shimmer 3s ease-in-out infinite; pointer-events: none; border-radius: 16px; }
  `}</style>
);

// --- Arena-Style Hero Card ---

const HeroCard = ({ character, isSelected, onSelect }) => {
  const cls = classData[character.class];
  const glowColor = cls.color;
  const hpPct = Math.round((character.currentHp / character.maxHp) * 100);
  const isLowHp = hpPct < 50;

  return (
    <button
      onClick={() => onSelect(character)}
      className={`hero-card ${isSelected ? "selected" : ""}`}
      style={{
        position: "relative",
        width: "100%",
        aspectRatio: "1 / 1.4",
        borderRadius: 16,
        overflow: "hidden",
        border: isSelected ? `2px solid ${theme.gold}88` : `1.5px solid ${theme.borderSubtle}`,
        cursor: "pointer",
        padding: 0,
        background: "none",
        outline: "none",
        fontFamily: "inherit",
        boxShadow: isSelected
          ? `0 0 16px ${theme.gold}33, 0 4px 12px ${theme.bgAbyss}88`
          : `0 0 8px ${glowColor}18, 0 2px 6px ${theme.bgAbyss}55`,
      }}
    >
      {/* Avatar background (placeholder — in real app this is AvatarImageView) */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: avatarBg[character.class],
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <div style={{ fontSize: 72, opacity: 0.3 }}>{cls.icon}</div>
      </div>

      {/* Radial vignette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at 50% 35%, transparent 25%, ${theme.bgAbyss}80 85%)`,
          pointerEvents: "none",
        }}
      />

      {/* Bottom fade for text */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: "65%",
          background: `linear-gradient(180deg, transparent 0%, transparent 10%, ${theme.bgAbyss}66 35%, ${theme.bgAbyss}cc 55%, ${theme.bgAbyss}f2 75%, ${theme.bgAbyss} 100%)`,
          pointerEvents: "none",
        }}
      />

      {/* Shimmer overlay */}
      {isSelected && <div className="shimmer-overlay" />}

      {/* Content overlay */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 14,
        }}
      >
        {/* Top badges */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          {/* Level circle */}
          <div
            style={{
              width: 28,
              height: 28,
              borderRadius: 14,
              background: `${theme.bgAbyss}bf`,
              border: `1.5px solid ${cls.color}80`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 12,
              fontWeight: 700,
              color: cls.color,
              fontFamily: "'Oswald', sans-serif",
            }}
          >
            {character.level}
          </div>

          {/* HP badge (instead of difficulty) */}
          {isLowHp && (
            <div
              style={{
                fontSize: 11,
                fontWeight: 700,
                color: theme.danger,
                background: `${theme.danger}1f`,
                borderRadius: 6,
                padding: "2px 8px",
                border: `0.5px solid ${theme.danger}40`,
                fontFamily: "'Oswald', sans-serif",
                letterSpacing: 0.5,
              }}
            >
              LOW HP
            </div>
          )}
        </div>

        {/* Bottom info */}
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {/* Name */}
          <div
            style={{
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: 600,
              fontFamily: "'Oswald', sans-serif",
              letterSpacing: 0.5,
              textShadow: `0 2px 6px ${theme.bgAbyss}e6`,
              lineHeight: 1.2,
            }}
          >
            {character.characterName}
          </div>

          {/* Class tag pill */}
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <span
              style={{
                fontSize: 10,
                fontWeight: 700,
                color: cls.color,
                background: `${cls.color}1f`,
                borderRadius: 4,
                padding: "2px 8px",
                border: `0.5px solid ${cls.color}40`,
                fontFamily: "'Oswald', sans-serif",
                letterSpacing: 1,
              }}
            >
              {cls.name}
            </span>
            <span
              style={{
                fontSize: 10,
                color: theme.textTertiary,
                textTransform: "uppercase",
                letterSpacing: 0.5,
              }}
            >
              {character.origin}
            </span>
          </div>

          {/* Rating (dominant) */}
          <div
            style={{
              fontSize: 32,
              fontWeight: 700,
              color: theme.textPrimary,
              fontFamily: "'Oswald', sans-serif",
              lineHeight: 1,
              textShadow: `0 0 12px ${glowColor}66, 0 1px 3px ${theme.bgAbyss}99`,
            }}
          >
            {character.pvpRating}
          </div>

          {/* Glass stat pills (ATK / DEF / WIN%) */}
          <div style={{ display: "flex", gap: 4 }}>
            {[
              { label: "ATK", value: character.strength, color: theme.danger },
              { label: "DEF", value: character.vitality, color: theme.info },
              { label: "WIN%", value: `${character.winRate}%`, color: theme.success },
            ].map((stat) => (
              <div
                key={stat.label}
                style={{
                  flex: 1,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: 1,
                  padding: "5px 0",
                  background: `${theme.bgAbyss}a6`,
                  borderRadius: 6,
                  border: `0.5px solid ${stat.color}26`,
                }}
              >
                <div
                  style={{
                    fontSize: 13,
                    fontWeight: 700,
                    color: stat.color,
                    fontFamily: "'Oswald', sans-serif",
                    fontVariantNumeric: "tabular-nums",
                  }}
                >
                  {stat.value}
                </div>
                <div
                  style={{
                    fontSize: 9,
                    color: theme.textTertiaryAA,
                    letterSpacing: 0.5,
                    textTransform: "uppercase",
                  }}
                >
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Animated ornamental border overlays */}
      <CornerBrackets color={isSelected ? theme.gold : glowColor} opacity={isSelected ? 0.6 : 0.35} length={14} />
      <CornerDiamonds color={isSelected ? theme.gold : glowColor} opacity={isSelected ? 0.5 : 0.3} size={5} />

      {/* Selected checkmark */}
      {isSelected && (
        <div
          style={{
            position: "absolute",
            top: 10,
            right: 10,
            width: 24,
            height: 24,
            borderRadius: 12,
            background: `linear-gradient(135deg, ${theme.goldBright}, ${theme.gold})`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 14,
            color: theme.bgAbyss,
            fontWeight: 800,
            border: `1.5px solid ${theme.bgAbyss}80`,
            boxShadow: `0 0 8px ${theme.gold}44`,
          }}
        >
          ✓
        </div>
      )}
    </button>
  );
};

// --- Create Hero Card (arena-style dashed placeholder) ---

const CreateHeroCard = ({ slotsLeft, onClick }) => (
  <button
    onClick={onClick}
    className="hero-card"
    style={{
      position: "relative",
      width: "100%",
      aspectRatio: "1 / 1.4",
      borderRadius: 16,
      overflow: "hidden",
      border: `1.5px dashed ${theme.borderMedium}`,
      cursor: "pointer",
      padding: 0,
      background: theme.bgSecondary,
      outline: "none",
      fontFamily: "inherit",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      gap: 10,
    }}
  >
    <div
      style={{
        width: 48,
        height: 48,
        borderRadius: 24,
        background: theme.bgTertiary,
        border: `1.5px solid ${theme.borderMedium}`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 28,
        color: theme.gold,
        fontWeight: 300,
      }}
    >
      +
    </div>
    <div style={{ textAlign: "center" }}>
      <div
        style={{
          color: theme.textPrimary,
          fontSize: 14,
          fontWeight: 600,
          fontFamily: "'Oswald', sans-serif",
          letterSpacing: 0.8,
          textTransform: "uppercase",
        }}
      >
        Создать героя
      </div>
      <div style={{ color: theme.textTertiary, fontSize: 11, marginTop: 3 }}>
        {slotsLeft} из 5 слотов
      </div>
    </div>
  </button>
);

// --- Guest Banner ---

const GuestBanner = ({ onCreateAccount }) => (
  <div
    style={{
      position: "relative",
      padding: "10px 14px",
      borderRadius: 12,
      background: `linear-gradient(135deg, ${theme.gold}0d, ${theme.bgSecondary})`,
      border: `1px solid ${theme.gold}26`,
      display: "flex",
      alignItems: "center",
      gap: 10,
    }}
  >
    <div
      style={{
        width: 32,
        height: 32,
        borderRadius: 16,
        background: `${theme.gold}1a`,
        border: `1px solid ${theme.gold}33`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 16,
        flexShrink: 0,
      }}
    >
      ⚠
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ color: theme.goldBright, fontSize: 12, fontWeight: 600, fontFamily: "'Oswald', sans-serif", letterSpacing: 0.5 }}>
        Гостевой аккаунт
      </div>
      <div style={{ color: theme.textSecondary, fontSize: 11, marginTop: 1, lineHeight: 1.3 }}>
        Создай аккаунт, чтобы сохранить прогресс
      </div>
    </div>
    <button
      onClick={onCreateAccount}
      style={{
        padding: "7px 12px",
        borderRadius: 8,
        background: `linear-gradient(135deg, ${theme.goldBright}, ${theme.gold})`,
        border: "none",
        color: theme.bgAbyss,
        fontSize: 11,
        fontWeight: 700,
        cursor: "pointer",
        fontFamily: "'Oswald', sans-serif",
        letterSpacing: 0.8,
        textTransform: "uppercase",
        whiteSpace: "nowrap",
      }}
    >
      Создать
    </button>
  </div>
);

// --- Empty State ---

const EmptyState = ({ isGuest, onCreateHero, onCreateAccount }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "60px 24px", textAlign: "center", gap: 16, flex: 1 }}>
    <div style={{ fontSize: 56, opacity: 0.4 }}>⚔</div>
    <div style={{ color: theme.textPrimary, fontSize: 20, fontFamily: "'Oswald', sans-serif", letterSpacing: 1 }}>
      У тебя ещё нет героев
    </div>
    <div style={{ color: theme.textSecondary, fontSize: 14, maxWidth: 260, lineHeight: 1.4 }}>
      Создай своего первого героя и начни путешествие в мир Hexbound
    </div>
    <button
      onClick={onCreateHero}
      style={{
        marginTop: 8,
        padding: "14px 36px",
        borderRadius: 8,
        background: `linear-gradient(135deg, ${theme.goldBright}, ${theme.gold})`,
        border: "none",
        color: theme.bgAbyss,
        fontSize: 15,
        fontWeight: 700,
        cursor: "pointer",
        fontFamily: "'Oswald', sans-serif",
        letterSpacing: 1,
        textTransform: "uppercase",
        position: "relative",
        boxShadow: `0 0 24px ${theme.gold}33, 0 4px 12px ${theme.bgAbyss}88`,
      }}
    >
      <div style={{ position: "absolute", inset: 0, borderRadius: 8, background: "linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 50%, rgba(0,0,0,0.08) 100%)", pointerEvents: "none" }} />
      Создать героя
    </button>
    {isGuest && (
      <button
        onClick={onCreateAccount}
        style={{ marginTop: 4, padding: "10px 24px", borderRadius: 8, background: "transparent", border: `1px solid ${theme.borderMedium}`, color: theme.textSecondary, fontSize: 13, cursor: "pointer", fontFamily: "inherit" }}
      >
        Или создай аккаунт
      </button>
    )}
  </div>
);

// --- Main Screen ---

export default function CharacterSelectionScreen() {
  const [characters] = useState(mockCharacters);
  const [selectedId, setSelectedId] = useState(mockCharacters[0]?.id);
  const [isGuest, setIsGuest] = useState(true);
  const [screen, setScreen] = useState("list");
  const [enterPressed, setEnterPressed] = useState(false);

  const slotsLeft = 5 - characters.length;
  const selectedChar = characters.find((c) => c.id === selectedId);

  // Phone frame wrapper
  const PhoneFrame = ({ children }) => (
    <div
      style={{
        width: 390,
        height: 844,
        background: `radial-gradient(ellipse at 50% 15%, ${theme.bgTertiary}, ${theme.bgPrimary} 50%, ${theme.bgAbyss})`,
        fontFamily: "system-ui, -apple-system, sans-serif",
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
        borderRadius: 20,
        border: `1px solid ${theme.borderSubtle}`,
        margin: "0 auto",
        position: "relative",
      }}
    >
      <AnimatedBorderStyle />
      {children}
    </div>
  );

  // --- Empty screen ---
  if (screen === "empty") {
    return (
      <PhoneFrame>
        <div style={{ height: 56 }} />
        <div style={{ padding: "0 20px", textAlign: "center" }}>
          <div style={{ color: theme.goldBright, fontSize: 22, fontWeight: 700, fontFamily: "'Oswald', sans-serif", letterSpacing: 2, textTransform: "uppercase" }}>
            Выбор Героя
          </div>
        </div>
        <EmptyState isGuest={isGuest} onCreateHero={() => setScreen("list")} onCreateAccount={() => alert("→ RegisterDetailView")} />
        <div style={{ padding: "0 20px 20px" }}>
          <button onClick={() => setScreen("list")} style={{ width: "100%", padding: 10, borderRadius: 8, background: theme.bgTertiary, border: `1px solid ${theme.borderSubtle}`, color: theme.textTertiary, fontSize: 11, cursor: "pointer", fontFamily: "inherit" }}>
            [Demo] Показать список героев
          </button>
        </div>
      </PhoneFrame>
    );
  }

  // --- Main list screen ---
  return (
    <PhoneFrame>
      {/* Status bar */}
      <div style={{ height: 48 }} />

      {/* Header */}
      <div style={{ padding: "4px 20px 0", textAlign: "center" }}>
        <div style={{ color: theme.goldBright, fontSize: 22, fontWeight: 700, fontFamily: "'Oswald', sans-serif", letterSpacing: 2, textTransform: "uppercase" }}>
          Выбор Героя
        </div>
        <div style={{ color: theme.textTertiary, fontSize: 12, marginTop: 3, letterSpacing: 0.5 }}>
          Выбери героя для приключения
        </div>
      </div>

      <div style={{ padding: "0 20px" }}>
        <DiamondDivider />
      </div>

      {/* Guest banner */}
      {isGuest && (
        <div style={{ padding: "0 16px 8px" }}>
          <GuestBanner onCreateAccount={() => alert("→ RegisterDetailView")} />
        </div>
      )}

      {/* Hero cards grid (2 columns like Arena) */}
      <div
        style={{
          flex: 1,
          overflow: "auto",
          padding: "4px 16px 8px",
        }}
      >
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 16,
          }}
        >
          {characters.map((char) => (
            <HeroCard
              key={char.id}
              character={char}
              isSelected={char.id === selectedId}
              onSelect={(c) => setSelectedId(c.id)}
            />
          ))}

          {slotsLeft > 0 && (
            <CreateHeroCard
              slotsLeft={slotsLeft}
              onClick={() => alert("→ Onboarding")}
            />
          )}
        </div>
      </div>

      {/* Bottom CTA */}
      <div
        style={{
          padding: "0 16px 32px",
          background: `linear-gradient(180deg, transparent 0%, ${theme.bgAbyss}dd 25%, ${theme.bgAbyss} 100%)`,
          paddingTop: 16,
        }}
      >
        {/* Selected hero name preview */}
        {selectedChar && (
          <div style={{ textAlign: "center", marginBottom: 10 }}>
            <span style={{ color: theme.textSecondary, fontSize: 12 }}>Играть за </span>
            <span style={{ color: theme.goldBright, fontSize: 13, fontWeight: 600, fontFamily: "'Oswald', sans-serif" }}>
              {selectedChar.characterName}
            </span>
          </div>
        )}

        <button
          onClick={() => {
            setEnterPressed(true);
            setTimeout(() => setEnterPressed(false), 600);
          }}
          disabled={!selectedId}
          style={{
            width: "100%",
            padding: "16px 0",
            borderRadius: 8,
            background: selectedId
              ? `linear-gradient(135deg, ${theme.goldBright}, ${theme.gold})`
              : theme.bgTertiary,
            border: "none",
            color: selectedId ? theme.bgAbyss : theme.textTertiary,
            fontSize: 16,
            fontWeight: 700,
            cursor: selectedId ? "pointer" : "default",
            fontFamily: "'Oswald', sans-serif",
            letterSpacing: 1.5,
            textTransform: "uppercase",
            position: "relative",
            boxShadow: selectedId
              ? `0 0 24px ${theme.gold}44, 0 4px 12px ${theme.bgAbyss}88`
              : "none",
            transition: "all 0.15s ease",
            transform: enterPressed ? "scale(0.98)" : "scale(1)",
            filter: enterPressed ? "brightness(0.94)" : "brightness(1)",
            overflow: "hidden",
          }}
        >
          <div style={{ position: "absolute", inset: 0, borderRadius: 8, background: "linear-gradient(180deg, rgba(255,255,255,0.12) 0%, transparent 50%, rgba(0,0,0,0.08) 100%)", pointerEvents: "none" }} />
          {enterPressed ? "Входим..." : "Войти в игру"}
        </button>

        {/* Demo toggles */}
        <div style={{ display: "flex", gap: 8, marginTop: 10, justifyContent: "center" }}>
          <button onClick={() => setScreen("empty")} style={{ padding: "5px 10px", borderRadius: 6, background: theme.bgTertiary, border: `1px solid ${theme.borderSubtle}`, color: theme.textTertiary, fontSize: 10, cursor: "pointer", fontFamily: "inherit" }}>
            [Demo] Empty
          </button>
          <button onClick={() => setIsGuest(!isGuest)} style={{ padding: "5px 10px", borderRadius: 6, background: theme.bgTertiary, border: `1px solid ${theme.borderSubtle}`, color: theme.textTertiary, fontSize: 10, cursor: "pointer", fontFamily: "inherit" }}>
            [Demo] {isGuest ? "Hide" : "Show"} Guest
          </button>
        </div>
      </div>
    </PhoneFrame>
  );
}