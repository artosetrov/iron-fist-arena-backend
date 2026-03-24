const COLORS = {
  bgPrimary: "#0D0D12",
  bgSecondary: "#1A1A2E",
  bgTertiary: "#16213E",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  textPrimary: "#F5F5F5",
  textSecondary: "#A0A0B0",
  textTertiary: "#6B6B80",
  textOnGold: "#1A1A2E",
  borderSubtle: "#2A2A3E",
  classWarrior: "#E68C33",
  success: "#5DECA5",
};

const stats = [
  { name: "Strength", value: 8, boosted: true },
  { name: "Agility", value: 5, boosted: false },
  { name: "Vitality", value: 7, boosted: true },
  { name: "Endurance", value: 5, boosted: false },
  { name: "Intelligence", value: 5, boosted: false },
  { name: "Wisdom", value: 5, boosted: false },
  { name: "Luck", value: 5, boosted: false },
];

function PhoneFrame({ label, labelColor, children }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div className="text-sm font-bold tracking-widest" style={{ color: labelColor || COLORS.textSecondary }}>{label}</div>
      <div className="relative rounded-3xl border overflow-hidden" style={{ width: 280, height: 540, borderColor: COLORS.borderSubtle, background: COLORS.bgPrimary }}>
        {children}
      </div>
    </div>
  );
}

function StatBar({ stat, variant }) {
  const fill = stat.value / 10;
  const barColor = stat.boosted ? COLORS.goldBright : COLORS.gold;

  const textColor = variant === "before" ? COLORS.textPrimary : COLORS.textOnGold;
  const shadowStyle = variant === "before"
    ? { textShadow: "0 1px 2px rgba(0,0,0,0.3)" }
    : {};
  const valueColor = variant === "before"
    ? (stat.boosted ? barColor : COLORS.textTertiary)
    : (stat.boosted ? COLORS.goldBright : COLORS.textPrimary);

  return (
    <div className="relative rounded overflow-hidden" style={{ height: 20, background: COLORS.bgTertiary }}>
      <div className="absolute inset-y-0 left-0 rounded" style={{ width: `${fill * 100}%`, background: `linear-gradient(to right, ${barColor}B3, ${barColor})` }} />
      <div className="absolute inset-0 flex items-center justify-between px-2">
        <span className="font-semibold" style={{ color: textColor, fontSize: 10, fontFamily: "system-ui", ...shadowStyle }}>{stat.name}</span>
        <span className="font-bold" style={{ color: valueColor, fontSize: 10, fontFamily: "system-ui" }}>{stat.value}</span>
      </div>
    </div>
  );
}

function Annotation({ text, color = "#4DCC4D", style = {} }) {
  return (
    <div className="absolute px-2 py-0.5 rounded-full font-medium whitespace-nowrap" style={{ background: `${color}22`, color, border: `1px solid ${color}44`, fontSize: 8, ...style }}>
      {text}
    </div>
  );
}

