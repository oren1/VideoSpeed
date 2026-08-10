//
//  SpidAssetModel.swift
//  VideoSpeed
//

import Foundation
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
    @Relationship(deleteRule: .cascade)
    var timeRange: StoredCMTimeRange?
    @Relationship(deleteRule: .cascade)
    var clipSourceRange: StoredCMTimeRange?
    var videoWidth: Double
    var videoHeight: Double
    var speed: Float
    var soundOn: Bool
    var sliderValue: Float
    var mediaKindRawValue: String
    var videoFilterRawValue: String
    var sortIndex: Int
    var project: VideoProject?

    init(
        id: UUID,
        videoData: Data,
        fileExtension: String,
        timeRange: StoredCMTimeRange,
        clipSourceRange: StoredCMTimeRange,
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
        self.timeRange = timeRange
        self.clipSourceRange = clipSourceRange
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
