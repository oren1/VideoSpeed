//
//  LabelViewModel.swift
//  VideoSpeed
//
//  Created by oren shalev on 09/02/2025.
//

import UIKit
import AVFoundation

class LabelViewModel: ObservableObject {
    var width: CGFloat
    var height: CGFloat
    var labelFrame: CGRect
    var text: String
    var textColor: UIColor
    var backgroundColor: UIColor
    var numberOfLines = 0
    var masksToBounds = true
    var textAlignment: NSTextAlignment
    var center: CGPoint = .zero
    var borderWidth = 1.0
    var borderColor = UIColor.orange.cgColor
    var rotation: CGFloat = 0.0
    var timeRange: CMTimeRange?
    var rightHandleConstraintConstant: CGFloat?
    var leftHandleConstraintConstant: CGFloat?
    
    @Published
    var selected: Bool = false
    
    init(width: CGFloat = 0.0, height: CGFloat = 0.0, labelFrame: CGRect, text: String, textColor: UIColor, backgroundColor: UIColor, numberOfLines: Int = 0, masksToBounds: Bool = true, textAlignment: NSTextAlignment, center: CGPoint = .zero, borderWidth: Double = 1.0, borderColor: CGColor = UIColor.orange.cgColor, rotation: CGFloat = 0.0, timeRange: CMTimeRange? = nil, selected: Bool = false
) {
       
        self.width = labelFrame.size.width + (labelFrame.size.width / 3)
        self.height = labelFrame.size.height + (labelFrame.size.height / 2) + 30
        self.labelFrame = labelFrame
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.numberOfLines = numberOfLines
        self.masksToBounds = masksToBounds
        self.textAlignment = textAlignment
        self.center = center
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.rotation = rotation
        self.timeRange = timeRange
    }
    
    func updateRotation(rotation: CGFloat) {
        self.rotation += rotation
    }
}
