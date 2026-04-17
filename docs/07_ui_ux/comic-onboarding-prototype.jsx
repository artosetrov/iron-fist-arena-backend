import { useState, useEffect, useCallback, useRef } from "react";

// Historical prototype snapshot retained for onboarding concept context; not live tutorial source of truth.

// — Color tokens (matching DarkFantasyTheme) —
const T = {
  bgAbyss: "#0D0D1A",
  bgPrimary: "#1A1A2E",
  bgSecondary: "#252540",
  gold: "#D4A537",
  goldBright: "#F0C850",
  danger: "#E63946",
  classMage: "#7B68EE",
  textPrimary: "#F5F5F5",
  textSecondary: "#A0A0B0",
  textTertiary: "#6B6B80",
  borderMedium: "#3A3A50",
  borderSubtle: "#2A2A40",
};

// — Comic data —
const PAGES = [
  {
    title: "WELCOME TO HEXBOUND",
    accentColor: T.gold,
    panels: [
      {
        id: "1.1",
        layout: "wide",
        caption: "HEXBOUND. A city older than regret.",
        captionStyle: "narrator",
        aspectRatio: "350 / 180",
        bgGradient: `linear-gradient(135deg, #1a1020 0%, #0d0d1a 40%, #2a1a10 100%)`,
        scene: "🏰 Bird's eye view — ancient city, arena dome, dungeon glow, forge smoke",
      },
      {
        id: "1.2",
        layout: "left",
        caption: "They sell swords, curses, and secondhand potions. No refunds.",
        captionStyle: "narrator",
        aspectRatio: "170 / 210",
        bgGradient: `linear-gradient(180deg, #1a1520 0%, #0d0d1a 100%)`,
        scene: "🧪 Market street — shady merchant, wounded warrior, wanted posters",
      },
      {
        id: "1.3",
        layout: "right",
        caption: '"You look like easy money. Welcome."',
        captionStyle: "speech",
        aspectRatio: "170 / 210",
        bgGradient: `linear-gradient(180deg, #1a1020 0%, #0d0d1a 100%)`,
        scene: "💀 Skeleton NPC grinning at viewer — breaking 4th wall",
      },
    ],
  },
  {
    title: "BLOOD & GLORY",
    accentColor: T.danger,
    panels: [
      {
        id: "2.1",
        layout: "wide",
        caption: "Bakers fight. Priests fight. Even the rats have a ranking.",
        captionStyle: "narrator",
        aspectRatio: "350 / 160",
        bgGradient: `linear-gradient(135deg, #2a1015 0%, #0d0d1a 50%, #1a0a0a 100%)`,
        scene: "⚔️ Arena clash — two warriors, sparks, roaring crowd",
      },
      {
        id: "2.2",
        layout: "left",
        caption: "Win, and they sing songs about you.",
        captionStyle: "narrator",
        aspectRatio: "170 / 180",
        bgGradient: `linear-gradient(180deg, #1a1a10 0%, #0d0d1a 100%)`,
        scene: "🏆 Victor standing on pile of opponents, coins raining",
      },
      {
        id: "2.3",
        layout: "right",
        caption: "Lose, and they sing funnier ones.",
        captionStyle: "narrator",
        aspectRatio: "170 / 180",
        bgGradient: `linear-gradient(180deg, #151520 0%, #0d0d1a 100%)`,
        scene: "😵 Same warrior face-down, new champ standing over them",
      },
      {
        id: "2.4",
        layout: "wide",
        caption: "Below the city, things get worse. Much worse.",
        captionStyle: "narrator",
        aspectRatio: "350 / 180",
        bgGradient: `linear-gradient(135deg, #0a1a10 0%, #0d0d1a 50%, #0a0d1a 100%)`,
        scene: "🕳️ Dungeon mouth — glowing eyes in darkness, scattered bones",
      },
    ],
  },
  {
    title: "YOUR TURN",
    accentColor: T.gold,
    panels: [
      {
        id: "3.1",
        layout: "wide-tall",
        caption: "Every legend started broke, confused, and slightly terrified.",
        captionStyle: "narrator",
        aspectRatio: "350 / 260",
        bgGradient: `linear-gradient(180deg, #1a1510 0%, #0d0d1a 60%, #1a0a05 100%)`,
        scene: "🔥 Hero silhouette gearing up in forge — armor, sword, firelight",
      },
      {
        id: "3.2",
        layout: "wide-hero",
        caption: "The difference? They fought anyway.",
        captionStyle: "narrator",
        aspectRatio: "350 / 220",
        bgGradient: `linear-gradient(0deg, #0d0d1a 0%, #2a1a10 40%, #1a0a00 100%)`,
        scene: "🚪 Hero walking through arena gates, backlit, cape flowing",
        finalText: "YOUR TURN.",
      },
    ],
  },
];

