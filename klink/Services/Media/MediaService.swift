import Foundation
import FirebaseStorage
import UIKit

// MARK: - MediaService
// Uploads any attachment type (image, video, voice note, arbitrary file) to
// Firebase Storage under a per-chat path, mirroring what the web app does,
// so media sent from the native app and the web client are interchangeable.

enum MediaKind: String {
    case image, video, audio, file
}

struct UploadedMedia {
    var url: String
    var thumbURL: String?
    var fileName: String?
    var fileSizeBytes: Int
    var width: Int?
    var height: Int?
    var durationSeconds: Double?
}

final class MediaService {
    static let shared = MediaService()
    private let storage = Storage.storage()
    private init() {}

    func upload(
        data: Data,
        kind: MediaKind,
        chatId: String,
        fileName: String,
        contentType: String,
        width: Int? = nil,
        height: Int? = nil,
        durationSeconds: Double? = nil,
        thumbnailData: Data? = nil
    ) async throws -> UploadedMedia {
        let path = "chats/\(chatId)/\(kind.rawValue)/\(UUID().uuidString)-\(fileName)"
        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()

        var thumbURL: String?
        if let thumbnailData {
            let thumbRef = storage.reference().child("chats/\(chatId)/thumbs/\(UUID().uuidString).jpg")
            let thumbMeta = StorageMetadata()
            thumbMeta.contentType = "image/jpeg"
            _ = try await thumbRef.putDataAsync(thumbnailData, metadata: thumbMeta)
            thumbURL = try await thumbRef.downloadURL().absoluteString
        }

        return UploadedMedia(
            url: url.absoluteString,
            thumbURL: thumbURL,
            fileName: fileName,
            fileSizeBytes: data.count,
            width: width,
            height: height,
            durationSeconds: durationSeconds
        )
    }

    /// Convenience for images: downsamples large photos before upload to
    /// keep bandwidth and storage costs reasonable, and generates a small
    /// thumbnail for the chat list / bubble preview.
    func uploadImage(_ image: UIImage, chatId: String) async throws -> UploadedMedia {
        let resized = Self.resized(image, maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.82) else {
            throw MediaError.encodingFailed
        }
        let thumb = Self.resized(image, maxDimension: 240)
        let thumbData = thumb.jpegData(compressionQuality: 0.6)

        return try await upload(
            data: data,
            kind: .image,
            chatId: chatId,
            fileName: "photo.jpg",
            contentType: "image/jpeg",
            width: Int(resized.size.width),
            height: Int(resized.size.height),
            thumbnailData: thumbData
        )
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    enum MediaError: LocalizedError {
        case encodingFailed
        var errorDescription: String? {
            "Couldn't process the file before sending."
        }
    }
}
