import Foundation
import Combine
import RealmSwift
internal import UIKit

// Копия Realm-модели в виде структуры
struct UserModelStruct {
    var isSubscribed: Bool = true
    var name: String = ""
    var email: String? = nil
    var phone: Int? = nil
    var address: String? = nil
    var logo: Data? = nil

    // Convenience initializer for UIImage logo
    init(isSubscribed: Bool = true,
         name: String = "",
         email: String? = nil,
         phone: Int? = nil,
         address: String? = nil,
         logoImage: UIImage? = nil) {
        self.isSubscribed = isSubscribed
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        if let img = logoImage {
            self.logo = img.jpegData(compressionQuality: 0.9)
        }
    }
    
    // Convenience initializer from UserModel (Realm)
    init(from model: UserModel) {
        self.isSubscribed = model.isSubscribed
        self.name = model.name
        self.email = model.email
        self.phone = model.phone
        self.address = model.address
        self.logo = model.logo
    }
}

final class PersonalAuthorizationViewModel: ObservableObject {
    @Published var userStruct: UserModelStruct = UserModelStruct()

    // Методы работы со структурой
    func setName(_ name: String) {
        userStruct.name = name
    }

    func setEmail(_ email: String?) {
        userStruct.email = email
    }

    func setPhone(_ phone: String?) {
        if let phone = phone, let phoneInt = Int(phone), !phone.isEmpty {
            userStruct.phone = phoneInt
        } else {
            userStruct.phone = nil
        }
    }

    func setAddress(_ address: String?) {
        userStruct.address = address
    }

    func setLogo(_ image: UIImage?) {
        if let image = image {
            userStruct.logo = image.jpegData(compressionQuality: 0.9)
        } else {
            userStruct.logo = nil
        }
    }

    /// Метод для конвертации структуры в Realm-модель и добавления в Realm
    func saveToRealm() -> UserModel? {
        let newUser = UserModel()
        newUser.isSubscribed = userStruct.isSubscribed
        newUser.name = userStruct.name
        newUser.email = userStruct.email
        newUser.phone = userStruct.phone
        newUser.address = userStruct.address
        newUser.logo = userStruct.logo
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(newUser)
            }
            return newUser
        } catch {
            print("Realm add error: \(error)")
            return nil
        }
    }
}
