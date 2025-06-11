//
//  UIView+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 12/02/2025.
//

import UIKit


import UIKit

extension UIView {
    func attachToEdges(of superview: UIView, constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: constant),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: constant),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: constant),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: constant)
        ])
    }
    
    
//    func captureAsImage(scaleFactor: CGFloat = 1.0) -> UIImage? {
//           let size = self.bounds.size
//           let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
//           
//           UIGraphicsBeginImageContextWithOptions(scaledSize, false, scaleFactor)
//           guard let context = UIGraphicsGetCurrentContext() else { return nil }
//           
//           // Scale the context to account for high resolution
//           context.scaleBy(x: scaleFactor, y: scaleFactor)
//           
//           // Render the view's layer into the context
//           self.layer.render(in: context)
//           
//           // Retrieve the image
//           let image = UIGraphicsGetImageFromCurrentImageContext()
//           UIGraphicsEndImageContext()
//           return image
//       }
    
    func captureAsImage(scaleFactor: CGFloat = 1.0) -> UIImage? {
            let rendererFormat = UIGraphicsImageRendererFormat.default()
            rendererFormat.scale = scaleFactor
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: rendererFormat)
            let image = renderer.image { context in
                self.layer.render(in: context.cgContext)
            }
            return image
        }
}
