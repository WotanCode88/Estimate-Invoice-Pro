import Foundation
import RealmSwift
import Combine
internal import Realm

final class ClientListViewModel: ObservableObject {
    @Published var clients: [ClientModel] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil

    private var notificationToken: NotificationToken?
    private var realm: Realm?

    func fetchClients() {
        isLoading = true
        do {
            realm = try Realm()
            let results = realm!.objects(ClientModel.self)
            notificationToken = results.observe { [weak self] changes in
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    self?.clients = Array(collection)
                    self?.isLoading = false
                case .error(let error):
                    self?.error = error.localizedDescription
                    self?.isLoading = false
                }
            }
        } catch {
//            error = error.localizedDescription
            isLoading = false
        }
    }

    deinit {
        notificationToken?.invalidate()
    }
}
