//
//  SpidAssetModel.swift
//  VideoSpeed
//

import Foundation
import SwiftData

/// SwiftData counterpart of runtime `SpidAsset`. Holds persistable fields only;
/// AVFoundation objects stay on the actor and are rebuilt from `assetURLString` when needed.
@Model
final class SpidAssetModel {
    @Attribute(.unique) var id: UUID
    /// Underlying video file URL (`AVURLAsset.url.absoluteString`). Empty when the asset has no file URL.
    var assetURLString: String
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

    init(
        id: UUID,
        assetURLString: String,
        timeRange: StoredCMTimeRange,
        clipSourceRange: StoredCMTimeRange,
        videoWidth: Double,
        videoHeight: Double,
        speed: Float = 1,
        soundOn: Bool = true,
        sliderValue: Float = 19.5,
        mediaKindRawValue: String = "video",
        videoFilterRawValue: String = VideoFilter.none.rawValue,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.assetURLString = assetURLString
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
    }
}
