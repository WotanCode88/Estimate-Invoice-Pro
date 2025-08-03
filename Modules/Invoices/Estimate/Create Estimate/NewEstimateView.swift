import SwiftUI
import RealmSwift

struct NewEstimateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewEstimateViewModel()
    @StateObject private var currencyVM = CurrencyViewModel()
    @StateObject private var clientVM = ClientListViewModel()
    @State private var showIssuedPicker = false
    @State private var showDuePicker = false
    @State private var showClientSheet = false
    @State private var showItemSheet = false
    @State private var showCurrencySheet = false
    @State private var showAddClientViewNav = false
    @State private var tempDueDate: Date = Date()
    @State private var summaryAmount: String = ""
    @State private var selectedCurrency: String = "USD"
    @State private var selectedClientName: String? = nil
    @FocusState private var isAmountFocused: Bool
    @StateObject private var itemVM = ItemListViewModel()
    @State private var selectedItems: [ItemModel] = []
    @State private var notes: String = ""
    @State private var showPhotoSheet = false
    @State private var showSubscriptionSheet = false
    @StateObject private var userVM = SubscriptionViewModel.shared
    @State private var showImagePicker = false
    @State private var pickedImage: UIImage? = nil
    @State private var photoAdded: Bool = false
    @State private var showValidationAlert = false
    var onDismiss: () -> Void
    
    @State private var showPreview = false
    @State private var showInvoiceView = false

    var totalAmount: Double {
        selectedItems.reduce(0) { sum, item in
            let base = item.price * Double(item.quantity)
            let discountValue = base * Double(item.discount) / 100.0
            let discounted = base - discountValue
            let taxValue = discounted * Double(item.tax) / 100.0
            let final = discounted + taxValue
            return sum + final
        }
    }

    func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }

    func currencySymbol(for code: String) -> String {
        for localeID in Locale.availableIdentifiers {
            let locale = Locale(identifier: localeID)
            if locale.currencyCode == code, let symbol = locale.currencySymbol {
                return symbol
            }
        }
        return ""
    }

    func total() -> Double {
        var total: Double = 0
        selectedItems.forEach { item in
            total += item.price * Double(item.quantity)
        }
        return total
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { isAmountFocused = false }
                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 0) {
                            EstimateHeaderView(
                                dismiss: dismiss,
                                issuedDate: viewModel.issuedDate,
                                dueDate: viewModel.dueDate,
                                client: viewModel.draft.client,
                                items: selectedItems,
                                total: totalAmount,
                                currency: selectedCurrency,
                                onBack: {
                                    viewModel.draft.items = selectedItems
                                    viewModel.draft.total = total()
                                    viewModel.draft.currency = selectedCurrency
                                    viewModel.saveToRealm()
                                    showInvoiceView = true
                                },
                                back: { onDismiss() }
                            )
                            EstimateDatesSection(
                                issuedDate: $viewModel.issuedDate,
                                invoiceNumberText: viewModel.invoiceNumberText,
                                showIssuedPicker: $showIssuedPicker,
                                dateFormatter: dateFormatter,
                            )
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Client")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(width: 340)
                                
                                Button(action: { showClientSheet = true }) {
                                    HStack {
                                        if let name = selectedClientName {
                                            HStack {
                                                Text(name)
                                                    .font(.body)
                                                    .foregroundColor(.black)
                                                Spacer()
                                                Image("change")
                                                    .resizable()
                                                    .frame(width: 49, height: 17)
                                                    .padding(.trailing)
                                            }
                                        } else {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.black)
                                            Text("Add client")
                                                .font(.body)
                                                .foregroundColor(.black)
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading, 16)
                                    .frame(height: 44)
                                    .frame(width: 340)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3))
                                    )
                                }
                            }
                            .padding(.top, 24)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Item")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(width: 340)
                                
                                VStack(spacing: 0) {
                                    ForEach(selectedItems, id: \._id) { item in
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            Text("\(currencySymbol(for: selectedCurrency))\(formattedPrice(item.price))")
                                        }
                                        .frame(height: 44)
                                        .padding(.horizontal, 16)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                selectedItems.removeAll { $0._id == item._id }
                                            } label: {
                                                Label("Delete from invoice", systemImage: "trash")
                                            }
                                        }
                                    }
                                    
                                    if !selectedItems.isEmpty {
                                        Divider()
                                            .padding(.horizontal, 8)
                                    }
                                    
                                    Button(action: { showItemSheet = true }) {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.black)
                                            Text("Add item")
                                                .font(.body)
                                                .foregroundColor(.black)
                                            Spacer()
                                        }
                                        .padding(.leading, 16)
                                        .frame(height: 44)
                                    }
                                }
                                .frame(width: 340)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                            }
                            .padding(.top, 24)
                            
                            
                            InvoiceSummarySection(
                                selectedCurrency: selectedCurrency,
                                currencySymbol: currencySymbol,
                                items: selectedItems,
                                onCurrencyTap: {
                                    showCurrencySheet = true
                                    currencyVM.fetchCurrencies()
                                },
                                totalAmount: totalAmount
                            )
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                Button(action: {
                                    if userVM.isSubscribed {
                                        showImagePicker = true
                                    } else {
                                        showSubscriptionSheet = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.black)
                                        Text(photoAdded ? "Added" : "Add Photo")
                                            .font(.body)
                                            .foregroundColor(photoAdded ? .green : .black)
                                        Spacer()
                                        Image("premium")
                                            .resizable()
                                            .frame(width: 67, height: 18)
                                            .padding(.trailing)
                                    }
                                    .padding(.leading, 16)
                                    .frame(height: 44)
                                    .frame(width: 340)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3))
                                    )
                                }
                            }
                            .frame(width: 340)
                            .padding(.top, 24)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes & Payment Instructions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        .background(Color.white.cornerRadius(12))
                                    TextField("Optional", text: $notes, axis: .vertical)
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(minHeight: 60, maxHeight: 120, alignment: .topLeading)
                                        .background(Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .frame(height: 100)
                            }
                            .frame(width: 340)
                            .padding(.top, 24)
                            
                            Spacer()
                            
                            NavigationLink(isActive: $showPreview) {
                                InvoiceJustPreviewRepresentable(invoice: viewModel.makeInvoiceModel())
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: { EmptyView() }
                            .hidden()

                            NavigationLink(isActive: $showInvoiceView) {
                                if let invoice = viewModel.invoice {
                                    SingleEstimateVCWrapper(invoice: invoice, isCustom: true)
                                }
                            } label: { EmptyView() }
                            .hidden()
                        }
                        .onTapGesture {
                            UIApplication.shared.hideKeyboard()
                        }
                        .padding(.bottom, 32)
                        
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                let isClientSelected = viewModel.draft.client != nil
                                let hasItems = !selectedItems.isEmpty
                                let currencySelected = !selectedCurrency.isEmpty
                                let issuedDateSelected = viewModel.issuedDate != nil

                                if isClientSelected && hasItems && currencySelected && issuedDateSelected {
                                    viewModel.draft.items = selectedItems
                                    viewModel.draft.total = total()
                                    viewModel.draft.currency = selectedCurrency
                                    showPreview = true
                                } else {
                                    showValidationAlert = true
                                }
                            }) {
                                Text("Preview")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)

                            Button(action: {
                                let isClientSelected = viewModel.draft.client != nil
                                let hasItems = !selectedItems.isEmpty
                                let currencySelected = !selectedCurrency.isEmpty
                                let issuedDateSelected = viewModel.issuedDate != nil

                                if isClientSelected && hasItems && currencySelected && issuedDateSelected {
                                    viewModel.draft.items = selectedItems
                                    viewModel.draft.total = total()
                                    viewModel.draft.currency = selectedCurrency
                                    viewModel.saveToRealm()
                                    showInvoiceView = true
                                } else {
                                    showValidationAlert = true
                                }
                            }) {
                                Text("Create Estimate")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.black)
                                    .cornerRadius(20)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 18)
                            .alert(isPresented: $showValidationAlert) {
                                Alert(
                                    title: Text("Required fields missing"),
                                    message: Text("Please fill out all required fields before saving the invoice."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                        }
                        .background(Color.white.ignoresSafeArea(edges: .bottom))
                    }
                }
                .sheet(isPresented: $showIssuedPicker) {
                    VStack {
                        DatePicker(
                            "Issued date",
                            selection: $viewModel.issuedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        Button("Done") { showIssuedPicker = false }
                            .padding()
                    }
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showDuePicker) {
                    VStack {
                        DatePicker(
                            "Due date",
                            selection: $tempDueDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        HStack {
                            Button("Clean") {
                                viewModel.dueDate = nil
                                showDuePicker = false
                            }
                            .foregroundColor(.red)
                            Spacer()
                            Button("Done") {
                                viewModel.dueDate = tempDueDate
                                showDuePicker = false
                            }
                            .foregroundColor(.blue)
                        }
                        .padding()
                    }
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showClientSheet) {
                    NavigationStack {
                        VStack(spacing: 0) {
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 6)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            Text("Clients")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.top)
                                .padding(.bottom, 12)
                            if clientVM.isLoading {
                                ProgressView("Loading...")
                                    .padding()
                            } else if let error = clientVM.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            } else if clientVM.clients.isEmpty {
                                Text("No clients found")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                Spacer()
                            } else {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(clientVM.clients, id: \.name) { client in
                                            Button(action: {
                                                selectedClientName = client.name
                                                viewModel.setClient(client)
                                                showClientSheet = false
                                            }) {
                                                HStack(spacing: 14) {
                                                    ClientLogoView(name: client.name)
                                                    Text(client.name)
                                                        .font(.body)
                                                        .foregroundColor(.black)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 18)
                                                .padding(.horizontal)
                                            }
                                            Divider()
                                        }
                                    }
                                }
                            }
                            NavigationLink(
                                destination: AddClientView(),
                                isActive: $showAddClientViewNav
                            ) {
                                Button(action: {
                                    showAddClientViewNav = true
                                }) {
                                    Text("Add Client")
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                            }
                        }
                        .presentationDetents([.large])
                        .onAppear {
                            clientVM.fetchClients()
                        }
                    }
                }
                .sheet(isPresented: $showItemSheet) {
                    ItemSheetView(itemVM: itemVM, selectedItems: $selectedItems, showItemSheet: $showItemSheet, currencyCode: selectedCurrency)
                        .ignoresSafeArea()
                }
                .sheet(isPresented: $showCurrencySheet) {
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 6)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        Text("Currency")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.top)
                            .padding(.bottom, 12)
                        if currencyVM.isLoading {
                            ProgressView("Loading...")
                                .padding()
                        } else if let error = currencyVM.error {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(currencyVM.currencies) { currency in
                                        Button(action: {
                                            selectedCurrency = currency.code
                                            viewModel.setCurrency(currency.code)
                                            showCurrencySheet = false
                                        }) {
                                            HStack {
                                                Text(currency.code)
                                                    .font(.body)
                                                    .foregroundColor(.black)
                                                    .frame(width: 60, alignment: .leading)
                                                Spacer()
                                                Text(currency.name)
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 20)
                                            .padding(.horizontal)
                                        }
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .presentationDetents([.large])
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $pickedImage)
                        .onDisappear {
                            if let img = pickedImage, let data = img.jpegData(compressionQuality: 0.8) {
                                viewModel.draft.photo = data
                                photoAdded = true
                            }
                        }
                }
                .sheet(isPresented: $showSubscriptionSheet) {
                    SubscriptionView()
                        .ignoresSafeArea()
                }
            }
        }
    }
}
