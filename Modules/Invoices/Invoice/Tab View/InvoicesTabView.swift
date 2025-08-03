import SwiftUI

struct InvoicesTabView: View {
    @ObservedObject var coordinator: InvoicesCoordinator
    @StateObject private var viewModel = InvoicesViewModel()
    @State private var selectedFilter: InvoiceFilter = .all
    @State private var selectedInvoice: InvoiceModel? = nil

    @ObservedObject private var userVM = UserViewModel.shared
    @State private var reloadID = UUID()

    var userInvoices: [InvoiceModel] {
        guard let currentUser = userVM.currentUser else { return [] }
        return Array(currentUser.invoices)
    }

    var filteredInvoices: [InvoiceModel] {
        let invoices = userInvoices.filter { $0.isEstimate == false }
        switch selectedFilter {
        case .all:    return invoices
        case .unpaid: return invoices.filter { !($0.wasPaid ?? false) }
        case .paid:   return invoices.filter { $0.wasPaid ?? false }
        }
    }

    var totalSum: Double {
        filteredInvoices.reduce(0) { $0 + ($1.total ?? 0) }
    }

    var currency: String {
        filteredInvoices.first?.currency ?? ""
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                CustomSegmentedPicker(selected: $selectedFilter)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                if filteredInvoices.isEmpty {
                    Spacer()
                    Image("invoiceEmptyView")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220)
                        .padding()
                    Spacer()
                } else {
                    Text("Total: \(String(format: "%.2f", totalSum)) \(currency)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    VStack {
                        List {
                            ForEach(filteredInvoices, id: \.self) { invoice in
                                InvoiceRowView(invoice: invoice)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 6)
                                    .listRowSeparator(.hidden)
                                    .onTapGesture {
                                        selectedInvoice = invoice
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let invoiceToDelete = filteredInvoices[index]
                                    viewModel.deleteInvoice(invoiceToDelete)
                                }
                            }
                        }
                        .sheet(item: $selectedInvoice) { invoice in
                            SingleInvoiceVCWrapper(invoice: invoice, isCustom: false)
                        }
                        .listRowSeparator(.hidden)
                        .listStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
                
                Button(action: {
                    coordinator.presentNewInvoice()
                }) {
                    Text("+ Create Invoice")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(20)
                        .padding(.horizontal, 100)
                }
                .padding(.bottom, 16)
            }
        }
        .id(reloadID) 
        .onReceive(userVM.$currentUser) { _ in
            reloadID = UUID()
        }
    }
}

struct InvoiceRowView: View {
    let invoice: InvoiceModel

    var paidAsset: some View {
        Image("paidAsset")
            .resizable()
            .frame(width: 30, height: 17)
    }

    var unpaidAsset: some View {
        Image("unpaidAsset")
            .resizable()
            .frame(width: 45, height: 17)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(invoice.client?.name ?? "nil")
                    .font(.system(size: 18, weight: .semibold))
                HStack(spacing: 12) {
                    Text("Issue: \(formatDate(invoice.Issued))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("Due: \(formatDate(invoice.due))")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 4) {
                    Text("\(String(format: "%.2f", invoice.total ?? 0))")
                        .font(.system(size: 17, weight: .semibold))
                    Text(invoice.currency ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                if invoice.wasPaid ?? false {
                    paidAsset
                } else {
                    unpaidAsset
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 68)
        .background(
            Color.white
                .cornerRadius(14)
                .shadow(color: Color(.systemGray4).opacity(0.18), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }

    func formatDate(_ date: Date?) -> String {
        guard let date else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unpaid = "Unpaid"
    case paid = "Paid"
    var id: String { rawValue }
}

struct CustomSegmentedPicker: View {
    @Binding var selected: InvoiceFilter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(InvoiceFilter.allCases) { filter in
                Button(action: {
                    selected = filter
                }) {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selected == filter ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(selected == filter ? Color.black : Color.clear)
                        .cornerRadius(7)
                }
            }
        }
        .padding(2)
        .frame(width: 200)
        .background(Color(.white))
        .cornerRadius(9)
    }
}
