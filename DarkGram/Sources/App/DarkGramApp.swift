import SwiftUI
import TDLibKit

@main
struct DarkGramApp: App {
    @StateObject private var tdManager = TDManager.shared
    @StateObject private var tweaks    = TweakSettings.shared
    @StateObject private var theme     = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tdManager)
                .environmentObject(tweaks)
                .environmentObject(theme)
                .preferredColorScheme(.dark)
        }
    }
}
