//
//  VerticalLabelsView.swift
//  VideoSpeed
//
//  Created by oren shalev on 21/05/2025.
//

import UIKit

class VerticalLabelsView: UIView {
    
    // Constants for spacing
    private let verticalSpacing: CGFloat = 8
    private var viewModel: LabelViewModel
    
    // StackView to align labels vertically
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.distribution = .fillProportionally
        sv.spacing = -2
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // Initializer
    init(strings: [String], viewModel: LabelViewModel, font: UIFont? = nil) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
        addLabels(for: strings, font: font)
        
        switch viewModel.textAlignment {
        case .left:
            stackView.alignment = .leading
        case .center:
            stackView.alignment = .center
        case .right:
            stackView.alignment = .trailing
        default:
            stackView.alignment = .center
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Setup container view
    private func setupView() {
        stackView.attachToEdges(of: self)
    }
    
    // Add labels for each string in array
    private func addLabels(for strings: [String], font: UIFont?) {
        for string in strings {
            let label = PaddedLabel()
//            label.text = string
//            label.textColor = viewModel.textColor
            label.font = font == nil ? viewModel.font : font
            label.textAlignment = viewModel.textAlignment
            label.numberOfLines = 1
            label.backgroundColor = viewModel.backgroundColor
            if viewModel.textAlignment == .center {
                var labelHeight = string.textSize(withConstrainedWidth: .greatestFiniteMagnitude, font: label.font).height
                labelHeight = labelHeight + (labelHeight * 0.1)
                label.layer.cornerRadius =  labelHeight * 0.1
            }
            label.layer.borderWidth = 0
            label.layer.borderColor = nil
            label.layer.masksToBounds = true
            label.translatesAutoresizingMaskIntoConstraints = false
            label.layer.contentsScale = .greatestFiniteMagnitude
            label.adjustsFontSizeToFitWidth = true
            label.layer.shouldRasterize = false
            label.layer.contentsScale = UIScreen.main.scale
            label.layer.rasterizationScale = UIScreen.main.scale
    
            // Stroke + fill
            let attributes: [NSAttributedString.Key: Any] = [
                .strokeColor: viewModel.strokeColor,
                .foregroundColor: viewModel.textColor,
                .strokeWidth: viewModel.strokeWidth // Negative means stroke + fill
            ]
            
            label.attributedText = NSAttributedString(string: string, attributes: attributes)

            
            
            stackView.addArrangedSubview(label)
        }
                
        setNeedsLayout()
        layoutSubviews()
    }
    
    
    
}


class PaddedLabel: UILabel {

    var horizontalPaddingRatio: CGFloat = 0.05
    var verticalPaddingRatio: CGFloat = 0.05

    var currentPadding: UIEdgeInsets = .zero

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update the padding based on current size
        let horizontal = bounds.width * horizontalPaddingRatio
        let vertical = bounds.height * verticalPaddingRatio
        currentPadding = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)

        invalidateIntrinsicContentSize()
        setNeedsDisplay()
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: currentPadding))
    }

    override var intrinsicContentSize: CGSize {
        let baseSize = super.intrinsicContentSize
        return CGSize(
            width: baseSize.width + currentPadding.left + currentPadding.right,
            height: baseSize.height + currentPadding.top + currentPadding.bottom
        )
    }
}

