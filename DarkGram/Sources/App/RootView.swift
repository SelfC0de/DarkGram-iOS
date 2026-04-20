import SwiftUI

struct RootView: View {
    @EnvironmentObject var tdManager: TDManager

    var body: some View {
        Group {
            switch tdManager.authState {
            case .waitPhoneNumber, .waitCode, .waitPassword:
                AuthView()
            case .ready:
                ChatListView()
            default:
                DarkSplashView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tdManager.authState)
    }
}
