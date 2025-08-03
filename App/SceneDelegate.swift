internal import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        registerCustomFont(name: "Urbanist-VariableFont_wght", fileExtension: "ttf")
        registerCustomFont(name: "SongMyung-Regular", fileExtension: "ttf")

        LaunchCoordinator(window: window).dispatchStartScreen()
    }
}
