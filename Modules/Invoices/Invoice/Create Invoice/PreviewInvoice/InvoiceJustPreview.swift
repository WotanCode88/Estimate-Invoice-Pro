internal import UIKit
import SnapKit
import RealmSwift
import SwiftUI

struct InvoiceJustPreviewRepresentable: UIViewControllerRepresentable {
    let invoice: InvoiceModel

    func makeUIViewController(context: Context) -> InvoiceJustPreview {
        return InvoiceJustPreview(invoice: invoice)
    }

    func updateUIViewController(_ uiViewController: InvoiceJustPreview, context: Context) {
    }
}

final class InvoiceJustPreview: UIViewController {
    private let a4AspectRatio: CGFloat = 210.0 / 297.0

    private func fetchUser() -> UserModel? {
        let vm = UserViewModel.shared
        return vm.currentUser
    }
    
    var user: UserModel?
    let invoice: InvoiceModel
    
    init(invoice: InvoiceModel) {
        self.invoice = invoice
        super.init(nibName: nil, bundle: nil)
        self.user = fetchUser()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func onlyDate(_ value: Date?) -> String {
        guard let value = value else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
    
    func currencySymbol(for code: String) -> String {
        for localeID in Locale.availableIdentifiers {
            let locale = Locale(identifier: localeID)
            if locale.currencyCode == code, let symbol = locale.currencySymbol {
                return symbol
            }
        }
        return ""
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCustomNavBar()
        setupInvoice()
    }
}

extension InvoiceJustPreview {
    
    @objc private func didTapBack() {
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func setupCustomNavBar() {
        let navBar = UIView()
        navBar.backgroundColor = .clear
        navBar.layer.shadowColor = UIColor.black.cgColor
        navBar.layer.shadowOpacity = 0.06
        navBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        navBar.layer.shadowRadius = 4
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        let backButton = UIButton(type: .system)
        if let chevronImage = UIImage(systemName: "chevron.left") {
            backButton.setImage(chevronImage, for: .normal)
        }
        backButton.tintColor = .black
        backButton.contentHorizontalAlignment = .leading
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        navBar.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        let titleLabel = UILabel()
        if invoice.isEstimate {
            titleLabel.text = "Estimate Preview"
        } else {
            titleLabel.text = "Invoice Preview"
        }
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(2)
        }
    }
    
    func setupInvoice() {
        
        var invoiceLabels: [UILabel] = []
        
        let a4View = UIView()
        a4View.backgroundColor = .white
        a4View.layer.cornerRadius = 16
        a4View.layer.shadowColor = UIColor.black.cgColor
        a4View.layer.shadowOpacity = 0.07
        a4View.layer.shadowOffset = CGSize(width: 0, height: 4)
        a4View.layer.shadowRadius = 8
        view.addSubview(a4View)
        
        let maxWidth: CGFloat = 420
        let screenWidth = min(UIScreen.main.bounds.width * 0.9, maxWidth)
        let pageHeight = screenWidth / a4AspectRatio
        
        a4View.snp.makeConstraints { make in
            make.width.equalTo(screenWidth)
            make.height.equalTo(pageHeight)
            make.center.equalToSuperview()
        }
        
        let logoImageView = UIImageView()
        logoImageView.backgroundColor = .clear
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = 10
        logoImageView.clipsToBounds = true
        
        if let logoData = user?.logo, let image = UIImage(data: logoData) {
            logoImageView.image = image
        } else {
            logoImageView.image = UIImage(named: "emptyAvatar")
        }
        a4View.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalToSuperview().offset(40)
            make.width.height.equalTo(70)
        }
        
        let invoiceLabel = UILabel()
        if invoice.isEstimate {
            invoiceLabel.text = "ESTIMATE"
        } else {
            invoiceLabel.text = "INVOICE"
        }
        invoiceLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        invoiceLabel.textColor = .black
        invoiceLabel.textAlignment = .right
        a4View.addSubview(invoiceLabel)
        invoiceLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(40)
            make.top.equalTo(logoImageView)
        }
        invoiceLabels.append(invoiceLabel)
        
        let labelFont = UIFont.systemFont(ofSize: 6, weight: .medium)
        let labelColor = UIColor(white: 0.3, alpha: 1)
        
        let numberLabel = UILabel()
        numberLabel.text = "#\(invoice.number)"
        numberLabel.textColor = labelColor
        numberLabel.font = labelFont
        invoiceLabels.append(numberLabel)
        
        let dueLabel = UILabel()
        dueLabel.text = "Due \(onlyDate(invoice.due))"
        dueLabel.font = labelFont
        dueLabel.textColor = labelColor
        invoiceLabels.append(dueLabel)
        
        let issuedLabel = UILabel()
        issuedLabel.text = "Issued \(onlyDate(invoice.Issued))"
        issuedLabel.font = labelFont
        issuedLabel.textColor = labelColor
        invoiceLabels.append(issuedLabel)
        
        a4View.addSubview(numberLabel)
        a4View.addSubview(dueLabel)
        a4View.addSubview(issuedLabel)
        
        issuedLabel.snp.makeConstraints { const in
            const.bottom.equalTo(logoImageView)
            const.trailing.equalTo(invoiceLabel)
        }
        
        dueLabel.snp.makeConstraints { const in
            const.bottom.equalTo(issuedLabel.snp.top).offset(-4)
            const.trailing.equalTo(invoiceLabel)
        }
        
        numberLabel.snp.makeConstraints { const in
            const.bottom.equalTo(dueLabel.snp.top).offset(-4)
            const.trailing.equalTo(invoiceLabel)
        }
        
        // --- Rectangle under logo ---
        let infoRectangle = UIView()
        infoRectangle.backgroundColor = .white
        infoRectangle.layer.cornerRadius = 14
        infoRectangle.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        infoRectangle.layer.borderWidth = 1
        a4View.addSubview(infoRectangle)
        infoRectangle.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(18)
            make.left.equalTo(logoImageView)
            make.trailing.equalTo(invoiceLabel)
            make.height.equalTo(100)
        }
        
