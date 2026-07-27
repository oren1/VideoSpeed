//
//  AudioImportOption.swift
//  VideoSpeed
//

import Foundation

enum AudioImportOption: String, CaseIterable, Identifiable {
    case extractFromVideo = "Extract from Video"
    case importFromMusic = "Import from iTunes"
    case record = "Record"

    var id: String { rawValue }

    var systemImageName: String {
        switch self {
        case .extractFromVideo: return "film"
        case .importFromMusic: return "music.note"
        case .record: return "mic.fill"
        }
    }
}
