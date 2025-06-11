//
//  TextEditViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 31/01/2025.
//

import UIKit
import Combine

enum EditStatus {
    case new, editing
}

class TextEditViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var editContainerView: UIView!
    @IBOutlet weak var editOptionsCollectionView: UICollectionView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var editContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var visualEffectViewWidthConstraint: NSLayoutConstraint!
    var testLabel: UILabel!
    var placeHolderLabel = UILabel()
    var videoContainerWidth: CGFloat = 0
    var videoContainerHeight: CGFloat = 0
    var paddingLabel: PaddingLabel!
    var editStatus: EditStatus!
    var labelViewModel: LabelViewModel!
    let minimumItemWidth = 67.0
    var currentFrameImage: UIImage?
    var apppliedKeyBoardHeight: Bool = false
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    let textEditMenuItemReuseIdentifier = "TextEditMenuItem"
    let textEditMenuItems = [
        TextEditMenuItem(identifier: .font,
                         selectedImage: UIImage(systemName: "florinsign"),
                         normalImage: UIImage(systemName: "florinsign"), selected: false),
        TextEditMenuItem(identifier: .textColor,
                         selectedImage: UIImage(systemName: "paintbrush.pointed"),
                         normalImage: UIImage(systemName: "paintbrush.pointed"), selected: true),
        TextEditMenuItem(identifier: .strokeColor,
                         selectedImage: UIImage(systemName: "lineweight"),
                         normalImage: UIImage(systemName: "lineweight"), selected: false),
        TextEditMenuItem(identifier: .bgColor,
                         selectedImage: UIImage(systemName: "square"),
                         normalImage: UIImage(systemName: "square"), selected: false),
        TextEditMenuItem(identifier: .bgStyle,
                         selectedImage: UIImage(systemName: "align.horizontal.center.fill"),
                         normalImage: UIImage(systemName: "align.horizontal.center.fill"), selected: false),
        TextEditMenuItem(identifier: .alignment,
                         selectedImage: UIImage(systemName: "text.aligncenter"),
                         normalImage: UIImage(systemName: "text.aligncenter"), selected: false),
        TextEditMenuItem(identifier: .size,
                         selectedImage: UIImage(systemName: "textformat.size.larger"),
                         normalImage: UIImage(systemName: "textformat.size.larger"), selected: false),
        
        
    ]
    
    private var subscribers: [AnyCancellable] = []
    var textColorEditSectionVC: ColorEditSectionVC!
    var bgColorEditSectionVC: ColorEditSectionVC!
    var fontEditSectionVC: FontEditSectionVC!
    var alignmentEditSection: AlignmentEditSectionVC!
    var fontSizeEditSection: FontSizeEditSectionVC!
    var bgStyleEditSection: BGStyleEditSectionVC!
    var strokeColorEditSection: StrokeColorEditSectionVC!
    
    var selectedEditSection: UIViewController?
    var verticalLabelsView: VerticalLabelsView!
    
    override func viewDidLoad() {

        super.viewDidLoad()
        textView.delegate = self
        textView.layer.cornerRadius = 8
        
        editOptionsCollectionView.delegate = self
        editOptionsCollectionView.dataSource = self

        addPlaceHolderToTextView()
        addPaddingLabelToTop()
        
        createEditSections()
       
        imageView.image = currentFrameImage
        imageViewWidthConstraint.constant = videoContainerWidth
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = imageView.bounds
        blurredEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.addSubview(blurredEffectView)
    
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        view.layoutIfNeeded()
        
        textView.becomeFirstResponder()
    }

    
    override func viewDidAppear(_ animated: Bool) {
//        textView.becomeFirstResponder()

//        paddingLabel.isHidden = true

    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if !textView.text!.isEmpty {
            if editStatus == .new {
                UserDataManager.main.labelViewsModels.append(labelViewModel)
            }
            else if editStatus == .editing {
                NotificationCenter.default.post(name: Notification.Name.OverlayLabelViewsUpdated, object: nil)
            }
        }
        
        dismiss(animated: true)
    }
    
    
   
   
    
    // MARK: UI
    func addPlaceHolderToTextView() {
        placeHolderLabel.text = "Enter Text"
        placeHolderLabel.font = .systemFont(ofSize: (textView.font?.pointSize)!)
        placeHolderLabel.sizeToFit()
        textView.addSubview(placeHolderLabel)
        placeHolderLabel.frame.origin = CGPoint(x: 5, y: (textView.font?.pointSize)! / 2)
        placeHolderLabel.textColor = .tertiaryLabel
        placeHolderLabel.isHidden = !textView.text.isEmpty
    }
   
    func addPaddingLabelToTop() {
        
        if editStatus == .new {
            paddingLabel = PaddingLabel(text: "Enter Text", verticalPadding: 12, horizontalPadding: 12)
            labelViewModel = LabelViewModel(labelFrame: paddingLabel.frame,
                                            text: paddingLabel.text,
                                            textColor: UIColor.white,
                                            backgroundColor: .clear,
                                            textAlignment: .center)
        }
        else if editStatus == .editing {
            labelViewModel = UserDataManager.main.selectedLabelViewModel
            paddingLabel = PaddingLabel(text: labelViewModel.text, verticalPadding: 12, horizontalPadding: 12)
            paddingLabel.textColor = labelViewModel.textColor
            paddingLabel.backgroundColor = labelViewModel.backgroundColor
            paddingLabel.textAlignment = labelViewModel.textAlignment
            paddingLabel.strokeColor = labelViewModel.strokeColor
            paddingLabel.strokeWidth = labelViewModel.strokeWidth
            textView.text = labelViewModel.text
        }
        
        labelViewModel.$textColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] textColor in
                guard let self = self else {return}
                
                paddingLabel.textColor = textColor
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }.store(in: &subscribers)
        
        labelViewModel.$backgroundColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] backgroundColor in
                guard let self = self else {return}
                
                paddingLabel.backgroundColor = backgroundColor
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }.store(in: &subscribers)
        
        labelViewModel?.$text
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] text in
                guard let self = self else { return }
                paddingLabel.text = text
                let font = labelViewModel.font
                let newTextSize = textView.text.textSize(withConstrainedWidth: 500, font: font)
