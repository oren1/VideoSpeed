//
//  BundledAudioCatalog.swift
//  VideoSpeed
//

import Foundation

struct BundledAudioTrack: Identifiable, Equatable {
    let id: String
    let title: String
    let fileName: String

    var fileURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}

enum BundledAudioCatalog {
    static let tracks: [BundledAudioTrack] = [
        BundledAudioTrack(
            id: "check_yes_juliet_audio",
            title: "Check Yes, Juliet",
            fileName: "Check Yes, Juliet-audio.mp3"
        ),
        BundledAudioTrack(
            id: "the_hell_song_audio",
            title: "The Hell Song",
            fileName: "The Hell Song-audio.mp3"
        )
    ]
}
