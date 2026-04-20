import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var colors: ThemeColors = .ultraDark

    private var cancellable: AnyCancellable?

    private init() {
        apply(TweakSettings.shared.selectedTheme)
        cancellable = TweakSettings.shared.$selectedTheme
            .sink { [weak self] theme in self?.apply(theme) }
    }

    private func apply(_ theme: DarkTheme) {
        switch theme {
        case .ultraDark: colors = .ultraDark
        case .midnight:  colors = .midnight
        case .amoled:    colors = .amoled
        }
    }
}

struct ThemeColors {
    let bg:           Color
    let surface:      Color
    let surfaceHigh:  Color
    let accent:       Color
    let text:         Color
    let textSecondary:Color
    let bubble:       Color
    let bubbleOwn:    Color
    let separator:    Color

    static let ultraDark = ThemeColors(
        bg:            Color(hex: "#0a0a0f"),
        surface:       Color(hex: "#111118"),
        surfaceHigh:   Color(hex: "#1a1a24"),
        accent:        Color(hex: "#5b7fff"),
        text:          Color(hex: "#e8e8f0"),
        textSecondary: Color(hex: "#6b6b80"),
        bubble:        Color(hex: "#1e1e2e"),
        bubbleOwn:     Color(hex: "#2a3a6b"),
        separator:     Color(hex: "#1c1c28")
    )

    static let midnight = ThemeColors(
        bg:            Color(hex: "#0d0d14"),
        surface:       Color(hex: "#141420"),
        surfaceHigh:   Color(hex: "#1e1e2e"),
        accent:        Color(hex: "#7b5ea7"),
        text:          Color(hex: "#dcdce8"),
        textSecondary: Color(hex: "#666678"),
        bubble:        Color(hex: "#1a1a2a"),
        bubbleOwn:     Color(hex: "#2d2050"),
        separator:     Color(hex: "#1a1a26")
    )

    static let amoled = ThemeColors(
        bg:            Color(hex: "#000000"),
        surface:       Color(hex: "#0a0a0a"),
        surfaceHigh:   Color(hex: "#111111"),
        accent:        Color(hex: "#00c8ff"),
        text:          Color(hex: "#ffffff"),
        textSecondary: Color(hex: "#606060"),
        bubble:        Color(hex: "#111111"),
        bubbleOwn:     Color(hex: "#003344"),
        separator:     Color(hex: "#1a1a1a")
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
