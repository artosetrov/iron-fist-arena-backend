import { useState } from "react";

const colors = {
  bgAbyss: "#0a0a0f",
  bgPrimary: "#12121a",
  bgSecondary: "#1a1a2e",
  bgTertiary: "#252540",
  gold: "#D4A537",
  goldBright: "#FFD700",
  goldDim: "#8B6914",
  textPrimary: "#e8e0d0",
  textSecondary: "#a09880",
  textTertiary: "#6b6050",
  danger: "#c0392b",
  dangerDim: "#8b2020",
  success: "#27ae60",
  successDim: "#1a7a40",
  info: "#3498db",
  infoDim: "#1a5a8a",
  borderMedium: "#3a3a50",
  borderSubtle: "#2a2a3e",
};

const fonts = {
  title: "Oswald, sans-serif",
  body: "Inter, system-ui, sans-serif",
};

// ──── Shared Components ────

const PhoneFrame = ({ children, label }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
    <div style={{
      fontFamily: fonts.title, fontSize: 13, color: colors.goldBright,
      textTransform: "uppercase", letterSpacing: 2, fontWeight: 600,
    }}>{label}</div>
    <div style={{
      width: 320, height: 640, borderRadius: 28,
      background: colors.bgPrimary,
      border: `2px solid ${colors.borderMedium}`,
      overflow: "hidden", position: "relative",
      boxShadow: `0 0 30px ${colors.bgAbyss}, 0 0 60px rgba(0,0,0,0.5)`,
    }}>
      {children}
    </div>
  </div>
);

const OrnTitle = ({ icon, text }) => (
  <div style={{ textAlign: "center", padding: "14px 0 4px" }}>
    <div style={{
      fontFamily: fonts.title, fontSize: 18, color: colors.goldBright,
      textTransform: "uppercase", letterSpacing: 3, fontWeight: 600,
    }}>{icon} {text}</div>
    <div style={{
      margin: "6px auto 0", width: 180, height: 1,
      background: `linear-gradient(90deg, transparent, ${colors.gold}, transparent)`,
    }} />
    <div style={{
      width: 6, height: 6, background: colors.gold, transform: "rotate(45deg)",
      margin: "-3px auto 0",
    }} />
  </div>
);

const Btn = ({ children, variant = "primary", disabled, small, onClick }) => {
  const styles = {
    primary: {
      background: `linear-gradient(180deg, ${colors.goldBright} 0%, ${colors.gold} 50%, ${colors.goldDim} 100%)`,
      color: colors.bgAbyss, fontWeight: 700,
      boxShadow: `0 0 12px ${colors.goldDim}80, inset 0 1px 0 rgba(255,255,255,0.2)`,
    },
    secondary: {
      background: colors.bgTertiary,
      color: colors.textPrimary, fontWeight: 500,
      border: `1px solid ${colors.borderMedium}`,
      boxShadow: `inset 0 1px 0 rgba(255,255,255,0.05)`,
    },
    danger: {
      background: `linear-gradient(180deg, ${colors.danger}, ${colors.dangerDim})`,
      color: "#fff", fontWeight: 600,
      boxShadow: `0 0 8px ${colors.dangerDim}80`,
    },
    success: {
      background: `linear-gradient(180deg, ${colors.success}, ${colors.successDim})`,
      color: "#fff", fontWeight: 600,
    },
    ghost: {
      background: "transparent", color: colors.textSecondary, fontWeight: 500,
    },
  };
  return (
    <button onClick={onClick} style={{
      ...styles[variant],
      width: "100%", padding: small ? "8px 12px" : "13px 16px",
      borderRadius: 8, border: styles[variant].border || "none",
      fontFamily: fonts.title, fontSize: small ? 12 : 14,
      textTransform: "uppercase", letterSpacing: 1.5,
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.4 : 1,
      transition: "all 0.15s",
    }}>{children}</button>
  );
};

const Avatar = ({ size = 40, name = "?", online }) => (
  <div style={{ position: "relative", flexShrink: 0 }}>
    <div style={{
      width: size, height: size, borderRadius: size * 0.35,
      background: `linear-gradient(135deg, ${colors.bgTertiary}, ${colors.bgSecondary})`,
      border: `2px solid ${colors.borderMedium}`,
      display: "flex", alignItems: "center", justifyContent: "center",
      fontFamily: fonts.title, fontSize: size * 0.4, color: colors.gold,
    }}>{name[0]}</div>
    {online !== undefined && (
      <div style={{
        position: "absolute", bottom: -1, right: -1,
        width: 10, height: 10, borderRadius: 5,
        background: online === "online" ? colors.success : online === "away" ? "#f39c12" : colors.textTertiary,
        border: `2px solid ${colors.bgPrimary}`,
      }} />
    )}
  </div>
);

