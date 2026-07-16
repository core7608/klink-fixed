import SwiftUI

// MARK: - LaunchView
// The very first thing the user sees on cold start — a short, polished
// branded animation (logo mark draws in, then settles) before handing off
// to the auth-state check. Purely presentational; RootView controls how
// long it stays up and what comes after.

struct LaunchView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.6
    @State private var ringOpacity: Double = 0.6
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            themeManager.current.background.ignoresSafeArea()

            Circle()
                .stroke(themeManager.current.accent.opacity(0.35), lineWidth: 2)
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(themeManager.current.accent)
                    .frame(width: 92, height: 92)
                    .overlay {
                        Text("k")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(themeManager.current.accentForeground)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: themeManager.current.accent.opacity(0.35), radius: 24, y: 10)

                Text("klink")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(themeManager.current.textPrimary)
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                logoScale = 1
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 1.1).delay(0.05)) {
                ringScale = 1.35
                ringOpacity = 0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.35)) {
                taglineOpacity = 1
            }
        }
    }
}
