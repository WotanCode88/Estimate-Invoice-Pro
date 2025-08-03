import SwiftUI

struct EstimateDatesSection: View {
    @Binding var issuedDate: Date
    let invoiceNumberText: String
    @Binding var showIssuedPicker: Bool
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Issued")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("#")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 0) {
                Button(action: { showIssuedPicker = true }) {
                    Text(dateFormatter.string(from: issuedDate))
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Rectangle()
                    .frame(width: 1, height: 40)
                    .foregroundColor(Color.gray.opacity(0.3))
                Text(invoiceNumberText)
                    .font(.body)
                    .foregroundColor(.black)
                    .padding(.trailing, 8)
                    .frame(width: 50, alignment: .center)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3))
            )
        }
        .frame(width: 340)
        .padding(.top, 24)
    }
}
