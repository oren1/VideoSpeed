//
//  CaptionsStyle.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 13/01/2026.
//

import Combine
import Foundation
import UIKit

enum CaptionsType {
    case oneWord, wordByWord, wordHighlighted
}

final class CaptionsStyle: ObservableObject {
    @Published var captionType: CaptionsType = .oneWord
    @Published var textColor: UIColor = .white
    @Published var borderColor: UIColor = .black
    @Published var highlightColor: UIColor?
    @Published var font: UIFont = .systemFont(ofSize: CaptionStyleGenerator.basicFontSize)
}
