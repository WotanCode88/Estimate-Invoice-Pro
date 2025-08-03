import Combine
import RealmSwift
import Foundation
internal import Realm

final class InvoicesViewModel: ObservableObject {
    @Published var invoices: [InvoiceModel] = []
    private var notificationToken: NotificationToken?
    private var realm: Realm?

    init() {
        do {
            realm = try Realm()
            fetchInvoices()
        } catch {
            print("Ошибка открытия Realm: \(error)")
        }
    }

    private func fetchInvoices() {
        guard let realm else { return }
        let results = realm.objects(InvoiceModel.self)
        notificationToken = results.observe { [weak self] changes in
            switch changes {
            case .initial(let collection), .update(let collection, _, _, _):
                self?.invoices = Array(collection)
            case .error(let error):
                print("Realm error: \(error)")
            }
        }
    }
    
    func deleteInvoice(_ invoice: InvoiceModel) {
        if let index = invoices.firstIndex(of: invoice) {
            invoices.remove(at: index)
        }
        let realm = try? Realm()
        if let realm = realm, realm.isInWriteTransaction == false {
            try? realm.write {
                if let obj = realm.object(ofType: InvoiceModel.self, forPrimaryKey: invoice._id) {
                    realm.delete(obj)
                }
            }
        }
    }

    deinit {
        notificationToken?.invalidate()
    }
}
