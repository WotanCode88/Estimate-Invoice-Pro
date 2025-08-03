import Foundation
import RealmSwift
import Combine

final class ItemListViewModel: ObservableObject {
    @Published var items: [ItemModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    func fetchItems() {
        isLoading = true
        error = nil
        do {
            let realm = try Realm()
            let results = realm.objects(ItemModel.self)
            items = Array(results)
            isLoading = false
        } catch {
//            error = "Failed to load items"
            isLoading = false
        }
    }

    func deleteItem(_ item: ItemModel) {
        do {
            let realm = try Realm()
            if let object = realm.object(ofType: ItemModel.self, forPrimaryKey: item._id) {
                try realm.write {
                    realm.delete(object)
                }
            }
            fetchItems()
        } catch {
//            error = "Failed to delete item"
        }
    }
}
