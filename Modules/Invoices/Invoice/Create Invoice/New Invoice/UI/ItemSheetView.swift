import SwiftUI
import RealmSwift

struct ItemSheetView: View {
    @ObservedObject var itemVM: ItemListViewModel
    @Binding var selectedItems: [ItemModel]
    @Binding var showItemSheet: Bool
    @State private var showAddItemViewNav = false
    @Environment(\.dismiss) private var dismiss
    var currencyCode: String
    
    func formattedPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 6)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                Text("Items")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top)
                    .padding(.bottom, 12)

                if itemVM.isLoading {
                    ProgressView("Loading...")
                        .padding()
                    Spacer()
                } else if let error = itemVM.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if itemVM.items.isEmpty {
                    Text("No items found")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(itemVM.items, id: \._id) { item in
                            Button(action: {
                                // Добавляем item в массив, если ещё не выбран
                                if !selectedItems.contains(where: { $0._id == item._id }) {
                                    selectedItems.append(item)
                                }
                                showItemSheet = false
                            }) {
                                HStack(spacing: 10) {
                                    Text(item.name)
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("\(currencySymbol(for: currencyCode))\(formattedPrice(item.price))")
                                        .font(.body)
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 8)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    itemVM.deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
                NavigationLink(
                    destination: ItemView(currencyCode: currencyCode),
                    isActive: $showAddItemViewNav
                ) {
                    Button(action: {
                        showAddItemViewNav = true
                    }) {
                        Text("Add Item")
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
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                itemVM.fetchItems()
            }
            // Если выбранный айтем был удалён из Realm — удаляем его из массива
            .onReceive(itemVM.$items) { items in
                selectedItems.removeAll { selected in
                    selected.isInvalidated || !items.contains(where: { $0._id == selected._id })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
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
}
