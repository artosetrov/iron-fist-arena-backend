import { useState, useEffect, useRef } from "react";

// ─── Floating Dust Particle System ───
function DustParticles() {
  const [particles] = useState(() =>
    Array.from({ length: 14 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      size: 2 + Math.random() * 3,
      duration: 8 + Math.random() * 12,
      delay: Math.random() * 6,
      opacity: 0.08 + Math.random() * 0.2,
      color: Math.random() > 0.5 ? "#D4A537" : "#8B5CF6",
    }))
  );

  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none" style={{ zIndex: 2 }}>
      {particles.map((p) => (
        <div
          key={p.id}
          className="absolute rounded-full"
          style={{
            left: `${p.x}%`,
            top: `${p.y}%`,
            width: p.size,
            height: p.size,
            backgroundColor: p.color,
            opacity: p.opacity,
            filter: `blur(${p.size > 3 ? 1 : 0}px)`,
            animation: `dustFloat ${p.duration}s ease-in-out ${p.delay}s infinite`,
          }}
        />
      ))}
      <style>{`
        @keyframes dustFloat {
          0%, 100% { transform: translate(0, 0) scale(1); opacity: 0; }
          15% { opacity: 1; }
          50% { transform: translate(${30 - Math.random() * 60}px, -${40 + Math.random() * 30}px) scale(1.3); opacity: 0.6; }
          85% { opacity: 1; }
        }
      `}</style>
    </div>
  );
}

// ─── Pulsing Portal ───
function DungeonPortal() {
  return (
    <div className="relative flex items-center justify-center" style={{ width: 220, height: 220 }}>
      {/* Outer glow rings */}
      <div
        className="absolute rounded-full"
        style={{
          width: 220,
          height: 220,
          background: "radial-gradient(circle, rgba(139,92,246,0.15) 0%, transparent 70%)",
          animation: "portalPulse 3s ease-in-out infinite",
        }}
      />
      <div
        className="absolute rounded-full"
        style={{
          width: 200,
          height: 200,
          background: "radial-gradient(circle, rgba(212,165,55,0.12) 0%, transparent 60%)",
          animation: "portalPulse 3s ease-in-out 1.5s infinite",
        }}
      />

      {/* Main circle */}
      <div
        className="relative rounded-full flex items-center justify-center"
        style={{
          width: 180,
          height: 180,
          background: "radial-gradient(circle at 40% 35%, #2a2035 0%, #15111e 70%)",
          boxShadow: `
            0 0 40px rgba(212,165,55,0.25),
            0 0 80px rgba(139,92,246,0.15),
            inset 0 1px 0 rgba(255,255,255,0.06),
            inset 0 -2px 0 rgba(0,0,0,0.3),
            0 4px 12px rgba(0,0,0,0.5)
          `,
          border: "2px solid rgba(212,165,55,0.3)",
        }}
      >
        {/* Inner ornamental ring */}
        <div
          className="absolute rounded-full"
          style={{
            width: 168,
            height: 168,
            border: "1px solid rgba(212,165,55,0.12)",
          }}
        />

        {/* Portal icon placeholder */}
        <div className="text-center">
          <div style={{ fontSize: 64, filter: "drop-shadow(0 0 12px rgba(212,165,55,0.4))" }}>
            🏚️
          </div>
          <div
            className="absolute inset-0 rounded-full"
            style={{
              background: "radial-gradient(circle, rgba(212,165,55,0.08) 0%, transparent 50%)",
              animation: "innerGlow 4s ease-in-out infinite",
            }}
          />
        </div>
      </div>

      {/* Corner diamonds (ornamental) */}
      {[0, 90, 180, 270].map((deg) => (
        <div
          key={deg}
          className="absolute"
          style={{
            width: 6,
            height: 6,
            backgroundColor: "rgba(212,165,55,0.4)",
            transform: `rotate(${deg}deg) translateY(-104px) rotate(45deg)`,
          }}
        />
      ))}

      <style>{`
        @keyframes portalPulse {
          0%, 100% { transform: scale(1); opacity: 0.5; }
          50% { transform: scale(1.08); opacity: 1; }
        }
        @keyframes innerGlow {
          0%, 100% { opacity: 0.3; }
          50% { opacity: 0.8; }
        }
      `}</style>
    </div>
  );
}

