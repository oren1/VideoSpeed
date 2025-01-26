//
//  SpidLabel.swift
//  VideoSpeed
//
//  Created by oren shalev on 25/01/2025.
//

import UIKit

class SpidLabel: UILabel {

    var rotation: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