        // FROM (left column)
        let fromTitle = UILabel()
        fromTitle.text = "FROM"
        fromTitle.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        fromTitle.textColor = .black
        infoRectangle.addSubview(fromTitle)
        fromTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(12)
        }
        invoiceLabels.append(fromTitle)
        
        let fromName = UILabel()
        fromName.text = user?.name ?? ""
        fromName.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        fromName.textColor = .black
        infoRectangle.addSubview(fromName)
        fromName.snp.makeConstraints { make in
            make.top.equalTo(fromTitle.snp.bottom).offset(5)
            make.left.equalTo(fromTitle)
        }
        invoiceLabels.append(fromName)
        
        let fromMail = UILabel()
        fromMail.text = user?.email ?? ""
        fromMail.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        fromMail.textColor = .gray
        infoRectangle.addSubview(fromMail)
        fromMail.snp.makeConstraints { make in
            make.top.equalTo(fromName.snp.bottom).offset(2)
            make.left.equalTo(fromTitle)
        }
        invoiceLabels.append(fromMail)
        
        let fromPhone = UILabel()
        fromPhone.text = user?.phone != nil ? String(user!.phone!) : ""
        fromPhone.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        fromPhone.textColor = .gray
        infoRectangle.addSubview(fromPhone)
        fromPhone.snp.makeConstraints { make in
            make.top.equalTo(fromMail.snp.bottom).offset(2)
            make.left.equalTo(fromTitle)
        }
        invoiceLabels.append(fromPhone)
        
        let fromAddress = UILabel()
        fromAddress.text = user?.address ?? ""
        fromAddress.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        fromAddress.textColor = .gray
        fromAddress.numberOfLines = 2
        infoRectangle.addSubview(fromAddress)
        fromAddress.snp.makeConstraints { make in
            make.top.equalTo(fromPhone.snp.bottom).offset(2)
            make.left.equalTo(fromTitle)
            make.right.lessThanOrEqualTo(infoRectangle.snp.centerX).offset(-8)
        }
        invoiceLabels.append(fromAddress)
        
        // BILL TO (right column)
        let billToTitle = UILabel()
        billToTitle.text = "BILL TO"
        billToTitle.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        billToTitle.textColor = .black
        infoRectangle.addSubview(billToTitle)
        billToTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(infoRectangle.snp.centerX).offset(8)
        }
        invoiceLabels.append(billToTitle)
        
        let billToName = UILabel()
        billToName.text = invoice.client?.name ?? ""
        billToName.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        billToName.textColor = .black
        infoRectangle.addSubview(billToName)
        billToName.snp.makeConstraints { make in
            make.top.equalTo(billToTitle.snp.bottom).offset(5)
            make.left.equalTo(billToTitle)
        }
        invoiceLabels.append(billToName)
        
        let billToMail = UILabel()
        billToMail.text = invoice.client?.email ?? ""
        billToMail.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        billToMail.textColor = .gray
        infoRectangle.addSubview(billToMail)
        billToMail.snp.makeConstraints { make in
            make.top.equalTo(billToName.snp.bottom).offset(2)
            make.left.equalTo(billToTitle)
        }
        invoiceLabels.append(billToMail)
        
        let billToPhone = UILabel()
        billToPhone.text = invoice.client?.phone ?? ""
        billToPhone.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        billToPhone.textColor = .gray
        infoRectangle.addSubview(billToPhone)
        billToPhone.snp.makeConstraints { make in
            make.top.equalTo(billToMail.snp.bottom).offset(2)
            make.left.equalTo(billToTitle)
        }
        invoiceLabels.append(billToPhone)
        
        let billToAddress = UILabel()
        billToAddress.text = invoice.client?.addres ?? ""
        billToAddress.font = UIFont.systemFont(ofSize: 8, weight: .regular)
        billToAddress.textColor = .gray
        billToAddress.numberOfLines = 2
        infoRectangle.addSubview(billToAddress)
        billToAddress.snp.makeConstraints { make in
            make.top.equalTo(billToPhone.snp.bottom).offset(2)
            make.left.equalTo(billToTitle)
            make.right.equalToSuperview().inset(12)
        }
        invoiceLabels.append(billToAddress)
        
        // --- ВСТАВКА ФОТО, если оно есть ---
        var photoImageView: UIImageView?
        if let photoData = invoice.photo, let image = UIImage(data: photoData) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            a4View.addSubview(imageView)
            
            photoImageView = imageView
            imageView.snp.makeConstraints { make in
                make.top.equalTo(infoRectangle.snp.bottom).offset(12)
                make.left.equalTo(infoRectangle).offset(12)
                make.right.equalTo(infoRectangle).inset(12)
                make.height.equalTo(100)
                make.width.equalTo(100)
            }
        }
        
        // --- Horizontal gray rectangle under infoRectangle (или фото) ---
        let itemsHeaderView = UIView()
        itemsHeaderView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        itemsHeaderView.layer.cornerRadius = 8
        a4View.addSubview(itemsHeaderView)
        itemsHeaderView.snp.makeConstraints { make in
            if let photo = photoImageView {
                make.top.equalTo(photo.snp.bottom).offset(12)
            } else {
                make.top.equalTo(infoRectangle.snp.bottom).offset(18)
            }
            make.leading.equalTo(infoRectangle)
            make.trailing.equalTo(infoRectangle)
            make.height.equalTo(20)
        }
        
        // Лейбл ITEM слева
        let itemLabel = UILabel()
        itemLabel.text = "ITEM"
        itemLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        itemLabel.textColor = .black
        itemsHeaderView.addSubview(itemLabel)
        itemLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        invoiceLabels.append(itemLabel)
        
        // Лейблы справа
        let amountLabel = UILabel()
        amountLabel.text = "AMOUNT,\(invoice.currency ?? "")"
        amountLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        amountLabel.textColor = .black
        itemsHeaderView.addSubview(amountLabel)
        invoiceLabels.append(amountLabel)
        
        let priceLabel = UILabel()
        priceLabel.text = "PRICE,\(invoice.currency ?? "")"
        priceLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        priceLabel.textColor = .black
        itemsHeaderView.addSubview(priceLabel)
        invoiceLabels.append(priceLabel)
        
        let quantityLabel = UILabel()
        quantityLabel.text = "QUANTITY"
        quantityLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        quantityLabel.textColor = .black
        itemsHeaderView.addSubview(quantityLabel)
        invoiceLabels.append(quantityLabel)
        
        amountLabel.snp.makeConstraints { const in
            const.trailing.equalToSuperview().offset(-10)
            const.centerY.equalToSuperview()
        }
        
        priceLabel.snp.makeConstraints { const in
            const.centerY.equalToSuperview()
            const.trailing.equalTo(amountLabel.snp.leading).offset(-10)
        }
        
        quantityLabel.snp.makeConstraints { const in
            const.centerY.equalToSuperview()
            const.trailing.equalTo(priceLabel.snp.leading).offset(-10)
        }
        
        var lastItemView: UIView = itemsHeaderView
        let items = Array(invoice.item)
        
        // --- Тело таблицы с айтемами ---
        for item in items {
            let rowView = UIView()
            a4View.addSubview(rowView)
            rowView.snp.makeConstraints { make in
                make.top.equalTo(lastItemView.snp.bottom).offset(0)
                make.leading.trailing.equalTo(itemsHeaderView)
                make.height.equalTo(20)
            }
            
            // ITEM NAME под ITEM (слева)
            let nameLabel = UILabel()
            nameLabel.text = item.name
            nameLabel.font = UIFont.systemFont(ofSize: 6, weight: .regular)
            nameLabel.textColor = .black
            rowView.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
            invoiceLabels.append(nameLabel)
            
            // QUANTITY под QUANTITY (справа)
            let quantityValueLabel = UILabel()
            quantityValueLabel.text = "\(item.quantity)"
            quantityValueLabel.font = UIFont.systemFont(ofSize: 6, weight: .regular)
            quantityValueLabel.textColor = .black
            rowView.addSubview(quantityValueLabel)
            quantityValueLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalTo(priceLabel.snp.leading).offset(-10)
            }
            invoiceLabels.append(quantityLabel)
            
            // PRICE под PRICE (ещё правее)
            let priceValueLabel = UILabel()
            priceValueLabel.text = "\(currencySymbol(for: invoice.currency))\(String(format: "%.2f", item.price))"
            priceValueLabel.font = UIFont.systemFont(ofSize: 6, weight: .regular)
            priceValueLabel.textColor = .black
            rowView.addSubview(priceValueLabel)
            priceValueLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalTo(amountLabel.snp.leading).offset(-10)
            }
            invoiceLabels.append(priceLabel)
            
            let finalAmount = (item.price * Double(item.quantity))
            let amountValueLabel = UILabel()
            amountValueLabel.text = "\(currencySymbol(for: invoice.currency))\(String(format: "%.2f", finalAmount))"
            amountValueLabel.font = UIFont.systemFont(ofSize: 6, weight: .regular)
            amountValueLabel.textColor = .black
            rowView.addSubview(amountValueLabel)
            amountValueLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-10)
            }
            invoiceLabels.append(amountValueLabel)
            
            lastItemView = rowView
        }
        
        let separator = UIView()
        separator.backgroundColor = UIColor(white: 0.85, alpha: 1)
        a4View.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalTo(lastItemView.snp.bottom).offset(10)
            make.height.equalTo(1)
            make.leading.equalTo(quantityLabel)
            make.trailing.equalTo(amountLabel)
        }
        
        // SUBTOTAL label
        let subtotalLabel = UILabel()
        subtotalLabel.text = "SUBTOTAL"
        subtotalLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        subtotalLabel.textColor = .black
        a4View.addSubview(subtotalLabel)
        subtotalLabel.snp.makeConstraints { make in
            make.leading.equalTo(separator)
            make.top.equalTo(separator.snp.bottom).offset(5)
        }
        invoiceLabels.append(subtotalLabel)
        
        let subtotalValueLabel = UILabel()
        subtotalValueLabel.text = "\(currencySymbol(for: invoice.currency))\(String(format: "%.2f", invoice.total))"
        subtotalValueLabel.font = UIFont.systemFont(ofSize: 6, weight: .regular)
        subtotalValueLabel.textColor = .black
        a4View.addSubview(subtotalValueLabel)
        subtotalValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(separator)
            make.top.equalTo(subtotalLabel)
        }
        invoiceLabels.append(subtotalValueLabel)
        
        // TOTAL label (ниже)
        let totalLabel = UILabel()
        totalLabel.text = "TOTAL"
        totalLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        totalLabel.textColor = .black
        a4View.addSubview(totalLabel)
        totalLabel.snp.makeConstraints { make in
            make.leading.equalTo(separator)
            make.top.equalTo(subtotalLabel.snp.bottom).offset(5)
        }
        invoiceLabels.append(totalLabel)
        
        let totalValueLabel = UILabel()
        totalValueLabel.text = "\(currencySymbol(for: invoice.currency))\(String(format: "%.2f", totalAmount()))"
        totalValueLabel.font = UIFont.systemFont(ofSize: 6, weight: .bold)
        totalValueLabel.textColor = .black
        a4View.addSubview(totalValueLabel)
        totalValueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(separator)
            make.top.equalTo(totalLabel)
        }
        invoiceLabels.append(totalValueLabel)
    }
}
