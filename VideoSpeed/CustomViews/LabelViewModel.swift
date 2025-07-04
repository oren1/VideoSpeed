//
//  LabelViewModel.swift
//  VideoSpeed
//
//  Created by oren shalev on 09/02/2025.
//

import UIKit
import AVFoundation

let LabelViewExtraWidth = 24.0
let LabelViewExtraHeight = 24.0

enum BackgroundStyle {
    case full, fragmented
}

class LabelViewModel: ObservableObject {
    var width: CGFloat
    var height: CGFloat
    var numberOfLines = 0
    var masksToBounds = true
    var borderWidth = 1.0
    var borderColor = UIColor.orange.cgColor
    var fullRotation: CGFloat = 0.0
    var timeRange: CMTimeRange?
    var rightHandleConstraintConstant: CGFloat?
    var leftHandleConstraintConstant: CGFloat?
    var fullScale: CGFloat = 1
    var labelFrame: CGRect {
        didSet {}
    }

    
    @Published
    var text: String
    
    @Published
    var textColor: UIColor
    
    @Published
    var backgroundColor: UIColor
    
    @Published
    var selected: Bool = false
    
    @Published
    var center: CGPoint = .zero

    @Published
    var scale: CGFloat = 1
   
    @Published
    var rotation: CGFloat = 0.0
    
    @Published
    var isHidden: Bool = false
    
    @Published
    var font: UIFont = UIFont(name: ".SFUIText", size: 18)!
    
    @Published
    var fontSize: CGFloat = 18
    
    @Published
    var textAlignment: NSTextAlignment

    @Published
    var backgroundStyle: BackgroundStyle = .fragmented
    
    @Published
    var strokeColor: UIColor = .clear
    
    @Published
    var strokeWidth: CGFloat = 0
    
    
    init(width: CGFloat = 0.0, height: CGFloat = 0.0, labelFrame: CGRect, text: String, textColor: UIColor, backgroundColor: UIColor, numberOfLines: Int = 0, masksToBounds: Bool = true, textAlignment: NSTextAlignment, center: CGPoint = .zero, borderWidth: Double = 1.0, borderColor: CGColor = UIColor.orange.cgColor, rotation: CGFloat = 0.0, timeRange: CMTimeRange? = nil, selected: Bool = false) {
       
        self.width = labelFrame.size.width + LabelViewExtraWidth
        self.height = labelFrame.size.height + LabelViewExtraHeight
//        self.width = labelFrame.size.width
//        self.height = labelFrame.size.height
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
    
//    func updateRotation(rotation: CGFloat) {
//        self.rotation += rotation
//    }
    
    func createLabelView() -> LabelView {
        let size = CGSize(width: width, height: height)
        let labelView = LabelView(frame: CGRect(origin: .zero, size: size))
        labelView.center = center
        labelView.backgroundColor = .clear
        
        let paddingLabel = PaddingLabel(text: self.text, verticalPadding: 12, horizontalPadding: 12)
        let font = UIFont.systemFont(ofSize: 18)
        let textSize = text.textSize(withConstrainedWidth: 500, font: font).size
       
        let label = UILabel(frame: CGRect(origin: .zero, size: textSize))
        label.center = CGPoint(x: paddingLabel.frame.width / 2.0, y: paddingLabel.frame.height / 2.0)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.layer.displayIfNeeded()
        paddingLabel.layer.addSublayer(label.layer)
        
        paddingLabel.backgroundColor = backgroundColor
        paddingLabel.label.layer.displayIfNeeded()
        paddingLabel.layer.displayIfNeeded()
        labelView.layer.addSublayer(paddingLabel.layer)
        
        return labelView
    }
    
    
    func resetTimeRange() {
        self.timeRange = nil
        self.rightHandleConstraintConstant = nil
        self.leftHandleConstraintConstant = nil
    }
    
    func getVerticalLabelsViewSizeWith(fontSize: CGFloat) -> CGSize {
        let strings = String.getLinesOfText(text, font: font, width: .greatestFiniteMagnitude)
        let rawLineHeight = font.withSize(fontSize).lineHeight
        let lineHeight =  rawLineHeight + (rawLineHeight * 0.1)
        let textSize = text.textSize(withConstrainedWidth: .greatestFiniteMagnitude, font: font.withSize(fontSize)).size
        let verticalLabelsViewHeight = CGFloat(strings.count) * lineHeight
        let verticalLabelsViewWidth = textSize.width + (textSize.width * 0.1)
        
        return CGSize(width: verticalLabelsViewWidth, height: verticalLabelsViewHeight)
    }
}
