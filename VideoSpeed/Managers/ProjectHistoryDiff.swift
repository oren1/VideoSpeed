//
//  ProjectHistoryDiff.swift
//  VideoSpeed
//

import Foundation
import CoreMedia
import CoreGraphics
import SwiftData

enum VideoProjectField: String, Hashable {
    case thumbnailImage
    case spidAssets
    case createdAt
    case other
}

/// A SpidAsset field that changed, carrying the post-change value.
enum SpidAssetFieldChange {
    case speed(Float)
    case soundOn(Bool)
    case sliderValue(Float)
    case videoFilter(String)
    case timeRange(CMTimeRange)
    case clipSourceRange(CMTimeRange)
    case videoSize(CGSize)
    case mediaKind(String)
    case sortIndex(Int)
    case other

    /// Case identity used to keep at most one change per field.
    var fieldID: String {
        switch self {
        case .speed: return "speed"
        case .soundOn: return "soundOn"
        case .sliderValue: return "sliderValue"
        case .videoFilter: return "videoFilter"
        case .timeRange: return "timeRange"
        case .clipSourceRange: return "clipSourceRange"
        case .videoSize: return "videoSize"
        case .mediaKind: return "mediaKind"
        case .sortIndex: return "sortIndex"
        case .other: return "other"
        }
    }

    var isSpeedOrSlider: Bool {
        switch self {
        case .speed, .sliderValue: return true
        default: return false
        }
    }

    var isTimeRange: Bool {
        if case .timeRange = self { return true }
        return false
    }
}

struct ProjectHistoryDiff {
    var projectUpdated: Set<VideoProjectField> = []
    var insertedAssetIDs: Set<UUID> = []
    var deletedAssetPersistentIDs: Set<PersistentIdentifier> = []
    var updatedAssets: [UUID: [SpidAssetFieldChange]] = [:]

    /// Inserts or replaces a field change so each field appears at most once per asset.
    mutating func upsertAssetChange(assetID: UUID, _ change: SpidAssetFieldChange) {
        var changes = updatedAssets[assetID, default: []]
        if let index = changes.firstIndex(where: { $0.fieldID == change.fieldID }) {
            changes[index] = change
        } else {
            changes.append(change)
        }
        updatedAssets[assetID] = changes
    }

    mutating func upsertAssetChanges(assetID: UUID, _ changes: [SpidAssetFieldChange]) {
        for change in changes {
            upsertAssetChange(assetID: assetID, change)
        }
    }
}

extension ProjectHistoryDiff: CustomStringConvertible {
    var description: String {
        let projectFields = projectUpdated.map(\.rawValue).sorted().joined(separator: ",")
        let assetUpdates = updatedAssets
            .map { assetID, changes in
                let fields = changes.map(\.fieldID).sorted().joined(separator: ",")
                return "\(assetID.uuidString.prefix(8)): \(fields)"
            }
            .sorted()
            .joined(separator: "; ")
        return "project=[\(projectFields)] insertedAssets=\(insertedAssetIDs.count) deletedAssets=\(deletedAssetPersistentIDs.count) updatedAssets=[\(assetUpdates)]"
    }
}