// ─── Gold Ornamental Divider ───
function GoldDivider() {
  return (
    <div className="flex items-center justify-center w-full" style={{ padding: "0 32px" }}>
      <div className="flex-1" style={{ height: 1, background: "linear-gradient(to right, transparent, rgba(212,165,55,0.4))" }} />
      <div className="mx-3 flex items-center gap-1">
        <div style={{ width: 4, height: 4, backgroundColor: "rgba(212,165,55,0.5)", transform: "rotate(45deg)" }} />
        <div style={{ width: 6, height: 6, backgroundColor: "rgba(212,165,55,0.7)", transform: "rotate(45deg)" }} />
        <div style={{ width: 4, height: 4, backgroundColor: "rgba(212,165,55,0.5)", transform: "rotate(45deg)" }} />
      </div>
      <div className="flex-1" style={{ height: 1, background: "linear-gradient(to left, transparent, rgba(212,165,55,0.4))" }} />
    </div>
  );
}

// ─── Risk Callout (Enhanced) ───
function RiskCallout() {
  return (
    <div
      className="relative overflow-hidden"
      style={{
        padding: "14px 16px",
        borderRadius: 12,
        background: "linear-gradient(135deg, rgba(220,38,38,0.08) 0%, rgba(220,38,38,0.03) 100%)",
        border: "1px solid rgba(220,38,38,0.25)",
        boxShadow: "0 0 20px rgba(220,38,38,0.06), inset 0 1px 0 rgba(255,255,255,0.03)",
      }}
    >
      {/* Pulsing border glow */}
      <div
        className="absolute inset-0 rounded-xl pointer-events-none"
        style={{
          border: "1px solid rgba(220,38,38,0.15)",
          animation: "dangerPulse 2.5s ease-in-out infinite",
        }}
      />

      <div className="flex items-center gap-3">
        {/* Skull icon — larger */}
        <div
          style={{
            fontSize: 36,
            filter: "drop-shadow(0 0 6px rgba(220,38,38,0.3))",
            lineHeight: 1,
          }}
        >
          💀
        </div>

        <div className="flex-1">
          <div
            style={{
              fontFamily: "'Oswald', sans-serif",
              fontSize: 16,
              fontWeight: 600,
              color: "#EF4444",
              letterSpacing: 2,
              textShadow: "0 0 8px rgba(239,68,68,0.3)",
            }}
          >
            ONE LIFE ONLY
          </div>
          <div
            style={{
              fontFamily: "'Inter', sans-serif",
              fontSize: 13,
              color: "rgba(255,255,255,0.55)",
              marginTop: 3,
              lineHeight: 1.4,
            }}
          >
            Defeat = lose all gold & XP. Escape anytime to keep rewards.
          </div>
        </div>
      </div>

      <style>{`
        @keyframes dangerPulse {
          0%, 100% { opacity: 0; }
          50% { opacity: 1; }
        }
      `}</style>
    </div>
  );
}

// ─── Stats Panel (Ornamental) ───
function StatsPanel() {
  const stats = [
    { value: "12", label: "ROOMS", icon: "⚔️" },
    { value: "1", label: "SHOP", icon: "🏪" },
    { value: "2", label: "BOSSES", icon: "👹" },
    { value: "2", label: "EVENTS", icon: "✨" },
  ];

  return (
    <div
      className="relative"
      style={{
        borderRadius: 12,
        background: "radial-gradient(ellipse at center, rgba(30,25,40,0.9) 0%, rgba(18,14,26,0.95) 100%)",
        border: "1px solid rgba(212,165,55,0.15)",
        boxShadow: `
          inset 0 1px 0 rgba(255,255,255,0.04),
          inset 0 -1px 0 rgba(0,0,0,0.2),
          0 4px 16px rgba(0,0,0,0.4)
        `,
        overflow: "hidden",
      }}
    >
      {/* Surface lighting */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: "linear-gradient(to bottom, rgba(255,255,255,0.04) 0%, transparent 40%, rgba(0,0,0,0.08) 100%)",
          borderRadius: 12,
        }}
      />

      <div className="flex relative">
        {stats.map((stat, i) => (
          <div key={stat.label} className="flex items-center" style={{ flex: 1 }}>
            <div className="flex flex-col items-center w-full" style={{ padding: "14px 0" }}>
              <div style={{ fontSize: 14, marginBottom: 4 }}>{stat.icon}</div>
              <div
                style={{
                  fontFamily: "'Oswald', sans-serif",
                  fontSize: 28,
                  fontWeight: 600,
                  color: "#FFD700",
                  textShadow: "0 0 12px rgba(212,165,55,0.4)",
                  lineHeight: 1,
                }}
              >
                {stat.value}
              </div>
              <div
                style={{
                  fontFamily: "'Inter', sans-serif",
                  fontSize: 10,
                  fontWeight: 500,
                  color: "rgba(255,255,255,0.4)",
                  letterSpacing: 2,
                  marginTop: 4,
                }}
              >
                {stat.label}
              </div>
            </div>
            {i < stats.length - 1 && (
              <div
                style={{
                  width: 1,
                  alignSelf: "stretch",
                  background: "linear-gradient(to bottom, transparent, rgba(212,165,55,0.2), transparent)",
                  margin: "8px 0",
                }}
              />
            )}
          </div>
        ))}
      </div>

      {/* Corner brackets */}
      {["top-left", "top-right", "bottom-left", "bottom-right"].map((pos) => {
        const isTop = pos.includes("top");
        const isLeft = pos.includes("left");
        return (
          <div
            key={pos}
            className="absolute pointer-events-none"
            style={{
              [isTop ? "top" : "bottom"]: 4,
              [isLeft ? "left" : "right"]: 4,
              width: 12,
              height: 12,
              borderColor: "rgba(212,165,55,0.25)",
              borderStyle: "solid",
              borderWidth: 0,
              ...(isTop && isLeft && { borderTopWidth: 1.5, borderLeftWidth: 1.5 }),
              ...(isTop && !isLeft && { borderTopWidth: 1.5, borderRightWidth: 1.5 }),
              ...(!isTop && isLeft && { borderBottomWidth: 1.5, borderLeftWidth: 1.5 }),
              ...(!isTop && !isLeft && { borderBottomWidth: 1.5, borderRightWidth: 1.5 }),
            }}
          />
        );
      })}
    </div>
  );
}

