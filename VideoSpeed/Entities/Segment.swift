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

    static func normalizedTokens(from raw: String) -> [String] {
        raw.split { $0.isWhitespace }.filter { !$0.isEmpty }.map(String.init)
    }

    /// Rebuilds `words` and `text` after the user edits this segment’s caption string.
    /// - Same token count as before → each token keeps its original word timing (text may change).
    /// - Insertions or deletions → one `Word` per token with the segment span split evenly across them.
    func withEditedText(_ raw: String) -> Segment {
        let tokens = Self.normalizedTokens(from: raw)
        guard !tokens.isEmpty else {
            return Segment(text: "", start: start, end: end, words: [])
        }
        let newWords = Self.reconcileWords(
            originalWords: words,
            editedTokens: tokens,
            segmentStart: start,
            segmentEnd: end
        )
        let newText = newWords.map(\.text).joined(separator: " ")
        return Segment(text: newText, start: start, end: end, words: newWords)
    }

    static func reconcileWords(
        originalWords: [Word],
        editedTokens: [String],
        segmentStart: Double,
        segmentEnd: Double
    ) -> [Word] {
        guard !editedTokens.isEmpty else { return [] }

        guard !originalWords.isEmpty else {
            return wordsWithEvenTiming(tokens: editedTokens, start: segmentStart, end: segmentEnd)
        }

        if editedTokens.count == originalWords.count {
            return zip(editedTokens, originalWords).map { token, original in
                Word(text: token, start: original.start, end: original.end)
            }
        }

        return wordsWithEvenTiming(tokens: editedTokens, start: segmentStart, end: segmentEnd)
    }

    private static func wordsWithEvenTiming(tokens: [String], start: Double, end: Double) -> [Word] {
        guard !tokens.isEmpty else { return [] }
        let span = max(end - start, 1e-6)
        let slice = span / Double(tokens.count)
        return tokens.enumerated().map { index, token in
            let wordStart = start + Double(index) * slice
            let wordEnd = start + Double(index + 1) * slice
            return Word(text: token, start: wordStart, end: wordEnd)
        }
    }
    
    static func demoTranscription() -> Transcription {
        let words = [
            Word(text: "this", start: 0.0, end: 0.35),
            Word(text: "is", start: 0.35, end: 0.55),
            Word(text: "example", start: 0.55, end: 1.05),
            Word(text: "template", start: 1.05, end: 1.55)
        ]
        
        let segment = Segment(
            text: "this is example template",
            start: 0.0,
            end: 1.55,
            words: words
        )
        
        return Transcription(
            text: "this is example template",
            words: words,
            segments: [segment]
        )
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

    /// Replaces one segment (by index) and rebuilds flat `words` plus top-level `text`.
    func replacingSegment(at index: Int, editedText: String) -> Transcription? {
        guard let segments, index >= 0, index < segments.count else { return nil }
        var newSegments = Array(segments)
        newSegments[index] = segments[index].withEditedText(editedText)
        let flatWords = newSegments.flatMap(\.words)
        let fullText = newSegments.map(\.text).joined(separator: " ")
        return Transcription(text: fullText, words: flatWords, segments: newSegments)
    }
}
