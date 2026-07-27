//
//  AudioExtractor.swift
//  VideoSpeed
//

import AVFoundation
import Foundation

enum AudioExtractorError: LocalizedError {
    case noAudioTrack
    case exportSessionCreationFailed
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "This video has no audio track."
        case .exportSessionCreationFailed:
            return "Could not prepare audio extraction."
        case .exportFailed(let message):
            return message
        }
    }
}

enum AudioExtractor {
    static func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw AudioExtractorError.noAudioTrack
        }

        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw AudioExtractorError.exportSessionCreationFailed
        }

        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        try compositionTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("extracted-audio-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw AudioExtractorError.exportSessionCreationFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed:
            throw AudioExtractorError.exportFailed(exportSession.error?.localizedDescription ?? "Export failed.")
        case .cancelled:
            throw AudioExtractorError.exportFailed("Export was cancelled.")
        default:
            throw AudioExtractorError.exportFailed("Export did not complete.")
        }
    }
}
