import { useState } from "react";

const PhoneFrame = ({ children, label }) => (
  <div className="flex flex-col items-center gap-3">
    <span className="text-xs font-bold tracking-widest text-gray-400 uppercase">
      {label}
    </span>
    <div
      className="relative rounded-3xl border-2 border-gray-700 bg-gray-950 overflow-hidden"
      style={{ width: 320, height: 640 }}
    >
      {/* Notch */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-6 bg-black rounded-b-2xl z-30" />
      {/* Status bar */}
      <div className="h-12 bg-gray-950 flex items-end justify-between px-6 pb-1 text-gray-500 text-xs z-20 relative">
        <span>4:27</span>
        <span>●●● ▐▐▐ 🔋</span>
      </div>
      {children}
    </div>
  </div>
);

const Annotation = ({ children, color = "emerald" }) => (
  <div
    className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-${color}-500/20 text-${color}-400 border border-${color}-500/30`}
  >
    <span className="w-1.5 h-1.5 rounded-full bg-current" />
    {children}
  </div>
);

/* ─── BEFORE: Current Toast System ─── */
const BeforeToast = ({ title, subtitle, dotColor }) => (
  <div
    className="flex items-start gap-2.5 px-3 py-2.5 rounded-lg border relative"
    style={{
      background:
        "linear-gradient(135deg, rgba(30,28,38,1) 0%, rgba(38,35,48,1) 100%)",
      borderColor: `${dotColor}80`,
    }}
  >
    <div
      className="w-2 h-2 rounded-full mt-1.5 shrink-0"
      style={{
        backgroundColor: dotColor,
        boxShadow: `0 0 6px ${dotColor}99`,
      }}
    />
    <div className="flex flex-col gap-0.5">
      <span className="text-sm font-semibold text-gray-100">{title}</span>
      {subtitle && (
        <span className="text-xs text-gray-400">{subtitle}</span>
      )}
    </div>
  </div>
);

const BeforeScreen = () => (
  <PhoneFrame label="Before">
    <div className="relative h-full">
      {/* Fake app content behind */}
      <div className="absolute inset-0 bg-gradient-to-b from-gray-900 via-gray-850 to-gray-950">
        <div className="px-4 pt-2">
          {/* Fake hero widget */}
          <div className="h-20 rounded-xl bg-gray-800/60 border border-gray-700/30 flex items-center px-4 gap-3">
            <div className="w-12 h-12 rounded-full bg-gray-700" />
            <div className="flex flex-col gap-1.5 flex-1">
              <div className="h-3 w-24 rounded bg-gray-700" />
              <div className="h-2 w-full rounded-full bg-gray-800">
                <div className="h-2 w-3/4 rounded-full bg-red-900/60" />
              </div>
              <div className="h-2 w-full rounded-full bg-gray-800">
                <div className="h-2 w-1/2 rounded-full bg-amber-900/40" />
              </div>
            </div>
          </div>
          {/* Fake content cards */}
          <div className="mt-3 space-y-2">
            <div className="h-24 rounded-lg bg-gray-800/40 border border-gray-700/20" />
            <div className="h-24 rounded-lg bg-gray-800/40 border border-gray-700/20" />
          </div>
        </div>
      </div>

      {/* Toast stack - the problem */}
      <div className="absolute top-0 left-0 right-0 px-3 pt-1 flex flex-col gap-2 z-20">
        <BeforeToast
          title="Failed to load shop"
          subtitle="Pull to refresh or try again later"
          dotColor="#FF6B6B"
        />
        <BeforeToast
          title="Failed to load shop"
          subtitle="Pull to refresh or try again later"
          dotColor="#FF6B6B"
        />
        <BeforeToast
          title="Session expired, please login again"
          dotColor="#FF6B6B"
        />

        {/* Annotations */}
        <div className="flex flex-wrap gap-1.5 mt-1">
          <Annotation color="red">SPAM: 3 toasts stacked</Annotation>
          <Annotation color="red">Duplicate errors</Annotation>
          <Annotation color="amber">No dismiss gesture</Annotation>
          <Annotation color="amber">Critical = same as error</Annotation>
          <Annotation color="amber">~130pt content blocked</Annotation>
        </div>
      </div>
    </div>
  </PhoneFrame>
);

/* ─── AFTER: Improved Toast System ─── */

const AfterToast = ({ icon, title, subtitle, accentColor, action }) => (
  <div
    className="flex items-center gap-2.5 px-3 py-2.5 rounded-lg border relative overflow-hidden"
    style={{
      background:
        "linear-gradient(135deg, rgba(30,28,38,0.97) 0%, rgba(38,35,48,0.97) 100%)",
      borderColor: `${accentColor}40`,
      backdropFilter: "blur(12px)",
    }}
  >
    {/* Radial glow from left */}
    <div
      className="absolute left-0 top-0 bottom-0 w-16"
      style={{
        background: `radial-gradient(circle at left center, ${accentColor}15, transparent)`,
      }}
    />
    {/* Icon instead of dot */}
    <div
      className="relative w-7 h-7 rounded-md flex items-center justify-center shrink-0"
      style={{
        background: `${accentColor}20`,
        border: `1px solid ${accentColor}30`,
      }}
    >
      <span className="text-sm">{icon}</span>
    </div>
    <div className="flex flex-col gap-0.5 flex-1 relative">
      <span className="text-sm font-semibold text-gray-100">{title}</span>
      {subtitle && (
        <span className="text-xs text-gray-400">{subtitle}</span>
      )}
    </div>
    {action && (
      <button
        className="relative px-3 py-1.5 rounded-md text-xs font-bold shrink-0"
        style={{
          background: `${accentColor}30`,
          color: accentColor,
          border: `1px solid ${accentColor}40`,
          minHeight: 32,
        }}
      >
        {action}
      </button>
    )}
    {/* Swipe hint line */}
    <div className="absolute top-1 left-1/2 -translate-x-1/2 w-8 h-0.5 rounded-full bg-gray-600/40" />
  </div>
);

const SessionExpiredModal = () => (
  <div className="absolute inset-0 z-30 flex items-center justify-center">
    {/* Backdrop */}
    <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" />
    {/* Modal */}
    <div className="relative w-64 rounded-2xl border border-amber-500/20 overflow-hidden">
      {/* Glow background */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "radial-gradient(circle at center, rgba(45,40,55,1), rgba(25,22,32,1))",
        }}
      />
      <div className="relative p-5 flex flex-col items-center gap-4">
        {/* Icon */}
        <div className="w-14 h-14 rounded-full bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
          <span className="text-2xl">🔒</span>
        </div>
        <div className="text-center">
          <p className="text-base font-bold text-gray-100 mb-1">
            Session Expired
          </p>
          <p className="text-xs text-gray-400">
            Please log in again to continue your adventure
          </p>
        </div>
        {/* CTA */}
        <button
          className="w-full py-3 rounded-lg text-sm font-bold text-gray-900"
          style={{
            background: "linear-gradient(180deg, #FFD700, #D4A537)",
          }}
        >
          Log In
        </button>
        {/* Corner brackets */}
        <div className="absolute top-2 left-2 w-4 h-4 border-t border-l border-amber-500/30" />
        <div className="absolute top-2 right-2 w-4 h-4 border-t border-r border-amber-500/30" />
        <div className="absolute bottom-2 left-2 w-4 h-4 border-b border-l border-amber-500/30" />
        <div className="absolute bottom-2 right-2 w-4 h-4 border-b border-r border-amber-500/30" />
      </div>
    </div>
  </div>
);

const AfterScreen = () => (
  <PhoneFrame label="After">
    <div className="relative h-full">
      {/* Same fake app content */}
      <div className="absolute inset-0 bg-gradient-to-b from-gray-900 via-gray-850 to-gray-950">
        <div className="px-4 pt-2">
          <div className="h-20 rounded-xl bg-gray-800/60 border border-gray-700/30 flex items-center px-4 gap-3">
            <div className="w-12 h-12 rounded-full bg-gray-700" />
            <div className="flex flex-col gap-1.5 flex-1">
              <div className="h-3 w-24 rounded bg-gray-700" />
              <div className="h-2 w-full rounded-full bg-gray-800">
                <div className="h-2 w-3/4 rounded-full bg-red-900/60" />
              </div>
              <div className="h-2 w-full rounded-full bg-gray-800">
                <div className="h-2 w-1/2 rounded-full bg-amber-900/40" />
              </div>
            </div>
          </div>
          <div className="mt-3 space-y-2">
            <div className="h-24 rounded-lg bg-gray-800/40 border border-gray-700/20" />
            <div className="h-24 rounded-lg bg-gray-800/40 border border-gray-700/20" />
          </div>
        </div>
      </div>

      {/* IMPROVED: Single deduplicated toast at top */}
      <div className="absolute top-0 left-0 right-0 px-3 pt-1 z-20">
        <AfterToast
          icon="⚠️"
          title="Failed to load shop"
          subtitle="Check your connection"
          accentColor="#FF6B6B"
          action="RETRY"
        />
        {/* Annotations for toast */}
        <div className="flex flex-wrap gap-1.5 mt-2">
          <Annotation color="emerald">1 toast max, deduplicated</Annotation>
          <Annotation color="emerald">Icon + action button</Annotation>
          <Annotation color="emerald">Swipe up to dismiss ↑</Annotation>
        </div>
      </div>

      {/* Session expired as modal (shown below as separate concept) */}
      <div className="absolute bottom-3 left-3 right-3 z-20">
        <div className="bg-gray-900/90 border border-gray-700/50 rounded-lg p-2.5">
          <p className="text-xs font-semibold text-amber-400 mb-1.5">
            ✦ Session expired → blocking modal:
          </p>
          <div className="rounded-lg border border-amber-500/20 p-3 flex flex-col items-center gap-2" style={{background: "rgba(30,28,38,0.95)"}}>
            <span className="text-lg">🔒</span>
            <p className="text-xs font-bold text-gray-200">Session Expired</p>
            <p className="text-xs text-gray-500 text-center">Log in again to continue</p>
            <div
              className="w-full py-1.5 rounded text-xs font-bold text-gray-900 text-center"
              style={{ background: "linear-gradient(180deg, #FFD700, #D4A537)" }}
            >
              Log In
            </div>
          </div>
          <Annotation color="emerald">
            Critical errors = modal, not toast
          </Annotation>
        </div>
      </div>
    </div>
  </PhoneFrame>
);

/* ─── Main Component ─── */
export default function ToastReviewBeforeAfter() {
  return (
    <div className="min-h-screen bg-gray-950 text-white p-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold text-gray-100 mb-2">
            Toast System — Before / After
          </h1>
          <p className="text-sm text-gray-400">
            Kuzya UI/UX Review • Hexbound Notification System
          </p>
        </div>

        {/* Side by side */}
        <div className="flex flex-wrap justify-center gap-8 mb-10">
          <BeforeScreen />
          <AfterScreen />
        </div>

        {/* Legend */}
        <div className="max-w-xl mx-auto bg-gray-900/60 border border-gray-800 rounded-xl p-5">
          <h2 className="text-sm font-bold text-gray-300 mb-3 uppercase tracking-wider">
            Changes Applied
          </h2>
          <div className="space-y-3 text-sm">
            <div className="flex gap-3">
              <span className="text-red-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #1
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  Deduplication
                </span>
                <span className="text-gray-400">
                  {" "}— same-title toasts collapsed into one. Timer resets on repeat.
                </span>
              </div>
            </div>
            <div className="flex gap-3">
              <span className="text-red-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #2
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  Session expired → modal
                </span>
                <span className="text-gray-400">
                  {" "}— critical auth errors get a blocking modal with single CTA, not a dismissable toast.
                </span>
              </div>
            </div>
            <div className="flex gap-3">
              <span className="text-amber-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #3
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  1 toast limit
                </span>
                <span className="text-gray-400">
                  {" "}— max 1 visible toast at a time. Queue with FIFO, new replaces old.
                </span>
              </div>
            </div>
            <div className="flex gap-3">
              <span className="text-amber-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #4
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  Icons replace dots
                </span>
                <span className="text-gray-400">
                  {" "}— type-specific SF Symbol in colored container. Accessibility: color + icon + text.
                </span>
              </div>
            </div>
            <div className="flex gap-3">
              <span className="text-amber-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #5
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  Swipe to dismiss
                </span>
                <span className="text-gray-400">
                  {" "}— drag up gesture removes toast instantly. Swipe handle hint at top.
                </span>
              </div>
            </div>
            <div className="flex gap-3">
              <span className="text-amber-400 font-mono text-xs mt-0.5 shrink-0 w-6">
                #6
              </span>
              <div>
                <span className="font-semibold text-gray-200">
                  Retry action on errors
                </span>
                <span className="text-gray-400">
                  {" "}— all error toasts get a contextual retry button instead of passive text.
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
