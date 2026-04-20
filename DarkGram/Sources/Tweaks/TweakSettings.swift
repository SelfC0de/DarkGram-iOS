import Foundation
import Combine

final class TweakSettings: ObservableObject {
    static let shared = TweakSettings()

    // MARK: - Ghost Mode
    /// Не отправляет отметку "прочитано" серверу
    @Published var ghostMode: Bool {
        didSet { save("ghostMode", ghostMode) }
    }

    // MARK: - Online Status
    /// Скрывает статус "онлайн" и "был(а) в сети"
    @Published var hideOnlineStatus: Bool {
        didSet { save("hideOnlineStatus", hideOnlineStatus) }
    }

    // MARK: - Protected Content
    /// Разрешает скриншоты и сохранение защищённого контента
    @Published var allowProtectedContent: Bool {
        didSet { save("allowProtectedContent", allowProtectedContent) }
    }

    // MARK: - Forward Without Source
    /// Пересылка сообщений без указания источника
    @Published var forwardWithoutSource: Bool {
        didSet { save("forwardWithoutSource", forwardWithoutSource) }
    }

    // MARK: - Anti-Spam
    /// Фильтр: скрывать сообщения от незнакомцев с ссылками
    @Published var antiSpamFilter: Bool {
        didSet { save("antiSpamFilter", antiSpamFilter) }
    }

    // MARK: - No Channel Ads
    /// Скрывать спонсорские сообщения в каналах
    @Published var hideChannelAds: Bool {
        didSet { save("hideChannelAds", hideChannelAds) }
    }

    // MARK: - Theme
    @Published var selectedTheme: DarkTheme {
        didSet { save("selectedTheme", selectedTheme.rawValue) }
    }

    private init() {
        let ud = UserDefaults.standard
        ghostMode           = ud.bool(forKey: "ghostMode")
        hideOnlineStatus    = ud.bool(forKey: "hideOnlineStatus")
        allowProtectedContent = ud.bool(forKey: "allowProtectedContent")
        forwardWithoutSource = ud.bool(forKey: "forwardWithoutSource")
        antiSpamFilter      = ud.bool(forKey: "antiSpamFilter")
        hideChannelAds      = ud.bool(forKey: "hideChannelAds")
        selectedTheme       = DarkTheme(rawValue: ud.string(forKey: "selectedTheme") ?? "") ?? .ultraDark
    }

    private func save(_ key: String, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: key)
    }
    private func save(_ key: String, _ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

enum DarkTheme: String, CaseIterable, Identifiable {
    case ultraDark = "Ultra Dark"
    case midnight  = "Midnight"
    case amoled    = "AMOLED"

    var id: String { rawValue }
}
