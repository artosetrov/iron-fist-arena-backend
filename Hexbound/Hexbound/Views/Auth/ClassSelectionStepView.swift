import SwiftUI

/// Onboarding Step 1: Class selection with showcase + carousel.
struct ClassSelectionStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("CHOOSE A CLASS")
                .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .padding(.top, LayoutConstants.spaceLG)

            if let selectedClass = vm.selectedClass {
                classShowcase(selectedClass)
                    .padding(.top, LayoutConstants.spaceMD)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { value in
                                if value.translation.width < -40 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vm.selectNextClass()
                                    }
                                } else if value.translation.width > 40 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vm.selectPreviousClass()
                                    }
                                }
                            }
                    )

                Spacer(minLength: LayoutConstants.spaceMD)

                classCarousel
                    .padding(.bottom, LayoutConstants.spaceLG + LayoutConstants.spaceMD)
            }
        }
    }

    // MARK: - Class Showcase

    @ViewBuilder
    private func classShowcase(_ charClass: CharacterClass) -> some View {
        VStack(spacing: LayoutConstants.spaceMD) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                DarkFantasyTheme.classColor(for: charClass).opacity(0.2),
                                DarkFantasyTheme.bgSecondary.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(height: 340)

                Image(charClass.iconAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 256, height: 256)
                    .shadow(color: DarkFantasyTheme.classColor(for: charClass).opacity(0.5), radius: 20)
            }

            VStack(spacing: LayoutConstants.spaceSM) {
                Text(charClass.sfName)
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textScreen))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: 4) {
                    Text("MAIN ATTRIBUTE")
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text("–")
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                    Text(charClass.mainAttribute)
                        .font(DarkFantasyTheme.section(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.goldBright)
                }

                Text(charClass.mainAttributeDescription)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .multilineTextAlignment(.center)

                Text(charClass.bonuses)
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textCaption))
                    .foregroundStyle(DarkFantasyTheme.textSuccess)
                    .padding(.top, 2)
            }
            .padding(.horizontal, LayoutConstants.screenPadding)
        }
    }

    // MARK: - Class Carousel

    private var classCarousel: some View {
        HStack(spacing: LayoutConstants.spaceSM) {
            Button { vm.selectPreviousClass() } label: {
                Image("ui-arrow-left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 36, height: 36)
            }

            HStack(spacing: LayoutConstants.spaceSM) {
                ForEach(Array(CharacterClass.allCases.enumerated()), id: \.element.id) { index, charClass in
                    classMedallion(charClass, isSelected: vm.selectedClass == charClass)
                        .onTapGesture {
                            vm.selectClass(at: index)
                        }
                }
            }

            Button { vm.selectNextClass() } label: {
                Image("ui-arrow-right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
    }

    // MARK: - Class Medallion

    @ViewBuilder
    private func classMedallion(_ charClass: CharacterClass, isSelected: Bool) -> some View {
        let color = DarkFantasyTheme.classColor(for: charClass)

        ZStack {
            Circle()
                .fill(isSelected ? color.opacity(0.2) : DarkFantasyTheme.bgSecondary)
                .frame(width: 56, height: 56)

            Circle()
                .stroke(isSelected ? color : DarkFantasyTheme.borderSubtle, lineWidth: isSelected ? 2.5 : 1)
                .frame(width: 56, height: 56)

            Image(charClass.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        }
        .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
