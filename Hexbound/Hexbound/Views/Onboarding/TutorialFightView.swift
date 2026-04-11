import SwiftUI

/// W2.D3 — Scripted first fight.
///
/// Self-contained, isolated from the real PvP/PvE combat system so we don't
/// accidentally corrupt live game state during onboarding. The fight is
/// resolved server-side with a fixed seed guaranteeing hero victory.
///
/// Flow:
///   1. `onAppear` → `TutorialService.preloadScriptedFight` (fetches hero + opponent)
///   2. User sees pre-fight preview (hero card vs opponent card)
///   3. User taps FIGHT → `TutorialService.resolveScriptedFight` (server runs combat, grants rewards)
///   4. On success → navigate to `.tutorialVictory(heroName:)` — VictoryOverlayView handles reward reveal
///
/// Scope compromise: we do NOT play the full combat replay animation in MVP —
/// the existing `CombatViewModel` + `CombatDetailView` are tightly coupled to
/// live-game data flow. Rather than invasively threading `tutorialMode` through
/// both, the scripted tutorial uses a simplified "pre-fight → server-side resolve
/// → victory overlay" loop. Adding full replay is a polish-pass task tracked
/// in the W2.D3 design doc.
///
/// See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
struct TutorialFightView: View {
    let heroName: String

    @Environment(AppState.self) private var appState
    @State private var vm: TutorialFightViewModel?

    var body: some View {
        ZStack {
            // Arena backdrop
            Image("bg-arena")
                .resizable()
                .scaledToFill()
                .opacity(0.45)
                .ignoresSafeArea()
            DarkFantasyTheme.bgBackdrop
                .ignoresSafeArea()

            if let vm {
                content(for: vm)
            } else {
                LoadingOverlay()
            }
        }
        .task {
            if vm == nil {
                let newVM = TutorialFightViewModel(appState: appState)
                vm = newVM
                await newVM.preload()
            }
        }
    }

    // MARK: - Content States

    @ViewBuilder
    private func content(for vm: TutorialFightViewModel) -> some View {
        switch vm.state {
        case .loading:
            LoadingOverlay()

        case .ready:
            preFightPanel(vm: vm)

        case .resolving:
            VStack(spacing: LayoutConstants.spaceMD) {
                Spacer()
                HexPulseLoader(.compact)
                Text("RESOLVING...")
                    .font(DarkFantasyTheme.section)
                    .foregroundStyle(DarkFantasyTheme.gold)
                Spacer()
            }

        case .error(let message):
            errorPanel(message: message, vm: vm)
        }
    }

    // MARK: - Pre-Fight Panel

    private func preFightPanel(vm: TutorialFightViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceLG) {
            OrnamentalTitle("FIRST BLOOD", accentColor: DarkFantasyTheme.danger)
                .padding(.top, LayoutConstants.spaceMD)

            Spacer(minLength: 0)

            // VS layout — hero left, opponent right
            HStack(spacing: LayoutConstants.spaceMD) {
                fighterCard(
                    name: heroName,
                    subtitle: (vm.heroClass ?? "hero").capitalized,
                    hp: vm.heroMaxHp,
                    accent: DarkFantasyTheme.gold,
                )

                Text("VS")
                    .font(DarkFantasyTheme.title)
                    .foregroundStyle(DarkFantasyTheme.danger)

                fighterCard(
                    name: vm.opponentName ?? "Grunt",
                    subtitle: "Orc",
                    hp: vm.opponentMaxHp,
                    accent: DarkFantasyTheme.danger,
                )
            }
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Hint copy — single line, no lore
            Text("Tap FIGHT to end him.")
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textSecondary)
                .padding(.top, LayoutConstants.spaceSM)

            Spacer(minLength: 0)

            // FIGHT CTA — full-width gold primary
            Button {
                Task { await vm.resolve(heroName: heroName) }
            } label: {
                Text("FIGHT")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, LayoutConstants.screenPadding)

            // Skip button — tiny, requires confirmation
            Button {
                vm.requestSkipConfirmation()
            } label: {
                Text("Skip tutorial")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .padding(.bottom, LayoutConstants.spaceMD)
        }
        .confirmationDialog(
            "Skip the tutorial?",
            isPresented: Binding(
                get: { vm.showSkipConfirmation },
                set: { vm.showSkipConfirmation = $0 },
            ),
            titleVisibility: .visible,
        ) {
            Button("Skip and go to Hub", role: .destructive) {
                Task { await vm.skipToHub() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll miss 150 gold, 50 XP, and a starter weapon. Proceed?")
        }
    }

    private func fighterCard(
        name: String,
        subtitle: String,
        hp: Int,
        accent: Color,
    ) -> some View {
        VStack(spacing: LayoutConstants.spaceXS) {
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(Color.black.opacity(0.55))
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                        .stroke(accent.opacity(0.7), lineWidth: 2),
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(accent.opacity(0.6)),
                )

            Text(name)
                .font(DarkFantasyTheme.cardTitle)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .lineLimit(1)

            Text(subtitle)
                .font(DarkFantasyTheme.caption)
                .foregroundStyle(DarkFantasyTheme.textSecondary)

            Text("\(hp) HP")
                .font(DarkFantasyTheme.badge)
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error Panel

    private func errorPanel(message: String, vm: TutorialFightViewModel) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DarkFantasyTheme.danger)
            Text(message)
                .font(DarkFantasyTheme.body)
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LayoutConstants.screenPadding)

            Button {
                Task { await vm.preload() }
            } label: {
                Text("RETRY")
            }
            .buttonStyle(.secondary)

            Button {
                Task { await vm.skipToHub() }
            } label: {
                Text("Skip to Hub")
                    .font(DarkFantasyTheme.caption)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            Spacer()
        }
    }
}
