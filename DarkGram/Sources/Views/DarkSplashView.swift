import SwiftUI

struct DarkSplashView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            theme.colors.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundColor(theme.colors.accent)
                Text("DarkGram+")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.colors.text)
                ProgressView()
                    .tint(theme.colors.accent)
            }
        }
    }
}
