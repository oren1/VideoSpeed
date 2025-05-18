//
//  PaddingLabel.swift
//  VideoSpeed
//
//  Created by oren shalev on 12/04/2025.
//

import Foundation
import UIKit

class PaddingLabel: UIView{
    
    var label: UILabel!
    var horizontalPadding: Double!
    var verticalPadding: Double!
    
    var text: String {
        set {
            label.text = newValue
        }
        get { label.text! }
    }
    
    var textColor: UIColor {
        set {
            label.textColor = newValue
        }
        get { label.textColor }
    }
    
    var textAlignment: NSTextAlignment {
        set {
            label.textAlignment = newValue
        }
        get { label.textAlignment }
    }
    
    var font: UIFont {
        set {
            label.font = newValue
        }
        get { label.font }
    }
    
    var fontSize: CGFloat {
        set {
            label.font = label.font.withSize(newValue)
        }
        get { label.font.pointSize }
    }
    
    init(text: String!,
         font: UIFont = UIFont.systemFont(ofSize: 18),
         verticalPadding: Double,
         horizontalPadding: Double) {
        
        let font = font
        let textSize = text.textSize(withConstrainedWidth: 500, font: font).size
        let viewSize = CGSize(width: textSize.width + horizontalPadding, height: textSize.height + verticalPadding)
        
        super.init(frame: CGRect(origin: .zero, size: viewSize))
        self.backgroundColor = .green
        self.layer.cornerRadius = frame.width / 10
        self.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        
        label = UILabel(frame: CGRect(origin: .zero, size: textSize))
        self.addSubview(label)
        label.center = CGPoint(x: self.frame.width / 2.0, y: self.frame.height / 2.0)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        self.text = text
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func copyPaddingLabel() -> PaddingLabel {
        let view = PaddingLabel(text: self.label.text, verticalPadding: self.verticalPadding, horizontalPadding: self.horizontalPadding)
        view.autoresizingMask =  [.flexibleWidth, .flexibleHeight]
        view.layer.cornerRadius = self.frame.width / 10
        
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.backgroundColor = view.backgroundColor
        
        return view
    }
    
    static func instantiateWith(canvasLabel: UILabel, verticalPadding: Double, horizontalPadding: Double) -> UIView {
        let size = CGSize(width: canvasLabel.frame.size.width + horizontalPadding, height: canvasLabel.frame.size.height + verticalPadding)

        let view = UIView(frame: CGRect(origin: .zero, size: size))
        let label = canvasLabel.copyLabel()
        
        let bounds = label.bounds
        label.font = label.font.withSize(200)
        label.bounds.size = label.intrinsicContentSize
        label.layer.cornerRadius = label.bounds.size.height / 10
        
        let scaleX = bounds.size.width / label.frame.size.width
        let scaleY = bounds.size.height / label.frame.size.height
        
        
        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        label.center = CGPoint(x: view.frame.size.width / 2.0, y: view.frame.size.height / 2.0)
        view.addSubview(label)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return view
    }
    
    
    // MARK: UI Updates
    var heightConstraint: NSLayoutConstraint? {
        get {
            return constraints.first(where: {
                $0.firstAttribute == .height && $0.relation == .equal
            })
        }
        set { setNeedsLayout() }
    }
   
    var widthConstraint: NSLayoutConstraint? {
        get {
            return constraints.first(where: {
                $0.firstAttribute == .width && $0.relation == .equal
            })
        }
        set { setNeedsLayout() }
    }
    
}
