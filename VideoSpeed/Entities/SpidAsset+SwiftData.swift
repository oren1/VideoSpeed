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
        let videoData: Data
        let fileExtension: String
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
        let ext = (getOriginalAsset() as? AVURLAsset)?.url.pathExtension ?? ""
        return PersistableSnapshot(
            id: id,
            videoData: Data(),
            fileExtension: ext.isEmpty ? "mov" : ext,
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

    func makePersistableSnapshot(videoData: Data) -> PersistableSnapshot {
        let base = makePersistableSnapshot()
        return PersistableSnapshot(
            id: base.id,
            videoData: videoData,
            fileExtension: base.fileExtension,
            timeRangeStartValue: base.timeRangeStartValue,
            timeRangeStartTimescale: base.timeRangeStartTimescale,
            timeRangeDurationValue: base.timeRangeDurationValue,
            timeRangeDurationTimescale: base.timeRangeDurationTimescale,
            clipSourceStartValue: base.clipSourceStartValue,
            clipSourceStartTimescale: base.clipSourceStartTimescale,
            clipSourceDurationValue: base.clipSourceDurationValue,
            clipSourceDurationTimescale: base.clipSourceDurationTimescale,
            videoWidth: base.videoWidth,
            videoHeight: base.videoHeight,
            speed: base.speed,
            soundOn: base.soundOn,
            sliderValue: base.sliderValue,
            mediaKindRawValue: base.mediaKindRawValue,
            videoFilterRawValue: base.videoFilterRawValue
        )
    }

    /// Rebuilds a runtime `SpidAsset` from a persisted `SpidAssetModel`.
    static func make(from model: SpidAssetModel) async -> SpidAsset? {
        guard !model.videoData.isEmpty else {
            print("SpidAsset.make: empty videoData for \(model.id)")
            return nil
        }

        let url: URL
        do {
            url = try ProjectMediaStore.materialize(
                model.videoData,
                assetID: model.id,
                fileExtension: model.fileExtension
            )
        } catch {
            print("SpidAsset.make: failed to materialize videoData for \(model.id): \(error)")
            return nil
        }

        let avAsset = AVURLAsset(url: url)
        let timeRange = model.timeRange?.cmTimeRange ?? .zero
        let clipSourceRange = model.clipSourceRange?.cmTimeRange ?? timeRange
        let videoSize = CGSize(width: model.videoWidth, height: model.videoHeight)
        let mediaKind: MediaKind = model.mediaKindRawValue == "image" ? .image : .video
        let thumbnailTime = timeRange.start.isValid && !timeRange.start.isIndefinite ? timeRange.start : .zero

        guard let thumbnailImage = await avAsset.generateThumbnailImage(at: thumbnailTime) else {
            print("SpidAsset.make: thumbnail failed for \(url.path)")
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

    /// Copies persistable fields from `model` onto this runtime asset.
    /// Trimmer handle caches are cleared when the time range changes so UI rebuilds from the model.
    func apply(from model: SpidAssetModel) {
        let newTimeRange = model.timeRange?.cmTimeRange ?? timeRange
        let newClipSourceRange = model.clipSourceRange?.cmTimeRange ?? clipSourceRange
        if !CMTimeRangeEqual(newTimeRange, timeRange) || !CMTimeRangeEqual(newClipSourceRange, clipSourceRange) {
            clearTrimmerHandleConstants()
        }
        timeRange = newTimeRange
        clipSourceRange = newClipSourceRange
        updateVideoSize(CGSize(width: model.videoWidth, height: model.videoHeight))
        speed = model.speed
        soundOn = model.soundOn
        sliderValue = model.sliderValue
        updateMediaKind(model.mediaKindRawValue == "image" ? .image : .video)
        if let filter = VideoFilter(rawValue: model.videoFilterRawValue) {
            videoFilter = filter
        }
    }
}
