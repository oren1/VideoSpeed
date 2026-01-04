//
//  ScalableTextContainer.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 06/10/2025.
//


import UIKit
import Combine

class CaptionsTextContainer: UIView {
    
    let label = UILabel()
    private var baseFontSize: CGFloat = 32
    private var currentScale: CGFloat = 1.0
    private var currentRotation: CGFloat = 0.0
    private let closeButton = UIButton(type: .system)
//    private var initialFrame: CGRect = .zero
    var viewModel: ViewModel = ViewModel()
    var subscriptions: Set<AnyCancellable> = []
    
    // MARK: - Init
    override init(frame: CGRect) {
        viewModel.initialFrame = frame
        super.init(frame: frame)
        setupView()
        setupViewModel()
        setupLabel(frame: frame)
//        setupTextLayer(frame: frame)
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
    
    func setupViewModel() {
        viewModel.$center.receive(on: DispatchQueue.main).sink { [weak self] center in
            self?.center = center
        }
        .store(in: &subscriptions)
    }
    
    private func setupLabel(frame: CGRect) {
       
        let scale = 4.0

        let text = "Pinch to scale me uhguy hygu khgcd"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: baseFontSize * scale)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byWordWrapping
    
//        label.backgroundColor = .red
        let scaledWidth = frame.width * scale
        let scaledHeight = frame.height * scale

        let scaledFontSize = baseFontSize * scale
        
//        let labelHeight: CGFloat = text.height(withConstrainedWidth: frame.width, font: UIFont.systemFont(ofSize: baseFontSize))
//        label.frame = CGRect(x: 0, y: 0, width: frame.width, height: labelHeight)
        
//        let labelHeight: CGFloat = text.height(withConstrainedWidth: scaledWidth, font: UIFont.systemFont(ofSize: scaledFontSize))
//        label.frame = CGRect(x: 0, y: 0, width: scaledWidth, height: labelHeight)

       
        label.frame = CGRect(x: 0, y: 0, width: scaledWidth , height: scaledHeight)
        
        
//        label.sizeToFit()

        
//        let bounds = label.bounds
//        label.font = label.font.withSize(200)
//        label.bounds.size = label.intrinsicContentSize
//        
////        label.layer.cornerRadius = label.bounds.size.height / 10
//        
//        let scaleX = label.bounds.size.width / label.frame.size.width
//        let scaleY = label.bounds.size.height / label.frame.size.height
//
//        
        label.transform = CGAffineTransform(scaleX: 1/scale, y: 1/scale)
//        label.backgroundColor = .green
        label.center = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
//        view.addSubview(label)
        
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

        
//        label.translatesAutoresizingMaskIntoConstraints = false
//        let constraints = [
//            label.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
//            label.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor),
//            label.rightAnchor.constraint(equalTo: self.safeAreaLayoutGuide.rightAnchor),
////            label.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
//        ]
//        
//        NSLayoutConstraint.activate(constraints)
//        setNeedsLayout()
    }
    private func setupTextLayer(frame: CGRect) {
        let textLayer = CATextLayer()

        // 2. Set its properties
        textLayer.frame = frame
        textLayer.string = "Hello, World!"
        textLayer.fontSize = 32
        textLayer.foregroundColor = UIColor.blue.cgColor
        textLayer.font = UIFont.systemFont(ofSize: 32) // Assign UIFont
        textLayer.backgroundColor = UIColor.yellow.cgColor
//        label.center = CGPoint(x: self.frame.size.width / 2.0, y: self.frame.size.height / 2.0)
        textLayer.contentsScale = UIScreen.main.scale

        // 3. Add the layer to the view's layer
        self.layer.addSublayer(textLayer)
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
            viewModel.fullScale *= gesture.scale
            print("viewModel.fullScale \(viewModel.fullScale)")
            applyTransform(scale: viewModel.fullScale, rotation: viewModel.fullRotation)

//            currentScale *= gesture.scale
//            applyTransform(scale: currentScale, rotation: currentRotation)
            
            gesture.scale = 1
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            viewModel.fullRotation += gesture.rotation
            applyTransform(scale: viewModel.fullScale, rotation: viewModel.fullRotation)
//            currentRotation += gesture.rotation
//            applyTransform(scale: currentScale, rotation: currentRotation)
            gesture.rotation = 0
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        
//        let translation = gesture.translation(in: self.videoContainerView)
//       
//       guard let selectedLabelViewModel = UserDataManager.main.selectedLabelViewModel else { return }
//         let center = CGPoint(
//           x: selectedLabelViewModel.center.x + translation.x,
//           y: selectedLabelViewModel.center.y + translation.y
//         )
//         selectedLabelViewModel.center = center
//         gesture.setTranslation(.zero, in: view)
        
        let translation = gesture.translation(in: superview)
        viewModel.center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
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
        func duplicate() -> CaptionsTextContainer {
            let copy = CaptionsTextContainer(frame: viewModel.initialFrame)
            
            // Copy visual attributes
            copy.backgroundColor = backgroundColor
//            copy.layer.borderWidth = layer.borderWidth
//            copy.layer.borderColor = layer.borderColor
//            copy.layer.cornerRadius = layer.cornerRadius
            
            // Copy text
//            copy.label.text = label.text
//            copy.label.textColor = label.textColor
//            copy.baseFontSize = baseFontSize
//            copy.label.font = label.font
//            copy.label.textAlignment = label.textAlignment
//            copy.label.numberOfLines = label.numberOfLines
            
            // Copy transform state
            copy.currentScale = currentScale
            copy.currentRotation = currentRotation
            
//            copy.applyTransform(scale: currentScale, rotation: currentRotation)
            
            // Copy position
            copy.center = center
            
            return copy
        }
    
    func duplicateNoTransform() -> CaptionsTextContainer {
        let copy = CaptionsTextContainer(frame: viewModel.initialFrame)
        
        // Copy visual attributes
        copy.backgroundColor = backgroundColor
//            copy.layer.borderWidth = layer.borderWidth
//            copy.layer.borderColor = layer.borderColor
//            copy.layer.cornerRadius = layer.cornerRadius
        
        // Copy text
//            copy.label.text = label.text
//            copy.label.textColor = label.textColor
//            copy.baseFontSize = baseFontSize
//            copy.label.font = label.font
//            copy.label.textAlignment = label.textAlignment
//            copy.label.numberOfLines = label.numberOfLines
        
        // Copy transform state
        copy.currentScale = currentScale
        copy.currentRotation = currentRotation
        
        
        copy.viewModel.fullScale = viewModel.fullScale
        copy.viewModel.fullRotation = viewModel.fullRotation
        copy.viewModel.center = center

        
        //        copy.applyTransform(scale: currentScale, rotation: currentRotation)
        
        // Copy position
//        copy.center = center
        
        return copy
    }
}

extension CaptionsTextContainer {
    class ViewModel: ObservableObject {
        @Published
        var initialFrame: CGRect = .zero
        
        @Published
        var center: CGPoint = .zero
        
        @Published
        var fullRotation: CGFloat = 0.0
        
        @Published
        var fullScale: CGFloat = 1
    }
}