// — Panel component —
function ComicPanel({ panel, visible, accentColor, onTap, index }) {
  const isWide = panel.layout.startsWith("wide");
  const isSpeech = panel.captionStyle === "speech";

  return (
    <div
      onClick={onTap}
      style={{
        width: isWide ? "100%" : "calc(50% - 4px)",
        aspectRatio: panel.aspectRatio,
        position: "relative",
        overflow: "hidden",
        borderRadius: 8,
        border: `2px solid ${visible ? (accentColor + "60") : T.borderSubtle}`,
        background: visible ? panel.bgGradient : T.bgPrimary,
        opacity: visible ? 1 : 0,
        transform: visible ? "translateY(0)" : "translateY(20px)",
        transition: "all 0.5s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
        cursor: "pointer",
        flexShrink: 0,
      }}
    >
      {/* Scene placeholder */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: isWide ? 48 : 36,
          opacity: visible ? 0.3 : 0,
          transition: "opacity 0.6s ease",
        }}
      >
        {panel.scene.split(" ")[0]}
      </div>

      {/* Vignette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `linear-gradient(180deg, transparent 40%, ${T.bgAbyss}ee 100%)`,
          pointerEvents: "none",
        }}
      />

      {/* Scene description (placeholder for actual art) */}
      <div
        style={{
          position: "absolute",
          top: 8,
          left: 8,
          right: 8,
          fontFamily: "Inter, sans-serif",
          fontSize: 10,
          color: T.textTertiary,
          opacity: visible ? 0.6 : 0,
          transition: "opacity 0.4s ease 0.3s",
        }}
      >
        {panel.scene}
      </div>

      {/* Caption */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          padding: isSpeech ? "8px 12px" : "10px 12px",
          opacity: visible ? 1 : 0,
          transform: visible ? "translateY(0)" : "translateY(10px)",
          transition: "all 0.4s ease 0.3s",
        }}
      >
        {isSpeech ? (
          <div
            style={{
              background: "#F5F5F5",
              color: T.bgAbyss,
              padding: "8px 12px",
              borderRadius: "12px 12px 4px 12px",
              fontFamily: "'Comic Sans MS', cursive, Inter, sans-serif",
              fontSize: 12,
              fontWeight: 600,
              fontStyle: "italic",
              boxShadow: `0 2px 8px ${T.bgAbyss}80`,
            }}
          >
            {panel.caption}
          </div>
        ) : (
          <div
            style={{
              background: `${T.bgAbyss}cc`,
              padding: "6px 10px",
              borderLeft: `3px solid ${accentColor}`,
              fontFamily: "Inter, sans-serif",
              fontSize: isWide ? 13 : 11,
              color: T.textPrimary,
              lineHeight: 1.4,
              fontStyle: "italic",
            }}
          >
            {panel.caption}
          </div>
        )}
      </div>

      {/* Panel number */}
      <div
        style={{
          position: "absolute",
          top: 4,
          right: 8,
          fontFamily: "monospace",
          fontSize: 9,
          color: accentColor,
          opacity: visible ? 0.5 : 0,
          transition: "opacity 0.3s ease",
        }}
      >
        {panel.id}
      </div>
    </div>
  );
}

