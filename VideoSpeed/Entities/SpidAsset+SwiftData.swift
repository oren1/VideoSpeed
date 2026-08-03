//
//  SpidAsset+SwiftData.swift
//  VideoSpeed
//

import Foundation
import AVFoundation

extension SpidAsset {
    /// Snapshot of persistable fields for syncing into `SpidAssetModel`.
    struct PersistableSnapshot: Sendable {
        let id: UUID
        let assetURLString: String
        let timeRangeStartValue: Int64
        let timeRangeStartTimescale: Int32
        let timeRangeDurationValue: Int64
        let timeRangeDurationTimescale: Int32
        let clipSourceStartValue: Int64
        let clipSourceStartTimescale: Int32
        let clipSourceDurationValue: Int64
        let clipSourceDurationTimescale: Int32
        let videoWidth: Double
        let videoHeight: Double
        let speed: Float
        let soundOn: Bool
        let sliderValue: Float
        let mediaKindRawValue: String
        let videoFilterRawValue: String
    }

    func makePersistableSnapshot() -> PersistableSnapshot {
        let urlString = (getOriginalAsset() as? AVURLAsset)?.url.absoluteString ?? ""
        return PersistableSnapshot(
            id: id,
            assetURLString: urlString,
            timeRangeStartValue: timeRange.start.value,
            timeRangeStartTimescale: timeRange.start.timescale,
            timeRangeDurationValue: timeRange.duration.value,
            timeRangeDurationTimescale: timeRange.duration.timescale,
            clipSourceStartValue: clipSourceRange.start.value,
            clipSourceStartTimescale: clipSourceRange.start.timescale,
            clipSourceDurationValue: clipSourceRange.duration.value,
            clipSourceDurationTimescale: clipSourceRange.duration.timescale,
            videoWidth: videoSize.width,
            videoHeight: videoSize.height,
            speed: speed,
            soundOn: soundOn,
            sliderValue: sliderValue,
            mediaKindRawValue: mediaKind == .image ? "image" : "video",
            videoFilterRawValue: videoFilter.rawValue
        )
    }

    /// Rebuilds a runtime `SpidAsset` from a persisted `SpidAssetModel`.
    static func make(from model: SpidAssetModel) async -> SpidAsset? {
        guard !model.assetURLString.isEmpty,
              let url = URL(string: model.assetURLString) else {
            return nil
        }

        let avAsset = AVURLAsset(url: url)
        let timeRange = model.timeRange?.cmTimeRange ?? .zero
        let clipSourceRange = model.clipSourceRange?.cmTimeRange ?? timeRange
        let videoSize = CGSize(width: model.videoWidth, height: model.videoHeight)
        let mediaKind: MediaKind = model.mediaKindRawValue == "image" ? .image : .video

        guard let thumbnailImage = await avAsset.generateThumbnailImage(at: timeRange.start) else {
            return nil
        }

        let spidAsset = SpidAsset(
            asset: avAsset,
            timeRange: timeRange,
            videoSize: videoSize,
            thumnbnailImage: thumbnailImage,
            mediaKind: mediaKind,
            clipSourceRange: clipSourceRange,
            id: model.id
        )
        await spidAsset.updateSpeed(speed: model.speed)
        await spidAsset.updateSound(soundOn: model.soundOn)
        await spidAsset.updateSliderValue(value: model.sliderValue)
        if let filter = VideoFilter(rawValue: model.videoFilterRawValue) {
            await spidAsset.updateVideoFilter(filter)
        }
        return spidAsset
    }
}
