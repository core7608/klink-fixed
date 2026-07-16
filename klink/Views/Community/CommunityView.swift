import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.current.textSecondary)
                Text("Community")
                    .font(KFont.title(18))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.current.background)
            .navigationTitle("Community")
        }
    }
}
