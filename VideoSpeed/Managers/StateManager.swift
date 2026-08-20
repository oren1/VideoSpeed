//
//  StateManager.swift
//  VideoSpeed
//

import Foundation
import AVFoundation

/// Single entry point for edit-state mutations that must stay in sync between
/// the in-memory `SpidAsset` and its SwiftData `SpidAssetModel`.
@MainActor
final class StateManager {
    static let shared = StateManager()

    private init() {}

    /// Updates speed on the runtime asset and persists it to SwiftData.
    func updateSpeed(_ speed: Float, for asset: SpidAsset? = nil) async {
        guard let target = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let speedSliderValue = SpidAsset.convertSpeedToSliderValue(speed: speed)
        await target.updateSpeed(speed: speed)
        let assetId = await target.id
        SwiftDataManager.shared.updateSpeed(speed, forAssetID: assetId)
    }

    /// Updates time range on the runtime asset and persists it to SwiftData.
    func updateTimeRange(_ timeRange: CMTimeRange, for asset: SpidAsset? = nil) async {
        guard let target = asset ?? UserDataManager.main.currentSpidAsset else { return }
        await target.updateTimeRange(timeRange: timeRange)
        let assetId = await target.id
        SwiftDataManager.shared.updateTimeRange(timeRange, forAssetID: assetId)
    }
}
