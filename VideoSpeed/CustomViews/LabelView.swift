//
//  LabelView.swift
//  VideoSpeed
//
//  Created by oren shalev on 05/02/2025.
//

import UIKit
import AVFoundation

class LabelView: UIView {

    var viewModel: LabelViewModel!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("LabelView", owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
    }
     
    func copyLabelView() -> LabelView {
        let labelToCopy = subviews.first { type(of: $0) == SpidLabel.self } as! SpidLabel
        let label = SpidLabel(frame: labelToCopy.frame)
        label.text = labelToCopy.text
        label.textColor = labelToCopy.textColor
        label.backgroundColor = .green
        label.numberOfLines = labelToCopy.numberOfLines
        label.layer.masksToBounds = true
        label.textAlignment = labelToCopy.textAlignment

        let labelView = LabelView(frame: frame)

        labelView.center = center
        labelView.layer.borderWidth = layer.borderWidth
        labelView.layer.borderColor = layer.borderColor
        labelView.layer.cornerRadius = layer.cornerRadius

        label.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
        labelView.addSubview(label)
        
       
        
        let bounds = label.bounds
        label.font = label.font.withSize(100)
        label.bounds.size = label.intrinsicContentSize
        label.layer.cornerRadius = label.bounds.size.height / 10
        
        let scaleX = bounds.size.width / label.frame.size.width
        let scaleY = bounds.size.height / label.frame.size.height
        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        labelView.layer.displayIfNeeded()
        label.layer.displayIfNeeded()

        return labelView
    }
    
    func scaledBy(_ scaleFactor: CGFloat) -> LabelView {
        let x = self.frame.origin.x * scaleFactor
        let y = self.frame.origin.y * scaleFactor

        let labelView = LabelView(frame: CGRect(x: x, y: y, width: frame.width, height: frame.height))
        labelView.center = CGPoint(x: center.x * scaleFactor, y: center.y * scaleFactor)
        labelView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return labelView
    }
    
    static func instantiateWithLabelViewModel(_ model: LabelViewModel) -> LabelView {

        let labelView = LabelView(frame: CGRect(origin: .zero, size: CGSize(width: model.width, height: model.height)))
        labelView.viewModel = model

        labelView.center = .zero
        labelView.layer.borderWidth = model.borderWidth
        labelView.layer.borderColor = model.borderColor
        labelView.layer.cornerRadius = 8
        
        
        let label = SpidLabel(frame: model.labelFrame)
        label.text = model.text
        label.textColor = model.textColor
        label.backgroundColor = model.backgroundColor
        label.numberOfLines = model.numberOfLines
        label.layer.masksToBounds = model.masksToBounds
        label.textAlignment = model.textAlignment
        

        label.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
        labelView.addSubview(label)
      
        let bounds = label.bounds
        label.font = label.font.withSize(200)
        label.bounds.size = label.intrinsicContentSize
        label.layer.cornerRadius = label.bounds.size.height / 10
        
        let scaleX = bounds.size.width / label.frame.size.width
        let scaleY = bounds.size.height / label.frame.size.height
        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)


        
        return labelView
    }
}