const Pill = ({ children, color = colors.gold, bg }) => (
  <span style={{
    display: "inline-flex", alignItems: "center", gap: 4,
    padding: "3px 10px", borderRadius: 10,
    background: bg || `${color}15`,
    border: `1px solid ${color}30`,
    fontFamily: fonts.body, fontSize: 11, color,
    whiteSpace: "nowrap",
  }}>{children}</span>
);

const TabBar = ({ tabs, active, onSelect, badges = {} }) => (
  <div style={{
    display: "flex", gap: 2, padding: "0 12px",
    borderBottom: `1px solid ${colors.borderSubtle}`,
  }}>
    {tabs.map(t => (
      <button key={t} onClick={() => onSelect(t)} style={{
        flex: 1, padding: "10px 4px 8px", border: "none", cursor: "pointer",
        background: "transparent",
        borderBottom: active === t ? `2px solid ${colors.gold}` : "2px solid transparent",
        fontFamily: fonts.title, fontSize: 11, letterSpacing: 1.5,
        textTransform: "uppercase",
        color: active === t ? colors.goldBright : colors.textTertiary,
        position: "relative",
      }}>
        {t}
        {badges[t] > 0 && (
          <span style={{
            position: "absolute", top: 4, right: "calc(50% - 20px)",
            minWidth: 16, height: 16, borderRadius: 8,
            background: colors.gold, color: colors.bgAbyss,
            fontSize: 9, fontWeight: 700, fontFamily: fonts.body,
            display: "flex", alignItems: "center", justifyContent: "center",
            padding: "0 4px",
          }}>{badges[t]}</span>
        )}
      </button>
    ))}
  </div>
);

const Panel = ({ children, accent, style: s }) => (
  <div style={{
    background: `radial-gradient(ellipse at 50% 30%, ${colors.bgTertiary}40, ${colors.bgSecondary})`,
    borderRadius: 12, padding: 12,
    border: `1px solid ${accent ? `${accent}20` : colors.borderSubtle}`,
    boxShadow: `0 4px 12px ${colors.bgAbyss}60, inset 0 1px 0 rgba(255,255,255,0.04)`,
    ...s,
  }}>{children}</div>
);

const Divider = ({ label }) => (
  <div style={{
    display: "flex", alignItems: "center", gap: 8,
    padding: "4px 0", margin: "4px 0",
  }}>
    <div style={{ flex: 1, height: 1, background: colors.borderSubtle }} />
    {label && <span style={{
      fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary,
      textTransform: "uppercase", letterSpacing: 1.5,
    }}>{label}</span>}
    <div style={{ flex: 1, height: 1, background: colors.borderSubtle }} />
  </div>
);

const Toast = ({ text, type = "info" }) => {
  const c = type === "info" ? colors.info : type === "success" ? colors.success : colors.gold;
  return (
    <div style={{
      position: "absolute", top: 10, left: 12, right: 12, zIndex: 10,
      background: `${colors.bgSecondary}f0`, borderRadius: 10,
      border: `1px solid ${c}40`, padding: "10px 14px",
      fontFamily: fonts.body, fontSize: 12, color: colors.textPrimary,
      boxShadow: `0 4px 16px ${colors.bgAbyss}`,
      display: "flex", alignItems: "center", gap: 8,
    }}>
      <div style={{
        width: 6, height: 6, borderRadius: 3, background: c,
        boxShadow: `0 0 6px ${c}`,
      }} />
      {text}
    </div>
  );
};

// ──── Screen 1: Challenge Confirmation ────

