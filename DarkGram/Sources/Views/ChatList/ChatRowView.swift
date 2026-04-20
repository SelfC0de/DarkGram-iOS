import SwiftUI
import TDLibKit

struct ChatRowView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var tweaks: TweakSettings
    let chat: Chat

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ChatAvatarView(chat: chat)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(chat.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.colors.text)
                        .lineLimit(1)

                    Spacer()

                    if let msg = chat.lastMessage {
                        Text(formatDate(msg.date))
                            .font(.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                HStack {
                    Text(lastMessageText)
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    // Unread badge
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.colors.bg)
    }

    private var lastMessageText: String {
        guard let msg = chat.lastMessage else { return "" }
        switch msg.content {
        case .messageText(let t):
            // Фильтр спама
            if tweaks.antiSpamFilter, containsSpamLink(t.text.text) {
                return "⚠️ Возможный спам"
            }
            return t.text.text
        case .messagePhoto:       return "📷 Фото"
        case .messageVideo:       return "🎥 Видео"
        case .messageVoiceNote:   return "🎤 Голосовое"
        case .messageDocument:    return "📎 Файл"
        case .messageSticker:     return "🎭 Стикер"
        default:                  return "Сообщение"
        }
    }

    private func containsSpamLink(_ text: String) -> Bool {
        let patterns = ["http://", "https://", "t.me/", "bit.ly", "tinyurl"]
        return patterns.contains(where: { text.lowercased().contains($0) })
    }

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let cal  = Calendar.current
        if cal.isDateInToday(date) {
            return date.formatted(.dateTime.hour().minute())
        } else if cal.isDateInYesterday(date) {
            return "вчера"
        } else {
            return date.formatted(.dateTime.day().month())
        }
    }
}
