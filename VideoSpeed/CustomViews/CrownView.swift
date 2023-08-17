//
//  CrownView.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/08/2023.
//

import UIKit

class CrownView: UIView {

    @IBOutlet var contentView: UIView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("CrownView", owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.layer.cornerRadius = 4
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

}
