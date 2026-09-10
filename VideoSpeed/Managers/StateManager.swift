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

    /// Updates speed on the runtime asset and persists it to SwiftData.
    func updateSpeed(_ speed: Float, for asset: SpidAsset? = nil) async {
        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldSpeed = await spidAsset.speed
        guard oldSpeed != speed else { return }

        registerUndo(
            previous: .speed(oldSpeed, spidAsset),
            current: .speed(speed, spidAsset)
        )
        await spidAsset.updateSpeed(speed: speed)
    }

    /// Updates time range on the runtime asset and persists it to SwiftData.
    func updateTimeRange(_ timeRange: CMTimeRange, for asset: SpidAsset? = nil) async {
        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldTimeRange = await spidAsset.timeRange
        guard oldTimeRange != timeRange else { return }

        registerUndo(
            previous: .timeRange(oldTimeRange, spidAsset),
            current: .timeRange(timeRange, spidAsset)
        )
        await spidAsset.updateTimeRange(timeRange: timeRange)
    }

    /// Registers undo that restores `previous`. While undoing/redoing, re-registers
    /// with `previous`/`current` swapped so the opposite stack entry is created.
    private func registerUndo(previous: UndoField, current: UndoField) {
        let undoManager = UserDataManager.main.undoManager
        // Registers an undo operation
        undoManager.registerUndo(withTarget: self) { stateManager in
            // setting the undoField to the previous
            stateManager.undoField = previous
            // Register a reverse undo operation. While inside an undo operation, adding another operation
            // adds it to the opposite stack and allows to redo
            stateManager.registerUndo(previous: current, current: previous)
            stateManager.notifyUndoFieldChanged(field: previous)
           
            Task { @MainActor in
                await stateManager.apply(previous)
            }
        }
    }

    func notifyUndoFieldChanged(field: UndoField)  {
        NotificationCenter.default.post(
            name: .UndoManagerDidChangeField,
            object: nil,
            userInfo: [UndoManagerNotification.fieldKey: field]
        )
    }
    
    private func apply(_ field: UndoField) async {
        switch field {
        case .none, .other:
            break
        case .speed(let speed, let asset):
            await asset.updateSpeed(speed: speed)
        case .soundOn(let soundOn, let asset):
            await asset.updateSound(soundOn: soundOn)
        case .sliderValue(let value, let asset):
            await asset.updateSliderValue(value: value)
        case .videoFilter(let filterName, let asset):
            guard let filter = VideoFilter(rawValue: filterName) else { return }
            await asset.updateVideoFilter(filter)
        case .timeRange(let timeRange, let asset):
            await asset.updateTimeRange(timeRange: timeRange)
        case .clipSourceRange(let range, let asset):
            await asset.updateClipSourceRange(range)
        case .videoSize(let size, let asset):
            await asset.updateVideoSize(size)
        case .mediaKind(let kindName, let asset):
            let kind: MediaKind = kindName == "image" ? .image : .video
            await asset.updateMediaKind(kind)
        case .spidAssets:
            break
        }
    }
}
