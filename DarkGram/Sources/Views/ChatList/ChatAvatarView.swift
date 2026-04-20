import SwiftUI
import TDLibKit

struct ChatAvatarView: View {
    @EnvironmentObject var theme: ThemeManager
    let chat: Chat

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor(for: chat.id))

            Text(initials)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
        .clipShape(Circle())
    }

    private var initials: String {
        let words = chat.title.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        }
        return String(chat.title.prefix(2)).uppercased()
    }

    private func avatarColor(for id: Int64) -> Color {
        let colors: [Color] = [
            Color(hex: "#e17055"), Color(hex: "#6c5ce7"),
            Color(hex: "#00b894"), Color(hex: "#0984e3"),
            Color(hex: "#e84393"), Color(hex: "#fd79a8"),
            Color(hex: "#a29bfe"), Color(hex: "#55efc4"),
        ]
        let index = Int(abs(id) % Int64(colors.count))
        return colors[index]
    }
}
