//
//  SwiftDataManager.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import AVFoundation
import UIKit

@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    let container: ModelContainer

    var modelContext: ModelContext {
        container.mainContext
    }

    private init() {
        do {
            container = try ModelContainer(
                for: VideoProject.self,
                SpidAssetModel.self,
                SDLabelViewModel.self
            )
            container.mainContext.undoManager = UndoManager()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        NotificationCenter.default.addObserver(
            forName: .OverlayLabelViewsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                SwiftDataManager.shared.upsertLabelViewModels()
            }
        }
    }

    // MARK: - VideoProject

    func fetchVideoProjects() -> [VideoProject] {
        (try? modelContext.fetch(FetchDescriptor<VideoProject>())) ?? []
    }

    /// Creates a new `VideoProject` from the selected base videos and sets it as `UserDataManager.currentProject`.
    @discardableResult
    func createVideoProject(from assets: [SpidAsset]) async -> VideoProject {
        var models: [SpidAssetModel] = []
        for (index, asset) in assets.enumerated() {
            let snapshot = await makePersistedSnapshot(from: asset)
            models.append(makeSpidAssetModel(from: snapshot, sortIndex: index))
        }

        let thumbnailImage = await thumbnailData(from: assets.first)
        let project = VideoProject(thumbnailImage: thumbnailImage, spidAssets: models)
        modelContext.insert(project)
        save()

        UserDataManager.main.currentProject = project
        return project
    }

    /// Upserts `UserDataManager.spidAssets` into `UserDataManager.currentProject`.
    @discardableResult
    func upsertVideoProject() async -> VideoProject? {
        guard let project = UserDataManager.main.currentProject else { return nil }
    
        let assets = UserDataManager.main.spidAssets
        if assets.count == 0 {
            print("upsertVideoProject: no assets to upsert")
        }
        var models: [SpidAssetModel] = []
        for (index, asset) in assets.enumerated() {
            let snapshot = await makePersistedSnapshot(from: asset)
            models.append(upsertSpidAssetModel(from: snapshot, sortIndex: index))
        }
        print("upsertVideoProject: after iteration")

        project.thumbnailImage = await thumbnailData(from: assets.first)
        project.spidAssets = models
        save()
        return project
    }

    /// Upserts `UserDataManager.labelViewsModels` into the current project's labels.
    @discardableResult
    func upsertLabelViewModels() -> [SDLabelViewModel]? {
        guard let project = UserDataManager.main.currentProject else { return nil }

        let viewModels = UserDataManager.main.labelViewsModels
        let targetIDs = Set(viewModels.map(\.id))
        for existing in project.labelViewModels where !targetIDs.contains(existing.id) {
            modelContext.delete(existing)
        }

        var existingByID = Dictionary(
            uniqueKeysWithValues: project.labelViewModels.map { ($0.id, $0) }
        )

        var models: [SDLabelViewModel] = []
        models.reserveCapacity(viewModels.count)
        for (index, viewModel) in viewModels.enumerated() {
            if let existing = existingByID[viewModel.id] {
                existing.update(from: viewModel, sortIndex: index)
                existing.project = project
                models.append(existing)
            } else {
                let model = SDLabelViewModel.make(from: viewModel, sortIndex: index, project: project)
                modelContext.insert(model)
                existingByID[model.id] = model
                models.append(model)
            }
        }

        project.labelViewModels = models
        save()
        return models
    }

