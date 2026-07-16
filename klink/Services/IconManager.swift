import UIKit
import SwiftUI

// MARK: - IconManager
// Wraps UIApplication's alternate-icon API. The 17 icon variants are
// declared in Info.plist under CFBundleIcons / CFBundleAlternateIcons; the
// primary AppIcon (asset catalog) is icon id `nil`.

struct AppIconOption: Identifiable, Equatable {
    var id: String  // "primary" for the default icon, otherwise the CFBundleAlternateIcons key
    var displayName: String
    /// File name (without extension) of the loose 60pt PNG bundled under
    /// AlternateIcons/<id>/ used to render a preview thumbnail in the
    /// picker. For the primary icon this points at a copy of the main
    /// AppIcon art bundled the same way for a consistent preview API.
    var previewFileName: String

    func previewImage() -> UIImage? {
        // Previews live under AlternateIcons/Previews/ (folder resource).
        // Fall back to the sized icon folders and a root search so a missing
        // preview file never crashes the picker.
        let candidates: [String?] = [
            Bundle.main.path(forResource: previewFileName, ofType: "png", inDirectory: "AlternateIcons/Previews"),
            Bundle.main.path(forResource: previewFileName, ofType: "png", inDirectory: "Previews"),
            Bundle.main.path(forResource: previewFileName, ofType: "png"),
        ]
        for path in candidates {
            if let path, let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}

@MainActor
final class IconManager: ObservableObject {
    static let shared = IconManager()

    @Published private(set) var currentIconId: String?

    let options: [AppIconOption] = [
        AppIconOption(id: "primary", displayName: "Default (Black)", previewFileName: "AppIcon-Primary-60"),
        AppIconOption(id: "AppIcon-ColdWhite", displayName: "Cold White", previewFileName: "AppIcon-ColdWhite-60"),
        AppIconOption(id: "AppIcon-Midnight", displayName: "Midnight", previewFileName: "AppIcon-Midnight-60"),
        AppIconOption(id: "AppIcon-Ocean", displayName: "Ocean", previewFileName: "AppIcon-Ocean-60"),
        AppIconOption(id: "AppIcon-Forest", displayName: "Forest", previewFileName: "AppIcon-Forest-60"),
        AppIconOption(id: "AppIcon-Sunset", displayName: "Sunset", previewFileName: "AppIcon-Sunset-60"),
        AppIconOption(id: "AppIcon-Rose", displayName: "Rose", previewFileName: "AppIcon-Rose-60"),
        AppIconOption(id: "AppIcon-Grape", displayName: "Grape", previewFileName: "AppIcon-Grape-60"),
        AppIconOption(id: "AppIcon-Outline", displayName: "Outline", previewFileName: "AppIcon-Outline-60"),
        AppIconOption(id: "AppIcon-Neon", displayName: "Neon", previewFileName: "AppIcon-Neon-60"),
        AppIconOption(id: "AppIcon-Mint", displayName: "Mint", previewFileName: "AppIcon-Mint-60"),
        AppIconOption(id: "AppIcon-Sand", displayName: "Sand", previewFileName: "AppIcon-Sand-60"),
        AppIconOption(id: "AppIcon-Steel", displayName: "Steel", previewFileName: "AppIcon-Steel-60"),
        AppIconOption(id: "AppIcon-Ember", displayName: "Ember", previewFileName: "AppIcon-Ember-60"),
        AppIconOption(id: "AppIcon-Sky", displayName: "Sky", previewFileName: "AppIcon-Sky-60"),
        AppIconOption(id: "AppIcon-Noir", displayName: "Noir", previewFileName: "AppIcon-Noir-60"),
        AppIconOption(id: "AppIcon-Multicolor", displayName: "Multicolor", previewFileName: "AppIcon-Multicolor-60"),
    ]

    private init() {
        currentIconId = UIApplication.shared.alternateIconName ?? "primary"
    }

    func select(_ option: AppIconOption) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let target = option.id == "primary" ? nil : option.id
        guard target != UIApplication.shared.alternateIconName else { return }

        UIApplication.shared.setAlternateIconName(target) { [weak self] error in
            Task { @MainActor in
                if error == nil {
                    self?.currentIconId = option.id
                }
            }
        }
    }
}
