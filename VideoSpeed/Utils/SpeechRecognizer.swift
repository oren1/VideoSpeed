//
//  SpeechRecognizer.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 17/08/2025.
//

import Foundation
import Speech

import Speech

class Sentence {
    let segments: [SFTranscriptionSegment]
    
    init(segments: [SFTranscriptionSegment]) {
        self.segments = segments
    }
    
    /// The concatenated text of all segments in this sentence
    var text: String {
        segments.map { $0.substring }.joined(separator: " ")
    }
    
    /// Start time of the first segment
    var startTime: TimeInterval {
        segments.first?.timestamp ?? 0
    }
    
    /// End time of the last segment
    var endTime: TimeInterval {
        guard let last = segments.last else { return 0 }
        return last.timestamp + last.duration
    }
}


enum SpeechRecognizerError: LocalizedError {
    case speechRecognizerNotAvailable

    var errorDescription: String? {
        switch self {
            case .speechRecognizerNotAvailable:
            return "Speech recognizer is not available."
        }
    }
}

enum AudioExportError: Error {
    case noAudioTrack
    case cannotCreateExportSession
    case exportFailed
    case unknown
}

public class SpeechRecognizer {
    
    static func getSpeechRecognitionPermissionsStatus() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                continuation.resume(returning: authStatus)
            }
        }
    }

    static func transcribeAudio(url: URL) async throws -> [SFTranscriptionSegment] {
        // create a new recognizer and point it at our audio
        guard let recognizer = SFSpeechRecognizer() else {
            throw SpeechRecognizerError.speechRecognizerNotAvailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        return try await withCheckedThrowingContinuation { continuation in
            // start recognition
            recognizer.recognitionTask(with: request) { (result, error) in
                // abort if we didn't get any transcription back
                guard let result = result else {
                  return continuation.resume(throwing: error!)
                }

                // if we got the final transcription back, print it
                if result.isFinal {
                    // pull out the best transcription...
                    print("result.bestTranscription.formattedString \(result.bestTranscription.formattedString)")
                    continuation.resume(returning: result.bestTranscription.segments)
                }
            }
        }

    }
    
    static func exportAudio(from asset: AVAsset, to outputURL: URL) async throws -> URL {
        // Ensure asset has audio track
        guard asset.tracks(withMediaType: .audio).count > 0 else {
            throw AudioExportError.noAudioTrack
        }

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset,
                                                       presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioExportError.cannotCreateExportSession
        }

        // Set output
        try? FileManager.default.removeItem(at: outputURL)
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
          print("completed export with url: \(outputURL)")
            return outputURL
        default:
            throw AudioExportError.exportFailed
        }
    }
    
    /// Groups transcription segments into sentences by detecting pauses.
    /// - Parameters:
    ///   - segments: Array of SFTranscriptionSegment (from `bestTranscription.segments`)
    ///   - pauseThreshold: Seconds of silence to treat as a sentence boundary
    /// - Returns: Array of sentences, each sentence is an array of SFTranscriptionSegment
    static func groupSegmentsIntoSentences(
        segments: [SFTranscriptionSegment],
        pauseThreshold: TimeInterval = 0.6
    ) -> [Sentence] {
        
        var sentences: [Sentence] = []
        var currentSentence: [SFTranscriptionSegment] = []
        
        for (i, segment) in segments.enumerated() {
            currentSentence.append(segment)
            
            // If this isn't the last segment, check the gap
            if i < segments.count - 1 {
                let thisEnd = segment.timestamp + segment.duration
                let nextStart = segments[i + 1].timestamp
                let gap = nextStart - thisEnd
                
                if gap >= pauseThreshold {
                    // End of sentence
                    sentences.append(Sentence(segments: currentSentence))
                    currentSentence = []
                }
            }
        }
        
        // Add the last sentence if any
        if !currentSentence.isEmpty {
            sentences.append(Sentence(segments: currentSentence))
        }
        
        return sentences
    }

}

