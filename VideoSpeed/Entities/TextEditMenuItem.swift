//
//  TextEditMenuItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 29/04/2025.
//

import Foundation
import UIKit

enum TextEditMenuItemIdentifier: String, CaseIterable {
    case textColor = "Text Color"
    case bgColor = "BG Color"
    case font = "Font"
    case alignment = "Alignment"
    case size = "Size"
    case bgStyle = "BG Style"
    case strokeColor = "Stroke Color"
}

class TextEditMenuItem {
   
    let identifier: TextEditMenuItemIdentifier
    let selectedImage: UIImage?
    let normalImage: UIImage?
    var selected: Bool = false
    
    init(identifier: TextEditMenuItemIdentifier, selectedImage: UIImage?, normalImage: UIImage?, selected: Bool) {
        self.identifier = identifier
        self.selectedImage = selectedImage
        self.normalImage = normalImage
        self.selected = selected
    }
    
   
}
