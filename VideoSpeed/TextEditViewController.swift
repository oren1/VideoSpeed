//
//  TextEditViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 31/01/2025.
//

import UIKit

class TextEditViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if !textView.text!.isEmpty {
            let frame = textView.text!.textSize(withConstrainedWidth: textView.frame.size.width, font: .boldSystemFont(ofSize: 17))
            let label = SpidLabel(frame: frame)
            label.text = textView.text
            label.center = .zero
            UserDataManager.main.textOverlayLabels.append(label)
        }
        
        dismiss(animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        print("textView.text! \(textView.text!)")
        print("textView.attributed! \(textView.attributedText!)")
    }
}


// when pressing done, create a new label with the
// attributed text of the 'textView' and add it to the
// 'textOverlayLabels'.
