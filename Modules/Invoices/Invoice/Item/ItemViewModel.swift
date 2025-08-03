import Foundation
import RealmSwift
import Combine

final class ItemViewModel: ObservableObject {
    @Published var itemName: String = ""
    @Published var itemDetails: String = ""
    @Published var unitPrice: String = ""
    @Published var quantity: String = ""
    @Published var unitType: String = ""
    @Published var discount: String = ""
    @Published var isDiscountEnabled: Bool = false
    @Published var tax: String = ""
    @Published var isTaxEnabled: Bool = false

    var isValid: Bool {
        let nameIsValid = !itemName.trimmingCharacters(in: .whitespaces).isEmpty
        let priceIsValid = Double(unitPrice) != nil && (Double(unitPrice) ?? 0) > 0
        let quantityIsValid = Int(quantity) != nil && (Int(quantity) ?? 0) > 0
        return nameIsValid && priceIsValid && quantityIsValid
    }

    func saveItem() {
        guard isValid else { return }
        let realm = try! Realm()
        let item = ItemModel()
        item.name = itemName
        item.datails = itemDetails.isEmpty ? nil : itemDetails
        item.unitType = unitType.isEmpty ? nil : unitType
        item.price = Double(unitPrice) ?? 0
        item.quantity = Int(quantity) ?? 0
        item.discount = isDiscountEnabled ? (Int(discount) ?? 0) : 0
        item.tax = isTaxEnabled ? (Int(tax) ?? 0) : 0

        try! realm.write {
            realm.add(item)
        }
    }
}
