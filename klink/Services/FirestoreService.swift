import Foundation
import FirebaseFirestore

// MARK: - FirestoreService
// Mirrors the Firestore collections used by the web app:
//   users/{uid}
//   chats/{chatId}
//   chats/{chatId}/messages/{messageId}

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: Users

    func ensureUserProfile(
        uid: String,
        email: String?,
        displayName: String?,
        photoURL: String?
    ) async throws -> KlinkUser {
        let ref = db.collection("users").document(uid)
        let snapshot = try await ref.getDocument()

        if snapshot.exists, let data = snapshot.data() {
            return Self.decodeUser(uid: uid, data: data)
        }

        let now = Date().timeIntervalSince1970 * 1000
        let newUserData: [String: Any] = [
            "uid": uid,
            "email": email as Any,
            "displayName": displayName as Any,
            "photoURL": photoURL as Any,
            "createdAt": now,
            "lastSeen": now,
        ]
        try await ref.setData(newUserData, merge: true)
        return KlinkUser(
            uid: uid,
            username: nil,
            displayName: displayName,
            photoURL: photoURL,
            email: email,
            isSubscriber: false,
            subscriptionUntil: nil,
            createdAt: now,
            lastSeen: now
        )
    }

    func fetchUser(uid: String) async throws -> KlinkUser? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return Self.decodeUser(uid: uid, data: data)
    }

    private static func decodeUser(uid: String, data: [String: Any]) -> KlinkUser {
        KlinkUser(
            uid: uid,
            username: data["username"] as? String,
            displayName: data["displayName"] as? String,
            photoURL: data["photoURL"] as? String,
            email: data["email"] as? String,
            isSubscriber: data["isSubscriber"] as? Bool,
            isVerifiedOwner: data["isVerifiedOwner"] as? Bool,
            subscriptionUntil: data["subscriptionUntil"] as? Double,
            createdAt: data["createdAt"] as? Double,
            lastSeen: data["lastSeen"] as? Double
        )
    }

    // MARK: Chats

    func listenChats(uid: String, onChange: @escaping ([Chat]) -> Void) -> ListenerRegistration {
        db.collection("chats")
            .whereField("memberIds", arrayContains: uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let chats: [Chat] = docs.compactMap { doc in
                    let data = doc.data()
                    guard let memberIds = data["memberIds"] as? [String] else { return nil }
                    let lastMessageData = data["lastMessage"] as? [String: Any]
                    let lastMessage = lastMessageData.map { lm in
                        Message(
                            id: lm["id"] as? String ?? "",
                            chatId: doc.documentID,
                            senderId: lm["senderId"] as? String ?? "",
                            text: lm["text"] as? String,
                            type: lm["type"] as? String ?? "text",
                            createdAt: lm["createdAt"] as? Double,
                            status: lm["status"] as? String,
                            replyToId: lm["replyToId"] as? String
                        )
                    }
                    return Chat(
                        id: doc.documentID,
                        isGroup: data["isGroup"] as? Bool ?? false,
                        name: data["name"] as? String,
                        photoURL: data["photoURL"] as? String,
                        memberIds: memberIds,
                        lastMessage: lastMessage,
                        unread: data["unread"] as? [String: Int] ?? [:],
                        updatedAt: data["updatedAt"] as? Double,
                        otherUser: nil
                    )
                }
                onChange(chats)
            }
    }

    // MARK: Messages

    func listenMessages(chatId: String, onChange: @escaping ([Message]) -> Void) -> ListenerRegistration {
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(toLast: 200)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let messages: [Message] = docs.map { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        chatId: chatId,
                        senderId: data["senderId"] as? String ?? "",
                        text: data["text"] as? String,
                        type: data["type"] as? String ?? "text",
                        createdAt: data["createdAt"] as? Double,
                        status: data["status"] as? String,
                        replyToId: data["replyToId"] as? String,
                        replyToText: data["replyToText"] as? String,
                        replyToSenderId: data["replyToSenderId"] as? String,
                        mediaURL: data["mediaURL"] as? String,
                        mediaThumbURL: data["mediaThumbURL"] as? String,
                        mediaDurationSeconds: data["mediaDurationSeconds"] as? Double,
                        mediaFileName: data["mediaFileName"] as? String,
                        mediaFileSizeBytes: data["mediaFileSizeBytes"] as? Int,
                        mediaWidth: data["mediaWidth"] as? Int,
                        mediaHeight: data["mediaHeight"] as? Int,
                        isEdited: data["isEdited"] as? Bool
                    )
                }
                onChange(messages)
            }
    }

    func sendMessage(chatId: String, senderId: String, text: String, replyTo: Message? = nil) async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()
        var payload: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "type": "text",
            "createdAt": now,
            "status": "sent",
        ]
        if let replyTo {
            payload["replyToId"] = replyTo.id
            payload["replyToText"] = replyTo.type == "text" ? (replyTo.text ?? "") : Self.previewLabel(for: replyTo)
            payload["replyToSenderId"] = replyTo.senderId
        }
        try await messageRef.setData(payload)

        try await db.collection("chats").document(chatId).setData([
            "updatedAt": now,
            "lastMessage": [
                "id": messageRef.documentID,
                "senderId": senderId,
                "text": text,
                "type": "text",
                "createdAt": now,
                "status": "sent",
            ],
        ], merge: true)
    }

    /// Sends any non-text attachment (image, video, audio, file) already
    /// uploaded via MediaService, writing the same message-document shape
    /// the web app expects so both clients render it identically.
    func sendMediaMessage(
        chatId: String,
        senderId: String,
        kind: MediaKind,
        media: UploadedMedia,
        replyTo: Message? = nil
    ) async throws {
        let now = Date().timeIntervalSince1970 * 1000
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()

        var payload: [String: Any] = [
            "senderId": senderId,
            "type": kind.rawValue,
            "createdAt": now,
            "status": "sent",
            "mediaURL": media.url,
        ]
        if let thumb = media.thumbURL { payload["mediaThumbURL"] = thumb }
        if let name = media.fileName { payload["mediaFileName"] = name }
        payload["mediaFileSizeBytes"] = media.fileSizeBytes
        if let w = media.width { payload["mediaWidth"] = w }
        if let h = media.height { payload["mediaHeight"] = h }
        if let d = media.durationSeconds { payload["mediaDurationSeconds"] = d }

        if let replyTo {
            payload["replyToId"] = replyTo.id
            payload["replyToText"] = replyTo.type == "text" ? (replyTo.text ?? "") : Self.previewLabel(for: replyTo)
            payload["replyToSenderId"] = replyTo.senderId
        }

        try await messageRef.setData(payload)

        let lastMessagePreview = Self.previewLabel(forKind: kind)
        try await db.collection("chats").document(chatId).setData([
            "updatedAt": now,
            "lastMessage": [
                "id": messageRef.documentID,
                "senderId": senderId,
                "text": lastMessagePreview,
                "type": kind.rawValue,
                "createdAt": now,
                "status": "sent",
            ],
        ], merge: true)
    }

    private static func previewLabel(for message: Message) -> String {
        previewLabel(forKind: MediaKind(rawValue: message.type) ?? .file)
    }

    private static func previewLabel(forKind kind: MediaKind) -> String {
        switch kind {
        case .image: return "📷 Photo"
        case .video: return "🎥 Video"
        case .audio: return "🎤 Voice message"
        case .file: return "📎 File"
        }
    }

    /// Soft-deletes a message, mirroring the web's deleteMessage(): the
    /// message's `type` becomes "deleted" and its text is cleared, rather
    /// than removing the document outright.
    func deleteMessage(chatId: String, messageId: String) async throws {
        try await db.collection("chats").document(chatId).collection("messages")
            .document(messageId)
            .setData(["type": "deleted", "text": FieldValue.delete()], merge: true)
    }
}
