//
//  SDBackgroundAudio.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import AVFoundation

/// SwiftData counterpart of `BackgroundAudioTrackItem` (optional 1:1 on `VideoProject`).
@Model
final class SDBackgroundAudio {
    @Attribute(.unique) var id: UUID
    var project: VideoProject?

    var sourceId: String
    var sourceRawValue: String
    var displayName: String
    /// Raw audio bytes (empty for `.bundled` — resolved from the app bundle on load).
    @Attribute(.externalStorage) var audioData: Data
    var fileExtension: String

    var fullSourceStartValue: Int64
    var fullSourceStartTimescale: Int32
    var fullSourceDurationValue: Int64
    var fullSourceDurationTimescale: Int32

    var sourceStartValue: Int64
    var sourceStartTimescale: Int32
    var sourceDurationValue: Int64
    var sourceDurationTimescale: Int32

    var timelineStartValue: Int64
    var timelineStartTimescale: Int32
    var timelineDurationValue: Int64
    var timelineDurationTimescale: Int32

    var volume: Float

    var source: BackgroundAudioSource {
        BackgroundAudioSource(rawValue: sourceRawValue) ?? .recorded
    }

    var fullSourceRange: CMTimeRange {
        get {
            CMTimeRange(
                start: CMTime(value: fullSourceStartValue, timescale: fullSourceStartTimescale),
                duration: CMTime(value: fullSourceDurationValue, timescale: fullSourceDurationTimescale)
            )
        }
        set {
            fullSourceStartValue = newValue.start.value
            fullSourceStartTimescale = newValue.start.timescale
            fullSourceDurationValue = newValue.duration.value
            fullSourceDurationTimescale = newValue.duration.timescale
        }
    }

    var sourceTimeRange: CMTimeRange {
        get {
            CMTimeRange(
                start: CMTime(value: sourceStartValue, timescale: sourceStartTimescale),
                duration: CMTime(value: sourceDurationValue, timescale: sourceDurationTimescale)
            )
        }
        set {
            sourceStartValue = newValue.start.value
            sourceStartTimescale = newValue.start.timescale
            sourceDurationValue = newValue.duration.value
            sourceDurationTimescale = newValue.duration.timescale
        }
    }

    var timelineTimeRange: CMTimeRange {
        get {
            CMTimeRange(
                start: CMTime(value: timelineStartValue, timescale: timelineStartTimescale),
                duration: CMTime(value: timelineDurationValue, timescale: timelineDurationTimescale)
            )
        }
        set {
            timelineStartValue = newValue.start.value
            timelineStartTimescale = newValue.start.timescale
            timelineDurationValue = newValue.duration.value
            timelineDurationTimescale = newValue.duration.timescale
        }
    }

    init(
        id: UUID = UUID(),
        project: VideoProject? = nil,
        sourceId: String,
        sourceRawValue: String,
        displayName: String,
        audioData: Data,
        fileExtension: String,
        fullSourceRange: CMTimeRange,
        sourceTimeRange: CMTimeRange,
        timelineTimeRange: CMTimeRange,
        volume: Float
    ) {
        self.id = id
        self.project = project
        self.sourceId = sourceId
        self.sourceRawValue = sourceRawValue
        self.displayName = displayName
        self.audioData = audioData
        self.fileExtension = fileExtension
        self.fullSourceStartValue = fullSourceRange.start.value
        self.fullSourceStartTimescale = fullSourceRange.start.timescale
        self.fullSourceDurationValue = fullSourceRange.duration.value
        self.fullSourceDurationTimescale = fullSourceRange.duration.timescale
        self.sourceStartValue = sourceTimeRange.start.value
        self.sourceStartTimescale = sourceTimeRange.start.timescale
        self.sourceDurationValue = sourceTimeRange.duration.value
        self.sourceDurationTimescale = sourceTimeRange.duration.timescale
        self.timelineStartValue = timelineTimeRange.start.value
        self.timelineStartTimescale = timelineTimeRange.start.timescale
        self.timelineDurationValue = timelineTimeRange.duration.value
        self.timelineDurationTimescale = timelineTimeRange.duration.timescale
        self.volume = volume
    }

    static func make(
        from track: BackgroundAudioTrackItem,
        audioData: Data,
        project: VideoProject?
    ) -> SDBackgroundAudio {
        SDBackgroundAudio(
            project: project,
            sourceId: track.sourceId,
            sourceRawValue: track.source.rawValue,
            displayName: track.displayName,
            audioData: audioData,
            fileExtension: track.fileURL.pathExtension,
            fullSourceRange: track.fullSourceRange,
            sourceTimeRange: track.sourceTimeRange,
            timelineTimeRange: track.timelineTimeRange,
            volume: track.volume
        )
    }

    func update(from track: BackgroundAudioTrackItem, audioData: Data) {
        sourceId = track.sourceId
        sourceRawValue = track.source.rawValue
        displayName = track.displayName
        self.audioData = audioData
        fileExtension = track.fileURL.pathExtension
        fullSourceRange = track.fullSourceRange
        sourceTimeRange = track.sourceTimeRange
        timelineTimeRange = track.timelineTimeRange
        volume = track.volume
    }

    /// Builds a runtime track. Caller supplies a playable `fileURL` (bundle or materialized cache).
    func makeTrack(fileURL: URL) -> BackgroundAudioTrackItem {
        BackgroundAudioTrackItem(
            sourceId: sourceId,
            source: source,
            displayName: displayName,
            fileURL: fileURL,
            fullSourceRange: fullSourceRange,
            sourceTimeRange: sourceTimeRange,
            timelineTimeRange: timelineTimeRange,
            volume: volume
        )
    }

    static func copy(from model: SDBackgroundAudio, project: VideoProject?) -> SDBackgroundAudio {
        SDBackgroundAudio(
            project: project,
            sourceId: model.sourceId,
            sourceRawValue: model.sourceRawValue,
            displayName: model.displayName,
            audioData: model.audioData,
            fileExtension: model.fileExtension,
            fullSourceRange: model.fullSourceRange,
            sourceTimeRange: model.sourceTimeRange,
            timelineTimeRange: model.timelineTimeRange,
            volume: model.volume
        )
    }
}
