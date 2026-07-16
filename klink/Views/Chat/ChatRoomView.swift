import SwiftUI
import PhotosUI

struct ChatRoomView: View {
    let chatId: String
    let selfUid: String
    @StateObject private var vm: MessagesViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var draftStore: DraftStore
    @EnvironmentObject var security: SecurityService
    @StateObject private var recorder = VoiceRecorderService()

    @State private var showAttachments = false
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var showCamera = false
    @State private var showFilePicker = false
    @State private var uploading = false
    @FocusState private var inputFocused: Bool

    init(chatId: String, selfUid: String) {
        self.chatId = chatId
        self.selfUid = selfUid
        _vm = StateObject(wrappedValue: MessagesViewModel(chatId: chatId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if security.screenshotDetected {
                screenshotBanner
            }

            messageList

            if recorder.isRecording {
                recordingBar
            } else {
                if draftStore.hasStashes(for: chatId) {
                    stashBanner(count: draftStore.stashCount(for: chatId))
                }
                if let replyTarget = draftStore.replyTarget(for: chatId) {
                    replyPreviewBar(replyTarget)
                }
                inputBar
            }
        }
        .background(themeManager.current.background)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.subscribe() }
        .onDisappear { vm.stop() }
        .sheet(isPresented: $showAttachments) {
            AttachmentSheet(
                onPickPhoto: { showPhotoPicker = true },
                onPickVideo: { showVideoPicker = true },
                onOpenCamera: { showCamera = true },
                onPickFile: { showFilePicker = true }
            )
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraRepresentable { image, videoURL in
                showCamera = false
                if let image {
                    Task { await sendImage(image) }
                } else if let videoURL {
                    Task { await sendVideo(url: videoURL) }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilePicker) {
            FilePickerRepresentable { url in
                Task { await sendFile(url: url) }
            }
        }
        .overlay {
            // Hidden pickers for photo/video use the PhotosPicker wrapper
            // below since .photosPicker(selection:) needs a real binding.
            PhotoVideoPickerBridge(
                showPhoto: $showPhotoPicker,
                showVideo: $showVideoPicker,
                onImage: { data in Task { await sendImageData(data) } },
                onVideo: { data in Task { await sendVideoData(data) } }
            )
            .frame(width: 0, height: 0)
        }
    }

    // MARK: Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.messages) { message in
                        MessageRow(
                            message: message,
                            isMine: message.senderId == selfUid,
                            onDelete: { Task { await vm.delete(messageId: message.id) } },
                            onReply: {
                                // If the user is mid-compose and wants to reply
                                // to another message, stash the current draft
                                // first so nothing is lost.
                                let hasDraft = !draftStore.text(for: chatId)
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                                if hasDraft {
                                    _ = draftStore.stashCurrentDraft(for: chatId)
                                }
                                draftStore.setReplyTarget(message, for: chatId)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(12)
            }
            .onChange(of: vm.messages.count) { _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: Screenshot banner

    private var screenshotBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "camera.viewfinder")
            Text("A screenshot was taken of this chat")
                .font(.caption)
        }
        .foregroundStyle(themeManager.current.accentForeground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(themeManager.current.accent)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: The stashed-draft banner — the standout feature

    private func stashBanner(count: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                draftStore.restoreLastStash(for: chatId)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.up.fill")
                    .foregroundStyle(themeManager.current.accent)
                Text(count > 1 ? "You have \(count) stashed drafts — tap to return" : "You have a stashed draft — tap to return")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(themeManager.current.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.circle.fill")
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(themeManager.current.surfaceAlt)
    }

    // MARK: Reply preview bar

    private func replyPreviewBar(_ target: Message) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(themeManager.current.accent).frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(target.senderId == selfUid ? "You" : "Replying to a message")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(themeManager.current.accent)
                Text(target.type == "text" ? (target.text ?? "") : previewLabel(target))
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.current.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                draftStore.setReplyTarget(nil, for: chatId)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(themeManager.current.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.current.surfaceAlt)
    }

    private func previewLabel(_ message: Message) -> String {
        switch message.type {
        case "image": return "📷 Photo"
        case "video": return "🎥 Video"
        case "audio": return "🎤 Voice message"
        case "file": return "📎 File"
        default: return message.text ?? ""
        }
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                showAttachments = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(themeManager.current.textSecondary)
            }

            TextField(
                "Type a message...",
                text: Binding(
                    get: { draftStore.text(for: chatId) },
                    set: { draftStore.setText($0, for: chatId) }
                ),
                axis: .vertical
            )
            .focused($inputFocused)
            .lineLimit(1...4)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(themeManager.current.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(themeManager.current.line, lineWidth: 1)
                    }
            }

            let hasText = !draftStore.text(for: chatId).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Stash the current draft so the user can reply to a new
            // incoming message without losing the long text they were
            // already writing — the standout "pending drafts" feature.
            if hasText {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        _ = draftStore.stashCurrentDraft(for: chatId)
                    }
                } label: {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .accessibilityLabel("Message caption")

                Button {
                    sendCurrentDraft()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(themeManager.current.accent))
                        .foregroundStyle(themeManager.current.accentForeground)
                }
            } else {
                Button {
                    Task {
                        let started = await recorder.requestPermissionAndStart()
                        if !started {
                            // Could surface a permission-denied alert here.
                        }
                    }
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(themeManager.current.accent))
                        .foregroundStyle(themeManager.current.accentForeground)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(themeManager.current.surface)
    }

