import Foundation
import RealmSwift
import Combine

final class UserViewModel: ObservableObject {
    static let shared = UserViewModel()
    
    @Published var currentUser: UserModel?
    @Published var users: [UserModel] = []
    
    var realm: Realm
    var coreModel: CoreModel?
    
    private init() {
        self.realm = try! Realm()
        self.coreModel = realm.objects(CoreModel.self).first
        
        if let core = coreModel {
            self.currentUser = core.currentUser
            self.users = Array(realm.objects(UserModel.self))
        }
    }
    
    func setCurrentUser(_ user: UserModel) {
        guard let core = coreModel else { return }
        try? realm.write {
            core.currentUser = user
        }
        self.currentUser = user
    }
}
