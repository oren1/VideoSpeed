//
//  BackgroundStyleEditSectionViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 21/05/2025.
//

import UIKit

//
//  AlignmentEditSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/05/2025.
//

import UIKit

typealias BGStyleClosure = (BackgroundStyle) -> Void

class BGStyleEditSectionVC: UIViewController {
    private var fullBackgroundButton: UIButton!
    private var fragmentedBackgroundButton: UIButton!

    var didSelectBGStyle: BGStyleClosure?
    
    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear

        fullBackgroundButton = createButtonWithImage(named: "rectangle.fill")
        fragmentedBackgroundButton = createButtonWithImage(named: "distribute.vertical.bottom.fill")
        
        fullBackgroundButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        fragmentedBackgroundButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [fullBackgroundButton, fragmentedBackgroundButton])
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
        [fullBackgroundButton, fragmentedBackgroundButton].forEach { button in
            button?.tintColor = .white
        }
        
        // Highlight tapped button
        sender.tintColor = .systemBlue
        
        let backgroundStyle: BackgroundStyle
        
        switch sender {
        case fullBackgroundButton:
            backgroundStyle = .full
        case fragmentedBackgroundButton:
            backgroundStyle = .fragmented
        default:
            fatalError()
        }
        
        didSelectBGStyle?(backgroundStyle)
    
    }


}

