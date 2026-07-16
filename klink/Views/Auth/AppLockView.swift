import SwiftUI

struct AppLockView: View {
    @EnvironmentObject var security: SecurityService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var authenticating = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(themeManager.current.accent)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(themeManager.current.accentForeground)
                }

            VStack(spacing: 6) {
                Text("klink is Locked")
                    .font(KFont.title(20))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text("Use Face ID or your device passcode to continue")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
            }

            Button {
                Task { await unlock() }
            } label: {
                HStack {
                    if authenticating { ProgressView().tint(themeManager.current.accentForeground) }
                    Image(systemName: "faceid")
                    Text("Unlock")
                }
                .font(KFont.title(15))
                .frame(maxWidth: 220)
            }
            .buttonStyle(KButtonStyle(prominent: true))
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.current.background.ignoresSafeArea())
        .task { await unlock() }
    }

    private func unlock() async {
        authenticating = true
        _ = await security.authenticate()
        authenticating = false
    }
}
