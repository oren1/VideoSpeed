//
//  CaptionStyleGenerator.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 10/11/2025.
//

import Foundation
import UIKit

class CaptionStyleGenerator {
   
    static var basicFontSize = CGFloat(32)
    static let scaleFactor = 4.0
    
    static func getCurrentCaption(captions: [Caption], time: Double) -> Caption {
       
        // look for the current caption that needs to be presented
        for caption in captions {
            if time.isLessThanOrEqualTo(caption.endTime) && caption.startTime.isLessThanOrEqualTo(time) {
                return caption
            }
        }
        
        return  Caption(startTime:0 , endTime: 0, text: NSAttributedString(string: "", attributes: [:]))
        
    }
    
    
    static func getCurrentWordByWordCaption(captions: [Caption], time: Double) -> Caption {
       
        // look for the current caption that needs to be presented
        for (index, caption) in captions.enumerated() {
            if time.isLessThanOrEqualTo(caption.endTime) {
//                return caption

                if caption.startTime.isLessThanOrEqualTo(time) {
                    return caption
                }
                
                let previousCaptionIndex = (index - 1) < 0 ? 0 : index - 1
                return captions[previousCaptionIndex]
            }
        }
        
        return  Caption(startTime:0 , endTime: 0, text: NSAttributedString(string: "", attributes: [:]))
        
    }
    
    static func generateOneWordCaptionStyle(segment: Segment, time: Double) -> NSAttributedString {
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        // look for the current word that needs to be presented
        for word in segment.words {
            if word.start.isLessThanOrEqualTo(time) && time.isLessThanOrEqualTo(word.end) {
                let attributedString = NSAttributedString(
                    string: word.text,
                    attributes: attributes
                )
                return attributedString

            }
        }
        
        
        return NSAttributedString(string: "", attributes: [:])
        
//        let text = segment.text
//        let fullString = NSMutableAttributedString(string: text)

        // Apply style to "Hello"
//        fullString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: 5))
//
//        // Apply style to "world"
//        fullString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 30), range: NSRange(location: 7, length: 5))
        
//        return fullString
    }
    
    
    
    static func generateOneByOneCaptionStyle(segment: Segment, time: Double) -> NSAttributedString {
       
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
        ]
        
        // 1. Iterate the segment's words to get the index of the next word needed to be added to the caption text
        var currentWordIndex: Int?
        for (index, word) in segment.words.enumerated() {
            if time.isLessThanOrEqualTo(word.end) {
                if word.start.isLessThanOrEqualTo(time) {
                    currentWordIndex = index
                    break
                }
                else { /* In case that the  current video time is in between words and still didn't get
                        to the time frame of the next word. its not bigger than the "word.end" but still
                        didn't reach to the "word.start"
                        */
                    currentWordIndex = index - 1
                    break

                }
            }
        }
        
        /* 2. If the index is less than 0, it means that the video's current time didn't pass the start time of the
         first word in the segment. in this case no word should be presented and i return an empty string.
         */
        if let currentWordIndex, currentWordIndex < 0 {
            return NSAttributedString(string: "", attributes: [:])
        }
        else if currentWordIndex == nil {
            /* The 'currentWordIndex' will be 'nil' only in the case the video's current
               time has passed the 'endTime' of the last word, in which case the 'currentWordIndex' is not assigned
               and in this case, show the entire sentence
             */
            currentWordIndex = segment.words.count - 1

        }
        
        // 3. Combine the words of the segment up to 'currentWordIndex' index
            var combinedText: String = ""
            for wordIndex in 0...currentWordIndex! {
                combinedText += segment.words[wordIndex].text
                combinedText += " "
            }
            let attributedString = NSAttributedString(
                string: combinedText,
                attributes: attributes
            )
            return attributedString
        

    }
    
    
    // function that gets a segments array and returns a Captions array with timmings
    static func generateOneWordCaptions(from segments: [Segment]) -> [Caption] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        var captions: [Caption] = []
        
        for segment in segments {
            for word in segment.words {
                let startTime = word.start
                let endTime = word.end
                let text = NSAttributedString(string: "\(word.text)", attributes: attributes)
                captions.append(Caption(startTime: startTime, endTime: endTime, text: text))
            }
        }
        
        return captions
    }
    
    static func generateOneByOneCaptions(from segments: [Segment], scale: CGFloat = 4.0) -> [Caption] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
    
        let fontSize: CGFloat = basicFontSize * scale
    
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor.red,
            .paragraphStyle: paragraphStyle
        ]
        
        var captions: [Caption] = []
        
        for segment in segments {
           for index in 0..<segment.words.count {
              
               var phrase = ""
               for i in 0...index {
                   let word = segment.words[i]
                   
                   if i == index {
                       // if it's the last word, add it without the space
                       phrase += word.text
                   }
                   else {
                       phrase += word.text + " "
                   }
               }
               
               // 1. Search for the range of the phrase in the complete segment text
               guard let nsRange = segment.text.nsRange(of: phrase, options: .caseInsensitive) else {continue}
               
               // 2. Create the NSMutableAttributesString with the entire segment's text
               let captionAttributtedText = NSMutableAttributedString(string: segment.text)

               // 3. Give specific attributes for the current phrase range
               captionAttributtedText.addAttribute(.foregroundColor,
                                                   value: UIColor.red,
                                                   range: nsRange)
               captionAttributtedText.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize, weight: .light), range: nsRange)
               captionAttributtedText.addAttributes([.paragraphStyle: paragraphStyle], range: nsRange)
               
               captionAttributtedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: segment.text.count))

               
               
               // 4. Give the rest of the text different attributes
