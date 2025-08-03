import RealmSwift

final class ClientModel: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var email: String?
    @Persisted var phone: String?
    @Persisted var addres: String?
    @Persisted var balance: Int
}
