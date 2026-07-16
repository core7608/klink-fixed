import SwiftUI

enum KAvatarHelpers {
    static func initials(_ name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .filter { !$0.isEmpty }
        if parts.isEmpty { return "?" }
        if parts.count == 1 { return String(parts[0].prefix(2)).uppercased() }
        let first = parts[0].first.map(String.init) ?? ""
        let second = parts[1].first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private static let palette: [Color] = [
        Color(hex: 0x1f2937), Color(hex: 0x374151), Color(hex: 0x111827), Color(hex: 0x4b5563),
        Color(hex: 0x0f172a), Color(hex: 0x1e293b), Color(hex: 0x334155), Color(hex: 0x020617),
    ]

    static func color(for seed: String) -> Color {
        var h: UInt32 = 0
        for scalar in seed.unicodeScalars {
            h = (h &* 31 &+ scalar.value)
        }
        return palette[Int(h % UInt32(palette.count))]
    }
}

struct KAvatar: View {
    var name: String
    var photoURL: String?
    var size: CGFloat = 48
    var verified: Bool = false
    var online: Bool = false

    private var fontSize: CGFloat { size * 0.34 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            initialsCircle
                        }
                    }
                } else {
                    initialsCircle
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay { Circle().stroke(KColor.coldWhite, lineWidth: 2) }

            if online {
                Circle()
                    .fill(KColor.success)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .overlay { Circle().stroke(KColor.coldWhite, lineWidth: 2) }
                    .offset(x: -1, y: 1)
            }

            if verified {
                Image(systemName: "checkmark.seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.32, height: size * 0.32)
                    .foregroundStyle(Color(hex: 0x0ea5e9))
                    .background(Circle().fill(KColor.coldWhite).padding(1))
                    .offset(x: -1, y: 1)
            }
        }
    }

    private var initialsCircle: some View {
        KAvatarHelpers.color(for: name.isEmpty ? "?" : name)
            .overlay {
                Text(KAvatarHelpers.initials(name))
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(KColor.coldWhite)
            }
    }
}

enum KTimeFormat {
    static func messageTime(_ epochMillis: Double?) -> String {
        guard let epochMillis, epochMillis > 0 else { return "" }
        let date = Date(timeIntervalSince1970: epochMillis / 1000)
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()),
           weekInterval.contains(date) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US")
            f.dateFormat = "EEEE"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = "d/M/yyyy"
        return f.string(from: date)
    }
}
