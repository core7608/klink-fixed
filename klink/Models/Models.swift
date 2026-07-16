import Foundation

// MARK: - Models
// Mirror the Firestore document shapes used by the existing web app so this
// native client reads/writes the exact same data.

struct KlinkUser: Identifiable, Codable, Equatable {
    var id: String { uid }
    var uid: String
    var username: String?
    var displayName: String?
    var photoURL: String?
    var email: String?
    var isSubscriber: Bool?
    var isVerifiedOwner: Bool?
    var subscriptionUntil: Double?
    var createdAt: Double?
    var lastSeen: Double?
}

struct Message: Identifiable, Codable, Equatable {
    var id: String
    var chatId: String
    var senderId: String
    var text: String?
    var type: String // "text" | "image" | "video" | "audio" | "file" | "deleted" | "system"
    var createdAt: Double?
    var status: String? // "pending" | "sent" | "delivered" | "read"
    var replyToId: String?
    var replyToText: String?
    var replyToSenderId: String?

    // Media attachment fields (all optional; used depending on `type`).
    var mediaURL: String?
    var mediaThumbURL: String?
    var mediaDurationSeconds: Double?
    var mediaFileName: String?
    var mediaFileSizeBytes: Int?
    var mediaWidth: Int?
    var mediaHeight: Int?

    var isEdited: Bool?
}

struct Chat: Identifiable, Codable, Equatable {
    var id: String
    var isGroup: Bool
    var name: String?
    var photoURL: String?
    var memberIds: [String]
    var lastMessage: Message?
    var unread: [String: Int]
    var updatedAt: Double?
    var otherUser: KlinkUser?
}
