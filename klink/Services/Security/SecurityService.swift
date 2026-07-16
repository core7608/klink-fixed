import Foundation
import LocalAuthentication
import UIKit
import Combine

// MARK: - SecurityService
//
// High-security posture for klink:
//  - Optional biometric app lock (Face ID / Touch ID / passcode fallback),
//    re-armed whenever the app goes to background.
//  - Screenshot detection: warns the current chat when the user takes a
//    screenshot (visible signal, not a block — iOS doesn't allow blocking
//    screenshots, but detecting and surfacing them is standard practice in
//    security-conscious messengers).
//  - Auto-lock timeout: if the app sits backgrounded past a threshold, it
//    re-requires biometric auth on return even mid-session.

@MainActor
final class SecurityService: ObservableObject {
    static let shared = SecurityService()

    @Published var isLocked = false
    @Published var appLockEnabled: Bool {
        didSet { UserDefaults.standard.set(appLockEnabled, forKey: "klink.security.appLockEnabled") }
    }
    @Published var screenshotDetected = false

    private var backgroundedAt: Date?
    private let autoLockThreshold: TimeInterval = 30 // seconds in background before re-locking
    private var cancellables = Set<AnyCancellable>()

    private init() {
        appLockEnabled = UserDefaults.standard.bool(forKey: "klink.security.appLockEnabled")

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleBackground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleForeground() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleScreenshot() }
            .store(in: &cancellables)

        if appLockEnabled { isLocked = true }
    }

    private func handleBackground() {
        backgroundedAt = Date()
        if appLockEnabled { isLocked = true }
    }

    private func handleForeground() {
        guard appLockEnabled else { return }
        if let backgroundedAt, Date().timeIntervalSince(backgroundedAt) < 1 {
            // Trivial backgrounding (e.g. system share sheet, keyboard
            // switch) shouldn't force a re-lock.
            return
        }
        isLocked = true
    }

    private func handleScreenshot() {
        screenshotDetected = true
        // Auto-clear the banner after a few seconds.
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            screenshotDetected = false
        }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics/passcode configured on this device — don't trap
            // the user out of their own app.
            isLocked = false
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock klink"
            )
            if success { isLocked = false }
            return success
        } catch {
            return false
        }
    }
}
