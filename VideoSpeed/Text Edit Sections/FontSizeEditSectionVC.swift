//
//  FontSizeEditSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 18/05/2025.
//

import UIKit

class FontSizeEditSectionVC: UIViewController {

    var onFontSizeChange: ((Int) -> Void)?

    private let fontSizeLabel: UILabel = {
            let label = UILabel()
            label.text = "18"
            label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private let fontSizeSlider: UISlider = {
            let slider = UISlider()
            slider.minimumValue = 10
            slider.maximumValue = 72
            slider.tintColor = .white
            slider.value = 18 // default font size
            slider.translatesAutoresizingMaskIntoConstraints = false
            return slider
        }()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            
            // Add label to view
            view.addSubview(fontSizeLabel)
            view.addSubview(fontSizeSlider)

            NSLayoutConstraint.activate([
                fontSizeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                fontSizeLabel.bottomAnchor.constraint(equalTo: fontSizeSlider.topAnchor, constant: -20)
            ])
            
            // Add slider to view
            NSLayoutConstraint.activate([
                fontSizeSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                fontSizeSlider.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                fontSizeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                fontSizeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
            ])
            
            // Add target for slider value change
            fontSizeSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        }
        
        @objc private func sliderValueChanged(_ sender: UISlider) {
            let fontSize = Int(sender.value)
            // Update label with new font size
            fontSizeLabel.text = "\(fontSize)"
            // Handle font size change as needed, e.g., notify delegate or callback
            onFontSizeChange?(fontSize)
        }

}
