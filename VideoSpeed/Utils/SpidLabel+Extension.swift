//
//  UILabel+.swift
//  VideoSpeed
//
//  Created by oren shalev on 24/01/2025.
//

import UIKit

extension SpidLabel {
    
    func scaledBy(_ scaleFactor: CGFloat) -> UILabel {
        let x = self.frame.origin.x * scaleFactor
        let y = self.frame.origin.y * scaleFactor

        let label = UILabel(frame: CGRect(x: x, y: y, width: frame.width, height: frame.height))
        label.center = CGPoint(x: center.x * scaleFactor, y: center.y * scaleFactor)
        label.font = font
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.numberOfLines = numberOfLines
        label.text = text
        label.adjustsFontSizeToFitWidth = true
        label.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return label
    }
}
