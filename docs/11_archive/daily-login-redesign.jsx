import { useState, useEffect, useRef } from "react";

// ─── REWARD DATA ────────────────────────────────────────────────
const REWARDS = [
  { day: 1, type: "gold", amount: 500, icon: "🪙", label: "500 Gold" },
  { day: 2, type: "gem", amount: 1, icon: "💎", label: "1 Gem" },
  { day: 3, type: "gold", amount: 1000, icon: "🪙", label: "1K Gold" },
  { day: 4, type: "card", amount: 1, icon: "🃏", label: "Card Pack" },
  { day: 5, type: "gem", amount: 3, icon: "💎", label: "3 Gems" },
  { day: 6, type: "gold", amount: 2500, icon: "🪙", label: "2.5K Gold" },
  { day: 7, type: "chest", amount: 1, icon: "🏆", label: "Epic Chest" },
];

// ─── PARTICLE SYSTEM ────────────────────────────────────────────
function Particles({ active, color }) {
  const canvasRef = useRef(null);
  const particlesRef = useRef([]);
  const animRef = useRef(null);

  useEffect(() => {
    if (!active || !canvasRef.current) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    canvas.width = 400;
    canvas.height = 600;

    particlesRef.current = Array.from({ length: 40 }, () => ({
      x: 200 + (Math.random() - 0.5) * 60,
      y: 300,
      vx: (Math.random() - 0.5) * 6,
      vy: -Math.random() * 8 - 2,
      size: Math.random() * 4 + 2,
      alpha: 1,
      color: color || `hsl(${40 + Math.random() * 20}, 100%, ${60 + Math.random() * 20}%)`,
    }));

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particlesRef.current.forEach((p) => {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15;
        p.alpha -= 0.015;
        if (p.alpha > 0) {
          ctx.globalAlpha = p.alpha;
          ctx.fillStyle = p.color;
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
          ctx.fill();
        }
      });
      if (particlesRef.current.some((p) => p.alpha > 0)) {
        animRef.current = requestAnimationFrame(animate);
      }
    };
    animate();
    return () => cancelAnimationFrame(animRef.current);
  }, [active, color]);

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: "absolute",
        top: "50%",
        left: "50%",
        transform: "translate(-50%, -50%)",
        pointerEvents: "none",
        zIndex: 100,
      }}
    />
  );
}

// ─── GLOW RING (SVG animated) ───────────────────────────────────
function GlowRing() {
  return (
    <svg
      viewBox="0 0 100 100"
      style={{
        position: "absolute",
        inset: -6,
        width: "calc(100% + 12px)",
        height: "calc(100% + 12px)",
        animation: "spin 4s linear infinite",
      }}
    >
      <defs>
        <linearGradient id="glowGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FFD700" stopOpacity="1" />
          <stop offset="50%" stopColor="#FFA500" stopOpacity="0.3" />
          <stop offset="100%" stopColor="#FFD700" stopOpacity="1" />
        </linearGradient>
      </defs>
      <circle
        cx="50"
        cy="50"
        r="46"
        fill="none"
        stroke="url(#glowGrad)"
        strokeWidth="3"
        strokeDasharray="40 250"
        strokeLinecap="round"
      />
    </svg>
  );
}

// ─── SINGLE DAY CELL ────────────────────────────────────────────
function DayCell({ reward, status, isCurrent, onClick, justClaimed }) {
  const isClaimed = status === "claimed";
  const isLocked = status === "locked";
  const isBonus = reward.day === 7;

  const bgColor = isClaimed
    ? "linear-gradient(135deg, #2a2a1a 0%, #1a1a0a 100%)"
    : isCurrent
    ? "linear-gradient(135deg, #3d2e0a 0%, #2a1f05 100%)"
    : "linear-gradient(135deg, #1a1a2e 0%, #0f0f1a 100%)";

  const borderColor = isClaimed
    ? "#5a5a2a"
    : isCurrent
    ? "#FFD700"
    : "#2a2a3e";

  return (
    <div
      onClick={isCurrent ? onClick : undefined}
      style={{
        position: "relative",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        width: isBonus ? "100%" : "calc(33.33% - 8px)",
        height: isBonus ? 90 : 100,
        background: bgColor,
        border: `2px solid ${borderColor}`,
        borderRadius: 16,
        cursor: isCurrent ? "pointer" : "default",
        opacity: isLocked ? 0.4 : 1,
        transition: "all 0.3s ease",
        overflow: "visible",
        boxShadow: isCurrent
          ? "0 0 20px rgba(255, 215, 0, 0.3), inset 0 0 20px rgba(255, 215, 0, 0.05)"
          : "0 2px 8px rgba(0,0,0,0.3)",
        transform: justClaimed ? "scale(1.05)" : "scale(1)",
      }}
    >
      {isCurrent && <GlowRing />}

      {isClaimed && (
        <div
          style={{
            position: "absolute",
            top: 6,
            right: 8,
            fontSize: 14,
            color: "#4CAF50",
          }}
        >
          ✓
        </div>
      )}

      <div
        style={{
          fontSize: isBonus ? 32 : 28,
          lineHeight: 1,
          filter: isLocked ? "grayscale(1)" : "none",
          transition: "transform 0.3s",
          transform: justClaimed ? "scale(1.3)" : "scale(1)",
        }}
      >
        {reward.icon}
      </div>

      <div
        style={{
          marginTop: 4,
          fontSize: 12,
          fontWeight: 700,
          color: isClaimed ? "#8a8a5a" : isCurrent ? "#FFD700" : "#8888aa",
          letterSpacing: "0.05em",
          textTransform: "uppercase",
        }}
      >
        {reward.label}
      </div>

      <div
        style={{
          fontSize: 10,
          color: isCurrent ? "#cca800" : "#555577",
          marginTop: 2,
          fontWeight: 600,
        }}
      >
        Day {reward.day}
      </div>
    </div>
  );
}