// — Main component —
export default function ComicOnboardingPrototype() {
  const [currentPage, setCurrentPage] = useState(0);
  const [revealedCount, setRevealedCount] = useState(0);
  const [showFinalText, setShowFinalText] = useState(false);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const timerRef = useRef(null);
  const page = PAGES[currentPage];
  const totalPanels = page.panels.length;
  const allRevealed = revealedCount >= totalPanels;
  const isLastPage = currentPage === PAGES.length - 1;

  // Auto-reveal timer
  useEffect(() => {
    if (revealedCount < totalPanels) {
      timerRef.current = setTimeout(() => {
        setRevealedCount((c) => c + 1);
      }, revealedCount === 0 ? 400 : 700);
    } else if (isLastPage && !showFinalText) {
      timerRef.current = setTimeout(() => setShowFinalText(true), 1000);
    }
    return () => clearTimeout(timerRef.current);
  }, [revealedCount, totalPanels, isLastPage, showFinalText]);

  // Tap to reveal next panel faster
  const handleTap = useCallback(() => {
    if (revealedCount < totalPanels) {
      clearTimeout(timerRef.current);
      setRevealedCount((c) => c + 1);
    }
  }, [revealedCount, totalPanels]);

  // Navigate pages
  const goToPage = useCallback(
    (dir) => {
      const next = currentPage + dir;
      if (next < 0 || next >= PAGES.length || isTransitioning) return;
      setIsTransitioning(true);
      setTimeout(() => {
        setCurrentPage(next);
        setRevealedCount(0);
        setShowFinalText(false);
        setIsTransitioning(false);
      }, 300);
    },
    [currentPage, isTransitioning]
  );

  // Swipe
  const touchStart = useRef(0);

  // Build panel grid
  const renderPanels = () => {
    const rows = [];
    let i = 0;
    while (i < page.panels.length) {
      const p = page.panels[i];
      if (p.layout.startsWith("wide")) {
        rows.push(
          <div key={p.id} style={{ display: "flex", width: "100%" }}>
            <ComicPanel
              panel={p}
              visible={i < revealedCount}
              accentColor={page.accentColor}
              onTap={handleTap}
              index={i}
            />
          </div>
        );
        i++;
      } else {
        // left + right pair
        const left = page.panels[i];
        const right = page.panels[i + 1];
        rows.push(
          <div
            key={left.id + "-row"}
            style={{ display: "flex", gap: 8, width: "100%" }}
          >
            <ComicPanel
              panel={left}
              visible={i < revealedCount}
              accentColor={page.accentColor}
              onTap={handleTap}
              index={i}
            />
            {right && (
              <ComicPanel
                panel={right}
                visible={i + 1 < revealedCount}
                accentColor={page.accentColor}
                onTap={handleTap}
                index={i + 1}
              />
            )}
          </div>
        );
        i += 2;
      }
    }
    return rows;
  };

  return (
    <div
      style={{
        width: 390,
        height: 844,
        margin: "0 auto",
        background: T.bgAbyss,
        borderRadius: 40,
        overflow: "hidden",
        position: "relative",
        fontFamily: "Inter, system-ui, sans-serif",
        border: `3px solid ${T.borderSubtle}`,
        boxShadow: `0 0 60px ${T.bgAbyss}, 0 0 120px ${T.bgAbyss}`,
        userSelect: "none",
      }}
      onTouchStart={(e) => (touchStart.current = e.touches[0].clientX)}
      onTouchEnd={(e) => {
        const dx = e.changedTouches[0].clientX - touchStart.current;
        if (allRevealed && dx < -60) goToPage(1);
        if (dx > 60) goToPage(-1);
      }}
    >
      {/* Status bar mock */}
      <div
        style={{
          height: 54,
          display: "flex",
          alignItems: "flex-end",
          justifyContent: "center",
          paddingBottom: 4,
          fontSize: 14,
          fontWeight: 600,
          color: T.textPrimary,
        }}
      >
        5:44
      </div>

      {/* Skip button */}
      <div
        style={{
          position: "absolute",
          top: 54,
          right: 20,
          zIndex: 10,
        }}
      >
        <button
          style={{
            background: T.bgSecondary + "99",
            border: `1px solid ${T.borderSubtle}`,
            borderRadius: 20,
            padding: "4px 12px",
            color: T.textTertiary,
            fontSize: 11,
            fontWeight: 600,
            letterSpacing: 0.8,
            cursor: "pointer",
            fontFamily: "Inter, sans-serif",
          }}
        >
          SKIP
        </button>
      </div>

      {/* Main content area */}
      <div
        style={{
          padding: "8px 20px 0",
          display: "flex",
          flexDirection: "column",
          height: "calc(100% - 54px - 120px)",
          opacity: isTransitioning ? 0 : 1,
          transform: isTransitioning ? "translateX(-40px)" : "translateX(0)",
          transition: "all 0.3s ease",
        }}
      >
        {/* Page title */}
        <div
          style={{
            textAlign: "center",
            marginBottom: 12,
            opacity: revealedCount > 0 ? 1 : 0,
            transition: "opacity 0.5s ease",
          }}
        >
          <div
            style={{
              fontFamily: "'Inter', system-ui, sans-serif",
              fontSize: 10,
              letterSpacing: 1.4,
              textTransform: "uppercase",
              color: T.textTertiary,
              marginBottom: 6,
            }}
          >
            Historical prototype snapshot
          </div>
          <h1
            style={{
              fontFamily: "'Oswald', Impact, sans-serif",
              fontSize: 16,
              fontWeight: 700,
              color: page.accentColor,
              letterSpacing: 3,
              margin: 0,
              textShadow: `0 0 20px ${page.accentColor}40`,
            }}
          >
            {page.title}
          </h1>
          <div
            style={{
              width: 40,
              height: 1,
              background: `linear-gradient(90deg, transparent, ${page.accentColor}60, transparent)`,
              margin: "6px auto 0",
            }}
          />
        </div>

        {/* Panels grid */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 8,
            flex: 1,
            justifyContent: "center",
          }}
        >
          {renderPanels()}
        </div>

        {/* Final text for last page */}
        {isLastPage && (
          <div
            style={{
              textAlign: "center",
              padding: "16px 0 8px",
              opacity: showFinalText ? 1 : 0,
              transform: showFinalText ? "translateY(0)" : "translateY(10px)",
              transition: "all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            }}
          >
            <span
              style={{
                fontFamily: "'Oswald', Impact, sans-serif",
                fontSize: 28,
                fontWeight: 700,
                color: T.gold,
                letterSpacing: 4,
                textShadow: `0 0 30px ${T.gold}60, 0 0 60px ${T.gold}30`,
              }}
            >
              YOUR TURN.
            </span>
          </div>
        )}
      </div>

      {/* Bottom section */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          padding: "0 20px 34px",
          background: `linear-gradient(180deg, transparent, ${T.bgAbyss} 30%)`,
        }}
      >
        {/* Progress bar */}
        <div
          style={{
            height: 3,
            borderRadius: 2,
            background: T.borderSubtle + "60",
            marginBottom: 16,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              height: "100%",
              width: `${((currentPage + 1) / PAGES.length) * 100}%`,
              borderRadius: 2,
              background: `linear-gradient(90deg, ${page.accentColor}aa, ${page.accentColor})`,
              boxShadow: `0 0 8px ${page.accentColor}80`,
              transition: "width 0.4s ease",
            }}
          />
        </div>

        {/* Navigation */}
        {isLastPage && allRevealed && showFinalText ? (
          <button
            style={{
              width: "100%",
              height: 52,
              borderRadius: 10,
              border: "none",
              background: `linear-gradient(135deg, ${T.gold}, ${T.goldBright})`,
              color: T.bgAbyss,
              fontFamily: "'Oswald', Impact, sans-serif",
              fontSize: 18,
              fontWeight: 700,
              letterSpacing: 2,
              cursor: "pointer",
              boxShadow: `0 0 20px ${T.gold}40, inset 0 1px 0 ${T.goldBright}40`,
              transition: "all 0.3s ease",
            }}
          >
            ENTER HEXBOUND
          </button>
        ) : (
          <div style={{ display: "flex", gap: 12 }}>
            {/* Tap hint */}
            <div
              style={{
                flex: 1,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 6,
              }}
            >
              {!allRevealed && (
                <span
                  style={{
                    fontSize: 12,
                    color: T.textTertiary,
                    opacity: 0.7,
                    animation: "pulse 2s ease-in-out infinite",
                  }}
                >
                  tap to reveal
                </span>
              )}
            </div>

            {/* Continue button */}
            {allRevealed && !isLastPage && (
              <button
                onClick={() => goToPage(1)}
                style={{
                  flex: 1,
                  height: 48,
                  borderRadius: 10,
                  border: `1px solid ${T.borderMedium}`,
                  background: T.bgSecondary,
                  color: T.textPrimary,
                  fontFamily: "'Oswald', Impact, sans-serif",
                  fontSize: 16,
                  fontWeight: 600,
                  letterSpacing: 1.5,
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: 6,
                  transition: "all 0.3s ease",
                }}
              >
                CONTINUE
                <span style={{ fontSize: 12 }}>›</span>
              </button>
            )}
          </div>
        )}

        {/* Page dots */}
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            gap: 6,
            marginTop: 12,
          }}
        >
          {PAGES.map((_, i) => (
            <div
              key={i}
              style={{
                width: i === currentPage ? 16 : 6,
                height: 6,
                borderRadius: 3,
                background:
                  i === currentPage ? page.accentColor : T.borderSubtle,
                transition: "all 0.3s ease",
              }}
            />
          ))}
        </div>
      </div>

      {/* CSS animations */}
      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 0.4; }
          50% { opacity: 0.8; }
        }
        @import url('https://fonts.googleapis.com/css2?family=Oswald:wght@400;600;700&family=Inter:wght@400;500;600&display=swap');
      `}</style>
    </div>
  );
}
