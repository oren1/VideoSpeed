import Foundation
import AVFoundation

extension UserDataManager {

    @MainActor
    func splitCurrentAsset(at splitTime: CMTime) async -> Bool {
        guard let asset = currentSpidAsset,
              let index = spidAssets.firstIndex(where: { $0 === asset }) else {
            return false
        }

        let range = await asset.timeRange
        let timescale = range.start.timescale
        let minDuration = CMTime(seconds: 1.0, preferredTimescale: timescale)
        let earliestSplit = CMTimeAdd(range.start, minDuration)
        let latestSplit = CMTimeSubtract(range.end, minDuration)

        guard CMTimeCompare(splitTime, earliestSplit) >= 0,
              CMTimeCompare(splitTime, latestSplit) <= 0 else {
            return false
        }

        let leftRange = CMTimeRange(start: range.start, end: splitTime)
        let rightRange = CMTimeRange(start: splitTime, end: range.end)

        let mediaAsset = await asset.getAsset()
        let leftThumbnail = await mediaAsset.generateThumbnailImage(at: leftRange.start)
        let rightThumbnail = await mediaAsset.generateThumbnailImage(at: rightRange.start)

        let isImage = await asset.isImageClip
        let preservedClipSourceRange = await asset.clipSourceRange

        await asset.updateTimeRange(timeRange: leftRange)
        if !isImage {
            await asset.updateClipSourceRange(leftRange)
        }
        await asset.clearTrimmerHandleConstants()
        if isImage {
            // 1-frame source: keep existing thumbnail
        } else if let leftThumbnail {
            await asset.updateThumbnailImage(leftThumbnail)
        }

        let fallbackThumbnail = await asset.thumbnailImage
        let rightClipSourceRange = isImage ? preservedClipSourceRange : rightRange
        let rightAsset = await asset.duplicate(
            with: rightRange,
            thumbnailImage: (isImage ? fallbackThumbnail : rightThumbnail) ?? fallbackThumbnail,
            clipSourceRange: rightClipSourceRange
        )
        spidAssets.insert(rightAsset, at: index + 1)
        currentSpidAsset = rightAsset
        splitCount += 1
        return true
    }
}
