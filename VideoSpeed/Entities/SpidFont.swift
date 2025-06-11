//
//  SpidFont.swift
//  VideoSpeed
//
//  Created by oren shalev on 11/05/2025.
//

import Foundation
import UIKit

class SpidFont {
    let name: String
    let font: UIFont?
    let isPro: Bool
    
    init(name: String, font: UIFont?, isPro: Bool) {
        self.name = name
        self.font = font
        self.isPro = isPro
    }
}

