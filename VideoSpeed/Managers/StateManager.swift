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
//        let oldSpeed = await target.speed
//        let undoManager = UserDataManager.main.undoManager
//        undoManager.registerUndo(withTarget: target) { spidAsset in
//           Task {
//                await spidAsset.updateSpeed(speed: oldSpeed)
//                NotificationCenter.default.post(
//                name: .UndoManagerDidChangeField,
//                              object: nil,
//                userInfo: [UndoManagerNotification.fieldKey: UndoField.speed(oldSpeed, target)])
//               
//            }
//        }
        await target.updateSpeed(speed: speed)
    }

    /// Updates time range on the runtime asset and persists it to SwiftData.
    func updateTimeRange(_ timeRange: CMTimeRange, for asset: SpidAsset? = nil) async {
        guard let target = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldTimeRange = await target.timeRange
        let undoManager = UserDataManager.main.undoManager
      
        undoManager.registerUndo(withTarget: target) { spidAsset in
            Task {
                await spidAsset.updateTimeRange(timeRange: oldTimeRange)
                NotificationCenter.default.post(
                 name: .UndoManagerDidChangeField,
                               object: nil,
                 userInfo: [UndoManagerNotification.fieldKey: UndoField.timeRange(oldTimeRange, target)])
            }
        }
    

        await target.updateTimeRange(timeRange: timeRange)
       
    }
}
