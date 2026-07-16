import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(KTheme.all) { theme in
                    ThemeSwatch(theme: theme, selected: theme.id == themeManager.current.id) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            themeManager.select(theme)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.current.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ThemeSwatch: View {
    let theme: ThemePalette
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Circle().fill(theme.bubbleMine).frame(width: 18, height: 18)
                    Circle().fill(theme.bubbleTheirs).frame(width: 18, height: 18)
                        .overlay(Circle().stroke(theme.line, lineWidth: 1))
                    Spacer()
                    Image(systemName: theme.previewSymbol)
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 6).fill(theme.surfaceAlt).frame(height: 8)
                    RoundedRectangle(cornerRadius: 6).fill(theme.surfaceAlt).frame(width: 60, height: 8)
                }

                Text(theme.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(selected ? theme.accent : theme.line, lineWidth: selected ? 2 : 1)
                    }
            }
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accent)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
