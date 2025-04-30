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

class TextEditViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var editContainerView: UIView!
    @IBOutlet weak var editOptionsCollectionView: UICollectionView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var editContainerViewHeightConstraint: NSLayoutConstraint!
    var testLabel: UILabel!
    var placeHolderLabel = UILabel()
    var videoContainerWidth: CGFloat = 0
    var paddingLabel: PaddingLabel!
    var editStatus: EditStatus!
    var labelViewModel: LabelViewModel!
    let minimumItemWidth = 64.0
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    let textEditMenuItemReuseIdentifier = "TextEditMenuItem"
    let textEditMenuItems = [
        TextEditMenuItem(identifier: .textColor,
                         selectedImage: UIImage(systemName: "paintbrush.pointed"),
                         normalImage: UIImage(systemName: "paintbrush.pointed"), selected: false),
        TextEditMenuItem(identifier: .bgColor,
                         selectedImage: UIImage(systemName: "square"),
                         normalImage: UIImage(systemName: "square"), selected: false),
        TextEditMenuItem(identifier: .font,
                         selectedImage: UIImage(systemName: "florinsign"),
                         normalImage: UIImage(systemName: "florinsign"), selected: false),
        TextEditMenuItem(identifier: .alignment,
                         selectedImage: UIImage(systemName: "text.aligncenter"),
                         normalImage: UIImage(systemName: "text.aligncenter"), selected: false),
        TextEditMenuItem(identifier: .size,
                         selectedImage: UIImage(systemName: "textformat.size.larger"),
                         normalImage: UIImage(systemName: "textformat.size.larger"), selected: false)
        
    ]
    
    private var subscribers: [AnyCancellable] = []

    override func viewDidLoad() {

        super.viewDidLoad()
        textView.delegate = self
        textView.layer.cornerRadius = 8
        
        editOptionsCollectionView.delegate = self
        editOptionsCollectionView.dataSource = self

        addPlaceHolderToTextView()
        addPaddingLabelToTop()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        view.layoutIfNeeded()
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
    
    
   
    func textViewDidEndEditing(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeHolderLabel.isHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeHolderLabel.isHidden = !textView.text.isEmpty
        labelViewModel?.text = textView.text
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
                                            backgroundColor: UIColor.green,
                                            textAlignment: .center)
        }
        else if editStatus == .editing {
            labelViewModel = UserDataManager.main.selectedLabelViewModel
            paddingLabel = PaddingLabel(text: labelViewModel.text, verticalPadding: 12, horizontalPadding: 12)
            paddingLabel.textColor = labelViewModel.textColor
            paddingLabel.backgroundColor = labelViewModel.backgroundColor
            paddingLabel.textAlignment = labelViewModel.textAlignment
            textView.text = labelViewModel.text
        }
        
        
        
        labelViewModel?.$text
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] text in
                guard let self = self else { return }
                paddingLabel.text = text
                let font = UIFont.systemFont(ofSize: 18)
                let newTextSize = textView.text.textSize(withConstrainedWidth: 500, font: font)
                labelViewModel.labelFrame = newTextSize
                paddingLabel.widthConstraint?.constant = newTextSize.width + paddingLabel.horizontalPadding
                paddingLabel.heightConstraint?.constant = newTextSize.height + paddingLabel.verticalPadding
                labelViewModel.width = newTextSize.width + paddingLabel.horizontalPadding + LabelViewExtraWidth
                labelViewModel.height = newTextSize.height + paddingLabel.verticalPadding + LabelViewExtraHeight
            })
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
    }
    
    
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            editContainerViewHeightConstraint.constant = keyboardRectangle.height
            view.layoutIfNeeded()
        }
    }
}

