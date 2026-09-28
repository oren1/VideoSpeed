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

    /// Updates video filter on the runtime asset and persists it to SwiftData.
    func updateVideoFilter(_ filter: VideoFilter, for asset: SpidAsset? = nil) async {
        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldFilter = await spidAsset.videoFilter
        guard oldFilter != filter else { return }

        registerUndo(
            previous: .videoFilter(oldFilter.rawValue, spidAsset),
            current: .videoFilter(filter.rawValue, spidAsset)
        )
        await spidAsset.updateVideoFilter(filter)
        await SwiftDataManager.shared.upsertVideoProject()
    }

    /// Splits the current clip at `splitTime` and registers undo/redo snapshots.
    @discardableResult
    func split(at splitTime: CMTime) async -> Bool {
        guard let sourceAsset = UserDataManager.main.currentSpidAsset else { return false }

        let before = await makeSplitSnapshot(sourceAsset: sourceAsset)
        let didSplit = await UserDataManager.main.splitCurrentAsset(at: splitTime)
        guard didSplit else { return false }

        let after = await makeSplitSnapshot(sourceAsset: sourceAsset)
        registerUndo(previous: .split(before), current: .split(after))
        await SwiftDataManager.shared.upsertVideoProject()
        return true
    }

    /// Runs a labels mutation and registers undo/redo from deep-copied before/after snapshots.
    func performLabelsChange(_ change: () -> Void) {
        let before = LabelsUndoSnapshot.capture()
        change()
        registerLabelsChange(before: before)
    }

    /// Registers undo from a previously captured `before` snapshot to the current labels state.
    func registerLabelsChange(before: LabelsUndoSnapshot) {
        let after = LabelsUndoSnapshot.capture()
        registerUndo(previous: .labels(before), current: .labels(after))
    }

    /// Runs a captions mutation and registers undo/redo from before/after snapshots.
    func performCaptionsChange(_ change: () -> Void) {
        let before = CaptionsUndoSnapshot.capture()
        change()
        registerCaptionsChange(before: before)
    }

    /// Registers undo from a previously captured `before` snapshot to the current captions state.
    func registerCaptionsChange(before: CaptionsUndoSnapshot) {
        let after = CaptionsUndoSnapshot.capture()
        guard before != after else { return }
        registerUndo(previous: .captions(before), current: .captions(after))
        SwiftDataManager.shared.upsertCaptions()
    }

    /// Updates sound on/off on the runtime asset and registers undo/redo.
    func updateSound(_ soundOn: Bool, for asset: SpidAsset? = nil) async {
        guard let spidAsset = asset ?? UserDataManager.main.currentSpidAsset else { return }
        let oldSoundOn = await spidAsset.soundOn
        guard oldSoundOn != soundOn else { return }

        registerUndo(
            previous: .soundOn(oldSoundOn, spidAsset),
            current: .soundOn(soundOn, spidAsset)
        )
        await spidAsset.updateSound(soundOn: soundOn)
    }

    /// Updates project FPS and registers undo/redo.
    func updateFPS(from oldFPS: Int32, to fps: Int32) {
        guard oldFPS != fps else { return }
        registerUndo(previous: .fps(oldFPS), current: .fps(fps))
        SwiftDataManager.shared.updateProjectFPS(fps)
    }

    /// Registers undo that restores `previous`. While undoing/redoing, re-registers
    /// with `previous`/`current` swapped so the opposite stack entry is created.
    private func registerUndo(previous: UndoField, current: UndoField) {
        let undoManager = UserDataManager.main.undoManager
        // Registers an undo operation
        undoManager.registerUndo(withTarget: self) { stateManager in
            // setting the undoField to the previous
            stateManager.undoField = previous
            // Register a reverse undo operation.
            // While we're inside an undo operation, adding another operation
            // adds it to the opposite stack and allows to redo
            stateManager.registerUndo(previous: current, current: previous)

            Task { @MainActor in
                await stateManager.apply(previous)
                stateManager.notifyUndoFieldChanged(field: previous)
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

    private func makeSplitSnapshot(sourceAsset: SpidAsset) async -> SplitUndoSnapshot {
        SplitUndoSnapshot(
            assets: UserDataManager.main.spidAssets,
            currentAsset: UserDataManager.main.currentSpidAsset,
            sourceAsset: sourceAsset,
            sourceTimeRange: await sourceAsset.timeRange,
            sourceClipSourceRange: await sourceAsset.clipSourceRange,
            sourceThumbnail: await sourceAsset.thumbnailImage,
            sourceThumbnailImages: await sourceAsset.thumbnailImages,
            sourceLeftHandle: await sourceAsset.leftHandleConstraintConstant,
            sourceRightHandle: await sourceAsset.rightHandleConstraintConstant,
            splitCount: UserDataManager.main.splitCount
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
            await SwiftDataManager.shared.upsertVideoProject()
        case .timeRange(let timeRange, let asset):
            await asset.updateTimeRange(timeRange: timeRange)
            await asset.clearHandleConstraintConstants()
        case .clipSourceRange(let range, let asset):
            await asset.updateClipSourceRange(range)
        case .videoSize(let size, let asset):
            await asset.updateVideoSize(size)
        case .mediaKind(let kindName, let asset):
            let kind: MediaKind = kindName == "image" ? .image : .video
            await asset.updateMediaKind(kind)
        case .spidAssets:
            break
        case .split(let snapshot):
            UserDataManager.main.spidAssets = snapshot.assets
            UserDataManager.main.currentSpidAsset = snapshot.currentAsset
            UserDataManager.main.splitCount = snapshot.splitCount

            await snapshot.sourceAsset.updateTimeRange(timeRange: snapshot.sourceTimeRange)
            await snapshot.sourceAsset.updateClipSourceRange(snapshot.sourceClipSourceRange)
            await snapshot.sourceAsset.updateThumbnailImage(snapshot.sourceThumbnail)
            await snapshot.sourceAsset.updateThumbnailImages(images: snapshot.sourceThumbnailImages)
            await snapshot.sourceAsset.clearHandleConstraintConstants()
            if let left = snapshot.sourceLeftHandle {
                await snapshot.sourceAsset.updateLeftHandleConstraintConstant(constant: left)
            }
            if let right = snapshot.sourceRightHandle {
                await snapshot.sourceAsset.updateRightHandleConstraintConstant(constant: right)
            }

            await SwiftDataManager.shared.upsertVideoProject()
        case .labels(let snapshot):
            let restored = snapshot.labels.map { $0.copyForUndo() }
            UserDataManager.main.labelViewsModels = restored
            if let selectedID = snapshot.selectedID,
               let selected = restored.first(where: { $0.id == selectedID }) {
                UserDataManager.main.setSelectedLabeViewModel(selected)
            } else {
                restored.forEach { $0.selected = false }
                UserDataManager.main.selectedLabelViewModel = nil
            }
            SwiftDataManager.shared.upsertLabelViewModels()
        case .captions(let snapshot):
            CaptionStyleGenerator.applyStyleFromStore {
                snapshot.style.apply(to: CaptionStyleGenerator.captionsStyle)
            }
            UserDataManager.main.captionsOverlayPose = snapshot.pose
            if let data = snapshot.transcriptionData,
               let transcription = try? PersistedTranscription.decode(data) {
                UserDataManager.main.transcription = transcription
                if let segments = transcription.segments {
                    UserDataManager.main.currentCaptions = CaptionStyleGenerator.generateCaptions(from: segments)
                } else {
                    UserDataManager.main.currentCaptions = nil
                }
            } else {
                UserDataManager.main.transcription = nil
                UserDataManager.main.currentCaptions = nil
                UserDataManager.main.captions = []
            }
            SwiftDataManager.shared.upsertCaptions()
        case .fps(let fps):
            SwiftDataManager.shared.updateProjectFPS(fps)
        }
    }
}