const ChallengeConfirmScreen = () => {
  const [state, setState] = useState("default"); // default | friend | lowStamina | cooldown | warning
  return (
    <PhoneFrame label="Challenge Confirm">
      <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
        {/* Top: Opponent Profile peek */}
        <div style={{
          background: `linear-gradient(180deg, ${colors.bgSecondary}, ${colors.bgPrimary})`,
          padding: "40px 16px 16px", textAlign: "center",
        }}>
          <Avatar size={56} name="D" />
          <div style={{
            fontFamily: fonts.title, fontSize: 20, color: colors.textPrimary,
            marginTop: 8, fontWeight: 600,
          }}>DarkLord_99</div>
          <div style={{
            fontFamily: fonts.body, fontSize: 12, color: colors.textSecondary,
            marginTop: 2,
          }}>Lv.45 · Mage · Gold Rank</div>
          <div style={{ display: "flex", gap: 6, justifyContent: "center", marginTop: 8 }}>
            <Pill color={colors.gold}>⚔ 1842 Rating</Pill>
            <Pill color={colors.success}>67% Win</Pill>
          </div>
        </div>

        {/* State selector (for prototype) */}
        <div style={{ display: "flex", gap: 4, padding: "8px 12px", flexWrap: "wrap" }}>
          {["default", "friend", "lowStamina", "cooldown", "warning"].map(s => (
            <button key={s} onClick={() => setState(s)} style={{
              padding: "3px 8px", borderRadius: 6, border: "none", cursor: "pointer",
              background: state === s ? colors.gold : colors.bgTertiary,
              color: state === s ? colors.bgAbyss : colors.textSecondary,
              fontSize: 9, fontFamily: fonts.body,
            }}>{s}</button>
          ))}
        </div>

        {/* Confirmation content */}
        <div style={{ flex: 1, padding: "0 16px", display: "flex", flexDirection: "column", gap: 10 }}>
          <Panel>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textSecondary }}>
                  ⚡ Stamina Cost
                </span>
                <span style={{
                  fontFamily: fonts.title, fontSize: 15, fontWeight: 600,
                  color: state === "friend" ? colors.success : state === "lowStamina" ? colors.danger : colors.textPrimary,
                }}>
                  {state === "friend" ? "FREE" : state === "lowStamina" ? "10 (need 4 more)" : "10"}
                </span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textSecondary }}>
                  📊 Rating Risk
                </span>
                <span style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>
                  ±15–25
                </span>
              </div>
              {state === "friend" && (
                <div style={{
                  padding: "6px 10px", borderRadius: 8,
                  background: `${colors.success}15`, border: `1px solid ${colors.success}30`,
                  fontFamily: fonts.body, fontSize: 11, color: colors.success,
                }}>
                  ✓ Friends fight for free — no stamina cost!
                </div>
              )}
              {state === "warning" && (
                <div style={{
                  padding: "6px 10px", borderRadius: 8,
                  background: `${colors.gold}15`, border: `1px solid ${colors.gold}30`,
                  fontFamily: fonts.body, fontSize: 11, color: colors.gold,
                }}>
                  ⚠ Level gap: 12 levels. Opponent may be much stronger.
                </div>
              )}
              {state === "cooldown" && (
                <div style={{
                  padding: "6px 10px", borderRadius: 8,
                  background: `${colors.info}15`, border: `1px solid ${colors.info}30`,
                  fontFamily: fonts.body, fontSize: 11, color: colors.info,
                }}>
                  ⏳ Cooldown active. Available in 24:30
                </div>
              )}
            </div>
          </Panel>

          <div style={{ marginTop: "auto", paddingBottom: 20, display: "flex", flexDirection: "column", gap: 8 }}>
            <Btn variant="primary" disabled={state === "lowStamina" || state === "cooldown"}>
              🔥 FIGHT!
            </Btn>
            {state === "lowStamina" && (
              <Btn variant="secondary" small>⚡ Get Stamina (10 gems)</Btn>
            )}
            <Btn variant="ghost">Cancel</Btn>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
};

// ──── Screen 2: Combat Result with Social Actions ────

const CombatResultScreen = () => (
  <PhoneFrame label="Post-Challenge Result">
    <div style={{
      height: "100%", display: "flex", flexDirection: "column",
      background: `radial-gradient(ellipse at 50% 20%, ${colors.goldDim}20, ${colors.bgPrimary})`,
    }}>
      {/* Victory card */}
      <div style={{ textAlign: "center", padding: "48px 16px 16px" }}>
        <div style={{
          fontFamily: fonts.title, fontSize: 32, color: colors.goldBright,
          textTransform: "uppercase", letterSpacing: 4, fontWeight: 700,
          textShadow: `0 0 20px ${colors.goldDim}`,
        }}>VICTORY!</div>
        <div style={{
          fontFamily: fonts.body, fontSize: 13, color: colors.textSecondary, marginTop: 4,
        }}>vs DarkLord_99</div>
      </div>

      {/* Rewards */}
      <div style={{ padding: "0 16px", display: "flex", flexDirection: "column", gap: 8 }}>
        <Panel accent={colors.gold}>
          <div style={{ display: "flex", justifyContent: "space-around", textAlign: "center" }}>
            {[
              { label: "Gold", value: "+297", color: colors.gold },
              { label: "XP", value: "+150", color: colors.info },
              { label: "Rating", value: "+22", color: colors.success },
            ].map(r => (
              <div key={r.label}>
                <div style={{ fontFamily: fonts.title, fontSize: 20, color: r.color, fontWeight: 600 }}>
                  {r.value}
                </div>
                <div style={{ fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary, marginTop: 2 }}>
                  {r.label}
                </div>
              </div>
            ))}
          </div>
        </Panel>

        {/* Loot preview */}
        <Panel style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <div style={{
            width: 40, height: 40, borderRadius: 8,
            background: `linear-gradient(135deg, ${colors.info}40, ${colors.bgTertiary})`,
            border: `2px solid ${colors.info}60`,
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 18,
          }}>⚔</div>
          <div>
            <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>
              Steel Greatsword
            </div>
            <div style={{ fontFamily: fonts.body, fontSize: 11, color: colors.info }}>Rare</div>
          </div>
        </Panel>
      </div>

      {/* Social actions — NEW for challenge flow */}
      <div style={{ marginTop: "auto", padding: "0 16px 24px", display: "flex", flexDirection: "column", gap: 8 }}>
        <Divider label="Actions" />
        <div style={{ display: "flex", gap: 8 }}>
          <div style={{ flex: 1 }}><Btn variant="primary" small>🔥 Rematch</Btn></div>
          <div style={{ flex: 1 }}><Btn variant="secondary" small>📜 Send GG</Btn></div>
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <div style={{ flex: 1 }}><Btn variant="secondary" small>👤 Profile</Btn></div>
          <div style={{ flex: 1 }}><Btn variant="ghost" small>🏠 Hub</Btn></div>
        </div>
      </div>
    </div>
  </PhoneFrame>
);

