//
//  Segment.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 16/09/2025.
//

import Foundation

// Word entity
class Word: Codable {

    let text: String
    let start: Double
    let end: Double

    private enum CodingKeys: String, CodingKey {
        case text = "word"
        case start
        case end
    }

    init(text: String, start: Double, end: Double) {
        self.text = text
        self.start = start
        self.end = end
    }
}

// Segment entity
class Segment: NSObject, Decodable {
    let text: String
    let start: Double
    let end: Double
    let words: [Word]

    init(text: String, start: Double, end: Double, words: [Word]) {
        self.text = text
        self.start = start
        self.end = end
        self.words = words
    }
    
    override var description: String {
        return "Segment: \(text), start: \(start), end: \(end)"
    }
}

// API response
class TranscriptionResponse: Codable {

    let text: String
    let words: [Word]?
}


class Transcription {
    
    let text: String
    let words: [Word]?
    let segments: [Segment]?
    
    init?(transcriptionResponse: TranscriptionResponse) {
        guard let words = transcriptionResponse.words else {
            return nil
        }
        
        let segments = Transcription.createSegments2(from: words)

        
        self.text = transcriptionResponse.text
        self.words = words
        self.segments = segments
    }
    
    init(text: String, words: [Word]?, segments: [Segment]?) {
        self.text = text
        self.words = words
        self.segments = segments
    }
   

    static func createSegments(from words: [Word], maxLength: Int = 40) -> [Segment] {
         var segments: [Segment] = []
         var currentWords: [Word] = []
         var currentText = ""

         for word in words {
             let potentialText = currentText.isEmpty ? word.text : currentText + " " + word.text

             if potentialText.count > maxLength, !currentWords.isEmpty {
                 // Close out current segment
                 let segmentText = currentText
                 let start = currentWords.first?.start ?? 0
                 let end = currentWords.last?.end ?? 0
                 let segment = Segment(text: segmentText, start: start, end: end, words: currentWords)
                 segments.append(segment)

                 // Start new segment with current word
                 currentWords = [word]
                 currentText = word.text
             } else {
                 currentWords.append(word)
                 currentText = potentialText
             }
         }

         // Append any remaining words as the last segment
         if !currentWords.isEmpty {
             let segmentText = currentText
             let start = currentWords.first?.start ?? 0
             let end = currentWords.last?.end ?? 0
             let segment = Segment(text: segmentText, start: start, end: end, words: currentWords)
             segments.append(segment)
         }

         return segments
     }
    
    
    static func createSegments2(
        from words: [Word],
        maxLength: Int = 40,
        minDuration: Double = 1.0,
        maxDuration: Double = 4.0
    ) -> [Segment] {
        
        var segments: [Segment] = []
        var currentWords: [Word] = []
        var currentText = ""
        
        for word in words {
            let potentialText = currentText.isEmpty
                ? word.text
                : currentText + " " + word.text
            
            let segmentStart = currentWords.first?.start ?? word.start
            let potentialEnd = word.end
            let potentialDuration = potentialEnd - segmentStart
            
            let exceedsLength = potentialText.count > maxLength
            let exceedsTime = potentialDuration > maxDuration
            
            if (exceedsLength || exceedsTime), !currentWords.isEmpty {
                // Close current segment
                let start = currentWords.first!.start
                var end = currentWords.last!.end
                
                // Ensure minimum duration
                if end - start < minDuration {
                    end = start + minDuration
                }
                
                segments.append(
                    Segment(
                        text: currentText,
                        start: start,
                        end: end,
                        words: currentWords
                    )
                )
                
                // Start new segment
                currentWords = [word]
                currentText = word.text
            } else {
                currentWords.append(word)
                currentText = potentialText
            }
        }
        
        // Final segment
        if !currentWords.isEmpty {
            let start = currentWords.first!.start
            var end = currentWords.last!.end
            
            if end - start < minDuration {
                end = start + minDuration
            }
            
            segments.append(
                Segment(
                    text: currentText,
                    start: start,
                    end: end,
                    words: currentWords
                )
            )
        }
        
        return segments
    }


}