//                labelViewModel.labelFrame = newTextSize
                paddingLabel.widthConstraint?.constant = newTextSize.width + paddingLabel.horizontalPadding
                paddingLabel.heightConstraint?.constant = newTextSize.height + paddingLabel.verticalPadding
                labelViewModel.width = newTextSize.width + paddingLabel.horizontalPadding + LabelViewExtraWidth
                labelViewModel.height = newTextSize.height + paddingLabel.verticalPadding + LabelViewExtraHeight
                
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            })
            .store(in: &subscribers)
        
        labelViewModel.$font
            .receive(on: DispatchQueue.main)
            .sink { [weak self] font in
                guard let self = self else { return }
                // Applying the fontSize that the user selected
                let fontWithSize = font.withSize(labelViewModel.fontSize)
                self.paddingLabel.font = fontWithSize
                let newTextSize = textView.text.textSize(withConstrainedWidth: 500, font: fontWithSize)
//                labelViewModel.labelFrame = newTextSize
                paddingLabel.widthConstraint?.constant = newTextSize.width + paddingLabel.horizontalPadding
                paddingLabel.heightConstraint?.constant = newTextSize.height + paddingLabel.verticalPadding
                labelViewModel.width = newTextSize.width + paddingLabel.horizontalPadding + LabelViewExtraWidth
                labelViewModel.height = newTextSize.height + paddingLabel.verticalPadding + LabelViewExtraHeight
                
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }
            .store(in: &subscribers)
        
        labelViewModel.$textAlignment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] textAlignment in
                guard let self = self else { return }

                paddingLabel.textAlignment = textAlignment
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }
            .store(in: &subscribers)
        
        
        labelViewModel.$fontSize
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fontSize in
                guard let self = self else { return }
                
                self.paddingLabel.fontSize = fontSize
                let font = labelViewModel.font.withSize(fontSize)
                labelViewModel.font = font
                let newTextSize = textView.text.textSize(withConstrainedWidth: 500, font: font)
                labelViewModel.labelFrame = newTextSize
                paddingLabel.widthConstraint?.constant = newTextSize.width + paddingLabel.horizontalPadding
                paddingLabel.heightConstraint?.constant = newTextSize.height + paddingLabel.verticalPadding
                labelViewModel.width = newTextSize.width + paddingLabel.horizontalPadding + LabelViewExtraWidth
                labelViewModel.height = newTextSize.height + paddingLabel.verticalPadding + LabelViewExtraHeight
                
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }
            .store(in: &subscribers)
        
        labelViewModel.$backgroundStyle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bgStyle in
                guard let self = self else {return}
                
                switch bgStyle {
                case .full:
                    paddingLabel.isHidden = false
                    verticalLabelsView?.removeFromSuperview()
                    verticalLabelsView = nil
                case .fragmented:
                    paddingLabel.isHidden = true
                    createVerticalLabelsView(labelViewModel!)
                }
                
            }.store(in: &subscribers)
        
        labelViewModel.$strokeColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokColor in
                guard let self = self else {return}
                paddingLabel.strokeColor = strokColor
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }
            .store(in: &subscribers)
        
        labelViewModel.$strokeWidth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokeWidth in
                guard let self = self else {return}
                paddingLabel.strokeWidth = strokeWidth
                if labelViewModel.backgroundStyle == .fragmented {
                    createVerticalLabelsView(labelViewModel!)
                }
            }
            .store(in: &subscribers)
        
        view.addSubview(paddingLabel)
        paddingLabel.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            paddingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            paddingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paddingLabel.widthAnchor.constraint(equalToConstant: paddingLabel.frame.width),
            paddingLabel.heightAnchor.constraint(equalToConstant: paddingLabel.frame.height)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        if labelViewModel.backgroundStyle == .fragmented {
            paddingLabel.isHidden = true
        }
        else {
            paddingLabel.isHidden = false
        }
        
    }
    
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            if keyboardRectangle.height > editContainerViewHeightConstraint.constant {
                editContainerViewHeightConstraint.constant = keyboardRectangle.height
                view.layoutIfNeeded()
            }
        }
    }
    
    
    func getLinesOfText(_ text: String, font: UIFont, width: CGFloat) -> [String] {
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var lines: [String] = []
        var index = 0

        while index < layoutManager.numberOfGlyphs {
            var lineRange = NSRange(location: 0, length: 0)
            let rect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)

            // Convert glyph range to character range
            let charRange = layoutManager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
            if let substringRange = Range(charRange, in: text) {
                let lineString = String(text[substringRange])
                
                // Remove any \n characters
                let cleanedLine = lineString.replacingOccurrences(of: "\n", with: "")
                lines.append(cleanedLine)
            }

            index = NSMaxRange(lineRange)
        }

        return lines
    }
    
    
    func createVerticalLabelsView(_ viewModel: LabelViewModel ) {
        let prev = verticalLabelsView
        
        var textLines = String.getLinesOfText(textView.text, font: labelViewModel.font, width: .greatestFiniteMagnitude)
        if textLines.count == 0 {
            textLines = ["Enter Text"]
        }
        verticalLabelsView = VerticalLabelsView(strings: textLines, viewModel: viewModel)
        
        verticalLabelsView.translatesAutoresizingMaskIntoConstraints = false
        verticalLabelsView.setNeedsLayout()
        verticalLabelsView.layoutIfNeeded()
                
        view.addSubview(verticalLabelsView)
        let constraints = [
            verticalLabelsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            verticalLabelsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ]
        
        
        NSLayoutConstraint.activate(constraints)
        
        prev?.removeFromSuperview()
    }
}

