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
        let fifthOfWidth = frame.size.width / 5
        let fifthOfHeight = frame.size.height / 5

        super.init(frame: CGRect(origin: frame.origin, size: CGSize(width: frame.size.width + fifthOfWidth, height: frame.size.height + fifthOfHeight)))
        adjustsFontSizeToFitWidth = true
//        self.startTime = startTime
//        self.endTime = endTime
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        
        let insets = UIEdgeInsets(top: rect.size.height / 10, left: rect.size.width / 10 , bottom: rect.size.height / 10, right: rect.size.width / 10)
        super.drawText(in: rect.inset(by: insets))
    }
}

class SomeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
//        self.startTime = startTime
//        self.endTime = endTime
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        super.drawText(in: rect.inset(by: insets))
    }
}
