import SwiftUI

// MARK: - LandingView
//
// The page shown after LaunchView and before AuthScreen — a marketing-style
// animated intro, choreographed the way a GSAP timeline would be on the web:
//  1. Background ambient shapes drift continuously (infinite, subtle).
//  2. The logo mark pops in with a back-out overshoot.
//  3. The headline reveals word-by-word with a staggered power3-out slide+fade.
//  4. Three feature rows cascade in with a stagger.
//  5. The CTA button arrives last with a back-out pop.
//
// Tapping "Get Started" hands off to AuthScreen via onContinue.

struct LandingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var onContinue: () -> Void

    @State private var showLogo = false
    @State private var headlineWordsShown = 0
    @State private var showFeatures = [false, false, false]
    @State private var showCTA = false
    @State private var orbDrift = false

    private let headlineWords = ["Your", "conversations.", "Faster.", "Clearer.", "More", "yours."]

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("bolt.fill", "Instant speed", "Messages and calls with no noticeable delay"),
        ("lock.fill", "Real security", "Biometric lock, encryption, and full control over your privacy"),
        ("paintpalette.fill", "A look that's truly yours", "13 themes and 17 icons you can switch between freely"),
    ]

    var body: some View {
        ZStack {
            themeManager.current.background.ignoresSafeArea()
            backgroundOrbs

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                logoMark
                    .padding(.bottom, 28)

                headline
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)

                VStack(spacing: 14) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureRow(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
                            .opacity(showFeatures[index] ? 1 : 0)
                            .offset(x: showFeatures[index] ? 0 : 24)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                        Image(systemName: "arrow.left")
                    }
                    .font(KFont.title(16))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(KButtonStyle(prominent: true))
                .padding(.horizontal, 24)
                .opacity(showCTA ? 1 : 0)
                .scaleEffect(showCTA ? 1 : 0.85)

                Button(action: onContinue) {
                    Text("Skip")
                        .font(.footnote)
                        .foregroundStyle(themeManager.current.textSecondary)
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
                .opacity(showCTA ? 1 : 0)
            }
        }
        .onAppear { runTimeline() }
    }

    // MARK: Background ambient motion

    private var backgroundOrbs: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(themeManager.current.accent.opacity(0.18))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 60)
                    .offset(
                        x: orbDrift ? geo.size.width * 0.15 : -geo.size.width * 0.1,
                        y: orbDrift ? -geo.size.height * 0.05 : geo.size.height * 0.05
                    )
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.18)

                Circle()
                    .fill(themeManager.current.accent.opacity(0.12))
                    .frame(width: geo.size.width * 0.55)
                    .blur(radius: 70)
                    .offset(
                        x: orbDrift ? -geo.size.width * 0.1 : geo.size.width * 0.12,
                        y: orbDrift ? geo.size.height * 0.06 : -geo.size.height * 0.04
                    )
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.75)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                orbDrift = true
            }
        }
    }

    // MARK: Logo

    private var logoMark: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(themeManager.current.accent)
            .frame(width: 76, height: 76)
            .overlay {
                Text("k")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(themeManager.current.accentForeground)
            }
            .shadow(color: themeManager.current.accent.opacity(0.3), radius: 20, y: 8)
            .scaleEffect(showLogo ? 1 : 0.4)
            .opacity(showLogo ? 1 : 0)
    }

    // MARK: Headline — word-by-word stagger

    private var headline: some View {
        // Wrap manually so each word can animate independently (Text
        // concatenation doesn't support per-word transforms).
        FlowLayout(spacing: 8) {
            ForEach(Array(headlineWords.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(KFont.title(30))
                    .foregroundStyle(themeManager.current.textPrimary)
                    .opacity(index < headlineWordsShown ? 1 : 0)
                    .offset(y: index < headlineWordsShown ? 0 : 14)
                    .blur(radius: index < headlineWordsShown ? 0 : 6)
            }
        }
    }

    // MARK: Timeline sequencing (the GSAP-timeline equivalent)

    private func runTimeline() {
        withAnimation(.gsapBackOut(duration: 0.65)) {
            showLogo = true
        }

        for index in headlineWords.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 + Stagger.delay(index: index, base: 0.12)) {
                withAnimation(.gsapPower3Out(duration: 0.5)) {
                    headlineWordsShown = index + 1
                }
            }
        }

        let featuresStart = 0.35 + Double(headlineWords.count) * 0.12 + 0.25
        for index in features.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + featuresStart + Stagger.delay(index: index, base: 0.15)) {
                withAnimation(.gsapPower2Out(duration: 0.5)) {
                    showFeatures[index] = true
                }
            }
        }

        let ctaStart = featuresStart + Double(features.count) * 0.15 + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + ctaStart) {
            withAnimation(.gsapBackOut(duration: 0.55)) {
                showCTA = true
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(themeManager.current.accent.opacity(0.14))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .foregroundStyle(themeManager.current.accent)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.current.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.current.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeManager.current.surface)
        }
    }
}

/// Minimal RTL-aware flow layout for wrapping headline words naturally,
/// since SwiftUI has no built-in wrapping HStack.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