// ──── Screen 3: Friends List (Tavern) ────

const FriendsListScreen = () => {
  const [tab, setTab] = useState("ALLIES");
  return (
    <PhoneFrame label="Guild Hall — Allies">
      <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
        <OrnTitle icon="⚔" text="Guild Hall" />
        <TabBar
          tabs={["ALLIES", "SCROLLS", "DUELS"]}
          active={tab}
          onSelect={setTab}
          badges={{ ALLIES: 2, SCROLLS: 3 }}
        />

        <div style={{ flex: 1, overflowY: "auto", padding: "8px 12px" }}>
          {/* Alliance Requests */}
          <Panel accent={colors.gold} style={{ marginBottom: 10 }}>
            <div style={{
              fontFamily: fonts.title, fontSize: 11, color: colors.gold,
              textTransform: "uppercase", letterSpacing: 1.5, marginBottom: 8,
            }}>Alliance Requests (2)</div>

            {[
              { name: "SkullCrusher", lvl: 32, cls: "Warrior", rank: "Silver" },
              { name: "MageDoom", lvl: 28, cls: "Mage", rank: "Bronze" },
            ].map((p, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "center", gap: 10, padding: "8px 0",
                borderTop: i > 0 ? `1px solid ${colors.borderSubtle}` : "none",
              }}>
                <Avatar size={36} name={p.name} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary, fontWeight: 500 }}>
                    {p.name}
                  </div>
                  <div style={{ fontFamily: fonts.body, fontSize: 11, color: colors.textSecondary }}>
                    Lv.{p.lvl} · {p.cls} · {p.rank}
                  </div>
                </div>
                <div style={{ display: "flex", gap: 6 }}>
                  <button style={{
                    width: 32, height: 32, borderRadius: 8, border: "none",
                    background: `${colors.success}20`, color: colors.success,
                    fontSize: 16, cursor: "pointer",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>✓</button>
                  <button style={{
                    width: 32, height: 32, borderRadius: 8, border: "none",
                    background: `${colors.danger}15`, color: colors.danger,
                    fontSize: 14, cursor: "pointer",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>✗</button>
                </div>
              </div>
            ))}
          </Panel>

          {/* Online Friends */}
          <Divider label="Online (3)" />
          {[
            { name: "NightBlade", lvl: 41, cls: "Rogue", rank: "Gold", status: "online" },
            { name: "IronFist", lvl: 38, cls: "Tank", rank: "Gold", status: "online" },
            { name: "ShadowFang", lvl: 35, cls: "Warrior", rank: "Silver", status: "away" },
          ].map((f, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 10, padding: "10px 0",
              borderBottom: `1px solid ${colors.borderSubtle}10`,
            }}>
              <Avatar size={36} name={f.name} online={f.status} />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary, fontWeight: 500 }}>
                  {f.name}
                </div>
                <div style={{ fontFamily: fonts.body, fontSize: 11, color: colors.textSecondary }}>
                  Lv.{f.lvl} · {f.cls} · {f.rank}
                </div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {["⚔", "💬", "👁"].map((icon, j) => (
                  <button key={j} style={{
                    width: 28, height: 28, borderRadius: 6, border: `1px solid ${colors.borderSubtle}`,
                    background: colors.bgTertiary, color: colors.textSecondary,
                    fontSize: 12, cursor: "pointer",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>{icon}</button>
                ))}
              </div>
            </div>
          ))}

          {/* Offline Friends */}
          <Divider label="Offline (2)" />
          {[
            { name: "DeathMage", lvl: 45, cls: "Mage", rank: "Platinum", lastSeen: "2h ago" },
            { name: "StormKnight", lvl: 50, cls: "Tank", rank: "Diamond", lastSeen: "1d ago" },
          ].map((f, i) => (
            <div key={i} style={{
              display: "flex", alignItems: "center", gap: 10, padding: "10px 0",
              opacity: 0.7,
            }}>
              <Avatar size={36} name={f.name} online="offline" />
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary, fontWeight: 500 }}>
                  {f.name}
                </div>
                <div style={{ fontFamily: fonts.body, fontSize: 11, color: colors.textTertiary }}>
                  Lv.{f.lvl} · {f.cls} · {f.lastSeen}
                </div>
              </div>
              <div style={{ display: "flex", gap: 6 }}>
                {["⚔", "💬", "👁"].map((icon, j) => (
                  <button key={j} style={{
                    width: 28, height: 28, borderRadius: 6, border: `1px solid ${colors.borderSubtle}`,
                    background: colors.bgTertiary, color: colors.textTertiary,
                    fontSize: 12, cursor: "pointer",
                    display: "flex", alignItems: "center", justifyContent: "center",
                  }}>{icon}</button>
                ))}
              </div>
            </div>
          ))}

          {/* Counter */}
          <div style={{
            textAlign: "center", padding: "12px 0 8px",
            fontFamily: fonts.body, fontSize: 11, color: colors.textTertiary,
          }}>7 / 50 allies</div>
        </div>
      </div>
    </PhoneFrame>
  );
};

