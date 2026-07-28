//
//  BackgroundAudioTrackItem.swift
//  VideoSpeed
//

import Foundation
import CoreMedia

struct BackgroundAudioTrackItem {
    let sourceId: String
    let source: BackgroundAudioSource
    let displayName: String
    let fileURL: URL
    let fullSourceRange: CMTimeRange
    var sourceTimeRange: CMTimeRange
    var timelineTimeRange: CMTimeRange
    /// Gain for background audio in the composition (`0` = mute, `1` = full).
    var volume: Float = 1.0

    mutating func updateSourceTimeRange(_ newRange: CMTimeRange) {
        sourceTimeRange = newRange
        timelineTimeRange = CMTimeRange(start: timelineTimeRange.start, duration: newRange.duration)
    }

    mutating func updateVolume(_ volume: Float) {
        self.volume = min(max(volume, 0), 1)
    }

    mutating func updateTimelineStart(_ newStart: CMTime) {
        timelineTimeRange = CMTimeRange(start: newStart, duration: sourceTimeRange.duration)
    }

    mutating func updateTimelineTimeRange(_ newRange: CMTimeRange) {
        timelineTimeRange = newRange
        sourceTimeRange = CMTimeRange(start: sourceTimeRange.start, duration: newRange.duration)
    }

    /// Keeps timeline and source durations equal and within the composition bounds.
    mutating func clampToCompositionDuration(_ compositionDuration: CMTime) {
        guard compositionDuration.isValid, CMTimeCompare(compositionDuration, .zero) > 0 else {
            timelineTimeRange = CMTimeRange(start: .zero, duration: .zero)
            sourceTimeRange = CMTimeRange(start: sourceTimeRange.start, duration: .zero)
            return
        }

        var timelineStart = timelineTimeRange.start
        if CMTimeCompare(timelineStart, compositionDuration) >= 0 {
            timelineStart = .zero
        }

        let remainingOnTimeline = CMTimeSubtract(compositionDuration, timelineStart)
        var duration = CMTimeMinimum(timelineTimeRange.duration, remainingOnTimeline)

        let maxSourceRemaining = CMTimeSubtract(CMTimeRangeGetEnd(fullSourceRange), sourceTimeRange.start)
        duration = CMTimeMinimum(duration, maxSourceRemaining)

        if CMTimeCompare(duration, .zero) < 0 {
            duration = .zero
        }

        timelineTimeRange = CMTimeRange(start: timelineStart, duration: duration)
        sourceTimeRange = CMTimeRange(start: sourceTimeRange.start, duration: duration)
    }
}
