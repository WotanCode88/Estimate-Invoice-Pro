import Combine
import RealmSwift
import Foundation
internal import Realm

final class EstimatesViewModel: ObservableObject {
    @Published var estimates: [InvoiceModel] = []
    private var notificationToken: NotificationToken?
    private var realm: Realm?

    init() {
        do {
            realm = try Realm()
            fetchEstimates()
        } catch {
            print("Ошибка открытия Realm: \(error)")
        }
    }

    private func fetchEstimates() {
        guard let realm else { return }
        let results = realm.objects(InvoiceModel.self).filter("isEstimate == true")
        notificationToken = results.observe { [weak self] changes in
            switch changes {
            case .initial(let collection), .update(let collection, _, _, _):
                self?.estimates = Array(collection)
            case .error(let error):
                print("Realm error: \(error)")
            }
        }
    }
    
    func deleteEstimate(_ estimate: InvoiceModel) {
        if let index = estimates.firstIndex(of: estimate) {
            estimates.remove(at: index)
        }
        let realm = try? Realm()
        if let realm = realm, realm.isInWriteTransaction == false {
            try? realm.write {
                if let obj = realm.object(ofType: InvoiceModel.self, forPrimaryKey: estimate._id) {
                    realm.delete(obj)
                }
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }
}
