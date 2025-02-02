//
//  SpidLabel.swift
//  VideoSpeed
//
//  Created by oren shalev on 25/01/2025.
//

import UIKit
import AVFoundation

class SpidLabel: UILabel {

    var rotation: CGFloat = 0
    var startTime: CMTime?
    var endTime: CMTime?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.startTime = startTime
//        self.endTime = endTime
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