fileprivate typealias EditSections = TextEditViewController
extension EditSections {
   
    // MARK: Creation
    private func createEditSections() {
        createTextColorEditSection()
        createBGColorEditSection()
        createFontEditSection()
        createAlignmentEditSection()
        createFontSizeEditSection()
        createBGStyleEditSection()
        createStrokeColorEditSection()
        
        addSection(sectionVC: textColorEditSectionVC)
    }
    
    func createTextColorEditSection()  {
        textColorEditSectionVC = ColorEditSectionVC()
        textColorEditSectionVC.didSelectColor = { [weak self] textColor in
            self?.labelViewModel?.textColor = textColor
        }
    }
    
    func createBGColorEditSection()  {
        bgColorEditSectionVC = ColorEditSectionVC()
        bgColorEditSectionVC.didSelectColor = { [weak self] backgroundColor in
            self?.labelViewModel?.backgroundColor = backgroundColor
        }
    }
    
    
    func createFontEditSection() {
        fontEditSectionVC = FontEditSectionVC()
        fontEditSectionVC.didSelectFont = { [weak self] font in
            self?.labelViewModel.font = font
        }
    }
    
    func createAlignmentEditSection() {
        alignmentEditSection = AlignmentEditSectionVC()
        alignmentEditSection.didSelectAlignment = { [weak self] textAlignment in
            self?.labelViewModel.textAlignment = textAlignment
        }
    }
    
    func createFontSizeEditSection() {
        fontSizeEditSection = FontSizeEditSectionVC()
        fontSizeEditSection.onFontSizeChange = { [weak self] fontSize in
            self?.labelViewModel.fontSize = CGFloat(fontSize)
        }
    }
    
    func createBGStyleEditSection() {
        bgStyleEditSection = BGStyleEditSectionVC()
        bgStyleEditSection.didSelectBGStyle = { [weak self] bgStyle in
            self?.labelViewModel.backgroundStyle = bgStyle
        }
    }
    
