import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    // ChatService is a process-wide singleton; observe it rather than
    // claiming ownership via @StateObject.
    @ObservedObject private var chatService = ChatService.shared
    @State private var query = ""
    @State private var path = NavigationPath()
    @State private var verifiedFlash = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if filtered.isEmpty {
                        emptyState.padding(.top, 64)
                    } else {
                        ForEach(filtered) { chat in
                            Button {
                                path.append(chat.id)
                            } label: {
                                KChatRow(chat: chat, selfUid: auth.user?.uid ?? "")
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 76).foregroundStyle(themeManager.current.line)
                        }
                    }
                }
            }
            .background(themeManager.current.background)
            .searchable(text: $query, prompt: "Search chats")
            .onChange(of: query) { newValue in
                Task {
                    let matched = await VerificationService.checkSearchInput(newValue)
                    if matched {
                        query = ""
                        withAnimation(.gsapBackOut()) { verifiedFlash = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { verifiedFlash = false }
                        }
                        if let uid = auth.user?.uid {
                            auth.user = try? await FirestoreService.shared.fetchUser(uid: uid)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(themeManager.current.accent)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Text("k").font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(themeManager.current.accentForeground)
                            }
                        Text("klink").font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(themeManager.current.textPrimary)
                    }
                }
            }
            .navigationDestination(for: String.self) { chatId in
                ChatRoomView(chatId: chatId, selfUid: auth.user?.uid ?? "")
            }
            .onAppear {
                if let uid = auth.user?.uid {
                    chatService.subscribeChats(uid: uid)
                }
            }
            .overlay(alignment: .top) {
                if verifiedFlash {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Verified")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(themeManager.current.accent, in: Capsule())
                    .foregroundStyle(themeManager.current.accentForeground)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(themeManager.current.surfaceAlt).frame(width: 72, height: 72)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 28))
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            Text("No chats yet")
                .font(KFont.title(17))
                .foregroundStyle(themeManager.current.textPrimary)
            Text("Start a new chat and it'll show up here instantly")
                .font(.subheadline)
                .foregroundStyle(themeManager.current.textSecondary)
        }
    }

    private var filtered: [Chat] {
        guard !query.isEmpty else { return chatService.chats }
        return chatService.chats.filter { chat in
            let name = chat.isGroup ? (chat.name ?? "") : (chat.otherUser?.displayName ?? "")
            return name.localizedCaseInsensitiveContains(query)
        }
    }
}

struct KChatRow: View {
    let chat: Chat
    let selfUid: String
    @EnvironmentObject var themeManager: ThemeManager

    private var title: String {
        if chat.isGroup { return chat.name ?? "Group" }
        return chat.otherUser?.displayName ?? "User"
    }

    private var unread: Int { chat.unread[selfUid] ?? 0 }
    private var verified: Bool {
        !chat.isGroup && (chat.otherUser?.isSubscriber == true || chat.otherUser?.isVerifiedOwner == true)
    }

    var body: some View {
        HStack(spacing: 12) {
            KAvatar(
                name: title,
                photoURL: chat.isGroup ? chat.photoURL : chat.otherUser?.photoURL,
                size: 48,
                verified: verified
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(themeManager.current.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(KTimeFormat.messageTime(chat.lastMessage?.createdAt ?? chat.updatedAt))
                        .font(.system(size: 11))
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                HStack {
                    Text(chat.lastMessage?.text ?? "Start the conversation...")
                        .font(.system(size: 13, weight: unread > 0 ? .medium : .regular))
                        .foregroundStyle(unread > 0 ? themeManager.current.textPrimary : themeManager.current.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 6)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(themeManager.current.accent, in: Capsule())
                            .foregroundStyle(themeManager.current.accentForeground)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
