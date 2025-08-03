internal import UIKit
import SnapKit

extension SingleInvoiceVC {
    @objc func didTapShare() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else { return }
        let pdfData = a4View.asPDFData()
        let fileName = "Invoice-\(invoice.number).pdf"
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

    @objc func didTapPrint() {
        guard let a4View = view.subviews.first(where: { $0.backgroundColor == .white && $0.layer.cornerRadius == 16 }) else { return }
        let pdfData = a4View.asPDFData()
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Invoice-\(invoice.number)"
        printInfo.outputType = .general
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.printingItem = pdfData
        printController.present(animated: true, completionHandler: nil)
    }

    @objc func didTapPresentSendInvoice() {
        view.viewWithTag(999_111)?.removeFromSuperview()
        isCustom = false
        showFinal()
    }

    @objc func showPaid() {
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

    @objc func didTapNavBarDone() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        isCustom.toggle()
    }

    @objc func didTapEditFinal() {
        sendInvoiceButton?.removeFromSuperview()
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
        setupBottomDoneButtonAndWhiteView()
    }

    @objc func handleSizeTap(_ sender: UIButton) {
        selectedInvoiceFontSizeIndex = sender.tag
        updateSizeSelectionUI()
        applyFontToInvoiceLabelsWithSize()
        applyFontToInvoiceLabel()
    }

    @objc func handleSizeSubRequired(_ sender: UIButton) {
        delegate?.presentSubscription()
    }

    @objc func handleFontSubRequired(_ sender: UIButton) {
        delegate?.presentSubscription()
    }

    @objc func handleFontTap(_ sender: UIButton) {
        selectedFontIndex = sender.tag
        updateFontSelectionUI()
        applyFontToAllLabels()
        applyFontToInvoiceLabel()
    }

    @objc func handleColorTap(_ sender: UITapGestureRecognizer) {
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
            .customBlue,
            .customOrange,
            .customSea,
            .customPurple,
            .customGreen,
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

    @objc func didTapBack() {
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc func didTapDone() {
        exportInvoiceToPDF()
    }
}
