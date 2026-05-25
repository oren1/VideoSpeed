//
//  RoundedBackgroundCaptionLabel.swift
//  VideoSpeed
//
//  Created by Codex on 10/05/2026.
//

import UIKit

extension NSAttributedString.Key {
    /// Fill color for a pill-shaped word highlight (drawn by `RoundedBackgroundCaptionLabel`).
    static let roundedBackgroundHighlightColor = NSAttributedString.Key("roundedBackgroundHighlightColor")
}

/// UILabel that draws `roundedBackgroundHighlightColor` ranges as rounded rects before the glyphs.
final class RoundedBackgroundCaptionLabel: UILabel {

    var highlightCornerRadius: CGFloat = 6
    var highlightHorizontalPadding: CGFloat = 4
    var highlightVerticalPadding: CGFloat = 2

    override func drawText(in rect: CGRect) {
        guard let attributedText = attributedText, attributedText.length > 0 else {
            super.drawText(in: rect)
            return
        }

        let textRect = self.textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        drawRoundedHighlights(for: attributedText, in: textRect)
        super.drawText(in: rect)
    }

    private func drawRoundedHighlights(for attributedText: NSAttributedString, in textRect: CGRect) {
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: textRect.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(
            .roundedBackgroundHighlightColor,
            in: fullRange,
            options: []
        ) { value, characterRange, _ in
            guard let color = value as? UIColor else { return }

            let glyphRange = layoutManager.glyphRange(forCharacterRange: characterRange, actualCharacterRange: nil)
            guard glyphRange.length > 0 else { return }

            layoutManager.enumerateEnclosingRects(
                forGlyphRange: glyphRange,
                withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                in: textContainer
            ) { glyphRect, _ in
                var highlightRect = glyphRect
                highlightRect.origin.x += textRect.origin.x
                highlightRect.origin.y += textRect.origin.y
                highlightRect = highlightRect.insetBy(
                    dx: -self.highlightHorizontalPadding,
                    dy: -self.highlightVerticalPadding
                )
                let path = UIBezierPath(roundedRect: highlightRect, cornerRadius: self.highlightCornerRadius)
                color.setFill()
                path.fill()
            }
        }
    }
}
