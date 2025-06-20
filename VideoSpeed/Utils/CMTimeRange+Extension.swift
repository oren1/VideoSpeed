//
//  CMTimeRange+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/06/2025.
//

import Foundation
import CoreMedia

extension CMTimeRange {
    func convertTimeRange(toScale newScale: CMTimeScale) -> CMTimeRange {
        let convertedStart = CMTimeConvertScale(self.start, timescale: newScale, method: .default)
        let convertedDuration = CMTimeConvertScale(self.duration, timescale: newScale, method: .default)
        return CMTimeRange(start: convertedStart, duration: convertedDuration)
    }
}
