//
//  SpidAsset.swift
//  VideoSpeed
//
//  Created by oren shalev on 22/12/2024.
//

import Foundation
import AVFoundation

actor SpidAsset {
    private var asset: AVAsset
    private var rotatedAsset: AVAsset?
    private(set) var assetHasBeenRotated: Bool = false
    var timeRange: CMTimeRange
    
    init(asset: AVAsset, timeRange: CMTimeRange) {
        self.asset = asset
        self.timeRange = timeRange
    }
    
    func getOriginalAsset() -> AVAsset {
        return asset
    }
    
    func getAsset() -> AVAsset { rotatedAsset != nil ? rotatedAsset! : asset }
    
    func updateRotatedAsset(rotatedAsset: AVAsset) {
        self.rotatedAsset = rotatedAsset
        assetHasBeenRotated = true
    }
    
    func updateTimeRange(timeRange: CMTimeRange) {
        self.timeRange = timeRange
    }
}
