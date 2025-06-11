//
//  SpidLabel.swift
//  VideoSpeed
//
//  Created by oren shalev on 25/01/2025.
//

import UIKit
import AVFoundation

let heightInset: CGFloat = 20
let widthInset: CGFloat = 20

class SpidLabel: UILabel {

    var rotation: CGFloat = 0
    var startTime: CMTime?
    var endTime: CMTime?
    
    override init(frame: CGRect) {
        let fifthOfWidth = frame.size.width / 5
        let fifthOfHeight = frame.size.height / 5

        super.init(frame: CGRect(origin: frame.origin,
                                 size: CGSize(width: frame.size.width + (widthInset * 2), height: frame.size.height)))
//        super.init(frame: frame)
        self.layer.masksToBounds = true

//        adjustsFontSizeToFitWidth = true
//        self.startTime = startTime
//        self.endTime = endTime
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.masksToBounds = true

//        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawText(in rect: CGRect) {
        
        let insets = UIEdgeInsets(top: 0, left: widthInset , bottom: 0, right: widthInset)
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