// ─── STREAK PROGRESS BAR ────────────────────────────────────────
function StreakBar({ currentDay, totalDays }) {
  const pct = ((currentDay - 1) / (totalDays - 1)) * 100;
  return (
    <div style={{ width: "100%", marginBottom: 8 }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "baseline",
          marginBottom: 8,
        }}
      >
        <span style={{ fontSize: 13, color: "#8888aa", fontWeight: 600 }}>
          Weekly Progress
        </span>
        <span style={{ fontSize: 13, color: "#FFD700", fontWeight: 700 }}>
          {currentDay}/7
        </span>
      </div>
      <div
        style={{
          width: "100%",
          height: 6,
          background: "#1a1a2e",
          borderRadius: 3,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${pct}%`,
            height: "100%",
            background: "linear-gradient(90deg, #FFD700, #FFA500)",
            borderRadius: 3,
            transition: "width 0.6s ease",
            boxShadow: "0 0 8px rgba(255, 215, 0, 0.5)",
          }}
        />
      </div>
    </div>
  );
}

// ─── MAIN COMPONENT ─────────────────────────────────────────────
export default function DailyLoginRedesign() {
  const [currentDay, setCurrentDay] = useState(3);
  const [claimedDays, setClaimedDays] = useState([1, 2]);
  const [showParticles, setShowParticles] = useState(false);
  const [justClaimedDay, setJustClaimedDay] = useState(null);
  const [streakCount, setStreakCount] = useState(9);
  const [buttonState, setButtonState] = useState("idle"); // idle | claiming | claimed

  const handleClaim = () => {
    if (buttonState !== "idle") return;
    setButtonState("claiming");
    setShowParticles(true);
    setJustClaimedDay(currentDay);

    setTimeout(() => {
      setClaimedDays((prev) => [...prev, currentDay]);
      setButtonState("claimed");

      setTimeout(() => {
        setShowParticles(false);
      }, 1500);
    }, 400);
  };

  const getStatus = (day) => {
    if (claimedDays.includes(day)) return "claimed";
    if (day === currentDay) return "current";
    return "locked";
  };

  const todayReward = REWARDS.find((r) => r.day === currentDay);

  return (
    <div
      style={{
        width: 393,
        minHeight: 852,
        background: "linear-gradient(180deg, #0a0a14 0%, #0f0f1a 40%, #0a0a14 100%)",
        fontFamily: "'Segoe UI', system-ui, sans-serif",
        color: "#fff",
        display: "flex",
        flexDirection: "column",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: "absolute",
          top: 80,
          left: "50%",
          transform: "translateX(-50%)",
          width: 300,
          height: 300,
          background: "radial-gradient(circle, rgba(255,215,0,0.06) 0%, transparent 70%)",
          pointerEvents: "none",
        }}
      />

      {/* Header */}
      <div style={{ padding: "56px 20px 0", textAlign: "center" }}>
        <div
          style={{
            fontSize: 11,
            fontWeight: 700,
            letterSpacing: "0.2em",
            color: "#8888aa",
            textTransform: "uppercase",
            marginBottom: 4,
          }}
        >
          Daily Login
        </div>
        <div
          style={{
            fontSize: 28,
            fontWeight: 800,
            background: "linear-gradient(135deg, #FFD700, #FFA500)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            letterSpacing: "-0.02em",
          }}
        >
          Day {streakCount} Streak
        </div>
        <div
          style={{
            fontSize: 12,
            color: "#6666aa",
            marginTop: 4,
          }}
        >
          Don't break your streak to earn bonus rewards!
        </div>
      </div>

      {/* Streak bar */}
      <div style={{ padding: "20px 24px 0" }}>
        <StreakBar currentDay={currentDay} totalDays={7} />
      </div>

      {/* Day grid */}
      <div style={{ padding: "16px 24px", position: "relative" }}>
        {showParticles && <Particles active={showParticles} />}

        {/* Top 3 days */}
        <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
          {REWARDS.slice(0, 3).map((reward) => (
            <DayCell
              key={reward.day}
              reward={reward}
              status={getStatus(reward.day)}
              isCurrent={reward.day === currentDay}
              onClick={handleClaim}
              justClaimed={justClaimedDay === reward.day}
            />
          ))}
        </div>

        {/* Middle 3 days */}
        <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
          {REWARDS.slice(3, 6).map((reward) => (
            <DayCell
              key={reward.day}
              reward={reward}
              status={getStatus(reward.day)}
              isCurrent={reward.day === currentDay}
              onClick={handleClaim}
              justClaimed={justClaimedDay === reward.day}
            />
          ))}
        </div>

        {/* Day 7 bonus row */}
        <div style={{ display: "flex" }}>
          <DayCell
            reward={REWARDS[6]}
            status={getStatus(7)}
            isCurrent={currentDay === 7}
            onClick={handleClaim}
            justClaimed={justClaimedDay === 7}
          />
        </div>
      </div>

      {/* Today's reward highlight */}
      <div style={{ padding: "0 24px" }}>
        <div
          style={{
            background: "linear-gradient(135deg, #1a1522 0%, #15102a 100%)",
            border: "1px solid #2a2a4e",
            borderRadius: 16,
            padding: "20px",
            display: "flex",
            alignItems: "center",
            gap: 16,
          }}
        >
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: 14,
              background:
                buttonState === "claimed"
                  ? "linear-gradient(135deg, #1a3a1a, #0a2a0a)"
                  : "linear-gradient(135deg, #3d2e0a, #2a1f05)",
              border:
                buttonState === "claimed"
                  ? "2px solid #4CAF50"
                  : "2px solid #FFD700",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 28,
              flexShrink: 0,
              boxShadow:
                buttonState === "claimed"
                  ? "0 0 12px rgba(76,175,80,0.3)"
                  : "0 0 12px rgba(255,215,0,0.2)",
            }}
          >
            {buttonState === "claimed" ? "✓" : todayReward?.icon}
          </div>
          <div style={{ flex: 1 }}>
            <div
              style={{
                fontSize: 10,
                fontWeight: 700,
                letterSpacing: "0.15em",
                color: "#8888aa",
                textTransform: "uppercase",
                marginBottom: 2,
              }}
            >
              Today's Reward
            </div>
            <div
              style={{
                fontSize: 18,
                fontWeight: 800,
                color:
                  buttonState === "claimed" ? "#4CAF50" : "#FFD700",
              }}
            >
              {buttonState === "claimed" ? "Claimed!" : todayReward?.label}
            </div>
          </div>
          <div
            style={{
              fontSize: 11,
              color: "#6666aa",
              fontWeight: 600,
            }}
          >
            Day {currentDay}
          </div>
        </div>
      </div>

      {/* Claim button */}
      <div style={{ padding: "20px 24px" }}>
        <button
          onClick={handleClaim}
          disabled={buttonState !== "idle"}
          style={{
            width: "100%",
            height: 56,
            border: "none",
            borderRadius: 16,
            fontSize: 16,
            fontWeight: 800,
            letterSpacing: "0.08em",
            textTransform: "uppercase",
            cursor: buttonState === "idle" ? "pointer" : "default",
            transition: "all 0.3s ease",
            position: "relative",
            overflow: "hidden",
            ...(buttonState === "claimed"
              ? {
                  background: "linear-gradient(135deg, #1a3a1a, #2a4a2a)",
                  color: "#4CAF50",
                  boxShadow: "0 0 20px rgba(76, 175, 80, 0.2)",
                }
              : buttonState === "claiming"
              ? {
                  background: "linear-gradient(135deg, #cc9900, #aa7700)",
                  color: "#fff",
                  boxShadow: "0 4px 20px rgba(255, 215, 0, 0.4)",
                }
              : {
                  background: "linear-gradient(135deg, #FFD700, #E5A800)",
                  color: "#1a1a0a",
                  boxShadow:
                    "0 4px 20px rgba(255, 215, 0, 0.3), inset 0 1px 0 rgba(255,255,255,0.3)",
                }),
          }}
        >
          {buttonState === "claimed"
            ? "✓ Reward Claimed"
            : buttonState === "claiming"
            ? "Claiming..."
            : "Claim Reward"}
        </button>
      </div>

      {/* Upcoming hint */}
      {buttonState !== "claimed" && currentDay < 7 && (
        <div
          style={{
            textAlign: "center",
            fontSize: 12,
            color: "#4a4a6e",
            padding: "0 24px 20px",
          }}
        >
          Tomorrow:{" "}
          <span style={{ color: "#8888aa" }}>
            {REWARDS[currentDay]?.icon} {REWARDS[currentDay]?.label}
          </span>
        </div>
      )}

      {buttonState === "claimed" && currentDay < 7 && (
        <div
          style={{
            textAlign: "center",
            padding: "0 24px 20px",
          }}
        >
          <div style={{ fontSize: 12, color: "#4a4a6e", marginBottom: 4 }}>
            Come back tomorrow for
          </div>
          <div
            style={{
              fontSize: 16,
              fontWeight: 700,
              color: "#8888cc",
            }}
          >
            {REWARDS[currentDay]?.icon} {REWARDS[currentDay]?.label}
          </div>
        </div>
      )}

      {/* Global keyframes */}
      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
