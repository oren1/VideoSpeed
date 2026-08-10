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
                StoredCMTimeRange.self,
                StoredCMTime.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
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
        var models: [SpidAssetModel] = []
        for (index, asset) in assets.enumerated() {
            let snapshot = await makePersistedSnapshot(from: asset)
            models.append(upsertSpidAssetModel(from: snapshot, sortIndex: index))
        }

        project.thumbnailImage = await thumbnailData(from: assets.first)
        project.spidAssets = models
        save()
        return project
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
            timeRange: StoredCMTimeRange(timeRangeCM),
            clipSourceRange: StoredCMTimeRange(clipSourceRangeCM),
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
            if let existingTimeRange = existing.timeRange {
                existingTimeRange.update(from: timeRangeCM)
            } else {
                existing.timeRange = StoredCMTimeRange(timeRangeCM)
            }
            if let existingClipSourceRange = existing.clipSourceRange {
                existingClipSourceRange.update(from: clipSourceRangeCM)
            } else {
                existing.clipSourceRange = StoredCMTimeRange(clipSourceRangeCM)
            }
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

    private func thumbnailData(from asset: SpidAsset?) async -> Data {
        guard let asset else { return Data() }
        let cgImage = await asset.thumbnailImage
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.85) ?? Data()
    }
}
