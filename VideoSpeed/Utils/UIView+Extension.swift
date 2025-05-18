//
//  UIView+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 12/02/2025.
//

import UIKit


import UIKit

extension UIView {
    func attachToEdges(of superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
}
