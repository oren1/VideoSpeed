//
//  TextEditViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 31/01/2025.
//

import UIKit

enum EditStatus {
    case new, editing
}

class TextEditViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var editContainerView: UIView!
    @IBOutlet weak var editOptionsCollectionView: UICollectionView!
    @IBOutlet weak var textView: UITextView!
    var testLabel: UILabel!
    var placeHolderLabel = UILabel()
    var videoContainerWidth: CGFloat = 0
    var paddingLabel: PaddingLabel!
    var editStatus: EditStatus!
    
    override func viewDidLoad() {

        super.viewDidLoad()
        textView.delegate = self
        textView.layer.cornerRadius = 8
        
        addPlaceHolderToTextView()
        addPaddingLabelToTop()

        
        label.isHidden = true
        label.backgroundColor = .green
        label.text = "Enter Text"
        view.layoutIfNeeded()
    }

    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if !textView.text!.isEmpty {
           
            let labelViewModel = LabelViewModel(labelFrame: paddingLabel.frame,
                                                text: paddingLabel!.label.text!,
                                                textColor: label.textColor!,
                                                backgroundColor: label.backgroundColor!,
                                                textAlignment: label.textAlignment)
            
            let labelView = LabelView.instantiateWithPaddingLabel(paddingLabel, viewModel: labelViewModel)
            UserDataManager.main.overlayLabelViews.append(labelView)
            
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
        paddingLabel.label.text = textView.text
        let font = UIFont.systemFont(ofSize: 18)
        let newTextSize = textView.text.textSize(withConstrainedWidth: 500, font: font)
        paddingLabel.widthConstraint?.constant = newTextSize.width + paddingLabel.horizontalPadding
        paddingLabel.heightConstraint?.constant = newTextSize.height + paddingLabel.verticalPadding
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
        }
        /*
          If the 'editStatus' is 'editing', the 'PaddingLabel' instance is passed when creating
          the ViewController before pushing it to the view
        */
        paddingLabel.layer.cornerRadius = paddingLabel.frame.width / 10
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
}

