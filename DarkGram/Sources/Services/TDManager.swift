import Foundation
import TDLibKit
import UIKit
import Combine

enum AuthState: Equatable {
    case idle, waitPhoneNumber, waitCode, waitPassword, ready, error(String)
}

final class TDManager: ObservableObject {
    static let shared = TDManager()

    @Published var authState: AuthState = .idle
    @Published var chats: [Chat] = []

    private let api: TdApi
    private let manager = TDLibClientManager()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let tdClient = manager.createClient(updateHandler: { data, _ in
            guard let update = try? JSONDecoder().decode(Update.self, from: data) else { return }
            Task { @MainActor in
                TDManager.shared.handle(update: update)
            }
        })
        api = TdApi(client: tdClient as! TdClient)
        configure()
    }

    // MARK: - Configure

    private func configure() {
        Task {
            _ = try? await api.setTdlibParameters(
                apiHash: TELEGRAM_API_HASH,
                apiId: Int(TELEGRAM_API_ID),
                applicationVersion: "1.0",
                databaseDirectory: dbPath(),
                databaseEncryptionKey: nil,
                deviceModel: UIDevice.current.model,
                filesDirectory: filesPath(),
                systemLanguageCode: Locale.current.language.languageCode?.identifier ?? "en",
                systemVersion: UIDevice.current.systemVersion,
                useChatInfoDatabase: true,
                useFileDatabase: true,
                useMessageDatabase: true,
                useSecretChats: true,
                useTestDc: false
            )
        }
    }

    // MARK: - Update loop

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
                var chat = chats[i]
                chats[i] = Chat(
                    accentColorId: chat.accentColorId,
                    actionBar: chat.actionBar,
                    availableReactions: chat.availableReactions,
                    background: chat.background,
                    backgroundCustomEmojiId: chat.backgroundCustomEmojiId,
                    blockList: chat.blockList,
                    businessBotManageBar: chat.businessBotManageBar,
                    canBeDeletedForAllUsers: chat.canBeDeletedForAllUsers,
                    canBeDeletedOnlyForSelf: chat.canBeDeletedOnlyForSelf,
                    canBeReported: chat.canBeReported,
                    chatLists: chat.chatLists,
                    clientData: chat.clientData,
                    defaultDisableNotification: chat.defaultDisableNotification,
                    draftMessage: chat.draftMessage,
                    emojiStatus: chat.emojiStatus,
                    hasProtectedContent: chat.hasProtectedContent,
                    hasScheduledMessages: chat.hasScheduledMessages,
                    id: chat.id,
                    isMarkedAsUnread: chat.isMarkedAsUnread,
                    isTranslatable: chat.isTranslatable,
                    lastMessage: u.lastMessage,
                    lastReadInboxMessageId: chat.lastReadInboxMessageId,
                    lastReadOutboxMessageId: chat.lastReadOutboxMessageId,
                    messageAutoDeleteTime: chat.messageAutoDeleteTime,
                    messageSenderId: chat.messageSenderId,
                    notificationSettings: chat.notificationSettings,
                    pendingJoinRequests: chat.pendingJoinRequests,
                    permissions: chat.permissions,
                    photo: chat.photo,
                    positions: u.positions,
                    profileAccentColorId: chat.profileAccentColorId,
                    profileBackgroundCustomEmojiId: chat.profileBackgroundCustomEmojiId,
                    replyMarkupMessageId: chat.replyMarkupMessageId,
                    theme: chat.theme,
                    title: chat.title,
                    type: chat.type,
                    unreadCount: chat.unreadCount,
                    unreadMentionCount: chat.unreadMentionCount,
                    unreadReactionCount: chat.unreadReactionCount,
                    upgradedGiftColors: chat.upgradedGiftColors,
                    videoChat: chat.videoChat,
                    viewAsTopics: chat.viewAsTopics
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

    func markRead(chatId: Int64, messageId: Int64) {
        guard !TweakSettings.shared.ghostMode else { return }
        Task {
            _ = try? await api.viewMessages(
                chatId: chatId,
                forceRead: false,
                messageIds: [messageId],
                source: nil
            )
        }
    }

    // MARK: - Send message

    func send(text: String, chatId: Int64, replyToId: Int64? = nil) async throws {
        let content = InputMessageContent.inputMessageText(
            InputMessageText(
                clearDraft: true,
                linkPreviewOptions: nil,
                text: FormattedText(entities: [], text: text)
            )
        )
        var replyTo: InputMessageReplyTo? = nil
        if let rid = replyToId {
            replyTo = .inputMessageReplyToMessage(
                InputMessageReplyToMessage(checklistTaskId: 0, messageId: rid, quote: nil)
            )
        }
        _ = try await api.sendMessage(
            chatId: chatId,
            inputMessageContent: content,
            options: nil,
            replyMarkup: nil,
            replyTo: replyTo,
            topicId: nil
        )
    }

    // MARK: - Messages

    func loadMessages(chatId: Int64, fromMessageId: Int64 = 0, limit: Int = 50) async throws -> [Message] {
        let result = try await api.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            limit: limit,
            offset: 0,
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
