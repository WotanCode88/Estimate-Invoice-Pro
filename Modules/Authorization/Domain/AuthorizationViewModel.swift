import Foundation
import Combine
import RealmSwift
internal import UIKit

final class AuthorizationViewModel: ObservableObject {
    private let realm: Realm
    @Published var user: UserModel

    init() {
        let realm = try! Realm()
        try? realm.write {
            realm.delete(realm.objects(UserModel.self))
            realm.delete(realm.objects(CoreModel.self))
        }
        let newUser = UserModel()
        let newCore = CoreModel()
        newCore.currentUser = newUser
        newCore.users.append(newUser)
        try! realm.write {
            realm.add(newUser)
            realm.add(newCore)
        }
        self.realm = realm
        self.user = newUser
    }

    func setName(_ name: String) {
        try? realm.write {
            user.name = name
        }
    }

    func setEmail(_ email: String?) {
        try? realm.write {
            user.email = email
        }
    }

    func setPhone(_ phone: String?) {
        try? realm.write {
            if let phone = phone, let phoneInt = Int(phone), !phone.isEmpty {
                user.phone = phoneInt
            } else {
                user.phone = nil
            }
        }
    }

    func setAddress(_ address: String?) {
        try? realm.write {
            user.address = address
        }
    }

    func setLogo(_ image: UIImage?) {
        guard let image = image, let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? realm.write {
            user.logo = data
        }
    }
}
