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
        let width = self.frame.size.width * scaleFactor
        let height = self.frame.size.height * scaleFactor

        let font = UIFont.boldSystemFont(ofSize: font.pointSize * scaleFactor)
        
        let label = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        label.font = font
        label.backgroundColor = backgroundColor
        label.textColor = textColor
        label.numberOfLines = numberOfLines
        label.text = text
//        label.transform = CGAffineTransform(rotationAngle: rotation)
        return label
    }
}
