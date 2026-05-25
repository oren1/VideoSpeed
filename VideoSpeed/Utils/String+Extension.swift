//
//  String+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/01/2025.
//

import CoreGraphics
import UIKit
import NaturalLanguage


extension String {
    func nsRangeOfLastWord() -> NSRange? {
        let nsText = self as NSString
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self

        var lastRange: NSRange?

        tokenizer.enumerateTokens(in: self.startIndex..<self.endIndex) { range, _ in
            lastRange = NSRange(range, in: self)
            return true
        }

        return lastRange
    }

    
    func nsRange(of substring: String,
                    options: CompareOptions = []) -> NSRange? {
           guard let range = self.range(of: substring, options: options) else {
               return nil
           }
           return NSRange(range, in: self)
       }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
    
    func textSize(withConstrainedWidth width: CGFloat, font: UIFont) -> CGRect {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox
    }
    
   static func getLinesOfText(_ text: String, font: UIFont, width: CGFloat) -> [String] {
        let textStorage = NSTextStorage(string: text)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        var lines: [String] = []
        var index = 0

        while index < layoutManager.numberOfGlyphs {
            var lineRange = NSRange(location: 0, length: 0)
            let rect = layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)

            // Convert glyph range to character range
            let charRange = layoutManager.characterRange(forGlyphRange: lineRange, actualGlyphRange: nil)
            if let substringRange = Range(charRange, in: text) {
                let lineString = String(text[substringRange])
                
                // Remove any \n characters
                let cleanedLine = lineString.replacingOccurrences(of: "\n", with: "")
                lines.append(cleanedLine)
            }

            index = NSMaxRange(lineRange)
        }

        return lines
    }
}
