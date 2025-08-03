internal import UIKit
import SnapKit

extension SingleInvoiceVC {
    /// Возвращает символ валюты по коду (например, "USD" -> "$")
    func currencySymbol(for code: String) -> String {
        for localeID in Locale.availableIdentifiers {
            let locale = Locale(identifier: localeID)
            if locale.currencyCode == code, let symbol = locale.currencySymbol {
                return symbol
            }
        }
        return ""
    }

    /// Возвращает сумму всех позиций инвойса с учетом скидки и налога
    func totalAmount() -> Double {
        var total: Double = 0
        invoice.item.forEach { item in
            let base = item.price * Double(item.quantity)
            let discountValue = base * Double(item.discount) / 100.0
            let discounted = base - discountValue
            let taxValue = discounted * Double(item.tax) / 100.0
            let final = discounted + taxValue
            total += final
        }
        return total
    }

    /// Форматирует дату в строку "yyyy-MM-dd"
    func onlyDate(_ value: Date?) -> String {
        guard let value = value else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }

    /// Показывает алерт с ошибкой экспорта
    func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Export Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func exportInvoiceToPDF() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else {
            return
        }
        let pdfData = a4View.asPDFData()
        let fileName = "Invoice-\(invoice.number).pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tmpURL)
        } catch {
            showErrorAlert(error: error)
            return
        }
        let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: 100, width: 0, height: 0)
        }
        present(activityVC, animated: true)
    }
    
    
    func applyFontToInvoiceLabelsWithSize() {
        let isIncreased = (selectedInvoiceFontSizeIndex == 1)
        for (i, label) in allInvoiceLabels.enumerated() {
            // Получаем оригинальный размер лейбла
            let baseSize = (i < originalLabelFontSizes.count) ? originalLabelFontSizes[i] : label.font.pointSize
            let newSize = isIncreased ? baseSize + 1 : baseSize

            // Сохраняем стиль (bold/regular/кастом) — если у тебя есть смена стиля, то ее надо учесть!
            if selectedFontIndex == 1, let font = UIFont(name: "SongMyung-Regular", size: newSize) {
                label.font = font
            } else if selectedFontIndex == 2, let font = UIFont(name: "Urbanist-Regular", size: newSize) {
                label.font = font
            } else {
                // system, вернуть прежний вес
                let traits = label.font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
                let weightValue = traits?[.weight] as? CGFloat ?? UIFont.Weight.regular.rawValue
                let weight = UIFont.Weight(rawValue: weightValue)
                label.font = UIFont.systemFont(ofSize: newSize, weight: weight)
            }
        }
    }
    
    func updateSizeSelectionUI() {
        for (i, button) in sizeButtons.enumerated() {
            button.layer.borderColor = (i == selectedInvoiceFontSizeIndex ? UIColor.black.cgColor : UIColor.lightGray.cgColor)
        }
    }
    
    func applyFontToAllLabels() {
        for label in allInvoiceLabels {
            let oldFont = label.font!
            let oldSize = oldFont.pointSize
            switch selectedFontIndex {
            case 1: // Classic
                if let classicFont = UIFont(name: "SongMyung-Regular", size: oldSize) {
                    label.font = classicFont
                }
            case 2: // Round
                if let roundFont = UIFont(name: "Urbanist-Regular", size: oldSize) {
                    label.font = roundFont
                }
            default: // Normal (system)
                
                let traits = oldFont.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
                let weightValue = traits?[.weight] as? CGFloat ?? UIFont.Weight.regular.rawValue
                let weight = UIFont.Weight(rawValue: weightValue)
                label.font = UIFont.systemFont(ofSize: oldSize, weight: weight)
            }
        }
    }
    
    func applyFontToInvoiceLabel() {
        guard let label = invoiceLabel else { return }
        let oldFont = label.font!
        let oldSize = oldFont.pointSize
        
        switch selectedFontIndex {
        case 1: // Classic
            if let classicFont = UIFont(name: "SongMyung-Regular", size: oldSize) {
                label.font = classicFont
            }
        case 2: // Round
            if let roundFont = UIFont(name: "Urbanist-Regular", size: oldSize) {
                label.font = roundFont
            }
        default: // Normal (system, BOLD)
            label.font = UIFont.systemFont(ofSize: oldSize, weight: .bold)
        }
    }
}
