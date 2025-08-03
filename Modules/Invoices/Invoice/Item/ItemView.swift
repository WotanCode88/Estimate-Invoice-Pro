import SwiftUI

struct ItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ItemViewModel()
    @State private var showDeleteButton: Bool = false
    let currencyCode: String

    private let inputWidth: CGFloat = 350

    func currencySymbol(for code: String) -> String {
        for localeID in Locale.availableIdentifiers {
            let locale = Locale(identifier: localeID)
            if locale.currencyCode == code, let symbol = locale.currencySymbol {
                return symbol
            }
        }
        return ""
    }

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text("Item")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.body)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .frame(height: 44)
                .background(Color(.systemGray6))
                .navigationBarBackButtonHidden(true)

                VStack(spacing: 0) {
                    TextField("Name", text: $viewModel.itemName)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(Color.white)
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(.systemGray))
                    TextField("Description", text: $viewModel.itemDetails, axis: .vertical)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.top)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 60, maxHeight: 100, alignment: .top)
                        .background(Color.white)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(width: inputWidth)
                .padding(.top, 32)

                VStack(spacing: 8) {
                    HStack {
                        Text("Unit price")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: inputWidth / 3, alignment: .leading)
                        Spacer()
                        Text("Quantity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: inputWidth / 3, alignment: .leading)
                        Spacer()
                        Text("Unit Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: inputWidth / 3, alignment: .leading)
                    }
                    .frame(width: inputWidth)

                    HStack(spacing: 0) {
                        HStack(spacing: 0) {
                            TextField("0", text: $viewModel.unitPrice)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .background(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(currencySymbol(for: currencyCode))
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.trailing, 12)
                                .background(Color.white)
                        }
                        .background(Color.white)
                        .frame(width: inputWidth / 3)
                        Rectangle()
                            .frame(width: 1, height: 40)
                            .foregroundColor(Color(.systemGray3))
                        HStack(spacing: 0) {
                            TextField("0", text: $viewModel.quantity)
                                .keyboardType(.numberPad)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .background(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: inputWidth / 3)
                        Rectangle()
                            .frame(width: 1, height: 40)
                            .foregroundColor(Color(.systemGray3))
                        HStack(spacing: 0) {
                            TextField("Optional", text: $viewModel.unitType)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .background(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: inputWidth / 3)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(width: inputWidth)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Discount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    HStack {
                        HStack(spacing: 0) {
                            TextField("Discount", text: $viewModel.discount)
                                .keyboardType(.numberPad)
                                .disabled(!viewModel.isDiscountEnabled)
                                .font(.body)
                                .foregroundColor(viewModel.isDiscountEnabled ? .green : .gray)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .background(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("%")
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.trailing, 12)
                                .background(Color.white)
                        }
                        Toggle("", isOn: $viewModel.isDiscountEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .padding(.trailing, 12)
                    }
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(width: inputWidth)
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tax")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)

                    HStack {
                        HStack(spacing: 0) {
                            TextField("Tax", text: $viewModel.tax)
                                .keyboardType(.numberPad)
                                .disabled(!viewModel.isTaxEnabled)
                                .font(.body)
                                .foregroundColor(viewModel.isTaxEnabled ? .green : .gray)
                                .padding(.vertical, 12)
                                .padding(.leading, 16)
                                .background(Color.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("%")
                                .font(.body)
                                .foregroundColor(.black)
                                .padding(.trailing, 12)
                                .background(Color.white)
                        }
                        Toggle("", isOn: $viewModel.isTaxEnabled)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .padding(.trailing, 12)
                    }
                    .frame(height: 44)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .frame(width: inputWidth)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 16) {
                    if showDeleteButton {
                        Button(action: {
                            // Action for delete
                        }) {
                            Text("Delete Item")
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                    }

                    Button(action: {
                        if viewModel.isValid {
                            viewModel.saveItem()
                            dismiss()
                        }
                    }) {
                        Text("Save")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(viewModel.isValid ? Color.black : Color.gray)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}