//               let remainingTextRange = nsRange.upperBound..<segment.text.count
               let length = segment.text.count - nsRange.upperBound
               let nsRemainingTextRange = NSRange(location: nsRange.upperBound, length: length)
               captionAttributtedText.addAttribute(.foregroundColor, value: UIColor.clear, range: nsRemainingTextRange)
    

               let startTime = segment.words[index].start
               /* To prevent blank area times where text does not apear in the middle of a segment,
                set the endTime of the caption items to the start of the next word except for the
                last word which got no next item*/
               let endTime: Double
               if index == segment.words.count - 1 { // last word in the segment
                  endTime = segment.words[index].end
               }
               else {
                  endTime = segment.words[index + 1].start
               }
               captions.append(Caption(startTime: startTime, endTime: endTime, text: captionAttributtedText))
            }
        }
     
        return captions
    }
    
    
    static func generateWordHighlightCaptions(from segments: [Segment], scale: CGFloat = 4.0) -> [Caption] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
    
        let fontSize: CGFloat = basicFontSize * scale
    
        let attributes: [NSAttributedString.Key : Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        var captions: [Caption] = []
        
        for segment in segments {
           for index in 0..<segment.words.count {
              
               var phrase = ""
               for i in 0...index {
                   let word = segment.words[i]
                   
                   if i == index {
                       // if it's the last word, add it without the space
                       phrase += word.text
                   }
                   else {
                       phrase += word.text + " "
                   }
               }
               
               // 1. Search for the range of the phrase in the complete segment text
               guard let nsRange = segment.text.nsRange(of: phrase, options: .caseInsensitive) else {continue}
               guard let lastWordNSRange = phrase.nsRangeOfLastWord() else {continue}
               
               // 2. Create the NSMutableAttributesString with the entire segment's text
               let captionAttributtedText = NSMutableAttributedString(string: segment.text)

               // 3. Give specific attributes for the current phrase range
               captionAttributtedText.addAttributes([
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white,
//                .backgroundColor: UIColor.green,
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold)
               ], range: nsRange)

               captionAttributtedText.addAttributes([
                .foregroundColor: UIColor.green,
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .strokeColor: UIColor.black,
               ], range: lastWordNSRange)
//               captionAttributtedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: segment.text.count))

               
               
               // 4. Give the rest of the text different attributes
//               let remainingTextRange = nsRange.upperBound..<segment.text.count
               let length = segment.text.count - nsRange.upperBound
               let nsRemainingTextRange = NSRange(location: nsRange.upperBound, length: length)
//               captionAttributtedText.addAttribute(.foregroundColor, value: UIColor.clear, range: nsRemainingTextRange)
               captionAttributtedText.addAttributes(attributes, range: nsRemainingTextRange)

               let startTime = segment.words[index].start
               /* To prevent blank area times where text does not apear in the middle of a segment,
                set the endTime of the caption items to the start of the next word except for the
                last word which got no next item*/
               let endTime: Double
               if index == segment.words.count - 1 { // last word in the segment
                  endTime = segment.words[index].end
               }
               else {
                  endTime = segment.words[index + 1].start
               }
               captions.append(Caption(startTime: startTime, endTime: endTime, text: captionAttributtedText))
            }
        }
     
        return captions
    }

    
}


class Caption {
    let startTime: Double
    let endTime: Double
    let text: NSAttributedString
    
    init(startTime: Double, endTime: Double, text: NSAttributedString) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
    
    var description: String {
        return "Caption(startTime: \(startTime), endTime: \(endTime), text: \(text))"
    }
}
