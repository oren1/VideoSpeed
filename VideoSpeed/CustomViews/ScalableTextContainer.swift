//
//  ScalableTextContainer.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 06/10/2025.
//


import UIKit

class ScalableLabelTextContainer: UIView {
    let label = UILabel()
    private var baseFontSize: CGFloat = 24
    private var currentScale: CGFloat = 1.0
    private var currentRotation: CGFloat = 0.0
    private let closeButton = UIButton(type: .system)
    private var initialFrame: CGRect = .zero
    
    // MARK: - Init
    override init(frame: CGRect) {
        initialFrame = frame
        super.init(frame: frame)
        setupView()
        setupLabel(frame: frame)
        setupGesture()
        setupCloseButton()
    }

    required init?(coder: NSCoder) {

        super.init(coder: coder)
//        setupView()
//        setupLabel()
//        setupGesture()
//        setupCloseButton()
    }
    
    // MARK: - Setup
    func setupView() {
        backgroundColor = .clear
        layer.borderWidth = 1
        layer.borderColor = UIColor.blue.cgColor
        layer.cornerRadius = 8
    }
    
    private func setupLabel(frame: CGRect) {
        let text = "Pinch to scale me uhguy hygu khgcd"
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: baseFontSize)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byWordWrapping
    
        label.backgroundColor = .red
        let labelHeight: CGFloat = text.height(withConstrainedWidth: frame.width, font: UIFont.systemFont(ofSize: baseFontSize))
        label.frame = CGRect(x: 0, y: 0, width: frame.width, height: labelHeight)
//        label.sizeToFit()

        addSubview(label)
        
        
        
//        let label = label
//        let bounds = label.bounds
//        print("bounds \(bounds)")
//        label.font = label.font.withSize(200)
//        label.bounds.size = label.intrinsicContentSize
////        label.layer.cornerRadius = label.bounds.size.height / 10
//        
//        let scaleX = bounds.size.width / label.frame.size.width
//        let scaleY = bounds.size.height / label.frame.size.height
//        
//        label.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//        label.center = .init(x: self.frame.width / 2, y: self.frame.height / 2)

        
        label.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            label.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            label.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor),
            label.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor),
//            label.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
//        setNeedsLayout()
    }
    
    private func setupCloseButton() {
        closeButton.setTitle("✕", for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 12
        closeButton.clipsToBounds = true
        
        // Place outside the top-left corner
        closeButton.frame = CGRect(x: -12, y: -24, width: 24, height: 24)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        addSubview(closeButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        label.frame = bounds.insetBy(dx: 8, dy: 8)
//        label.sizeToFit()

    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Include touches on the close button even outside bounds
        if super.point(inside: point, with: event) { return true }
        let convertedPoint = closeButton.convert(point, from: self)
        return closeButton.bounds.contains(convertedPoint)
    }

    // MARK: - Gestures
    private func setupGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        addGestureRecognizer(rotation)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            currentScale *= gesture.scale
            applyTransform(scale: currentScale, rotation: currentRotation)
//            label.font = label.font.withSize(baseFontSize * currentScale)
            gesture.scale = 1
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            currentRotation += gesture.rotation
            applyTransform(scale: currentScale, rotation: currentRotation)
            gesture.rotation = 0
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)
    }

    // MARK: - Helpers
    private func applyTransform(scale: CGFloat, rotation: CGFloat) {
        let transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .rotated(by: rotation)
        self.transform = transform
        
        // Keep the ✕ button same size (not scaled) but rotated
        let inverseScale = 1 / currentScale
        closeButton.transform = CGAffineTransform.identity
            .scaledBy(x: inverseScale, y: inverseScale)
            .rotated(by: rotation)
    }

    @objc private func closeTapped() {
        removeFromSuperview()
    }
    
    
    // MARK: - Duplication
        func duplicate() -> ScalableLabelTextContainer {
            let copy = ScalableLabelTextContainer(frame: initialFrame)
            
            // Copy visual attributes
            copy.backgroundColor = backgroundColor
            copy.layer.borderWidth = layer.borderWidth
            copy.layer.borderColor = layer.borderColor
            copy.layer.cornerRadius = layer.cornerRadius
            
            // Copy text
            copy.label.text = label.text
            copy.label.textColor = label.textColor
            copy.baseFontSize = baseFontSize
            copy.label.font = label.font
            copy.label.textAlignment = label.textAlignment
            copy.label.numberOfLines = label.numberOfLines
            
            // Copy transform state
            copy.currentScale = currentScale
            copy.currentRotation = currentRotation
            copy.applyTransform(scale: currentScale, rotation: currentRotation)
            
            // Copy position
            copy.center = center
            
            return copy
        }
}
