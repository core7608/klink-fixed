import SwiftUI

// MARK: - Liquid Glass
//
// This targets the real Liquid Glass material introduced in iOS 26 /
// Xcode 26 (`.glassEffect()`, `GlassEffectContainer`). Codemagic builds this
// project with the latest available Xcode image, so the modern API is safe
// to use directly (unlike the earlier Capacitor build on an older local
// Xcode, where it wasn't available).
//
// A graceful `.ultraThinMaterial`-based fallback is kept behind
// `#available` checks so the app still runs correctly on older iOS versions
// at runtime, even though it's built with a new SDK.

// MARK: Screen background

struct KScreenBackground: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.background(KColor.background(scheme).ignoresSafeArea())
    }
}

extension View {
    func kScreenBackground() -> some View {
        modifier(KScreenBackground())
    }
}

// MARK: Glass chrome (tab bar / nav bar)

struct KGlassChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.visible, for: .tabBar, .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar, .navigationBar)
    }
}

extension View {
    func kGlassChrome() -> some View {
        modifier(KGlassChrome())
    }
}

// MARK: Glass surface (cards, bars, sheets)

struct KGlassSurface: ViewModifier {
    var corner: CGFloat = KRadius.lg
    var tinted: Bool = false
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        Group {
            if #available(iOS 26.0, *) {
                content.background {
                    shape.fill(.clear).glassEffect(
                        tinted
                            ? .regular.tint(scheme == .dark ? KColor.softBlack100 : KColor.coldWhite50).interactive()
                            : .regular.interactive(),
                        in: shape
                    )
                }
            } else {
                content.background {
                    shape
                        .fill(.ultraThinMaterial)
                        .overlay {
                            shape.strokeBorder(KColor.line.opacity(scheme == .dark ? 0.15 : 0.6), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
                }
            }
        }
    }
}

extension View {
    func kGlassSurface(corner: CGFloat = KRadius.lg, tinted: Bool = false) -> some View {
        modifier(KGlassSurface(corner: corner, tinted: tinted))
    }
}

// MARK: Glass card

struct GlassCard<Content: View>: View {
    var corner: CGFloat = KRadius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding()
            .kGlassSurface(corner: corner)
    }
}

// MARK: Buttons

struct KButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: KRadius.md, style: .continuous)
        Group {
            if prominent {
                configuration.label
                    .font(KFont.title(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(minHeight: 46)
                    .background(shape.fill(scheme == .dark ? KColor.coldWhite : KColor.softBlack))
                    .foregroundStyle(scheme == .dark ? KColor.softBlack : KColor.coldWhite)
            } else if #available(iOS 26.0, *) {
                configuration.label
                    .font(KFont.title(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(minHeight: 46)
                    .background {
                        shape.fill(.clear).glassEffect(.regular.interactive(), in: shape)
                    }
                    .foregroundStyle(KColor.foreground(scheme))
            } else {
                configuration.label
                    .font(KFont.title(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(minHeight: 46)
                    .background {
                        shape.fill(.ultraThinMaterial)
                            .overlay { shape.strokeBorder(KColor.line, lineWidth: 1) }
                    }
                    .foregroundStyle(KColor.foreground(scheme))
            }
        }
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.25), value: configuration.isPressed)
    }
}

// MARK: Message bubbles

struct GlassBubble<Content: View>: View {
    var isMine: Bool
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        content()
            .padding(12)
            .background {
                if isMine {
                    shape.fill(scheme == .dark ? KColor.coldWhite : KColor.bubbleMine)
                } else if #available(iOS 26.0, *) {
                    shape.fill(.clear).glassEffect(.regular, in: shape)
                } else {
                    shape.fill(scheme == .dark ? KColor.softBlack100 : KColor.bubbleTheirs)
                        .overlay { shape.strokeBorder(KColor.line, lineWidth: 1) }
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                }
            }
            .foregroundStyle(
                isMine
                    ? (scheme == .dark ? KColor.softBlack : KColor.coldWhite)
                    : KColor.foreground(scheme)
            )
    }
}

// MARK: Floating glass pill (filters, tags)

struct KPill: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KFont.caption())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule().fill(selected ? KColor.softBlack : KColor.coldWhite100)
                }
                .foregroundStyle(selected ? KColor.coldWhite : KColor.muted)
        }
        .buttonStyle(.plain)
    }
}
