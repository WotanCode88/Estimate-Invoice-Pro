import SwiftUI

struct ClientLogoView: View {
    let name: String

    var initials: String {
        let components = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let second = components[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return ""
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(UIColor.systemGray5))
                .frame(width: 38, height: 38)
            Text(initials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.black)
        }
    }
}
