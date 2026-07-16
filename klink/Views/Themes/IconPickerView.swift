import SwiftUI

struct IconPickerView: View {
    @EnvironmentObject var iconManager: IconManager
    @EnvironmentObject var themeManager: ThemeManager
    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 14)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(iconManager.options) { option in
                    IconSwatch(
                        option: option,
                        selected: option.id == (iconManager.currentIconId ?? "primary")
                    ) {
                        iconManager.select(option)
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.current.background)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct IconSwatch: View {
    let option: AppIconOption
    let selected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let uiImage = option.previewImage() {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(selected ? themeManager.current.accent : Color.clear, lineWidth: 2.5)
                }

                Text(option.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(themeManager.current.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
    }
}
