import RealmSwift
import Foundation

final class InvoiceModel: Object {
    @Persisted var Issued: Date
    @Persisted var due: Date
    
    @Persisted var isEstimate: Bool = false
    
    @Persisted var client: ClientModel?
    @Persisted var item: List<ItemModel>
    
    @Persisted var total: Double
    @Persisted var currency: String
    
    @Persisted var photo: Data?
    @Persisted var wasPaid: Bool
    
    @Persisted var payMethod: String
    @Persisted var number: Int
    
    @Persisted var notes: String?
    @Persisted(primaryKey: true) var _id: ObjectId
}

extension InvoiceModel: Identifiable {
    var id: ObjectId { _id }
}

