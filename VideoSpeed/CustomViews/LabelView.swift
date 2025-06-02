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
            
            viewModel?.$text
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] text in
                    guard let self = self else { return }
                    paddingLabel?.text = text
                    let font = UIFont.systemFont(ofSize: 18)
                    let newTextSize = text.textSize(withConstrainedWidth: 500, font: font)
                    viewModel.labelFrame = newTextSize
                    self.frame.size = CGSize(width: self.viewModel.width, height: self.viewModel.height)
                })
                .store(in: &subscribers)
            
            viewModel.$center
                .receive(on: DispatchQueue.main)
                .sink { [weak self] center in
                    self?.center = center
                }.store(in: &subscribers)
            
            viewModel.$scale
                .receive(on: DispatchQueue.main)
                .sink { [weak self] scale in
                    guard let self = self else { return }
                    transform = transform.scaledBy(
                        x: scale,
                        y: scale
                    )
                 cancelButton.transform = cancelButton.transform.scaledBy(x: 1/scale, y: 1/scale)
                 viewModel.fullScale *= scale
                }.store(in: &subscribers)
        
            viewModel.$rotation
                .receive(on: DispatchQueue.main)
                .sink { [weak self] rotation in
                    guard let self = self else { return }
                   
                    transform = transform.rotated(
                        by: rotation
                    )
    
                }.store(in: &subscribers)
            
            viewModel.$isHidden
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isHidden in
                    self?.isHidden = isHidden
                }
                .store(in: &subscribers)
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
        UserDataManager.main.labelViewsModels.removeAll(where: {$0 === self.viewModel})
    }
     
    
    func scaledBy(_ scaleFactor: CGFloat) -> LabelView {
        let x = self.frame.origin.x * scaleFactor
        let y = self.frame.origin.y * scaleFactor

        let labelView = LabelView(frame: CGRect(x: x, y: y, width: frame.width, height: frame.height))
        labelView.center = CGPoint(x: center.x * scaleFactor, y: center.y * scaleFactor)
        labelView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return labelView
    }
    
    static func instantiateWithViewModel(_ viewModel: LabelViewModel) -> LabelView {
        
        if viewModel.backgroundStyle == .fragmented {
            let fontSize = 200.0
            let strings = String.getLinesOfText(viewModel.text, font: viewModel.font, width: .greatestFiniteMagnitude)
            let rawLineHeight = viewModel.font.withSize(fontSize).lineHeight
//            let lineHeight =  rawLineHeight + PaddedLabel.padding.top + PaddedLabel.padding.bottom
            let lineHeight =  rawLineHeight + (rawLineHeight * 0.1)
            let textSize = viewModel.text.textSize(withConstrainedWidth: .greatestFiniteMagnitude, font: viewModel.font.withSize(fontSize)).size
            let verticalLabelsViewHeight = CGFloat(strings.count) * lineHeight
//            let verticalLabelsViewWidth = textSize.width + PaddedLabel.padding.right + PaddedLabel.padding.left
            let verticalLabelsViewWidth = textSize.width + (textSize.width * 0.1)
            let verticalLabelsView = VerticalLabelsView(strings: strings, viewModel: viewModel, font: viewModel.font.withSize(fontSize))
            verticalLabelsView.frame = CGRect(origin: .zero, size: CGSize(width: verticalLabelsViewWidth, height: verticalLabelsViewHeight))
            let scale = viewModel.fontSize / fontSize
            verticalLabelsView.transform = CGAffineTransform(scaleX: scale, y: scale)
//            print("vertical labels view intrinsic size \(verticalLabelsView.intrinsicContentSize)")
            let labelViewSize = CGSize(width: verticalLabelsView.frame.width + LabelViewExtraWidth, height: verticalLabelsView.frame.height + LabelViewExtraHeight)
            let labelView = LabelView(frame: CGRect(origin: .zero, size: labelViewSize))
           
//            verticalLabelsView.setNeedsLayout()
//            verticalLabelsView.layoutIfNeeded()
//            // 1. Create an image from 'VerticalLabelsView' instance
//            if let image = verticalLabelsView.captureAsImage(scaleFactor: 30) {
//                // 2. Create a UIImageView
//                let imageView = UIImageView()
//                imageView.image = image
//                imageView.contentMode = .scaleToFill
//                imageView.frame = CGRect(origin: .zero, size: CGSize(width: verticalLabelsViewWidth, height: verticalLabelsViewHeight))
//                imageView.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
//                labelView.addSubview(imageView)
//                labelView.viewModel = viewModel
//
//                return labelView
//            }
            
            // 3. Add the imageView to the screen instead of the vertic
            
            verticalLabelsView.center = CGPoint(x: labelView.frame.size.width / 2.0, y: labelView.frame.size.height / 2.0)
            
            labelView.viewModel = viewModel
            labelView.addSubview(verticalLabelsView)
            
            return labelView
        }
        
        // Create PaddingLabel to add to the LabelView
        let paddingLabel = PaddingLabel(text: viewModel.text, font: viewModel.font, verticalPadding: 12, horizontalPadding: 12)
        paddingLabel.textColor = viewModel.textColor
        paddingLabel.backgroundColor = viewModel.backgroundColor
        paddingLabel.textAlignment = viewModel.textAlignment
        paddingLabel.font = viewModel.font
        paddingLabel.strokeColor = viewModel.strokeColor
        paddingLabel.strokeWidth = viewModel.strokeWidth
        
        // Create size for the LabelView, adding an extra width and height
        let labelViewSize = CGSize(width: paddingLabel.frame.width + LabelViewExtraWidth, height: paddingLabel.frame.height + LabelViewExtraHeight)
        let labelView = LabelView(frame: CGRect(origin: .zero, size: labelViewSize))
        
        labelView.paddingLabel = paddingLabel
        labelView.viewModel = viewModel
        labelView.center = viewModel.center
        
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
    
    static func instantiateWithPaddingLabel(_ paddingLabel: PaddingLabel, viewModel: LabelViewModel) -> LabelView {
        let labelViewSize = CGSize(width: viewModel.width, height: viewModel.height)
        let labelView = LabelView(frame: CGRect(origin: .zero, size: labelViewSize))
        
        
        
        // copy the PaddingLabel
        let paddingLabel = paddingLabel.copyPaddingLabel()
        labelView.paddingLabel = paddingLabel
        labelView.viewModel = viewModel
        viewModel.center = .zero
//        labelView.center = .zero
        
        
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

