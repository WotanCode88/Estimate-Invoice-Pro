internal import UIKit
import RealmSwift
import SnapKit

class SingleEstimateVC: UIViewController, UIColorPickerViewControllerDelegate {
    init(invoice: InvoiceModel, isCustom: Bool) {
        self.invoice = invoice
        self.isCustom = isCustom
        super.init(nibName: nil, bundle: nil)
        self.user = fetchUser()
    }
    
    private let invoice: InvoiceModel
    private var user: UserModel?
    weak var delegate: InvoicePreviewDelegate?
    
    private let a4AspectRatio: CGFloat = 210.0 / 297.0
    private var navBarDoneButton: UIButton?
    private var bottomWhiteView: UIView?
    
    private var invoiceLabel: UILabel?
    private var infoRectangle: UIView?
    private var itemsHeaderView: UIView?
    
    private var selectedColorAsset: String?
    private var selectedFontIndex: Int = 0
    
    private var allInvoiceLabels: [UILabel] = []
    private var originalLabelFontSizes: [CGFloat] = []
    
    private var bottomDoneButton: UIButton?
    private var sendInvoiceButton: UIButton?
    
    private(set) var wasPaid: Bool = false {
        didSet {
            showFinal()
        }
    }
    private(set) var selectedPayMethod: String? {
        didSet {
            savePaidStatus(payMethod: selectedPayMethod!, wasPaid: wasPaid)
        }
    }
    
