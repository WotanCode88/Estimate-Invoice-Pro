internal import UIKit
import SwiftUI
import RealmSwift

final public class LaunchCoordinator {
    private let firstLaunchKey = "isFirstLaunch"
    private let window: UIWindow

    public init(window: UIWindow) {
        self.window = window
    }

    func dispatchStartScreen() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        if isFirstLaunch {
            showAutorizationFirstView()
        } else {
            showMainScreen()
        }
    }

    func showMainScreen() {
        let tabView = MainTabView()
                
        window.rootViewController = UIHostingController(rootView: tabView)
        window.makeKeyAndVisible()
    }

    func showAutorizationFirstView() {
        let rootView = AuthorizationFirstView(viewModel: authViewModel, coordinator: self)
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
    }
    
    private lazy var authViewModel = AuthorizationViewModel()

    func showAutorizationSecondView() {
        let rootView = AuthorizationSecondView(viewModel: authViewModel, coordinator: self)
        window.rootViewController = UIHostingController(rootView: rootView)
        window.makeKeyAndVisible()
    }

    func finishAuthorization() {
        UserDefaults.standard.set(true, forKey: firstLaunchKey)
        showMainScreen()
    }
}
