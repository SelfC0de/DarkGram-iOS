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

    private var client: TDLibClient!
    private let manager: TDLibClientManager

    private init() {
        manager = TDLibClientManager()
        client = manager.createClient(updateHandler: { data, tdClient in
            do {
                let update = try tdClient.decoder.decode(Update.self, from: data)
                Task { @MainActor in
                    TDManager.shared.handle(update: update)
                }
            } catch {}
        })
    }

    // MARK: - Configure

    private func configure() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbDir    = docs.appendingPathComponent("darkgram_db").path
        let filesDir = docs.appendingPathComponent("darkgram_files").path

        Task {
            do {
                try await client.setTdlibParameters(
                    apiHash: TELEGRAM_API_HASH,
                    apiId: Int(TELEGRAM_API_ID),
                    applicationVersion: "1.0",
                    databaseDirectory: dbDir,
                    databaseEncryptionKey: nil,
                    deviceModel: UIDevice.current.model,
                    filesDirectory: filesDir,
                    systemLanguageCode: Locale.current.language.languageCode?.identifier ?? "en",
                    systemVersion: UIDevice.current.systemVersion,
                    useChatInfoDatabase: true,
                    useFileDatabase: true,
                    useMessageDatabase: true,
                    useSecretChats: false,
                    useTestDc: false
                )
            } catch {
                print("[TDManager] setTdlibParameters error: \(error)")
            }
        }
    }

    // MARK: - Updates

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
                chats[i] = chats[i].withLastMessage(u.lastMessage, positions: u.positions)
            }
        default:
            break
        }
    }

    // MARK: - Auth

    private func handleAuth(state: AuthorizationState) {
        print("[TDManager] auth state: \(state)")
        switch state {
        case .authorizationStateWaitTdlibParameters:
            configure()
        case .authorizationStateWaitPhoneNumber:
            Task { @MainActor in self.authState = .waitPhoneNumber }
        case .authorizationStateWaitCode:
            Task { @MainActor in self.authState = .waitCode }
        case .authorizationStateWaitPassword:
            Task { @MainActor in self.authState = .waitPassword }
        case .authorizationStateReady:
            Task { @MainActor in self.authState = .ready }
            loadChats()
        case .authorizationStateClosed, .authorizationStateLoggingOut:
            Task { @MainActor in self.authState = .idle }
        default:
            break
        }
    }

    // MARK: - Public auth methods

    func sendPhone(_ phone: String) async throws {
        try await client.setAuthenticationPhoneNumber(phoneNumber: phone, settings: nil)
    }

    func sendCode(_ code: String) async throws {
        try await client.checkAuthenticationCode(code: code)
    }

    func sendPassword(_ password: String) async throws {
        try await client.checkAuthenticationPassword(password: password)
    }

    func logOut() {
        Task { _ = try? await client.logOut() }
    }

    // MARK: - Chats

    func loadChats() {
        Task {
            _ = try? await client.loadChats(chatList: .chatListMain, limit: 100)
        }
    }

    // MARK: - Ghost Mode

    func markRead(chatId: Int64, messageId: Int64) {
        guard !TweakSettings.shared.ghostMode else { return }
        Task {
            _ = try? await client.viewMessages(
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
        _ = try await client.sendMessage(
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
        let result = try await client.getChatHistory(
            chatId: chatId,
            fromMessageId: fromMessageId,
            limit: limit,
            offset: 0,
            onlyLocal: false
        )
        return result.messages ?? []
    }
}

// MARK: - Chat helper

private extension Chat {
    func withLastMessage(_ lastMessage: Message?, positions: [ChatPosition]) -> Chat {
        Chat(
            accentColorId: accentColorId,
            actionBar: actionBar,
            availableReactions: availableReactions,
            background: background,
            backgroundCustomEmojiId: backgroundCustomEmojiId,
            blockList: blockList,
            businessBotManageBar: businessBotManageBar,
            canBeDeletedForAllUsers: canBeDeletedForAllUsers,
            canBeDeletedOnlyForSelf: canBeDeletedOnlyForSelf,
            canBeReported: canBeReported,
            chatLists: chatLists,
            clientData: clientData,
            defaultDisableNotification: defaultDisableNotification,
            draftMessage: draftMessage,
            emojiStatus: emojiStatus,
            hasProtectedContent: hasProtectedContent,
            hasScheduledMessages: hasScheduledMessages,
            id: id,
            isMarkedAsUnread: isMarkedAsUnread,
            isTranslatable: isTranslatable,
            lastMessage: lastMessage,
            lastReadInboxMessageId: lastReadInboxMessageId,
            lastReadOutboxMessageId: lastReadOutboxMessageId,
            messageAutoDeleteTime: messageAutoDeleteTime,
            messageSenderId: messageSenderId,
            notificationSettings: notificationSettings,
            pendingJoinRequests: pendingJoinRequests,
            permissions: permissions,
            photo: photo,
            positions: positions,
            profileAccentColorId: profileAccentColorId,
            profileBackgroundCustomEmojiId: profileBackgroundCustomEmojiId,
            replyMarkupMessageId: replyMarkupMessageId,
            theme: theme,
            title: title,
            type: type,
            unreadCount: unreadCount,
            unreadMentionCount: unreadMentionCount,
            unreadReactionCount: unreadReactionCount,
            upgradedGiftColors: upgradedGiftColors,
            videoChat: videoChat,
            viewAsTopics: viewAsTopics
        )
    }
}
