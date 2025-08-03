
internal import UIKit
import RealmSwift
import SnapKit
import SwiftUI

struct SingleInvoiceVCWrapper: View {
    let invoice: InvoiceModel
    let isCustom: Bool

    var body: some View {
        ZStack {
            SingleInvoiceVCRepresentable(invoice: invoice, isCustom: isCustom)
                .ignoresSafeArea()
                .navigationBarHidden(true)
        }
    }
}

struct SingleInvoiceVCRepresentable: UIViewControllerRepresentable {
    let invoice: InvoiceModel
    let isCustom: Bool

    func makeUIViewController(context: Context) -> SingleInvoiceVC {
        let vc = SingleInvoiceVC(invoice: invoice, isCustom: isCustom)
        vc.navigationItem.hidesBackButton = true
        DispatchQueue.main.async {
            vc.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: SingleInvoiceVC, context: Context) {
        DispatchQueue.main.async {
            uiViewController.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
}

extension SingleInvoiceVC {
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
}

class SingleInvoiceVC: UIViewController, UIColorPickerViewControllerDelegate {
    init(invoice: InvoiceModel, isCustom: Bool) {
        self.invoice = invoice
        self.isCustom = isCustom
        super.init(nibName: nil, bundle: nil)
        self.user = fetchUser()
    }
    
    let invoice: InvoiceModel
    var user: UserModel?
    weak var delegate: InvoicePreviewDelegate?
    
    let a4AspectRatio: CGFloat = 210.0 / 297.0
    private var navBarDoneButton: UIButton?
    var bottomWhiteView: UIView?
    
    var invoiceLabel: UILabel?
    var infoRectangle: UIView?
    var itemsHeaderView: UIView?
    
    var selectedColorAsset: String?
    var selectedFontIndex: Int = 0
    
    var allInvoiceLabels: [UILabel] = []
    var originalLabelFontSizes: [CGFloat] = []
    
    var bottomDoneButton: UIButton?
    var sendInvoiceButton: UIButton?
    
    var wasPaid: Bool = false {
        didSet {
            showFinal()
        }
    }
    var selectedPayMethod: String? {
        didSet {
            savePaidStatus(payMethod: selectedPayMethod!, wasPaid: wasPaid)
        }
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
    
    func updateNavBarDoneButtonTitle() {
        let title = isCustom ? "Done" : "Custom"
        navBarDoneButton?.setTitle(title, for: .normal)
    }
    
    func updateBottomButtonVisibility() {
        if isCustom {
            bottomDoneButton?.isHidden = true
            bottomWhiteView?.isHidden = false
        } else {
            bottomDoneButton?.isHidden = false
            bottomWhiteView?.isHidden = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fetchUser() -> UserModel? {
        let vm = UserViewModel.shared
        return vm.currentUser
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
    
    var a4ViewTopConstraint: Constraint?
    var a4View: UIView?
    
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
    
    func changeColor(_ color: UIColor) {
        invoiceLabel?.textColor = color
        infoRectangle?.layer.borderColor = color.cgColor
        itemsHeaderView?.backgroundColor = color
    }
    
    func resetToDefaultColors() {
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
        titleLabel.text = "Invoice"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(2)
        }
    }
   
    func showFinal() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        hideNavDoneButton()
        scaleA4View()
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send Invoice", for: .normal)
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
            make.bottom.equalTo(sendButton.snp.top).offset(-14)
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
        
        if !wasPaid {
            let paidRect = UIView()
            paidRect.backgroundColor = .white
            paidRect.layer.cornerRadius = 14
            paidRect.layer.borderWidth = 1
            paidRect.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
            paidRect.tag = 999_445
            paidRect.isUserInteractionEnabled = true
            view.addSubview(paidRect)
            paidRect.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(20)
                make.height.equalTo(54)
                make.bottom.equalTo(horizontalStack.snp.top).offset(-14)
            }
            
            let paidLabel = UILabel()
            paidLabel.text = "Has invoice been paid?"
            paidLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            paidLabel.textColor = .black
            paidRect.addSubview(paidLabel)
            paidLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
            
            let paidIcon = UIImageView(image: UIImage(named: "markAsPaid"))
            paidIcon.contentMode = .scaleAspectFill
            paidRect.addSubview(paidIcon)
            paidIcon.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(50)
                make.centerY.equalToSuperview()
                make.height.equalTo(17)
                make.width.equalTo(74)
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(showPaid))
            paidRect.addGestureRecognizer(tap)
            
            let infoRect = UIView()
            infoRect.backgroundColor = .white
            infoRect.layer.cornerRadius = 14
            infoRect.layer.borderWidth = 1
            infoRect.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
            infoRect.tag = 999_446
            view.addSubview(infoRect)
            infoRect.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(20)
                make.height.equalTo(94)
                make.bottom.equalTo(paidRect.snp.top).offset(-14)
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
            invoiceLabel.text = "Invoice #"
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
                make.height.equalTo(110)
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

            // Due date (по центру)
            let dueLabel = UILabel()
            dueLabel.text = "Due \(onlyDate(invoice.due))"
            dueLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            dueLabel.textColor = .darkGray
            dueLabel.textAlignment = .center
            clientRect.addSubview(dueLabel)
            dueLabel.snp.makeConstraints { make in
                make.top.equalTo(totalLabel.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
        } else {
            let infoRect = UIView()
            infoRect.backgroundColor = .white
            infoRect.layer.cornerRadius = 14
            infoRect.layer.borderWidth = 1
            infoRect.layer.borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1).cgColor
            infoRect.tag = 999_446
            view.addSubview(infoRect)
            infoRect.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(20)
                make.height.equalTo(134) // увеличили высоту под 3 раздела
                make.bottom.equalTo(horizontalStack.snp.top).offset(-14)
            }

            // Первый разделитель
            let separator1 = UIView()
            separator1.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.87, alpha: 1)
            infoRect.addSubview(separator1)
            separator1.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(134 / 3)
                make.height.equalTo(1)
            }

            // Второй разделитель
            let separator2 = UIView()
            separator2.backgroundColor = separator1.backgroundColor
            infoRect.addSubview(separator2)
            separator2.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(2 * 134 / 3)
                make.height.equalTo(1)
            }

            // Верхняя часть (Issued)
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

            // Средняя часть (Invoice #)
            let invoiceLabel = UILabel()
            invoiceLabel.text = "Invoice #"
            invoiceLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            invoiceLabel.textColor = .black
            invoiceLabel.textAlignment = .left
            infoRect.addSubview(invoiceLabel)
            invoiceLabel.snp.makeConstraints { make in
                make.top.equalTo(separator1.snp.bottom).offset(14)
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

            // Нижняя часть (Mark as Paid)
            let paidLabel = UILabel()
            paidLabel.text = "Mark as Paid"
            paidLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            paidLabel.textColor = .black
            paidLabel.textAlignment = .left
            infoRect.addSubview(paidLabel)
            paidLabel.snp.makeConstraints { make in
                make.top.equalTo(separator2.snp.bottom).offset(14)
                make.left.equalToSuperview().offset(16)
            }

            let paidDateLabel = UILabel()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            paidDateLabel.text = formatter.string(from: Date())
            paidDateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            paidDateLabel.textColor = .black
            paidDateLabel.textAlignment = .right
            infoRect.addSubview(paidDateLabel)
            paidDateLabel.snp.makeConstraints { make in
                make.centerY.equalTo(paidLabel)
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
                make.height.equalTo(110)
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

            // Due date (по центру)
            let dueLabel = UILabel()
            dueLabel.text = "Due \(onlyDate(invoice.due))"
            dueLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            dueLabel.textColor = .darkGray
            dueLabel.textAlignment = .center
            clientRect.addSubview(dueLabel)
            dueLabel.snp.makeConstraints { make in
                make.top.equalTo(totalLabel.snp.bottom).offset(10)
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
            }
        }
    }
    
    var sizeButtons: [UIButton] = []
    var selectedInvoiceFontSizeIndex: Int = 0
    let invoiceFontSizes: [CGFloat] = [16, 24]
    
    var fontButtons: [UIButton] = []
    
    func updateFontSelectionUI() {
        for (i, button) in fontButtons.enumerated() {
            button.layer.borderColor = (i == selectedFontIndex ? UIColor.black.cgColor : UIColor.lightGray.cgColor)
        }
    }
    
    var colorContainers: [String: UIView] = [:]
    var checkmarkViews: [String: UIImageView] = [:]
    
    func updateCheckmarks() {
        for (asset, checkmark) in checkmarkViews {
            checkmark.isHidden = (asset != selectedColorAsset)
        }
    }
    
    func presentColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    private func showBottomDoneButton(_ show: Bool) {
        bottomDoneButton?.isHidden = !show
        bottomWhiteView?.isHidden = show
    }
}
