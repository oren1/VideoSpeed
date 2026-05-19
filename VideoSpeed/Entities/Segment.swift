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
    /// - Matching token → same timing, updated text.
    /// - Replacement → edited token keeps that word’s timing.
    /// - Insertion(s) before a word → coupled with the **next** original word (one `Word`, next word’s timing).
    /// - Deletion → original word dropped.
    /// - Trailing insertions → coupled into the previous word slot.
    func withEditedText(_ raw: String) -> Segment {
        let tokens = Self.normalizedTokens(from: raw)
        guard !tokens.isEmpty else {
            return Segment(text: "", start: start, end: end, words: [])
        }
        let newWords = Self.reconcileWords(originalWords: words, editedTokens: tokens)
        let newText = newWords.map(\.text).joined(separator: " ")
        return Segment(text: newText, start: start, end: end, words: newWords)
    }

    static func reconcileWords(originalWords: [Word], editedTokens: [String]) -> [Word] {
        guard !originalWords.isEmpty else {
            return editedTokens.enumerated().map { index, token in
                let t = Double(index)
                return Word(text: token, start: t, end: t + 1)
            }
        }

        var result: [Word] = []
        var o = 0
        var e = 0

        while e < editedTokens.count {
            if o >= originalWords.count {
                appendTrailingInsertion(editedTokens[e], to: &result, fallback: originalWords.last!)
                e += 1
                continue
            }

            let orig = originalWords[o]
            let token = editedTokens[e]

            if token.fuzzyMatches(orig.text) {
                result.append(Word(text: token, start: orig.start, end: orig.end))
                o += 1
                e += 1
                continue
            }

            if e + 1 < editedTokens.count, editedTokens[e + 1].fuzzyMatches(orig.text) {
                let coupled = [token, orig.text].joined(separator: " ")
                result.append(Word(text: coupled, start: orig.start, end: orig.end))
                o += 1
                e += 2
                continue
            }

            if let insertionRunEnd = endOfInsertionRun(
                editedTokens: editedTokens,
                startEditIndex: e,
                originalWords: originalWords,
                originalIndex: o
            ) {
                let run = Array(editedTokens[e..<insertionRunEnd])
                let coupled = (run + [orig.text]).joined(separator: " ")
                result.append(Word(text: coupled, start: orig.start, end: orig.end))
                o += 1
                e = insertionRunEnd + 1
                continue
            }

            if o + 1 < originalWords.count, token.fuzzyMatches(originalWords[o + 1].text) {
                o += 1
                continue
            }

            result.append(Word(text: token, start: orig.start, end: orig.end))
            o += 1
            e += 1
        }

        return result
    }

    private static func endOfInsertionRun(
        editedTokens: [String],
        startEditIndex: Int,
        originalWords: [Word],
        originalIndex: Int
    ) -> Int? {
        guard originalIndex < originalWords.count else { return nil }
        let anchor = originalWords[originalIndex].text

        var index = startEditIndex
        while index < editedTokens.count {
            if editedTokens[index].fuzzyMatches(anchor) {
                return index > startEditIndex ? index : nil
            }
            if index + 1 < editedTokens.count, editedTokens[index + 1].fuzzyMatches(anchor) {
                return nil
            }
            index += 1
        }
        return nil
    }

    private static func appendTrailingInsertion(_ token: String, to result: inout [Word], fallback: Word) {
        if let last = result.last {
            result[result.count - 1] = Word(
                text: [last.text, token].joined(separator: " "),
                start: last.start,
                end: last.end
            )
        } else {
            result.append(Word(text: token, start: fallback.start, end: fallback.end))
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

private extension String {
    func fuzzyMatches(_ other: String) -> Bool {
        caseInsensitiveCompare(other) == .orderedSame
    }
}
