import SwiftUI

// MARK: - Design tokens
// Mirrors the web app's src/index.css custom properties exactly, so the
// native app is visually identical to klink on the web.

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

enum KColor {
    static let coldWhite = Color(hex: 0xf7f8fa)
    static let coldWhite50 = Color(hex: 0xffffff)
    static let coldWhite100 = Color(hex: 0xf2f4f7)
    static let coldWhite200 = Color(hex: 0xe8ebf0)
    static let coldWhite300 = Color(hex: 0xd5dae3)

    static let softBlack = Color(hex: 0x121417)
    static let softBlack50 = Color(hex: 0x1a1d21)
    static let softBlack100 = Color(hex: 0x2a2e34)
    static let softBlack200 = Color(hex: 0x3d434c)
    static let softBlack300 = Color(hex: 0x5c6470)

    static let ink = Color(hex: 0x0a0a0a)
    static let muted = Color(hex: 0x6b7280)
    static let line = Color(hex: 0xe5e7eb)
    static let success = Color(hex: 0x16a34a)
    static let danger = Color(hex: 0xdc2626)

    static let bubbleMine = Color(hex: 0x121417)
    static let bubbleTheirs = Color(hex: 0xffffff)

    /// Background that adapts to light/dark automatically.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? softBlack : coldWhite
    }

    static func foreground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? coldWhite : softBlack
    }
}

enum KFont {
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium)
    }
}

enum KRadius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}