    private var recordingBar: some View {
        HStack(spacing: 12) {
            Circle().fill(Color.red).frame(width: 10, height: 10)
                .opacity(recorder.elapsed.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0.3)
            Text(formatElapsed(recorder.elapsed))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(themeManager.current.textPrimary)

            Spacer()

            Button {
                recorder.cancel()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(themeManager.current.danger)
            }

            Button {
                if let result = recorder.stopAndFinish() {
                    Task { await sendVoice(url: result.url, duration: result.duration) }
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(themeManager.current.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.current.surface)
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: Send actions

    private func sendCurrentDraft() {
        let text = draftStore.text(for: chatId)
        let replyTarget = draftStore.replyTarget(for: chatId)
        draftStore.setText("", for: chatId)
        draftStore.setReplyTarget(nil, for: chatId)
        Task { await vm.send(text: text, senderId: selfUid, replyTo: replyTarget) }
    }

    private func sendImage(_ image: UIImage) async {
        uploading = true
        defer { uploading = false }
        if let uploaded = try? await MediaService.shared.uploadImage(image, chatId: chatId) {
            let replyTarget = draftStore.replyTarget(for: chatId)
            draftStore.setReplyTarget(nil, for: chatId)
            await vm.sendMedia(uploaded, kind: .image, senderId: selfUid, replyTo: replyTarget)
        }
    }

    private func sendImageData(_ data: Data) async {
        guard let image = UIImage(data: data) else { return }
        await sendImage(image)
    }

    private func sendVideo(url: URL) async {
        guard let data = try? Data(contentsOf: url) else { return }
        await sendVideoDataInternal(data, fileName: url.lastPathComponent)
    }

    private func sendVideoData(_ data: Data) async {
        await sendVideoDataInternal(data, fileName: "video.mov")
    }

    private func sendVideoDataInternal(_ data: Data, fileName: String) async {
        uploading = true
        defer { uploading = false }
        if let uploaded = try? await MediaService.shared.upload(
            data: data, kind: .video, chatId: chatId, fileName: fileName, contentType: "video/quicktime"
        ) {
            let replyTarget = draftStore.replyTarget(for: chatId)
            draftStore.setReplyTarget(nil, for: chatId)
            await vm.sendMedia(uploaded, kind: .video, senderId: selfUid, replyTo: replyTarget)
        }
    }

    private func sendFile(url: URL) async {
        guard let data = try? Data(contentsOf: url) else { return }
        uploading = true
        defer { uploading = false }
        if let uploaded = try? await MediaService.shared.upload(
            data: data, kind: .file, chatId: chatId,
            fileName: url.lastPathComponent, contentType: "application/octet-stream"
        ) {
            let replyTarget = draftStore.replyTarget(for: chatId)
            draftStore.setReplyTarget(nil, for: chatId)
            await vm.sendMedia(uploaded, kind: .file, senderId: selfUid, replyTo: replyTarget)
        }
    }

    private func sendVoice(url: URL, duration: TimeInterval) async {
        guard let data = try? Data(contentsOf: url) else { return }
        uploading = true
        defer { uploading = false }
        if let uploaded = try? await MediaService.shared.upload(
            data: data, kind: .audio, chatId: chatId,
            fileName: "voice.m4a", contentType: "audio/m4a", durationSeconds: duration
        ) {
            await vm.sendMedia(uploaded, kind: .audio, senderId: selfUid)
        }
        try? FileManager.default.removeItem(at: url)
    }
}

private struct MessageRow: View {
    let message: Message
    let isMine: Bool
    let onDelete: () -> Void
    let onReply: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                if let replyText = message.replyToText, message.type != "deleted" {
                    HStack(spacing: 4) {
                        Rectangle().fill(themeManager.current.accent.opacity(0.5)).frame(width: 2, height: 14)
                        Text(replyText)
                            .font(.system(size: 11))
                            .foregroundStyle(themeManager.current.textSecondary)
                            .lineLimit(1)
                    }
                }

                Group {
                    if message.type == "deleted" {
                        bubble {
                            Text("This message was deleted")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundStyle(themeManager.current.textSecondary)
                        }
                    } else {
                        bubble {
                            MediaMessageContent(message: message, isMine: isMine)
                        }
                    }
                }
                .contextMenu {
                    if message.type != "deleted" {
                        Button(action: onReply) {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                    }
                    if isMine && message.type != "deleted" {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Message", systemImage: "trash")
                        }
                    }
                }
            }

            if !isMine { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private func bubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        content()
            .padding(message.type == "text" || message.type == "deleted" ? 12 : 4)
            .background {
                shape.fill(isMine ? themeManager.current.bubbleMine : themeManager.current.bubbleTheirs)
                    .overlay {
                        if !isMine {
                            shape.strokeBorder(themeManager.current.line, lineWidth: 1)
                        }
                    }
            }
            .foregroundStyle(isMine ? themeManager.current.bubbleMineText : themeManager.current.bubbleTheirsText)
            .clipShape(shape)
    }
}

/// Bridges PhotosPicker (which needs a real Binding<PhotosPickerItem?>) into
/// simple boolean sheet-trigger flags used elsewhere in ChatRoomView.
private struct PhotoVideoPickerBridge: View {
    @Binding var showPhoto: Bool
    @Binding var showVideo: Bool
    var onImage: (Data) -> Void
    var onVideo: (Data) -> Void

    @State private var photoSelection: PhotosPickerItem?
    @State private var videoSelection: PhotosPickerItem?

    var body: some View {
        Color.clear
            .photosPicker(isPresented: $showPhoto, selection: $photoSelection, matching: .images)
            .photosPicker(isPresented: $showVideo, selection: $videoSelection, matching: .videos)
            .onChange(of: photoSelection) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        onImage(data)
                    }
                    photoSelection = nil
                }
            }
            .onChange(of: videoSelection) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        onVideo(data)
                    }
                    videoSelection = nil
                }
            }
    }
}
