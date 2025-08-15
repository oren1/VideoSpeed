//
//  LanguageItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/08/2025.
//

import Foundation

struct LanguageItem: Identifiable, Codable {
    let id: String // Use identifier as the ID
    let identifier: String
    let localizedString: String
    var isSelected: Bool
    
    init(identifier: String, localizedString: String, isSelected: Bool = false) {
        self.id = identifier
        self.identifier = identifier
        self.localizedString = localizedString
        self.isSelected = isSelected
    }
}