    @objc private func didTapShare() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else { return }
        let pdfData = a4View.asPDFData()
        let fileName = "Estimete-\(invoice.number).pdf"
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tmpURL)
            let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: 100, width: 0, height: 0)
            }
            present(activityVC, animated: true)
        } catch {
            showErrorAlert(error: error)
        }
    }
    
    @objc private func didTapPrint() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else { return }
        let pdfData = a4View.asPDFData()
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Estimate-\(invoice.number)"
        printInfo.outputType = .general
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.printingItem = pdfData
        printController.present(animated: true, completionHandler: nil)
    }
    
    func savePaidStatus(payMethod: String, wasPaid: Bool) {
        let realm = try? Realm()
        guard let realm = realm else { return }
        do {
            try realm.write {
                invoice.payMethod = payMethod
                invoice.wasPaid = wasPaid
            }
        } catch {
            print("Error saving paid status: \(error)")
        }
    }
    
    var isCustom: Bool {
        didSet {
            updateNavBarDoneButtonTitle()
            updateBottomButtonVisibility()
        }
    }
    
    private func updateNavBarDoneButtonTitle() {
        let title = isCustom ? "Done" : "Custom"
        navBarDoneButton?.setTitle(title, for: .normal)
    }
    
    private func updateBottomButtonVisibility() {
        if isCustom {
            bottomDoneButton?.isHidden = true
            bottomWhiteView?.isHidden = false
        } else {
            bottomDoneButton?.isHidden = false
            bottomWhiteView?.isHidden = true
        }
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fetchUser() -> UserModel? {
        let vm = UserViewModel.shared
        return vm.currentUser
    }
    
    private func onlyDate(_ value: Date?) -> String {
        guard let value = value else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6
        navigationController?.navigationBar.isHidden = true
        setupInvoice()
        setupCustomNavBar()
        if invoice.wasPaid {
            wasPaid = true
        }
        if isCustom {
            setupBottomDoneButtonAndWhiteView()
        } else {
            showFinal()
        }
        updateNavBarDoneButtonTitle()
    }
    
    private func changeColor(_ color: UIColor) {
        invoiceLabel?.textColor = color
        infoRectangle?.layer.borderColor = color.cgColor
        itemsHeaderView?.backgroundColor = color
    }
    
    private func resetToDefaultColors() {
        invoiceLabel?.textColor = .black
        infoRectangle?.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        itemsHeaderView?.backgroundColor = UIColor(white: 0.96, alpha: 1)
    }
    
    private var backButton: UIButton?
    private var navBar: UIView?
    
    private func setupCustomNavBar() {
        navBar = UIView()
        guard let navBar = navBar else { return }
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
        
        backButton = UIButton(type: .system)
        guard let backButton = backButton else { return }
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
        titleLabel.text = "Estimate"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(2)
        }
        
        let doneButton = UIButton(type: .system)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        doneButton.setTitleColor(.black, for: .normal)
        navBar.addSubview(doneButton)
        doneButton.tag = 999_111
        doneButton.addTarget(self, action: #selector(didTapNavBarDone), for: .touchUpInside)
        doneButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(60)
        }
        self.navBarDoneButton = doneButton
    }
    
    @objc private func didTapPresentSendInvoice() {
        view.viewWithTag(999_111)?.removeFromSuperview()
        isCustom = false
        showFinal()
    }
    
    @objc private func convertToInvoice() {
        let realm = try? Realm()
        guard let realm = realm else { return }
        do {
            try realm.write {
                invoice.isEstimate = false
            }
            let alert = UIAlertController(
                title: "Converted",
                message: "The estimate has been converted to an invoice. You can find it in the Invoices section.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            if let topVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                var presenter = topVC
                while let presented = presenter.presentedViewController { presenter = presented }
                presenter.present(alert, animated: true, completion: nil)
            }
        } catch {
            print("Error saving paid status: \(error)")
        }
    }
    
    private func showFinal() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        view.viewWithTag(999_400)?.removeFromSuperview()
        hideNavDoneButton()
        scaleA4View()
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Estimate", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = .black
        sendButton.layer.cornerRadius = 14
        sendButton.clipsToBounds = true
        sendButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(14)
        }
        self.sendInvoiceButton = sendButton
        
        let convertButton = UIButton(type: .system)
        convertButton.setTitle("Convert to Invoice", for: .normal)
        convertButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        convertButton.setTitleColor(.black, for: .normal)
        convertButton.backgroundColor = .white
        convertButton.layer.cornerRadius = 14
        convertButton.layer.borderWidth = 2
        convertButton.layer.borderColor = UIColor.black.cgColor
        convertButton.clipsToBounds = true
        convertButton.tag = 999_400
        view.addSubview(convertButton)
        convertButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalTo(sendButton.snp.top).offset(-10)
        }
        convertButton.addTarget(self, action: #selector(convertToInvoice), for: .touchUpInside)
        
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .fill
        horizontalStack.distribution = .fillEqually
        horizontalStack.spacing = 12
        horizontalStack.tag = 999_444
        view.addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(70)
            make.bottom.equalTo(convertButton.snp.top).offset(-14)
        }
        
        let shareButton = UIButton(type: .system)
        shareButton.backgroundColor = .white
        shareButton.layer.cornerRadius = 14
        shareButton.clipsToBounds = true
        shareButton.adjustsImageWhenHighlighted = true
        
        let shareIcon = UIImageView(image: UIImage(systemName: "square.and.arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)))
        shareIcon.tintColor = .black
        shareIcon.contentMode = .scaleAspectFit
        shareButton.addSubview(shareIcon)
        shareIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        let shareLabel = UILabel()
        shareLabel.text = "Share"
        shareLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        shareLabel.textColor = .black
        shareLabel.textAlignment = .center
        shareButton.addSubview(shareLabel)
        shareLabel.snp.makeConstraints { make in
            make.top.equalTo(shareIcon.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(9)
        }
        
        let printButton = UIButton(type: .system)
        printButton.backgroundColor = .white
        printButton.layer.cornerRadius = 14
        printButton.clipsToBounds = true
        printButton.adjustsImageWhenHighlighted = true
        
        let printIcon = UIImageView(image: UIImage(systemName: "printer", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)))
        printIcon.tintColor = .black
        printIcon.contentMode = .scaleAspectFit
        printButton.addSubview(printIcon)
        printIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        let printLabel = UILabel()
        printLabel.text = "Print"
        printLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        printLabel.textColor = .black
        printLabel.textAlignment = .center
        printButton.addSubview(printLabel)
        printLabel.snp.makeConstraints { make in
            make.top.equalTo(printIcon.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(9)
        }
        
        let editButton = UIButton(type: .system)
        editButton.backgroundColor = .white
        editButton.layer.cornerRadius = 14
        editButton.clipsToBounds = true
        editButton.adjustsImageWhenHighlighted = true
        
        let editIcon = UIImageView(image: UIImage(systemName: "pencil.line", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)))
        editIcon.tintColor = .black
        editIcon.contentMode = .scaleAspectFit
        editButton.addSubview(editIcon)
        editIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        let editLabel = UILabel()
        editLabel.text = "Edit"
        editLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        editLabel.textColor = .black
        editLabel.textAlignment = .center
        editButton.addSubview(editLabel)
        editLabel.snp.makeConstraints { make in
            make.top.equalTo(editIcon.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(9)
        }
        
        editButton.addTarget(self, action: #selector(didTapEditFinal), for: .touchUpInside)
        editButton.accessibilityLabel = "Edit"
        
        horizontalStack.addArrangedSubview(shareButton)
        horizontalStack.addArrangedSubview(printButton)
        horizontalStack.addArrangedSubview(editButton)
        
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        printButton.addTarget(self, action: #selector(didTapPrint), for: .touchUpInside)
        
        bottomDoneButton?.isHidden = true
        
        
        let infoRect = UIView()
        infoRect.backgroundColor = .white
        infoRect.layer.cornerRadius = 14
        infoRect.layer.borderWidth = 1
        infoRect.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
        infoRect.tag = 999_446
        view.addSubview(infoRect)
        infoRect.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(94) // больше чем paidRect
            make.bottom.equalTo(horizontalStack.snp.top).offset(-14)
        }
        
        // --- Горизонтальный разделитель внутри infoRect ---
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1)
        infoRect.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(0)
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // --- Верхняя часть (Issued) ---
        let issuedLabel = UILabel()
        issuedLabel.text = "Issued"
        issuedLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        issuedLabel.textColor = .black
        issuedLabel.textAlignment = .left
        infoRect.addSubview(issuedLabel)
        issuedLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(16)
        }
        
        let issuedValueLabel = UILabel()
        issuedValueLabel.text = onlyDate(invoice.Issued)
        issuedValueLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        issuedValueLabel.textColor = .black
        issuedValueLabel.textAlignment = .right
        infoRect.addSubview(issuedValueLabel)
        issuedValueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(issuedLabel)
            make.right.equalToSuperview().inset(16)
        }
        
        let invoiceLabel = UILabel()
        invoiceLabel.text = "Estimate #"
        invoiceLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        invoiceLabel.textColor = .black
        invoiceLabel.textAlignment = .left
        infoRect.addSubview(invoiceLabel)
        invoiceLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(14)
            make.left.equalToSuperview().offset(16)
        }
        
        let invoiceNumberLabel = UILabel()
        invoiceNumberLabel.text = "\(invoice.number)"
        invoiceNumberLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        invoiceNumberLabel.textColor = .black
        invoiceNumberLabel.textAlignment = .right
        infoRect.addSubview(invoiceNumberLabel)
        invoiceNumberLabel.snp.makeConstraints { make in
            make.centerY.equalTo(invoiceLabel)
            make.right.equalToSuperview().inset(16)
        }
        
        let clientRect = UIView()
        clientRect.backgroundColor = .white
        clientRect.layer.cornerRadius = 14
        clientRect.layer.borderWidth = 1
        clientRect.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
        clientRect.tag = 999_447
        view.addSubview(clientRect)
        clientRect.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(90)
            make.bottom.equalTo(infoRect.snp.top).offset(-14)
        }
        
        // Имя клиента (по центру)
        let clientNameLabel = UILabel()
        clientNameLabel.text = invoice.client?.name ?? ""
        clientNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        clientNameLabel.textColor = .black
        clientNameLabel.textAlignment = .center
        clientRect.addSubview(clientNameLabel)
        clientNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        
        // Сумма totalAmount (без валюты, по центру)
        let totalLabel = UILabel()
        let symbol = currencySymbol(for: invoice.currency ?? "")
        totalLabel.text = "\(symbol)\(String(format: "%.2f", totalAmount()))"
        totalLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        totalLabel.textColor = .black
        totalLabel.textAlignment = .center
        clientRect.addSubview(totalLabel)
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(clientNameLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
    }
    
    @objc private func showPaid() {
        let dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimView.alpha = 0
        dimView.isUserInteractionEnabled = true
        view.addSubview(dimView)
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let sheetView = UIView()
        sheetView.backgroundColor = .white
        sheetView.layer.cornerRadius = 20
        sheetView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheetView.clipsToBounds = true
        view.addSubview(sheetView)
        
        // --- Mark as paid (bold, top) ---
        let titleLabel = UILabel()
        titleLabel.text = "Mark as paid"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        sheetView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.right.equalToSuperview().inset(20)
        }
        
        // --- Select how you received the money ---
        let selectLabel = UILabel()
        selectLabel.text = "Select how you received the money"
        selectLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        selectLabel.textColor = .black
        selectLabel.textAlignment = .center
        sheetView.addSubview(selectLabel)
        selectLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }
        
        // --- Gray label with today's date ---
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        dateLabel.text = formatter.string(from: Date())
        dateLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        dateLabel.textColor = UIColor(white: 0.5, alpha: 1)
        dateLabel.textAlignment = .center
        sheetView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(selectLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(20)
        }
        
        // --- Payment method buttons ---
        let paymentStack = UIStackView()
        paymentStack.axis = .horizontal
        paymentStack.alignment = .fill
        paymentStack.distribution = .fillEqually
        paymentStack.spacing = 12
        sheetView.addSubview(paymentStack)
        paymentStack.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(70)
            make.top.equalTo(dateLabel.snp.bottom).offset(24)
        }
        
        // Массив для сопоставления ассетов и строк в модели
        let paymentMethods: [(asset: String, method: String)] = [
            ("cashAsset", "Cash"),
            ("checkAsset", "Check"),
            ("bankAsset", "Bank"),
            ("payPalAsset", "PayPal")
        ]
        
        for (asset, method) in paymentMethods {
            let button = UIButton(type: .system)
            button.backgroundColor = .white
            button.layer.cornerRadius = 14
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
            button.clipsToBounds = true
            
            let imageView = UIImageView(image: UIImage(named: asset))
            imageView.contentMode = .scaleAspectFit
            button.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(60)
            }
            button.addAction(UIAction { [weak self, weak sheetView, weak dimView] _ in
                sheetView?.isUserInteractionEnabled = false
                UIView.animate(withDuration: 0.18, animations: {
                    sheetView?.alpha = 0
                    dimView?.alpha = 0
                }) { _ in
                    sheetView?.removeFromSuperview()
                    dimView?.removeFromSuperview()
                    self?.wasPaid = true
                    self?.selectedPayMethod = method
                }
            }, for: .touchUpInside)
            paymentStack.addArrangedSubview(button)
        }
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 14
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
        cancelButton.clipsToBounds = true
        sheetView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.left.right.equalTo(sheetView).inset(20)
            make.height.equalTo(52)
            make.top.equalTo(paymentStack.snp.bottom).offset(20)
            make.bottom.equalTo(sheetView.safeAreaLayoutGuide).inset(14)
        }
        
        sheetView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(60)
        }
        
        UIView.animate(withDuration: 0.22) {
            dimView.alpha = 1
        }
        
        cancelButton.addAction(UIAction { [weak sheetView, weak dimView] _ in
            UIView.animate(withDuration: 0.18, animations: {
                sheetView?.alpha = 0
                dimView?.alpha = 0
            }) { _ in
                sheetView?.removeFromSuperview()
                dimView?.removeFromSuperview()
            }
        }, for: .touchUpInside)
    }
    
    @objc private func didTapNavBarDone() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        view.viewWithTag(999_400)?.removeFromSuperview()

        isCustom.toggle()
    }
    
    @objc private func didTapEditFinal() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        view.viewWithTag(999_400)?.removeFromSuperview()
        
        setupBottomDoneButtonAndWhiteView()
    }
    func showNavDoneButton() {
        navBarDoneButton?.removeFromSuperview()
        
        guard let navBar = navBar else { return }
        let doneButton = UIButton(type: .system)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        doneButton.setTitleColor(.black, for: .normal)
        doneButton.setTitle(isCustom ? "Done" : "Custom", for: .normal)
        doneButton.tag = 999_111
        doneButton.addTarget(self, action: #selector(didTapNavBarDone), for: .touchUpInside)
        navBar.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(60)
        }
        self.navBarDoneButton = doneButton
    }
    
    func hideNavDoneButton() {
        navBarDoneButton?.removeFromSuperview()
        navBarDoneButton = nil
    }
    
    private var a4View: UIView?
    
    func scaleA4View(to scale: CGFloat = 0.8) {
        guard let a4View = a4View else { return }

        a4View.transform = .identity

        var physicalTop: CGFloat = 0
        
        if scale == 0.8 {
            physicalTop = 55
        } else if scale == 1 {
            physicalTop = 120
        }
        
        a4ViewTopConstraint?.update(offset: physicalTop)

        a4View.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    private func setupBottomDoneButtonAndWhiteView() {
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        view.viewWithTag(999_400)?.removeFromSuperview()
        
        self.bottomWhiteView?.removeFromSuperview()
        self.bottomWhiteView = nil
        self.bottomDoneButton?.removeFromSuperview()
        self.bottomDoneButton = nil

        isCustom = true
        showNavDoneButton()
        updateNavBarDoneButtonTitle()
        scaleA4View(to: 1)
        
        
        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = .black
        doneButton.layer.cornerRadius = 14
        doneButton.clipsToBounds = true
        doneButton.addTarget(self, action: #selector(didTapPresentSendInvoice), for: .touchUpInside)
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(52)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(14)
        }
        self.bottomDoneButton = doneButton
        
        let whiteView = UIView()
        whiteView.backgroundColor = .white
        whiteView.layer.cornerRadius = 20
        whiteView.layer.shadowColor = UIColor.black.cgColor
        whiteView.layer.shadowOpacity = 0.08
        whiteView.layer.shadowOffset = CGSize(width: 0, height: -2)
        whiteView.layer.shadowRadius = 10
        whiteView.clipsToBounds = false
        view.addSubview(whiteView)
        whiteView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(370)
            make.bottom.equalToSuperview()
        }
        
        // --- Лейбл "Colors" ---
        let colorsLabel = UILabel()
        colorsLabel.text = "Color"
        colorsLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        colorsLabel.textColor = .black
        whiteView.addSubview(colorsLabel)
        colorsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.left.equalToSuperview().offset(24)
        }
        
        let colorsStack = UIStackView()
        colorsStack.axis = .horizontal
        colorsStack.alignment = .center
        colorsStack.distribution = .equalSpacing
        colorsStack.spacing = 0
        whiteView.addSubview(colorsStack)
        colorsStack.snp.makeConstraints { make in
            make.top.equalTo(colorsLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().inset(24)
            make.height.equalTo(52)
        }
        
        
        let assetNames = [
            "customWhiteAsset",
            "customBlueAsset",
            "customOrangeAsset",
            "customSeaAsset",
            "customPurpleAsset",
            "customGreenAsset",
            "customColorsAsset"
        ]
        
        // Цвета для ассетов (порядок соответствует assetNames)
        let colorValues: [UIColor] = [
            .gray,
            .customBlue, // customBlueAsset
            .customOrange,  // customOrangeAsset
            .customSea, // customSeaAsset
            .customPurple,  // customPurpleAsset
            .customGreen, // customGreenAsset
            UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1)  // customColorsAsset (не используется)
        ]
        
        let isSubscribed = user?.isSubscribed ?? false
        
        // --- Сохраним контейнеры для обновления галочек
        var colorContainers: [String: UIView] = [:]
        var checkmarkViews: [String: UIImageView] = [:]
        
        for (index, asset) in assetNames.enumerated() {
            let container = UIView()
            container.snp.makeConstraints { make in
                make.width.height.equalTo(44)
            }
            
            let imageView = UIImageView()
            imageView.image = UIImage(named: asset)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            container.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // --- Добавляем бейдж needSubAsset если не подписан и не customWhiteAsset
            var hasBadge = false
            if !isSubscribed && asset != "customWhiteAsset" {
                hasBadge = true
                let badgeView = UIImageView()
                badgeView.image = UIImage(named: "needSubAsset")
                badgeView.contentMode = .scaleAspectFit
                badgeView.clipsToBounds = true
                container.addSubview(badgeView)
                badgeView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(0)
                    make.right.equalToSuperview().offset(0)
                    make.width.height.equalTo(18)
                }
            }
            
            // -- Галочка: добавляем всегда, скрываем если не выбрано
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
            checkmark.tintColor = .black
            checkmark.contentMode = .scaleAspectFit
            checkmark.isHidden = (selectedColorAsset != asset)
            container.addSubview(checkmark)
            checkmark.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(24)
            }
            checkmarkViews[asset] = checkmark
            
            // Add tap gesture recognizer for color selection
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleColorTap(_:)))
            container.isUserInteractionEnabled = true
            container.addGestureRecognizer(tap)
            container.tag = hasBadge ? 1 : 0 // tag 1 — нужен subscription
            container.accessibilityIdentifier = asset // чтобы знать какой цвет!
            
            colorsStack.addArrangedSubview(container)
            colorContainers[asset] = container
        }
        
        // --- Сохраняем для обновления галочек
        self.colorContainers = colorContainers
        self.checkmarkViews = checkmarkViews
        
        self.bottomWhiteView = whiteView
        
        // -- Изначальный выбор (дефолтный)
        if selectedColorAsset == nil {
            selectedColorAsset = "customWhiteAsset"
            updateCheckmarks()
        }
        
        // --------- Новый блок: Лейбл Font ----------
        let fontLabel = UILabel()
        fontLabel.text = "Font"
        fontLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        fontLabel.textColor = .black
        whiteView.addSubview(fontLabel)
        fontLabel.snp.makeConstraints { make in
            make.top.equalTo(colorsStack.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(24)
        }
        
        // --------- Новый блок: Font секции ----------
        let fontStack = UIStackView()
        fontStack.axis = .horizontal
        fontStack.alignment = .center
        fontStack.distribution = .equalSpacing
        fontStack.spacing = 0
        whiteView.addSubview(fontStack)
        fontStack.snp.makeConstraints { make in
            make.top.equalTo(fontLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        let fontNames = ["Normal", "Classic", "Round"]
        fontButtons = []
        for (i, fontName) in fontNames.enumerated() {
            let fontButton = UIButton(type: .system)
            fontButton.setTitle(fontName, for: .normal)
            if fontName == "Normal" {
                fontButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            } else if fontName == "Classic" {
                fontButton.titleLabel?.font = UIFont(name: "SongMyung-Regular", size: 17)
            } else if fontName == "Round" {
                fontButton.titleLabel?.font = UIFont(name: "Urbanist-Regular", size: 17)
            }
            
            fontButton.setTitleColor(.black, for: .normal)
            fontButton.backgroundColor = .white
            fontButton.layer.borderWidth = 2
            fontButton.layer.cornerRadius = 12
            fontButton.clipsToBounds = true
            fontButton.snp.makeConstraints { const in
                const.height.equalTo(44)
                const.width.equalTo((view.frame.width - 63) / 3)
            }
            fontButton.tag = i
            
            // ---- Добавляем бейдж needSubAsset для Classic и Round если нет подписки ----
            var hasBadge = false
            if !isSubscribed && (fontName == "Classic" || fontName == "Round") {
                hasBadge = true
                let badgeView = UIImageView()
                badgeView.image = UIImage(named: "needSubAsset")
                badgeView.contentMode = .scaleAspectFit
                badgeView.clipsToBounds = true
                fontButton.addSubview(badgeView)
                badgeView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(0)
                    make.right.equalToSuperview().offset(-2)
                    make.width.height.equalTo(18)
                }
            }
            
            if hasBadge {
                fontButton.addTarget(self, action: #selector(handleFontSubRequired(_:)), for: .touchUpInside)
            } else {
                fontButton.addTarget(self, action: #selector(handleFontTap(_:)), for: .touchUpInside)
            }
            
            fontButtons.append(fontButton)
            fontStack.addArrangedSubview(fontButton)
        }
        updateFontSelectionUI()
        
        // --------- Новый блок: Лейбл Size ----------
        let sizeLabel = UILabel()
        sizeLabel.text = "Size"
        sizeLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        sizeLabel.textColor = .black
        whiteView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.top.equalTo(fontStack.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(24)
        }
        
        // --------- Size секция ----------
        let sizeStack = UIStackView()
        sizeStack.axis = .horizontal
        sizeStack.alignment = .center
        sizeStack.distribution = .equalSpacing
        sizeStack.spacing = 12
        whiteView.addSubview(sizeStack)
        sizeStack.snp.makeConstraints { make in
            make.top.equalTo(sizeLabel.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }
        
        sizeButtons = []
        let sizes: [CGFloat] = [16, 24]
        for (i, fontSize) in sizes.enumerated() {
            let sizeButton = UIButton(type: .system)
            // Формируем отображение Аа
            let aaString = NSMutableAttributedString()
            // Большая A
            let bigA = NSAttributedString(string: "A", attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: UIColor.black
            ])
            // маленькая а
            let smallA = NSAttributedString(string: "a", attributes: [
                .font: UIFont.systemFont(ofSize: fontSize * 0.7, weight: .regular),
                .foregroundColor: UIColor.black
            ])
            aaString.append(bigA)
            aaString.append(smallA)
            sizeButton.setAttributedTitle(aaString, for: .normal)
            
            sizeButton.backgroundColor = .white
            sizeButton.layer.borderWidth = 2
            sizeButton.layer.cornerRadius = 12
            sizeButton.clipsToBounds = true
            sizeButton.snp.makeConstraints { const in
                const.height.equalTo(44)
                const.width.equalTo((view.frame.width - 63) / 2)
            }
            sizeButton.tag = i
            
            // --- Если нет подписки и это ВТОРАЯ кнопка (увеличенный размер) ---
            var hasBadge = false
            if !isSubscribed && i == 1 {
                hasBadge = true
                let badgeView = UIImageView()
                badgeView.image = UIImage(named: "needSubAsset")
                badgeView.contentMode = .scaleAspectFit
                badgeView.clipsToBounds = true
                sizeButton.addSubview(badgeView)
                badgeView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(0)
                    make.right.equalToSuperview().offset(-2)
                    make.width.height.equalTo(18)
                }
            }
            
            if hasBadge {
                sizeButton.addTarget(self, action: #selector(handleSizeSubRequired(_:)), for: .touchUpInside)
            } else {
                sizeButton.addTarget(self, action: #selector(handleSizeTap(_:)), for: .touchUpInside)
            }
            
            sizeButtons.append(sizeButton)
            sizeStack.addArrangedSubview(sizeButton)
        }
        updateSizeSelectionUI()
        self.bottomWhiteView = whiteView
    }
    
    @objc private func handleSizeTap(_ sender: UIButton) {
        selectedInvoiceFontSizeIndex = sender.tag
        updateSizeSelectionUI()
        applyFontToInvoiceLabelsWithSize()
        applyFontToInvoiceLabel() // если меняешь отдельно (см. ниже)
    }
    
    private func applyFontToInvoiceLabelsWithSize() {
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
    
    @objc private func handleSizeSubRequired(_ sender: UIButton) {
        delegate?.presentSubscription()
    }
    
    // --- Свойство для хранения size-кнопок и выбранного размера ---
    private var sizeButtons: [UIButton] = []
    private var selectedInvoiceFontSizeIndex: Int = 0
    private let invoiceFontSizes: [CGFloat] = [16, 24]
    
    // --- Логика выбора размера ---
    private func updateSizeSelectionUI() {
        for (i, button) in sizeButtons.enumerated() {
            button.layer.borderColor = (i == selectedInvoiceFontSizeIndex ? UIColor.black.cgColor : UIColor.lightGray.cgColor)
        }
    }
    
    @objc private func handleFontSubRequired(_ sender: UIButton) {
        delegate?.presentSubscription()
    }
    
    @objc private func handleFontTap(_ sender: UIButton) {
        selectedFontIndex = sender.tag
        updateFontSelectionUI()
        applyFontToAllLabels()
        applyFontToInvoiceLabel()
    }
    
    private func applyFontToAllLabels() {
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
    
    private func applyFontToInvoiceLabel() {
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
    
    private var fontButtons: [UIButton] = []
    
    private func updateFontSelectionUI() {
        for (i, button) in fontButtons.enumerated() {
            button.layer.borderColor = (i == selectedFontIndex ? UIColor.black.cgColor : UIColor.lightGray.cgColor)
        }
    }
    
    private var colorContainers: [String: UIView] = [:]
    private var checkmarkViews: [String: UIImageView] = [:]
    
    private func updateCheckmarks() {
        for (asset, checkmark) in checkmarkViews {
            checkmark.isHidden = (asset != selectedColorAsset)
        }
    }
    
    @objc private func handleColorTap(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        let asset = tappedView.accessibilityIdentifier ?? ""
        let isSubscribed = user?.isSubscribed ?? false
        
        if tappedView.tag == 1 {
            delegate?.presentSubscription()
            return
        }
        
        let assetNames = [
            "customWhiteAsset",
            "customBlueAsset",
            "customOrangeAsset",
            "customSeaAsset",
            "customPurpleAsset",
            "customGreenAsset",
            "customColorsAsset"
        ]
        let colorValues: [UIColor] = [
            .gray,
            .customBlue, // customBlueAsset
            .customOrange,  // customOrangeAsset
            .customSea, // customSeaAsset
            .customPurple,  // customPurpleAsset
            .customGreen, // customGreenAsset
            UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1)
        ]
        
        if asset == "customWhiteAsset" {
            selectedColorAsset = asset
            resetToDefaultColors()
        } else if asset == "customColorsAsset" {
            presentColorPicker()
        } else if let idx = assetNames.firstIndex(of: asset) {
            let color = colorValues[idx]
            selectedColorAsset = asset
            changeColor(color)
        }
        
        updateCheckmarks()
    }
    
    private func presentColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    private func showBottomDoneButton(_ show: Bool) {
        bottomDoneButton?.isHidden = !show
        bottomWhiteView?.isHidden = show
    }
    
    @objc private func didTapBack() {
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @objc private func didTapDone() {
        exportInvoiceToPDF()
    }
    
    private func exportInvoiceToPDF() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else {
            return
        }
        let pdfData = a4View.asPDFData()
        let fileName = "Estimate-\(invoice.number).pdf"
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
    
    private func showErrorAlert(error: Error) {
        let alert = UIAlertController(title: "Export Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    var a4ViewTopConstraint: Constraint?
}

extension SingleEstimateVC {
    func setupInvoice() {
        
        var invoiceLabels: [UILabel] = []
        
        a4View = UIView()
        guard let a4View = a4View else { return }
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
            make.centerX.equalToSuperview()
            self.a4ViewTopConstraint = make.top.equalToSuperview().offset(120).constraint
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
        
        invoiceLabel = UILabel()
        guard let invoiceLabel = invoiceLabel else { return }
        invoiceLabel.text = "ESTIMATE"
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
        
        //        dueLabel.snp.makeConstraints { const in
        //            const.bottom.equalTo(issuedLabel.snp.top).offset(-4)
        //            const.trailing.equalTo(invoiceLabel)
        //        }
        
        numberLabel.snp.makeConstraints { const in
            const.bottom.equalTo(issuedLabel.snp.top).offset(-4)
            const.trailing.equalTo(invoiceLabel)
        }
        
        // --- Rectangle under logo ---
        infoRectangle = UIView()
        guard let infoRectangle = infoRectangle else { return }
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
        itemsHeaderView = UIView()
        guard let itemsHeaderView = itemsHeaderView else { return }
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
        
        self.allInvoiceLabels = invoiceLabels
        self.originalLabelFontSizes = invoiceLabels.map { $0.font.pointSize }
        applyFontToAllLabels()
    }
}
