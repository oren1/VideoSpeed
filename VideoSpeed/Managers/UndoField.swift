//
//  UndoField.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 02/09/2026.
//
import Foundation
import AVFoundation

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
        case .other: return "other"
        }
    }
}
