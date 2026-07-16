import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView {
            ChatListView()
                .tabItem { Label("Chats", systemImage: "bubble.left.and.bubble.right.fill") }

            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(themeManager.current.accent)
    }
}
