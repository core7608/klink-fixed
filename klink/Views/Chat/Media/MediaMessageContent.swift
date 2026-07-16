import SwiftUI
import AVKit

struct MediaMessageContent: View {
    let message: Message
    let isMine: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        switch message.type {
        case "image":
            imageContent
        case "video":
            videoContent
        case "audio":
            AudioBubbleContent(message: message, isMine: isMine)
        case "file":
            fileContent
        default:
            Text(message.text ?? "")
                .font(.system(size: 15))
        }
    }

    private var imageContent: some View {
        AsyncImage(url: URL(string: message.mediaThumbURL ?? message.mediaURL ?? "")) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else if phase.error != nil {
                Color.gray.opacity(0.2).overlay(Image(systemName: "photo"))
            } else {
                Color.gray.opacity(0.1).overlay(ProgressView())
            }
        }
        .frame(width: 220, height: mediaHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var mediaHeight: CGFloat {
        guard let w = message.mediaWidth, let h = message.mediaHeight, w > 0 else { return 220 }
        let ratio = CGFloat(h) / CGFloat(w)
        return min(max(220 * ratio, 140), 320)
    }

    private var videoContent: some View {
        ZStack {
            if let urlString = message.mediaThumbURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { Color.black.opacity(0.6) }
                }
            } else {
                Color.black.opacity(0.6)
            }
            Circle()
                .fill(.black.opacity(0.45))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                }
        }
        .frame(width: 220, height: mediaHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var fileContent: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isMine ? Color.white.opacity(0.15) : Color.black.opacity(0.06))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(isMine ? themeManager.current.bubbleMineText : themeManager.current.bubbleTheirsText)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(message.mediaFileName ?? "File")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                if let size = message.mediaFileSizeBytes {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
        }
        .frame(minWidth: 180)
    }
}

private struct AudioBubbleContent: View {
    let message: Message
    let isMine: Bool
    @ObservedObject private var player = AudioPlaybackService.shared
    @EnvironmentObject var themeManager: ThemeManager

    private var isPlaying: Bool { player.playingMessageId == message.id }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                guard let urlString = message.mediaURL, let url = URL(string: urlString) else { return }
                player.play(url: url, messageId: message.id)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill((isMine ? themeManager.current.bubbleMineText : themeManager.current.bubbleTheirsText).opacity(0.15)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill((isMine ? themeManager.current.bubbleMineText : themeManager.current.bubbleTheirsText).opacity(0.2))
                        Capsule().fill(isMine ? themeManager.current.bubbleMineText : themeManager.current.bubbleTheirsText)
                            .frame(width: geo.size.width * (isPlaying ? player.progress : 0))
                    }
                }
                .frame(height: 4)

                if let duration = message.mediaDurationSeconds {
                    Text(formatDuration(duration))
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
            }
        }
        .frame(minWidth: 160)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