// ─── Reward Preview Pill ───
function RewardPreview() {
  const rewards = [
    { icon: "🪙", text: "Gold", color: "#D4A537" },
    { icon: "⚡", text: "XP", color: "#8B5CF6" },
    { icon: "🗡️", text: "Loot", color: "#3B82F6" },
    { icon: "💎", text: "Rare+", color: "#F59E0B" },
  ];

  return (
    <div className="flex justify-center gap-2">
      {rewards.map((r) => (
        <div
          key={r.text}
          className="flex items-center gap-1"
          style={{
            padding: "5px 10px",
            borderRadius: 20,
            background: "rgba(255,255,255,0.04)",
            border: `1px solid ${r.color}22`,
          }}
        >
          <span style={{ fontSize: 13 }}>{r.icon}</span>
          <span
            style={{
              fontFamily: "'Inter', sans-serif",
              fontSize: 11,
              color: r.color,
              fontWeight: 500,
            }}
          >
            {r.text}
          </span>
        </div>
      ))}
    </div>
  );
}

// ─── CTA Button (Gold, Ornamental) ───
function StartButton({ onClick }) {
  const [pressed, setPressed] = useState(false);

  return (
    <button
      onClick={onClick}
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      className="relative w-full"
      style={{
        height: 56,
        borderRadius: 8,
        background: pressed
          ? "linear-gradient(to bottom, #B8860B, #8B6914)"
          : "linear-gradient(to bottom, #F5D060, #D4A537, #B8860B)",
        border: "1.5px solid rgba(255,215,0,0.5)",
        boxShadow: pressed
          ? "inset 0 2px 4px rgba(0,0,0,0.3)"
          : `0 0 20px rgba(212,165,55,0.3), 0 4px 12px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.2)`,
        cursor: "pointer",
        transition: "all 0.1s",
        filter: pressed ? "brightness(0.94)" : "none",
      }}
    >
      {/* Surface lighting overlay */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          borderRadius: 7,
          background: "linear-gradient(to bottom, rgba(255,255,255,0.15) 0%, transparent 45%, rgba(0,0,0,0.1) 100%)",
        }}
      />

      <span
        style={{
          fontFamily: "'Oswald', sans-serif",
          fontSize: 20,
          fontWeight: 600,
          color: "#1a1400",
          letterSpacing: 3,
          textShadow: "0 1px 0 rgba(255,255,255,0.2)",
          position: "relative",
          zIndex: 1,
        }}
      >
        ENTER THE DEPTHS
      </span>

      {/* Corner brackets */}
      {["top-left", "top-right", "bottom-left", "bottom-right"].map((pos) => {
        const isTop = pos.includes("top");
        const isLeft = pos.includes("left");
        return (
          <div
            key={pos}
            className="absolute pointer-events-none"
            style={{
              [isTop ? "top" : "bottom"]: -6,
              [isLeft ? "left" : "right"]: -6,
              width: 10,
              height: 10,
              borderColor: "rgba(212,165,55,0.5)",
              borderStyle: "solid",
              borderWidth: 0,
              ...(isTop && isLeft && { borderTopWidth: 2, borderLeftWidth: 2 }),
              ...(isTop && !isLeft && { borderTopWidth: 2, borderRightWidth: 2 }),
              ...(!isTop && isLeft && { borderBottomWidth: 2, borderLeftWidth: 2 }),
              ...(!isTop && !isLeft && { borderBottomWidth: 2, borderRightWidth: 2 }),
            }}
          />
        );
      })}

      {/* Corner diamonds */}
      {[
        { top: -4, left: -4 },
        { top: -4, right: -4 },
        { bottom: -4, left: -4 },
        { bottom: -4, right: -4 },
      ].map((style, i) => (
        <div
          key={i}
          className="absolute pointer-events-none"
          style={{
            ...style,
            width: 5,
            height: 5,
            backgroundColor: "rgba(212,165,55,0.6)",
            transform: "rotate(45deg)",
          }}
        />
      ))}
    </button>
  );
}

