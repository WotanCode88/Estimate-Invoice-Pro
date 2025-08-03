import SwiftUI

struct InvoiceSummarySection: View {
    let selectedCurrency: String
    let currencySymbol: (String) -> String
    let items: [ItemModel]
    let onCurrencyTap: () -> Void
    let totalAmount: Double

    var subtotal: Double {
        items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }

    var totalDiscount: Double {
        items.reduce(0) { sum, item in
            let discountValue = item.price * Double(item.quantity) * Double(item.discount) / 100.0
            return sum + discountValue
        }
    }

    var totalTax: Double {
        return items.reduce(0) { sum, item in
            let taxPercent = Double(item.tax) 
            let base = item.price * Double(item.quantity) * (1.0 - Double(item.discount) / 100.0)
            let taxValue = base * taxPercent / 100.0
            return sum + taxValue
        }
    }

    private func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Summary")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 24)
            .frame(width: 340)

            if !items.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("Subtotal")
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                        Text(formattedPrice(subtotal))
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                    HStack {
                        Text("Discount")
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                        Text("-\(formattedPrice(totalDiscount))")
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                    HStack {
                        Text("Tax")
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                        Text(formattedPrice(totalTax))
                            .font(.body)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3))
                )
            }

            HStack(spacing: 12) {
                Button(action: {
                    onCurrencyTap()
                }) {
                    HStack(spacing: 4) {
                        Text(selectedCurrency)
                            .font(.body)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .frame(height: 44)
                    .frame(width: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3))
                    )
                }
                
                HStack(spacing: 0) {
                    Text("Total")
                        .font(.body)
                        .foregroundColor(.black)
                        .bold()
                        .padding(.leading, 16)
                    Text(formattedPrice(totalAmount))
                        .font(.body)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.leading, 8)
                        .padding(.trailing, 6)
                        .frame(minWidth: 60, maxWidth: .infinity, alignment: .leading)
                    Text(currencySymbol(selectedCurrency))
                        .font(.body)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.trailing, 15)
                }
                .frame(height: 44)
                .frame(width: 228, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3))
                )
            }
        }
        .frame(width: 340)

    }
}
