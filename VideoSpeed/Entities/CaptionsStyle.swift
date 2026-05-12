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

    /// PostScript face + metadata; use `fontSize` and `resolvedUIFont` for the actual `UIFont`.
    @Published var spidFont: SpidFont
    @Published var fontSize: CGFloat

    init(
        spidFont: SpidFont = CaptionsStyle.defaultSpidFont,
        fontSize: CGFloat = 32
    ) {
        self.spidFont = spidFont
        self.fontSize = fontSize
    }

    /// Default matches first catalog entry (display “SYSTEM”, PostScript `TimesNewRomanPSMT`).
    static let defaultSpidFont = SpidFont(
        name: "TimesNewRomanPSMT",
        displayName: "SYSTEM",
        font: nil,
        isPro: false
    )

    /// Builds a `UIFont` from `spidFont.name` and `fontSize`, optionally scaled (e.g. preview/export).
    func resolvedUIFont(scale: CGFloat = 1.0) -> UIFont {
        let pointSize = fontSize * scale
        return UIFont(name: spidFont.name, size: pointSize) ?? .systemFont(ofSize: pointSize)
    }
}
