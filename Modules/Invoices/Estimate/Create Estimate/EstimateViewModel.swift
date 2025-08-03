import Foundation
import Combine
import RealmSwift

final class NewEstimateViewModel: ObservableObject {
    @Published var issuedDate: Date = Date()
    @Published var dueDate: Date? = nil

    @Published var draft = InvoiceDraft()

    func setClient(_ client: ClientModel) {
        draft.client = client
    }

    func setTotal(_ total: Double) {
        draft.total = total
    }

    func setCurrency(_ currency: String) {
        draft.currency = currency
    }

    init() {
        $issuedDate
            .sink { [weak self] newDate in
                self?.draft.issuedDate = newDate
            }
            .store(in: &cancellables)
        $dueDate
            .sink { [weak self] newDate in
                self?.draft.dueDate = newDate
            }
            .store(in: &cancellables)
    }
    
    var invoice: InvoiceModel?
    
    func makeInvoiceModel() -> InvoiceModel {
        let invoice = InvoiceModel()
        invoice.Issued = draft.issuedDate
        invoice.due = draft.dueDate ?? Date()
        invoice.client = draft.client
        invoice.total = draft.total
        invoice.currency = draft.currency
        invoice.photo = draft.photo
        invoice.wasPaid = draft.wasPaid
        invoice.payMethod = draft.payMethod
        invoice.number = draft.number
        invoice.item.append(objectsIn: draft.items)
        invoice.isEstimate = true
        return invoice
    }

    func saveToRealm() {
        invoice = InvoiceModel()
        guard let invoice else { return }
        invoice.Issued = draft.issuedDate
        invoice.due = draft.dueDate ?? Date()
        invoice.client = draft.client
        invoice.total = draft.total
        invoice.currency = draft.currency
        invoice.photo = draft.photo
        invoice.wasPaid = draft.wasPaid
        invoice.payMethod = draft.payMethod
        invoice.number = draft.number
        invoice.item.append(objectsIn: draft.items)
        invoice.isEstimate = true
        
        let realm = try! Realm()
        let user = UserViewModel.shared.currentUser

        try! realm.write {
            if let user = user {
                user.invoices.append(invoice)
            }
            realm.add(invoice)
        }
    }

    var invoiceNumberText: String {
        return "\(NewInvoiceViewModel.invoiceCount() + 1)"
    }

    static func invoiceCount() -> Int {
        let realm = try! Realm()
        return realm.objects(InvoiceModel.self).count
    }

    private var cancellables = Set<AnyCancellable>()
    
    func getRealmModel() -> InvoiceModel {
        return invoice!
    }
}
