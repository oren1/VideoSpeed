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
}
