//
//  SwiftDataManager.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import AVFoundation

@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    let container: ModelContainer

    var modelContext: ModelContext {
        container.mainContext
    }

    private init() {
        do {
            let schema = Schema([
                VideoProject.self,
                SpidAssetModel.self,
                StoredCMTimeRange.self,
                StoredCMTime.self
            ])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
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

    func syncSpidAssetModels(from assets: [SpidAsset]) async {
        for (index, asset) in assets.enumerated() {
            let snapshot = await asset.makePersistableSnapshot()
            upsertSpidAssetModel(from: snapshot, sortIndex: index)
        }
        save()
    }

    func upsertSpidAssetModel(from snapshot: SpidAsset.PersistableSnapshot, sortIndex: Int) {
        let timeRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.timeRangeStartValue, timescale: snapshot.timeRangeStartTimescale),
            duration: CMTime(value: snapshot.timeRangeDurationValue, timescale: snapshot.timeRangeDurationTimescale)
        )
        let clipSourceRangeCM = CMTimeRange(
            start: CMTime(value: snapshot.clipSourceStartValue, timescale: snapshot.clipSourceStartTimescale),
            duration: CMTime(value: snapshot.clipSourceDurationValue, timescale: snapshot.clipSourceDurationTimescale)
        )

        if let existing = spidAssetModel(id: snapshot.id) {
            existing.assetURLString = snapshot.assetURLString
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
        } else {
            let model = SpidAssetModel(
                id: snapshot.id,
                assetURLString: snapshot.assetURLString,
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
            modelContext.insert(model)
        }
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
}
