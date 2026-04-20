import SwiftUI
import TDLibKit

struct ChatView: View {
    @EnvironmentObject var tdManager: TDManager
    @EnvironmentObject var tweaks: TweakSettings
    @EnvironmentObject var theme: ThemeManager

    let chat: Chat

    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var replyTo: Message?
    @State private var isLoading = true
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            theme.colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(messages, id: \.id) { msg in
                                MessageBubbleView(message: msg, chatId: chat.id)
                                    .id(msg.id)
                                    .onAppear {
                                        tdManager.markRead(chatId: chat.id, messageId: msg.id)
                                    }
                                    .contextMenu {
                                        messageContextMenu(msg)
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: messages.count) {
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Reply preview
                if let reply = replyTo {
                    replyPreview(reply)
                }

                Divider().background(theme.colors.separator)

                // Input bar
                inputBar
            }
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadMessages() }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Сообщение...", text: $inputText, axis: .vertical)
                .foregroundColor(theme.colors.text)
                .padding(10)
                .background(theme.colors.surface)
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($inputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? theme.colors.textSecondary : theme.colors.accent)
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.colors.bg)
    }

    // MARK: - Reply preview

    private func replyPreview(_ msg: Message) -> some View {
        HStack {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ответ")
                    .font(.caption)
                    .foregroundColor(theme.colors.accent)
                Text(replyText(msg))
                    .font(.caption)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button { replyTo = nil } label: {
                Image(systemName: "xmark")
                    .foregroundColor(theme.colors.textSecondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.colors.surface)
    }

    // MARK: - Context menu

    @ViewBuilder
    private func messageContextMenu(_ msg: Message) -> some View {
        Button {
            replyTo = msg
            inputFocused = true
        } label: {
            Label("Ответить", systemImage: "arrowshape.turn.up.left")
        }

        Button {
            copyMessage(msg)
        } label: {
            Label("Копировать", systemImage: "doc.on.doc")
        }

        if tweaks.forwardWithoutSource {
            Button {
                // forward without source — handled in ForwardSheet
            } label: {
                Label("Переслать (без источника)", systemImage: "arrowshape.turn.up.right")
            }
        } else {
            Button {
            } label: {
                Label("Переслать", systemImage: "arrowshape.turn.up.right")
            }
        }

        // Сохранить защищённый контент
        if tweaks.allowProtectedContent {
            if case .messagePhoto = msg.content {
                Button {
                    saveProtectedContent(msg)
                } label: {
                    Label("Сохранить", systemImage: "square.and.arrow.down")
                }
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task {
            try? await tdManager.send(
                text: text,
                chatId: chat.id,
                replyToId: replyTo?.id
            )
            replyTo = nil
        }
    }

    private func loadMessages() async {
        let msgs = (try? await tdManager.loadMessages(chatId: chat.id)) ?? []
        await MainActor.run {
            messages = msgs.reversed()
            isLoading = false
        }
    }

    private func copyMessage(_ msg: Message) {
        if case .messageText(let t) = msg.content {
            UIPasteboard.general.string = t.text.text
        }
    }

    private func saveProtectedContent(_ msg: Message) {
        // TDLib: downloadFile → save to Photos
    }

    private func replyText(_ msg: Message) -> String {
        switch msg.content {
        case .messageText(let t): return t.text.text
        case .messagePhoto:       return "Фото"
        case .messageVideo:       return "Видео"
        default:                  return "Сообщение"
        }
    }
}
