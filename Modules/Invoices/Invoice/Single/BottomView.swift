internal import UIKit
import SnapKit

extension SingleInvoiceVC {
    
     func setupBottomDoneButtonAndWhiteView() {
        view.viewWithTag(999_444)?.removeFromSuperview()
        view.viewWithTag(999_445)?.removeFromSuperview()
        view.viewWithTag(999_446)?.removeFromSuperview()
        view.viewWithTag(999_447)?.removeFromSuperview()
         
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
         updateBottomButtonVisibility()

    }
    
}
