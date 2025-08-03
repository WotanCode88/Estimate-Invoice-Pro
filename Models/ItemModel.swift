import RealmSwift

final class ItemModel: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var datails: String?
    @Persisted var unitType: String?
    @Persisted var price: Double
    @Persisted var quantity: Int
    @Persisted var discount: Int = 0
    @Persisted var tax: Int = 0
    static func == (lhs: ItemModel, rhs: ItemModel) -> Bool {
        lhs._id == rhs._id
    }
}
