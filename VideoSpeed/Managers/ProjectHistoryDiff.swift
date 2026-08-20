//
//  ProjectHistoryDiff.swift
//  VideoSpeed
//

import Foundation
import SwiftData

enum VideoProjectField: String, Hashable {
    case thumbnailImage
    case spidAssets
    case createdAt
    case other
}

enum SpidAssetField: String, Hashable {
    case speed
    case soundOn
    case sliderValue
    case videoFilter
    case timeRange
    case clipSourceRange
    case videoSize
    case mediaKind
    case sortIndex
    case other
}

struct ProjectHistoryDiff {
    var projectUpdated: Set<VideoProjectField> = []
    var insertedAssetIDs: Set<UUID> = []
    var deletedAssetPersistentIDs: Set<PersistentIdentifier> = []
    var updatedAssets: [UUID: Set<SpidAssetField>] = [:]
}

extension ProjectHistoryDiff: CustomStringConvertible {
    var description: String {
        let projectFields = projectUpdated.map(\.rawValue).sorted().joined(separator: ",")
        let assetUpdates = updatedAssets
            .map { "\($0.key.uuidString.prefix(8)): \($0.value.map(\.rawValue).sorted().joined(separator: ","))" }
            .sorted()
            .joined(separator: "; ")
        return "project=[\(projectFields)] insertedAssets=\(insertedAssetIDs.count) deletedAssets=\(deletedAssetPersistentIDs.count) updatedAssets=[\(assetUpdates)]"
    }
}
