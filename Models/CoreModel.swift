import Foundation
import RealmSwift

final class CoreModel: Object {
    @Persisted var currentUser: UserModel?
    @Persisted var users: List<UserModel>
}
