import SwiftUI

// MARK: - Theme system
//
// A theme is a complete palette — background, surface, accent, bubble
// colors, text — swappable at runtime without restarting the app. All
// views read colors through `theme.colors` (via ThemeManager as an
// EnvironmentObject) instead of the static KColor tokens, so switching
// a theme repaints the whole app immediately.

struct ThemePalette: Identifiable, Equatable {
    var id: String
    var name: String
    /// SF Symbol used as the little swatch preview dot / icon in the picker.
    var previewSymbol: String

    var background: Color
    var surface: Color
    var surfaceAlt: Color
    var accent: Color
    var accentForeground: Color
    var textPrimary: Color
    var textSecondary: Color
    var line: Color
    var bubbleMine: Color
    var bubbleMineText: Color
    var bubbleTheirs: Color
    var bubbleTheirsText: Color
    var isDark: Bool
    /// Semantic colors shared across themes (error / destructive actions).
    var danger: Color
    var success: Color
}

enum KTheme {
    static let classic = ThemePalette(
        id: "classic",
        name: "Classic",
        previewSymbol: "circle.fill",
        background: Color(hex: 0xf7f8fa),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xf2f4f7),
        accent: Color(hex: 0x121417),
        accentForeground: Color(hex: 0xf7f8fa),
        textPrimary: Color(hex: 0x121417),
        textSecondary: Color(hex: 0x6b7280),
        line: Color(hex: 0xe5e7eb),
        bubbleMine: Color(hex: 0x121417),
        bubbleMineText: Color(hex: 0xf7f8fa),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x121417),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let midnight = ThemePalette(
        id: "midnight",
        name: "Midnight",
        previewSymbol: "moon.stars.fill",
        background: Color(hex: 0x0a0a0d),
        surface: Color(hex: 0x16161c),
        surfaceAlt: Color(hex: 0x1e1e26),
        accent: Color(hex: 0x6366f1),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0xf2f2f5),
        textSecondary: Color(hex: 0x9497a6),
        line: Color(hex: 0x2a2a35),
        bubbleMine: Color(hex: 0x6366f1),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0x1e1e26),
        bubbleTheirsText: Color(hex: 0xf2f2f5),
        isDark: true,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let ocean = ThemePalette(
        id: "ocean",
        name: "Ocean",
        previewSymbol: "water.waves",
        background: Color(hex: 0xf0f7fb),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xe3f0f7),
        accent: Color(hex: 0x0369a1),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x0c2f3f),
        textSecondary: Color(hex: 0x4b7d94),
        line: Color(hex: 0xcfe6ef),
        bubbleMine: Color(hex: 0x0369a1),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x0c2f3f),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let forest = ThemePalette(
        id: "forest",
        name: "Forest",
        previewSymbol: "leaf.fill",
        background: Color(hex: 0xf3f7f2),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xe6efe3),
        accent: Color(hex: 0x15803d),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x142012),
        textSecondary: Color(hex: 0x577a52),
        line: Color(hex: 0xd6e6d1),
        bubbleMine: Color(hex: 0x15803d),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x142012),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let sunset = ThemePalette(
        id: "sunset",
        name: "Sunset",
        previewSymbol: "sun.horizon.fill",
        background: Color(hex: 0xfff6f0),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xffe9dc),
        accent: Color(hex: 0xea580c),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x2b1608),
        textSecondary: Color(hex: 0x8a5c40),
        line: Color(hex: 0xffdcc4),
        bubbleMine: Color(hex: 0xea580c),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x2b1608),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let rose = ThemePalette(
        id: "rose",
        name: "Rose",
        previewSymbol: "heart.fill",
        background: Color(hex: 0xfff5f7),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xffe4ea),
        accent: Color(hex: 0xe11d48),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x2c0a13),
        textSecondary: Color(hex: 0x93586a),
        line: Color(hex: 0xffd3dd),
        bubbleMine: Color(hex: 0xe11d48),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x2c0a13),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let grape = ThemePalette(
        id: "grape",
        name: "Grape",
        previewSymbol: "sparkles",
        background: Color(hex: 0x120a1a),
        surface: Color(hex: 0x1e1229),
        surfaceAlt: Color(hex: 0x281733),
        accent: Color(hex: 0xa855f7),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0xf3ecfa),
        textSecondary: Color(hex: 0xb69fcb),
        line: Color(hex: 0x352441),
        bubbleMine: Color(hex: 0xa855f7),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0x281733),
        bubbleTheirsText: Color(hex: 0xf3ecfa),
        isDark: true,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let sand = ThemePalette(
        id: "sand",
        name: "Sand",
        previewSymbol: "circle.hexagongrid.fill",
        background: Color(hex: 0xfaf6ee),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xf1e8d5),
        accent: Color(hex: 0x92400e),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x2b2013),
        textSecondary: Color(hex: 0x8a7754),
        line: Color(hex: 0xe6d8b8),
        bubbleMine: Color(hex: 0x92400e),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x2b2013),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let steel = ThemePalette(
        id: "steel",
        name: "Steel",
        previewSymbol: "gearshape.fill",
        background: Color(hex: 0x14171a),
        surface: Color(hex: 0x1e2226),
        surfaceAlt: Color(hex: 0x272c31),
        accent: Color(hex: 0x38bdf8),
        accentForeground: Color(hex: 0x0a0f14),
        textPrimary: Color(hex: 0xeef2f5),
        textSecondary: Color(hex: 0x93a1ab),
        line: Color(hex: 0x323a41),
        bubbleMine: Color(hex: 0x38bdf8),
        bubbleMineText: Color(hex: 0x0a0f14),
        bubbleTheirs: Color(hex: 0x272c31),
        bubbleTheirsText: Color(hex: 0xeef2f5),
        isDark: true,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let mint = ThemePalette(
        id: "mint",
        name: "Mint",
        previewSymbol: "leaf.circle.fill",
        background: Color(hex: 0xf0faf6),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xdcf5e9),
        accent: Color(hex: 0x0d9488),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x0a2620),
        textSecondary: Color(hex: 0x4f8a7c),
        line: Color(hex: 0xc7ecdf),
        bubbleMine: Color(hex: 0x0d9488),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x0a2620),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let ember = ThemePalette(
        id: "ember",
        name: "Ember",
        previewSymbol: "flame.fill",
        background: Color(hex: 0x180b0a),
        surface: Color(hex: 0x241211),
        surfaceAlt: Color(hex: 0x301815),
        accent: Color(hex: 0xf97316),
        accentForeground: Color(hex: 0x180b0a),
        textPrimary: Color(hex: 0xfaeee9),
        textSecondary: Color(hex: 0xc99c8c),
        line: Color(hex: 0x3d211d),
        bubbleMine: Color(hex: 0xf97316),
        bubbleMineText: Color(hex: 0x180b0a),
        bubbleTheirs: Color(hex: 0x301815),
        bubbleTheirsText: Color(hex: 0xfaeee9),
        isDark: true,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let sky = ThemePalette(
        id: "sky",
        name: "Sky",
        previewSymbol: "cloud.sun.fill",
        background: Color(hex: 0xf0f9ff),
        surface: Color(hex: 0xffffff),
        surfaceAlt: Color(hex: 0xdff1fc),
        accent: Color(hex: 0x2563eb),
        accentForeground: Color(hex: 0xffffff),
        textPrimary: Color(hex: 0x0b1c33),
        textSecondary: Color(hex: 0x5a7599),
        line: Color(hex: 0xcde3f7),
        bubbleMine: Color(hex: 0x2563eb),
        bubbleMineText: Color(hex: 0xffffff),
        bubbleTheirs: Color(hex: 0xffffff),
        bubbleTheirsText: Color(hex: 0x0b1c33),
        isDark: false,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let noir = ThemePalette(
        id: "noir",
        name: "Noir",
        previewSymbol: "circle.lefthalf.filled",
        background: Color(hex: 0x000000),
        surface: Color(hex: 0x0d0d0d),
        surfaceAlt: Color(hex: 0x181818),
        accent: Color(hex: 0xffffff),
        accentForeground: Color(hex: 0x000000),
        textPrimary: Color(hex: 0xffffff),
        textSecondary: Color(hex: 0x8e8e8e),
        line: Color(hex: 0x232323),
        bubbleMine: Color(hex: 0xffffff),
        bubbleMineText: Color(hex: 0x000000),
        bubbleTheirs: Color(hex: 0x181818),
        bubbleTheirsText: Color(hex: 0xffffff),
        isDark: true,
        danger: Color(hex: 0xdc2626),
        success: Color(hex: 0x16a34a)
    )

    static let all: [ThemePalette] = [
        classic, midnight, ocean, forest, sunset, rose,
        grape, sand, steel, mint, ember, sky, noir,
    ]
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var current: ThemePalette
    private let storageKey = "klink.theme.id"

    private init() {
        let savedId = UserDefaults.standard.string(forKey: storageKey)
        current = KTheme.all.first(where: { $0.id == savedId }) ?? KTheme.classic
    }

    func select(_ theme: ThemePalette) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: storageKey)
    }

    var colorScheme: ColorScheme {
        current.isDark ? .dark : .light
    }
}
