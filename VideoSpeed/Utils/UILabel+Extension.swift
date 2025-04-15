//
//  UILabel+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 06/04/2025.
//

import UIKit

extension UILabel {
    
    func createCopy() -> UILabel? {
        if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false),
           let label = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UILabel.self, from: archivedData) {
            return label
        }
        return nil
    }
    
    func copyLabel() -> UILabel {
          let label = UILabel(frame: self.frame)
          label.text = text
          label.font = font
          label.textColor = textColor
          label.backgroundColor = backgroundColor
          label.shadowColor = shadowColor
          label.shadowOffset = shadowOffset
          label.textAlignment = textAlignment
          label.lineBreakMode = lineBreakMode
          label.attributedText = attributedText
          label.highlightedTextColor = highlightedTextColor
          label.isUserInteractionEnabled = isUserInteractionEnabled
          label.isEnabled = isEnabled
          label.numberOfLines = numberOfLines
          label.baselineAdjustment = baselineAdjustment
          label.minimumScaleFactor = minimumScaleFactor
        
          return label
    }
}
