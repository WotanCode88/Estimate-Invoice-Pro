internal import UIKit
import CoreText

func registerCustomFont(name: String, fileExtension: String) {
    guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
        print("Не удалось найти шрифт \(name).\(fileExtension)")
        return
    }

    guard let fontData = try? Data(contentsOf: fontURL) as CFData else {
        print("Не удалось загрузить данные шрифта из \(fontURL)")
        return
    }

    guard let provider = CGDataProvider(data: fontData) else {
        print("Не удалось создать CGDataProvider")
        return
    }

    guard let font = CGFont(provider) else {
        print("Не удалось создать CGFont")
        return
    }

    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterGraphicsFont(font, &error) {
        print("Ошибка регистрации шрифта: \(String(describing: error))")
    }
}
