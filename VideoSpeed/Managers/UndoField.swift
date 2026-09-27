//
//  UndoField.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 02/09/2026.
//
import Foundation
import AVFoundation
import CoreGraphics
import UIKit

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

/// Value snapshot of live `CaptionsStyle` for undo/redo.
struct CaptionsStyleSnapshot: Equatable {
    let captionType: CaptionsType
    let textColorR: Double
    let textColorG: Double
    let textColorB: Double
    let textColorA: Double
    let borderColorR: Double
    let borderColorG: Double
    let borderColorB: Double
    let borderColorA: Double
    let borderWidth: Double
    let highlightColorR: Double?
    let highlightColorG: Double?
    let highlightColorB: Double?
    let highlightColorA: Double?
    let fontName: String
    let fontSize: Double

    static func capture(from style: CaptionsStyle = CaptionStyleGenerator.captionsStyle) -> CaptionsStyleSnapshot {
        let text = style.textColor.captionsRGBAComponents()
        let border = style.borderColor.captionsRGBAComponents()
        let highlight = style.highlightColor?.captionsRGBAComponents()
        return CaptionsStyleSnapshot(
            captionType: style.captionType,
            textColorR: text.r,
            textColorG: text.g,
            textColorB: text.b,
            textColorA: text.a,
            borderColorR: border.r,
            borderColorG: border.g,
            borderColorB: border.b,
            borderColorA: border.a,
            borderWidth: Double(style.borderWidth),
            highlightColorR: highlight?.r,
            highlightColorG: highlight?.g,
            highlightColorB: highlight?.b,
            highlightColorA: highlight?.a,
            fontName: style.spidFont.name,
            fontSize: Double(style.fontSize)
        )
    }

    func apply(to style: CaptionsStyle) {
        style.captionType = captionType
        style.textColor = UIColor(red: textColorR, green: textColorG, blue: textColorB, alpha: textColorA)
        style.borderColor = UIColor(red: borderColorR, green: borderColorG, blue: borderColorB, alpha: borderColorA)
        style.borderWidth = CGFloat(borderWidth)
        if let r = highlightColorR, let g = highlightColorG, let b = highlightColorB, let a = highlightColorA {
            style.highlightColor = UIColor(red: r, green: g, blue: b, alpha: a)
        } else {
            style.highlightColor = nil
        }
        style.fontSize = CGFloat(fontSize)
        style.spidFont = SpidFont.font(named: fontName, size: CGFloat(fontSize))
    }
}

/// Transcription + style + overlay pose for captions undo/redo.
struct CaptionsUndoSnapshot: Equatable {
    /// `nil` means captions are cleared.
    let transcriptionData: Data?
    let style: CaptionsStyleSnapshot
    let pose: CaptionsOverlayPose

    static func capture() -> CaptionsUndoSnapshot {
        let transcriptionData: Data?
        if let transcription = UserDataManager.main.transcription {
            transcriptionData = try? PersistedTranscription.encode(transcription)
        } else {
            transcriptionData = nil
        }
        return CaptionsUndoSnapshot(
            transcriptionData: transcriptionData,
            style: CaptionsStyleSnapshot.capture(),
            pose: UserDataManager.main.captionsOverlayPose
        )
    }
}

private extension UIColor {
    func captionsRGBAComponents() -> (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (Double(r), Double(g), Double(b), Double(a))
        }
        return (1, 1, 1, 1)
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
    case captions(CaptionsUndoSnapshot)
    case fps(Int32)
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
        case .captions: return "captions"
        case .fps: return "fps"
        case .other: return "other"
        }
    }
}
