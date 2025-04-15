//
//  LabelView.swift
//  VideoSpeed
//
//  Created by oren shalev on 05/02/2025.
//

import UIKit
import AVFoundation
import Combine

class LabelView: UIView {

    private var subscribers: [AnyCancellable] = []
    
    var viewModel: LabelViewModel! {
        didSet {
            viewModel.$selected.sink { [weak self] isSelected in
                if isSelected {
                    self?.setSelected()
                }
                else {
                    self?.setUnselected()
                }
            }.store(in: &subscribers)
            
            
//            viewModel.$text.
            
        }
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var cancelButtonTopConstraintConstant: NSLayoutConstraint!
    
    var paddingLabel: PaddingLabel?

    
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
        backgroundView.layer.cornerRadius = 8

    }

    @IBAction func cancelButtonTapped(_ sender: Any) {
        print("cancelButtonTapped")
        self.removeFromSuperview()
        UserDataManager.main.overlayLabelViews.removeAll(where: {$0 == self})
    }
     
    
    func scaledBy(_ scaleFactor: CGFloat) -> LabelView {
        let x = self.frame.origin.x * scaleFactor
        let y = self.frame.origin.y * scaleFactor

        let labelView = LabelView(frame: CGRect(x: x, y: y, width: frame.width, height: frame.height))
        labelView.center = CGPoint(x: center.x * scaleFactor, y: center.y * scaleFactor)
        labelView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return labelView
    }
    
//    static func instantiateWithLabelViewModel(_ model: LabelViewModel) -> LabelView {
//
//        let labelView = LabelView(frame: CGRect(origin: .zero, size: CGSize(width: model.width, height: model.height)))
//        labelView.viewModel = model
//        
//        labelView.center = .zero
////        labelView.layer.borderWidth = model.borderWidth
////        labelView.layer.borderColor = model.borderColor
////        labelView.layer.cornerRadius = 8
//        
//        let label = SpidLabel(frame: model.labelFrame)
//        label.text = model.text
//        label.textColor = model.textColor
//        label.backgroundColor = model.backgroundColor
//        label.numberOfLines = model.numberOfLines
//        label.layer.masksToBounds = model.masksToBounds
//        label.textAlignment = model.textAlignment
//        
//
//        label.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
//        labelView.addSubview(label)
//      
//        let bounds = label.bounds
//        label.font = label.font.withSize(200)
//        label.bounds.size = label.intrinsicContentSize
//        label.layer.cornerRadius = label.bounds.size.height / 10
//        
//        let scaleX = bounds.size.width / label.frame.size.width
//        let scaleY = bounds.size.height / label.frame.size.height
//        
//        
//        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//
//        
//        return labelView
//    }
    

//    static func instantiateWithLabel(_ canvasLabel: UILabel, viewModel: LabelViewModel) -> LabelView {
//
//        let labelView = LabelView(frame: CGRect(origin: .zero, size: canvasLabel.frame.size))
//        labelView.viewModel = viewModel
//        
//        labelView.center = .zero
//        
//        // copy the label
////        let label = canvasLabel.copyLabel()
////
////        label.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
////        labelView.addSubview(label)
////
////        let bounds = label.bounds
////        label.font = label.font.withSize(200)
////        label.bounds.size = label.intrinsicContentSize
////        label.layer.cornerRadius = label.bounds.size.height / 10
////        
////        let scaleX = bounds.size.width / label.frame.size.width
////        let scaleY = bounds.size.height / label.frame.size.height
////        
////        
////        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//
//        let paddingLabel = PaddingLabel.instantiateWith(canvasLabel: canvasLabel, verticalPadding: 10, horizontalPadding: 10)
//        paddingLabel.backgroundColor = .blue
//        paddingLabel.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
//        labelView.addSubview(paddingLabel)
//        
//        return labelView
//    }
    
    
    static func instantiateWithPaddingLabel(_ paddingLabel: PaddingLabel, viewModel: LabelViewModel) -> LabelView {
        let labelViewSize = CGSize(width: viewModel.width, height: viewModel.height)
        let labelView = LabelView(frame: CGRect(origin: .zero, size: labelViewSize))
        
        labelView.center = .zero
        
        // copy the PaddingLabel
        let paddingLabel = paddingLabel.copyPaddingLabel()
        labelView.paddingLabel = paddingLabel
        labelView.viewModel = viewModel

        let label = paddingLabel.label!
        let bounds = label.bounds
        label.font = label.font.withSize(200)
        label.bounds.size = label.intrinsicContentSize
        label.layer.cornerRadius = label.bounds.size.height / 10
        
        let scaleX = bounds.size.width / label.frame.size.width
        let scaleY = bounds.size.height / label.frame.size.height
        
        
        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        paddingLabel.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
        labelView.addSubview(paddingLabel)
        
        return labelView
    }
    
    
    func setSelected() {
        self.backgroundView.layer.borderWidth = 1
        self.backgroundView.layer.borderColor = UIColor.orange.cgColor
        self.cancelButton.isHidden = false
    }
    
    func setUnselected() {
        self.backgroundView.layer.borderWidth = 0
        self.backgroundView.layer.borderColor = UIColor.orange.cgColor
        self.cancelButton.isHidden = true
    }
    
}

