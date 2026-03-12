import SwiftUI

struct DailyLoginPopupView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DailyLoginPopupViewModel?
    @State private var appear = false

    var body: some View {
        ZStack {
            // Backdrop
            DarkFantasyTheme.bgModal
                .ignoresSafeArea()
                .opacity(appear ? 1 : 0)
                .onTapGesture {
                    dismissPopup()
                }

            if let vm = viewModel, !vm.isLoading, let data = vm.loginData {
                VStack(spacing: 0) {
                    // Title
                    Text("DAILY LOGIN")
                        .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                        .padding(.top, LayoutConstants.spaceLG)

                    // Streak subtitle
                    Text("Day \(data.streak) Streak! \u{1F525}")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .padding(.top, LayoutConstants.spaceXS)

                    // Day circles row (Days 1-6)
                    HStack(spacing: 0) {
                        ForEach(DailyReward.rewards.prefix(6), id: \.day) { reward in
                            dayCircle(reward: reward, data: data)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.spaceSM)
                    .padding(.top, LayoutConstants.spaceMD)

                    // Day 7 centered
                    if let day7 = DailyReward.rewards.last, day7.day == 7 {
                        dayCircle(reward: day7, data: data)
                            .padding(.top, LayoutConstants.spaceXS)
                    }

                    // Today's Reward Card
                    todayRewardCard(data: data)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.top, LayoutConstants.spaceMD)

                    // Claim Button
                    Button {
                        Task { await vm.claimReward() }
                    } label: {
                        if vm.isClaiming {
                            ProgressView()
                                .tint(DarkFantasyTheme.textOnGold)
                        } else {
                            Text(vm.hasClaimed ? "ALREADY CLAIMED" : "CLAIM REWARD")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(vm.hasClaimed || vm.isClaiming)
                    .padding(.horizontal, LayoutConstants.spaceMD)
                    .padding(.top, LayoutConstants.spaceMD)
                    .padding(.bottom, LayoutConstants.spaceLG)
                }
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .fill(DarkFantasyTheme.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                        .stroke(DarkFantasyTheme.gold.opacity(0.6), lineWidth: 1.5)
                )
                .padding(.horizontal, LayoutConstants.spaceLG)
                .scaleEffect(appear ? 1 : 0.9)
                .opacity(appear ? 1 : 0)
                .transition(.identity)
            }
        }
        .onAppear {
            let vm = DailyLoginPopupViewModel(appState: appState)
            viewModel = vm
            Task {
                await vm.loadData()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    appear = true
                }
            }
        }
    }

    // MARK: - Day Circle

    @ViewBuilder
    private func dayCircle(reward: DailyReward, data: DailyLoginData) -> some View {
        let isCurrentDay = reward.day == data.currentDay && data.canClaim
        let isClaimed = reward.day < data.currentDay || (reward.day == data.currentDay && !data.canClaim)
        let isDay7 = reward.day == 7
        let circleSize: CGFloat = isDay7 ? 54 : 46

        VStack(spacing: 4) {
            ZStack {
                // Background fill
                Circle()
                    .fill(
                        isClaimed ? Color(red: 0.55, green: 0.42, blue: 0.2).opacity(0.6) :
                        isCurrentDay ? DarkFantasyTheme.bgTertiary :
                        DarkFantasyTheme.bgTertiary.opacity(0.4)
                    )
                    .frame(width: circleSize, height: circleSize)

                // Border
                Circle()
                    .stroke(
                        isClaimed ? DarkFantasyTheme.gold :
                        isCurrentDay ? DarkFantasyTheme.goldBright :
                        isDay7 ? DarkFantasyTheme.gold.opacity(0.5) :
                        DarkFantasyTheme.borderSubtle.opacity(0.3),
                        lineWidth: isCurrentDay ? 2.5 : isClaimed ? 2 : 1
                    )
                    .frame(width: circleSize, height: circleSize)

                // Icon
                Text(reward.icon)
                    .font(.system(size: isDay7 ? 24 : 18))
                    .opacity(isClaimed || isCurrentDay ? 1.0 : 0.35)
            }

            Text("Day \(reward.day)")
                .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                .foregroundStyle(
                    isCurrentDay ? DarkFantasyTheme.textPrimary :
                    isClaimed ? DarkFantasyTheme.textSecondary :
                    DarkFantasyTheme.textDisabled
                )
        }
    }

    // MARK: - Today's Reward Card

    @ViewBuilder
    private func todayRewardCard(data: DailyLoginData) -> some View {
        if let reward = DailyReward.rewards.first(where: { $0.day == data.currentDay }) {
            VStack(spacing: LayoutConstants.spaceXS) {
                Text(reward.icon)
                    .font(.system(size: 32))

                Text(reward.label.uppercased())
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel).bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("Today's Reward")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceMD)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgTertiary.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.borderSubtle.opacity(0.4), lineWidth: 1)
            )
        }
    }

    private func dismissPopup() {
        withAnimation(.easeOut(duration: 0.2)) {
            appear = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            viewModel?.dismiss()
        }
    }
}
