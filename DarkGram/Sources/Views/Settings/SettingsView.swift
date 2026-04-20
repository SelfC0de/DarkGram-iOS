import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tweaks: TweakSettings
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.bg.ignoresSafeArea()

                List {
                    // MARK: Privacy
                    Section {
                        TweakToggle(
                            icon: "eye.slash.fill",
                            title: "Ghost Mode",
                            subtitle: "Читай без отметки «прочитано»",
                            isOn: $tweaks.ghostMode
                        )

                        TweakToggle(
                            icon: "person.slash.fill",
                            title: "Скрыть онлайн-статус",
                            subtitle: "Не показывай «был(а) в сети»",
                            isOn: $tweaks.hideOnlineStatus
                        )
                    } header: {
                        sectionHeader("Приватность")
                    }
                    .listRowBackground(theme.colors.surface)

                    // MARK: Content
                    Section {
                        TweakToggle(
                            icon: "lock.open.fill",
                            title: "Защищённый контент",
                            subtitle: "Сохраняй и скриншоти защищённые сообщения",
                            isOn: $tweaks.allowProtectedContent
                        )

                        TweakToggle(
                            icon: "arrowshape.turn.up.right.fill",
                            title: "Пересылка без источника",
                            subtitle: "Скрывает «Переслано от» при пересылке",
                            isOn: $tweaks.forwardWithoutSource
                        )

                        TweakToggle(
                            icon: "megaphone.fill",
                            title: "Убрать рекламу в каналах",
                            subtitle: "Скрывает спонсорские сообщения",
                            isOn: $tweaks.hideChannelAds
                        )
                    } header: {
                        sectionHeader("Контент")
                    }
                    .listRowBackground(theme.colors.surface)

                    // MARK: Spam
                    Section {
                        TweakToggle(
                            icon: "shield.fill",
                            title: "Антиспам",
                            subtitle: "Скрывает сообщения со ссылками от незнакомцев",
                            isOn: $tweaks.antiSpamFilter
                        )
                    } header: {
                        sectionHeader("Безопасность")
                    }
                    .listRowBackground(theme.colors.surface)

                    // MARK: Theme
                    Section {
                        ForEach(DarkTheme.allCases) { t in
                            HStack {
                                Image(systemName: tweaks.selectedTheme == t ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(tweaks.selectedTheme == t ? theme.colors.accent : theme.colors.textSecondary)

                                Text(t.rawValue)
                                    .foregroundColor(theme.colors.text)

                                Spacer()

                                themePreview(t)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { tweaks.selectedTheme = t }
                        }
                    } header: {
                        sectionHeader("Тема")
                    }
                    .listRowBackground(theme.colors.surface)

                    // MARK: About
                    Section {
                        HStack {
                            Text("Версия")
                                .foregroundColor(theme.colors.textSecondary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(theme.colors.text)
                        }
                        HStack {
                            Text("База")
                                .foregroundColor(theme.colors.textSecondary)
                            Spacer()
                            Text("BetterTG / TDLibKit")
                                .foregroundColor(theme.colors.text)
                        }
                    } header: {
                        sectionHeader("О приложении")
                    }
                    .listRowBackground(theme.colors.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundColor(theme.colors.textSecondary)
            .textCase(nil)
    }

    private func themePreview(_ t: DarkTheme) -> some View {
        let c: ThemeColors
        switch t {
        case .ultraDark: c = .ultraDark
        case .midnight:  c = .midnight
        case .amoled:    c = .amoled
        }
        return HStack(spacing: 3) {
            Circle().fill(c.bg).frame(width: 12, height: 12)
            Circle().fill(c.accent).frame(width: 12, height: 12)
            Circle().fill(c.bubble).frame(width: 12, height: 12)
        }
    }
}

struct TweakToggle: View {
    @EnvironmentObject var theme: ThemeManager
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(theme.colors.text)
                    .font(.system(size: 15))
                Text(subtitle)
                    .foregroundColor(theme.colors.textSecondary)
                    .font(.system(size: 12))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(theme.colors.accent)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
