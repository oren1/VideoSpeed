//
//  SpeechRecognizer.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 17/08/2025.
//

import Foundation
import Speech

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
}

