import Foundation
import FirebaseFirestore

@MainActor
final class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published var chats: [Chat] = []
    private var chatsListener: ListenerRegistration?

    private init() {}

    func subscribeChats(uid: String) {
        chatsListener?.remove()
        chatsListener = FirestoreService.shared.listenChats(uid: uid) { [weak self] chats in
            Task { @MainActor in
                self?.chats = chats
            }
        }
    }

    func stop() {
        chatsListener?.remove()
        chatsListener = nil
    }
}

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var listener: ListenerRegistration?
    let chatId: String

    init(chatId: String) {
        self.chatId = chatId
    }

    func subscribe() {
        listener?.remove()
        listener = FirestoreService.shared.listenMessages(chatId: chatId) { [weak self] messages in
            Task { @MainActor in
                self?.messages = messages
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send(text: String, senderId: String, replyTo: Message? = nil) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? await FirestoreService.shared.sendMessage(
            chatId: chatId,
            senderId: senderId,
            text: trimmed,
            replyTo: replyTo
        )
    }

    func sendMedia(_ uploaded: UploadedMedia, kind: MediaKind, senderId: String, replyTo: Message? = nil) async {
        try? await FirestoreService.shared.sendMediaMessage(
            chatId: chatId,
            senderId: senderId,
            kind: kind,
            media: uploaded,
            replyTo: replyTo
        )
    }

    func delete(messageId: String) async {
        try? await FirestoreService.shared.deleteMessage(chatId: chatId, messageId: messageId)
    }
}
