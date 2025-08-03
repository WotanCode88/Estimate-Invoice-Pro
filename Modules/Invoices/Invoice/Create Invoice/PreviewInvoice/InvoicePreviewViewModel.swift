import Foundation
import RealmSwift
import SwiftUI
import Combine

final class InvoicePreviewViewModel: ObservableObject {
    let invoice: InvoiceModel
    @Published var user: UserModel?

    init(invoice: InvoiceModel) {
        self.invoice = invoice
        self.user = fetchUser()
    }

    private func fetchUser() -> UserModel? {
        let vm = UserViewModel.shared
        return vm.currentUser
    }
    
    func savePaidStatus(payMethod: String, wasPaid: Bool) {
        let realm = try? Realm()
        guard let realm = realm else { return }
        do {
            try realm.write {
                invoice.payMethod = payMethod
                invoice.wasPaid = wasPaid
            }
        } catch {
            print("Error saving paid status: \(error)")
        }
    }
}
