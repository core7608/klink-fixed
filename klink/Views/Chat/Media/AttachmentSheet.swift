import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct AttachmentOption: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
}

struct AttachmentSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var onPickPhoto: () -> Void
    var onPickVideo: () -> Void
    var onOpenCamera: () -> Void
    var onPickFile: () -> Void

    private var options: [AttachmentOption] {
        [
            AttachmentOption(title: "Camera", systemImage: "camera.fill", tint: Color(hex: 0xef4444), action: onOpenCamera),
            AttachmentOption(title: "Photo", systemImage: "photo.fill", tint: Color(hex: 0x8b5cf6), action: onPickPhoto),
            AttachmentOption(title: "Video", systemImage: "video.fill", tint: Color(hex: 0x3b82f6), action: onPickVideo),
            AttachmentOption(title: "File", systemImage: "doc.fill", tint: Color(hex: 0x0ea5e9), action: onPickFile),
        ]
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(themeManager.current.line).frame(width: 40, height: 5).padding(.top, 8)

            HStack(spacing: 22) {
                ForEach(options) { option in
                    Button {
                        dismiss()
                        option.action()
                    } label: {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(option.tint.opacity(0.15))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Image(systemName: option.systemImage)
                                        .foregroundStyle(option.tint)
                                        .font(.system(size: 22))
                                }
                            Text(option.title)
                                .font(.system(size: 12))
                                .foregroundStyle(themeManager.current.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background(themeManager.current.surface)
        .presentationDetents([.height(160)])
        .presentationDragIndicator(.hidden)
    }
}

struct FilePickerRepresentable: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPicked(url) }
        }
    }
}

struct CameraRepresentable: UIViewControllerRepresentable {
    var onCaptured: (UIImage?, URL?) -> Void // image for photo, URL for video

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCaptured: onCaptured) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCaptured: (UIImage?, URL?) -> Void
        init(onCaptured: @escaping (UIImage?, URL?) -> Void) { self.onCaptured = onCaptured }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onCaptured(image, nil)
            } else if let url = info[.mediaURL] as? URL {
                onCaptured(nil, url)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
