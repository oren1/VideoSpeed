//
//  StoredTimeTypes.swift
//  VideoSpeed
//

import Foundation
import AVFoundation
import SwiftData

/// Persistable mapping of `CMTimeRange` (start + duration as plain attributes).
@Model
final class StoredCMTimeRange {
    var startValue: Int64
    var startTimescale: Int32
    var durationValue: Int64
    var durationTimescale: Int32

    var timeRangeOwner: SpidAssetModel?
    var clipSourceRangeOwner: SpidAssetModel?

    init(
        startValue: Int64 = 0,
        startTimescale: Int32 = 600,
        durationValue: Int64 = 0,
        durationTimescale: Int32 = 600
    ) {
        self.startValue = startValue
        self.startTimescale = startTimescale
        self.durationValue = durationValue
        self.durationTimescale = durationTimescale
    }

    convenience init(_ range: CMTimeRange) {
        self.init(
            startValue: range.start.value,
            startTimescale: range.start.timescale,
            durationValue: range.duration.value,
            durationTimescale: range.duration.timescale
        )
    }

    var cmTimeRange: CMTimeRange {
        CMTimeRange(
            start: CMTime(value: startValue, timescale: startTimescale),
            duration: CMTime(value: durationValue, timescale: durationTimescale)
        )
    }

    func update(from range: CMTimeRange) {
        startValue = range.start.value
        startTimescale = range.start.timescale
        durationValue = range.duration.value
        durationTimescale = range.duration.timescale
    }
}
