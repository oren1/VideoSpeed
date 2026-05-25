//
//  SpidFont.swift
//  VideoSpeed
//
//  Created by oren shalev on 11/05/2025.
//

import Foundation
import UIKit

class SpidFont {
    /// PostScript name (e.g. `TimesNewRomanPSMT`), stable identifier for the face.
    let name: String
    /// Label shown in the UI (e.g. `SYSTEM`, `Neo`).
    let displayName: String
    let font: UIFont?
    let isPro: Bool

    init(name: String, displayName: String, font: UIFont?, isPro: Bool) {
        self.name = name
        self.displayName = displayName
        self.font = font
        self.isPro = isPro
    }
}
