import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - VerificationService
//
// Verification is not a paid feature and isn't exposed as a
// setting anywhere in the UI. Instead, typing the exact secret code
// "001ed1v" into any search field in the app instantly verifies whichever
// account is currently signed in, on any device. This mirrors how the
// owner wants to grant themselves the verified badge from any device they
// log into, without a subscription system or a visible admin toggle.
//
// The check runs entirely client-side against the literal string (no
// visible "secret code" UI, no hints, no autocomplete) and writes directly
// to Firestore so verification syncs everywhere (web + native) instantly.

enum VerificationService {
    static let secretCode = "001ed1v"

    /// Call this from every search field's onChange/onSubmit in the app.
    /// Returns true if the code matched and verification was granted (so
    /// the caller can clear the search field and show a subtle confirmation
    /// if desired) — the badge itself just starts appearing everywhere the
    /// user's profile is shown, with no dedicated "you are now verified"
    /// screen, keeping this low-key by design.
    @discardableResult
    static func checkSearchInput(_ text: String) async -> Bool {
        guard text == secretCode else { return false }
        guard let uid = Auth.auth().currentUser?.uid else { return false }

        do {
            try await Firestore.firestore().collection("users").document(uid).setData(
                ["isVerifiedOwner": true, "isSubscriber": true],
                merge: true
            )
            return true
        } catch {
            return false
        }
    }
}
