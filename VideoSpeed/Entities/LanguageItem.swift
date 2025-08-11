//
//  LanguageItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/08/2025.
//

import Foundation

class LanguageItem: Identifiable {
    let id = UUID()
    let identifier: String
    let localizedString: String
    var isSelected: Bool
    
    init(identifier: String, localizedString: String, isSelected: Bool = false) {
        self.identifier = identifier
        self.localizedString = localizedString
        self.isSelected = isSelected
    }
}