// ──── Screen 4: Message Compose ────

const MessageComposeScreen = () => {
  const [selected, setSelected] = useState(null);
  const [text, setText] = useState("");
  const quickMessages = [
    "GG ⚔️", "Nice fight!", "Greetings!", "Rematch?", "Good luck!", "Revenge...", "Cool gear!",
  ];
  return (
    <PhoneFrame label="Send Scroll">
      <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
        <OrnTitle icon="📜" text="Send Scroll" />

        <div style={{ padding: "12px 16px", display: "flex", flexDirection: "column", gap: 12, flex: 1 }}>
          {/* Recipient */}
          <div style={{
            display: "flex", alignItems: "center", gap: 10,
            padding: "8px 12px", borderRadius: 8,
            background: colors.bgSecondary, border: `1px solid ${colors.borderSubtle}`,
          }}>
            <span style={{ fontFamily: fonts.body, fontSize: 12, color: colors.textTertiary }}>To:</span>
            <Avatar size={24} name="D" />
            <span style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>DarkLord_99</span>
            <Pill color={colors.textSecondary}>Lv.45</Pill>
          </div>

          {/* Quick messages */}
          <div>
            <div style={{
              fontFamily: fonts.body, fontSize: 11, color: colors.textTertiary,
              textTransform: "uppercase", letterSpacing: 1, marginBottom: 6,
            }}>Quick Message</div>
            <div style={{
              display: "flex", gap: 6, flexWrap: "wrap",
            }}>
              {quickMessages.map((q, i) => (
                <button key={i} onClick={() => { setSelected(i); setText(q); }} style={{
                  padding: "6px 12px", borderRadius: 16,
                  background: selected === i ? `${colors.gold}25` : colors.bgTertiary,
                  border: `1px solid ${selected === i ? colors.gold : colors.borderSubtle}`,
                  color: selected === i ? colors.goldBright : colors.textSecondary,
                  fontFamily: fonts.body, fontSize: 12, cursor: "pointer",
                  transition: "all 0.15s",
                }}>{q}</button>
              ))}
            </div>
          </div>

          {/* Text area */}
          <div>
            <div style={{
              fontFamily: fonts.body, fontSize: 11, color: colors.textTertiary,
              textTransform: "uppercase", letterSpacing: 1, marginBottom: 6,
            }}>Or write your own</div>
            <div style={{
              background: colors.bgSecondary, borderRadius: 10,
              border: `1px solid ${colors.borderMedium}`,
              padding: 12,
              boxShadow: `inset 0 2px 4px ${colors.bgAbyss}40`,
            }}>
              <textarea
                value={text}
                onChange={e => { setText(e.target.value.slice(0, 200)); setSelected(null); }}
                placeholder="Write your message..."
                style={{
                  width: "100%", minHeight: 72, background: "transparent", border: "none",
                  color: colors.textPrimary, fontFamily: fonts.body, fontSize: 14,
                  resize: "none", outline: "none",
                }}
              />
              <div style={{
                textAlign: "right", fontFamily: fonts.body, fontSize: 11,
                color: text.length >= 180 ? colors.danger : colors.textTertiary,
                marginTop: 4,
              }}>{text.length}/200</div>
            </div>
          </div>

          {/* Send */}
          <div style={{ marginTop: "auto", paddingBottom: 16 }}>
            <Btn variant="primary" disabled={text.length === 0}>📤 SEND</Btn>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
};

// ──── Screen 5: Inbox ────

const InboxScreen = () => (
  <PhoneFrame label="Guild Hall — Scrolls">
    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <OrnTitle icon="⚔" text="Guild Hall" />
      <TabBar
        tabs={["ALLIES", "SCROLLS", "DUELS"]}
        active="SCROLLS"
        onSelect={() => {}}
        badges={{ ALLIES: 2, SCROLLS: 3 }}
      />

      <div style={{ flex: 1, overflowY: "auto", padding: "8px 12px" }}>
        {/* Today */}
        <Divider label="Today" />
        {[
          { name: "SkullCrusher", msg: "Good game! ⚔️", time: "2 min ago", unread: true },
          { name: "NightBlade", msg: "Rematch? Meet me in the arena!", time: "1 hour ago", unread: true },
          { name: "MageDoom", msg: "That was a close one!", time: "3 hours ago", unread: true },
        ].map((m, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10, padding: "10px 4px",
            borderBottom: `1px solid ${colors.borderSubtle}10`,
            cursor: "pointer",
          }}>
            {m.unread && (
              <div style={{
                width: 6, height: 6, borderRadius: 3, background: colors.gold,
                boxShadow: `0 0 6px ${colors.gold}60`,
                flexShrink: 0,
              }} />
            )}
            <Avatar size={36} name={m.name} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                fontFamily: fonts.body, fontSize: 13,
                color: colors.textPrimary,
                fontWeight: m.unread ? 600 : 400,
              }}>{m.name}</div>
              <div style={{
                fontFamily: fonts.body, fontSize: 12,
                color: m.unread ? colors.textSecondary : colors.textTertiary,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>{m.msg}</div>
            </div>
            <span style={{
              fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary,
              flexShrink: 0,
            }}>{m.time}</span>
          </div>
        ))}

        {/* Yesterday */}
        <Divider label="Yesterday" />
        {[
          { name: "IronFist", msg: "Impressive gear you have!", time: "Yesterday" },
          { name: "DeathMage", msg: "I'll be back for revenge...", time: "Yesterday" },
        ].map((m, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10, padding: "10px 4px",
            borderBottom: `1px solid ${colors.borderSubtle}10`,
            opacity: 0.7,
          }}>
            <div style={{ width: 6 }} />
            <Avatar size={36} name={m.name} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>{m.name}</div>
              <div style={{
                fontFamily: fonts.body, fontSize: 12, color: colors.textTertiary,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>{m.msg}</div>
            </div>
            <span style={{ fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary }}>{m.time}</span>
          </div>
        ))}
      </div>
    </div>
  </PhoneFrame>
);

