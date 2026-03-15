import SwiftUI

struct DailyLoginDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: DailyLoginPopupViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                if vm.isLoading {
                    ProgressView()
                        .tint(DarkFantasyTheme.gold)
                } else if let data = vm.loginData {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Streak subtitle
                            Text("Day \(data.streak) Streak! \u{1F525}")
                                .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                                .foregroundStyle(DarkFantasyTheme.textSecondary)
                                .padding(.top, LayoutConstants.spaceMD)

                            // Day circles row (Days 1-6)
                            HStack(spacing: 0) {
                                ForEach(DailyReward.rewards.prefix(6), id: \.day) { reward in
                                    dayCircle(reward: reward, data: data)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, LayoutConstants.screenPadding)
                            .padding(.top, LayoutConstants.spaceLG)

                            // Day 7 centered
                            if let day7 = DailyReward.rewards.last, day7.day == 7 {
                                dayCircle(reward: day7, data: data)
                                    .padding(.top, LayoutConstants.spaceSM)
                            }

                            // Today's Reward Card
                            todayRewardCard(data: data)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)

                            // Claim Button
                            if vm.hasClaimed {
                                Button {
                                    appState.mainPath.removeLast()
                                } label: {
                                    Text("CLAIMED")
                                }
                                .buttonStyle(.primary)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)
                                .padding(.bottom, LayoutConstants.space2XL)
                            } else {
                                Button {
                                    Task { await vm.claimReward() }
                                } label: {
                                    if vm.isClaiming {
                                        ProgressView()
                                            .tint(DarkFantasyTheme.textOnGold)
                                    } else {
                                        Text("CLAIM REWARD")
                                    }
                                }
                                .buttonStyle(.primary)
                                .disabled(vm.isClaiming)
                                .padding(.horizontal, LayoutConstants.screenPadding)
                                .padding(.top, LayoutConstants.spaceLG)
                                .padding(.bottom, LayoutConstants.space2XL)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("DAILY LOGIN")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .task {
            if vm == nil {
                let viewModel = DailyLoginPopupViewModel(appState: appState)
                vm = viewModel
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Day Circle

    @ViewBuilder
    private func dayCircle(reward: DailyReward, data: DailyLoginData) -> some View {
        let isCurrentDay = reward.day == data.currentDay && data.canClaim
        let isClaimed = reward.day < data.currentDay || (reward.day == data.currentDay && !data.canClaim)
        let isDay7 = reward.day == 7
        let circleSize: CGFloat = isDay7 ? 58 : 48

        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        isClaimed ? DarkFantasyTheme.goldDim.opacity(0.6) :
                        isCurrentDay ? DarkFantasyTheme.bgTertiary :
                        DarkFantasyTheme.bgTertiary.opacity(0.4)
                    )
                    .frame(width: circleSize, height: circleSize)

                Circle()
                    .stroke(
                        isClaimed ? DarkFantasyTheme.gold :
                        isCurrentDay ? DarkFantasyTheme.goldBright :
                        isDay7 ? DarkFantasyTheme.gold.opacity(0.5) :
                        DarkFantasyTheme.borderSubtle.opacity(0.3),
                        lineWidth: isCurrentDay ? 2.5 : isClaimed ? 2 : 1
                    )
                    .frame(width: circleSize, height: circleSize)

                Text(reward.icon)
                    .font(.system(size: isDay7 ? 26 : 20)) // emoji text — keep as is
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
            VStack(spacing: LayoutConstants.spaceSM) {
                Text(reward.icon)
                    .font(.system(size: 40)) // emoji text — keep as is

                Text(reward.label.uppercased())
                    .font(DarkFantasyTheme.section(size: LayoutConstants.textBody).bold())
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                Text("Today's Reward")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LayoutConstants.spaceLG)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .fill(DarkFantasyTheme.bgSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.panelRadius)
                    .stroke(DarkFantasyTheme.gold.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
