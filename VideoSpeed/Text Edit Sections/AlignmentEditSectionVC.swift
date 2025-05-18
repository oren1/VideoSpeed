//
//  AlignmentEditSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/05/2025.
//

import UIKit

typealias AlignmentClosure = (NSTextAlignment) -> Void

class AlignmentEditSectionVC: UIViewController {
    private var leftButton: UIButton!
    private var centerButton: UIButton!
    private var rightButton: UIButton!

    var didSelectAlignment: AlignmentClosure?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear

            leftButton = createButtonWithImage(named: "text.alignleft")
            centerButton = createButtonWithImage(named: "text.aligncenter")
            rightButton = createButtonWithImage(named: "text.alignright")
        
        leftButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        centerButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [leftButton, centerButton, rightButton])
            stackView.axis = .horizontal
            stackView.spacing = 16
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

    private func createButtonWithImage(named imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(named: imageName) ?? UIImage(systemName: imageName)
        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.tintColor = .white // or any color you want
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 60).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        // Reset all buttons to default color
        [leftButton, centerButton, rightButton].forEach { button in
            button?.tintColor = .white
        }
        
        // Highlight tapped button
        sender.tintColor = .systemBlue
        
        let textAlignment: NSTextAlignment
        
        switch sender {
        case leftButton:
            textAlignment = .left
        case centerButton:
            textAlignment = .center
        case rightButton:
            textAlignment = .right
        default:
            fatalError()
        }
        
        didSelectAlignment?(textAlignment)
    
    }


}

