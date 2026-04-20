import Foundation
import TDLibKit
import Combine

enum AuthState: Equatable {
    case idle, waitPhoneNumber, waitCode, waitPassword, ready, error(String)
}

final class TDManager: ObservableObject {
    static let shared = TDManager()

    @Published var authState: AuthState = .idle
    @Published var chats: [Chat] = []

    private let api: TdApi
    private var cancellables = Set<AnyCancellable>()

    private init() {
        api = TdApi(client: TdClientImpl())
        configure()
        startUpdateLoop()
    }

    // MARK: - Configure

    private func configure() {
        Task {
            _ = try? await api.setTdlibParameters(
                databaseDirectory: dbPath(),
                databaseEncryptionKey: nil,
                filesDirectory: filesPath(),
                useFileDatabase: true,
                useChatInfoDatabase: true,
                useMessageDatabase: true,
                useSecretChats: true,
                apiId: TELEGRAM_API_ID,
                apiHash: TELEGRAM_API_HASH,
                systemLanguageCode: Locale.current.language.languageCode?.identifier ?? "en",
                deviceModel: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion,
                applicationVersion: "1.0"
            )
        }
    }

    // MARK: - Update loop

    private func startUpdateLoop() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            while true {
                guard let update = try? await self.api.getUpdate() else { continue }
                await self.handle(update: update)
            }
        }
    }

    @MainActor
    private func handle(update: Update) {
        switch update {
        case .updateAuthorizationState(let s):
            handleAuth(state: s.authorizationState)
        case .updateNewChat(let u):
            if !chats.contains(where: { $0.id == u.chat.id }) {
                chats.append(u.chat)
            }
        case .updateChatLastMessage(let u):
            if let i = chats.firstIndex(where: { $0.id == u.chatId }) {
                chats[i] = Chat(
                    id: chats[i].id,
                    type: chats[i].type,
                    title: chats[i].title,
                    photo: chats[i].photo,
                    lastMessage: u.lastMessage,
                    positions: u.positions,
                    messageSenderId: chats[i].messageSenderId,
                    blockList: chats[i].blockList,
                    hasProtectedContent: chats[i].hasProtectedContent,
                    isTranslatable: chats[i].isTranslatable,
                    isMarkedAsUnread: chats[i].isMarkedAsUnread,
                    viewAsTopics: chats[i].viewAsTopics,
                    hasScheduledMessages: chats[i].hasScheduledMessages,
                    canBeDeletedOnlyForSelf: chats[i].canBeDeletedOnlyForSelf,
                    canBeDeletedForAllUsers: chats[i].canBeDeletedForAllUsers,
                    canBeReported: chats[i].canBeReported,
                    defaultDisableNotification: chats[i].defaultDisableNotification,
                    unreadCount: chats[i].unreadCount,
                    lastReadInboxMessageId: chats[i].lastReadInboxMessageId,
                    lastReadOutboxMessageId: chats[i].lastReadOutboxMessageId,
                    unreadMentionCount: chats[i].unreadMentionCount,
                    unreadReactionCount: chats[i].unreadReactionCount,
                    notificationSettings: chats[i].notificationSettings,
                    availableReactions: chats[i].availableReactions,
                    messageAutoDeleteTime: chats[i].messageAutoDeleteTime,
                    emojiStatus: chats[i].emojiStatus,
                    background: chats[i].background,
                    themeName: chats[i].themeName,
                    actionBar: chats[i].actionBar,
                    videoChat: chats[i].videoChat,
                    pendingJoinRequests: chats[i].pendingJoinRequests,
                    replyMarkupMessageId: chats[i].replyMarkupMessageId,
                    draftMessage: chats[i].draftMessage,
                    clientData: chats[i].clientData
                )
            }
        default:
            break
        }
    }

    // MARK: - Auth

    private func handleAuth(state: AuthorizationState) {
        switch state {
        case .authorizationStateWaitPhoneNumber:
            DispatchQueue.main.async { self.authState = .waitPhoneNumber }
        case .authorizationStateWaitCode:
            DispatchQueue.main.async { self.authState = .waitCode }
        case .authorizationStateWaitPassword:
            DispatchQueue.main.async { self.authState = .waitPassword }
        case .authorizationStateReady:
            DispatchQueue.main.async { self.authState = .ready }
            loadChats()
        case .authorizationStateClosed:
            DispatchQueue.main.async { self.authState = .idle }
        default:
            break
        }
    }

    func sendPhone(_ phone: String) async throws {
        try await api.setAuthenticationPhoneNumber(
            phoneNumber: phone,
            settings: nil
        )
    }

    func sendCode(_ code: String) async throws {
        try await api.checkAuthenticationCode(code: code)
    }

    func sendPassword(_ password: String) async throws {
        try await api.checkAuthenticationPassword(password: password)
    }

    // MARK: - Chats

    func loadChats() {
        Task {
            _ = try? await api.loadChats(chatList: .chatListMain, limit: 100)
        }
    }

    // MARK: - Ghost Mode

    /// Помечает чат прочитанным только если Ghost Mode выключен
    func markRead(chatId: Int64, messageId: Int64) {
        guard !TweakSettings.shared.ghostMode else { return }
        Task {
            _ = try? await api.viewMessages(
                chatId: chatId,
                messageIds: [messageId],
                source: nil,
                forceRead: false
            )
        }
    }

    // MARK: - Send message

    func send(text: String, chatId: Int64, replyToId: Int64? = nil) async throws {
        let content = InputMessageContent.inputMessageText(
            InputMessageText(
                text: FormattedText(text: text, entities: []),
                linkPreviewOptions: nil,
                clearDraft: true
            )
        )
        var replyTo: InputMessageReplyTo? = nil
        if let rid = replyToId {
            replyTo = .inputMessageReplyToMessage(
                InputMessageReplyToMessage(chatId: chatId, messageId: rid, quote: nil)
            )
        }
        _ = try await api.sendMessage(
            chatId: chatId,
            messageThreadId: 0,
            replyTo: replyTo,
            options: nil,
            replyMarkup: nil,
            inputMessageContent: content
        )
    }

    // MARK: - Messages

    func loadMessages(chatId: Int64, fromMessageId: Int64 = 0, limit: Int = 50) async throws -> [Message] {
        let result = try await api.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            offset: 0,
            limit: limit,
            onlyLocal: false
        )
        return result.messages ?? []
    }

    // MARK: - Helpers

    private func dbPath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("darkgram_db").path
    }

    private func filesPath() -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("darkgram_files").path
    }
}
