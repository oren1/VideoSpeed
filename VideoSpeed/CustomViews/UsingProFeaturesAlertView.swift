//
//  UsingProFeaturesAlertView.swift
//  VideoSpeed
//
//  Created by oren shalev on 18/08/2023.
//

import UIKit

class UsingProFeaturesAlertView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    var onCancel: VoidClosure?
    var onContinue: VoidClosure?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("UsingProFeaturesAlertView", owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.layer.cornerRadius = 8
        continueButton.layer.cornerRadius = 8
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    @IBAction func cancelButtonTapped(_ sender: Any) {
        onCancel?()
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        onContinue?()
    }
}
