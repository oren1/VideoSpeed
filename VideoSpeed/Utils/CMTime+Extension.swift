//
//  CMTime+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/06/2025.
//

import Foundation
import CoreMedia

extension CMTime {
    func converted(toScale newScale: CMTimeScale) -> CMTime {
        return CMTimeConvertScale(self, timescale: newScale, method: .default)
    }

    func dividedBySpeed(_ speed: Float, timescale: CMTimeScale) -> CMTime {
        guard speed > 0 else { return converted(toScale: timescale) }
        return CMTimeMultiplyByFloat64(self, multiplier: 1.0 / Double(speed))
            .converted(toScale: timescale)
    }
}
