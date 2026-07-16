import Foundation
import AVFoundation

@MainActor
final class AudioPlaybackService: NSObject, ObservableObject {
    static let shared = AudioPlaybackService()

    @Published var playingMessageId: String?
    @Published var progress: Double = 0 // 0...1

    private var player: AVPlayer?
    private var timeObserver: Any?

    func play(url: URL, messageId: String) {
        if playingMessageId == messageId {
            togglePause()
            return
        }
        stop()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        playingMessageId = messageId
        progress = 0

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self, let duration = newPlayer.currentItem?.duration.seconds, duration > 0, duration.isFinite else { return }
            self.progress = time.seconds / duration
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        newPlayer.play()
    }

    private func togglePause() {
        guard let player else { return }
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player = nil
        playingMessageId = nil
        progress = 0
    }
}
