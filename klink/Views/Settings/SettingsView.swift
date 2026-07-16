import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var security: SecurityService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader

                    GlassCard {
                        VStack(spacing: 0) {
                            NavigationLink {
                                ThemePickerView()
                            } label: {
                                settingsRow(icon: "paintpalette.fill", title: "Appearance", trailing: themeManager.current.name)
                            }
                            Divider().padding(.leading, 44)

                            NavigationLink {
                                IconPickerView()
                            } label: {
                                settingsRow(icon: "app.badge.fill", title: "App Icon", trailing: nil)
                            }
                        }
                    }

                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "faceid")
                                    .foregroundStyle(themeManager.current.accent)
                                    .frame(width: 26)
                                Text("App Lock")
                                    .font(.system(size: 14))
                                    .foregroundStyle(themeManager.current.textPrimary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { security.appLockEnabled },
                                    set: { security.appLockEnabled = $0 }
                                ))
                                .labelsHidden()
                                .tint(themeManager.current.accent)
                            }
                            Text("Requires Face ID or your device passcode to open klink")
                                .font(.caption2)
                                .foregroundStyle(themeManager.current.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GlassCard {
                        Button(role: .destructive) {
                            try? auth.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                Spacer()
                            }
                            .foregroundStyle(KColor.danger)
                        }
                    }
                }
                .padding(16)
            }
            .background(themeManager.current.background)
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func settingsRow(icon: String, title: String, trailing: String?) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(themeManager.current.accent)
                .frame(width: 26)
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(themeManager.current.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            Image(systemName: "chevron.left")
                .font(.caption)
                .foregroundStyle(themeManager.current.textSecondary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var profileHeader: some View {
        GlassCard {
            HStack(spacing: 14) {
                KAvatar(
                    name: auth.user?.displayName ?? "?",
                    photoURL: auth.user?.photoURL,
                    size: 60,
                    verified: auth.user?.isSubscriber == true || auth.user?.isVerifiedOwner == true
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.user?.displayName ?? "No name")
                        .font(KFont.title(17))
                        .foregroundStyle(themeManager.current.textPrimary)
                    if let email = auth.user?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(themeManager.current.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }
}
