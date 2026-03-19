import SwiftUI

struct SettingsDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: SettingsViewModel?
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var deleteConfirmText = ""

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            if let vm {
                ScrollView {
                    VStack(spacing: LayoutConstants.spaceLG) {
                        audioSection(vm: vm)
                        notificationsSection(vm: vm)
                        languageSection(vm: vm)
                        accountSection(vm: vm)
                        #if DEBUG
                        devToolsSection
                        #endif
                        versionLabel
                    }
                    .padding(.horizontal, LayoutConstants.screenPadding)
                    .padding(.vertical, LayoutConstants.spaceMD)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("SETTINGS")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
        }
        .onAppear {
            if vm == nil { vm = SettingsViewModel(appState: appState) }
        }
    }

    // MARK: - Audio

    @ViewBuilder
    private func audioSection(vm: SettingsViewModel) -> some View {
        settingsCard {
            sectionHeader("Audio")

            toggleRow("Sound Effects", isOn: Binding(
                get: { vm.soundEnabled },
                set: { vm.soundEnabled = $0 }
            ))

            toggleRow("Music", isOn: Binding(
                get: { vm.musicEnabled },
                set: { vm.musicEnabled = $0 }
            ))

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("Music Volume")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Slider(
                        value: Binding(
                            get: { vm.bgmVolume },
                            set: { vm.bgmVolume = $0 }
                        ),
                        in: 0...100
                    )
                    .tint(DarkFantasyTheme.gold)

                    Text("\(Int(vm.bgmVolume))%")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 40)
                }
            }

            VStack(alignment: .leading, spacing: LayoutConstants.spaceXS) {
                Text("SFX Volume")
                    .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                    .foregroundStyle(DarkFantasyTheme.textPrimary)

                HStack(spacing: LayoutConstants.spaceSM) {
                    Slider(
                        value: Binding(
                            get: { vm.sfxVolume },
                            set: { vm.sfxVolume = $0 }
                        ),
                        in: 0...100
                    )
                    .tint(DarkFantasyTheme.gold)

                    Text("\(Int(vm.sfxVolume))%")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                        .frame(width: 40)
                }
            }
        }
    }

    // MARK: - Notifications

    @ViewBuilder
    private func notificationsSection(vm: SettingsViewModel) -> some View {
        settingsCard {
            sectionHeader("Notifications")

            toggleRow("Push Notifications", isOn: Binding(
                get: { vm.pushNotifications },
                set: { vm.pushNotifications = $0 }
            ))
        }
    }

    // MARK: - Language

    @ViewBuilder
    private func languageSection(vm: SettingsViewModel) -> some View {
        settingsCard {
            sectionHeader("Language")

            Menu {
                ForEach(0..<SettingsViewModel.languageNames.count, id: \.self) { index in
                    Button(SettingsViewModel.languageNames[index]) {
                        vm.selectedLanguageIndex = index
                    }
                }
            } label: {
                HStack {
                    Text(SettingsViewModel.languageNames[vm.selectedLanguageIndex])
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(DarkFantasyTheme.textSecondary)
                }
                .padding(.horizontal, LayoutConstants.spaceSM)
                .frame(height: LayoutConstants.buttonHeightMD)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.inputRadius)
                        .fill(DarkFantasyTheme.bgTertiary)
                )
            }
        }
    }

    // MARK: - Account

    @ViewBuilder
    private func accountSection(vm: SettingsViewModel) -> some View {
        settingsCard {
            sectionHeader("Account")

            // Link Account
            Button {
                vm.linkAccount()
            } label: {
                Text(vm.linkAccountMessage ?? "Link Account")
            }
            .buttonStyle(.neutral)
            .disabled(vm.linkAccountMessage != nil)

            // Logout — with confirmation
            Button {
                showLogoutConfirm = true
            } label: {
                Text("Logout")
            }
            .buttonStyle(.dangerOutline)
            .alert("Logout", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) { vm.logout() }
            } message: {
                Text("Are you sure you want to log out?")
            }

            // Delete Account — App Store requirement
            Button {
                showDeleteConfirm = true
            } label: {
                Text("Delete Account")
            }
            .buttonStyle(.ghost)
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                TextField("Type DELETE to confirm", text: $deleteConfirmText)
                Button("Cancel", role: .cancel) { deleteConfirmText = "" }
                Button("Delete Forever", role: .destructive) {
                    if deleteConfirmText == "DELETE" {
                        Task { await vm.deleteAccount() }
                    }
                    deleteConfirmText = ""
                }
            } message: {
                Text("This will permanently delete your account and all game data. This action cannot be undone. Type DELETE to confirm.")
            }
        }
    }

    // MARK: - Dev Tools

    #if DEBUG
    private var devToolsSection: some View {
        settingsCard {
            sectionHeader("Developer Tools")

            Button {
                appState.mainPath.append(AppRoute.screenCatalog)
            } label: {
                HStack {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text("Screen Catalog")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .frame(height: LayoutConstants.buttonHeightMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.97))

            Button {
                appState.mainPath.append(AppRoute.hubEditor)
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Text("Hub Map Editor")
                        .font(DarkFantasyTheme.body(size: LayoutConstants.textBody))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DarkFantasyTheme.textTertiary)
                }
                .frame(height: LayoutConstants.buttonHeightMD)
                .contentShape(Rectangle())
            }
            .buttonStyle(.scalePress(0.97))
        }
    }
    #endif

    // MARK: - Version

    private var versionLabel: some View {
        Text("Hexbound v1.0.0")
            .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
            .foregroundStyle(DarkFantasyTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, LayoutConstants.spaceSM)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LayoutConstants.spaceSM) {
            content()
        }
        .padding(LayoutConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardRadius)
                .fill(DarkFantasyTheme.bgSecondary)
        )
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DarkFantasyTheme.section(size: LayoutConstants.textCard))
            .foregroundStyle(DarkFantasyTheme.gold)
    }

    @ViewBuilder
    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(DarkFantasyTheme.body(size: LayoutConstants.textLabel))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
        }
        .tint(DarkFantasyTheme.gold)
    }
}
