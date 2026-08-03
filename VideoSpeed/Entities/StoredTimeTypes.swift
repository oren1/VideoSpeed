//
//  StoredTimeTypes.swift
//  VideoSpeed
//

import Foundation
import AVFoundation
import SwiftData

/// Persistable mapping of `CMTime` (value + timescale).
@Model
final class StoredCMTime {
    var value: Int64
    var timescale: Int32

    init(value: Int64 = 0, timescale: Int32 = 600) {
        self.value = value
        self.timescale = timescale
    }

    init(_ time: CMTime) {
        self.value = time.value
        self.timescale = time.timescale
    }

    var cmTime: CMTime {
        CMTime(value: value, timescale: timescale)
    }

    func update(from time: CMTime) {
        value = time.value
        timescale = time.timescale
    }
}

/// Persistable mapping of `CMTimeRange` (start + duration).
@Model
final class StoredCMTimeRange {
    @Relationship(deleteRule: .cascade)
    var start: StoredCMTime?

    @Relationship(deleteRule: .cascade)
    var duration: StoredCMTime?

    init(start: StoredCMTime, duration: StoredCMTime) {
        self.start = start
        self.duration = duration
    }

    convenience init(_ range: CMTimeRange) {
        self.init(start: StoredCMTime(range.start), duration: StoredCMTime(range.duration))
    }

    var cmTimeRange: CMTimeRange {
        CMTimeRange(
            start: start?.cmTime ?? .zero,
            duration: duration?.cmTime ?? .zero
        )
    }

    func update(from range: CMTimeRange) {
        if let start {
            start.update(from: range.start)
        } else {
            start = StoredCMTime(range.start)
        }
        if let duration {
            duration.update(from: range.duration)
        } else {
            duration = StoredCMTime(range.duration)
        }
    }
}
