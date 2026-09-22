//
//  UndoField.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 02/09/2026.
//
import Foundation
import AVFoundation
import CoreGraphics

/// Captures enough project + source-clip state to undo/redo a split.
struct SplitUndoSnapshot {
    let assets: [SpidAsset]
    let currentAsset: SpidAsset
    let sourceAsset: SpidAsset
    let sourceTimeRange: CMTimeRange
    let sourceClipSourceRange: CMTimeRange
    let sourceThumbnail: CGImage
    let sourceThumbnailImages: [CGImage]?
    let sourceLeftHandle: CGFloat?
    let sourceRightHandle: CGFloat?
    let splitCount: Int
}

/// Deep-copied overlay labels (+ selection) for undo/redo.
struct LabelsUndoSnapshot {
    let labels: [LabelViewModel]
    let selectedID: UUID?

    static func capture() -> LabelsUndoSnapshot {
        LabelsUndoSnapshot(
            labels: UserDataManager.main.labelViewsModels.map { $0.copyForUndo() },
            selectedID: UserDataManager.main.selectedLabelViewModel?.id
        )
    }
}

enum UndoField {
    case none
    case speed(Float, SpidAsset)
    case soundOn(Bool, SpidAsset)
    case sliderValue(Float, SpidAsset)
    case videoFilter(String, SpidAsset)
    case timeRange(CMTimeRange, SpidAsset)
    case clipSourceRange(CMTimeRange, SpidAsset)
    case videoSize(CGSize, SpidAsset)
    case mediaKind(String, SpidAsset)
    case spidAssets([SpidAsset])
    case split(SplitUndoSnapshot)
    case labels(LabelsUndoSnapshot)
    case other

    /// Case identity used to keep at most one change per field.
    var fieldID: String {
        switch self {
        case .none: return "none"
        case .speed: return "speed"
        case .soundOn: return "soundOn"
        case .sliderValue: return "sliderValue"
        case .videoFilter: return "videoFilter"
        case .timeRange: return "timeRange"
        case .clipSourceRange: return "clipSourceRange"
        case .videoSize: return "videoSize"
        case .mediaKind: return "mediaKind"
        case .spidAssets: return "spidAssets"
        case .split: return "split"
        case .labels: return "labels"
        case .other: return "other"
        }
    }
}