//    /// Mutates `project.spidAssets` in place: removes missing models, appends new ones, reorders to match `models`.
//    private func syncSpidAssetModels(_ models: [SpidAssetModel], into project: VideoProject) {
//        let targetIDs = Set(models.map(\.id))
//
//        for existing in project.spidAssets where !targetIDs.contains(existing.id) {
//            modelContext.delete(existing)
//        }
//        project.spidAssets.removeAll { !targetIDs.contains($0.id) }
//
//        for model in models {
//            model.project = project
//            if model.modelContext == nil {
//                modelContext.insert(model)
//            }
//            if !project.spidAssets.contains(where: { $0.id == model.id }) {
//                project.spidAssets.append(model)
//            }
//        }
//
//        let order = models.map(\.id)
//        project.spidAssets.sort { lhs, rhs in
//            (order.firstIndex(of: lhs.id) ?? 0) < (order.firstIndex(of: rhs.id) ?? 0)
//        }
//    }

    /// Syncs the current `VideoProject` and its `SpidAssetModel`s onto in-memory `SpidAsset`s.
    /// Recreates assets that exist only in SwiftData and drops in-memory assets that no longer exist.
    /// Uses `UserDataManager.currentProject` when `project` is omitted.
    func applyProjectToInMemoryState(from project: VideoProject? = nil) async {
        guard let project = project ?? UserDataManager.main.currentProject else { return }
        let models = project.spidAssets.sorted { $0.sortIndex < $1.sortIndex }
        let currentID = await UserDataManager.main.currentSpidAsset?.id

        var assetsByID: [UUID: SpidAsset] = [:]
        for asset in UserDataManager.main.spidAssets {
            assetsByID[await asset.id] = asset
        }

        var updated: [SpidAsset] = []
        var matchedCurrent: SpidAsset?
        updated.reserveCapacity(models.count)
        for model in models {
            let asset: SpidAsset?
            if let existing = assetsByID[model.id] {
                await existing.apply(from: model)
                asset = existing
            } else {
                asset = await SpidAsset.make(from: model)
            }
            guard let asset else { continue }
            updated.append(asset)
            if model.id == currentID {
                matchedCurrent = asset
            }
        }

        UserDataManager.main.spidAssets = updated
        UserDataManager.main.currentSpidAsset = matchedCurrent ?? updated.first
    }

    func deleteVideoProject(_ project: VideoProject) {
        modelContext.delete(project)
        save()
    }

    /// Inserts a deep copy of `project` (new asset IDs) and returns it.
    @discardableResult
    func duplicateVideoProject(_ project: VideoProject) -> VideoProject {
        let copiedAssets = project.spidAssets
            .sorted { $0.sortIndex < $1.sortIndex }
            .map(copySpidAssetModel)
        let duplicate = VideoProject(
            thumbnailImage: project.thumbnailImage,
            createdAt: Date(),
            spidAssets: copiedAssets
        )
        modelContext.insert(duplicate)
        save()
        return duplicate
    }

    private func copySpidAssetModel(_ model: SpidAssetModel) -> SpidAssetModel {
        let timeRange = model.timeRange
        let clipSourceRange = model.clipSourceRange
        return SpidAssetModel(
            id: UUID(),
            videoData: model.videoData,
            fileExtension: model.fileExtension,
            timeRange: timeRange,
            clipSourceRange: clipSourceRange,
            videoWidth: model.videoWidth,
            videoHeight: model.videoHeight,
            speed: model.speed,
            soundOn: model.soundOn,
            sliderValue: model.sliderValue,
            mediaKindRawValue: model.mediaKindRawValue,
            videoFilterRawValue: model.videoFilterRawValue,
            sortIndex: model.sortIndex
        )
    }

    /// Reads the clip's raw bytes so they can be stored directly on the `SpidAssetModel`.
    private func makePersistedSnapshot(from asset: SpidAsset) async -> SpidAsset.PersistableSnapshot {
        let base = await asset.makePersistableSnapshot()
        let avAsset = await asset.getOriginalAsset()
        guard let urlAsset = avAsset as? AVURLAsset,
              urlAsset.url.isFileURL,
              let data = try? Data(contentsOf: urlAsset.url, options: .mappedIfSafe) else {
            print("Failed to read video data for asset \(base.id)")
            return base
        }
        return await asset.makePersistableSnapshot(videoData: data)
    }

    // MARK: - SpidAssetModel

    func fetchSpidAssetModels() -> [SpidAssetModel] {
        let descriptor = FetchDescriptor<SpidAssetModel>(
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func makeSpidAssets(from models: [SpidAssetModel]) async -> [SpidAsset] {
        var assets: [SpidAsset] = []
        for model in models {
            if let asset = await SpidAsset.make(from: model) {
                assets.append(asset)
            }
        }
        return assets
    }

    func spidAssetModel(id: UUID) -> SpidAssetModel? {
        let targetID = id
        let descriptor = FetchDescriptor<SpidAssetModel>(
            predicate: #Predicate { $0.id == targetID }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Builds a new `SpidAssetModel` without inserting it; ownership comes from the parent `VideoProject`.
    func makeSpidAssetModel(from snapshot: SpidAsset.PersistableSnapshot, sortIndex: Int) -> SpidAssetModel {
        let timeRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.timeRangeStartValue, timescale: snapshot.timeRangeStartTimescale),
            duration: CMTime(value: snapshot.timeRangeDurationValue, timescale: snapshot.timeRangeDurationTimescale)
        )
        let clipSourceRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.clipSourceStartValue, timescale: snapshot.clipSourceStartTimescale),
            duration: CMTime(value: snapshot.clipSourceDurationValue, timescale: snapshot.clipSourceDurationTimescale)
        )

        return SpidAssetModel(
            id: snapshot.id,
            videoData: snapshot.videoData,
            fileExtension: snapshot.fileExtension,
            timeRange: timeRangeCM,
            clipSourceRange: clipSourceRangeCM,
            videoWidth: snapshot.videoWidth,
            videoHeight: snapshot.videoHeight,
            speed: snapshot.speed,
            soundOn: snapshot.soundOn,
            sliderValue: snapshot.sliderValue,
            mediaKindRawValue: snapshot.mediaKindRawValue,
            videoFilterRawValue: snapshot.videoFilterRawValue,
            sortIndex: sortIndex
        )
    }

    @discardableResult
    func upsertSpidAssetModel(from snapshot: SpidAsset.PersistableSnapshot, sortIndex: Int) -> SpidAssetModel {
        let timeRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.timeRangeStartValue, timescale: snapshot.timeRangeStartTimescale),
            duration: CMTime(value: snapshot.timeRangeDurationValue, timescale: snapshot.timeRangeDurationTimescale)
        )
        let clipSourceRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.clipSourceStartValue, timescale: snapshot.clipSourceStartTimescale),
            duration: CMTime(value: snapshot.clipSourceDurationValue, timescale: snapshot.clipSourceDurationTimescale)
        )

        if let existing = spidAssetModel(id: snapshot.id) {
            if !snapshot.videoData.isEmpty {
                existing.videoData = snapshot.videoData
                existing.fileExtension = snapshot.fileExtension
            }
            existing.timeRange = timeRangeCM
            existing.clipSourceRange = clipSourceRangeCM
            existing.videoWidth = snapshot.videoWidth
            existing.videoHeight = snapshot.videoHeight
            existing.speed = snapshot.speed
            existing.soundOn = snapshot.soundOn
            existing.sliderValue = snapshot.sliderValue
            existing.mediaKindRawValue = snapshot.mediaKindRawValue
            existing.videoFilterRawValue = snapshot.videoFilterRawValue
            existing.sortIndex = sortIndex
            return existing
        }

        return makeSpidAssetModel(from: snapshot, sortIndex: sortIndex)
    }

    func updateSpeed(_ speed: Float, forAssetID id: UUID) {
        guard let model = spidAssetModel(id: id) else { return }
        model.speed = speed
        model.sliderValue = SpidAsset.convertSpeedToSliderValue(speed: speed)
        save()
    }

    func updateTimeRange(_ timeRange: CMTimeRange, forAssetID id: UUID) {
        guard let model = spidAssetModel(id: id) else { return }
        model.timeRange = timeRange
        save()
    }

    func deleteAllSpidAssetModels() {
        do {
            let models = try modelContext.fetch(FetchDescriptor<SpidAssetModel>())
            for model in models {
                modelContext.delete(model)
            }
            save()
        } catch {
            print("Failed to delete SpidAssetModels: \(error)")
        }
    }

    func save() {
        guard modelContext.hasChanges else { return }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save ModelContext: \(error)")
        }
    }

    /// Persists the context without registering a new undo group, so redo survives undo+save.
    func saveWithoutRegisteringUndo() {
        let undoManager = modelContext.undoManager
        undoManager?.disableUndoRegistration()
        defer { undoManager?.enableUndoRegistration() }
        save()
    }

    /// Undoes or redoes the last SwiftData save, persists it, maps History, then syncs project to in-memory state.
    @discardableResult
    func performUndoOrRedo(undo: Bool) async -> ProjectHistoryDiff {
        print("[performUndoOrRedo] start undo=\(undo)")

        let before = try? latestHistoryToken()
        print("[performUndoOrRedo] latestHistoryToken before=\(String(describing: before))")

        if undo {
            print("[performUndoOrRedo] calling undoManager.undo()")
            modelContext.undoManager?.undo()
        } else {
            print("[performUndoOrRedo] calling undoManager.redo()")
            modelContext.undoManager?.redo()
        }

        print("[performUndoOrRedo] saving without registering undo")
        saveWithoutRegisteringUndo()

        let transactions = (try? fetchHistory(after: before)) ?? []
        print("[performUndoOrRedo] fetched \(transactions.count) history transaction(s) after token")

        guard !transactions.isEmpty else {
            print("[performUndoOrRedo] no transactions after token — falling back to last transaction")
            let transactions = try! fetchHistory(after: nil)
            print("[performUndoOrRedo] fallback fetched \(transactions.count) transaction(s)")
            let diff = projectHistoryDiff(from: transactions)
            print("[performUndoOrRedo] diff (fallback): \(diff)")
            print("[performUndoOrRedo] applying project to in-memory state")
            await applyProjectToInMemoryState()
            print("[performUndoOrRedo] done (fallback path)")
            return diff
        }

        let diff = projectHistoryDiff(from: transactions)
        print("[performUndoOrRedo] diff: \(diff)")
        print("[performUndoOrRedo] applying project to in-memory state")
        await applyProjectToInMemoryState()
        print("[performUndoOrRedo] done")
        return diff
    }

    func latestHistoryToken() throws -> DefaultHistoryToken? {
        let descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        return try modelContext.fetchHistory(descriptor).last?.token
    }

    func fetchHistory(after token: DefaultHistoryToken?) throws -> [DefaultHistoryTransaction] {
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token {
            descriptor.predicate = #Predicate { $0.token > token }
            return try modelContext.fetchHistory(descriptor)
        }
        let all = try modelContext.fetchHistory(descriptor)
        if let last = all.last {
            return [last]
        }
        return []
    }

    func projectHistoryDiff(from transactions: [DefaultHistoryTransaction]) -> ProjectHistoryDiff {
        var diff = ProjectHistoryDiff()
        for transaction in transactions {
            for change in transaction.changes {
                applyHistoryChange(change, to: &diff)
            }
        }
        print("diff \(diff)")

        return diff
    }

    private func applyHistoryChange(_ change: HistoryChange, to diff: inout ProjectHistoryDiff) {
        switch change {
        case .update(let update as DefaultHistoryUpdate<VideoProject>):
            diff.projectUpdated.formUnion(videoProjectFields(from: update.updatedAttributes))
        case .insert(_ as DefaultHistoryInsert<VideoProject>),
             .delete(_ as DefaultHistoryDelete<VideoProject>):
            diff.projectUpdated.insert(.other)
        case .insert(_ as DefaultHistoryInsert<SpidAssetModel>):
            if let model: SpidAssetModel = modelContext.registeredModel(for: change.changedPersistentIdentifier) {
                diff.insertedAssetIDs.insert(model.id)
            }
        case .update(let update as DefaultHistoryUpdate<SpidAssetModel>):
            if let model: SpidAssetModel = modelContext.registeredModel(for: change.changedPersistentIdentifier) {
                let changes = spidAssetFieldChanges(from: update.updatedAttributes, model: model)
                diff.upsertAssetChanges(assetID: model.id, changes)
            }
        case .delete(_ as DefaultHistoryDelete<SpidAssetModel>):
            diff.deletedAssetPersistentIDs.insert(change.changedPersistentIdentifier)
        default:
            break
        }
    }

    private func videoProjectFields(from attributes: [any PartialKeyPath<VideoProject> & Sendable]) -> Set<VideoProjectField> {
        var fields: Set<VideoProjectField> = []
        for path in attributes {
            let keyPath = path as PartialKeyPath<VideoProject>
            if keyPath == \.thumbnailImage {
                fields.insert(.thumbnailImage)
            } else if keyPath == \.spidAssets {
                fields.insert(.spidAssets)
            } else if keyPath == \.createdAt {
                fields.insert(.createdAt)
            } else {
                fields.insert(.other)
            }
        }
        return fields
    }

    private func spidAssetFieldChanges(
        from attributes: [any PartialKeyPath<SpidAssetModel> & Sendable],
        model: SpidAssetModel
    ) -> [SpidAssetFieldChange] {
        var changes: [SpidAssetFieldChange] = []
        var didAddVideoSize = false
        var didAddTimeRange = false
        var didAddClipSourceRange = false
        for path in attributes {
            let keyPath = path as PartialKeyPath<SpidAssetModel>
            if keyPath == \.speed {
                changes.append(.speed(model.speed))
            } else if keyPath == \.soundOn {
                changes.append(.soundOn(model.soundOn))
            } else if keyPath == \.sliderValue {
                changes.append(.sliderValue(model.sliderValue))
            } else if keyPath == \.videoFilterRawValue {
                changes.append(.videoFilter(model.videoFilterRawValue))
            } else if keyPath == \.sortIndex {
                changes.append(.sortIndex(model.sortIndex))
            } else if keyPath == \.videoWidth || keyPath == \.videoHeight {
                if !didAddVideoSize {
                    changes.append(.videoSize(CGSize(width: model.videoWidth, height: model.videoHeight)))
                    didAddVideoSize = true
                }
            } else if keyPath == \.mediaKindRawValue {
                changes.append(.mediaKind(model.mediaKindRawValue))
            } else if isTimeRangeScalar(keyPath) {
                if !didAddTimeRange {
                    changes.append(.timeRange(model.timeRange))
                    didAddTimeRange = true
                }
            } else if isClipSourceRangeScalar(keyPath) {
                if !didAddClipSourceRange {
                    changes.append(.clipSourceRange(model.clipSourceRange))
                    didAddClipSourceRange = true
                }
            } else {
                changes.append(.other)
            }
        }
        return changes
    }

    private func isTimeRangeScalar(_ keyPath: PartialKeyPath<SpidAssetModel>) -> Bool {
        keyPath == \.timeRangeStartValue
            || keyPath == \.timeRangeStartTimescale
            || keyPath == \.timeRangeDurationValue
            || keyPath == \.timeRangeDurationTimescale
    }

    private func isClipSourceRangeScalar(_ keyPath: PartialKeyPath<SpidAssetModel>) -> Bool {
        keyPath == \.clipSourceStartValue
            || keyPath == \.clipSourceStartTimescale
            || keyPath == \.clipSourceDurationValue
            || keyPath == \.clipSourceDurationTimescale
    }

    private func thumbnailData(from asset: SpidAsset?) async -> Data {
        guard let asset else { return Data() }
        let cgImage = await asset.thumbnailImage
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.85) ?? Data()
    }
}
