import Foundation
import Combine

// MARK: - DraftStore
//
// THE FEATURE: everyone has had this happen — you're in the middle of typing
// a long message, a new message comes in, and you want to reply to *that*
// new message right now without losing the long thing you were already
// writing.
//
// Normal chat apps force you to choose: either send/discard what you were
// writing, or ignore the new message until you finish. klink instead lets
// you "stash" your in-progress draft with one tap, reply to the incoming
// message immediately, and then "restore" your stashed draft afterward
// exactly where you left off — cursor position, reply-context and all.
//
// Multiple stashes are supported (a small stack), so this also works if a
// second message arrives while you're answering the first interruption.

struct StashedDraft: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var replyingTo: Message?
    var stashedAt: Date = Date()
}

@MainActor
final class DraftStore: ObservableObject {
    /// The text currently in the input field for a given chat.
    @Published var currentText: [String: String] = [:]
    /// The message the current input is replying to, per chat.
    @Published var currentReplyTarget: [String: Message] = [:]
    /// Stack of stashed (interrupted) drafts per chat — most recent last.
    @Published var stashes: [String: [StashedDraft]] = [:]

    func text(for chatId: String) -> String {
        currentText[chatId] ?? ""
    }

    func setText(_ text: String, for chatId: String) {
        currentText[chatId] = text
    }

    func replyTarget(for chatId: String) -> Message? {
        currentReplyTarget[chatId]
    }

    func setReplyTarget(_ message: Message?, for chatId: String) {
        currentReplyTarget[chatId] = message
    }

    /// Push whatever is currently being composed onto the stash stack, then
    /// clear the input so the user can immediately compose a reply to a new
    /// incoming message. Returns true if something was actually stashed
    /// (i.e. there was real in-progress content worth saving).
    @discardableResult
    func stashCurrentDraft(for chatId: String) -> Bool {
        let text = currentText[chatId] ?? ""
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let stash = StashedDraft(text: text, replyingTo: currentReplyTarget[chatId])
        stashes[chatId, default: []].append(stash)
        currentText[chatId] = ""
        currentReplyTarget[chatId] = nil
        return true
    }

    /// Pop the most recent stash back into the active input, restoring both
    /// the text and whatever it was replying to.
    func restoreLastStash(for chatId: String) {
        guard var stack = stashes[chatId], !stack.isEmpty else { return }
        let last = stack.removeLast()
        stashes[chatId] = stack
        currentText[chatId] = last.text
        currentReplyTarget[chatId] = last.replyingTo
    }

    func hasStashes(for chatId: String) -> Bool {
        !(stashes[chatId]?.isEmpty ?? true)
    }

    func stashCount(for chatId: String) -> Int {
        stashes[chatId]?.count ?? 0
    }

    /// Discards a specific stash without restoring it (user decided they no
    /// longer need that interrupted draft).
    func discardStash(_ stash: StashedDraft, for chatId: String) {
        stashes[chatId]?.removeAll { $0.id == stash.id }
    }

    func clearAll(for chatId: String) {
        currentText[chatId] = ""
        currentReplyTarget[chatId] = nil
        stashes[chatId] = []
    }
}
