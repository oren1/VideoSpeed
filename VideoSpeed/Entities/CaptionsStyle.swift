//
//  CaptionsStyle.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 13/01/2026.
//

import Foundation
import UIKit

enum captionsType {
    case oneWord, wordByWord, wordHighlighted
}

class CaptionsStyle {
    var captionType: captionsType = .oneWord
    var textColor: UIColor = .white
    var borderColor: UIColor = .black
    var highlightColor: UIColor?
    var font: UIFont = .systemFont(ofSize: CaptionStyleGenerator.basicFontSize)
}
