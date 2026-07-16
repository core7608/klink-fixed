import Foundation
import AVFoundation

// MARK: - VoiceRecorderService
// Records voice messages to disk (m4a/AAC, small + widely compatible),
// tracks elapsed time for the live waveform/timer UI, and hands back the
// recorded file + duration for upload via MediaService.

@MainActor
final class VoiceRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var meterLevel: Float = 0 // 0...1, for a simple live waveform

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    func requestPermissionAndStart() async -> Bool {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = await AVAudioApplication.requestRecordPermission()
        } else {
            granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { ok in
                    continuation.resume(returning: ok)
                }
            }
        }
        guard granted else { return false }
        start()
        return true
    }

    private func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("klink-voice-\(UUID().uuidString).m4a")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            elapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        } catch {
            isRecording = false
        }
    }

    private func tick() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        elapsed = recorder.currentTime
        let db = recorder.averagePower(forChannel: 0)
        // Normalize dB (-160...0) into a 0...1 level for a simple UI meter.
        let normalized = max(0, min(1, (db + 50) / 50))
        meterLevel = normalized
    }

    /// Stops recording and returns the file URL + duration, or nil if
    /// there was nothing usable (e.g. cancelled almost immediately).
    func stopAndFinish() -> (url: URL, duration: TimeInterval)? {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = recordingURL, elapsed > 0.3 else { return nil }
        return (url, elapsed)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

extension VoiceRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}
