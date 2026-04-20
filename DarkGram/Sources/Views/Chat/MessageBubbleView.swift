import SwiftUI
import TDLibKit

struct MessageBubbleView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var tweaks: TweakSettings

    let message: Message
    let chatId: Int64

    private var isOwn: Bool { message.isOutgoing }

    var body: some View {
        HStack {
            if isOwn { Spacer(minLength: 60) }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 2) {
                bubbleContent
                    .background(isOwn ? theme.colors.bubbleOwn : theme.colors.bubble)
                    .cornerRadius(16, corners: isOwn
                        ? [.topLeft, .bottomLeft, .topRight]
                        : [.topRight, .bottomRight, .topLeft]
                    )

                // Time + read status
                HStack(spacing: 4) {
                    Text(formatTime(message.date))
                        .font(.system(size: 10))
                        .foregroundColor(theme.colors.textSecondary)

                    if isOwn {
                        readStatusIcon
                    }
                }
                .padding(.horizontal, 4)
            }

            if !isOwn { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Bubble content

    @ViewBuilder
    private var bubbleContent: some View {
        switch message.content {
        case .messageText(let t):
            textBubble(t.text.text)
        case .messagePhoto:
            photoBubble
        case .messageVoiceNote:
            voiceBubble
        case .messageSticker(let s):
            stickerBubble(s)
        default:
            textBubble("Сообщение")
        }
    }

    private func textBubble(_ text: String) -> some View {
        // Anti-spam filter
        let display: String = {
            if tweaks.antiSpamFilter && !message.isOutgoing {
                let spamPhrases = ["http://", "https://", "bit.ly", "tinyurl", "t.me/joinchat"]
                if spamPhrases.contains(where: { text.lowercased().contains($0) }) {
                    return "⚠️ [Сообщение скрыто фильтром спама]"
                }
            }
            // Hide sponsored/ad messages in channels
            if tweaks.hideChannelAds, text.contains("Sponsored") || text.contains("спонсор") {
                return ""
            }
            return text
        }()

        return Text(display.isEmpty ? "" : display)
            .font(.system(size: 15))
            .foregroundColor(theme.colors.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var photoBubble: some View {
        Image(systemName: "photo")
            .font(.system(size: 48))
            .foregroundColor(theme.colors.textSecondary)
            .padding(16)
    }

    private var voiceBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .foregroundColor(theme.colors.accent)
            Text("Голосовое")
                .font(.system(size: 14))
                .foregroundColor(theme.colors.text)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func stickerBubble(_ sticker: MessageSticker) -> some View {
        Text("🎭")
            .font(.system(size: 48))
            .padding(8)
    }

    // MARK: - Read status

    @ViewBuilder
    private var readStatusIcon: some View {
        // Ghost mode: не показываем реальный статус отправки
        if tweaks.ghostMode {
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundColor(theme.colors.textSecondary)
        } else {
            Image(systemName: "checkmark")
                .font(.system(size: 10))
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ ts: Int) -> String {
        Date(timeIntervalSince1970: TimeInterval(ts))
            .formatted(.dateTime.hour().minute())
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
