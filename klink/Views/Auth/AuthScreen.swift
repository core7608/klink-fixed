import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var themeManager: ThemeManager

    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var oauthLoading = false
    @State private var errorMessage: String?

    enum Mode { case login, register }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                logo

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome")
                        .font(KFont.title(26))
                        .foregroundStyle(themeManager.current.textPrimary)
                    Text("Sign in with Google or email")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .padding(.top, 8)

                Button {
                    Task { await handleGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        if oauthLoading {
                            ProgressView().tint(themeManager.current.textPrimary)
                        } else {
                            GoogleIcon()
                        }
                        Text("Continue with Google")
                            .font(KFont.title(15))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(KButtonStyle())
                .disabled(oauthLoading)

                HStack(spacing: 12) {
                    Rectangle().fill(themeManager.current.line).frame(height: 1)
                    Text("or").font(.caption).foregroundStyle(themeManager.current.textSecondary)
                    Rectangle().fill(themeManager.current.line).frame(height: 1)
                }
                .padding(.vertical, 4)

                VStack(spacing: 12) {
                    KTextField(placeholder: "Email", text: $email, keyboard: .emailAddress)
                    KSecureField(placeholder: "Password", text: $password)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(themeManager.current.isDark ? Color(hex: 0xf87171) : KColor.danger)
                }

                Button {
                    Task { await handlePassword() }
                } label: {
                    HStack {
                        if loading { ProgressView().tint(themeManager.current.accentForeground) }
                        Text(mode == .login ? "Sign In" : "Create Account")
                            .font(KFont.title(15))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(KButtonStyle(prominent: true))
                .disabled(loading)

                Button {
                    mode = mode == .login ? .register : .login
                } label: {
                    Text(mode == .login ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                        .font(.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .padding(.top, 4)

                Text("By continuing you agree to the Terms of Service")
                    .font(.caption2)
                    .foregroundStyle(themeManager.current.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }
            .padding(20)
        }
        .background(themeManager.current.background)
    }

    private var logo: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.current.accent)
                .frame(width: 40, height: 40)
                .overlay {
                    Text("k")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(themeManager.current.accentForeground)
                }
            Text("klink")
                .font(KFont.title(22))
                .foregroundStyle(themeManager.current.textPrimary)
        }
    }

    private func handleGoogle() async {
        oauthLoading = true
        errorMessage = nil
        defer { oauthLoading = false }
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handlePassword() async {
        guard isValidEmail(email) else {
            errorMessage = "Enter a valid email address"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            if mode == .login {
                try await auth.signIn(email: email, password: password)
            } else {
                try await auth.register(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.contains(".") && value.count > 5
    }
}

private struct KTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboard)
            .autocapitalization(.none)
            .textContentType(.username)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: KRadius.md, style: .continuous)
                    .fill(themeManager.current.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: KRadius.md, style: .continuous)
                            .strokeBorder(themeManager.current.line, lineWidth: 1)
                    }
            }
    }
}

private struct KSecureField: View {
    var placeholder: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        SecureField(placeholder, text: $text)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: KRadius.md, style: .continuous)
                    .fill(themeManager.current.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: KRadius.md, style: .continuous)
                            .strokeBorder(themeManager.current.line, lineWidth: 1)
                    }
            }
    }
}

private struct GoogleIcon: View {
    var body: some View {
        // Simple monochrome-safe "G" mark; avoids bundling Google's brand
        // asset while still reading clearly as the Google button.
        Text("G")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: 0x4285F4), Color(hex: 0xEA4335), Color(hex: 0xFBBC05), Color(hex: 0x34A853)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
