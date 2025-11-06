//
//  LanguageItem.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/08/2025.
//

import Foundation

struct LanguageItem: Identifiable, Codable, Equatable, Hashable {
    let id: String // Use identifier as the ID
    let identifier: String
    let localizedString: String
    let code: String?
    var isSelected: Bool
    
    init(identifier: String, code: String? = nil, localizedString: String, isSelected: Bool = false) {
        self.id = identifier
        self.identifier = identifier
        self.code = code
        self.localizedString = localizedString
        self.isSelected = isSelected
    }
    
    static func == (lhs: LanguageItem, rhs: LanguageItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var description: String {
        return "LanguageItem(id: \(id), identifier: \(identifier), localizedString: \(localizedString), isSelected: \(isSelected))"
    }
}