// ──── Screen 6: Challenge Log ────

const ChallengeLogScreen = () => (
  <PhoneFrame label="Guild Hall — Duels">
    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      <OrnTitle icon="⚔" text="Guild Hall" />
      <TabBar
        tabs={["ALLIES", "SCROLLS", "DUELS"]}
        active="DUELS"
        onSelect={() => {}}
        badges={{ ALLIES: 2 }}
      />

      <div style={{ flex: 1, overflowY: "auto", padding: "8px 12px" }}>
        <Divider label="Incoming Challenges" />

        {/* Lost challenge */}
        <Panel accent={colors.danger} style={{ marginBottom: 8 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <Avatar size={36} name="S" />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>
                <span style={{ fontWeight: 600 }}>SkullCrusher</span> challenged you
              </div>
              <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
                <Pill color={colors.danger}>Defeat</Pill>
                <Pill color={colors.danger}>-18 rating</Pill>
                <span style={{ fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary, alignSelf: "center" }}>2h ago</span>
              </div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
            <div style={{ flex: 1 }}><Btn variant="danger" small>🔥 Revenge</Btn></div>
            <div style={{ flex: 1 }}><Btn variant="ghost" small>👁 Profile</Btn></div>
          </div>
        </Panel>

        {/* Won challenge */}
        <Panel accent={colors.success} style={{ marginBottom: 8 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <Avatar size={36} name="M" />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: fonts.body, fontSize: 13, color: colors.textPrimary }}>
                <span style={{ fontWeight: 600 }}>MageDoom</span> challenged you
              </div>
              <div style={{ display: "flex", gap: 6, marginTop: 4 }}>
                <Pill color={colors.success}>Victory</Pill>
                <Pill color={colors.success}>+22 rating</Pill>
                <span style={{ fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary, alignSelf: "center" }}>5h ago</span>
              </div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
            <div style={{ flex: 1 }}><Btn variant="ghost" small>👁 Profile</Btn></div>
          </div>
        </Panel>

        <Divider label="Your Challenges" />

        {[
          { name: "NightBlade", result: "Victory", rating: "+15", color: colors.success, time: "Yesterday" },
          { name: "IronFist", result: "Defeat", rating: "-12", color: colors.danger, time: "Yesterday" },
          { name: "DeathMage", result: "Victory", rating: "+28", color: colors.success, time: "2 days ago" },
        ].map((c, i) => (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 10, padding: "8px 0",
            borderBottom: `1px solid ${colors.borderSubtle}10`,
          }}>
            <Avatar size={32} name={c.name} />
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: fonts.body, fontSize: 12, color: colors.textSecondary }}>
                You challenged <span style={{ color: colors.textPrimary, fontWeight: 500 }}>{c.name}</span>
              </div>
              <div style={{ display: "flex", gap: 6, marginTop: 3 }}>
                <Pill color={c.color}>{c.result}</Pill>
                <Pill color={c.color}>{c.rating}</Pill>
                <span style={{ fontFamily: fonts.body, fontSize: 10, color: colors.textTertiary, alignSelf: "center" }}>{c.time}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  </PhoneFrame>
);

// ──── Screen 7: Add Friend Button States ────

const AddFriendStatesScreen = () => {
  const [state, setState] = useState("default");
  const states = {
    default: { text: "👤 ADD FRIEND", variant: "secondary" },
    sent: { text: "✓ REQUEST SENT", variant: "ghost", disabled: true },
    friends: { text: "✓ FRIENDS", variant: "success", disabled: true },
    accept: { text: "✓ ACCEPT FRIEND", variant: "primary" },
    blocked: { text: "🚫 BLOCKED", variant: "danger" },
    full: { text: "👤 ADD FRIEND", variant: "secondary", disabled: true },
  };
  const s = states[state];
  return (
    <PhoneFrame label="Add Friend States">
      <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
        {/* Mini profile header */}
        <div style={{
          background: `linear-gradient(180deg, ${colors.bgSecondary}, ${colors.bgPrimary})`,
          padding: "40px 16px 16px", textAlign: "center",
        }}>
          <Avatar size={56} name="D" />
          <div style={{
            fontFamily: fonts.title, fontSize: 20, color: colors.textPrimary,
            marginTop: 8, fontWeight: 600,
          }}>DarkLord_99</div>
          <div style={{
            fontFamily: fonts.body, fontSize: 12, color: colors.textSecondary, marginTop: 2,
          }}>Lv.45 · Mage · Gold</div>
        </div>

        {/* State selector */}
        <div style={{ display: "flex", gap: 4, padding: "12px 12px 4px", flexWrap: "wrap" }}>
          {Object.keys(states).map(st => (
            <button key={st} onClick={() => setState(st)} style={{
              padding: "3px 8px", borderRadius: 6, border: "none", cursor: "pointer",
              background: state === st ? colors.gold : colors.bgTertiary,
              color: state === st ? colors.bgAbyss : colors.textSecondary,
              fontSize: 9, fontFamily: fonts.body,
            }}>{st}</button>
          ))}
        </div>

        {/* Buttons area */}
        <div style={{ padding: "16px 16px", display: "flex", flexDirection: "column", gap: 8 }}>
          <Btn variant="primary">🔥 CHALLENGE</Btn>

          <div style={{ display: "flex", gap: 8 }}>
            <div style={{ flex: 1 }}>
              <Btn variant="secondary" small>📜 Scroll</Btn>
            </div>
            <div style={{ flex: 1 }}>
              <Btn variant={s.variant} disabled={s.disabled} small>{s.text}</Btn>
            </div>
          </div>

          {state === "full" && (
            <div style={{
              fontFamily: fonts.body, fontSize: 11, color: colors.textTertiary,
              textAlign: "center", marginTop: -4,
            }}>Friend list full (50/50)</div>
          )}
          {state === "accept" && (
            <div style={{
              padding: "6px 10px", borderRadius: 8,
              background: `${colors.gold}15`, border: `1px solid ${colors.gold}30`,
              fontFamily: fonts.body, fontSize: 11, color: colors.gold,
              textAlign: "center",
            }}>This player wants to be your friend!</div>
          )}
        </div>

        {/* Toast preview */}
        {state === "sent" && <Toast text="Friend request sent to DarkLord_99" type="info" />}
        {state === "friends" && <Toast text="You and DarkLord_99 are now friends!" type="success" />}
      </div>
    </PhoneFrame>
  );
};

// ──── Screen 8: Empty States ────

const EmptyStatesScreen = () => {
  const [view, setView] = useState("allies");
  return (
    <PhoneFrame label="Empty States">
      <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
        <OrnTitle icon="⚔" text="Guild Hall" />

        {/* View selector */}
        <div style={{ display: "flex", gap: 4, padding: "8px 12px", justifyContent: "center" }}>
          {["allies", "scrolls", "duels"].map(v => (
            <button key={v} onClick={() => setView(v)} style={{
              padding: "4px 12px", borderRadius: 6, border: "none", cursor: "pointer",
              background: view === v ? colors.gold : colors.bgTertiary,
              color: view === v ? colors.bgAbyss : colors.textSecondary,
              fontSize: 10, fontFamily: fonts.body, textTransform: "uppercase",
            }}>{v}</button>
          ))}
        </div>

        <div style={{
          flex: 1, display: "flex", flexDirection: "column",
          alignItems: "center", justifyContent: "center",
          padding: "0 32px", textAlign: "center",
        }}>
          <div style={{ fontSize: 48, marginBottom: 16, opacity: 0.4 }}>
            {view === "allies" ? "🛡" : view === "scrolls" ? "📜" : "⚔"}
          </div>
          <div style={{
            fontFamily: fonts.title, fontSize: 18, color: colors.textSecondary,
            marginBottom: 8, fontWeight: 500,
          }}>
            {view === "allies" && "The guild hall stands empty..."}
            {view === "scrolls" && "No scrolls yet"}
            {view === "duels" && "No duels yet"}
          </div>
          <div style={{
            fontFamily: fonts.body, fontSize: 13, color: colors.textTertiary,
            lineHeight: 1.5, marginBottom: 20,
          }}>
            {view === "allies" && "Find worthy warriors in the Leaderboard and forge an alliance."}
            {view === "scrolls" && "After your next battle, send a scroll to your opponent!"}
            {view === "duels" && "Challenge someone from the Leaderboard or your allies to forge your legend."}
          </div>
          <div style={{ width: 200 }}>
            <Btn variant="primary" small>
              {view === "allies" && "🏆 Leaderboard"}
              {view === "scrolls" && "⚔ Arena"}
              {view === "duels" && "🏆 Leaderboard"}
            </Btn>
          </div>
        </div>
      </div>
    </PhoneFrame>
  );
};

// ──── Main Layout ────

export default function SocialFlowsPrototype() {
  const [section, setSection] = useState(0);
  const sections = [
    { label: "Challenge", screens: [<ChallengeConfirmScreen key="c1" />, <CombatResultScreen key="c2" />] },
    { label: "Allies", screens: [<FriendsListScreen key="f1" />, <AddFriendStatesScreen key="f2" />] },
    { label: "Scrolls", screens: [<MessageComposeScreen key="m1" />, <InboxScreen key="m2" />] },
    { label: "Duels+", screens: [<ChallengeLogScreen key="l1" />, <EmptyStatesScreen key="e1" />] },
  ];

  return (
    <div style={{
      minHeight: "100vh",
      background: `linear-gradient(180deg, #050508, #0a0a14, #050508)`,
      padding: "24px 16px",
      fontFamily: fonts.body,
    }}>
      {/* Section tabs */}
      <div style={{
        display: "flex", justifyContent: "center", gap: 8, marginBottom: 24,
      }}>
        {sections.map((s, i) => (
          <button key={i} onClick={() => setSection(i)} style={{
            padding: "8px 20px", borderRadius: 8, border: "none", cursor: "pointer",
            background: section === i ? colors.gold : colors.bgTertiary,
            color: section === i ? colors.bgAbyss : colors.textSecondary,
            fontFamily: fonts.title, fontSize: 13, letterSpacing: 1.5,
            textTransform: "uppercase", fontWeight: 600,
            transition: "all 0.2s",
          }}>{s.label}</button>
        ))}
      </div>

      {/* Title */}
      <div style={{ textAlign: "center", marginBottom: 20 }}>
        <div style={{
          fontFamily: fonts.title, fontSize: 14, color: colors.goldBright,
          textTransform: "uppercase", letterSpacing: 4, fontWeight: 600,
        }}>Hexbound Social Features — UX Prototype</div>
        <div style={{
          fontFamily: fonts.body, fontSize: 12, color: colors.textTertiary, marginTop: 4,
        }}>Click state selectors inside screens to preview different states</div>
      </div>

      {/* Screens */}
      <div style={{
        display: "flex", justifyContent: "center", gap: 24, flexWrap: "wrap",
      }}>
        {sections[section].screens}
      </div>

      {/* Legend */}
      <div style={{
        maxWidth: 700, margin: "32px auto 0", padding: "16px 20px",
        background: colors.bgSecondary, borderRadius: 12,
        border: `1px solid ${colors.borderSubtle}`,
      }}>
        <div style={{
          fontFamily: fonts.title, fontSize: 12, color: colors.gold,
          textTransform: "uppercase", letterSpacing: 1.5, marginBottom: 8,
        }}>Interaction Notes</div>
        <div style={{ fontFamily: fonts.body, fontSize: 12, color: colors.textSecondary, lineHeight: 1.8 }}>
          {section === 0 && (
            <>
              <strong style={{ color: colors.textPrimary }}>Challenge Flow:</strong> Opponent Profile → Challenge Confirm Sheet → Combat → Result with social actions.
              Use the state selector to preview: default, friend (free fight), low stamina, cooldown, and level warning states.
              Post-combat adds Rematch + Send GG buttons. Rematch has 30-min cooldown per opponent.
            </>
          )}
          {section === 1 && (
            <>
              <strong style={{ color: colors.textPrimary }}>Allies Flow:</strong> Guild Hall building on Hub → Allies tab shows alliance requests + online/offline allies.
              Each ally has quick-action buttons (challenge, send scroll, view profile). Long-press for remove/block.
              Add Friend button has 6 states — use the selector on the right screen to preview all.
            </>
          )}
          {section === 2 && (
            <>
              <strong style={{ color: colors.textPrimary }}>Scrolls Flow:</strong> Quick message pills for common phrases + custom text (200 char max).
              Scrolls tab groups by day, unread shown with gold dot + bold text. Tap scroll → detail view with Reply + Profile.
              3 scrolls/day to non-allies, unlimited to allies.
            </>
          )}
          {section === 3 && (
            <>
              <strong style={{ color: colors.textPrimary }}>Additional Screens:</strong> Duels Log shows incoming/outgoing challenges with results.
              Lost duels get a Revenge button. Empty states for all 3 tabs have themed illustrations + CTA.
            </>
          )}
        </div>
      </div>
    </div>
  );
}