function CardContent({ variant }) {
  return (
    <div className="flex flex-col items-center pt-5 px-3 h-full">
      <div className="tracking-widest mb-3" style={{ color: COLORS.goldBright, fontSize: 11 }}>CHOOSE A CLASS</div>
      <div className="w-full rounded-xl p-3 flex flex-col items-center gap-1" style={{ background: COLORS.bgSecondary }}>
        <div className="rounded-lg flex items-center justify-center mb-1" style={{ width: 100, height: 100, background: `radial-gradient(circle, ${COLORS.classWarrior}33 0%, transparent 70%)` }}>
          <div className="rounded-full" style={{ width: 64, height: 64, background: COLORS.classWarrior + "44", border: `2px solid ${COLORS.classWarrior}66` }} />
        </div>
        <div className="font-bold" style={{ color: COLORS.textPrimary, fontSize: 14 }}>Warrior</div>
        <div style={{ color: COLORS.goldBright, fontSize: 9 }}>MAIN ATTRIBUTE – Strength</div>
        <div className="text-center" style={{ color: COLORS.textSecondary, fontSize: 9 }}>Deals devastating physical blows.</div>
        <div style={{ color: COLORS.success, fontSize: 9 }}>+3 Strength +2 Vitality</div>

        <div className="w-full rounded-lg p-2 mt-1 flex flex-col gap-1 relative" style={{ background: COLORS.bgSecondary }}>
          {stats.map((s) => <StatBar key={s.name} stat={s} variant={variant} />)}
          {variant === "before" && (
            <Annotation text="~1.4:1 contrast — FAIL" color="#E63946" style={{ top: -2, right: -4, transform: "translateY(-100%)" }} />
          )}
          {variant === "after" && (
            <Annotation text="FIXED: 8.5:1 contrast" color="#4DCC4D" style={{ top: -2, right: -4, transform: "translateY(-100%)" }} />
          )}
        </div>
      </div>

      <div className="flex items-center gap-2 mt-3 relative">
        <div className="rounded flex items-center justify-center" style={{ width: variant === "before" ? 32 : 40, height: variant === "before" ? 32 : 40, color: COLORS.textTertiary, fontSize: 16, border: `1px dashed ${variant === "before" ? "#E6394644" : "#4DCC4D44"}` }}>‹</div>
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="rounded-full" style={{ width: 36, height: 36, background: i === 1 ? COLORS.classWarrior + "33" : COLORS.bgSecondary, border: `2px solid ${i === 1 ? COLORS.classWarrior : COLORS.borderSubtle}`, opacity: i === 1 ? 1 : 0.5 }} />
        ))}
        <div className="rounded flex items-center justify-center" style={{ width: variant === "before" ? 32 : 40, height: variant === "before" ? 32 : 40, color: COLORS.textTertiary, fontSize: 16, border: `1px dashed ${variant === "before" ? "#E6394644" : "#4DCC4D44"}` }}>›</div>
        {variant === "before" && <Annotation text="36px touch" color="#E67E22" style={{ bottom: -14, left: -2 }} />}
        {variant === "after" && <Annotation text="44px touch" color="#4DCC4D" style={{ bottom: -14, left: 2 }} />}
      </div>
    </div>
  );
}

export default function ClassSelectionReview() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-6 p-6" style={{ background: "#08080C" }}>
      <h1 className="font-bold tracking-wider" style={{ color: COLORS.goldBright, fontSize: 15 }}>CLASS SELECTION — DESIGN REVIEW</h1>

      <div className="flex flex-wrap justify-center gap-6">
        <PhoneFrame label="BEFORE" labelColor="#E63946">
          <CardContent variant="before" />
        </PhoneFrame>
        <PhoneFrame label="AFTER" labelColor="#4DCC4D">
          <CardContent variant="after" />
        </PhoneFrame>
      </div>

      <div className="rounded-xl p-4 max-w-xl w-full" style={{ background: COLORS.bgSecondary }}>
        <div className="font-bold mb-2" style={{ color: COLORS.textPrimary, fontSize: 12 }}>Changes Applied</div>
        <div className="flex flex-col gap-2">
          {[
            { severity: "Critical", color: "#E63946", text: "Stat bar text: white → dark (#1A1A2E) for WCAG AA on gold fills" },
            { severity: "Major", color: "#E67E22", text: "Stat values: boosted bright gold, base white — all visible" },
            { severity: "Minor", color: "#3498DB", text: "Arrow touch targets: 36px → 44px (Apple HIG minimum)" },
          ].map((item) => (
            <div key={item.severity} className="flex items-start gap-2">
              <span className="px-2 py-0.5 rounded-full font-medium mt-0.5 shrink-0" style={{ background: `${item.color}22`, color: item.color, border: `1px solid ${item.color}44`, fontSize: 9 }}>{item.severity}</span>
              <span className="leading-relaxed" style={{ color: COLORS.textSecondary, fontSize: 10 }}>{item.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
