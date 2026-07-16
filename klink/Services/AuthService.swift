import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

// MARK: - AuthService
//
// This is a fully native replacement for the web app's authService.js.
// No WebView involved anywhere — Google Sign-In goes through Google's own
// native iOS SDK, which opens the system browser / native account picker.
// That's the flow Apple + Google actually support, so there's no
// "No provider was initialized" / hanging popup class of bug possible here.

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var user: KlinkUser?
    @Published var loading = true

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                guard let self else { return }
                if let firebaseUser {
                    self.user = try? await self.ensureUserProfile(firebaseUser)
                } else {
                    self.user = nil
                }
                self.loading = false
            }
        }

        // Safety net: never hang on the loading spinner forever if the auth
        // backend never calls back (bad network on first launch, etc).
        Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if loading { loading = false }
        }
    }

    deinit {
        // Auth listener removal is thread-safe; avoid capturing MainActor
        // state from deinit by reading the stored handle directly.
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: Google Sign-In

    func signInWithGoogle() async throws {
        guard let rootVC = Self.topViewController() else {
            throw AuthError.noPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        user = try await ensureUserProfile(authResult.user)
    }

    // MARK: Email / password

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        user = try await ensureUserProfile(result.user)
    }

    func register(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        user = try await ensureUserProfile(result.user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        user = nil
    }

    // MARK: Profile sync (Firestore "users" collection, same shape as web)

    private func ensureUserProfile(_ firebaseUser: FirebaseAuth.User) async throws -> KlinkUser {
        try await FirestoreService.shared.ensureUserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString
        )
    }

    // MARK: Helpers

    private static func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    enum AuthError: LocalizedError {
        case noPresentingViewController
        case missingIDToken

        var errorDescription: String? {
            switch self {
            case .noPresentingViewController:
                return "Couldn't open the sign-in screen."
            case .missingIDToken:
                return "Couldn't sign in with Google. Please try again."
            }
        }
    }
}
