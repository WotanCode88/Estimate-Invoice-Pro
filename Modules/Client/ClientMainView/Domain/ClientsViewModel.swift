import Foundation
import RealmSwift
import Combine

final class ClientsViewModel: ObservableObject {
    @Published var clients: [ClientModel] = []
    @Published var searchText: String = ""

    func loadClients() {
        let realm = try? Realm()
        clients = realm?.objects(ClientModel.self).map { $0 } ?? []
    }

    var filteredClients: [ClientModel] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return clients
        }
        let lowercased = searchText.lowercased()
        return clients.filter {
            $0.name.lowercased().contains(lowercased)
        }
    }

    func totalPaid(for client: ClientModel) -> Double {
        guard let realm = try? Realm() else { return 0 }
        let paidInvoices = realm.objects(InvoiceModel.self)
            .filter("client._id == %@ AND wasPaid == true", client._id)
        return paidInvoices.reduce(0.0) { $0 + ($1.total ?? 0) }
    }
}
