import SwiftUI
import Combine

final class InvoicesCoordinator: ObservableObject {
    @Published var isPresentingNewInvoice = false

    func presentNewInvoice() {
        isPresentingNewInvoice = true
    }

    func dismissNewInvoice() {
        isPresentingNewInvoice = false
    }
}