    func createStrokeColorEditSection()  {
        strokeColorEditSection = StrokeColorEditSectionVC(nibName: "StrokeColorEditSection", bundle: nil)
        strokeColorEditSection.didSelectColor = { [weak self] strokeColor in
            self?.labelViewModel.strokeColor = strokeColor
        }
        strokeColorEditSection.didSelectStroke = { [weak self] strokeWidth in
            self?.labelViewModel.strokeWidth = strokeWidth
        }
    }
    
    // MARK: Adding & Removing
    func addSection(sectionVC: UIViewController) {
        addChild(sectionVC)
        editContainerView.addSubview(sectionVC.view)
        sectionVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            sectionVC.view.topAnchor.constraint(equalTo: editContainerView.topAnchor),
            sectionVC.view.leftAnchor.constraint(equalTo: editContainerView.leftAnchor),
            sectionVC.view.rightAnchor.constraint(equalTo: editContainerView.rightAnchor),
            sectionVC.view.bottomAnchor.constraint(equalTo: editContainerView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        sectionVC.didMove(toParent: self)
        
        selectedEditSection = sectionVC
    }
    
    func removeEditSection(sectionVC: UIViewController) {
        sectionVC.willMove(toParent: nil)
        sectionVC.view.removeFromSuperview()
        sectionVC.removeFromParent()
    }
}


fileprivate typealias TextView = TextEditViewController
extension TextView: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
//        labelViewModel?.text = textView.text.isEmpty ? "Enter Text" : textView.text

        let selectedMenuItem = textEditMenuItems.first(where: { $0.selected })
        selectedMenuItem?.selected = false
        editOptionsCollectionView.reloadData()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
        labelViewModel?.text = textView.text
        
        if labelViewModel?.backgroundStyle == .fragmented {
            createVerticalLabelsView(labelViewModel)
        }

    }
    
    
}


class RoundedHighlightLabel: UILabel {
    var highlightRanges: [NSRange] = []

    override func drawText(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let text = self.text else {
            super.drawText(in: rect)
            return
        }

        // Draw the text normally
        super.drawText(in: rect)

        // Set the fill color for the highlight
        UIColor.yellow.setFill()

        // Loop over all highlight ranges
        for range in highlightRanges {
            // Get bounding rect for the range
            if let boundingRects = self.boundingRects(for: range) {
                for rect in boundingRects {
                    let path = UIBezierPath(roundedRect: rect.insetBy(dx: -2, dy: -2), cornerRadius: 8)
                    path.fill()
                }
            }
        }
    }

    func boundingRects(for range: NSRange) -> [CGRect]? {
        guard let attributedText = attributedText else { return nil }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: self.bounds.size)

        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        var rects: [CGRect] = []

        layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: textContainer) { rect, _ in
            // Convert rect to view's coordinate system
            let convertedRect = rect.offsetBy(dx: self.bounds.origin.x, dy: self.bounds.origin.y)
            rects.append(convertedRect)
        }
        return rects
    }
}



class RoundedLinesLabel: UILabel {
    var cornerRadius: CGFloat = 8
    
    override func drawText(in rect: CGRect) {
        guard let text = self.text, let font = self.font else {
            super.drawText(in: rect)
            return
        }
        
        // Prepare for custom drawing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = self.lineBreakMode
        paragraphStyle.alignment = self.textAlignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)

        // Prepare text storage and layout manager
        let textStorage = NSTextStorage(attributedString: attrString)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainerSize = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)

        let textContainer = NSTextContainer(size: textContainerSize)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        // Loop through each line
        var index = 0
        while index < layoutManager.numberOfGlyphs {
            var lineRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)

            // Convert glyph range to character range
            let charRange = layoutManager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
            let startIndex = text.index(text.startIndex, offsetBy: charRange.location)
            let endIndex = text.index(startIndex, offsetBy: charRange.length)
            let lineText = String(text[startIndex..<endIndex])
            
            // Draw the background rounded rect
            let rects = layoutManager.boundingRects(forGlyphRange: lineRange, in: textContainer)
            for rect in rects {
                let path = UIBezierPath(roundedRect: rect.insetBy(dx: -4, dy: -2), cornerRadius: cornerRadius) // inset for padding
                UIColor.lightGray.setFill()
                path.fill()
            }
            index = NSMaxRange(lineRange)
        }
        
        // Call super to draw the actual text
        super.drawText(in: rect)
    }
}

// Extension for NSLayoutManager to get bounding rects
extension NSLayoutManager {
    func boundingRects(forGlyphRange glyphRange: NSRange, in textContainer: NSTextContainer) -> [CGRect] {
        var rects: [CGRect] = []
        self.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: textContainer) { rect, _ in
            rects.append(rect)
        }
        return rects
    }
}
