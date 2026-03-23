import SwiftUI

// MARK: - Tutorial View (FTUE 3-Step Onboarding)

/// Full-screen guided tutorial shown after character creation.
/// Three objective cards: First Battle → Gear Up → Explore Dungeon.
/// Scrollable horizontally with NPC dialog and a single CTA button.
struct TutorialView: View {
    @Environment(AppState.self) private var appState
    private let tutorial = TutorialManager.shared

    @State private var selectedObjectiveIndex: Int = 0
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @State private var npcAppeared = false
    @State private var ctaAppeared = false

    /// The objective being displayed in the NPC dialog area
    private var displayedObjective: FTUEObjective {
        FTUEObjective.allCases[selectedObjectiveIndex]
    }

    var body: some View {
        ZStack {
            // Background
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            // Subtle radial glow behind content
            RadialGradient(
                colors: [
                    DarkFantasyTheme.gold.opacity(0.03),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : -12)

                Spacer(minLength: LayoutConstants.spaceMD)

                // Cards carousel
                cardsSection
                    .opacity(cardsAppeared ? 1 : 0)

                Spacer(minLength: LayoutConstants.spaceMD)

                // NPC Dialog
                NPCSpeechBubble(
                    npcName: "Tavern Keeper Grothmund",
                    message: displayedObjective.npcDialog,
                    npcImageName: "shopkeeper",
                    messageId: displayedObjective.id
                )
                .padding(.horizontal, LayoutConstants.screenPadding)
                .opacity(npcAppeared ? 1 : 0)
                .offset(y: npcAppeared ? 0 : 12)

                Spacer(minLength: LayoutConstants.spaceSM)

                // Progress + CTA
                bottomSection
                    .opacity(ctaAppeared ? 1 : 0)
                    .offset(y: ctaAppeared ? 0 : 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Auto-scroll to current objective
            if let current = tutorial.currentFTUEObjective {
                selectedObjectiveIndex = current.index
            }
            animateEntrance()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            OrnamentalTitle("TUTORIAL", subtitle: nil, accentColor: DarkFantasyTheme.gold)

            // Level + XP bar
            if let character = appState.currentCharacter {
                HStack(spacing: LayoutConstants.spaceSM) {
                    Text("LEVEL: \(character.level)")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                        .tracking(1)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DarkFantasyTheme.bgTertiary)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(DarkFantasyTheme.xpGradient)
                                .frame(width: geo.size.width * xpFraction(character))
                                .overlay(BarFillHighlight(cornerRadius: 8))
                        }
                    }
                    .frame(height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DarkFantasyTheme.gold.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, LayoutConstants.screenPadding + LayoutConstants.spaceLG)
            }
        }
        .padding(.top, LayoutConstants.spaceXL)
    }

    private func xpFraction(_ character: Character) -> Double {
        // New characters start with 0 XP. Show a small sliver so the bar isn't empty.
        let xp = character.experience ?? 0
        guard xp > 0 else { return 0.05 }
        // Approximate XP to next level (level × 100 is the base formula)
        // Server-authoritative: this is only visual; actual XP displayed elsewhere
        let needed = max(1, character.level * 100)
        return min(1.0, max(0, Double(xp) / Double(needed)))
    }

    // MARK: - Cards Section

    @ViewBuilder
    private var cardsSection: some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            Text("OBJECTIVES")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(2)

            // Horizontal scrolling cards
            TabView(selection: $selectedObjectiveIndex) {
                ForEach(Array(FTUEObjective.allCases.enumerated()), id: \.element.id) { index, objective in
                    TutorialStepCard(
                        objective: objective,
                        state: tutorial.ftueState(for: objective),
                        onTap: {
                            navigateToObjective(objective)
                        }
                    )
                    .padding(.horizontal, LayoutConstants.spaceLG)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)
        }
    }

    // MARK: - Bottom Section (Progress + CTA)

    @ViewBuilder
    private var bottomSection: some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            // Progress diamonds
            progressIndicator

            // CTA Button
            if tutorial.ftueState(for: displayedObjective) != .locked {
                Button {
                    HapticManager.medium()
                    navigateToObjective(displayedObjective)
                } label: {
                    HStack(spacing: LayoutConstants.spaceSM) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                        Text(displayedObjective.ctaLabel)
                    }
                }
                .buttonStyle(.primary(enabled: true))
                .shimmer()
                .accessibilityLabel(displayedObjective.ctaLabel)
                .padding(.horizontal, LayoutConstants.screenPadding)
            }

            // Skip tutorial (subtle)
            Button {
                HapticManager.light()
                tutorial.dismissFTUE()
                appState.mainPath = NavigationPath()
            } label: {
                Text("Skip Tutorial")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textTertiary)
            }
            .buttonStyle(.ghost)
            .accessibilityLabel("Skip tutorial")
        }
        .padding(.bottom, LayoutConstants.spaceLG)
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private var progressIndicator: some View {
        VStack(spacing: 6) {
            Text("\(tutorial.ftueCompletedCount)/\(FTUEObjective.allCases.count) STEPS COMPLETE")
                .font(DarkFantasyTheme.section(size: LayoutConstants.textBody))
                .foregroundStyle(DarkFantasyTheme.textTertiary)
                .tracking(0.5)

            HStack(spacing: 8) {
                ForEach(FTUEObjective.allCases) { objective in
                    let state = tutorial.ftueState(for: objective)
                    diamondDot(state: state, isSelected: objective.index == selectedObjectiveIndex)
                }
            }
        }
    }

    @ViewBuilder
    private func diamondDot(state: FTUEObjectiveState, isSelected: Bool) -> some View {
        let color: Color = {
            switch state {
            case .completed: return DarkFantasyTheme.success
            case .current:   return DarkFantasyTheme.gold
            case .locked:    return DarkFantasyTheme.borderSubtle
            }
        }()

        Rectangle()
            .fill(state == .completed ? color : color.opacity(0.3))
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
            .overlay(
                Rectangle()
                    .stroke(color, lineWidth: 1)
                    .rotationEffect(.degrees(45))
            )
            .shadow(
                color: isSelected ? color.opacity(0.5) : Color.clear,
                radius: isSelected ? 4 : 0
            )
    }

    // MARK: - Navigation

    private func navigateToObjective(_ objective: FTUEObjective) {
        switch objective {
        case .firstBattle:
            appState.selectedTab = .arena
            appState.mainPath = NavigationPath()
        case .gearUp:
            appState.mainPath.append(AppRoute.shop)
        case .exploreDungeon:
            appState.mainPath.append(AppRoute.dungeonMap)
        }
    }

    // MARK: - Entrance Animation

    private func animateEntrance() {
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            headerAppeared = true
        }

        withAnimation(.easeOut(duration: MotionConstants.fast).delay(0.15)) {
            cardsAppeared = true
        }

        withAnimation(.easeOut(duration: MotionConstants.fast).delay(0.3)) {
            npcAppeared = true
        }

        withAnimation(.easeOut(duration: MotionConstants.fast).delay(0.5)) {
            ctaAppeared = true
        }
    }
}