// ─── Stamina Cost Pill ───
function StaminaCost() {
  return (
    <div className="flex justify-center">
      <div
        className="flex items-center gap-1.5"
        style={{
          padding: "4px 12px",
          borderRadius: 20,
          background: "rgba(245,158,11,0.08)",
          border: "1px solid rgba(245,158,11,0.15)",
        }}
      >
        <span style={{ fontSize: 13 }}>⚡</span>
        <span
          style={{
            fontFamily: "'Inter', sans-serif",
            fontSize: 12,
            color: "#F59E0B",
            fontWeight: 500,
          }}
        >
          3 Stamina
        </span>
      </div>
    </div>
  );
}

// ─── Main Screen ───
export default function DungeonRushPrototype() {
  return (
    <div
      className="relative flex flex-col"
      style={{
        width: 393,
        height: 852,
        margin: "0 auto",
        background: "#0d0a14",
        overflow: "hidden",
        fontFamily: "'Inter', sans-serif",
        borderRadius: 40,
        border: "3px solid #333",
      }}
    >
      {/* ── Background Art ── */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage:
            "url('https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800')",
          backgroundSize: "cover",
          backgroundPosition: "center",
          opacity: 0.12,
          filter: "saturate(0.4) brightness(0.6)",
        }}
      />

      {/* Vignette overlay */}
      <div
        className="absolute inset-0"
        style={{
          background: `
            radial-gradient(ellipse at 50% 30%, transparent 20%, rgba(13,10,20,0.7) 70%),
            linear-gradient(to bottom, rgba(13,10,20,0.3) 0%, transparent 20%, transparent 50%, rgba(13,10,20,0.85) 80%, rgba(13,10,20,1) 95%)
          `,
          zIndex: 1,
        }}
      />

      {/* Dust Particles */}
      <DustParticles />

      {/* ── Toolbar ── */}
      <div
        className="relative flex items-center px-5 pt-14 pb-3"
        style={{ zIndex: 10 }}
      >
        <div
          className="flex items-center justify-center"
          style={{
            width: 40,
            height: 40,
            borderRadius: 10,
            background: "rgba(255,255,255,0.06)",
            border: "1px solid rgba(255,255,255,0.08)",
          }}
        >
          <span style={{ color: "rgba(255,255,255,0.7)", fontSize: 18 }}>←</span>
        </div>
        <div className="flex-1 text-center">
          <span
            style={{
              fontFamily: "'Oswald', sans-serif",
              fontSize: 18,
              fontWeight: 600,
              color: "#FFD700",
              letterSpacing: 3,
            }}
          >
            DUNGEON RUSH
          </span>
        </div>
        <div style={{ width: 40 }} />
      </div>

      {/* ── Main Content ── */}
      <div
        className="relative flex-1 flex flex-col items-center justify-between"
        style={{ zIndex: 5, padding: "0 20px" }}
      >
        {/* Hero Zone — Portal + Title — ~50% of screen */}
        <div className="flex flex-col items-center" style={{ paddingTop: 16 }}>
          <DungeonPortal />

          <div className="text-center" style={{ marginTop: 16 }}>
            <div
              style={{
                fontFamily: "'Inter', sans-serif",
                fontSize: 14,
                color: "rgba(255,255,255,0.45)",
                letterSpacing: 1,
                marginBottom: 12,
              }}
            >
              12 rooms of combat, treasure & mystery
            </div>

            <RewardPreview />
          </div>
        </div>

        {/* Middle — Divider + Info blocks */}
        <div className="w-full flex flex-col gap-4" style={{ marginTop: 4 }}>
          <GoldDivider />
          <RiskCallout />
          <StatsPanel />
        </div>

        {/* Bottom — CTA */}
        <div className="w-full" style={{ paddingBottom: 44, paddingTop: 16 }}>
          <StartButton onClick={() => alert("Rush started!")} />
          <div style={{ marginTop: 10 }}>
            <StaminaCost />
          </div>
        </div>
      </div>

      {/* Google Fonts */}
      <link
        href="https://fonts.googleapis.com/css2?family=Oswald:wght@400;500;600;700&family=Inter:wght@400;500;600&display=swap"
        rel="stylesheet"
      />
    </div>
  );
}