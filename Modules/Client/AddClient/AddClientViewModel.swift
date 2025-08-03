import Combine
import RealmSwift
import Foundation

final class AddClientViewModel: ObservableObject {

    func fillFields(with contact: ContactData,
                    name: inout String,
                    email: inout String,
                    phone: inout String,
                    address: inout String) {
        name = contact.name
        email = contact.email
        phone = contact.phone
        address = contact.address
    }

    func saveClient(name: String, email: String?, phone: String?, address: String?) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClientSaveError.emptyName
        }
        let client = ClientModel()
        client.name = name
        client.email = (email?.isEmpty == false) ? email : nil
        client.phone = (phone?.isEmpty == false) ? phone : nil
        client.addres = (address?.isEmpty == false) ? address : nil
        client.balance = 0

        let realm = try Realm()
        try realm.write {
            realm.add(client)
        }
    }

    enum ClientSaveError: Error {
        case emptyName
    }
}

struct ContactData {
    let name: String
    let email: String
    let phone: String
    let address: String
}
