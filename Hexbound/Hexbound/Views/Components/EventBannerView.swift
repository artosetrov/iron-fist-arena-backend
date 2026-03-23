import SwiftUI

// MARK: - Event Banner Data

struct GameEventData: Identifiable {
    let id: String
    let name: String
    let description: String
    let imageKey: String?
    let endsAt: Date
    let themeColor: Color
    let route: String?
}

// MARK: - Event Banner View

/// Themed event banner for Hub and other screens.
/// Shows event name, countdown timer, and themed styling.
/// Integrates with MotionConstants for entrance/pulse animations.
struct EventBannerView: View {
    let event: GameEventData
    var onTap: (() -> Void)? = nil

    @State private var appeared = false
    @State private var timeRemaining: String = ""
    @State private var isUrgent = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            HapticManager.light()
            onTap?()
        } label: {
            HStack(spacing: LayoutConstants.spaceSM) {
                // Event icon / image
                eventIcon

                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.name.uppercased())
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .tracking(1)

                    Text(event.description)
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBadge))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Timer
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeRemaining)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textCaption))
                        .foregroundStyle(isUrgent ? DarkFantasyTheme.arenaRankGold : event.themeColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: MotionConstants.tickUpShort), value: timeRemaining)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
            }
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.spaceXS + 4)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(event.themeColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(event.themeColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.scalePress(0.97))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : MotionConstants.cardSlideDistance)
        .glowPulse(color: event.themeColor, intensity: 0.2, isActive: isUrgent)
        .onAppear {
            updateTimer()
            withAnimation(MotionConstants.spring) {
                appeared = true
            }
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
    }

    // MARK: - Event Icon

    @ViewBuilder
    private var eventIcon: some View {
        if let imageKey = event.imageKey, UIImage(named: imageKey) != nil {
            Image(imageKey)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.radiusSM))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .fill(event.themeColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(event.themeColor)
            }
        }
    }

    // MARK: - Timer

    private func updateTimer() {
        let now = Date()
        let remaining = event.endsAt.timeIntervalSince(now)

        if remaining <= 0 {
            timeRemaining = "Ended"
            isUrgent = false
            return
        }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60

        // Urgent = last 24 hours
        isUrgent = remaining < 86400

        if hours >= 24 {
            let days = hours / 24
            timeRemaining = "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            timeRemaining = "\(hours)h \(minutes)m"
        } else {
            timeRemaining = "\(minutes)m \(seconds)s"
        }
    }
}
