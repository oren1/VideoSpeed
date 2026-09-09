//
//  SpidAssetModel.swift
//  VideoSpeed
//

import Foundation
import AVFoundation
import SwiftData

/// SwiftData counterpart of runtime `SpidAsset`. Holds persistable fields only;
/// AVFoundation objects stay on the actor and are rebuilt from `videoData` when needed.
@Model
final class SpidAssetModel {
    @Attribute(.unique) var id: UUID
    /// Raw bytes of the underlying video, stored on disk via SwiftData external storage.
    @Attribute(.externalStorage) var videoData: Data
    /// File extension of the original video (e.g. `mov`, `mp4`), used when materializing for playback.
    var fileExtension: String

    var timeRangeStartValue: Int64
    var timeRangeStartTimescale: Int32
    var timeRangeDurationValue: Int64
    var timeRangeDurationTimescale: Int32

    var clipSourceStartValue: Int64
    var clipSourceStartTimescale: Int32
    var clipSourceDurationValue: Int64
    var clipSourceDurationTimescale: Int32

    var videoWidth: Double
    var videoHeight: Double
    var speed: Float
    var soundOn: Bool
    var sliderValue: Float
    var mediaKindRawValue: String
    var videoFilterRawValue: String
    var sortIndex: Int
    var project: VideoProject?

    var timeRange: CMTimeRange {
        get {
            CMTimeRange(
                start: CMTime(value: timeRangeStartValue, timescale: timeRangeStartTimescale),
                duration: CMTime(value: timeRangeDurationValue, timescale: timeRangeDurationTimescale)
            )
        }
        set {
            timeRangeStartValue = newValue.start.value
            timeRangeStartTimescale = newValue.start.timescale
            timeRangeDurationValue = newValue.duration.value
            timeRangeDurationTimescale = newValue.duration.timescale
        }
    }

    var clipSourceRange: CMTimeRange {
        get {
            CMTimeRange(
                start: CMTime(value: clipSourceStartValue, timescale: clipSourceStartTimescale),
                duration: CMTime(value: clipSourceDurationValue, timescale: clipSourceDurationTimescale)
            )
        }
        set {
            clipSourceStartValue = newValue.start.value
            clipSourceStartTimescale = newValue.start.timescale
            clipSourceDurationValue = newValue.duration.value
            clipSourceDurationTimescale = newValue.duration.timescale
        }
    }

    init(
        id: UUID,
        videoData: Data,
        fileExtension: String,
        timeRange: CMTimeRange,
        clipSourceRange: CMTimeRange,
        videoWidth: Double,
        videoHeight: Double,
        speed: Float = 1,
        soundOn: Bool = true,
        sliderValue: Float = 19.5,
        mediaKindRawValue: String = "video",
        videoFilterRawValue: String = VideoFilter.none.rawValue,
        sortIndex: Int = 0,
        project: VideoProject? = nil
    ) {
        self.id = id
        self.videoData = videoData
        self.fileExtension = fileExtension
        self.timeRangeStartValue = timeRange.start.value
        self.timeRangeStartTimescale = timeRange.start.timescale
        self.timeRangeDurationValue = timeRange.duration.value
        self.timeRangeDurationTimescale = timeRange.duration.timescale
        self.clipSourceStartValue = clipSourceRange.start.value
        self.clipSourceStartTimescale = clipSourceRange.start.timescale
        self.clipSourceDurationValue = clipSourceRange.duration.value
        self.clipSourceDurationTimescale = clipSourceRange.duration.timescale
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.speed = speed
        self.soundOn = soundOn
        self.sliderValue = sliderValue
        self.mediaKindRawValue = mediaKindRawValue
        self.videoFilterRawValue = videoFilterRawValue
        self.sortIndex = sortIndex
        self.project = project
    }
}
