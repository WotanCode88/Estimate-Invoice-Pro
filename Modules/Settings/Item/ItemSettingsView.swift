import SwiftUI
import RealmSwift

struct ItemSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showNewItem = false
    @State private var searchText = ""

    @ObservedResults(ItemModel.self) var allItems

    var filteredItems: [ItemModel] {
        if searchText.isEmpty {
            return Array(allItems)
        } else {
            return allItems.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Custom NavBar
                ZStack {
                    Color(.systemGray6)
                        .frame(height: 56)
                        .shadow(color: Color(.systemGray4).opacity(0.10), radius: 1, x: 0, y: 1)
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        Spacer()
                        Text("Items")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: { showNewItem = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 56)
                
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name", text: $searchText)
                        .font(.system(size: 16))
                        .padding(.vertical, 8)
                }
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color(.systemGray4).opacity(0.08), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Список айтемов с горизонтальным отступом
                List {
                    ForEach(filteredItems, id: \._id) { item in
                        ItemRowView(item: item)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 12)
                            .listRowBackground(Color(.systemGray6))
                            .contentShape(Rectangle())
                    }
                }
                .listStyle(.plain)
                .background(Color(.systemGray6))
                .padding(.top, -8)

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showNewItem) {
            ItemView(currencyCode: "")
        }
    }
}

struct ItemRowView: View {
    let item: ItemModel
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 17, weight: .medium))
                if let details = item.datails, !details.isEmpty {
                    Text(details)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Text(String(format: "%.2f", item.price))
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.vertical, 8)
    }
}
