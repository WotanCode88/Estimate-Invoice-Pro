import RealmSwift
import Foundation

final class UserModel: Object {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var isSubscribed: Bool = true
    @Persisted var name: String
    @Persisted var email: String?
    @Persisted var phone: Int?
    @Persisted var address: String?
    @Persisted var logo: Data?
    @Persisted var invoices: List<InvoiceModel>
}

extension UserModel {
    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UserModel else { return false }
        return _id == other._id
    }
    override public var hash: Int {
        return _id.hashValue
    }
}
