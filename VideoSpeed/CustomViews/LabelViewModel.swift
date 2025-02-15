//
//  LabelViewModel.swift
//  VideoSpeed
//
//  Created by oren shalev on 09/02/2025.
//

import UIKit

struct LabelViewModel {
    var labelFrame: CGRect
    var text: String
    var textColor: UIColor
    var backgroundColor: UIColor
    var numberOfLines = 0
    var masksToBounds = true
    var textAlignment: NSTextAlignment
    var center: CGPoint = .zero
    var borderWidth = 1.0
    var borderColor = UIColor.orange.cgColor
    var scaleTransform: CGAffineTransform = .identity
}
