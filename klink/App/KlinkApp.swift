import SwiftUI
import FirebaseCore
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        // Wire Google Sign-In to the same OAuth client that Firebase Auth
        // expects (CLIENT_ID from GoogleService-Info.plist). Without this,
        // signIn(withPresenting:) fails with a missing-configuration error.
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct KlinkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var draftStore = DraftStore()
    @StateObject private var iconManager = IconManager.shared
    @StateObject private var security = SecurityService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(themeManager)
                .environmentObject(draftStore)
                .environmentObject(iconManager)
                .environmentObject(security)
                .preferredColorScheme(themeManager.colorScheme)
                .background(themeManager.current.background.ignoresSafeArea())
        }
    }
}

/// Top-level flow: Launch (brief branded splash) → Landing (animated
/// marketing intro, first-run only) → Auth → MainTabView. An app-lock
/// overlay can cover any of these except the lock screen itself.
struct RootView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var security: SecurityService
    @EnvironmentObject var themeManager: ThemeManager

    @State private var phase: Phase = .launch
    private let hasSeenLandingKey = "klink.hasSeenLanding"

    enum Phase { case launch, landing, main }

    var body: some View {
        ZStack {
            Group {
                switch phase {
                case .launch:
                    LaunchView()
                case .landing:
                    LandingView(onContinue: goToMain)
                case .main:
                    mainContent
                }
            }

            if security.isLocked && phase == .main {
                AppLockView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .task { await runLaunchSequence() }
    }

    @ViewBuilder
    private var mainContent: some View {
        if auth.loading {
            VStack(spacing: 12) {
                ProgressView()
                Text("klink...")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.current.background)
        } else if auth.user != nil {
            MainTabView()
        } else {
            AuthScreen()
        }
    }

    private func runLaunchSequence() async {
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        let hasSeenLanding = UserDefaults.standard.bool(forKey: hasSeenLandingKey)
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = hasSeenLanding ? .main : .landing
        }
    }

    private func goToMain() {
        UserDefaults.standard.set(true, forKey: hasSeenLandingKey)
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .main
        }
    }
}
