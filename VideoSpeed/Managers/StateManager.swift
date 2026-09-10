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

    var undoField: UndoField = .none

    private init() {}

    func updateSpeed(_ speed: Float, for asset: SpidAsset? = nil) async {
        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldSpeed = await spidAsset.speed
        guard oldSpeed != speed else { return }

        registerSpeedUndo(previous: oldSpeed, current: speed, asset: spidAsset)
        await spidAsset.updateSpeed(speed: speed)
    }
    
    /// Updates speed on the runtime asset and persists it to SwiftData.
//    func updateSpeed(_ speed: Float, for asset: SpidAsset? = nil) async {
//        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
//        let oldSpeed = await spidAsset.speed
//        let undoManager = UserDataManager.main.undoManager
//       
//        undoManager.registerUndo(withTarget: self) { [weak spidAsset] stateManager in
//            guard let spidAsset else { return }
//            stateManager.undoField = .speed(oldSpeed, spidAsset)
//            NotificationCenter.default.post(
//            name: .UndoManagerDidChangeField,
//                          object: nil,
//            userInfo: [UndoManagerNotification.fieldKey: UndoField.speed(oldSpeed, spidAsset)])
//           Task {
//                await spidAsset.updateSpeed(speed: oldSpeed)
//            }
//        }
//       
//        await spidAsset.updateSpeed(speed: speed)
//    }

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
    
    
    private func registerSpeedUndo(previous: Float, current: Float, asset: SpidAsset) {
        let undoManager = UserDataManager.main.undoManager
        undoManager.registerUndo(withTarget: self) { [weak asset] stateManager in
            guard let asset else { return }
            // Runs while isUndoing/isRedoing → becomes the opposite stack entry
            stateManager.registerSpeedUndo(previous: current, current: previous, asset: asset)

            stateManager.undoField = .speed(previous, asset)
            NotificationCenter.default.post(
                name: .UndoManagerDidChangeField,
                object: nil,
                userInfo: [UndoManagerNotification.fieldKey: UndoField.speed(previous, asset)]
            )
            Task { @MainActor in
                await asset.updateSpeed(speed: previous)
            }
        }
    }

}
